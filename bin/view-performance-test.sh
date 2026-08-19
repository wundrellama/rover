#!/usr/bin/env bash
# Synthetic 420-fill wall-clock guard over real Eyre and pinned Obelisk.
set -uo pipefail

PIER="${1:-${ROVER_PIER:-}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$REPO/tests/fixtures/rover-import-synthetic.json"
FILL_COUNT="${ROVER_PERF_FILL_COUNT:-420}"
BUDGET="${ROVER_VIEW_BUDGET_SECONDS:-2.0}"

[ -n "$PIER" ] || { echo "usage: bin/view-performance-test.sh <pier>" >&2; exit 2; }
[ -S "$PIER/.urb/conn.sock" ] || { echo "view-performance-test: no live pier at $PIER" >&2; exit 2; }
case "$(basename "$PIER")" in
  rover-*) ;;
  *) echo "view-performance-test: refusing non-Rover pier $PIER" >&2; exit 2 ;;
esac

fail() { echo "view-performance-test: FAIL - $*" >&2; exit 1; }
command -v click >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || fail "click not on PATH"

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || fail "no public HTTP port"
URL="http://localhost:$PORT"
JAR="$(mktemp /tmp/rover-perf-cookie.XXXXXX)"
DOCUMENT="$(mktemp /tmp/rover-perf-data.XXXXXX.json)"
BODY="$(mktemp /tmp/rover-perf-view.XXXXXX.html)"
BACKUP_DB="roverperfowner"
SWAPPED=0

click_file() {
  local source="$1" file out
  file="$(mktemp /tmp/rover-perf-click.XXXXXX.hoon)"
  printf '%s\n' "$source" >"$file"
  out="$(click -k -i "$file" "$PIER" 2>/dev/null | tail -1)"
  rm -f "$file"
  printf '%s\n' "$out"
}

derive_code() {
  local raw decimal dotted
  raw="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
(pure:m !>(.^(@p %j /(scot %p our.bowl)/code/(scot %da now.bowl)/(scot %p our.bowl))))' \
    | sed 's/^\[0 %avow 0 %noun //; s/\]$//')"
  decimal="$(python3 -c "print(int('$raw', 0))" 2>/dev/null)" || return 1
  dotted="$(printf '%s' "$decimal" | rev | sed 's/[0-9]\{3\}/&./g' | rev | sed 's/^\.//')"
  printf '`@p`%s\n' "$dotted" | urbit eval 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
    | grep -oE '[a-z]{6}(-[a-z]{6}){3}' | head -1
}

obelisk() {
  local database="$1" query="$2"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-performance-test
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %$database %vector \"$query\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
}

databases() { obelisk sys "FROM sys.sys.databases SELECT database;"; }
database_exists() { grep -Fq "[%database %tas %$2]" <<<"$1"; }

restore_owner() {
  local report
  [ "$SWAPPED" -eq 1 ] || return 0
  report="$(databases)"
  database_exists "$report" "$BACKUP_DB" || return 1
  if database_exists "$report" rover; then
    obelisk sys "DROP DATABASE FORCE rover" >/dev/null || return 1
  fi
  obelisk sys "ALTER DATABASE $BACKUP_DB RENAME TO rover" >/dev/null || return 1
  SWAPPED=0
}

cleanup() {
  restore_owner || echo "view-performance-test: cleanup could not restore owner database" >&2
  rm -f "$JAR" "$DOCUMENT" "$BODY"
}
trap cleanup EXIT

CODE="$(derive_code)"
[ -n "$CODE" ] || fail "could not derive +code"
curl -sS -c "$JAR" -o /dev/null "$URL/~/login" --data-urlencode "password=$CODE"
grep -q urbauth "$JAR" || fail "login did not yield an auth cookie"
owner_before="$(curl -sS -b "$JAR" "$URL/apps/rover/view" | sha256sum | awk '{print $1}')"

report="$(databases)"
database_exists "$report" "$BACKUP_DB" && fail "backup database already exists"
obelisk sys "ALTER DATABASE rover RENAME TO $BACKUP_DB" >/dev/null \
  || fail "could not isolate owner database"
SWAPPED=1
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s8)
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null

