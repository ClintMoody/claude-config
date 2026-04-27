# Claude Code Configuration

My personal Claude Code setup — synced across machines. Statusline, slash commands, hooks, and a couple of cost-tracking scripts.

## Install

```bash
./install.sh
```

Copies everything into `~/.claude/`, backing up any existing files as `*.bak`. Restart Claude Code to pick up changes.

## What's in here

### Statusline — `statusline-command.sh`

Cyberpunk-themed context meter that goes well past the default. Shows:

- Gradient progress bar (cyan → green → yellow → red) that scales to Claude Code's real 80% context limit
- Token counts (in ↓ / out ↑) with K/M suffixes
- Per-session cost, calculated live from current token usage and the model's API pricing
- Running monthly cost (read from a cache file the cost script keeps warm)
- Dynamic state labels: NEW, FRESH, OPTIMAL, ACTIVE, DANGER, CRITICAL — with blinking effects when context fills up
- Tip nudging you toward `/compact` when you're getting close

### Slash commands — `commands/`

- **`/video <path>`** — drop a video or GIF, get visual analysis. Probes the file with `ffprobe`, extracts frames with `ffmpeg` (rules adjust based on duration: ALL frames for short clips/GIFs, 1fps for medium, evenly-spaced for long), then Claude reads each frame as an image and describes what it sees. Great for UI bug repros and animation review. Requires `ffmpeg`.
- **`/api-costs`** — runs `usage-history.py --by-model` and prints the report inline. Month-by-month spend broken down by model family.

### Hooks — `hooks/`

- **`detect-video.sh`** (UserPromptSubmit) — if your prompt contains a path ending in `.mp4 / .mov / .gif / .webm / .avi / .mkv / .m4v / .flv`, auto-injects a directive telling Claude to run `/video` on it. So you can literally just drag a video into the terminal, hit enter, and it Just Works.
- **`gsd-check-update.js`** (SessionStart) — background check for [GSD](https://github.com/anthropics/get-shit-done) framework updates; writes the result to `~/.claude/cache/` for the statusline to surface.
- **`gsd-statusline.js`** — alternate, simpler statusline (model | task | dir | context). Not wired up by default; here if you want it instead of the cyberpunk one.

### Cost scripts

- **`usage-history.py`** — scans every transcript JSONL in `~/.claude/projects/` and prints month-by-month totals: cost, input/output/cache tokens, call counts. Flags: `--last N` to limit months, `--by-model` to break out Opus / Sonnet / Haiku separately.
- **`compute-monthly-cost.py`** — same scanner but only the current month, written atomically to `~/.claude/cache/monthly-cost.json` so the statusline can read it cheaply.

Both use API-equivalent pricing (early-2026 rates baked in — if you're on a Max plan, treat the number as "what this *would* cost on the API").

### Settings — `settings.json`, `claude-settings.json`, `settings.local.json`

The main `settings.json` wires up the hooks above, the statusline, enabled plugins (superpowers, telegram, frontend-design, playwright, skill-creator, obsidian-skills, cli-anything, clangd-lsp), and a few extra plugin marketplaces. `settings.local.json` has the per-project Bash permission allowlist.

## Heads up

- Pricing constants in the cost scripts are hand-coded for early 2026 — they'll drift. If you're using this much later, update the `PRICING` dict in `usage-history.py` / `compute-monthly-cost.py` and the `get_pricing()` case in `statusline-command.sh`.
- `install.sh` won't overwrite an existing `settings.json` — it'll tell you to merge manually so you don't lose your own hooks.
