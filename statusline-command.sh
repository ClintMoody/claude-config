#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# ULTRA COOL STATUSLINE v3.3
# A cyberpunk-inspired context meter with ALL THE DATA + monthly cost tracking
# ══════════════════════════════════════════════════════════════════════════════

# Read JSON input from stdin
input=$(cat)

# ─────────────────────────────────────────────────────────────────────────────
# EXTRACT ALL DATA
# ─────────────────────────────────────────────────────────────────────────────
# Context window
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
current_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
current_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
current_cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
current_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# Model & session info
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
model_id=$(echo "$input" | jq -r '.model.id // ""')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

# ─────────────────────────────────────────────────────────────────────────────
# SESSION COST: Calculate from current context token usage + model pricing
# ─────────────────────────────────────────────────────────────────────────────
# Pricing per million tokens (API rates as of early 2026)
# Using conservative published rates - adjust if needed
get_pricing() {
    local mid="$1"
    case "$mid" in
        *claude-opus-4*|*claude-opus-4-5*|*claude-opus-4-6*)
            echo "15 75 18.75 1.5"   # input output cache_write cache_read (per MTok)
            ;;
        *claude-sonnet-4*|*claude-sonnet-4-5*|*claude-sonnet-4-6*)
            echo "3 15 3.75 0.3"
            ;;
        *claude-haiku-3-5*|*claude-haiku-3*)
            echo "0.8 4 1 0.08"
            ;;
        *claude-opus-3*)
            echo "15 75 18.75 1.5"
            ;;
        *claude-sonnet-3-7*|*claude-sonnet-3-5*)
            echo "3 15 3.75 0.3"
            ;;
        *)
            # Default: sonnet-class pricing
            echo "3 15 3.75 0.3"
            ;;
    esac
}

pricing=$(get_pricing "$model_id")
price_in=$(echo "$pricing" | awk '{print $1}')
price_out=$(echo "$pricing" | awk '{print $2}')
price_cache_write=$(echo "$pricing" | awk '{print $3}')
price_cache_read=$(echo "$pricing" | awk '{print $4}')

# Calculate session cost from current context window usage
session_cost=0
if [ "$current_input" -gt 0 ] || [ "$current_output" -gt 0 ] 2>/dev/null; then
    session_cost=$(echo "scale=6; \
        ($current_input * $price_in / 1000000) + \
        ($current_output * $price_out / 1000000) + \
        ($current_cache_write * $price_cache_write / 1000000) + \
        ($current_cache_read * $price_cache_read / 1000000)" | bc -l 2>/dev/null || echo "0")
fi

# ─────────────────────────────────────────────────────────────────────────────
# MONTHLY COST: Read from cache, refresh in background if stale
# Uses ~/.claude/compute-monthly-cost.py (single-pass, per-model pricing)
# ─────────────────────────────────────────────────────────────────────────────
CACHE_DIR="$HOME/.claude/cache"
MONTHLY_CACHE="$CACHE_DIR/monthly-cost.json"
CURRENT_MONTH=$(date +%Y-%m)
REFRESH_INTERVAL=600  # refresh every 10 minutes

mkdir -p "$CACHE_DIR"

# Read existing cache
cached_month=""
cached_cost="0"
cached_updated="0"
if [ -f "$MONTHLY_CACHE" ]; then
    cached_month=$(jq -r '.month // ""' "$MONTHLY_CACHE" 2>/dev/null)
    cached_cost=$(jq -r '.cost // 0' "$MONTHLY_CACHE" 2>/dev/null)
    cached_updated=$(jq -r '.updated // 0' "$MONTHLY_CACHE" 2>/dev/null)
fi

# Determine if cache needs refresh: wrong month OR older than REFRESH_INTERVAL
needs_refresh=0
now=$(date +%s)
if [ "$cached_month" != "$CURRENT_MONTH" ]; then
    needs_refresh=1
elif [ $((now - cached_updated)) -ge $REFRESH_INTERVAL ]; then
    needs_refresh=1
fi

# Use a lock file to prevent multiple concurrent refreshes
LOCK_FILE="$CACHE_DIR/monthly-cost.lock"

# Auto-clean stale locks older than 60 seconds (handles killed processes)
if [ -f "$LOCK_FILE" ]; then
    lock_age=$((now - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo "$now")))
    if [ "$lock_age" -gt 60 ]; then
        rm -f "$LOCK_FILE"
    fi
fi

if [ "$needs_refresh" = "1" ]; then
    # Only start refresh if no other refresh is running
    if (set -o noclobber; echo $$ > "$LOCK_FILE") 2>/dev/null; then
        (python3 "$HOME/.claude/compute-monthly-cost.py"; rm -f "$LOCK_FILE") &
        disown
    fi
fi

# Always display from cache (background refresh will update it for next render)
if [ "$cached_month" = "$CURRENT_MONTH" ]; then
    total_cumulative="$cached_cost"
else
    total_cumulative="0"
fi

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
NEON_GOLD="\033[38;5;220m"
NEON_LIME="\033[38;5;118m"

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
MONEY="💰"
CHART="📊"
CLOCK="⏱"
SEP="│"
BAR_START="▐"
BAR_END="▌"

