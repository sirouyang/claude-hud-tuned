# claude-hud-tuned

A patch set for [claude-hud](https://github.com/jarrodwatts/claude-hud) — customized display config applied on top of the official plugin. No standalone fork, no separate registration; updates to `claude-hud` are preserved, and patches are re-applied on top.

## What's Customized

| Setting | Value |
|---------|-------|
| Language | Chinese (zh) |
| Layout | Expanded (multi-line) |
| Model format | Compact |
| Custom line | `{username}` (resolves to system username at runtime) |
| Context bar | Enabled |
| Git status + file stats | Enabled |
| Duration | h/m/s format |
| Label color | Bright gray (visible on dark backgrounds) |

## Install

Two methods — pick whichever fits your workflow.

### Method 1: Plugin Marketplace (Recommended)

This installs the upstream `claude-hud` plugin, then applies tuned patches on top.

**Step 1: Install claude-hud from marketplace**

Inside Claude Code, run:

```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/reload-plugins
```

> **Linux users**: If you see `EXDEV: cross-device link not permitted`, run:
> ```bash
> mkdir -p ~/.cache/tmp && TMPDIR=~/.cache/tmp claude
> ```
> Then retry the install commands in that session.

**Step 2: Clone this repo and apply patches**

```bash
git clone https://github.com/user/claude-hud-tuned.git
cd claude-hud-tuned
bash apply.sh
```

`apply.sh` will:
1. Find the installed `claude-hud` plugin cache
2. Copy patched files over it
3. Install the statusline wrapper
4. Copy the display config
5. Update `settings.json` with the statusLine command

**Step 3: Restart Claude Code**

The HUD will appear after restart.

### Method 2: From Source (No Marketplace)

If you prefer not to use the plugin marketplace, you can work directly with the source.

**Step 1: Clone the repo**

```bash
git clone https://github.com/user/claude-hud-tuned.git
cd claude-hud-tuned
```

**Step 2: Apply patches**

```bash
bash apply.sh
```

This does the same as Method 1 Step 2 — it requires `claude-hud` to already be installed in the plugin cache. If it's not installed yet, run `/plugin install claude-hud` inside Claude Code first, then come back and run `apply.sh`.

**Step 3: Restart Claude Code**

### Reinstall / Update

After a `claude-hud` plugin update, re-run `apply.sh` to re-apply patches:

```bash
cd claude-hud-tuned
bash apply.sh
```

Then restart Claude Code.

## Configuration

The display config is at `~/.claude/plugins/claude-hud/config.json`. Edit it directly for advanced options, or re-copy from this repo:

```bash
cp plugin-config.json ~/.claude/plugins/claude-hud/config.json
```

Key config files in this repo:

| File | Purpose |
|------|---------|
| `plugin-config.json` | Reference config (copied to plugin config dir by `apply.sh`) |
| `patches/src/` | Modified TypeScript sources |
| `patches/dist/` | Compiled JS patches |
| `claude-hud-statusline.sh` | Statusline wrapper script |

## Project Structure

```
claude-hud-tuned/
  apply.sh                    # Patches the installed claude-hud plugin
  claude-hud-statusline.sh    # Statusline wrapper (runs patched plugin)
  plugin-config.json          # Reference config
  patches/                    # Patched plugin files
    src/                      # Modified TypeScript sources
    dist/                     # Compiled JS patches
  plugin/                     # Full upstream claude-hud source (reference only)
```

## Platform Notes

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Supported | Node.js 18+ or Bun |
| Windows | Supported | Node.js 18+ (Git Bash or WSL recommended for `apply.sh`) |
| Linux | Supported | Node.js 18+ or Bun; watch out for `/tmp` tmpfs issue during plugin install |

On Windows, `apply.sh` runs in Git Bash. The statusline wrapper uses `/d/nodejs/node` by default — edit `claude-hud-statusline.sh` if your Node.js is installed elsewhere.

## Requirements

- Claude Code v1.0.80+
- Node.js 18+ (or Bun on macOS/Linux)
- `jq` (optional, for automatic `settings.json` editing — without it, `apply.sh` prints the JSON you need to add manually)

## License

MIT
