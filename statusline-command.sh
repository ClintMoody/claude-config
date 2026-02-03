#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# ULTRA COOL STATUSLINE v2.0
# A cyberpunk-inspired context meter with visual flair
# ══════════════════════════════════════════════════════════════════════════════

# Read JSON input from stdin
input=$(cat)

# Extract context usage percentage
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ─────────────────────────────────────────────────────────────────────────────
# COLOR PALETTE (Cyberpunk Theme)
# ─────────────────────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
BLINK="\033[5m"

# Neon colors
NEON_CYAN="\033[38;5;51m"
NEON_MAGENTA="\033[38;5;201m"
NEON_PINK="\033[38;5;199m"
NEON_PURPLE="\033[38;5;135m"
NEON_BLUE="\033[38;5;39m"
NEON_GREEN="\033[38;5;46m"
NEON_YELLOW="\033[38;5;226m"
NEON_ORANGE="\033[38;5;208m"
NEON_RED="\033[38;5;196m"

# ─────────────────────────────────────────────────────────────────────────────
# UNICODE SYMBOLS
# ─────────────────────────────────────────────────────────────────────────────
BLOCK_FULL="█"
BLOCK_LIGHT="░"
SPARK="✦"
BOLT="⚡"
BRAIN="🧠"
FIRE="🔥"
SKULL="💀"
ROCKET="🚀"
SEP_THIN="│"
BAR_START="▐"
BAR_END="▌"

# ─────────────────────────────────────────────────────────────────────────────
# HELPER: Generate progress bar with gradient
# ─────────────────────────────────────────────────────────────────────────────
generate_bar() {
    local percent=$1
    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local bar=""

    # Build filled portion with gradient
    for ((i=0; i<filled; i++)); do
        local pos=$((i * 100 / width))
        if [ $pos -lt 25 ]; then
            bar="${bar}${NEON_CYAN}${BLOCK_FULL}"
        elif [ $pos -lt 50 ]; then
            bar="${bar}${NEON_GREEN}${BLOCK_FULL}"
        elif [ $pos -lt 75 ]; then
            bar="${bar}${NEON_YELLOW}${BLOCK_FULL}"
        else
            bar="${bar}${NEON_RED}${BLOCK_FULL}"
        fi
    done

    # Build empty portion
    for ((i=0; i<empty; i++)); do
        bar="${bar}${DIM}\033[38;5;240m${BLOCK_LIGHT}"
    done

    echo -e "${bar}${RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN LOGIC
# ─────────────────────────────────────────────────────────────────────────────

# If no usage data yet
if [ -z "$used" ]; then
    printf "${NEON_CYAN}${SPARK}${RESET} ${DIM}Awaiting input...${RESET} ${NEON_CYAN}${SPARK}${RESET}"
    exit 0
fi

# Convert to integer
used_int=$(printf "%.0f" "$used")

# Generate the progress bar
bar=$(generate_bar $used_int)

# Determine status icon and color based on usage
if [ "$used_int" -ge 90 ]; then
    # CRITICAL: 90%+ - Blinking skull, danger zone
    icon="${BLINK}${NEON_RED}${SKULL}${RESET}"
    label="${BLINK}${BOLD}${NEON_RED}CRITICAL${RESET}"
    pct_color="${BLINK}${BOLD}${NEON_RED}"
    tip=" ${DIM}→ Consider /compact${RESET}"
elif [ "$used_int" -ge 80 ]; then
    # DANGER: 80-89% - Fire warning
    icon="${NEON_ORANGE}${FIRE}${RESET}"
    label="${BOLD}${NEON_ORANGE}DANGER${RESET}"
    pct_color="${BOLD}${NEON_ORANGE}"
    tip=" ${DIM}→ /compact soon${RESET}"
elif [ "$used_int" -ge 60 ]; then
    # WARNING: 60-79% - Yellow alert
    icon="${NEON_YELLOW}${BOLT}${RESET}"
    label="${NEON_YELLOW}ACTIVE${RESET}"
    pct_color="${NEON_YELLOW}"
    tip=""
elif [ "$used_int" -ge 40 ]; then
    # GOOD: 40-59% - Healthy usage
    icon="${NEON_GREEN}${BRAIN}${RESET}"
    label="${NEON_GREEN}OPTIMAL${RESET}"
    pct_color="${NEON_GREEN}"
    tip=""
elif [ "$used_int" -ge 20 ]; then
    # FRESH: 20-39% - Plenty of room
    icon="${NEON_CYAN}${ROCKET}${RESET}"
    label="${NEON_CYAN}FRESH${RESET}"
    pct_color="${NEON_CYAN}"
    tip=""
else
    # NEW: 0-19% - Brand new session
    icon="${NEON_MAGENTA}${SPARK}${RESET}"
    label="${NEON_MAGENTA}NEW${RESET}"
    pct_color="${NEON_MAGENTA}"
    tip=""
fi

# ─────────────────────────────────────────────────────────────────────────────
# RENDER STATUSLINE
# ─────────────────────────────────────────────────────────────────────────────
# Format: [icon] LABEL │ ▐████████░░░░░░░░░░▌ 45% [tip]

printf "${icon} ${label} ${DIM}${SEP_THIN}${RESET} ${BAR_START}${bar}${BAR_END} ${pct_color}${used_int}%%${RESET}${tip}"
