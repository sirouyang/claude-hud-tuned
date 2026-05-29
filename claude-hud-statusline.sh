#!/usr/bin/env bash
# claude-hud-tuned statusline wrapper.
# Runs the standalone custom plugin's dist/index.js via node.
# COLUMNS is exported so the HUD knows the terminal width.

cols=$( { stty size </dev/tty | awk '{print $2}'; } 2>/dev/null )
export COLUMNS=$(( ${cols:-120} > 4 ? ${cols:-120} - 4 : 1 ))

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Find the latest installed claude-hud plugin version
PLUGIN_DIR=$(
  ls -d "$CLAUDE_DIR"/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null \
    | awk -F/ '{ print $(NF-1) "\t" $0 }' \
    | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
    | tail -1 \
    | cut -f2- \
    | sed 's:/$::'
)

if [ -z "$PLUGIN_DIR" ] || [ ! -f "$PLUGIN_DIR/dist/index.js" ]; then
  exit 0
fi

# Detect runtime: prefer bun on macOS/Linux, node on Windows
RUNTIME=""
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  # Windows: node only
  RUNTIME=$(command -v node 2>/dev/null)
else
  # macOS/Linux: prefer bun, fall back to node
  RUNTIME=$(command -v bun 2>/dev/null || command -v node 2>/dev/null)
fi

if [ -z "$RUNTIME" ]; then
  echo "ERROR: Neither bun nor node found. Install Node.js 18+ or Bun." >&2
  exit 1
fi

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  exec "$RUNTIME" "$PLUGIN_DIR/dist/index.js"
else
  if [[ "$(basename "$RUNTIME")" == "bun" ]]; then
    exec "$RUNTIME" --env-file /dev/null "$PLUGIN_DIR/dist/index.js"
  else
    exec "$RUNTIME" "$PLUGIN_DIR/dist/index.js"
  fi
fi
