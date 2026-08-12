#!/usr/bin/env python3
"""Delete named top-level arms (++/+$) from a hoon core file.

Segment rule: an arm owns the contiguous run of `::` comment/separator
lines immediately above its `++  name` / `+$  name` line, through the
line before the next arm's leading comment run (or the closing `--`).
"""
import re
import sys

path = sys.argv[1]
names = set(sys.argv[2:])
lines = open(path).read().split("\n")

arm_re = re.compile(r"^(\+\+|\+\$)  ([a-z0-9-]+)\b")

# collect arm start indices and names
arms = []
for i, ln in enumerate(lines):
    m = arm_re.match(ln)
    if m:
        arms.append((i, m.group(2)))

# closing -- index (last line that is exactly --)
close = max(i for i, ln in enumerate(lines) if ln == "--")


def lead_start(idx):
    """First line of the contiguous ::-run immediately before line idx."""
    j = idx
    while j > 0 and lines[j - 1].startswith("::"):
        j -= 1
    return j


drop = [False] * len(lines)
found = set()
for k, (start, name) in enumerate(arms):
    if name not in names:
        continue
    found.add(name)
    nxt = arms[k + 1][0] if k + 1 < len(arms) else close
    a = lead_start(start)
    b = lead_start(nxt)  # exclusive
    for i in range(a, b):
        drop[i] = True

missing = names - found
if missing:
    sys.exit(f"arms not found: {sorted(missing)}")

out = [ln for i, ln in enumerate(lines) if not drop[i]]
open(path, "w").write("\n".join(out))
print(f"dropped {len(found)} arms, {sum(drop)} lines from {path}")
