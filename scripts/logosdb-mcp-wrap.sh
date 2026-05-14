#!/bin/sh
# Launch logosdb-mcp-server for Claude Code plugin MCP (stdio).
# Never write to stdout (reserved for MCP JSON-RPC); diagnostics → stderr only.
#
# Memory scope (LOGOS_MEMORY_MODE):
#   global  (default) — LOGOSDB_PATH = ~/.claude/.logosdb (shared across ALL projects/sessions)
#   project           — LOGOSDB_PATH = $CLAUDE_PROJECT_DIR/.logosdb (per-repo isolation)
#
# Override LOGOSDB_PATH explicitly to use any custom path regardless of mode.
# LOGOSDB_INDEX_ROOT is always scoped to the project directory for security.

set -eu

export NPM_CONFIG_FUND="${NPM_CONFIG_FUND:-false}"
export NPM_CONFIG_AUDIT="${NPM_CONFIG_AUDIT:-false}"
export npm_config_update_notifier="${npm_config_update_notifier:-false}"

LOGOS_MEMORY_MODE="${LOGOS_MEMORY_MODE:-global}"

if [ "$LOGOS_MEMORY_MODE" = "project" ]; then
  # Per-project isolation: DB lives inside the project directory.
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    cd "$CLAUDE_PROJECT_DIR"
    export LOGOSDB_PATH="${LOGOSDB_PATH:-$CLAUDE_PROJECT_DIR/.logosdb}"
    export LOGOSDB_INDEX_ROOT="${LOGOSDB_INDEX_ROOT:-$CLAUDE_PROJECT_DIR}"
  else
    export LOGOSDB_PATH="${LOGOSDB_PATH:-$PWD/.logosdb}"
    export LOGOSDB_INDEX_ROOT="${LOGOSDB_INDEX_ROOT:-$PWD}"
  fi
else
  # Global mode (default): user-wide DB shared across all projects and sessions.
  # Index root is still scoped to the project directory for security.
  _HOME="${HOME:-$USERPROFILE}"
  export LOGOSDB_PATH="${LOGOSDB_PATH:-$_HOME/.claude/.logosdb}"
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    cd "$CLAUDE_PROJECT_DIR"
    export LOGOSDB_INDEX_ROOT="${LOGOSDB_INDEX_ROOT:-$CLAUDE_PROJECT_DIR}"
  else
    export LOGOSDB_INDEX_ROOT="${LOGOSDB_INDEX_ROOT:-$PWD}"
  fi
fi

echo "[semantic-memory] mode=${LOGOS_MEMORY_MODE} LOGOSDB_PATH=${LOGOSDB_PATH} INDEX_ROOT=${LOGOSDB_INDEX_ROOT}" >&2

if command -v npm >/dev/null 2>&1 && npm exec -h >/dev/null 2>&1; then
  exec npm exec --yes -- logosdb-mcp-server
else
  exec npx --yes logosdb-mcp-server
fi
