---
name: memory-forget
description: LogosDB — delete a memory row by id or by semantic query match.
argument-hint: [--namespace=name] (--id=n | --query="...")
model: sonnet
---

# /memory-forget

User invoked with: **$ARGUMENTS**

## Instructions

Delete an entry from LogosDB by row **id** or by **semantic query** (search-then-delete).

Parse the arguments:

- `--namespace=<name>` or `-n <name>` sets the collection (default: `code`)
- **Either** `--id=<number>` or a bare positional number: delete that row id
- **Or** `--query="..."` (or positional text when no numeric id): embed the query, search `search_top_k` neighbors (default 10, max 50), delete the hit at `match_rank` (0-based, default 0 = best match)
- Optional with `--query`: `--search-top-k=<n>`, `--match-rank=<n>`

Call the **`logosdb_delete`** MCP tool:

- With `namespace` and `id` when deleting by id
- With `namespace`, `query`, and optionally `search_top_k` / `match_rank` when deleting by semantic match

Respond for by-id: `Deleted entry {id} from '{namespace}' namespace.`

Respond for semantic: `Deleted entry id {id} (rank {match_rank}, score {score}) from '{namespace}' matched by query.`

## Related

[`skills/semantic-memory/SKILL.md`](../semantic-memory/SKILL.md)
