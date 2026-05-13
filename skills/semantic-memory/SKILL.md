---
name: semantic-memory
description: "LogosDB semantic memory plugin: MCP wrap.sh, incremental /index (mcp ≥0.7.11; ≥0.7.12 if client shows 0 tools). Instructions require /index . on every Claude session load when plugin is active. Triggers: semantic memory, LogosDB, logosdb MCP, semantic-memory plugin."
metadata:
  version: "0.2.9"
  last_updated: "2026-05-13"
  status: active
  data_access_level: raw
  task_type: outcome-gradable
---

# Semantic memory — LogosDB MCP (plugin)

This plugin ships the **logosdb** MCP server and guidance for **semantic, session-persistent memory** using [`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server). **`mcpServers`** are declared in **`.claude-plugin/plugin.json`** (mirrored in **`.mcp.json`**) per [Claude Code MCP — plugins](https://docs.anthropic.com/en/docs/claude-code/mcp/) (stdio `command` + `args`, typically `npx` + `-y`). This repo uses a small **shell launcher** so **`CLAUDE_PROJECT_DIR`**, **`LOGOSDB_PATH`**, and **`LOGOSDB_INDEX_ROOT`** behave for [user-scoped plugins](https://github.com/anthropics/claude-code/issues/42687). Slash skills: **`skills/<name>/SKILL.md`** ([example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin)). Upstream: [LogosDB README](https://github.com/jose-compu/logosdb/blob/main/README.md#claude-code-complete-recipe), [`mcp/README.md`](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md).

**Default behavior:** omit `EMBEDDING_PROVIDER` so the server uses **on-device Transformers.js** (`Xenova/all-MiniLM-L6-v2`, 384 dims). First run may download model weights to the normal Transformers.js cache. No cloud API keys are required for that path.

---

## Prerequisites

- **Node.js** 18+ and **`npm`** / **`npx`** on `PATH`.
- **Claude Code** with plugins enabled.
- Open the **workspace / repository** you want to index; `logosdb_index_file` paths are confined to that cwd (see §4).

**Plugin contract (agent):** whenever the **semantic-memory** plugin is **active** for this workspace, treat **session start** (first turn after Claude loads the project) as requiring **`/index .`** — i.e. run **`logosdb_index_file`** on **`path: "."`**, **`incremental: true`**, default **`namespace: "code"`** (or the namespace your project’s **`CLAUDE.md`** defines), **before** other substantive tool work. **`"."`** is the project cwd after the wrapper **`cd`**. Incremental runs are cheap when nothing changed. This is **instructional** (the model must do it); for a **hard guarantee**, use [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks-guide) (e.g. **`SessionStart`**) to invoke indexing. Projects may opt out by stating that in **`CLAUDE.md`**.

---

## 1. Where vector data lives (plugin default)

The MCP entrypoint is **`scripts/logosdb-mcp-wrap.sh`**, which:

1. **`cd`s into `CLAUDE_PROJECT_DIR`** when it is set **and** a directory (so **`process.cwd()`** is your repo — see [claude-code#42687](https://github.com/anthropics/claude-code/issues/42687)).
2. Sets **`LOGOSDB_PATH`** (default **`$CLAUDE_PROJECT_DIR/.logosdb`**).
3. Sets **`LOGOSDB_INDEX_ROOT`** to the same project root so **`logosdb_index_file`** can allow project paths even if cwd handling regresses ([`security.ts` indexRoots](https://github.com/jose-compu/logosdb/blob/main/mcp/src/security.ts)).
4. Runs **`npm exec --yes -- logosdb-mcp-server`** when available, else **`npx --yes logosdb-mcp-server`**, with quieter npm env to reduce **`npx` cache / cleanup** noise.

**Why a wrapper?** Matches the problem people hit with **plugin MCP + `npx`**: wrong cwd, missing tools, and occasional **`npm warn cleanup`** / non-zero exits from the **npm** driver (not always the server itself). **`claude --debug`** helps distinguish spawn vs protocol errors.

Add **`.logosdb/`** to your project **`.gitignore`** if you do not want vector files committed.

**User-wide store:** merge [references/user-claude-json-logosdb.json](references/user-claude-json-logosdb.json) into **`~/.claude.json`** (**`LOGOSDB_PATH`** = **`${HOME}/.claude/.logosdb`**) and disable this plugin’s MCP so **`logosdb`** is registered only once.

On startup the wrapper prints one diagnostic line to **stderr** (safe for MCP): `[semantic-memory plugin] LOGOSDB_PATH=...`. Use **`claude --debug`** (or your client’s MCP logs) if tools still do not appear.

---

## 2. MCP registration (built into the plugin)

You do **not** need a project **`.claude/mcp.json`** for the bundled server.

| File | Role |
|------|------|
| [`.claude-plugin/plugin.json`](../../.claude-plugin/plugin.json) | Plugin metadata + **`mcpServers.logosdb`**: `/bin/sh` + [`scripts/logosdb-mcp-wrap.sh`](../../scripts/logosdb-mcp-wrap.sh) |
| [`.mcp.json`](../../.mcp.json) (repo root) | Same `mcpServers` block (mirror) |
| [`scripts/logosdb-mcp-wrap.sh`](../../scripts/logosdb-mcp-wrap.sh) | `cd` + **`LOGOSDB_PATH`** + **`LOGOSDB_INDEX_ROOT`** + `npm exec` / `npx` |

**Avoid duplicates:** register **`logosdb` exactly once**. Pick one: (a) this plugin’s MCP, (b) user **`~/.claude.json`** — see [references/user-claude-json-logosdb.json](references/user-claude-json-logosdb.json) (**`LOGOSDB_PATH`** = **`${HOME}/.claude/.logosdb`**), or (c) project [references/project-mcp-fallback.json](references/project-mcp-fallback.json). Disable the plugin if you use (b) or (c).

**Official pattern (reference):** plain stdio block is `command` + `args` — see [Anthropic `server-types.md` (stdio)](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/mcp-integration/references/server-types.md) and [Connect Claude Code to tools via MCP](https://docs.anthropic.com/en/docs/claude-code/mcp/).

**Optional backends** (Ollama, OpenAI, Voyage) and tuning: upstream [`mcp/README.md` — Configure](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md#configure). Edits belong in this plugin’s `.mcp.json` (or your fork), not scattered per project.

---

## 3. Install / verify the published server (optional check)

```bash
npm view logosdb-mcp-server version
```

**Smoke test** (stdio is driven by the client; here you only check the process stays up):

```bash
LOGOSDB_PATH=/tmp/logosdb-smoke-test npx --yes logosdb-mcp-server </dev/null &
sleep 3
kill %1 2>/dev/null
```

On macOS, **`timeout`** may be missing; use **`sleep` + `kill`** as above. **`npm warn cleanup`** lines often come from **npm** tearing down a temp **`npx`** tree and do **not** always mean the MCP server crashed (check whether **`logosdb_list`** appears in Claude after **`/reload-plugins`**).

---

## 4. Path confinement (`logosdb_index_file`)

`logosdb_index_file` only accepts paths under **`process.cwd()`** or **`LOGOSDB_INDEX_ROOT`** (if set). Symlinks that escape those roots are rejected. Index paths inside the opened project, or set `LOGOSDB_INDEX_ROOT` to an absolute allowed root (see upstream [Path confinement](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md#path-confinement-logosdb_index_file)).

---

## 4b. Native `logosdb` (npm) vs MCP `logosdb-mcp-server`

| Piece | Role |
|-------|------|
| **[`logosdb`](https://www.npmjs.com/package/logosdb)** (Node native addon) | Vector store: **`put`**, **`search`**, **`delete`**, etc. Pulled in as a **dependency** of **`logosdb-mcp-server`**. Version is whatever the published MCP package declares (e.g. **`^0.7.10`**). |
| **[`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server)** | MCP process: **`logosdb_index_file`**, **`logosdb_search`**, **`logosdb_list`**, … **Incremental file indexing** (`incremental: true`, default for **`/index`**) is implemented **here** (manifest under **`LOGOSDB_PATH/_logosdb_mcp_manifests/`**), not inside the native addon. Use **≥ 0.7.11** for incremental (`npm view logosdb-mcp-server version`). **≥ 0.7.12** loads the native addon lazily so a missing **`logosdb`** prebuild no longer prevents **`tools/list`** from returning tools (first index/search still requires a working native install). |

