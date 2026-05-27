#!/usr/bin/env bash
# Install the standalone claude-hud-tuned plugin.
#
# This registers a fully self-contained fork of claude-hud with baked-in config
# as a separate plugin. It won't be affected by updates to the original claude-hud.
#
# Idempotent — safe to re-run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PLUGIN_NAME="claude-hud-tuned"
MARKETPLACE_NAME="claude-hud-tuned"
VERSION="0.1.0"
CACHE_DIR="$CLAUDE_DIR/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION"
SETTINGS="$CLAUDE_DIR/settings.json"

# --- 1. Copy plugin to cache -----------------------------------------------
echo "Installing plugin to: $CACHE_DIR"
mkdir -p "$(dirname "$CACHE_DIR")"
rm -rf "$CACHE_DIR"
cp -r "$SCRIPT_DIR/plugin" "$CACHE_DIR"
echo "  Copied plugin files"

# --- 2. Register in installed_plugins.json ----------------------------------
INSTALLED="$CLAUDE_DIR/plugins/installed_plugins.json"
if [ ! -f "$INSTALLED" ]; then
  echo '{"version":2,"plugins":{}}' > "$INSTALLED"
fi

COMPOSITE_KEY="$PLUGIN_NAME@$MARKETPLACE_NAME"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

if command -v jq >/dev/null 2>&1; then
  cp "$INSTALLED" "$INSTALLED.bak-$(date +%Y%m%d-%H%M%S)"
  tmp=$(mktemp)
  jq --arg key "$COMPOSITE_KEY" \
     --arg path "$CACHE_DIR" \
     --arg ver "$VERSION" \
     --arg now "$NOW" \
     '.plugins[$key] = [{
        "scope": "user",
        "installPath": $path,
        "version": $ver,
        "installedAt": $now,
        "lastUpdated": $now
      }]' "$INSTALLED" > "$tmp"
  mv "$tmp" "$INSTALLED"
  echo "  Registered $COMPOSITE_KEY in installed_plugins.json"
else
  echo "  WARNING: jq not installed — you must manually add this to installed_plugins.json:"
  echo "  Key: $COMPOSITE_KEY"
  echo "  Path: $CACHE_DIR"
fi

# --- 3. Add marketplace entry ----------------------------------------------
KNOWN="$CLAUDE_DIR/plugins/known_marketplaces.json"
if [ ! -f "$KNOWN" ]; then
  echo '{}' > "$KNOWN"
fi

if command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  jq --arg name "$MARKETPLACE_NAME" \
     --arg loc "$CLAUDE_DIR/plugins/marketplaces/$MARKETPLACE_NAME" \
     '.[$name] = {
        "source": {"source": "local", "path": "'"$SCRIPT_DIR"'/plugin"},
        "installLocation": $loc,
        "lastUpdated": "'"$NOW"'"
      }' "$KNOWN" > "$tmp"
  mv "$tmp" "$KNOWN"
  echo "  Added marketplace entry for $MARKETPLACE_NAME"
fi

# --- 4. Create marketplace clone (symlink to plugin dir) --------------------
MKT_DIR="$CLAUDE_DIR/plugins/marketplaces/$MARKETPLACE_NAME"
if [ ! -d "$MKT_DIR" ]; then
  mkdir -p "$(dirname "$MKT_DIR")"
  # Use junction on Windows, symlink elsewhere
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    cmd //c "mklink /J \"$(cygpath -w "$MKT_DIR")\" \"$(cygpath -w "$SCRIPT_DIR/plugin")\"" 2>/dev/null \
      || cp -r "$SCRIPT_DIR/plugin" "$MKT_DIR"
  else
    ln -s "$SCRIPT_DIR/plugin" "$MKT_DIR"
  fi
  echo "  Created marketplace at $MKT_DIR"
fi

# --- 5. Install statusline wrapper -----------------------------------------
WRAPPER_SRC="$SCRIPT_DIR/claude-hud-statusline.sh"
WRAPPER_DST="$CLAUDE_DIR/claude-hud-statusline.sh"

# Generate a new wrapper that points to our custom plugin
cat > "$WRAPPER_DST" << 'WRAPPER_EOF'
#!/usr/bin/env bash
# claude-hud-tuned statusline wrapper.
# Runs the standalone custom plugin's dist/index.js via node.
# COLUMNS is exported so the HUD knows the terminal width.

cols=$( { stty size </dev/tty | awk '{print $2}'; } 2>/dev/null )
export COLUMNS=$(( ${cols:-120} > 4 ? ${cols:-120} - 4 : 1 ))

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PLUGIN_DIR="$CLAUDE_DIR/plugins/cache/claude-hud-tuned/claude-hud-tuned/0.1.0"

if [ ! -f "$PLUGIN_DIR/dist/index.js" ]; then
  exit 0
fi

exec /d/nodejs/node "$PLUGIN_DIR/dist/index.js"
WRAPPER_EOF
chmod +x "$WRAPPER_DST"
echo "  Installed wrapper: $WRAPPER_DST"

# --- 6. Update settings.json statusLine ------------------------------------
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
  echo "  Updated settings.json statusLine"
else
  echo
  echo "  WARNING: jq not installed — settings.json was not modified."
  echo "  Add this block manually:"
  echo
  echo '  "statusLine": {'
  echo '    "type": "command",'
  echo "    \"command\": \"bash $WRAPPER_DST\""
  echo '  }'
fi

# --- 7. Smoke test ----------------------------------------------------------
echo
echo "Smoke test:"
echo '{"model":{"display_name":"Opus 4.7"},"context_window":{"current_usage":{"input_tokens":45000},"context_window_size":200000},"transcript_path":"/tmp/test.jsonl","cwd":"'"$PWD"'"}' \
  | bash "$WRAPPER_DST" && echo "  Smoke test OK" || echo "  Smoke test failed"

echo
echo "Done. Restart Claude Code to pick up the new statusline."
echo "The original claude-hud plugin is still installed and can be uninstalled separately."
