#!/usr/bin/env bash
# Rover import fixtures over real Eyre and the pinned Obelisk agent.
set -uo pipefail

PIER="${1:-${ROVER_PIER:-}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE="$REPO/tests/fixtures/rover-import-synthetic.json"

if [ -z "$PIER" ]; then
  echo "usage: bin/import-test.sh <pier>" >&2
  exit 2
fi

fail() { echo "import-test: FAIL - $*" >&2; exit 1; }
note() { echo "import-test: $*"; }

[ -S "$PIER/.urb/conn.sock" ] || fail "no conn.sock under $PIER"
[ -f "$FIXTURE" ] || fail "missing synthetic fixture"
command -v click >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || fail "click not on PATH"

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || fail "no public HTTP port in $PIER/.http.ports"
URL="http://localhost:$PORT"
JAR="$(mktemp /tmp/rover-import-cookie.XXXXXX)"
CONFLICT="$(mktemp /tmp/rover-import-conflict.XXXXXX.json)"
ATOMIC="$(mktemp /tmp/rover-import-atomic.XXXXXX.json)"
STRESS="$(mktemp /tmp/rover-import-stress.XXXXXX.json)"
BACKUP_DB="roverimportowner"
SWAPPED=0
RAN=""

click_file() {
  local body="$1" file out
  file="$(mktemp /tmp/rover-import-click.XXXXXX.hoon)"
  printf '%s\n' "$body" >"$file"
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
=/  wire  /rover-import-test
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %$database %vector \"$query\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
}

databases() {
  obelisk sys "FROM sys.sys.databases SELECT database;"
}

database_exists() {
  grep -Fq "[%database %tas %$2]" <<<"$1"
}

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
  restore_owner || echo "import-test: cleanup could not restore owner database" >&2
  rm -f "$JAR" "$CONFLICT" "$ATOMIC" "$STRESS"
}
trap cleanup EXIT

row_count() {
  local key="$1"
  grep -o "\[%$key " | wc -l | tr -d ' '
}

expect_count() {
  local got="$1" want="$2" label="$3"
  [ "$got" = "$want" ] || fail "$label count $got, want $want"
}

run_fixture() {
  RAN="$RAN $1"
  note "fixture $1 PASS - $2"
}

CODE="$(derive_code)"
[ -n "$CODE" ] || fail "could not derive +code"
curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
grep -q urbauth "$JAR" || fail "login did not yield an auth cookie"
owner_before="$(curl -s -b "$JAR" "$URL/apps/rover/view" | sha256sum | awk '{print $1}')"

database_report="$(databases)"
database_exists "$database_report" "$BACKUP_DB" \
  && fail "fixture backup database already exists: $BACKUP_DB"
obelisk sys "ALTER DATABASE rover RENAME TO $BACKUP_DB" >/dev/null \
  || fail "could not rename owner database"
SWAPPED=1
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s8)
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null
database_report="$(databases)"
database_exists "$database_report" rover || fail "disposable rover database was not created"
schema_probe="$(obelisk rover "FROM acquisition-imports I SELECT I.acquisition-id;")"
case "$schema_probe" in
  "[0 %avow 0 %noun 0 "*) ;;
  *) fail "disposable schema omitted acquisition-imports: $schema_probe" ;;
esac
happy="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$FIXTURE" "$URL/apps/rover/import")"
grep -q 'Fills: imported 6, already-imported 0, conflicts 0, failures 0' <<<"$happy" \
  || fail "happy-path report was wrong: $happy"
grep -q 'Definitions: created 13, reused 2' <<<"$happy" \
  || fail "happy-path definition counts were wrong: $happy"
grep -q 'Places: created 2, reused 0' <<<"$happy" \
  || fail "happy-path place counts were wrong: $happy"
grep -q 'Vehicles: created 2, reused 0' <<<"$happy" \
  || fail "happy-path vehicle counts were wrong: $happy"
grep -q 'Station-none fills: 3' <<<"$happy" \
  || fail "happy-path station-none count was wrong: $happy"
grep -q 'Total cross-check: exact 6, off-by-one 0, beyond 0' <<<"$happy" \
  || fail "happy-path total cross-check was wrong: $happy"
grep -q 'Unit mismatches: 0' <<<"$happy" \
  || fail "happy-path unit validation was wrong: $happy"