# ─────────────────────────────────────────────────────────────────────────────
# HELPER: Generate progress bar with gradient
# ─────────────────────────────────────────────────────────────────────────────
generate_bar() {
    local percent=$1
    local width=12
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local bar=""

    # Color the entire bar based on overall usage level
    # Green → Yellow → Orange → Red, with red starting at 50%
    local bar_color
    if [ "$percent" -ge 90 ]; then
        bar_color="${BLINK}${NEON_RED}"
    elif [ "$percent" -ge 70 ]; then
        bar_color="${NEON_RED}"
    elif [ "$percent" -ge 50 ]; then
        bar_color="${NEON_ORANGE}"
    elif [ "$percent" -ge 35 ]; then
        bar_color="${NEON_YELLOW}"
    else
        bar_color="${NEON_GREEN}"
    fi

    for ((i=0; i<filled; i++)); do
        bar="${bar}${bar_color}${BLOCK_FULL}"
    done

    for ((i=0; i<empty; i++)); do
        bar="${bar}${DIM}\033[38;5;240m${BLOCK_LIGHT}"
    done

    echo -e "${bar}${RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
# HELPER: Format tokens (K suffix for thousands)
# ─────────────────────────────────────────────────────────────────────────────
format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000000 ] 2>/dev/null; then
        printf "%.1fM" $(echo "scale=1; $tokens / 1000000" | bc)
    elif [ "$tokens" -ge 1000 ] 2>/dev/null; then
        printf "%.1fK" $(echo "scale=1; $tokens / 1000" | bc)
    else
        printf "%d" $tokens
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# HELPER: Format cost
# ─────────────────────────────────────────────────────────────────────────────
format_cost() {
    local cost=$1
    if [ "$cost" = "0" ] || [ -z "$cost" ]; then
        printf "0.00"
    elif (( $(echo "$cost < 0.01" | bc -l 2>/dev/null || echo "0") )); then
        printf "%.3f" "$cost"
    elif (( $(echo "$cost < 10" | bc -l 2>/dev/null || echo "0") )); then
        printf "%.2f" "$cost"
    elif (( $(echo "$cost >= 1000" | bc -l 2>/dev/null || echo "0") )); then
        # Comma-separated thousands with no decimals
        printf "%'.0f" "$cost"
    else
        printf "%.0f" "$cost"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN LOGIC
# ─────────────────────────────────────────────────────────────────────────────

# If no usage data yet
if [ -z "$used" ]; then
    cum_fmt=$(format_cost "$total_cumulative")
    printf "${NEON_CYAN}${SPARK}${RESET} ${NEON_PURPLE}${model}${RESET} ${DIM}awaiting...${RESET} ${DIM}${SEP}${RESET} ${NEON_PINK}${CHART}\$${cum_fmt}${RESET} ${DIM}$(date +%b) API${RESET}"
    exit 0
fi

# Convert to integer
used_int=$(printf "%.0f" "$used")

# Calculate context window token counts (current loaded vs capacity)
context_loaded=$((current_input + current_output + current_cache_write + current_cache_read))
if [ "$used_int" -gt 0 ] && [ "$context_loaded" -gt 0 ] 2>/dev/null; then
    context_max=$(echo "scale=0; $context_loaded * 100 / $used_int" | bc 2>/dev/null || echo "0")
else
    context_max=0
fi
ctx_loaded_fmt=$(format_tokens $context_loaded)
ctx_max_fmt=$(format_tokens $context_max)

# Generate the progress bar
bar=$(generate_bar $used_int)

# Determine status icon and color based on usage
# Red zone starts at 50% as a reminder to clear context
if [ "$used_int" -ge 90 ]; then
    icon="${BLINK}${NEON_RED}${SKULL}${RESET}"
    pct_color="${BLINK}${BOLD}${NEON_RED}"
    tip=" ${DIM}→/compact${RESET}"
elif [ "$used_int" -ge 70 ]; then
    icon="${NEON_RED}${FIRE}${RESET}"
    pct_color="${BOLD}${NEON_RED}"
    tip=" ${DIM}→/compact${RESET}"
elif [ "$used_int" -ge 50 ]; then
    icon="${NEON_ORANGE}${BOLT}${RESET}"
    pct_color="${NEON_ORANGE}"
    tip=""
elif [ "$used_int" -ge 35 ]; then
    icon="${NEON_YELLOW}${BRAIN}${RESET}"
    pct_color="${NEON_YELLOW}"
    tip=""
elif [ "$used_int" -ge 15 ]; then
    icon="${NEON_GREEN}${ROCKET}${RESET}"
    pct_color="${NEON_GREEN}"
    tip=""
else
    icon="${NEON_GREEN}${SPARK}${RESET}"
    pct_color="${NEON_GREEN}"
    tip=""
fi

# Format all the data
tokens_in_fmt=$(format_tokens $total_in)
tokens_out_fmt=$(format_tokens $total_out)
session_cost_fmt=$(format_cost "$session_cost")
monthly_fmt=$(format_cost "$total_cumulative")
month_label=$(date +%b)

# ─────────────────────────────────────────────────────────────────────────────
# RENDER STATUSLINE
# ─────────────────────────────────────────────────────────────────────────────
# Format: [icon] ▐███░░░░░░░░░▌ 45% │ 💰$1.23 session │ 📊$45.67 Feb API │ 12K↓ 3K↑

if [ "$context_max" -gt 0 ] 2>/dev/null; then
    printf "${icon} ${BAR_START}${bar}${BAR_END} ${pct_color}%3d%%${RESET} ${DIM}${ctx_loaded_fmt}/${ctx_max_fmt}${RESET}" "$used_int"
else
    printf "${icon} ${BAR_START}${bar}${BAR_END} ${pct_color}%3d%%${RESET}" "$used_int"
fi
printf " ${DIM}${SEP}${RESET} ${NEON_GOLD}${MONEY}\$${session_cost_fmt}${RESET}"
printf " ${DIM}${SEP}${RESET} ${NEON_PINK}${CHART}\$${monthly_fmt}${RESET} ${DIM}${month_label} API${RESET}"
printf " ${DIM}${SEP}${RESET} ${NEON_CYAN}${tokens_in_fmt}↓${RESET}${NEON_LIME}${tokens_out_fmt}↑${RESET}"
printf "${tip}"
