#!/usr/bin/env bash
# Apply (or re-apply) the custom claude-hud HUD patches.
#
# Run this after a fresh `/plugin install claude-hud` or whenever a plugin
# update has wiped the customizations. Idempotent — safe to run multiple times.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# --- 1. Locate the installed claude-hud plugin cache ----------------------
PLUGIN_DIR=$(
  ls -d "$CLAUDE_DIR"/plugins/cache/*/claude-hud/*/ 2>/dev/null \
    | awk -F/ '{ print $(NF-1) "\t" $0 }' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+[[:space:]]' \
    | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
    | tail -1 \
    | cut -f2- \
    | sed 's:/$::'
)

if [ -z "$PLUGIN_DIR" ]; then
  echo "ERROR: claude-hud plugin not found under $CLAUDE_DIR/plugins/cache" >&2
  echo "Install it first: open Claude Code and run /plugin install claude-hud" >&2
  exit 1
fi

echo "Found claude-hud at: $PLUGIN_DIR"

# --- 2. Copy patched source/dist files in ---------------------------------
copy_patch() {
  local rel="$1"
  local src="$SCRIPT_DIR/patches/$rel"
  local dst="$PLUGIN_DIR/$rel"
  if [ ! -f "$src" ]; then
    echo "  skip (no patch): $rel"
    return
  fi
  if [ ! -f "$dst" ]; then
    echo "  skip (target missing): $rel"
    return
  fi
  cp "$src" "$dst"
  echo "  patched: $rel"
}

copy_patch "dist/index.js"
copy_patch "dist/render/index.js"
copy_patch "dist/render/colors.js"
copy_patch "dist/render/lines/identity.js"
copy_patch "dist/render/lines/project.js"
copy_patch "src/index.ts"
copy_patch "src/render/index.ts"
copy_patch "src/render/colors.ts"
copy_patch "src/render/lines/identity.ts"
copy_patch "src/render/lines/project.ts"

# --- 3. Install the statusline wrapper ------------------------------------
WRAPPER_DST="$CLAUDE_DIR/claude-hud-statusline.sh"
cp "$SCRIPT_DIR/claude-hud-statusline.sh" "$WRAPPER_DST"
chmod +x "$WRAPPER_DST"
echo "Installed wrapper: $WRAPPER_DST"

# --- 4. Install the plugin display config ---------------------------------
PLUGIN_CONFIG_DIR="$CLAUDE_DIR/plugins/claude-hud"
mkdir -p "$PLUGIN_CONFIG_DIR"
cp "$SCRIPT_DIR/plugin-config.json" "$PLUGIN_CONFIG_DIR/config.json"
echo "Installed plugin config: $PLUGIN_CONFIG_DIR/config.json"

# --- 5. Update settings.json statusLine -----------------------------------
SETTINGS="$CLAUDE_DIR/settings.json"
if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

if command -v jq >/dev/null 2>&1; then
  cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
  tmp=$(mktemp)
  jq --arg cmd "bash $WRAPPER_DST" \
    '.statusLine = {type: "command", command: $cmd}' \
    "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "Updated $SETTINGS statusLine"
else
  echo
  echo "WARNING: jq not installed — settings.json was not modified."
  echo "Add this block manually:"
  echo
  echo '  "statusLine": {'
  echo '    "type": "command",'
  echo "    \"command\": \"bash $WRAPPER_DST\""
  echo '  }'
fi

# --- 6. Smoke test --------------------------------------------------------
echo
echo "Smoke test (expect 2 colored lines, OS info + Context):"
echo '{"model":{"display_name":"Opus 4.7"},"context_window":{"current_usage":{"input_tokens":45000},"context_window_size":200000},"transcript_path":"/tmp/test.jsonl","cwd":"'"$PWD"'"}' \
  | bash "$WRAPPER_DST" || echo "(smoke test failed)"

echo
echo "Done. Restart Claude Code to pick up the new statusline."
