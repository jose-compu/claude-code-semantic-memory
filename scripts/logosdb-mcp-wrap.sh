#!/bin/sh
# Launch logosdb-mcp-server for Claude Code plugin MCP (stdio).
# - Never write to stdout (reserved for MCP JSON-RPC); diagnostics -> stderr only.
# - User-scoped plugins: cwd is often ~/.claude/plugins/cache/... — cd to the real project
#   when CLAUDE_PROJECT_DIR is set (anthropics/claude-code#42687).
# - Set LOGOSDB_INDEX_ROOT so logosdb_index_file accepts paths under the project even if
#   cwd were wrong (logosdb mcp security.ts indexRoots()).

set -eu

# Quieter npm (does not fix all npx cache races, but reduces noise)
export NPM_CONFIG_FUND="${NPM_CONFIG_FUND:-false}"
export NPM_CONFIG_AUDIT="${NPM_CONFIG_AUDIT:-false}"
export npm_config_update_notifier="${npm_config_update_notifier:-false}"

if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
  cd "$CLAUDE_PROJECT_DIR"
  export LOGOSDB_PATH="${LOGOSDB_PATH:-$CLAUDE_PROJECT_DIR/.logosdb}"
  export LOGOSDB_INDEX_ROOT="${LOGOSDB_INDEX_ROOT:-$CLAUDE_PROJECT_DIR}"
else
  export LOGOSDB_PATH="${LOGOSDB_PATH:-$PWD/.logosdb}"
  export LOGOSDB_INDEX_ROOT="${LOGOSDB_INDEX_ROOT:-$PWD}"
fi

echo "[semantic-memory plugin] cwd=$PWD LOGOSDB_PATH=$LOGOSDB_PATH LOGOSDB_INDEX_ROOT=$LOGOSDB_INDEX_ROOT CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-}" >&2

# Prefer npm exec (npm 7+); fall back to npx
if command -v npm >/dev/null 2>&1 && npm exec -h >/dev/null 2>&1; then
  exec npm exec --yes -- logosdb-mcp-server
else
  exec npx --yes logosdb-mcp-server
fi
