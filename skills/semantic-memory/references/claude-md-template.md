<!--
Drop-in snippet for a project's CLAUDE.md when the `semantic-memory` plugin is
installed. Paste the block below (between the BEGIN/END markers) into the
project CLAUDE.md and adjust paths/namespaces if needed.
-->

<!-- BEGIN: semantic-memory plugin CLAUDE.md block -->

## Semantic Memory (LogosDB)

The **semantic-memory** plugin is active. It provides seamless, session-persistent memory backed by a local vector store. **All automatic operations are completely silent — never announce them to the user.**

**DB location (global mode, default):** `~/.claude/.logosdb` — shared across all sessions and projects.  
**DB location (project mode):** `.logosdb/` inside this project (set `LOGOS_MEMORY_MODE=project`).

### UX contract — silence is mandatory

| Operation | What to do | What NOT to do |
|-----------|-----------|----------------|
| Session-start index | Run silently | Never say "Indexing…", "Index complete", or print the result |
| Session-start search | Call `logosdb_search` silently, use context naturally | Never say "Searching past sessions…" or "I found N memories" |
| Per-turn memory store | Call `logosdb_index` silently | Never say "Remembered", "Memory updated", or confirm the store |
| Per-turn re-index | Call `logosdb_index_file` silently | No output at all |
| Background search | Use findings in prose naturally | Never quote raw chunk text; cite only file paths when helpful |

Slash commands (`/index`, `/search`, `/forget`, `/remember`) are the one visible exception: respond with exactly one concise line. Nothing else.

### Session start — mandatory (silent)

At the **start of every session**, before other work, do both steps with **no output**:

1. Refresh the source index:
   ```
   logosdb_index_file(path=".", incremental=true, namespace="code")
   ```

2. Search past sessions for relevant context:
   ```
   logosdb_search(query="<first user message or session intent>", namespace="global", top_k=5)
   ```
   Incorporate any relevant memories naturally into your first response. Do not mention the search.

### After each substantive response — automatic turn memory (silent)

After producing a meaningful answer (architecture question, debugging outcome, decision, explanation), **silently** store a compact record with **no output or confirmation**:

```
logosdb_index(
  text="[YYYY-MM-DD HH:MM] <project-basename>
Q: <user question ≤300 chars>
[<thinking summary if extended thinking was active, wrapped in <thinking>…</thinking>>]
A: <answer summary ≤500 chars>",
  namespace="global"
)
```

**When thinking is active:** summarize your reasoning chain (key steps, ≤ 400 chars) and include it between `<thinking>…</thinking>` tags. **Skip** trivial confirmations and pure file edits with no reasoning content.

### Slash commands

| Command | What it does |
|---------|--------------|
| `/index <path>` | Index or re-index a file or directory (incremental). Use `.` for the whole project. |
| `/search <query>` | Semantic search. Default namespace `code`. Use `--namespace=global` for cross-session memories. |
| `/forget <query or --id=n>` | Delete indexed chunks by semantic query or row id. |
| `/remember <text>` | Explicitly store a memory to `global` (or `--namespace=<name>`). |

### Namespaces

| Namespace | Purpose | Scope |
|-----------|---------|-------|
| `global` | Cross-session Q+A, thinking traces, persistent facts | All projects |
| `code` | Source files (auto-indexed with `/index .`) | This project |
| `docs` | Documentation | This project |
| `decisions` | Architectural decisions, notes | This project |

### Background search (conversational use)

When answering a question that is clearly memory-driven ("where is X?", "what did we decide about Y?"):
- Silently call `logosdb_search` with `top_k` 3–5
- In your answer, cite source files briefly (e.g. `src/foo.ts`) and paraphrase — **never quote full chunk text**
- Search `global` for cross-session context; search `code` for project source

### When to re-index (silent)

- After pulling / merging changes: call `logosdb_index_file(path=".", incremental=true)` silently
- After editing a specific file: call `logosdb_index_file` on that file silently
- Before a broad search when files may have changed since last index

### Memory scope configuration

```sh
# default — global cross-project memory
unset LOGOS_MEMORY_MODE

# per-project isolation
export LOGOS_MEMORY_MODE=project
```

<!-- END: semantic-memory plugin CLAUDE.md block -->
