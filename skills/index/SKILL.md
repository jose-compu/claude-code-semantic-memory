---
name: index
description: LogosDB — incremental index of a file or directory (changed/new files only; fast refresh).
argument-hint: <path> [--namespace=name] [-n name]
model: sonnet
---

# /index

User invoked with: **$ARGUMENTS**

## Instructions

Index a file or directory into LogosDB for semantic search using **incremental** mode (requires **`logosdb-mcp-server`** ≥ **0.7.11**).

Parse the arguments:

- First positional argument is the path to index (file or directory)
- `--namespace=<name>` or `-n <name>` sets the collection name (default: `code`)

Call the **`logosdb_index_file`** MCP tool with the resolved path, namespace, and **`incremental: true`**.

**Incremental:** new or changed files only; changed files have old chunks removed first; unchanged files are skipped; directory runs also drop chunks for files removed from disk (see LogosDB [`mcp/README.md`](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md)). **Cost:** proportional to **changed chunks**, not the whole tree — suitable for **session-start refresh** or **after edits** when the user wants memory aligned with disk.

**Session load (semantic-memory plugin):** the model-invoked [`semantic-memory`](../semantic-memory/SKILL.md) skill requires **`/index .`** at **every** session start when the plugin is active; this slash command is how the user (or agent) performs **`path: "."`**. **Proactive use:** when the user asks to “sync memory” or after substantial edits, run **`/index`** on the affected path again — incremental makes repeat calls cheap.

When done, respond in exactly this format (no extra prose), using the tool result fields `indexed`, `indexed_files`, `skipped_files`, and `namespace`:

```text
Indexed {indexed} chunks ({indexed_files} files updated, {skipped_files} skipped) into '{namespace}' collection
```

## Related

Setup, namespaces, and `CLAUDE.md` template: [`skills/semantic-memory/SKILL.md`](../semantic-memory/SKILL.md).
