# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A patch set for [claude-hud](https://github.com/jarrodwatts/claude-hud). Instead of maintaining a standalone fork, this project applies targeted patches to the upstream `claude-hud` plugin to customize display behavior — no separate plugin registration needed.

## Architecture

```
claude-hud-tuned/
  apply.sh                    # Patches the installed claude-hud plugin
  claude-hud-statusline.sh    # Statusline wrapper (runs patched plugin)
  plugin-config.json          # Reference config (copied to ~/.claude/plugins/claude-hud/)
  patches/                    # Patched plugin files (src/ and dist/)
    src/                      # Modified TypeScript sources
    dist/                     # Compiled JS patches
  plugin/                     # Full upstream claude-hud source (reference only)
```

### How patches work

`apply.sh` finds the installed `claude-hud` plugin under `~/.claude/plugins/cache/claude-hud/*/` and overwrites specific files with patched versions from `patches/`. This lets us customize behavior (e.g., `loadConfig()` reads from external `config.json`, custom render logic) without forking the entire plugin.

### What's customized

- `loadConfig()` reads from `~/.claude/plugins/claude-hud/config.json` instead of requiring code changes
- Render lines (identity, project, colors) have display tweaks
- Config: Chinese language, expanded layout, custom colors, model compact format, `{username}` custom line

## Key workflows

### Apply patches

```bash
bash apply.sh
```

Idempotent. Copies patched files over the installed plugin, installs the statusline wrapper, copies config, and updates `settings.json`.

Requires `jq` for automatic JSON editing. Without jq, the script prints the entries you need to add manually.

### Update config

1. Edit `plugin-config.json` (reference copy)
2. Run `apply.sh` — it copies the config to `~/.claude/plugins/claude-hud/config.json`

### Edit plugin code

1. Edit files in `patches/src/` (or `patches/dist/` if compiled)
2. Run `apply.sh`

### Edit upstream plugin source

The `plugin/` directory contains the full upstream claude-hud source. Use it as reference when creating patches:
1. Edit files in `plugin/src/`
2. Compile: `cd plugin && npm run build`
3. Copy the modified files to `patches/src/` and `patches/dist/`
4. Run `apply.sh`

## Plugin system

- Upstream plugin cache: `~/.claude/plugins/cache/claude-hud/*/`
- Plugin config: `~/.claude/plugins/claude-hud/config.json`
- Wrapper: `~/.claude/claude-hud-statusline.sh` — runs the patched plugin
- Marketplace: `plugin/` directory (junction for development)

## Environment (Windows)

- Node: `/d/nodejs/node` (hardcoded in wrapper)
- Settings statusLine: `bash /c/Users/mango/.claude/claude-hud-statusline.sh`
