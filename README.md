# claude-code-semantic-memory

Claude Code **plugin** with bundled **LogosDB** MCP ([`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server)), local embeddings by default, and slash-invoked skills.

Structure follows Anthropic’s **[example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin)** ([README](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/example-plugin/README.md)): `.claude-plugin/plugin.json`, root **`.mcp.json`**, and **`skills/*/SKILL.md`** (preferred over legacy `commands/*.md`).

## Install (plugin)

```text
/plugin marketplace add jose-compu/claude-code-semantic-memory
/plugin install semantic-memory
```

MCP **`logosdb`** runs **`/bin/sh`** + **`scripts/logosdb-mcp-wrap.sh`** (see **`.claude-plugin/plugin.json`**, mirrored in **`.mcp.json`**). Wrapper sets **`LOGOSDB_PATH`**, **`LOGOSDB_INDEX_ROOT`**, and **`cd`** from **`CLAUDE_PROJECT_DIR`** when present ([claude-code#42687](https://github.com/anthropics/claude-code/issues/42687)). **`claude --debug`** if tools are missing.

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

| Command | Skill |
|---------|--------|
| `/index` | [`skills/index/SKILL.md`](skills/index/SKILL.md) |
| `/search` | [`skills/search/SKILL.md`](skills/search/SKILL.md) |
| `/forget` | [`skills/forget/SKILL.md`](skills/forget/SKILL.md) |

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
