#!/usr/bin/env python3
import json
import re
import sys
from collections import Counter
from pathlib import Path

niri = Path(sys.argv[1]).read_text().split("\nbinds {\n", 1)[1].split("\n}", 1)[0]
aliases = {"mod": "super", "wheelscrollup": "mouse_up", "wheelscrolldown": "mouse_down"}
modifiers = {1: "shift", 4: "ctrl", 8: "alt", 64: "super"}


def chord(parts):
    return "+".join(sorted(aliases.get(part.lower(), part.lower()) for part in parts))


expected = {
    chord(line.split()[0].split("+"))
    for line in niri.splitlines()
    if re.match(r"\s*\w+(?:\+\w+)*\s+[^/]*\{", line)
}
actual = Counter(
    chord([name for mask, name in modifiers.items() if bind["modmask"] & mask] + [bind["key"]])
    for bind in json.load(sys.stdin)
    if not bind.get("submap") or bind["submap"] == "default"
)
missing = sorted(expected - actual.keys())
extra = sorted(actual.keys() - expected)
duplicates = sorted(key for key, count in actual.items() if count > 1)
if not expected or missing or extra or duplicates:
    sys.exit(f"Missing: {missing}; extra: {extra}; duplicates: {duplicates}")
print(f"PASS: all {len(expected)} Niri chords registered in Hyprland exactly once")
