#!/usr/bin/env bash
# Rover M0 schema contract checks. Live checks use the owned real Obelisk pier.
set -euo pipefail

PIER="${1:-${ROVER_PIER:-}}"

if [ -z "$PIER" ]; then
  cat >&2 <<'USAGE'
schema-test: no pier given.

  usage: bin/schema-test.sh <pier>      e.g. bin/schema-test.sh ~/piers/rover-binbel
     or: ROVER_PIER=<pier> bin/schema-test.sh

There is deliberately no default; a hardcoded one silently tests a retired pier.

Candidate piers with a live conn.sock:
USAGE
  for p in "$HOME"/piers/*/; do
    [ -S "$p/.urb/conn.sock" ] && printf '  %s\n' "${p%/}" >&2
  done
  exit 2
fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PATH="$HOME/workspace/urbit/bin:$PATH"

fail() { echo "schema-test: FAIL - $*" >&2; exit 1; }
pass() { echo "schema-test: PASS - $*"; }

python3 - "$REPO/docs/schema-m0.sql" "$REPO/desk/lib/rover-act.hoon" <<'PY'
import pathlib
import re
import sys

source = pathlib.Path(sys.argv[1]).read_text()
hoon_source = pathlib.Path(sys.argv[2]).read_text()
ddl = "\n".join(line.split("--", 1)[0] for line in source.splitlines())
tables = re.findall(r"CREATE TABLE rover\.\.([a-z0-9-]+)", source)
if len(tables) != 79 or len(set(tables)) != 79:
    raise SystemExit(
        f"schema-test: FAIL - DDL has {len(tables)} tables, "
        f"{len(set(tables))} unique (want 79/79)"
    )

schema_arm = hoon_source.split("++  schema-m0", 1)[1].split(
    "++  display-preference-schema", 1
)[0]
hoon_tables = re.findall(
    r"CREATE TABLE rover\.\.([a-z0-9-]+)", schema_arm
)
if len(hoon_tables) != 79 or len(set(hoon_tables)) != 79:
    raise SystemExit(
        f"schema-test: FAIL - Hoon pour has {len(hoon_tables)} tables, "
        f"{len(set(hoon_tables))} unique (want 79/79)"
    )
if set(tables) != set(hoon_tables):
    raise SystemExit(
        "schema-test: FAIL - SQL/Hoon relation mismatch: "
        f"SQL-only={sorted(set(tables) - set(hoon_tables))}, "
        f"Hoon-only={sorted(set(hoon_tables) - set(tables))}"
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
if fk_count != 90 or restrict_count != 90:
    raise SystemExit(
        f"schema-test: FAIL - DDL has {fk_count} FKs and "
        f"{restrict_count} explicit RESTRICT pairs (want 90/90)"
    )
print(
    "schema-test: PASS - SQL/Hoon parity is 79/79 relations; "
    "DDL has 90 explicit RESTRICT FKs and zero forward references"
)
PY

[ -S "$PIER/.urb/conn.sock" ] ||
  fail "no conn.sock under $PIER"

click_file() {
  local body="$1" file out
  file="$(mktemp /tmp/rover-schema-test.XXXXXX.hoon)"
  printf '%s\n' "$body" > "$file"
  out="$(click -k -i "$file" "$PIER" 2>/dev/null | tail -1)"
  rm -f "$file"
  printf '%s\n' "$out"
}

database_report() {
  click -k -i "$REPO/probes/live-database-list.hoon" "$PIER" 2>/dev/null |
    tail -1
}

database_exists() {
  local report="$1" database="$2"
  grep -Fq "[%database %tas %$database]" <<<"$report"
}

obelisk_mutate() {
  local database="$1" query="$2"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-schema-test-mutation
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %$database %vector \"$query\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
}

BACKUP_DB="roverschematestowner"
DB_SWAPPED=0

restore_database() {
  local report
  [ "$DB_SWAPPED" -eq 1 ] || return 0
  report="$(database_report)"
  database_exists "$report" "$BACKUP_DB" ||
    { echo "schema-test: cleanup refused: owner backup database is absent" >&2; return 1; }
  if database_exists "$report" rover; then
    obelisk_mutate sys "DROP DATABASE FORCE rover" >/dev/null || return 1
  fi
  obelisk_mutate sys "ALTER DATABASE $BACKUP_DB RENAME TO rover" >/dev/null || return 1
  DB_SWAPPED=0
}
trap restore_database EXIT

report="$(database_report)"
database_exists "$report" rover ||
  fail "owner-facing rover database is absent"
database_exists "$report" "$BACKUP_DB" &&
  fail "fixture isolation backup database already exists: $BACKUP_DB"
obelisk_mutate sys "ALTER DATABASE rover RENAME TO $BACKUP_DB" >/dev/null
DB_SWAPPED=1
click -k -i "$REPO/probes/init-db.hoon" "$PIER" >/dev/null 2>&1
report="$(database_report)"
database_exists "$report" rover ||
  fail "fixture isolation did not create a disposable rover database"
database_exists "$report" "$BACKUP_DB" ||
  fail "fixture isolation lost the renamed owner database"

live="$(click -k -i "$REPO/probes/verify-schema.hoon" "$PIER" 2>/dev/null |
  tail -1)"
mapfile -t counts < <(
  grep -oE '%vector-count [0-9]+' <<<"$live" | awk '{print $2}'
)
[ "${#counts[@]}" -eq 3 ] ||
  fail "could not read table/column/FK counts from live metadata"
[ "${counts[0]}" -eq 79 ] ||
  fail "live Obelisk has ${counts[0]} relations (want 79)"
[ "${counts[2]}" -eq 93 ] ||
  fail "live Obelisk has ${counts[2]} FK metadata rows (want 93)"

if grep -Eq '\[%on-(delete|update) %tas %(cascade|set-default)\]' <<<"$live"; then
  fail "live Obelisk metadata contains cascade or set-default"
fi

restrict_delete="$(grep -o '\[%on-delete %tas %restrict\]' <<<"$live" | wc -l)"
restrict_update="$(grep -o '\[%on-update %tas %restrict\]' <<<"$live" | wc -l)"
[ "$restrict_delete" -eq 93 ] ||
  fail "live metadata has $restrict_delete RESTRICT deletes (want 93)"
[ "$restrict_update" -eq 93 ] ||
  fail "live metadata has $restrict_update RESTRICT updates (want 93)"

pass "fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 79 relations; all 90 FK constraints (93 column rows) are RESTRICT; zero cascade/set-default"
pass "COVERAGE - all 1 defined fixtures executed"
