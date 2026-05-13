<!--
Drop-in snippet for a project's CLAUDE.md when the `semantic-memory` plugin is
installed. Paste the block below (between the BEGIN/END markers) into the
project CLAUDE.md and adjust paths/namespaces if needed.
-->

<!-- BEGIN: semantic-memory plugin CLAUDE.md block -->

## Semantic Memory (LogosDB)

The **semantic-memory** plugin is active for this workspace. Vector data lives in `.logosdb/` (git-ignored). The plugin provides three slash commands that work without any extra setup.

### Session start — mandatory

**Run `/index .` at the start of every session** before doing other work. This incrementally refreshes the full index (only changed/new files are re-embedded; unchanged files are skipped, so it is fast).

```text
/index .
```

### Slash commands

| Command | What it does |
|---------|--------------|
| `/index <path>` | Index or re-index a file or directory (incremental by default). Use `.` for the whole project, or a subdirectory/file for targeted refresh. |
| `/search <query>` | Semantic search over indexed content. Returns ranked file matches. Accepts `--top-k=n` (default 5), `--namespace=name` (default `code`), and optional ISO timestamp bounds (`--from-ts`, `--to-ts`). |
| `/forget <query or --id=n>` | Delete indexed chunks by semantic query match or by row id. Use to remove stale or unwanted content from the index. |

### Namespaces

- **`code`** (default) — source files and general project content
- Use `--namespace=docs` or `-n docs` for documentation-only searches
- Use `--namespace=decisions` for durable architectural or research notes

### Conversational / background use (keep output quiet)

When you (the agent) call `logosdb_search` directly during normal conversation — not via `/search` — keep the call cheap and the prose tight:

- Use `top_k` 3–5 (rarely more than 8).
- In your final answer, **do not quote the full chunk text** returned by the tool. Cite source files briefly (e.g. `src/foo.ts:42`) and paraphrase.
- Prefer a single search per question; refine the query rather than fanning out.

When the user asks a question that is clearly memory-driven (e.g. “where is X?”, “what did we decide about Y?”), it is OK to silently call `logosdb_search` and answer in prose without explaining the retrieval.

### When to re-index

- After pulling / merging changes: `/index .`
- After editing a specific file: `/index <file>`
- Before a broad search when files may have changed since last index

### Forcing a re-index (`incremental` is doing its job)

`/index` runs with `incremental: true`, so files whose `mtime + size + chunk_size` match the per-namespace manifest are skipped (`skipped_files: 1, indexed_files: 0`). That is the cache hit, not an error. To force a rebuild:

- `touch <file>` then `/index <file>` (bumps mtime), **or**
- `/forget --query="…"` to drop specific entries, **or**
- delete the namespace directory under `.logosdb/<namespace>/` and the manifest at `.logosdb/_logosdb_mcp_manifests/<namespace>.json`, then `/index .` again.

### Opting out of auto-index

If the repo grows very large and `.` is too slow, replace `/index .` in the session-start instruction above with a narrower path (e.g. `/index ./src`) and document that here.

<!-- END: semantic-memory plugin CLAUDE.md block -->
