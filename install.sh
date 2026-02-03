#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# Claude Config Installer
# Syncs Claude Code configuration to ~/.claude/
# ══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "🔧 Installing Claude configuration..."

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/hooks"

# Backup existing files
backup_if_exists() {
    if [ -f "$1" ] && [ ! -L "$1" ]; then
        echo "  📦 Backing up existing $1 to $1.bak"
        cp "$1" "$1.bak"
    fi
}

# Install settings.json (merge if exists, otherwise copy)
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    echo "  ⚠️  settings.json exists - please merge manually if needed"
    echo "      Source: $SCRIPT_DIR/settings.json"
else
    cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    echo "  ✓ Installed settings.json"
fi

# Install statusline script
backup_if_exists "$CLAUDE_DIR/statusline-command.sh"
cp "$SCRIPT_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
echo "  ✓ Installed statusline-command.sh"

# Install hooks
for hook in "$SCRIPT_DIR/hooks/"*; do
    if [ -f "$hook" ]; then
        hookname=$(basename "$hook")
        backup_if_exists "$CLAUDE_DIR/hooks/$hookname"
        cp "$hook" "$CLAUDE_DIR/hooks/$hookname"
        chmod +x "$CLAUDE_DIR/hooks/$hookname"
        echo "  ✓ Installed hooks/$hookname"
    fi
done

echo ""
echo "✨ Claude configuration installed successfully!"
echo ""
echo "Note: You may need to restart Claude Code for changes to take effect."
