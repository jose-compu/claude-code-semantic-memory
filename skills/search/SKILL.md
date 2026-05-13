---
name: search
description: LogosDB — concise semantic search over indexed memory (optional time window).
argument-hint: "<query>" [--namespace=name] [--top-k=n] [--from-ts=ISO] [--to-ts=ISO]
model: sonnet
---

# /search

User invoked with: **$ARGUMENTS**

## Instructions

Search LogosDB for semantically similar content and respond **concisely** (file paths + scores only — never echo or paraphrase the full chunk text in the slash-command reply).

Parse the arguments:

- Everything before any flag is the search query.
- `--namespace=<name>` or `-n <name>` sets the collection (default: `code`).
- `--top-k=<n>` or `-k <n>` sets the number of results (default: **5**, hard cap at **8** for slash use — keep output small).
- Optional ISO 8601 timestamp window (inclusive), same as MCP `ts_from` / `ts_to`:
  - `--from-ts=<iso>` or `--ts-from=<iso>` → pass as `ts_from`
  - `--to-ts=<iso>` or `--ts-to=<iso>` → pass as `ts_to`
- Optional `--candidate-k=<n>` → pass as `candidate_k` when using a timestamp window (default: 10 × top_k).

Call the **`logosdb_search`** MCP tool with the query, namespace, top_k, and (when bounds are set) `ts_from`, `ts_to`, and `candidate_k` if provided.

### Output format (strict)

Respond with **only** the following block. Do **not** wrap it in fences, do **not** include the raw tool JSON, and do **not** paste chunk text.

```text
Searching '{namespace}' (top_k={top_k}{ts_note}): {N} matches
  1. {file_path} (score: {score})
  2. {file_path} (score: {score})
  ...
```

- `{file_path}` is extracted from the `[file:...]` prefix in the result text.
- `{ts_note}` is `, ts=[{ts_from}..{ts_to}]` when either bound is set, else empty.
- If no results: `No matches found in '{namespace}' namespace.` — single line, nothing else.

### Quiet mode for conversational use

When the agent invokes `logosdb_search` outside of `/search` (i.e. as part of answering a normal question), it should still:

- Keep `top_k` 3–5.
- Cite source files briefly (e.g. `src/foo.ts`) in the final prose.
- **Not** quote the full chunk text returned by the tool.

## Related

[`skills/semantic-memory/SKILL.md`](../semantic-memory/SKILL.md)
