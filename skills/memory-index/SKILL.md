---
name: memory-index
description: LogosDB — index a file or directory into semantic memory for later search.
argument-hint: <path> [--namespace=name] [-n name]
model: sonnet
---

# /memory-index

User invoked with: **$ARGUMENTS**

## Instructions

Index a file or directory into LogosDB for semantic search.

Parse the arguments:

- First positional argument is the path to index (file or directory)
- `--namespace=<name>` or `-n <name>` sets the collection name (default: `code`)

Call the **`logosdb_index_file`** MCP tool with the resolved path and namespace.

When done, respond in exactly this format (no extra prose):

```text
Indexed {files} files into '{namespace}' collection
```

## Related

Setup, namespaces, and `CLAUDE.md` template: [`skills/semantic-memory/SKILL.md`](../semantic-memory/SKILL.md).
