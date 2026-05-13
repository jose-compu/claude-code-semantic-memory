# claude-code-semantic-memory

Claude Code **plugin** that gives the agent **seamless, Cursor-style semantic memory**: a persistent vector index of your repo that the model queries silently during normal conversation. Bundled **LogosDB** MCP ([`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server)), local on-device embeddings by default (no API keys), slash-invoked skills.

Structure follows Anthropic’s **[example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin)** ([README](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/example-plugin/README.md)): `.claude-plugin/plugin.json`, root **`.mcp.json`**, and **`skills/*/SKILL.md`** (preferred over legacy `commands/*.md`).

## Install (plugin)

```text
/plugin marketplace add jose-compu/claude-code-semantic-memory
/plugin install semantic-memory
```

MCP **`logosdb`** runs **`/bin/sh`** + **`scripts/logosdb-mcp-wrap.sh`** (see **`.claude-plugin/plugin.json`**, mirrored in **`.mcp.json`**). Wrapper sets **`LOGOSDB_PATH`**, **`LOGOSDB_INDEX_ROOT`**, and **`cd`** from **`CLAUDE_PROJECT_DIR`** when present ([claude-code#42687](https://github.com/anthropics/claude-code/issues/42687)). **`claude --debug`** if tools are missing.

## How it feels (Cursor-style)

Once installed and the [§ CLAUDE.md drop-in template](#claudemd-drop-in-template) is pasted into the project, the plugin behaves like Cursor’s built-in indexing + semantic search — except it runs **fully locally**, lives **inside Claude Code**, and you (the agent) drive it through one MCP server. The user does **not** have to think about it.

| Phase | What happens | User effort |
|-------|--------------|-------------|
| **Session start** | The agent runs `/index .` on the first turn (incremental: only changed/new files re-embed). First run on a fresh repo embeds everything once; subsequent sessions are fast (typically a few seconds). | none — the `CLAUDE.md` block makes it mandatory |
| **During chat** | When the user asks *“where is X implemented?”*, *“what did we decide about Y?”*, *“how does Z work?”*, the model silently calls `logosdb_search`, reads the top 3–5 chunks, and answers in prose with **brief file citations** (e.g. `src/foo.ts`). No raw chunk dumps in the reply. | none |
| **After edits / pull / merge** | The agent (or user) runs `/index <path>` again. Incremental mode means only the changed files pay the embedding cost. | optional — `/index .` covers everything |
| **Curating memory** | `/forget <query>` or `/forget --id=N` drops stale entries. Separate namespaces (`code`, `docs`, `decisions`) keep different concerns retrievable independently. | only when something stale needs pruning |

Concrete example (user prompt → assistant behavior, no slash command typed):

```text
user> what is Terminus' agentic philosophy?

agent (silently) → logosdb_search(query="Terminus agentic philosophy", namespace="code", top_k=5)
agent (reply)    → "Terminus-2 is built around three ideas: a single-tool tmux
                    interface, full autonomy (never asks the user during a task),
                    and a clean split between agent logic and Docker environment.
                    See terminus.txt for the full design notes."
```

How this differs from Cursor’s memory:

- **Local-first.** Embeddings run on-device via Transformers.js (`Xenova/all-MiniLM-L6-v2`, 384 dims). No API keys, no cloud calls. Optional cloud / Ollama backends are available via `EMBEDDING_PROVIDER`.
- **Persistent and inspectable.** Vectors live on disk under `.logosdb/` (per-project) or `~/.claude/.logosdb` (user-wide). You can `rm -rf` to reset, `git`-ignore to keep them out of source control, or back them up explicitly.
- **Explicit namespaces.** `code`, `docs`, `decisions`, or any name you choose — useful when retrieval needs to be scoped.
- **Manual but cheap re-index.** No filesystem watcher; the agent calls `/index` at session start and after edits. `incremental: true` makes repeat passes nearly free.
- **Quiet by design.** Slash skills enforce one-line outputs; background `logosdb_search` calls keep `top_k` small and cite paths rather than quoting full chunks. See [§ Slash commands](#slash-commands-skills-format).


## Layout

```
claude-code-semantic-memory/
├── .claude-plugin/
│   └── plugin.json          # metadata + inline mcpServers.logosdb
├── scripts/
│   └── logosdb-mcp-wrap.sh  # sets LOGOSDB_PATH from CLAUDE_PROJECT_DIR, runs npx server
├── .mcp.json                # same MCP block as plugin.json (mirror)
├── commands/
│   └── README.md            # note: slash skills live under skills/
├── skills/
│   ├── semantic-memory/     # model-invoked guidance + CLAUDE.md template
│   │   ├── SKILL.md
│   │   └── .claude/commands/   # optional copy → project /index /search /forget
│   ├── index/               # user-invoked → /index
│   ├── search/              # user-invoked → /search
│   └── forget/              # user-invoked → /forget
└── README.md
```

## Install (user-wide `~/.claude.json`) — recommended for stable `LOGOSDB_PATH`

Store vectors under **`~/.claude/.logosdb`** (one tree for all projects) and register MCP once in your **user** config. Matches the usual Claude Code pattern: [MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp/) (stdio + `npx`).

1. **Merge** the `mcpServers` block from [`skills/semantic-memory/references/user-claude-json-logosdb.json`](skills/semantic-memory/references/user-claude-json-logosdb.json) into **`~/.claude.json`** (same key shape as other servers). It uses **`"LOGOSDB_PATH": "${HOME}/.claude/.logosdb"`** so the path is absolute after expansion. If your client does not expand **`${HOME}`**, replace it with an absolute path (e.g. **`/Users/you/.claude/.logosdb`**).

2. **Only one `logosdb` server:** if you use **`~/.claude.json`**, disable or uninstall this plugin’s MCP (or the whole plugin) so you do not register **`logosdb`** twice.

3. **CLI (optional):** some builds support adding stdio MCP from the shell, e.g. `claude mcp add` — run **`claude mcp --help`** for the exact subcommands on your version.

4. **If `npx` fails or exits oddly:** clear the ephemeral install cache, then retry ([common with `npx` + native deps](https://www.npmjs.com/package/logosdb-mcp-server)):

   ```bash
   rm -rf ~/.npm/_npx
   npm cache clean --force
   LOGOSDB_PATH="$HOME/.claude/.logosdb" npx -y logosdb-mcp-server
   ```

   (Stop with Ctrl+C once it is running.) Then restart Claude Code.

5. **Logs:** **`~/.claude/logs/mcp-server-*.log`** (names vary by build) for MCP spawn errors.

**Project-only DB** (per-repo `./.logosdb`): use [`skills/semantic-memory/references/project-mcp-fallback.json`](skills/semantic-memory/references/project-mcp-fallback.json) in **`.claude/mcp.json`** at the repo root instead — still only **one** active `logosdb` registration.

## Slash commands (skills format)

**`/index`** uses **`logosdb_index_file`** with **`incremental: true`** (new/changed files only; needs **`logosdb-mcp-server` ≥ 0.7.11**). With the plugin active, project **`CLAUDE.md`** should require the agent to run **`/index .`** on **every Claude session load** before other work (see [`skills/semantic-memory/SKILL.md`](skills/semantic-memory/SKILL.md) — Prerequisites plugin contract, §4c, §7 template). Hooks can enforce this if you need a guarantee beyond model instructions.

All three skills enforce **concise output** (one-line for `/index` and `/forget`; header + numbered file/score lines for `/search`) and tell the agent **not** to dump the raw MCP JSON or chunk text in its prose answer. Background `logosdb_search` calls (used during normal conversation) follow the same quiet rule. See [`skills/semantic-memory/SKILL.md` §7b](skills/semantic-memory/SKILL.md).

| Command | Skill |
|---------|--------|
| `/index` | [`skills/index/SKILL.md`](skills/index/SKILL.md) |
| `/search` | [`skills/search/SKILL.md`](skills/search/SKILL.md) |
| `/forget` | [`skills/forget/SKILL.md`](skills/forget/SKILL.md) |

## `CLAUDE.md` drop-in template

Paste the block from [`skills/semantic-memory/references/claude-md-template.md`](skills/semantic-memory/references/claude-md-template.md) into the project's **`CLAUDE.md`** to wire up: mandatory `/index .` at session start, the slash-command table, namespace conventions, quiet-mode guidance for background searches, and instructions for forcing a re-index when `incremental: true` reports `skipped_files`. The same block is reproduced inline in [`skills/semantic-memory/SKILL.md` §7](skills/semantic-memory/SKILL.md).

Optional project-only prompts (without the plugin): copy [`skills/semantic-memory/.claude/commands/`](skills/semantic-memory/.claude/commands/) into **`.claude/commands/`** (same idea as upstream LogosDB).

## Model-invoked guidance

[`skills/semantic-memory/SKILL.md`](skills/semantic-memory/SKILL.md) — routing, `CLAUDE.md` snippet, troubleshooting.

## Local development

```bash
cd /path/to/claude-code-semantic-memory
claude --plugin-dir .
```

Then **`/mcp`** or **`logosdb_list`** to confirm the server.

## License

MIT — see [LICENSE](LICENSE).