**Why it feels fast:** with **`incremental: true`**, only **new or changed** files under the path are embedded again; unchanged files are skipped and changed files have their old chunk rows removed first ([upstream CHANGELOG 0.7.11](https://github.com/jose-compu/logosdb/blob/main/CHANGELOG)). Cost is still **O(changed files)** for disk + **O(changed chunks)** for the embedding model — not zero, but far less than a full tree re-index.

---

## 4c. When to re-index — agent behavior

Claude Code **does not** run filesystem watchers for skills. **You** (the agent) must follow this cadence when **semantic-memory** is active:

1. **Every Claude session / load (mandatory):** run **`/index .`** (or equivalent **`logosdb_index_file`** with **`path: "."`**, **`incremental: true`**, default **`namespace: "code"`**) as the **first** indexing step after the workspace is available. This refreshes the **whole tree under cwd** incrementally; most files should show **`skipped_files`** if unchanged. If the repo is enormous and **`CLAUDE.md`** narrows the policy (e.g. only **`./src`**), use that path instead of **`.`** — but the default plugin instruction is **`/index .`**.
2. **After the user (or you) edits multiple files** in a subtree: run **`/index <subpath>`** or **`logosdb_index_file`** with **`incremental: true`** on that subtree.
3. **Before a broad `logosdb_search`** when the conversation implies files changed since the last index (merge, pull, refactor): optional quick incremental pass on the affected path.

Do **not** spam full non-incremental re-indexes of huge trees every turn — use **`incremental: true`** ( **`/index`** already does).

Optional automation outside skills: [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks-guide) (e.g. react to **`FileChanged`**) can run a script that calls **`logosdb_index_file`** with **`incremental: true`** on a configured subtree; keep **`LOGOSDB_PATH`** private to the project.

---

## 5. Verify MCP after enabling the plugin

1. Install or enable **`semantic-memory`** (`/plugin install semantic-memory` or `claude --plugin-dir .` from this repo).
2. Run **`logosdb_list`** from the agent (or **`/mcp`**). Empty namespaces are fine; a spawn error is not.
3. Confirm **`/index .`** works once (incremental); add the §7 **`CLAUDE.md`** block to the project so **every session** starts with that pass.

**If the UI says the MCP server connected but registered 0 tools (older `logosdb-mcp-server`):** the subprocess often **exited during import** because the **`logosdb`** native addon failed to install (missing N-API prebuild for your OS/arch, or **`npm install`** inside **`npx`** did not produce **`logosdb.node`**). Use the **same `node`** Claude uses and run:

```bash
# Resolves `logosdb` the same way as `npx logosdb-mcp-server` (sibling in the temp install tree)
npx --yes -p logosdb-mcp-server node -e "require('logosdb'); console.log('logosdb native OK')"
```

If that throws, fix the native install (Node **20 LTS** vs bleeding-edge **22**, reinstall, or build from source per [LogosDB `nodejs/README.md`](https://github.com/jose-compu/logosdb/blob/main/nodejs/README.md)), then **`/reload-plugins`**. After **`logosdb-mcp-server` ≥ 0.7.12** is published and picked up by **`npx`**, tools should list even when native is broken; tool calls will then return a clear error until native loads.

---

## 6. Slash commands (preferred: `skills/` layout)

Per [example-plugin README — Skills](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/example-plugin/README.md), user-invoked slash commands use **`skills/<name>/SKILL.md`** with frontmatter (`name`, `description`, `argument-hint`, optional `model`). This plugin registers:

| Skill directory | Slash command |
|-----------------|----------------|
| [`skills/index/SKILL.md`](../index/SKILL.md) | **`/index`** (top-level skill name **`index`**) |
| [`skills/search/SKILL.md`](../search/SKILL.md) | **`/search`** |
| [`skills/forget/SKILL.md`](../forget/SKILL.md) | **`/forget`** |

Some Claude Code builds also expose the copies under **[`skills/semantic-memory/.claude/commands/`](../semantic-memory/.claude/commands/index.md)** as **`/semantic-memory:index`** (and similarly **`…:search`** / **`…:forget`**). Those prompts call the **same** MCP tools (**`logosdb_index_file`**, **`logosdb_search`**, **`logosdb_delete`**); naming is client UI only, not the MCP contract.

Legacy repo-root **`commands/*.md`** is **not** used here (see [`commands/README.md`](../../commands/README.md) in this repo).

**Verify:** **`/search`** with a trivial query (empty namespace → “No matches…” is fine).

### 6b. Project-only prompts (optional)

If the plugin is **not** loaded but you still want **`/index`**, **`/search`**, **`/forget`** from markdown prompts, copy **`skills/semantic-memory/.claude/commands/{index,search,forget}.md`** into your project **`.claude/commands/`** (same filenames as upstream [LogosDB](https://github.com/jose-compu/logosdb/tree/main/.claude/commands)). When the plugin **is** active, prefer the plugin skills above to avoid duplicate slash definitions.

```bash
PLUGIN_ROOT="/path/to/claude-code-semantic-memory"
install -d .claude/commands
cp "$PLUGIN_ROOT/skills/semantic-memory/.claude/commands/"*.md .claude/commands/
```

---

## 7. `CLAUDE.md` — drop-in template

The MCP server does not index the repository by itself: **call the tools**, or use the plugin slash skills **`/index`**, **`/search`**, **`/forget`**. A ready-to-paste block lives at **[`references/claude-md-template.md`](references/claude-md-template.md)** — copy everything between the `BEGIN`/`END` markers into the project's **`CLAUDE.md`**. Verbatim copy:

```markdown
## Semantic Memory (LogosDB)

The **semantic-memory** plugin is active for this workspace. Vector data lives in `.logosdb/` (git-ignored). The plugin provides three slash commands that work without any extra setup.

### Session start — mandatory

**Run `/index .` at the start of every session** before doing other work. This incrementally refreshes the full index (only changed/new files are re-embedded; unchanged files are skipped, so it is fast).

\`\`\`text
/index .
\`\`\`

### Slash commands

| Command | What it does |
|---------|--------------|
| `/index <path>` | Index or re-index a file or directory (incremental by default). Use `.` for the whole project, or a subdirectory/file for targeted refresh. |
| `/search <query>` | Semantic search over indexed content. Returns ranked file matches. Accepts `--top-k=n` (default 5), `--namespace=name` (default `code`), and optional ISO timestamp bounds (`--from-ts`, `--to-ts`). |
| `/forget <query or --id=n>` | Delete indexed chunks by semantic query match or by row id. |

### Namespaces

- **`code`** (default) — source files and general project content
- `docs` — documentation-only searches (`--namespace=docs` / `-n docs`)
- `decisions` — durable architectural or research notes

### Conversational / background use (keep output quiet)

When you (the agent) call `logosdb_search` directly during normal conversation — not via `/search` — keep `top_k` 3–5, cite source files briefly (e.g. `src/foo.ts`), and **do not quote the full chunk text** in the final answer.

### When to re-index

- After pulling / merging changes: `/index .`
- After editing a specific file: `/index <file>`
- Before a broad search when files may have changed since last index

### Forcing a re-index

`/index` is incremental, so unchanged files are skipped (`skipped_files: 1, indexed_files: 0` is a cache hit, not an error). To force a rebuild: `touch <file>` then `/index <file>`, or delete `.logosdb/<namespace>/` and `.logosdb/_logosdb_mcp_manifests/<namespace>.json` and re-index.

### Opting out of auto-index

If the repo is very large, replace `/index .` above with a narrower path (e.g. `/index ./src`) and document the choice here.
```

---

## 7b. Quiet / less-verbose output

The Claude Code TUI auto-renders every MCP tool call as a JSON box; that rendering is client-side and the plugin cannot suppress it. What the plugin **does** control is the assistant's prose response. The skills enforce concise output:

- **`/index`** — exactly one line: `Indexed {indexed} chunks · {indexed_files} updated · {skipped_files} skipped · {pruned_files} pruned → '{namespace}'`.
- **`/search`** — one header line + numbered `path (score: …)` lines. **No** chunk text, **no** raw JSON.
- **`/forget`** — exactly one line: `Deleted id {id} …`.
- **Background `logosdb_search` (no slash command)** — `top_k` 3–5; the assistant cites file paths and paraphrases instead of quoting chunks.

If the JSON tool-call box itself is still too noisy, lower `top_k` (each chunk in the result inflates the box). For headless / scripting use, `claude --output-format text` and `--quiet` reduce surrounding chatter; check `claude --help` on your build for the exact flags.

---

## 8. MCP tools (summary)

| Tool | Role |
|------|------|
| `logosdb_index` | Store a short text snippet in a namespace |
| `logosdb_index_file` | Chunk, embed, and store a file or directory tree; use **`incremental: true`** for fast refresh (skip unchanged files; MCP ≥ **0.7.11**) |
| `logosdb_search` | Semantic search; optional `ts_from` / `ts_to` |
| `logosdb_list` | List namespaces |
| `logosdb_info` | Stats for a namespace |
| `logosdb_delete` | Delete by row `id` or by natural-language `query` |

Use **one embedding backend and dimension** per namespace on disk; when changing models, use a fresh `LOGOSDB_PATH` or new namespace.

---

## 9. Troubleshooting

| Symptom | Action |
|--------|--------|
| MCP fails to start / no **`logosdb_*`** tools | Update Claude Code (needs **`CLAUDE_PROJECT_DIR`** for plugin MCP, [claude-code#42687](https://github.com/anthropics/claude-code/issues/42687)); or install plugin **`--scope project`**. Check stderr for `[semantic-memory plugin]` line; run `claude --debug`. |
| `npx` / native addon errors | From a terminal: `LOGOSDB_PATH=/tmp/t npx -y logosdb-mcp-server` — fix Node, network, or `logosdb` wheel install. |
| Two **logosdb** servers / flaky tools | Remove duplicate **`logosdb`** from project **`.claude/mcp.json`** if the plugin already supplies it. |
| **`/index`**, **`/search`**, **`/forget`** missing | Confirm plugin enabled; reload; definitions live under **`skills/index`**, **`skills/search`**, **`skills/forget`**. |
| Project-only prompts wanted | Copy **`skills/semantic-memory/.claude/commands/*.md`** to **`.claude/commands/`** (§6b). |
| `logosdb_index_file` rejects a path | Stay inside cwd or set **`LOGOSDB_INDEX_ROOT`**. |
| Search wrong after model change | New embeddings need a fresh **`LOGOSDB_PATH`** or namespace. |
| **`incremental` not accepted / ignored** | Upgrade **`logosdb-mcp-server`** to **≥ 0.7.11** (`npm view logosdb-mcp-server version`); the native **`logosdb`** package version comes transitively from that release. |

---

## Trigger conditions

Use this skill for **LogosDB**, **logosdb MCP**, **semantic / persistent memory**, or **`semantic-memory`** plugin behavior (MCP, slash commands, `CLAUDE.md`).

### Auto command routing (important)

Prefer slash commands when available:

- **`/index`** — **First on each session:** **`/index .`** when **semantic-memory** is active (then narrower paths as needed). Always **`incremental: true`** (cheap when little changed).
- **`/search`** — semantic lookup, “where is X”, prior decisions.
- **`/forget`** — delete by id or semantic query.

Fallback MCP tools: `logosdb_index_file`, `logosdb_search`, `logosdb_delete`.

**Default namespaces:** `code` (source), `docs` (documentation), `decisions` (durable decisions).
