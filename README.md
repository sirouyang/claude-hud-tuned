# claude-hud-tuned

> [中文文档](README.zh.md)

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

### Method 1: Plugin Marketplace (Recommended)

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

**Step 3: Restart Claude Code**

### Method 2: From Source

```bash
git clone https://github.com/user/claude-hud-tuned.git
cd claude-hud-tuned
bash apply.sh
```

Requires `claude-hud` to already be installed in the plugin cache. If not, run `/plugin install claude-hud` inside Claude Code first, then run `apply.sh`.

### Reinstall / Update

After a `claude-hud` plugin update, re-run `apply.sh` and restart Claude Code:

```bash
cd claude-hud-tuned
bash apply.sh
```

## Configuration

The display config is at `~/.claude/plugins/claude-hud/config.json`. Edit it directly, or re-copy from this repo:

```bash
cp plugin-config.json ~/.claude/plugins/claude-hud/config.json
```

## Project Structure

```
claude-hud-tuned/
  apply.sh                    # Patches the installed claude-hud plugin
  claude-hud-statusline.sh    # Statusline wrapper (auto-detects node)
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

The statusline wrapper auto-detects `node` from PATH. If not found, it checks common install locations (`/usr/local/bin/node`, nvm paths, etc.). A clear error is shown if Node.js is missing.

## Requirements

- Claude Code v1.0.80+
- Node.js 18+ (or Bun on macOS/Linux)
- `jq` (optional, for automatic `settings.json` editing — without it, `apply.sh` prints the JSON you need to add manually)

## License

MIT
