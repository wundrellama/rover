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
WIDEN_BATCHED="$(mktemp /tmp/rover-import-widen-batched.XXXXXX.json)"
WIDEN_SINGLE="$(mktemp /tmp/rover-import-widen-single.XXXXXX.json)"
WIDEN_WHOLE="$(mktemp /tmp/rover-import-widen-whole.XXXXXX.json)"
WIDEN_OWNER="$(mktemp /tmp/rover-import-widen-owner.XXXXXX.json)"
WIDEN_REVIVE="$(mktemp /tmp/rover-import-widen-revive.XXXXXX.json)"
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
  rm -f "$JAR" "$CONFLICT" "$ATOMIC" "$STRESS" "$WIDEN_BATCHED" "$WIDEN_SINGLE" \
    "$WIDEN_WHOLE" "$WIDEN_OWNER" "$WIDEN_REVIVE"
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

# --- helpers for the widening fixtures 8 to 13 -------------------------------
# Each widening scenario needs its own vehicle labels and its own provenance
# keys, because the fixtures share one disposable database.
widen_document() {
  local tag="$1" target="$2"
  python3 - "$FIXTURE" "$target" "$tag" <<'PY'
import json
import sys

source, target, tag = sys.argv[1:4]
with open(source, encoding="utf-8") as handle:
    document = json.load(handle)
for vehicle in document["vehicles"]:
    label = f"{tag} {vehicle['label']}"
    vehicle["label"] = label
    for fill in vehicle["fills"]:
        fill["vehicle"] = label
        fill["sourceRecordId"] = f"{tag.lower()}-{fill['sourceRecordId']}"
with open(target, "w", encoding="utf-8") as handle:
    json.dump(document, handle, separators=(",", ":"), sort_keys=True)
PY
}

widen_upload() {
  python3 "$REPO/tools/rover-import/upload.py" "$1" \
    --url "$URL/apps/rover/import" --cookie-file "$JAR" --batch-size "$2" 2>&1
}

widen_aggregate() {
  sed -n '/^Aggregate$/,$p'
}

# Provenance rows that reached one vehicle. The label is the scenario key.
vehicle_import_count() {
  obelisk rover "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN vehicles V ON A.vehicle-id = V.vehicle-id WHERE V.label = '$1' SELECT I.source-record-id;" |
    row_count source-record-id
}

# Energy links, driving-mode links, and the default energy of one vehicle.
# archived @f prints as 1 for an active link and 0 for an archived one.
vehicle_links() {
  obelisk rover "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = '$1' SELECT E.label AS energy, L.archived AS link-archived; FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '$1' SELECT D.label AS mode, L.archived AS link-archived; FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id WHERE V.label = '$1' SELECT E.label AS default-energy;"
}

# Only the link content. The raw report also carries per-query server times,
# which differ on every read and would defeat a comparison.
vehicle_link_summary() {
  vehicle_links "$1" |
    grep -oE "\[%(energy|mode) 116 '[^']*'\] \[%link-archived 102 [01]\]|\[%default-energy 116 '[^']*'\]" |
    sort
}

expect_link() {
  local report="$1" kind="$2" label="$3" state="$4" context="$5"
  grep -Fq "[%$kind 116 '$label'] [%link-archived 102 $state]" <<<"$report" ||
    fail "$context - $kind $label is not in link state $state: $report"
}

expect_no_archived_link() {
  local report="$1" context="$2" archived
  archived="$(grep -o '\[%link-archived 102 0\]' <<<"$report" | wc -l | tr -d ' ')"
  [ "$archived" = 0 ] || fail "$context - an import archived $archived link(s): $report"
}