python3 - "$SOURCE" "$DOCUMENT" "$FILL_COUNT" <<'PY'
import copy
import datetime as dt
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    original = json.load(source)
count = int(sys.argv[3])
vehicle = copy.deepcopy(original["vehicles"][0])
template = copy.deepcopy(vehicle["fills"][0])
vehicle["label"] = "Synthetic Performance Vehicle"
vehicle["fills"] = []
start = dt.datetime(2025, 1, 1, 8, 0)
for index in range(count):
    fill = copy.deepcopy(template)
    fill["vehicle"] = vehicle["label"]
    fill["quantity"] = "10.000"
    fill["price"] = "3.000"
    fill["tank"] = "full"
    fill["missedFill"] = "no"
    fill["observed"] = (start + dt.timedelta(hours=index)).strftime("%Y-%m-%dT%H:%M")
    fill["mileage"] = f"{1000 + index * 100}.0"
    fill["station"] = "none"
    fill["additives"] = []
    fill["tags"] = []
    fill.pop("notes", None)
    fill["sourceApp"] = "synthetic-performance"
    fill["sourceRecordId"] = f"performance-{index + 1:04d}"
    fill["sourceTotal"] = "30.00"
    for key in list(fill):
        if key.startswith("new"):
            del fill[key]
    vehicle["fills"].append(fill)
document = {
    "rover-import": 1,
    "source": {"app": "synthetic-performance"},
    "definitions": copy.deepcopy(original["definitions"]),
    "places": [],
    "vehicles": [vehicle],
}
with open(sys.argv[2], "w", encoding="utf-8") as target:
    json.dump(document, target, separators=(",", ":"), sort_keys=True)
PY

import_report="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$DOCUMENT" "$URL/apps/rover/import")"
grep -q "Fills: imported $FILL_COUNT, already-imported 0, conflicts 0, failures 0" \
  <<<"$import_report" || fail "synthetic import did not land $FILL_COUNT fills"

# History and Statistics serve the selected vehicle, and a fresh database has no
# default, so the measured page has to name one. Without this the guard timed a
# view that rendered no history at all.
perf_default="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Synthetic Performance Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle")"
[ "$perf_default" = $'Saved default vehicle\n201' ] \
  || fail "could not select the synthetic vehicle: $perf_default"

for run in 1 2; do
  timing="$(curl -sS -b "$JAR" -o "$BODY" -w '%{http_code} %{time_total} %{size_download}' \
    "$URL/apps/rover/view")"
  read -r status elapsed bytes <<<"$timing"
  [ "$status" = 200 ] || fail "run $run returned HTTP $status"
  awk -v elapsed="$elapsed" -v budget="$BUDGET" 'BEGIN { exit !(elapsed <= budget) }' \
    || fail "run $run took ${elapsed}s; budget is ${BUDGET}s"
  rows="$(grep -o 'class="history-table-row"' "$BODY" | wc -l | tr -d ' ')"
  [ "$rows" = 25 ] || fail "run $run rendered $rows history rows; expected newest 25"
  grep -q 'data-view-page="1"' "$BODY" || fail "run $run has no Older page control"
  echo "view-performance-test: run $run - ${elapsed}s, ${bytes} bytes, 25 of $FILL_COUNT fills"
done

restore_owner || fail "could not restore owner database"
owner_after="$(curl -sS -b "$JAR" "$URL/apps/rover/view" | sha256sum | awk '{print $1}')"
[ "$owner_before" = "$owner_after" ] || fail "owner view changed across performance fixture"
echo "view-performance-test: COVERAGE - synthetic $FILL_COUNT-fill view stayed within ${BUDGET}s"
