---
name: semantic-memory
description: "LogosDB semantic memory via bundled MCP: scripts/logosdb-mcp-wrap.sh sets LOGOSDB_PATH from CLAUDE_PROJECT_DIR (fixes user-scope plugin cwd in cache). logosdb-mcp-server. User-invoked /index /search /forget. Triggers: semantic memory, LogosDB, logosdb MCP, semantic-memory plugin."
metadata:
  version: "0.2.4"
  last_updated: "2026-05-11"
  status: active
  data_access_level: raw
  task_type: outcome-gradable
---

# Semantic memory — LogosDB MCP (plugin)

This plugin ships the **logosdb** MCP server and guidance for **semantic, session-persistent memory** using [`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server). **`mcpServers`** live **inline in `.claude-plugin/plugin.json`** (and are mirrored in root **`.mcp.json`**). User-invoked slash skills use **`skills/<name>/SKILL.md`** per [example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin). Upstream: [LogosDB README](https://github.com/jose-compu/logosdb/blob/main/README.md#claude-code-complete-recipe), [`mcp/README.md`](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md).

**Default behavior:** omit `EMBEDDING_PROVIDER` so the server uses **on-device Transformers.js** (`Xenova/all-MiniLM-L6-v2`, 384 dims). First run may download model weights to the normal Transformers.js cache. No cloud API keys are required for that path.

---

## Prerequisites

- **Node.js** 18+ and **`npm`** / **`npx`** on `PATH`.
- **Claude Code** with plugins enabled.
- Open the **workspace / repository** you want to index; `logosdb_index_file` paths are confined to that cwd (see §4).

---

## 1. Where vector data lives (plugin default)

The MCP entrypoint is **`scripts/logosdb-mcp-wrap.sh`**, which:

1. **`cd`s into `CLAUDE_PROJECT_DIR`** when set (so **`process.cwd()`** matches your repo — required for **`logosdb_index_file`** path rules; see [claude-code#42687](https://github.com/anthropics/claude-code/issues/42687)).
2. Sets **`LOGOSDB_PATH`** to **`$CLAUDE_PROJECT_DIR/.logosdb`** (or **`$PWD/.logosdb`** if unset).

**Why a wrapper?** User-scoped plugins often started with cwd = **plugin cache**; both the vector root and indexable paths were wrong until **`CLAUDE_PROJECT_DIR`** + **`cd`**.

Add **`.logosdb/`** to your project **`.gitignore`** if you do not want vector files committed.

On startup the wrapper prints one diagnostic line to **stderr** (safe for MCP): `[semantic-memory plugin] LOGOSDB_PATH=...`. Use **`claude --debug`** (or your client’s MCP logs) if tools still do not appear.

---

## 2. MCP registration (built into the plugin)

You do **not** need a project **`.claude/mcp.json`** for the bundled server.

| File | Role |
|------|------|
| [`.claude-plugin/plugin.json`](../../.claude-plugin/plugin.json) | Plugin metadata + **`mcpServers.logosdb`**: `/bin/sh` + [`scripts/logosdb-mcp-wrap.sh`](../../scripts/logosdb-mcp-wrap.sh) → `npx -y logosdb-mcp-server` |
| [`.mcp.json`](../../.mcp.json) (repo root) | Same `mcpServers` block (mirror) |
| [`scripts/logosdb-mcp-wrap.sh`](../../scripts/logosdb-mcp-wrap.sh) | Sets **`LOGOSDB_PATH`**, logs to stderr, **`exec`** server (stdout reserved for MCP) |

**Avoid duplicates:** if the same workspace still defines **`logosdb`** in **`.claude/mcp.json`**, remove one registration or you may spawn two servers.

**Optional backends** (Ollama, OpenAI, Voyage) and tuning: upstream [`mcp/README.md` — Configure](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md#configure). Edits belong in this plugin’s `.mcp.json` (or your fork), not scattered per project.

---

## 3. Install / verify the published server (optional check)

```bash
npm view logosdb-mcp-server version
```

**Smoke test** (stdio normally driven by the client):

```bash
LOGOSDB_PATH=/tmp/logosdb-smoke-test npx -y logosdb-mcp-server
```

(Exit with Ctrl+C after it starts.)

---

## 4. Path confinement (`logosdb_index_file`)

`logosdb_index_file` only accepts paths under **`process.cwd()`** or **`LOGOSDB_INDEX_ROOT`** (if set). Symlinks that escape those roots are rejected. Index paths inside the opened project, or set `LOGOSDB_INDEX_ROOT` to an absolute allowed root (see upstream [Path confinement](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md#path-confinement-logosdb_index_file)).

---

## 5. Verify MCP after enabling the plugin

1. Install or enable **`semantic-memory`** (`/plugin install semantic-memory` or `claude --plugin-dir .` from this repo).
2. Run **`logosdb_list`** from the agent (or ** `/mcp`**). Empty namespaces are fine; a spawn error is not.

---

## 6. Slash commands (preferred: `skills/` layout)

Per [example-plugin README — Skills](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/example-plugin/README.md), user-invoked slash commands use **`skills/<name>/SKILL.md`** with frontmatter (`name`, `description`, `argument-hint`, optional `model`). This plugin registers:

| Skill directory | Slash command |
|-----------------|----------------|
| [`skills/index/SKILL.md`](../index/SKILL.md) | **`/index`** |
| [`skills/search/SKILL.md`](../search/SKILL.md) | **`/search`** |
| [`skills/forget/SKILL.md`](../forget/SKILL.md) | **`/forget`** |

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

## 7. `CLAUDE.md` — agent instructions (adapted)

The MCP server does not index the repository by itself: **call the tools**, or use plugin slash skills **`/index`**, **`/search`**, **`/forget`**. Add the following to the project’s **`CLAUDE.md`** (or equivalent). Adjust namespaces and paths.

```markdown
## LogosDB (semantic memory via MCP)

The **logosdb** MCP server is configured (this workspace uses the **semantic-memory** plugin). Vector data lives under **`LOGOSDB_PATH`** (default **`$CLAUDE_PROJECT_DIR/.logosdb`** when the wrapper runs under Claude Code — add **`.logosdb/`** to **`.gitignore`** if needed).

**Namespaces:** Use separate namespaces (e.g. `code` for `src/`, `docs` for `docs/`, `decisions` for short notes). Search the namespace that matches the task.

**When starting substantive work on this codebase:**
1. If you need broad code context, call **`logosdb_index_file`** on the smallest useful path (e.g. `src/`), or run **`/index`** with the same path — not the whole monorepo unless asked.
2. Before “where is X implemented?”, call **`logosdb_search`** or **`/search`** with a tight query, appropriate `namespace`, `top_k` **3–8**. Retrieve, then open only cited files.
3. For recent decisions, **`logosdb_search`** with optional **`ts_from` / `ts_to`** on `decisions` or `docs` when timestamps matter.
4. For durable facts, **`logosdb_index`** (or document via **`/index`** flows) into the right namespace.

**After large refactors:** re-index affected paths.

**Deletion:** **`logosdb_delete`** or **`/forget`** by `id` or semantic `query`.
```

---

## 8. MCP tools (summary)

| Tool | Role |
|------|------|
| `logosdb_index` | Store a short text snippet in a namespace |
| `logosdb_index_file` | Chunk, embed, and store a file or directory tree |
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

---

## Trigger conditions

Use this skill for **LogosDB**, **logosdb MCP**, **semantic / persistent memory**, or **`semantic-memory`** plugin behavior (MCP, slash commands, `CLAUDE.md`).

### Auto command routing (important)

Prefer slash commands when available:

- **`/index`** — index paths, refresh memory after changes, new namespace.
- **`/search`** — semantic lookup, “where is X”, prior decisions.
- **`/forget`** — delete by id or semantic query.

Fallback MCP tools: `logosdb_index_file`, `logosdb_search`, `logosdb_delete`.

**Default namespaces:** `code` (source), `docs` (documentation), `decisions` (durable decisions).