report="$(obelisk rover "FROM acquisition-imports I SELECT I.acquisition-id;")"
expect_count "$(row_count acquisition-id <<<"$report")" 6 "import provenance"
simple_definitions="$(obelisk rover "FROM additive-definitions D SELECT D.additive-id, D.label; FROM driving-mode-definitions D SELECT D.mode-id, D.label; FROM tag-definitions D SELECT D.tag-id, D.label; FROM payment-method-definitions D SELECT D.method-id, D.label;")"
expect_count "$(row_count additive-id <<<"$simple_definitions")" 3 "starter plus synthetic additive definitions"
expect_count "$(row_count mode-id <<<"$simple_definitions")" 6 "starter plus synthetic driving-mode definitions"
expect_count "$(row_count tag-id <<<"$simple_definitions")" 6 "synthetic tag definitions"
expect_count "$(row_count method-id <<<"$simple_definitions")" 5 "synthetic payment-method definitions"
breaks="$(obelisk rover "FROM economy-breaks B JOIN acquisition-imports I ON B.acquisition-id = I.acquisition-id SELECT B.reason;")"
grep -q '%missed-fill' <<<"$breaks" || fail "missed-fill economy break was absent"
preferences="$(obelisk rover "FROM vehicle-display-preferences P JOIN vehicles V ON P.vehicle-id = V.vehicle-id WHERE V.label = 'Synthetic Gas Car' OR V.label = 'Synthetic Diesel Truck' SELECT P.vehicle-id;")"
if grep -q '%vehicle-id' <<<"$preferences"; then
  fail "import created a vehicle display preference"
fi
grep -q 'Synthetic Parts Depot' <<<"$(obelisk rover "FROM places P JOIN place-address-parts A ON P.place-id = A.place-id WHERE P.label = 'Synthetic Parts Depot' SELECT P.label, A.part, A.value;")" \
  || fail "parts-only address did not land"
if grep -q 'Synthetic Parts Depot' <<<"$(obelisk rover "FROM places P JOIN place-address-formatted F ON P.place-id = F.place-id WHERE P.label = 'Synthetic Parts Depot' SELECT P.label;")"; then
  fail "parts-only address acquired invented formatted text"
fi
run_fixture 1 "seeded-parent reconciliation landed two missing energy subtypes plus the real 13-simple-definition shape, six fills, ratings, optional children, parts-only address, and no display preferences"

python3 - "$FIXTURE" "$STRESS" <<'PY'
import copy
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    original = json.load(source)
document = {
    "rover-import": 1,
    "source": {"app": "synthetic"},
    "definitions": copy.deepcopy(original["definitions"]),
    "places": [
        {
            "label": (
                f"Synthetic Driver's Stress Place {index:02d}"
                if index <= 7
                else f"Synthetic Stress Place {index:02d}"
            )
        }
        for index in range(1, 52)
    ],
    "vehicles": [],
}
energy_labels = {}
renamed_labels = {}
for definition in document["definitions"]["energy"]:
    old_label = definition["label"]
    definition["label"] = f"Synthetic Stress {old_label}"
    energy_labels[old_label] = definition["label"]
    for subtype in definition["subtypes"]:
        old_subtype = subtype["label"]
        subtype["label"] = f"Synthetic Stress {subtype['label']}"
        renamed_labels[old_subtype] = subtype["label"]
for category in ("additives", "driving-modes", "tags", "payment-methods"):
    for definition in document["definitions"][category]:
        old_label = definition["label"]
        definition["label"] = f"Synthetic Stress {definition['label']}"
        renamed_labels[old_label] = definition["label"]
for index, source_vehicle in enumerate(original["vehicles"], 1):
    vehicle = copy.deepcopy(source_vehicle)
    vehicle["label"] = (
        "Synthetic Owner's Stress Vehicle 1"
        if index == 1
        else f"Synthetic Stress Vehicle {index}"
    )
    vehicle["defaultEnergy"] = energy_labels[vehicle["defaultEnergy"]]
    vehicle.pop("tankSize", None)
    vehicle["fills"] = []
    if index == 1:
        fill = copy.deepcopy(source_vehicle["fills"][0])
        fill["vehicle"] = vehicle["label"]
        fill["definition"] = energy_labels[fill["definition"]]
        fill["subtype"] = renamed_labels[fill["subtype"]]
        fill["drivingMode"] = renamed_labels[fill["drivingMode"]]
        fill["paymentMethod"] = renamed_labels[fill["paymentMethod"]]
        fill["additives"] = [renamed_labels[label] for label in fill["additives"]]
        fill["tags"] = [renamed_labels[label] for label in fill["tags"]]
        fill["station"] = "none"
        fill["notes"] = "Synthetic first line\nSynthetic second line"
        fill["sourceApp"] = "syntheticstress"
        fill["sourceRecordId"] = "stress-apostrophe-1"
        vehicle["fills"].append(fill)
    document["vehicles"].append(vehicle)
