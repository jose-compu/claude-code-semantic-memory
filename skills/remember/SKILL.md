---
name: remember
description: LogosDB — store a memory, fact, or note in the global cross-session namespace (or any namespace). Concise output.
argument-hint: "<text to remember>" [--namespace=name]
model: sonnet
---

# /remember

User invoked with: **$ARGUMENTS**

## Instructions

Store a piece of text in LogosDB for retrieval in future sessions.

Parse the arguments:

- Everything before any flag is the text to store.
- `--namespace=<name>` or `-n <name>` sets the collection (default: `global`).

Call the **`logosdb_index`** MCP tool with the text and namespace.

The `global` namespace is shared across **all projects and sessions** — use it for cross-cutting facts, preferences, decisions, or anything worth remembering in future work.

Use a project-specific namespace (e.g. `code`, `decisions`) when the memory is only relevant to this project.

### Output format (strict)

Respond with **one line only**:

```
Remembered → '<namespace>'
```

On tool error, surface the server's `Error:` message on a single line, unchanged.

## Examples

```
/remember always prefer functional components over class components
/remember --namespace=decisions use Postgres not SQLite for this project
/remember -n global my preferred tab size is 2 spaces
```

## Related

[`skills/semantic-memory/SKILL.md`](../semantic-memory/SKILL.md) — global memory, thinking traces, session auto-store.
