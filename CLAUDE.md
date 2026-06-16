# CLAUDE.md

Patches for [claude-hud](https://github.com/jarrodwatts/claude-hud) — customize display without forking.

## Structure

```
apply.sh              # Apply patches to installed plugin
patches/src/          # Modified TypeScript sources
patches/dist/         # Compiled JS
plugin/               # Upstream source (reference)
plugin-config.json    # Config reference
```

## Workflows

### Apply patches
```bash
bash apply.sh
```
Idempotent. Uses Node.js for JSON editing (no extra dependencies).

### Edit plugin code
1. Edit `patches/src/` or `patches/dist/`
2. Run `bash apply.sh`

## Paths

- Plugin cache: `~/.claude/plugins/cache/claude-hud/*/`
- Config: `~/.claude/plugins/claude-hud/config.json`
- Wrapper: `~/.claude/claude-hud-statusline.sh`
- StatusLine config: `~/.claude/settings.local.json` (NOT `settings.json` — that gets overwritten on startup)