with open(sys.argv[2], "w", encoding="utf-8") as target:
    json.dump(document, target, separators=(",", ":"), sort_keys=True)
PY
stress="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$STRESS" "$URL/apps/rover/import")"
grep -q 'Fills: imported 1, already-imported 0, conflicts 0, failures 0' <<<"$stress" \
  || fail "multi-entity ID stress report was wrong: $stress"
grep -q 'Definitions: created 15, reused 0' <<<"$stress" \
  || fail "multi-entity ID stress definition counts were wrong: $stress"
grep -q 'Places: created 51, reused 0' <<<"$stress" \
  || fail "multi-entity ID stress place counts were wrong: $stress"
grep -q 'Vehicles: created 2, reused 0' <<<"$stress" \
  || fail "multi-entity ID stress vehicle counts were wrong: $stress"
stress_places="$(obelisk rover "FROM places P SELECT P.place-id; FROM stations S SELECT S.station-id; FROM vehicles V SELECT V.vehicle-id;")"
expect_count "$(row_count place-id <<<"$stress_places")" 53 "all synthetic places"
expect_count "$(row_count station-id <<<"$stress_places")" 53 "all synthetic stations"
expect_count "$(row_count vehicle-id <<<"$stress_places")" 4 "all synthetic vehicles"
stress_again="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$STRESS" "$URL/apps/rover/import")"
grep -q 'Fills: imported 0, already-imported 1, conflicts 0, failures 0' <<<"$stress_again" \
  || fail "escaped-label/multiline-note re-import was not a no-op: $stress_again"
run_fixture 2 "one import created 51 places, two vehicles, and one fill with apostrophe-bearing labels plus a multiline note; its re-import was a no-op"

before="$(obelisk rover "FROM acquisition-imports I WHERE I.source-app = %synthetic SELECT I.acquisition-id, I.source-app, I.source-record-id;")"
before_count="$(row_count acquisition-id <<<"$before")"
again="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$FIXTURE" "$URL/apps/rover/import")"
grep -q 'Fills: imported 0, already-imported 6, conflicts 0, failures 0' <<<"$again" \
  || fail "re-import report was wrong: $again"
after="$(obelisk rover "FROM acquisition-imports I WHERE I.source-app = %synthetic SELECT I.acquisition-id, I.source-app, I.source-record-id;")"
after_count="$(row_count acquisition-id <<<"$after")"
[ "$before_count" = 6 ] || fail "re-import precondition had $before_count provenance rows, want 6"
[ "$after_count" = "$before_count" ] \
  || fail "re-import changed provenance row count from $before_count to $after_count"
run_fixture 3 "identical re-import was a six-record no-op with unchanged provenance row count"

python3 - "$FIXTURE" "$CONFLICT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    document = json.load(source)
document["vehicles"][0]["fills"][0]["quantity"] = "11.000"
document["vehicles"][0]["fills"][0]["sourceTotal"] = "33.00"
with open(sys.argv[2], "w", encoding="utf-8") as target:
    json.dump(document, target, separators=(",", ":"), sort_keys=True)
PY
conflict="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$CONFLICT" "$URL/apps/rover/import")"
grep -q 'Fills: imported 0, already-imported 5, conflicts 1, failures 0' <<<"$conflict" \
  || fail "conflict report was wrong: $conflict"
grep -q 'Conflict: Synthetic Gas Car' <<<"$conflict" \
  || fail "conflict did not name the human record: $conflict"
grep -q 'quantity' <<<"$conflict" || fail "conflict did not name the differing field"
original="$(obelisk rover "FROM acquisition-imports I JOIN fuel-fills F ON I.acquisition-id = F.acquisition-id WHERE I.source-app = %synthetic AND I.source-record-id = 'gas-1' SELECT F.quantity-milli;")"
grep -q '\[%quantity-milli 25717 10000\]' <<<"$original" \
  || fail "conflict changed the original fill: $original"
run_fixture 4 "changed provenance key reported a field-level conflict and preserved the original"

