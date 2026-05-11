---
name: semantic-memory
description: "Install LogosDB semantic memory via logosdb-mcp-server (MCP). Default: fully local Transformers.js embeddings (no API keys). Plugin ships slash commands /memory-index, /memory-search, /memory-forget (commands/ at repo root, same pattern as academic-research-skills). Requires .claude/mcp.json, .gitignore for LOGOSDB_PATH, verification, CLAUDE.md block. Optional project .claude/commands/ for /index, /search, /forget aliases. Triggers on: semantic memory, LogosDB, logosdb MCP, persistent memory, semantic-memory skill."
metadata:
  version: "0.1.5"
  last_updated: "2026-05-11"
  status: active
  data_access_level: raw
  task_type: outcome-gradable
---

# Semantic memory — LogosDB MCP

This skill walks through enabling **semantic, session-persistent memory** using the **LogosDB** MCP server published as [`logosdb-mcp-server`](https://www.npmjs.com/package/logosdb-mcp-server). Authoritative upstream docs: [LogosDB README — agent recipe](https://github.com/jose-compu/logosdb/blob/main/README.md#claude-code-complete-recipe) and [`mcp/README.md`](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md).

**Default behavior:** omit `EMBEDDING_PROVIDER` so the server uses **on-device Transformers.js** (`Xenova/all-MiniLM-L6-v2`, 384 dims). First run may download model weights to the normal Transformers.js cache. No cloud API keys are required for that path.

---

## Prerequisites

- **Node.js** 18+ and **`npm`** / **`npx`** on `PATH`.
- **Claude Code** installed and signed in.
- Open the **target repository** as the Claude Code project root (MCP child `cwd` is usually that root; relative paths in config resolve there).

---

## 1. Choose where vector data lives

- Environment variable **`LOGOSDB_PATH`** (default `./.logosdb`) is the on-disk root for namespaces.
- Add that directory to **`.gitignore`** if you do not want it committed (this repo’s `.gitignore` already lists `.logosdb/` as an example).

---

## 2. Install the MCP server (pick one)

**Recommended — published package, no project `package.json` required:**

```bash
npm view logosdb-mcp-server version
```

Claude Code will run the server via `npx` from `.claude/mcp.json` (next section). Optional local pin:

```bash
npm install logosdb-mcp-server
```

**Develop from a LogosDB git clone:** from the monorepo root run `npm install` so `mcp/dist/index.js` exists; point `mcp.json` at `node` + that script (see upstream README “Option A”).

---

## 3. Register MCP — `.claude/mcp.json`

At the **project root**, create or merge **`.claude/mcp.json`**. Use a single server name **`logosdb`**.

**Fully local embeddings (default):** no `EMBEDDING_PROVIDER`, only storage path:

```json
{
  "mcpServers": {
    "logosdb": {
      "command": "npx",
      "args": ["-y", "logosdb-mcp-server"],
      "env": {
        "LOGOSDB_PATH": "./.logosdb"
      }
    }
  }
}
```

**Notes:**

- User-wide config may live in **`~/.claude.json`** with the same `mcpServers` shape if you prefer one global definition.
- If the client’s cwd is **not** the project root, use **absolute** paths in `args` or in `LOGOSDB_PATH`.
- Optional backends (Ollama, OpenAI, Voyage) and tuning (`TRANSFORMERS_MODEL`, `LOGOSDB_CHUNK_SIZE`, `LOGOSDB_INDEX_ROOT`) are documented in upstream [`mcp/README.md` — Configure](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md#configure).

---

## 4. Path confinement (`logosdb_index_file`)

`logosdb_index_file` only accepts paths under **`process.cwd()`** or **`LOGOSDB_INDEX_ROOT`** (if set). Symlinks that escape those roots are rejected. Index paths inside the opened project, or set `LOGOSDB_INDEX_ROOT` to an absolute allowed root (see upstream [Path confinement](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md#path-confinement-logosdb_index_file)).

---

## 5. Restart and verify (MCP)

1. Restart Claude Code or reload MCP after editing `mcp.json`.
2. The **logosdb** server typically starts on **first tool use**.
3. Run **`logosdb_list`** from the agent (or use the MCP tools panel). Empty namespaces are fine; a spawn error is not.

**Smoke test in a shell** from the project root (same cwd Claude uses):

```bash
npx -y logosdb-mcp-server
```

(Exit with Ctrl+C after confirming it starts; stdio mode is normally driven by the client.)

---

## 6. Slash commands

### 6a. Plugin commands (**primary** — [academic-research-skills](https://github.com/Imbad0202/academic-research-skills) style)

This repository declares slash commands under repo-root **`commands/*.md`**. After **`/plugin install semantic-memory`**, Claude Code loads:

| File | Slash command |
|------|----------------|
| `commands/memory-index.md` | **`/memory-index`** |
| `commands/memory-search.md` | **`/memory-search`** |
| `commands/memory-forget.md` | **`/memory-forget`** |

Each file uses YAML frontmatter (`description`, `model: sonnet`) plus the same MCP wiring as LogosDB’s project prompts. **No manual copy** is required for these three when using the marketplace plugin.

**Verify:** reload the client; run **`/memory-search`** with a trivial query (empty namespace → “No matches…” is fine). Unknown command means the plugin is not installed or the client did not refresh.

### 6b. Project aliases (**optional**) — short names `/index`, `/search`, `/forget`

Claude Code also supports project-local **`.claude/commands/*.md`**. To match upstream [LogosDB](https://github.com/jose-compu/logosdb/tree/main/.claude/commands) filenames exactly, copy from this repo:

**Bundled copy:** `semantic-memory/.claude/commands/{index,search,forget}.md` → your project **`.claude/commands/`**.

```bash
SKILL_ROOT="/path/to/claude-code-semantic-memory/semantic-memory"
install -d .claude/commands
cp "$SKILL_ROOT/.claude/commands/"*.md .claude/commands/
```

---

## 7. `CLAUDE.md` — agent instructions (upstream template)

The MCP server does not index the repository by itself: **the agent must call the tools**, or the user may use **`/memory-index`**, **`/memory-search`**, **`/memory-forget`** (plugin), or **`/index`**, **`/search`**, **`/forget`** if you installed §6b. Add the following block to your project’s **`CLAUDE.md`** (or any instructions file your agent reads every session). Adjust namespaces and paths to your repo.

This text matches the **Agent instructions** section of the [LogosDB README](https://github.com/jose-compu/logosdb/blob/main/README.md#agent-instructions-claudemd-and-similar).

```markdown
## LogosDB (semantic memory via MCP)

The **logosdb** MCP server is configured. Data lives on disk under `LOGOSDB_PATH` (see `.claude/mcp.json`); it **persists across sessions**.

**Namespaces:** Use separate namespaces for different concerns (e.g. `code` for `src/`, `docs` for `docs/`, `decisions` for short architectural notes). Search only the namespace that matches the user's task.

**When starting substantive work on this codebase:**
1. If the user has not indexed recently and you need broad code context, call **`logosdb_index_file`** on the smallest useful path (e.g. `src/` or a package directory), not the whole monorepo unless asked.
2. Before answering "where is X implemented?" or similar, call **`logosdb_search`** with a tight natural-language `query`, `namespace` set appropriately, and `top_k` between **3** and **8**. Do not paste entire trees into the chat—retrieve, then read only the cited files.
3. For "what did we decide recently?" style questions, use **`logosdb_search`** with optional **`ts_from` / `ts_to`** (ISO 8601 inclusive bounds) on the `decisions` or `docs` namespace when timestamps matter.
4. When the user states a durable fact worth remembering (API contract, policy, workaround), call **`logosdb_index`** into the right namespace with concise text (timestamps are stored automatically; optional **`metadata`** can label the source).

**After large refactors or dependency upgrades:** Re-run **`logosdb_index_file`** on affected paths so search stays aligned with the tree.

**Deletion:** Use **`logosdb_delete`** with **`id`** from a prior search hit, or with **`query`** + optional **`match_rank`** / **`search_top_k`** to remove a semantically matched row when the user asks to forget something.
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

## 9. Troubleshooting (condensed from upstream)

| Symptom | Action |
|--------|--------|
| MCP fails to start / module not found | From project root run `npx -y logosdb-mcp-server` or `node` + your built `index.js`; fix Node version or paths. |
| `/memory-*` missing | Confirm `/plugin install semantic-memory` and reload; commands live in repo-root `commands/`. |
| `/index`, `/search`, `/forget` missing (optional aliases) | Copy `semantic-memory/.claude/commands/*.md` into the project’s `.claude/commands/` and reload. |
| `logosdb_index_file` rejects a path | Stay inside cwd or set `LOGOSDB_INDEX_ROOT`. |
| Search looks wrong after a model change | New embeddings need a fresh DB path or namespace; dimensions must match. |

---

## Trigger conditions

Use this skill when the user wants **LogosDB**, **logosdb MCP**, **semantic / persistent memory**, or **`semantic-memory`** setup (install, config, `CLAUDE.md`).

### Auto command routing (important)

When plugin commands are available, prefer these slash commands first:

- Use **`/memory-index`** when the user asks to index a path, ingest docs/code, refresh memory after changes, or build/update a namespace.
- Use **`/memory-search`** when the user asks where something is implemented, asks for similar content, prior decisions, or semantic lookup.
- Use **`/memory-forget`** when the user asks to delete memory, remove wrong/outdated entries, or forget a specific record/query match.

If commands are unavailable (or fail), call the equivalent MCP tools directly:

- `/memory-index` -> `logosdb_index_file`
- `/memory-search` -> `logosdb_search`
- `/memory-forget` -> `logosdb_delete`

Default namespace policy:

- Use `code` for source files and implementation lookup.
- Use `docs` for design notes and documentation.
- Use `decisions` for durable architecture/product decisions.
