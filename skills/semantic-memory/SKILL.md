---
name: semantic-memory
description: "LogosDB semantic memory via bundled MCP (root .mcp.json + plugin.json mcpServers). logosdb-mcp-server, local Transformers.js by default. User-invoked slash skills /memory-index /memory-search /memory-forget live under skills/<name>/SKILL.md (Anthropic example-plugin pattern). Optional project .claude/commands/ for /index aliases. Triggers: semantic memory, LogosDB, logosdb MCP, persistent memory, semantic-memory plugin."
metadata:
  version: "0.2.1"
  last_updated: "2026-05-11"
  status: active
  data_access_level: raw
  task_type: outcome-gradable
---

# Semantic memory — LogosDB MCP (plugin)

This plugin ships the **logosdb** MCP server and guidance for **semantic, session-persistent memory** using [`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server). Layout matches Anthropic’s [example-plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/example-plugin): root **`.mcp.json`**, **`plugin.json`** with **`mcpServers`**, and **user-invoked slash commands** as **`skills/<name>/SKILL.md`** (not legacy `commands/*.md`). Upstream reference: [LogosDB README](https://github.com/jose-compu/logosdb/blob/main/README.md#claude-code-complete-recipe), [`mcp/README.md`](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md).

**Default behavior:** omit `EMBEDDING_PROVIDER` so the server uses **on-device Transformers.js** (`Xenova/all-MiniLM-L6-v2`, 384 dims). First run may download model weights to the normal Transformers.js cache. No cloud API keys are required for that path.

---

## Prerequisites

- **Node.js** 18+ and **`npm`** / **`npx`** on `PATH`.
- **Claude Code** with plugins enabled.
- Open the **workspace / repository** you want to index; `logosdb_index_file` paths are confined to that cwd (see §4).

---

## 1. Where vector data lives (plugin default)

This plugin’s **`.mcp.json`** sets:

- **`LOGOSDB_PATH`** = **`${CLAUDE_PLUGIN_DATA}/.logosdb`**

That directory is **writable plugin data** (not inside your git checkout). You do **not** need a repo `.gitignore` entry for it unless you point `LOGOSDB_PATH` at a path inside the project.

To store vectors **inside the repo** (e.g. `./.logosdb`), override MCP env in your client or fork the plugin’s `.mcp.json` / `plugin.json` merge strategy — then add `.logosdb/` to **`.gitignore`**.

---

## 2. MCP registration (built into the plugin)

You do **not** need a project **`.claude/mcp.json`** for the bundled server.

| File | Role |
|------|------|
| [`.mcp.json`](../../.mcp.json) (repo root) | Defines `mcpServers.logosdb` (`npx` + `logosdb-mcp-server` + env) |
| [`.claude-plugin/plugin.json`](../../.claude-plugin/plugin.json) | Plugin metadata + **`"mcpServers": "./.mcp.json"`** so Claude loads servers with the plugin |

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
| [`skills/memory-index/SKILL.md`](../memory-index/SKILL.md) | **`/memory-index`** |
| [`skills/memory-search/SKILL.md`](../memory-search/SKILL.md) | **`/memory-search`** |
| [`skills/memory-forget/SKILL.md`](../memory-forget/SKILL.md) | **`/memory-forget`** |

Legacy repo-root **`commands/*.md`** is **not** used here (see [`commands/README.md`](../../commands/README.md) in this repo).

**Verify:** **`/memory-search`** with a trivial query (empty namespace → “No matches…” is fine).

### 6b. Project aliases (optional) — `/index`, `/search`, `/forget`

Copy **`skills/semantic-memory/.claude/commands/{index,search,forget}.md`** into your project **`.claude/commands/`**:

```bash
PLUGIN_ROOT="/path/to/claude-code-semantic-memory"
install -d .claude/commands
cp "$PLUGIN_ROOT/skills/semantic-memory/.claude/commands/"*.md .claude/commands/
```

---

## 7. `CLAUDE.md` — agent instructions (adapted)

The MCP server does not index the repository by itself: **call the tools**, or use **`/memory-index`**, **`/memory-search`**, **`/memory-forget`** (plugin), or **`/index`**, **`/search`**, **`/forget`** if you installed §6b. Add the following to the project’s **`CLAUDE.md`** (or equivalent). Adjust namespaces and paths.

```markdown
## LogosDB (semantic memory via MCP)

The **logosdb** MCP server is configured (this workspace uses the **semantic-memory** plugin). Vector data lives under **`LOGOSDB_PATH`** (plugin default: plugin data dir via `${CLAUDE_PLUGIN_DATA}/.logosdb` — not committed to your repo unless you override).

**Namespaces:** Use separate namespaces (e.g. `code` for `src/`, `docs` for `docs/`, `decisions` for short notes). Search the namespace that matches the task.

**When starting substantive work on this codebase:**
1. If you need broad code context, call **`logosdb_index_file`** on the smallest useful path (e.g. `src/`), or run **`/memory-index`** with the same path — not the whole monorepo unless asked.
2. Before “where is X implemented?”, call **`logosdb_search`** or **`/memory-search`** with a tight query, appropriate `namespace`, `top_k` **3–8**. Retrieve, then open only cited files.
3. For recent decisions, **`logosdb_search`** with optional **`ts_from` / `ts_to`** on `decisions` or `docs` when timestamps matter.
4. For durable facts, **`logosdb_index`** (or document via **`/memory-index`** flows) into the right namespace.

**After large refactors:** re-index affected paths.

**Deletion:** **`logosdb_delete`** or **`/memory-forget`** by `id` or semantic `query`.
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
| MCP fails to start / module not found | Run `npx -y logosdb-mcp-server` with a temp `LOGOSDB_PATH`; fix Node / network. |
| Two **logosdb** servers / flaky tools | Remove duplicate **`logosdb`** from project **`.claude/mcp.json`** if the plugin already supplies it. |
| `/memory-*` missing | Confirm plugin enabled; reload; definitions live under **`skills/memory-*/SKILL.md`**. |
| `/index` etc. missing | Copy **`skills/semantic-memory/.claude/commands/*.md`** to project **`.claude/commands/`**. |
| `logosdb_index_file` rejects a path | Stay inside cwd or set **`LOGOSDB_INDEX_ROOT`**. |
| Search wrong after model change | New embeddings need a fresh **`LOGOSDB_PATH`** or namespace. |

---

## Trigger conditions

Use this skill for **LogosDB**, **logosdb MCP**, **semantic / persistent memory**, or **`semantic-memory`** plugin behavior (MCP, slash commands, `CLAUDE.md`).

### Auto command routing (important)

Prefer slash commands when available:

- **`/memory-index`** — index paths, refresh memory after changes, new namespace.
- **`/memory-search`** — semantic lookup, “where is X”, prior decisions.
- **`/memory-forget`** — delete by id or semantic query.

Fallback MCP tools: `logosdb_index_file`, `logosdb_search`, `logosdb_delete`.

**Default namespaces:** `code` (source), `docs` (documentation), `decisions` (durable decisions).
