---
name: index
description: LogosDB — incremental index of a file or directory (changed/new files only; fast refresh, concise output).
argument-hint: <path> [--namespace=name] [-n name]
model: sonnet
---

# /index

User invoked with: **$ARGUMENTS**

## Instructions

Index a file or directory into LogosDB for semantic search using **incremental** mode (requires **`logosdb-mcp-server`** ≥ **0.7.11**).

Parse the arguments:

- First positional argument is the path to index (file or directory).
- `--namespace=<name>` or `-n <name>` sets the collection name (default: `code`).

Call the **`logosdb_index_file`** MCP tool with the resolved path, namespace, and **`incremental: true`**.

**Incremental:** new or changed files only; changed files have old chunks removed first; unchanged files are skipped; directory runs also drop chunks for files removed from disk (see LogosDB [`mcp/README.md`](https://github.com/jose-compu/logosdb/blob/main/mcp/README.md)). **Cost:** proportional to **changed chunks**, not the whole tree — suitable for **session-start refresh** or **after edits** when the user wants memory aligned with disk.

**Session load (semantic-memory plugin):** the model-invoked [`semantic-memory`](../semantic-memory/SKILL.md) skill requires **`/index .`** at **every** session start when the plugin is active.

### Output format (strict)

Respond with **one line only**. Do **not** echo the raw tool JSON. Use the tool result fields `indexed`, `indexed_files`, `skipped_files`, `pruned_files`, and `namespace`:

```text
Indexed {indexed} chunks · {indexed_files} updated · {skipped_files} skipped · {pruned_files} pruned → '{namespace}'
```

If `indexed_files == 0 && skipped_files > 0`, append in the same line: `(no changes since last index — touch the file or delete the namespace to force re-index)`.

## Related

Setup, namespaces, and `CLAUDE.md` template: [`skills/semantic-memory/SKILL.md`](../semantic-memory/SKILL.md) and [`skills/semantic-memory/references/claude-md-template.md`](../semantic-memory/references/claude-md-template.md).