expect_default_energy() {
  local report="$1" label="$2" context="$3"
  grep -Fq "[%default-energy 116 '$label']" <<<"$report" ||
    fail "$context - the default energy is not $label: $report"
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

# --- Import widens an existing vehicle's links -------------------------------
# A batch that carries none of a vehicle's fills still creates the vehicle. The
# batches behind it must add the energy definitions and driving modes their own
# fills use. Ruling: ~/brain/projects/rover/import-gui.md, section "Import
# batching defect - ruled 2026-08-12". Import adds a link and revives an
# archived one. It never archives a link and never moves the default energy.

widen_document Widen2 "$WIDEN_BATCHED" || fail "could not build the batched document"
widen_batched="$(widen_upload "$WIDEN_BATCHED" 2)"
widen_batched_status=$?
[ "$widen_batched_status" = 0 ] \
  || fail "batch size 2 upload exited $widen_batched_status: $widen_batched"
widen_batched_aggregate="$(widen_aggregate <<<"$widen_batched")"
grep -q 'Fills: imported 6, already-imported 0, conflicts 0, failures 0' \
  <<<"$widen_batched_aggregate" \
  || fail "batch size 2 aggregate was wrong: $widen_batched"
grep -q 'Vehicles: created 2, reused 4' <<<"$widen_batched_aggregate" \
  || fail "batch size 2 vehicle counts were wrong: $widen_batched"
expect_count "$(vehicle_import_count 'Widen2 Synthetic Gas Car')" 3 "batched gas car"
expect_count "$(vehicle_import_count 'Widen2 Diesel Truck')" 3 "batched diesel truck"
widen_batched_links="$(vehicle_links 'Widen2 Diesel Truck')"
expect_link "$widen_batched_links" energy Diesel 1 "fixture 8"
expect_link "$widen_batched_links" mode 'Synthetic Normal' 1 "fixture 8"
expect_no_archived_link "$widen_batched_links" "fixture 8"
widen_batched_summary="$(vehicle_link_summary 'Widen2 Diesel Truck')"
run_fixture 8 "the unchanged CLI imported a two-vehicle document at batch size 2, six of six, and the vehicle a batch created without fills gained its driving mode"

widen_document Widen1 "$WIDEN_SINGLE" || fail "could not build the one-per-batch document"
widen_single="$(widen_upload "$WIDEN_SINGLE" 1)"
widen_single_status=$?
[ "$widen_single_status" = 0 ] \
  || fail "batch size 1 upload exited $widen_single_status: $widen_single"
widen_single_aggregate="$(widen_aggregate <<<"$widen_single")"
grep -q 'Fills: imported 6, already-imported 0, conflicts 0, failures 0' \
  <<<"$widen_single_aggregate" \
  || fail "batch size 1 aggregate was wrong: $widen_single"
grep -q 'Vehicles: created 2, reused 10' <<<"$widen_single_aggregate" \
  || fail "batch size 1 vehicle counts were wrong: $widen_single"
expect_count "$(vehicle_import_count 'Widen1 Synthetic Gas Car')" 3 "one-per-batch gas car"
expect_count "$(vehicle_import_count 'Widen1 Diesel Truck')" 3 "one-per-batch diesel truck"
run_fixture 9 "the same document at batch size 1 imported six of six across six batches"

widen_document Widen0 "$WIDEN_WHOLE" || fail "could not build the one-POST document"
widen_whole="$(curl -sS -b "$JAR" -H 'content-type: application/json' \
  --data-binary "@$WIDEN_WHOLE" "$URL/apps/rover/import")"
grep -q 'Fills: imported 6, already-imported 0, conflicts 0, failures 0' <<<"$widen_whole" \
  || fail "one-POST report was wrong: $widen_whole"
grep -q 'Vehicles: created 2, reused 0' <<<"$widen_whole" \
  || fail "one-POST vehicle counts were wrong: $widen_whole"
run_fixture 10 "the same document in a single POST still imported six of six"

widen_again="$(widen_upload "$WIDEN_BATCHED" 2)"
widen_again_status=$?
[ "$widen_again_status" = 0 ] \
  || fail "re-upload exited $widen_again_status: $widen_again"
widen_again_aggregate="$(widen_aggregate <<<"$widen_again")"
grep -q 'Fills: imported 0, already-imported 6, conflicts 0, failures 0' \
  <<<"$widen_again_aggregate" \
  || fail "re-upload was not an already-imported no-op: $widen_again"
expect_count "$(vehicle_import_count 'Widen2 Synthetic Gas Car')" 3 "re-uploaded gas car"
expect_count "$(vehicle_import_count 'Widen2 Diesel Truck')" 3 "re-uploaded diesel truck"
widen_again_summary="$(vehicle_link_summary 'Widen2 Diesel Truck')"
[ "$widen_again_summary" = "$widen_batched_summary" ] \
  || fail "the re-upload changed the vehicle links from '$widen_batched_summary' to '$widen_again_summary'"
run_fixture 11 "re-uploading the whole document reported already-imported for every record and changed no link"

widen_owner_created="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"label":"Widen Owner Truck","energy":"Diesel"}' \
  "$URL/apps/rover/add-vehicle")"
[ "$widen_owner_created" = "Added vehicle - Widen Owner Truck"$'\n201' ] \
  || fail "the owner could not add a vehicle by hand: $widen_owner_created"
widen_owner_before="$(vehicle_links 'Widen Owner Truck')"
expect_link "$widen_owner_before" energy Diesel 1 "fixture 12 baseline"
expect_default_energy "$widen_owner_before" Diesel "fixture 12 baseline"
if grep -q '\[%mode ' <<<"$widen_owner_before"; then
  fail "fixture 12 baseline - the hand-made vehicle already has a driving mode: $widen_owner_before"
fi
python3 - "$FIXTURE" "$WIDEN_OWNER" <<'PY'
import copy
import json
import sys

source, target = sys.argv[1:3]
with open(source, encoding="utf-8") as handle:
    original = json.load(handle)
vehicle = copy.deepcopy(original["vehicles"][0])
vehicle["label"] = "Widen Owner Truck"
vehicle["defaultEnergy"] = "Gasoline"
for fill in vehicle["fills"]:
    fill["vehicle"] = "Widen Owner Truck"
    fill["sourceRecordId"] = f"owner-{fill['sourceRecordId']}"
document = {
    "rover-import": 1,
    "source": copy.deepcopy(original["source"]),
    "definitions": copy.deepcopy(original["definitions"]),
    "places": copy.deepcopy(original["places"]),
    "vehicles": [vehicle],
}
with open(target, "w", encoding="utf-8") as handle:
    json.dump(document, handle, separators=(",", ":"), sort_keys=True)
PY
[ $? = 0 ] || fail "could not build the owner-vehicle document"
widen_owner="$(widen_upload "$WIDEN_OWNER" 1)"
widen_owner_status=$?
[ "$widen_owner_status" = 0 ] \
  || fail "owner-vehicle upload exited $widen_owner_status: $widen_owner"
grep -q 'Fills: imported 3, already-imported 0, conflicts 0, failures 0' \
  <<<"$(widen_aggregate <<<"$widen_owner")" \
  || fail "owner-vehicle aggregate was wrong: $widen_owner"
widen_owner_after="$(vehicle_links 'Widen Owner Truck')"
expect_link "$widen_owner_after" energy Diesel 1 "fixture 12"
expect_link "$widen_owner_after" energy Gasoline 1 "fixture 12"
expect_link "$widen_owner_after" mode 'Synthetic Normal' 1 "fixture 12"
expect_no_archived_link "$widen_owner_after" "fixture 12"
expect_default_energy "$widen_owner_after" Diesel "fixture 12"
run_fixture 12 "a vehicle the owner made by hand gained the links its imported fills need and kept its original default energy"

widen_revive_created="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"label":"Widen Revive Car","energy":"Gasoline","additionalEnergy":["Diesel"],"drivingModes":["Normal","Sport"]}' \
  "$URL/apps/rover/add-vehicle")"
[ "$widen_revive_created" = "Added vehicle - Widen Revive Car"$'\n201' ] \
  || fail "the owner could not add the revive vehicle: $widen_revive_created"
widen_revive_narrowed="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Widen Revive Car","label":"Widen Revive Car","defaultEnergy":"Gasoline","energySources":["Gasoline"],"drivingModes":["Normal"]}' \
  "$URL/apps/rover/edit-vehicle")"
