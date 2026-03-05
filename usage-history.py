#!/usr/bin/env python3
"""Claude Code API usage history — month-by-month cost and token breakdown.

Usage:
    python3 ~/.claude/usage-history.py           # all months
    python3 ~/.claude/usage-history.py --last 3   # last 3 months
    python3 ~/.claude/usage-history.py --by-model  # break down by model family
"""

import json, os, sys, time
from collections import defaultdict
from pathlib import Path

PROJECTS_DIR = Path.home() / ".claude" / "projects"

# Pricing per million tokens
PRICING = {
    "opus":   {"input": 15,   "output": 75,   "cache_write": 18.75, "cache_read": 1.5},
    "sonnet": {"input": 3,    "output": 15,   "cache_write": 3.75,  "cache_read": 0.3},
    "haiku":  {"input": 0.8,  "output": 4,    "cache_write": 1,     "cache_read": 0.08},
}

def classify_model(model_id: str) -> str:
    if "opus" in model_id:
        return "opus"
    elif "haiku" in model_id:
        return "haiku"
    return "sonnet"

def fmt_tokens(n: int) -> str:
    if n >= 1_000_000_000:
        return f"{n / 1_000_000_000:.1f}B"
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)

def fmt_cost(c: float) -> str:
    if c >= 1000:
        return f"${c:,.0f}"
    if c >= 10:
        return f"${c:.0f}"
    if c >= 0.01:
        return f"${c:.2f}"
    return f"${c:.3f}"

def scan_transcripts():
    """Scan all JSONL transcripts and return per-month, per-model stats."""
    # stats[month][model_family] = {input, output, cache_write, cache_read, cost, api_calls}
    stats = defaultdict(lambda: defaultdict(lambda: {
        "input": 0, "output": 0, "cache_write": 0, "cache_read": 0,
        "cost": 0.0, "api_calls": 0,
    }))

    if not PROJECTS_DIR.is_dir():
        return stats

    for root, _dirs, files in os.walk(PROJECTS_DIR):
        for fn in files:
            if not fn.endswith(".jsonl"):
                continue
            fp = os.path.join(root, fn)
            try:
                with open(fp, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            obj = json.loads(line)
                        except Exception:
                            continue
                        ts = obj.get("timestamp", "")
                        if len(ts) < 7:
                            continue
                        month = ts[:7]  # YYYY-MM
                        msg = obj.get("message", {})
                        if not isinstance(msg, dict):
                            continue
                        usage = msg.get("usage", {})
                        if not isinstance(usage, dict) or not usage:
                            continue
                        inp = usage.get("input_tokens", 0) or 0
                        out = usage.get("output_tokens", 0) or 0
                        cw = usage.get("cache_creation_input_tokens", 0) or 0
                        cr = usage.get("cache_read_input_tokens", 0) or 0
                        if not (inp or out):
                            continue
                        model_id = msg.get("model", "")
                        family = classify_model(model_id)
                        p = PRICING[family]
                        cost = (inp * p["input"] + out * p["output"] +
                                cw * p["cache_write"] + cr * p["cache_read"]) / 1_000_000

                        s = stats[month][family]
                        s["input"] += inp
                        s["output"] += out
                        s["cache_write"] += cw
                        s["cache_read"] += cr
                        s["cost"] += cost
                        s["api_calls"] += 1
            except Exception:
                continue

    return stats

def print_summary_table(stats, last_n=None):
    months = sorted(stats.keys())
    if last_n:
        months = months[-last_n:]

    if not months:
        print("No usage data found.")
        return

    # Header
    print()
    print("╔══════════╤════════════╤════════════╤════════════╤════════════╤══════════╗")
    print("║  Month   │    Cost    │   Input    │   Output   │   Cache    │API Calls ║")
    print("╠══════════╪════════════╪════════════╪════════════╪════════════╪══════════╣")

    grand_cost = 0
    grand_input = 0
    grand_output = 0
    grand_cache = 0
    grand_calls = 0

    for month in months:
        families = stats[month]
        m_cost = sum(f["cost"] for f in families.values())
        m_input = sum(f["input"] for f in families.values())
        m_output = sum(f["output"] for f in families.values())
        m_cache = sum(f["cache_write"] + f["cache_read"] for f in families.values())
        m_calls = sum(f["api_calls"] for f in families.values())

        grand_cost += m_cost
        grand_input += m_input
        grand_output += m_output
        grand_cache += m_cache
        grand_calls += m_calls

        print(f"║ {month}  │ {fmt_cost(m_cost):>10} │ {fmt_tokens(m_input):>10} │ {fmt_tokens(m_output):>10} │ {fmt_tokens(m_cache):>10} │ {m_calls:>8,} ║")

    print("╠══════════╪════════════╪════════════╪════════════╪════════════╪══════════╣")
    print(f"║  TOTAL   │ {fmt_cost(grand_cost):>10} │ {fmt_tokens(grand_input):>10} │ {fmt_tokens(grand_output):>10} │ {fmt_tokens(grand_cache):>10} │ {grand_calls:>8,} ║")
    print("╚══════════╧════════════╧════════════╧════════════╧════════════╧══════════╝")
    print()

def print_model_table(stats, last_n=None):
    months = sorted(stats.keys())
    if last_n:
        months = months[-last_n:]

    if not months:
        print("No usage data found.")
        return

    col_w = 22  # width per model column

    print()
    print(f"╔══════════╤{'═' * col_w}╤{'═' * col_w}╤{'═' * col_w}╗")
    print(f"║  Month   │{'Opus':^{col_w}}│{'Sonnet':^{col_w}}│{'Haiku':^{col_w}}║")
    print(f"╠══════════╪{'═' * col_w}╪{'═' * col_w}╪{'═' * col_w}╣")

    totals = {"opus": 0.0, "sonnet": 0.0, "haiku": 0.0}

    for month in months:
        families = stats[month]
        parts = []
        for fam in ("opus", "sonnet", "haiku"):
            c = families[fam]["cost"]
            totals[fam] += c
            calls = families[fam]["api_calls"]
            if c > 0:
                cell = f"{fmt_cost(c)} ({calls:,})"
                parts.append(f"{cell:^{col_w}}")
            else:
                parts.append(f"{'—':^{col_w}}")
        print(f"║ {month}  │{'│'.join(parts)}║")

    print(f"╠══════════╪{'═' * col_w}╪{'═' * col_w}╪{'═' * col_w}╣")
    parts = []
    for fam in ("opus", "sonnet", "haiku"):
        c = totals[fam]
        if c > 0:
            parts.append(f"{fmt_cost(c):^{col_w}}")
        else:
            parts.append(f"{'—':^{col_w}}")
    print(f"║  TOTAL   │{'│'.join(parts)}║")
    print(f"╚══════════╧{'═' * col_w}╧{'═' * col_w}╧{'═' * col_w}╝")
    print()

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Claude Code usage history")
    parser.add_argument("--last", type=int, help="Show only the last N months")
    parser.add_argument("--by-model", action="store_true", help="Break down by model family")
    args = parser.parse_args()

    print("Scanning transcripts...", end="", flush=True)
    stats = scan_transcripts()
    print(" done.")

    print_summary_table(stats, last_n=args.last)

    if args.by_model:
        print_model_table(stats, last_n=args.last)

if __name__ == "__main__":
    main()
