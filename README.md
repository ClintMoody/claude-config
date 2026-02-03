# Claude Code Configuration

Personal Claude Code settings synced across machines.

## Contents

- `settings.json` - Main Claude Code settings
- `statusline-command.sh` - Ultra Cool Statusline v2.0 (cyberpunk theme)
- `hooks/` - Session hooks (GSD update checker, etc.)
- `install.sh` - Installation script

## Installation

On a new machine, run:

```bash
./install.sh
```

This will copy the configuration to `~/.claude/` with automatic backups of existing files.

## Statusline Features

The custom statusline displays context usage with:
- Gradient progress bar (cyan → green → yellow → red)
- Dynamic emoji icons based on state
- Status labels (NEW, FRESH, OPTIMAL, ACTIVE, DANGER, CRITICAL)
- Blinking effects at critical levels
- Tips for `/compact` when context is filling up