[ "$widen_revive_narrowed" = $'Saved vehicle settings\n201' ] \
  || fail "the owner could not narrow the revive vehicle: $widen_revive_narrowed"
widen_revive_before="$(vehicle_links 'Widen Revive Car')"
expect_link "$widen_revive_before" energy Diesel 0 "fixture 13 baseline"
expect_link "$widen_revive_before" mode Sport 0 "fixture 13 baseline"
expect_link "$widen_revive_before" energy Gasoline 1 "fixture 13 baseline"
expect_link "$widen_revive_before" mode Normal 1 "fixture 13 baseline"
python3 - "$FIXTURE" "$WIDEN_REVIVE" <<'PY'
import copy
import json
import sys

source, target = sys.argv[1:3]
with open(source, encoding="utf-8") as handle:
    original = json.load(handle)
vehicle = copy.deepcopy(original["vehicles"][1])
vehicle["label"] = "Widen Revive Car"
vehicle["defaultEnergy"] = "Gasoline"
for fill in vehicle["fills"]:
    fill["vehicle"] = "Widen Revive Car"
    fill["drivingMode"] = "Sport"
    fill["sourceRecordId"] = f"revive-{fill['sourceRecordId']}"
definitions = copy.deepcopy(original["definitions"])
definitions["driving-modes"].append({"label": "Sport"})
document = {
    "rover-import": 1,
    "source": copy.deepcopy(original["source"]),
    "definitions": definitions,
    "places": copy.deepcopy(original["places"]),
    "vehicles": [vehicle],
}
with open(target, "w", encoding="utf-8") as handle:
    json.dump(document, handle, separators=(",", ":"), sort_keys=True)
