#!/usr/bin/env bash
# Rover M0 schema contract checks. Live checks use the owned real Obelisk pier.
set -euo pipefail

PIER="${1:-$HOME/piers/rover-bel}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PATH="$HOME/workspace/urbit/bin:$PATH"

fail() { echo "schema-test: FAIL - $*" >&2; exit 1; }
pass() { echo "schema-test: PASS - $*"; }

python3 - "$REPO/docs/schema-m0.sql" <<'PY'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1]).read_text()
ddl = "\n".join(line.split("--", 1)[0] for line in source.splitlines())
tables = re.findall(r"CREATE TABLE rover\.\.([a-z0-9-]+)", source)
if len(tables) != 64 or len(set(tables)) != 64:
    raise SystemExit(
        f"schema-test: FAIL - DDL has {len(tables)} tables, "
        f"{len(set(tables))} unique (want 64/64)"
    )

seen = set()
forward = []
for statement in source.split(";"):
    created = re.search(r"CREATE TABLE rover\.\.([a-z0-9-]+)", statement)
    if not created:
        continue
    for target in re.findall(r"REFERENCES ([a-z0-9-]+)", statement):
        if target not in seen:
            forward.append(f"{created.group(1)}->{target}")
    seen.add(created.group(1))
if forward:
    raise SystemExit(
        "schema-test: FAIL - forward FK references: " + ", ".join(forward)
    )

fk_count = len(re.findall(r"\bREFERENCES [a-z0-9-]+", ddl))
restrict_count = len(re.findall(
    r"ON DELETE RESTRICT ON UPDATE RESTRICT", ddl
))
if fk_count != 71 or restrict_count != 71:
    raise SystemExit(
        f"schema-test: FAIL - DDL has {fk_count} FKs and "
        f"{restrict_count} explicit RESTRICT pairs (want 71/71)"
    )
print(
    "schema-test: PASS - DDL has 64 unique tables, "
    "71 explicit RESTRICT FKs, zero forward references"
)
PY

[ -S "$PIER/.urb/conn.sock" ] ||
  fail "no conn.sock under $PIER"

live="$(click -k -i "$REPO/probes/verify-schema.hoon" "$PIER" 2>/dev/null |
  tail -1)"
mapfile -t counts < <(
  grep -oE '%vector-count [0-9]+' <<<"$live" | awk '{print $2}'
)
[ "${#counts[@]}" -eq 3 ] ||
  fail "could not read table/column/FK counts from live metadata"
[ "${counts[0]}" -eq 64 ] ||
  fail "live Obelisk has ${counts[0]} relations (want 64)"
[ "${counts[2]}" -eq 74 ] ||
  fail "live Obelisk has ${counts[2]} FK metadata rows (want 74)"

if grep -Eq '\[%on-(delete|update) %tas %(cascade|set-default)\]' <<<"$live"; then
  fail "live Obelisk metadata contains cascade or set-default"
fi

restrict_delete="$(grep -o '\[%on-delete %tas %restrict\]' <<<"$live" | wc -l)"
restrict_update="$(grep -o '\[%on-update %tas %restrict\]' <<<"$live" | wc -l)"
[ "$restrict_delete" -eq 74 ] ||
  fail "live metadata has $restrict_delete RESTRICT deletes (want 74)"
[ "$restrict_update" -eq 74 ] ||
  fail "live metadata has $restrict_update RESTRICT updates (want 74)"

pass "fixture 17 - live Obelisk has 64 relations; all 71 FK constraints (74 column rows) are RESTRICT; zero cascade/set-default"
