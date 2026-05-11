#!/bin/sh
# Launch logosdb-mcp-server with a stable LOGOSDB_PATH.
# MCP uses stdout for JSON-RPC — log diagnostics only to stderr.
#
# User-scoped plugins often have cwd = plugin cache (~/.claude/plugins/cache/...),
# so ./.logosdb would be wrong. Claude Code sets CLAUDE_PROJECT_DIR for stdio MCP
# (see anthropics/claude-code#42687). Fall back to PWD when unset (older clients).

set -eu

# LogosDB MCP path rules use process.cwd() as an allowed root for logosdb_index_file.
# User-scoped plugins often start with cwd = plugin cache; cd to the real project first.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  cd "$CLAUDE_PROJECT_DIR"
  export LOGOSDB_PATH="${LOGOSDB_PATH:-$CLAUDE_PROJECT_DIR/.logosdb}"
else
  export LOGOSDB_PATH="${LOGOSDB_PATH:-$PWD/.logosdb}"
fi

echo "[semantic-memory plugin] LOGOSDB_PATH=$LOGOSDB_PATH cwd=$PWD CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-}" >&2

exec npx -y logosdb-mcp-server
