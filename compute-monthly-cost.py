#!/usr/bin/env python3
"""Scan all Claude Code transcript JSONL files and compute API-equivalent cost for the current month.
Writes result to ~/.claude/cache/monthly-cost.json atomically."""

import json, os, sys, time
from pathlib import Path

PROJECTS_DIR = Path.home() / ".claude" / "projects"
CACHE_DIR = Path.home() / ".claude" / "cache"
CACHE_FILE = CACHE_DIR / "monthly-cost.json"

# Pricing per million tokens (API rates as of early 2026)
PRICING = {
    "opus":   (15,   75,   18.75, 1.5),   # input, output, cache_write, cache_read
    "sonnet": (3,    15,   3.75,  0.3),
    "haiku":  (0.8,  4,    1,     0.08),
}

def get_pricing(model_id: str):
    if "opus" in model_id:
        return PRICING["opus"]
    elif "haiku" in model_id:
        return PRICING["haiku"]
    else:
        return PRICING["sonnet"]

def main():
    month = time.strftime("%Y-%m")
    total_cost = 0.0
    file_count = 0

    if not PROJECTS_DIR.is_dir():
        write_cache(month, 0.0)
        return

    for root, _dirs, files in os.walk(PROJECTS_DIR):
        for fn in files:
            if not fn.endswith(".jsonl"):
                continue
            fp = os.path.join(root, fn)
            file_count += 1
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
                        if not ts.startswith(month):
                            continue
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
                        p = get_pricing(model_id)
                        total_cost += (inp * p[0] + out * p[1] + cw * p[2] + cr * p[3]) / 1_000_000
            except Exception:
                continue

    write_cache(month, total_cost)

def write_cache(month: str, cost: float):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = CACHE_FILE.with_suffix(f".tmp.{os.getpid()}")
    try:
        tmp.write_text(json.dumps({
            "month": month,
            "cost": round(cost, 2),
            "updated": int(time.time()),
        }) + "\n")
        tmp.replace(CACHE_FILE)
    except Exception:
        tmp.unlink(missing_ok=True)

if __name__ == "__main__":
    main()