PY
[ $? = 0 ] || fail "could not build the revive document"
widen_revive="$(widen_upload "$WIDEN_REVIVE" 1)"
widen_revive_status=$?
[ "$widen_revive_status" = 0 ] \
  || fail "revive upload exited $widen_revive_status: $widen_revive"
grep -q 'Fills: imported 3, already-imported 0, conflicts 0, failures 0' \
  <<<"$(widen_aggregate <<<"$widen_revive")" \
  || fail "revive aggregate was wrong: $widen_revive"
widen_revive_after="$(vehicle_links 'Widen Revive Car')"
expect_link "$widen_revive_after" energy Diesel 1 "fixture 13"
expect_link "$widen_revive_after" mode Sport 1 "fixture 13"
expect_link "$widen_revive_after" energy Gasoline 1 "fixture 13"
expect_link "$widen_revive_after" mode Normal 1 "fixture 13"
expect_no_archived_link "$widen_revive_after" "fixture 13"
expect_default_energy "$widen_revive_after" Gasoline "fixture 13"
widen_revive_summary="$(vehicle_link_summary 'Widen Revive Car')"
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %hood] %kiln-suspend !>(`@tas`%rover))
;<  ~  bind:m  (sleep ~s2)
;<  ~  bind:m  (poke [our %hood] %kiln-revive !>(`@tas`%rover))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null
widen_revive_restarted="$(vehicle_link_summary 'Widen Revive Car')"
[ "$widen_revive_restarted" = "$widen_revive_summary" ] \
  || fail "suspend/revive changed the widened links from '$widen_revive_summary' to '$widen_revive_restarted'"
run_fixture 13 "import revived the two links the owner had archived, archived none of the rest, kept the default energy, and the widened links survived a restart"

restore_owner || fail "could not restore owner database"
owner_after="$(curl -s -b "$JAR" "$URL/apps/rover/view" | sha256sum | awk '{print $1}')"
[ "$owner_before" = "$owner_after" ] \
  || fail "owner database view changed across disposable import fixtures"

executed="$(wc -w <<<"$RAN" | tr -d ' ')"
[ "$executed" = 13 ] || fail "coverage gate saw $executed of 13 fixtures"
note "COVERAGE - all 13 defined import fixtures executed"