python3 - "$FIXTURE" "$ATOMIC" <<'PY'
import copy
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    original = json.load(source)
vehicle = copy.deepcopy(original["vehicles"][0])
vehicle.pop("tankSize", None)
vehicle["fills"] = []
for index, definition in enumerate(("Gasoline", "Missing Synthetic Energy", "Gasoline"), 1):
    fill = copy.deepcopy(original["vehicles"][0]["fills"][1])
    fill["definition"] = definition
    fill["observed"] = f"2026-02-0{index}T08:00"
    fill["mileage"] = f"13{index}0.0"
    fill["sourceRecordId"] = f"atomic-{index}"
    fill["missedFill"] = "no"
    vehicle["fills"].append(fill)
document = {
    "rover-import": 1,
    "source": {"app": "synthetic"},
    "definitions": {
        "energy": [],
        "additives": [],
        "driving-modes": [],
        "tags": [],
        "payment-methods": [],
    },
    "places": [],
    "vehicles": [vehicle],
}
with open(sys.argv[2], "w", encoding="utf-8") as target:
    json.dump(document, target, separators=(",", ":"), sort_keys=True)
PY
atomic="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$ATOMIC" "$URL/apps/rover/import")"
grep -q 'Fills: imported 2, already-imported 0, conflicts 0, failures 1' <<<"$atomic" \
  || fail "atomicity report was wrong: $atomic"
grep -q 'Failure: Synthetic Gas Car' <<<"$atomic" \
  || fail "atomicity failure did not name its human record: $atomic"
atomic_rows="$(obelisk rover "FROM acquisition-imports I WHERE I.source-app = %synthetic AND (I.source-record-id = 'atomic-1' OR I.source-record-id = 'atomic-2' OR I.source-record-id = 'atomic-3') SELECT I.source-record-id;")"
grep -q 'atomic-1' <<<"$atomic_rows" || fail "record before engineered failure did not land"
grep -q 'atomic-3' <<<"$atomic_rows" || fail "record after engineered failure did not land"
if grep -q 'atomic-2' <<<"$atomic_rows"; then
  fail "engineered failing record wrote provenance"
fi
run_fixture 5 "one bad middle record failed alone while earlier and later records landed"

ui_fill='{"vehicle":"Synthetic Gas Car","definition":"Gasoline","quantity":"1.000","price":"3.000","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-03-01T08:00","zone":"America/Chicago","mileage":"1400.0","mileageUnit":"mi","station":"none","additives":[],"subtype":"Synthetic 87 AKI","missedFill":"no","tags":[]}'
saved="$(curl -sS -b "$JAR" -w $'\n%{http_code}' -H 'content-type: application/json' \
  --data-raw "$ui_fill" "$URL/apps/rover/add-fill")"
grep -q $'\n201$' <<<"$saved" || fail "UI-entered control fill failed: $saved"
counts="$(obelisk rover "FROM energy-acquisitions A SELECT A.acquisition-id;")"
expect_count "$(row_count acquisition-id <<<"$counts")" 10 "all synthetic acquisitions"
served="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
if grep -Eq 'gas-1|atomic-1|sourceRecordId|source-record-id' <<<"$served"; then
  fail "source provenance appeared in owner-facing HTML"
fi
provenance="$(obelisk rover "FROM acquisition-imports I SELECT I.acquisition-id;")"
expect_count "$(row_count acquisition-id <<<"$provenance")" 9 "import-only provenance"
run_fixture 6 "provenance exists only for imports and never appears in rendered HTML"

click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %hood] %kiln-suspend !>(`@tas`%rover))
;<  ~  bind:m  (sleep ~s2)
;<  ~  bind:m  (poke [our %hood] %kiln-revive !>(`@tas`%rover))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null
persistent="$(obelisk rover "FROM acquisition-imports I SELECT I.acquisition-id;")"
expect_count "$(row_count acquisition-id <<<"$persistent")" 9 "post-restart provenance"
preferences="$(obelisk rover "FROM vehicle-display-preferences P SELECT P.vehicle-id;")"
if grep -q '%vehicle-id' <<<"$preferences"; then
  fail "post-restart import database contains a display preference"
fi
run_fixture 7 "suspend/revive preserved imported rows and provenance"

restore_owner || fail "could not restore owner database"
owner_after="$(curl -s -b "$JAR" "$URL/apps/rover/view" | sha256sum | awk '{print $1}')"
[ "$owner_before" = "$owner_after" ] \
  || fail "owner database view changed across disposable import fixtures"

executed="$(wc -w <<<"$RAN" | tr -d ' ')"
[ "$executed" = 7 ] || fail "coverage gate saw $executed of 7 fixtures"
note "COVERAGE - all 7 defined import fixtures executed"
