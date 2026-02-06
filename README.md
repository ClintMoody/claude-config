# Claude Code Configuration

Personal Claude Code settings synced across machines.

## Contents

- `settings.json` - Main Claude Code settings
- `statusline-command.sh` - Ultra Cool Statusline v2.0 (cyberpunk theme)
- `hooks/` - Session hooks
  - `gsd-check-update.js` - GSD update checker
  - `detect-video.sh` - Auto-detect video/GIF drops and trigger `/video` analysis
- `commands/` - Slash commands
  - `video.md` - `/video` command — extract frames from video/GIF for visual analysis
- `install.sh` - Installation script

## Installation

On a new machine, run:

```bash
./install.sh
```

This will copy the configuration to `~/.claude/` with automatic backups of existing files.

## Video Analysis

Drop a video or GIF file path into the terminal and press Enter — Claude automatically extracts key frames and analyzes them visually. Also available as `/video <path>`.

Supports: `.mp4`, `.mov`, `.gif`, `.webm`, `.avi`, `.mkv`, `.m4v`, `.flv`

Requires: `ffmpeg` installed on the system.

## Statusline Features

The custom statusline displays context usage with:
- Gradient progress bar (cyan → green → yellow → red)
- Dynamic emoji icons based on state
- Status labels (NEW, FRESH, OPTIMAL, ACTIVE, DANGER, CRITICAL)
- Blinking effects at critical levels
- Tips for `/compact` when context is filling up
