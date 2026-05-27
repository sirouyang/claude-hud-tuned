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
Idempotent. Requires `jq` for JSON editing.

### Edit plugin code
1. Edit `patches/src/` or `patches/dist/`
2. Run `bash apply.sh`

## Paths

- Plugin cache: `~/.claude/plugins/cache/claude-hud/*/`
- Config: `~/.claude/plugins/claude-hud/config.json`
- Wrapper: `~/.claude/claude-hud-statusline.sh`
