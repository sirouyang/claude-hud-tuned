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

# Find node: try PATH first, then common locations
NODE_BIN=$(command -v node 2>/dev/null)
if [ -z "$NODE_BIN" ]; then
  for candidate in /d/nodejs/node /usr/local/bin/node /usr/bin/node "$HOME/.nvm/versions/node/"*/bin/node; do
    if [ -x "$candidate" ]; then
      NODE_BIN="$candidate"
      break
    fi
  done
fi

if [ -z "$NODE_BIN" ]; then
  echo "ERROR: node not found. Install Node.js 18+ and ensure it is on PATH." >&2
  exit 1
fi

exec "$NODE_BIN" "$PLUGIN_DIR/dist/index.js"
