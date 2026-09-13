#!/usr/bin/env bash
# Rover M7 T1 event-family battery. Real Eyre, real pinned Obelisk, real pier.
#
# Every write goes through the product endpoint a browser calls. Every read is
# either the served view or a urQL query that %obelisk answers. Nothing here
# pokes a fixture action, and nothing here mocks the database.
#
# The battery must give the same verdict when it runs twice back to back, so
# each run works on its own vehicle and carries a run stamp in the values it
# asserts on. The station, the tag, and the payment method are deliberately
# NOT per-run: reusing them across runs is what fixture 9 proves.
set -uo pipefail

PIER="${1:-${ROVER_PIER:-}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
ROVER_TEST_TMP="$REPO/.scratch/event-test"
mkdir -p "$ROVER_TEST_TMP"
export TMPDIR="$ROVER_TEST_TMP"

if [ -z "$PIER" ]; then
  cat >&2 <<'USAGE'
event-test: no pier given.

  usage: bin/event-test.sh <pier>     e.g. bin/event-test.sh ~/piers/rover-m7t1-bel
     or: ROVER_PIER=<pier> bin/event-test.sh

There is deliberately no default. A hardcoded one silently tests a retired pier.

Candidate piers with a live conn.sock:
USAGE
  for p in "$HOME"/piers/*/; do
    [ -S "$p/.urb/conn.sock" ] && printf '  %s\n' "${p%/}" >&2
  done
  exit 2
fi

fail() { echo "event-test: FAIL - $*" >&2; exit 1; }

_ROVER_RAN=""
note() {
  case "$*" in
    fixture\ [0-9]*)
      _ROVER_RAN="$_ROVER_RAN $(printf '%s' "$*" | awk '{print $2}')" ;;
  esac
  echo "event-test: $*"
}

[ -S "$PIER/.urb/conn.sock" ] || { echo "no conn.sock under $PIER" >&2; exit 2; }
command -v click >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || { echo "click not on PATH" >&2; exit 2; }

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || { echo "no public http port in $PIER/.http.ports" >&2; exit 2; }
URL="http://localhost:$PORT"
JAR="$(mktemp ${ROVER_TEST_TMP}/rover-event-test-jar.XXXXXX)"
ROUNDTRIP_BACKUP='roverexportowner'
ROUNDTRIP_SWAPPED=0
# M8. The real corpus loads into a database of its own, so the battery's own
# data is neither mixed with the owner's history nor changed by it, and the
# second back-to-back run meets exactly the state the first one did.
CORPUS_BACKUP='rovercorpusowner'
CORPUS_SWAPPED=0
ROUNDTRIP_BEFORE=''
ROUNDTRIP_AFTER=''
ROUNDTRIP_COUNTS_BEFORE=''
ROUNDTRIP_COUNTS_AFTER=''
ROUNDTRIP_HISTORY_BEFORE=''
ROUNDTRIP_HISTORY_AFTER=''

cleanup_event_test() {
  if [ "$ROUNDTRIP_SWAPPED" -eq 1 ]; then
    restore_roundtrip_owner >/dev/null 2>&1 ||
      echo "event-test: cleanup could not restore the pre-round-trip database" >&2
  fi
  if [ "$CORPUS_SWAPPED" -eq 1 ]; then
    restore_corpus_owner >/dev/null 2>&1 ||
      echo "event-test: cleanup could not restore the pre-corpus database" >&2
  fi
  rm -f "$JAR"
  [ -z "$ROUNDTRIP_BEFORE" ] || rm -f "$ROUNDTRIP_BEFORE"
  [ -z "$ROUNDTRIP_AFTER" ] || rm -f "$ROUNDTRIP_AFTER"
  [ -z "$ROUNDTRIP_COUNTS_BEFORE" ] || rm -f "$ROUNDTRIP_COUNTS_BEFORE"
  [ -z "$ROUNDTRIP_COUNTS_AFTER" ] || rm -f "$ROUNDTRIP_COUNTS_AFTER"
  [ -z "$ROUNDTRIP_HISTORY_BEFORE" ] || rm -f "$ROUNDTRIP_HISTORY_BEFORE"
  [ -z "$ROUNDTRIP_HISTORY_AFTER" ] || rm -f "$ROUNDTRIP_HISTORY_AFTER"
}
trap cleanup_event_test EXIT

STAMP="$(date +%s)"
VEHICLE="Event Vehicle $STAMP"
STATION='Event Fuel'
PLACE='Event Town'
TAG='Event Tag'
PAYMENT='Event Card'
SERVICE_AT='2026-08-01T09:30'
EXPENSE_AT='2026-08-02T09:30'
NOTE_AT='2026-08-03T09:30'
SERVICE_DA='~2026.08.01..09.30.00'
EXPENSE_DA='~2026.08.02..09.30.00'
NOTE_DA='~2026.08.03..09.30.00'
# Values the served view is asserted on. Each one carries the run stamp, so a
# card left behind by an earlier run can never satisfy this run's assertion.
SERVICE_ODO="$((52000 + STAMP % 1000))"
SERVICE_NOTE="Front brakes and rotors $STAMP"
EXPENSE_NOTE="Airport parking $STAMP"
NOTE_NOTE="Rattle over rough pavement $STAMP"
SERVICE_TOTAL='$412.75'
EXPENSE_TOTAL='$24.00'
# M7 T2. Three more service events, one per subtype count the corpus holds:
# ten at once, exactly one, and none at all.
MULTI_AT='2026-08-04T09:30'
SINGLE_AT='2026-08-05T09:30'
BARE_AT='2026-08-06T09:30'
MULTI_DA='~2026.08.04..09.30.00'
SINGLE_DA='~2026.08.05..09.30.00'
BARE_DA='~2026.08.06..09.30.00'
MULTI_NOTE="Major service $STAMP"
SINGLE_NOTE="Oil change only $STAMP"
BARE_NOTE="Shop visit, work unrecorded $STAMP"
MULTI_TOTAL='$1,248.10'
SINGLE_TOTAL='$68.40'
BARE_TOTAL='$95.00'
CHARGE_AT='2026-08-07T09:30'
CHARGE_DA='~2026.08.07..09.30.00'
CHARGE_ODO="$((54000 + STAMP % 1000))"
# The owner's real 2026-04-15 record carries ten subtypes at once. These ten
# are all starter-pack labels, and none is created by the event write.
MULTI_SUBTYPES='["Engine Oil","Oil Filter","Air Filter","Cabin Air Filter","Fuel Filter","Tire Rotation","Brake Fluid","Windshield Wipers","Battery","Inspection"]'
# Engine Oil is deliberately shared with the ten-subtype event. Two events
# naming one subtype must reuse one definition row, never make a second.
SINGLE_SUBTYPES='["Engine Oil"]'
# M7 T4. Buying and selling the vehicle itself. The dates run before every
# other event of this run, because a purchase opens the ownership interval the
# fills and the service visit sit inside.
BUY_AT='2026-07-01T09:00'
SELL_AT='2026-07-05T09:00'
REBUY_AT='2026-07-09T09:00'
BUY_DA='~2026.07.01..09.00.00'
SELL_DA='~2026.07.05..09.00.00'
REBUY_DA='~2026.07.09..09.00.00'
BUY_NOTE="Bought from private seller $STAMP"
SELL_NOTE="Sold to neighbour $STAMP"
REBUY_NOTE="Bought it back $STAMP"
BUY_TOTAL='$18,400.00'
SELL_TOTAL='$14,250.00'
REBUY_TOTAL='$13,900.00'
BUY_ODO="$((41000 + STAMP % 1000))"
SELL_ODO="$((49000 + STAMP % 1000))"
REBUY_ODO="$((50000 + STAMP % 1000))"
# The trade-in pair. Ruling 14: two independent events on two vehicles, with
# no relation joining them. The second vehicle exists only for this pair.
TRADE_VEHICLE="Trade Vehicle $STAMP"
TRADE_OUT_AT='2026-07-11T09:00'
TRADE_IN_AT='2026-07-11T10:00'
TRADE_OUT_DA='~2026.07.11..09.00.00'
TRADE_IN_DA='~2026.07.11..10.00.00'
TRADE_OUT_NOTE="Traded the old one in $STAMP"
TRADE_IN_NOTE="Drove the new one home $STAMP"
TRADE_OUT_TOTAL='$9,500.00'
TRADE_IN_TOTAL='$31,750.00'
TRADE_OUT_ODO="$((61000 + STAMP % 1000))"
# The vehicle fixture 32 archives. Archiving is a display state, so it must
# leave no disposal behind, and it needs a vehicle of its own to hide.
ARCHIVE_VEHICLE="Archive Vehicle $STAMP"
# M7 T12. Correcting an event. Each correction works on an event this block
# records for the purpose, so a correction can never satisfy an assertion an
# earlier fixture made, and no earlier fixture reads a value a correction moves.
FIX_VEHICLE="Correction Vehicle $STAMP"
FIX_AT='2026-08-11T09:30'
FIX_DA='~2026.08.11..09.30.00'
FIX_NOTE="Transmission service $STAMP"
FIX_TOTAL='$300.00'
FIX_TOTAL_FIXED='$355.25'
FIX_ODO="$((57000 + STAMP % 1000))"
# The sibling. It shares the vehicle and nothing else, and fixture 92 proves
# a correction beside it leaves every one of its facts alone.
SIB_AT='2026-08-12T09:30'
SIB_DA='~2026.08.12..09.30.00'
SIB_NOTE="Wiper blades $STAMP"
SIB_TOTAL='$41.00'
SIB_ODO="$((58000 + STAMP % 1000))"
# The bare event. No total, no odometer, no station, no tag, no payment
# method - so fixture 90 can add each one by correction.
BARE_EDIT_AT='2026-08-13T09:30'
BARE_EDIT_DA='~2026.08.13..09.30.00'
BARE_EDIT_NOTE="Roadside inspection $STAMP"
BARE_EDIT_TOTAL='$62.50'
BARE_EDIT_ODO="$((59000 + STAMP % 1000))"
# The event a real browser corrects in fixture 95. It is its own event so the
# pointer-driven correction cannot move a figure another fixture reads.
BROWSER_FIX_AT='2026-08-14T09:30'
BROWSER_FIX_DA='~2026.08.14..09.30.00'
BROWSER_FIX_NOTE="Browser correction $STAMP"
BROWSER_FIX_TOTAL='$120.00'
BROWSER_FIX_FIXED='$137.45'
BROWSER_FIX_ODO="$((60000 + STAMP % 1000))"
# The correction vehicle for the derived figures. Statistics reads one
# vehicle, and this one holds a purchase, a service, and nothing else, so the
# total of ownership is arithmetic a reader can check by hand.
STAT_FIX_VEHICLE="Correction Statistics Vehicle $STAMP"

click_file() {
  local body="$1" file out
  file="$(mktemp ${ROVER_TEST_TMP}/rover-event-test.XXXXXX.hoon)"
  printf '%s\n' "$body" > "$file"
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
  case "$decimal" in (''|*[!0-9]*) return 1;; esac
  dotted="$(printf '%s' "$decimal" | rev | sed 's/[0-9]\{3\}/&./g' | rev | sed 's/^\.//')"
  printf '`@p`%s\n' "$dotted" | urbit eval 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
    | grep -oE '[a-z]{6}(-[a-z]{6}){3}' | head -1
}

# A readback is one urQL script sent straight to %obelisk. The tail line of the
# click output is the typed fyrd result, and every assertion below reads it.
obelisk_report() {
  local database="$1" script="$2"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-event-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %$database %vector \"$script\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
}

rover_report() {
  obelisk_report rover "$1"
}

database_exists() {
  grep -Fq "[%database %tas %$2]" <<<"$1"
}

restore_corpus_owner() {
  local databases
  [ "$CORPUS_SWAPPED" -eq 1 ] || return 0
  databases="$(obelisk_report sys 'FROM sys.sys.databases SELECT database;')"
  database_exists "$databases" "$CORPUS_BACKUP" || return 1
  if database_exists "$databases" rover; then
    obelisk_report sys 'DROP DATABASE FORCE rover;' >/dev/null || return 1
  fi
  obelisk_report sys "ALTER DATABASE $CORPUS_BACKUP RENAME TO rover;" >/dev/null || return 1
  CORPUS_SWAPPED=0
}

restore_roundtrip_owner() {
  local databases
  [ "$ROUNDTRIP_SWAPPED" -eq 1 ] || return 0
  databases="$(obelisk_report sys 'FROM sys.sys.databases SELECT database;')"
  database_exists "$databases" "$ROUNDTRIP_BACKUP" || return 1
  if database_exists "$databases" rover; then
    obelisk_report sys 'DROP DATABASE FORCE rover;' >/dev/null || return 1
  fi
  obelisk_report sys "ALTER DATABASE $ROUNDTRIP_BACKUP RENAME TO rover;" >/dev/null || return 1
  ROUNDTRIP_SWAPPED=0
}

eyre_login() {
  local code
  code="$(derive_code)" || fail "could not derive +code"
  [ -n "$code" ] || fail "could not derive +code"
  : > "$JAR"
  curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$code"
  grep -q urbauth "$JAR" || fail "could not log in to $URL"
}

eyre_post() {
  local path="$1" payload="$2" expected="$3" label="$4" response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$payload" "$URL/apps/rover/$path")"
  [ "$response" = "$expected" ] || fail "$label: $response"
}

eyre_view() {
  curl -s -b "$JAR" -H 'content-type: application/json' \
    --data-raw '{"page":"0"}' "$URL/apps/rover/view"
}

event_payload() {
  # kind observed total mileage station tags newTag payment notes
  printf '{"vehicle":"%s","observed":"%s","zone":"America/Chicago","total":"%s","currency":"usd","mileage":"%s","mileageUnit":"mi","station":"%s","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":%s,"newTag":"%s","paymentMethod":"%s","notes":"%s"}' \
    "$VEHICLE" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
}

# M7 T4. The body a purchase or a sale sends. The kind is NOT in it: the route
# carries the kind, and fixture 33 proves a body cannot override that. The
# vehicle is an argument because a trade-in writes on two different vehicles.
ownership_payload() {
  # vehicle observed total mileage disposalKind notes
  printf '{"vehicle":"%s","observed":"%s","zone":"America/Chicago","total":"%s","currency":"usd","mileage":"%s","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":[],"disposalKind":"%s","notes":"%s"}' \
    "$1" "$2" "$3" "$4" "$5" "$6"
}

# M7 T2. The same body as event_payload, plus the subtype selection. It is a
# second helper rather than a tenth argument on the first, so the T1 fixtures
# keep sending exactly the body they sent before.
event_subtype_payload() {
  # observed total mileage station tags payment notes subtypes
  printf '{"vehicle":"%s","observed":"%s","zone":"America/Chicago","total":"%s","currency":"usd","mileage":"%s","mileageUnit":"mi","station":"%s","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":%s,"newTag":"","paymentMethod":"%s","notes":"%s","subtypes":%s}' \
    "$VEHICLE" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

# The one served event card of this kind that carries this run's unique note.
# An empty result means the card this run wrote is not in the document.
event_card() {
  local kind="$1" needle="$2"
  python3 -c '
import re, sys
document = sys.stdin.read()
kind, needle = sys.argv[1], sys.argv[2]
pattern = r"<article class=\"history-card event\" data-event-kind=\"%s\".*?</article>" % re.escape(kind)
for match in re.finditer(pattern, document, re.S):
    if needle in match.group(0):
        sys.stdout.write(match.group(0))
        break
' "$kind" "$needle" <<<"$view"
}

count_rows() {
  local report="$1" marker="$2"
  grep -o "$marker" <<<"$report" | wc -l
}

# Rows of one relation that belong to this run's event at this observed start.
scoped_rows() {
  local relation="$1" alias="$2" column="$3" observed="$4" vehicle="${5:-$VEHICLE}"
  rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN $relation $alias ON E.event-id = $alias.event-id WHERE V.label = '$vehicle' AND E.observed-start = $observed SELECT $alias.$column;"
}

# M7 T12 helpers.
#
# The report printer writes a small atom in decimal and a large one in hex, so
# no numeric assertion may compare the printed token. Every number below goes
# through this, which reads either form and returns one integer.
cell_number() {
  local report="$1" key="$2" token
  token="$(grep -oE "%$key [0-9]+ [0-9a-fx.]+" <<<"$report" | head -1 | awk '{print $3}')"
  python3 -c '
import sys
raw = sys.argv[1].replace(".", "")
print("" if not raw else int(raw, 16) if raw.startswith("0x") else int(raw))
' "$token"
}

# The event a person named, by the vehicle they picked and the moment they
# recorded. This is the identity the correction must preserve, and it is read
# as the printed token because only equality matters.
event_id_at() {
  local observed="$1" vehicle="${2:-$VEHICLE}"
  rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = '$vehicle' AND E.observed-start = $observed SELECT E.event-id;" \
    | grep -oE '%event-id [0-9]+ [0-9a-fx.]+' | head -1
}

# One event on the correction vehicle. The correction fixtures work on their
# own vehicle, so no figure an earlier fixture derived from the shared vehicle
# can move under it.
fix_payload() {
  # observed total mileage station tags payment notes subtypes
  printf '{"vehicle":"%s","observed":"%s","zone":"America/Chicago","total":"%s","currency":"usd","mileage":"%s","mileageUnit":"mi","station":"%s","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":%s,"newTag":"","paymentMethod":"%s","notes":"%s","subtypes":%s}' \
    "$FIX_VEHICLE" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

# One correction body. It carries the moment the record currently holds, so a
# correction that moves the date still finds the record it means.
edit_payload() {
  # kind observed originalObserved total mileage station tags payment notes subtypes
  printf '{"vehicle":"%s","kind":"%s","observed":"%s","originalObserved":"%s","zone":"America/Chicago","total":"%s","currency":"usd","mileage":"%s","mileageUnit":"mi","station":"%s","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":%s,"newTag":"","paymentMethod":"%s","disposalKind":"","notes":"%s","subtypes":%s}' \
    "${11:-$VEHICLE}" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}"
}

# The served view scoped to one vehicle, the way the Statistics selector asks
# for it.
scoped_event_view() {
  curl -s -b "$JAR" -H 'content-type: application/json' \
    --data-raw "$(printf '{"page":"0","vehicle":"%s"}' "$1")" "$URL/apps/rover/view"
}

# How many event cards of this kind carry this run's note. A plain text count
# over the whole document would count the same note twice, because the edit
# control carries it as well as the card body.
event_card_count() {
  local kind="$1" needle="$2"
  python3 -c '
import re, sys
document = sys.stdin.read()
kind, needle = sys.argv[1], sys.argv[2]
pattern = r"<article class=\"history-card event\" data-event-kind=\"%s\".*?</article>" % re.escape(kind)
print(sum(1 for m in re.finditer(pattern, document, re.S) if needle in m.group(0)))
' "$kind" "$needle" <<<"$view"
}

eyre_login

# ---------------------------------------------------------------------------
# fixture 1 - the owner view serves, which also bootstraps a fresh database
# ---------------------------------------------------------------------------
view="$(eyre_view)"
grep -q 'id="main-hub"' <<<"$view" \
  || fail "fixture 1 the served view has no hub: $view"
note "fixture 1 PASS - the owner view serves after bootstrap"

# ---------------------------------------------------------------------------
# fixture 2 - the definition-layer catch-up. Rover is published and installed
# on another ship, so a new relation has to reach a POPULATED database. The
# pour reads the relation list first and sends only what is absent, because
# Obelisk has no CREATE TABLE IF NOT EXISTS and a script is atomic.
# ---------------------------------------------------------------------------
ensure_def_schema() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%ensure-def-schema ~]))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(~))' > /dev/null
}
ensure_def_schema
report="$(rover_report 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
for relation in vehicle-events service-events expense-events note-events \
  vehicle-event-costs vehicle-event-cost-totals vehicle-event-odometers \
  vehicle-event-stations vehicle-event-tags vehicle-event-payment-method \
  vehicle-event-notes energy-acquisition-odometers; do
  grep -q "%name %tas %$relation" <<<"$report" \
    || fail "fixture 2 the pour is missing $relation"
done
grep -q '%name %tas %fuel-fill-odometers' <<<"$report" \
  && fail "fixture 2 the fresh pour still carries fuel-fill-odometers"
note "fixture 2 PASS - the event relations and parent-keyed energy odometer link exist after the definition-layer catch-up"
# A second run must be a no-op rather than an atomic abort on the first
# already-present relation.
ensure_def_schema
report="$(rover_report 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
grep -q '%name %tas %vehicle-events' <<<"$report" \
  || fail "fixture 2 a second catch-up run damaged the pour"
note "fixture 2 PASS - a second catch-up run changes nothing"

# ---------------------------------------------------------------------------
# fixture 3 - baseline state a real owner already has: a vehicle, a fill at a
# station, a tag, and a payment method. The event fixtures reuse all of it.
# ---------------------------------------------------------------------------
curl -s -b "$JAR" -H 'content-type: application/json' \
  --data-raw "$(printf '{"rover-import":1,"source":{"app":"rover-event-test"},"definitions":{"energy":[],"additives":[],"driving-modes":[],"tags":[{"label":"%s"}],"payment-methods":[{"label":"%s"}]},"places":[],"vehicles":[]}' "$TAG" "$PAYMENT")" \
  "$URL/apps/rover/import" > /dev/null
eyre_post add-vehicle "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":["Electricity"]}' "$VEHICLE")" \
  "$(printf 'Added vehicle - %s\n201' "$VEHICLE")" 'fixture 3 event vehicle'
report="$(rover_report "FROM stations S WHERE S.label = '$STATION' SELECT S.station-id;")"
if grep -q '%station-id' <<<"$report"; then
  station_field="$STATION"
  new_station_label=""
  new_place_label=""
else
  station_field="new"
  new_station_label="$STATION"
  new_place_label="$PLACE"
fi
eyre_post add-fill "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"12.000","price":"$3.29","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-20T12:00","zone":"America/Chicago","mileage":"52000","mileageUnit":"mi","station":"%s","newStationLabel":"%s","newPlaceLabel":"%s","newStationKind":"fuel","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' \
  "$VEHICLE" "$station_field" "$new_station_label" "$new_place_label")" \
  $'Saved fill - $3.299 - derived $39.59\n201' 'fixture 3 baseline fill'
report="$(rover_report "FROM vehicles V WHERE V.label = '$VEHICLE' SELECT V.vehicle-id; FROM stations S JOIN places P ON S.place-id = P.place-id WHERE S.label = '$STATION' SELECT S.label AS station, P.label AS place;")"
grep -q "%station 116 '$STATION'" <<<"$report" \
  || fail "fixture 3 the baseline station is absent: $report"
note "fixture 3 PASS - baseline vehicle, fill, station, tag, and payment method exist"

places_before="$(count_rows "$(rover_report 'FROM places P SELECT P.place-id;')" '%place-id')"
stations_before="$(count_rows "$(rover_report 'FROM stations S SELECT S.station-id;')" '%station-id')"

# ---------------------------------------------------------------------------
# fixture 4 - a service event with an entered total, a linked odometer, the
# station the fill already uses, a tag, a payment method, and a note
# ---------------------------------------------------------------------------
eyre_post add-service-event \
  "$(event_payload service "$SERVICE_AT" "$SERVICE_TOTAL" "$SERVICE_ODO" "$STATION" "[\"$TAG\"]" '' "$PAYMENT" "$SERVICE_NOTE")" \
  "$(printf 'Saved service event - %s\n201' "$SERVICE_TOTAL")" 'fixture 4 service event'
note "fixture 4 PASS - the service endpoint accepted an entered total"

# ---------------------------------------------------------------------------
# fixture 5 - the service event reads back through Eyre, with the total, the
# odometer, and the station on its own card
# ---------------------------------------------------------------------------
view="$(eyre_view)"
card="$(event_card service "$SERVICE_NOTE")"
[ -n "$card" ] || fail "fixture 5 no service card carrying this run's note"
grep -qF "data-event-total=\"$SERVICE_TOTAL\"" <<<"$card" \
  || fail "fixture 5 the served service card carries no entered total: $card"
odo_display="$(printf '%s' "$SERVICE_ODO" | sed 's/\([0-9]\{2\}\)\([0-9]\{3\}\)$/\1,\2/')"
grep -qF "data-event-odometer=\"$odo_display mi\"" <<<"$card" \
  || fail "fixture 5 the served service card carries no linked odometer: $card"
grep -qF "data-event-station=\"$STATION\"" <<<"$card" \
  || fail "fixture 5 the served service card carries no station: $card"
grep -qF "$TAG" <<<"$card" || fail "fixture 5 the served service card carries no tag"
grep -qF "$PAYMENT" <<<"$card" \
  || fail "fixture 5 the served service card carries no payment method"
note "fixture 5 PASS - the service event, its entered total, its odometer, its station, its tag, and its payment method read back through Eyre"

# ---------------------------------------------------------------------------
# fixture 6 - the service reading joins the vehicle's one odometer list
# ---------------------------------------------------------------------------
report="$(rover_report "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = '$VEHICLE' SELECT O.value-digits;")"
grep -q '%value-digits 25717 52000' <<<"$report" \
  || fail "fixture 6 the fill reading left the odometer list: $report"
grep -q "%value-digits 25717 $SERVICE_ODO" <<<"$report" \
  || fail "fixture 6 the service reading is not in the odometer list: $report"
note "fixture 6 PASS - fill and service readings share one odometer-observations list"

report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-odometers L ON E.event-id = L.event-id WHERE V.label = '$VEHICLE' AND E.observed-start = $SERVICE_DA SELECT L.odometer-id;")"
grep -q '%odometer-id' <<<"$report" \
  || fail "fixture 6 the event odometer link is absent: $report"
note "fixture 6 PASS - the event links to that reading through vehicle-event-odometers"

# ---------------------------------------------------------------------------
# fixture 7 - an expense event with a total and no station writes no station
# row and no odometer row
# ---------------------------------------------------------------------------
eyre_post add-expense-event \
  "$(event_payload expense "$EXPENSE_AT" "$EXPENSE_TOTAL" '' none '[]' '' '' "$EXPENSE_NOTE")" \
  "$(printf 'Saved expense event - %s\n201' "$EXPENSE_TOTAL")" 'fixture 7 expense event'
view="$(eyre_view)"
card="$(event_card expense "$EXPENSE_NOTE")"
[ -n "$card" ] || fail "fixture 7 no expense card carrying this run's note"
grep -qF "data-event-total=\"$EXPENSE_TOTAL\"" <<<"$card" \
  || fail "fixture 7 the served expense card carries no entered total: $card"
grep -q 'data-event-station=' <<<"$card" \
  && fail "fixture 7 the served expense card shows a station it does not have"
report="$(scoped_rows vehicle-event-stations L station-id "$EXPENSE_DA")"
grep -q '%station-id' <<<"$report" \
  && fail "fixture 7 a station row exists for an event that named no station: $report"
report="$(scoped_rows vehicle-event-odometers L odometer-id "$EXPENSE_DA")"
grep -q '%odometer-id' <<<"$report" \
  && fail "fixture 7 an odometer row exists for an event that recorded no mileage: $report"
note "fixture 7 PASS - the expense event reads back and wrote no sentinel station or odometer row"

# ---------------------------------------------------------------------------
# fixture 8 - a note event with no cost writes no zero-cost row
# ---------------------------------------------------------------------------
eyre_post add-note-event \
  "$(event_payload note "$NOTE_AT" '' '' none '[]' '' '' "$NOTE_NOTE")" \
  $'Saved note event\n201' 'fixture 8 note event'
view="$(eyre_view)"
card="$(event_card note "$NOTE_NOTE")"
[ -n "$card" ] || fail "fixture 8 no note card carrying this run's note"
grep -q 'data-event-total=' <<<"$card" \
  && fail "fixture 8 the served note card shows a cost it does not have"
report="$(scoped_rows vehicle-event-costs C cost-state "$NOTE_DA")"
grep -q '%cost-state' <<<"$report" \
  && fail "fixture 8 a cost row exists for an event with no cost: $report"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$NOTE_DA")"
grep -q '%total-mills' <<<"$report" \
  && fail "fixture 8 a zero-cost total row exists for an event with no cost: $report"
note "fixture 8 PASS - the note event reads back and wrote no zero-cost row"

# ---------------------------------------------------------------------------
# fixture 9 - the service event reused the fill's station, creating no
# duplicate place or station row
# ---------------------------------------------------------------------------
places_after="$(count_rows "$(rover_report 'FROM places P SELECT P.place-id;')" '%place-id')"
stations_after="$(count_rows "$(rover_report 'FROM stations S SELECT S.station-id;')" '%station-id')"
[ "$places_before" = "$places_after" ] \
  || fail "fixture 9 places grew from $places_before to $places_after"
[ "$stations_before" = "$stations_after" ] \
  || fail "fixture 9 stations grew from $stations_before to $stations_after"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-stations L ON E.event-id = L.event-id JOIN energy-acquisition-stations F ON L.station-id = F.station-id JOIN stations S ON L.station-id = S.station-id WHERE V.label = '$VEHICLE' AND E.observed-start = $SERVICE_DA SELECT S.label AS shared-station;")"
grep -q "%shared-station 116 '$STATION'" <<<"$report" \
  || fail "fixture 9 the event station is not a station a fill also uses: $report"
note "fixture 9 PASS - the service event and the fill share one station, with no duplicate place or station row"

# ---------------------------------------------------------------------------
# fixture 10 - tags, payment method, and notes attach to the family parent
# ---------------------------------------------------------------------------
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-tags L ON E.event-id = L.event-id JOIN tag-definitions T ON L.tag-id = T.tag-id WHERE V.label = '$VEHICLE' AND E.observed-start = $SERVICE_DA SELECT T.label AS tag;")"
grep -q "%tag 116 '$TAG'" <<<"$report" \
  || fail "fixture 10 the event tag link is absent: $report"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-payment-method L ON E.event-id = L.event-id JOIN payment-method-definitions P ON L.method-id = P.method-id WHERE V.label = '$VEHICLE' AND E.observed-start = $SERVICE_DA SELECT P.label AS payment-method;")"
grep -q "%payment-method 116 '$PAYMENT'" <<<"$report" \
  || fail "fixture 10 the event payment method link is absent: $report"
report="$(scoped_rows vehicle-event-notes X note "$SERVICE_DA")"
grep -qF "$SERVICE_NOTE" <<<"$report" \
  || fail "fixture 10 the event note is absent: $report"
note "fixture 10 PASS - tag, payment method, and note rows key to vehicle-events"

# ---------------------------------------------------------------------------
# fixture 11 - the kind is which typed child exists, and exactly one exists
# ---------------------------------------------------------------------------
check_child() {
  local relation="$1" alias="$2" observed="$3" want="$4" label="$5"
  local report
  report="$(scoped_rows "$relation" "$alias" event-id "$observed")"
  if [ "$want" = present ]; then
    grep -q '%event-id' <<<"$report" \
      || fail "fixture 11 $label is missing its $relation row: $report"
  else
    grep -q '%event-id' <<<"$report" \
      && fail "fixture 11 $label also has a $relation row: $report"
  fi
  return 0
}
check_child service-events S "$SERVICE_DA" present 'the service event'
check_child expense-events X "$SERVICE_DA" absent  'the service event'
check_child note-events    Z "$SERVICE_DA" absent  'the service event'
check_child expense-events X "$EXPENSE_DA" present 'the expense event'
check_child service-events S "$EXPENSE_DA" absent  'the expense event'
check_child note-events    Z "$EXPENSE_DA" absent  'the expense event'
check_child note-events    Z "$NOTE_DA"    present 'the note event'
check_child service-events S "$NOTE_DA"    absent  'the note event'
check_child expense-events X "$NOTE_DA"    absent  'the note event'
note "fixture 11 PASS - each event has exactly one typed child, and it is the right one"

report="$(rover_report 'FROM vehicle-events E SELECT E.event-id, E.vehicle-id, E.observed-start, E.observed-end, E.observed-precision, E.source-zone, E.recorded-at;')"
grep -q '%kind' <<<"$report" \
  && fail "fixture 11 vehicle-events carries a kind column"
note "fixture 11 PASS - the common header carries no kind column"

# ---------------------------------------------------------------------------
# fixture 16 - the two T2 relations exist, and the subtype link keys to
# vehicle-events. A link keyed to service-events would leave every sibling of
# that child with a hole, which is the defect ruling 11 exists to stop.
# ---------------------------------------------------------------------------
report="$(rover_report 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
for relation in service-subtype-definitions vehicle-event-service-subtypes; do
  grep -q "%name %tas %$relation" <<<"$report" \
    || fail "fixture 16 the pour is missing $relation"
done
report="$(rover_report 'FROM sys.foreign-keys WHERE child-table = %vehicle-event-service-subtypes SELECT parent-table, parent-column, child-column, on-delete, on-update;')"
grep -q '%parent-table %tas %vehicle-events' <<<"$report" \
  || fail "fixture 16 the subtype link does not key to vehicle-events: $report"
grep -q '%parent-table %tas %service-subtype-definitions' <<<"$report" \
  || fail "fixture 16 the subtype link does not key to the definition family: $report"
for child in service-events expense-events note-events; do
  grep -q "%parent-table %tas %$child" <<<"$report" \
    && fail "fixture 16 the subtype link keys to the typed child $child: $report"
done
grep -q '%on-delete %tas %restrict' <<<"$report" \
  || fail "fixture 16 the subtype link is not RESTRICT on delete: $report"
note "fixture 16 PASS - the subtype link relation keys to vehicle-events and not to a typed child"

# ---------------------------------------------------------------------------
# fixture 17 - the subtype starter pack. Rover ships ONE catalog, so the three
# labels aCar carries twice - Car Wash, Insurance, Registration - are seeded
# once each. A duplicate in the selector cannot be archived away until T8.
# ---------------------------------------------------------------------------
subtype_labels() {
  rover_report 'FROM service-subtype-definitions S SELECT S.label;'
}
report="$(subtype_labels)"
starter_count="$(count_rows "$report" '%label')"
[ "$starter_count" -ge 60 ] \
  || fail "fixture 17 the starter pack holds only $starter_count definitions"
for label in 'Engine Oil' 'Oil Filter' 'Air Filter' 'Cabin Air Filter' \
  'Fuel Filter' 'Brakes, Front' 'Brakes, Rear' 'Brake Fluid' 'Tire Rotation' \
  'Wheel Alignment' 'New Tires' 'Battery' 'Belts' 'Spark Plugs' 'Timing Belt' \
  'Transmission Fluid' 'Differential Fluid' 'Coolant System' \
  'Engine Antifreeze' 'Diesel Exhaust Fluid' 'Diesel Particulate Filter' \
  'Windshield Wipers' 'Windshield Washer Fluid' 'Inspection' 'Registration'; do
  grep -qF "%label 116 '$label'" <<<"$report" \
    || fail "fixture 17 the starter pack is missing $label"
done
for label in 'Car Wash' 'Insurance' 'Registration'; do
  seen="$(grep -cF "%label 116 '$label'" <<<"$report")"
  [ "$seen" = 1 ] \
    || fail "fixture 17 the label $label is seeded $seen times, want 1"
done
note "fixture 17 PASS - the subtype starter pack is present, and each duplicated source label is seeded once"
# The shipping %seed-starters action is a real product surface, and a second
# run of it must add nothing. This runs on every battery run, on a database
# that already holds the pack, which is exactly the case that can go wrong.
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(~))' > /dev/null
report="$(subtype_labels)"
reseeded_count="$(count_rows "$report" '%label')"
[ "$reseeded_count" = "$starter_count" ] \
  || fail "fixture 17 a second seed run grew the catalog from $starter_count to $reseeded_count"
note "fixture 17 PASS - a second starter seed adds no definition"

subtypes_before="$(count_rows "$(rover_report 'FROM service-subtype-definitions S SELECT S.service-subtype-id;')" '%service-subtype-id')"

# ---------------------------------------------------------------------------
# fixture 18 - a service event carries TEN subtypes at once and renders all
# ten. This mirrors the owner's real 2026-04-15 record.
# ---------------------------------------------------------------------------
eyre_post add-service-event \
  "$(event_subtype_payload "$MULTI_AT" "$MULTI_TOTAL" '' none '[]' '' "$MULTI_NOTE" "$MULTI_SUBTYPES")" \
  "$(printf 'Saved service event - %s\n201' "$MULTI_TOTAL")" 'fixture 18 ten-subtype service event'
report="$(scoped_rows vehicle-event-service-subtypes L service-subtype-id "$MULTI_DA")"
link_rows="$(count_rows "$report" '%service-subtype-id')"
[ "$link_rows" = 10 ] \
  || fail "fixture 18 the ten-subtype event wrote $link_rows link rows, want 10"
view="$(eyre_view)"
card="$(event_card service "$MULTI_NOTE")"
[ -n "$card" ] || fail "fixture 18 no service card carrying this run's ten-subtype note"
grep -qF 'data-event-subtype-count="10"' <<<"$card" \
  || fail "fixture 18 the served card does not report ten subtypes: $card"
for label in 'Engine Oil' 'Oil Filter' 'Air Filter' 'Cabin Air Filter' \
  'Fuel Filter' 'Tire Rotation' 'Brake Fluid' 'Windshield Wipers' 'Battery' \
  'Inspection'; do
  grep -qF "data-event-subtype=\"$label\"" <<<"$card" \
    || fail "fixture 18 the served card omits the subtype $label"
done
note "fixture 18 PASS - a service event carries ten subtypes at once and renders all ten"

# ---------------------------------------------------------------------------
# fixture 19 - one subtype, and none. Four of the owner's 39 events carry no
# subtype, and a zero-subtype event must write no link row and no sentinel.
# ---------------------------------------------------------------------------
eyre_post add-service-event \
  "$(event_subtype_payload "$SINGLE_AT" "$SINGLE_TOTAL" '' none '[]' '' "$SINGLE_NOTE" "$SINGLE_SUBTYPES")" \
  "$(printf 'Saved service event - %s\n201' "$SINGLE_TOTAL")" 'fixture 19 one-subtype service event'
eyre_post add-service-event \
  "$(event_subtype_payload "$BARE_AT" "$BARE_TOTAL" '' none '[]' '' "$BARE_NOTE" '[]')" \
  "$(printf 'Saved service event - %s\n201' "$BARE_TOTAL")" 'fixture 19 zero-subtype service event'
report="$(scoped_rows vehicle-event-service-subtypes L service-subtype-id "$SINGLE_DA")"
link_rows="$(count_rows "$report" '%service-subtype-id')"
[ "$link_rows" = 1 ] \
  || fail "fixture 19 the one-subtype event wrote $link_rows link rows, want 1"
report="$(scoped_rows vehicle-event-service-subtypes L service-subtype-id "$BARE_DA")"
grep -q '%service-subtype-id' <<<"$report" \
  && fail "fixture 19 a link row exists for an event that named no subtype: $report"
view="$(eyre_view)"
card="$(event_card service "$SINGLE_NOTE")"
[ -n "$card" ] || fail "fixture 19 no service card carrying this run's one-subtype note"
grep -qF 'data-event-subtype-count="1"' <<<"$card" \
  || fail "fixture 19 the served card does not report one subtype: $card"
grep -qF 'data-event-subtype="Engine Oil"' <<<"$card" \
  || fail "fixture 19 the served card omits its one subtype: $card"
card="$(event_card service "$BARE_NOTE")"
[ -n "$card" ] || fail "fixture 19 no service card carrying this run's zero-subtype note"
grep -q 'data-event-subtype-count=' <<<"$card" \
  && fail "fixture 19 the served card shows a subtype line it does not have: $card"
note "fixture 19 PASS - one subtype reads back, and a zero-subtype event writes no link row and no sentinel"

# ---------------------------------------------------------------------------
# fixture 20 - two events naming one subtype reuse one definition row
# ---------------------------------------------------------------------------
subtypes_after="$(count_rows "$(rover_report 'FROM service-subtype-definitions S SELECT S.service-subtype-id;')" '%service-subtype-id')"
[ "$subtypes_before" = "$subtypes_after" ] \
  || fail "fixture 20 the catalog grew from $subtypes_before to $subtypes_after while saving events"
report="$(rover_report "FROM service-subtype-definitions S WHERE S.label = 'Engine Oil' SELECT S.service-subtype-id;")"
definitions="$(count_rows "$report" '%service-subtype-id')"
[ "$definitions" = 1 ] \
  || fail "fixture 20 Engine Oil has $definitions definition rows, want 1"
# The event-id is in the projection because the pinned engine returns a SET of
# vectors: two link rows that project to one identical row come back as one.
# Selecting only the subtype id would report a single link and hide the reuse
# this fixture exists to prove.
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-service-subtypes L ON E.event-id = L.event-id JOIN service-subtype-definitions S ON L.service-subtype-id = S.service-subtype-id WHERE V.label = '$VEHICLE' AND S.label = 'Engine Oil' SELECT E.event-id, L.service-subtype-id;")"
shared="$(count_rows "$report" '%event-id')"
[ "$shared" -ge 2 ] \
  || fail "fixture 20 only $shared event links name Engine Oil, want at least 2: $report"
distinct="$(grep -o '%service-subtype-id [0-9]* 0x[0-9a-f.]*' <<<"$report" | sort -u | wc -l)"
[ "$distinct" = 1 ] \
  || fail "fixture 20 the shared subtype resolved to $distinct different definition rows: $report"
note "fixture 20 PASS - two events naming one subtype reference one definition row"

# ---------------------------------------------------------------------------
# fixture 23 - a charge records mileage through the parent-keyed energy link,
# renders it through Eyre, and shares the vehicle's one odometer stream with a
# fill. The charge is later than every other reading, so it is current.
# ---------------------------------------------------------------------------
eyre_post add-charge \
  "$(printf '{"vehicle":"%s","definition":"Electricity","start":"2026-08-07T09:00","end":"%s","zone":"America/Chicago","energyDelivered":"42.0","energySource":"charger-reported","startBattery":"20","endBattery":"80","mileage":"%s","mileageUnit":"mi","costState":"unknown","currency":"usd"}' "$VEHICLE" "$CHARGE_AT" "$CHARGE_ODO")" \
  $'Saved charge - Energy delivered 42.0 kWh\n201' 'fixture 23 charge mileage'
report="$(rover_report "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN energy-acquisition-odometers L ON A.acquisition-id = L.acquisition-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE V.label = '$VEHICLE' AND A.observed-end = $CHARGE_DA SELECT A.acquisition-id, O.value-digits, O.decimal-places, O.unit;")"
grep -q "%value-digits 25717 $CHARGE_ODO" <<<"$report" \
  || fail "fixture 23 the charge has no parent-keyed odometer link: $report"
view="$(eyre_view)"
charge_odo_display="$(printf '%s' "$CHARGE_ODO" | sed 's/\([0-9]\{2\}\)\([0-9]\{3\}\)$/\1,\2/')"
grep -qF "data-charge-odometer=\"$charge_odo_display mi\"" <<<"$view" \
  || fail "fixture 23 the charge mileage does not render through Eyre"
report="$(rover_report "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = '$VEHICLE' SELECT O.odometer-id, O.value-digits;")"
grep -q '%value-digits 25717 52000' <<<"$report" \
  || fail "fixture 23 the fill mileage left the vehicle odometer stream: $report"
grep -q "%value-digits 25717 $CHARGE_ODO" <<<"$report" \
  || fail "fixture 23 the charge mileage is absent from the vehicle odometer stream: $report"
grep -qF "CURRENT ODOMETER - DERIVED</span><strong>$charge_odo_display mi" <<<"$view" \
  || fail "fixture 23 the charge reading is not the derived current odometer"
note "fixture 23 PASS - fill and charge mileage share the parent-keyed link and one odometer stream"

# ---------------------------------------------------------------------------
# fixture 25 - the three T4 relations exist, both new children key to
# vehicle-events, and nothing keys to either child. Ruling 13 puts acquisition
# and disposal beside service, expense, and note; a relation keyed to
# vehicle-id with an "at most one" primary key would forbid buy-sell-rebuy.
# ---------------------------------------------------------------------------
report="$(rover_report 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
for relation in vehicle-acquisitions vehicle-disposals disposal-kind-definitions; do
  grep -q "%name %tas %$relation" <<<"$report" \
    || fail "fixture 25 the pour is missing $relation"
done
report="$(rover_report 'FROM sys.foreign-keys WHERE child-table = %vehicle-acquisitions SELECT parent-table, parent-column, child-column, on-delete, on-update;')"
grep -q '%parent-table %tas %vehicle-events' <<<"$report" \
  || fail "fixture 25 vehicle-acquisitions does not key to vehicle-events: $report"
grep -q '%on-delete %tas %restrict' <<<"$report" \
  || fail "fixture 25 vehicle-acquisitions is not RESTRICT on delete: $report"
grep -q '%parent-table %tas %vehicles' <<<"$report" \
  && fail "fixture 25 vehicle-acquisitions keys to vehicles, not to the event parent: $report"
report="$(rover_report 'FROM sys.foreign-keys WHERE child-table = %vehicle-disposals SELECT parent-table, parent-column, child-column, on-delete, on-update;')"
grep -q '%parent-table %tas %vehicle-events' <<<"$report" \
  || fail "fixture 25 vehicle-disposals does not key to vehicle-events: $report"
grep -q '%parent-table %tas %disposal-kind-definitions' <<<"$report" \
  || fail "fixture 25 vehicle-disposals does not key to the disposal-kind family: $report"
grep -q '%parent-table %tas %vehicles' <<<"$report" \
  && fail "fixture 25 vehicle-disposals keys to vehicles, not to the event parent: $report"
grep -q '%on-delete %tas %restrict' <<<"$report" \
  || fail "fixture 25 vehicle-disposals is not RESTRICT on delete: $report"
note "fixture 25 PASS - acquisition and disposal are typed children of vehicle-events, and the disposal names a kind definition"

# ---------------------------------------------------------------------------
# fixture 26 - the disposal-kind starter pack. Six owner-editable labels, one
# row each, and a second seed run adds nothing.
# ---------------------------------------------------------------------------
disposal_kind_labels() {
  rover_report 'FROM disposal-kind-definitions D SELECT D.label;'
}
report="$(disposal_kind_labels)"
kind_count="$(count_rows "$report" '%label')"
[ "$kind_count" -ge 6 ] \
  || fail "fixture 26 the disposal-kind pack holds only $kind_count definitions: $report"
for label in 'Sold' 'Traded In' 'Totaled' 'Scrapped' 'Gifted' 'Stolen'; do
  seen="$(grep -cF "%label 116 '$label'" <<<"$report")"
  [ "$seen" = 1 ] \
    || fail "fixture 26 the disposal kind $label is seeded $seen times, want 1"
done
report="$(rover_report 'FROM disposal-kind-definitions D SELECT D.disposal-kind-id, D.archived;')"
grep -q '%archived 102 0' <<<"$report" \
  && fail "fixture 26 a starter disposal kind was written archived: $report"
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(~))' > /dev/null
report="$(disposal_kind_labels)"
reseeded_kinds="$(count_rows "$report" '%label')"
[ "$reseeded_kinds" = "$kind_count" ] \
  || fail "fixture 26 a second seed run grew the pack from $kind_count to $reseeded_kinds"
note "fixture 26 PASS - the six disposal kinds are seeded once each, unarchived, and a second seed adds none"

# ---------------------------------------------------------------------------
# fixture 27 - a purchase saves with an entered total and a linked odometer,
# and reads back through Eyre. A purchase price has no quantity and no unit
# price, so the total is the observation and nothing is derived from it.
# ---------------------------------------------------------------------------
eyre_post add-acquisition-event \
  "$(ownership_payload "$VEHICLE" "$BUY_AT" "$BUY_TOTAL" "$BUY_ODO" '' "$BUY_NOTE")" \
  "$(printf 'Saved acquisition event - %s\n201' "$BUY_TOTAL")" 'fixture 27 purchase'
view="$(eyre_view)"
card="$(event_card acquisition "$BUY_NOTE")"
[ -n "$card" ] || fail "fixture 27 no acquisition card carrying this run's note"
grep -qF "data-event-total=\"$BUY_TOTAL\"" <<<"$card" \
  || fail "fixture 27 the served purchase card carries no entered total: $card"
buy_odo_display="$(printf '%s' "$BUY_ODO" | sed 's/\([0-9]\{2\}\)\([0-9]\{3\}\)$/\1,\2/')"
grep -qF "data-event-odometer=\"$buy_odo_display mi\"" <<<"$card" \
  || fail "fixture 27 the served purchase card carries no linked odometer: $card"
grep -q '%event-id' <<<"$(scoped_rows vehicle-acquisitions A event-id "$BUY_DA")" \
  || fail "fixture 27 the purchase has no vehicle-acquisitions row"
grep -q '%event-id' <<<"$(scoped_rows vehicle-disposals D event-id "$BUY_DA")" \
  && fail "fixture 27 the purchase also has a vehicle-disposals row"
grep -q '%event-id' <<<"$(scoped_rows service-events S event-id "$BUY_DA")" \
  && fail "fixture 27 the purchase also has a service-events row"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$BUY_DA")"
grep -q '%total-mills' <<<"$report" \
  || fail "fixture 27 the purchase wrote no entered total row: $report"
note "fixture 27 PASS - a purchase saves with an entered total and a linked odometer, and reads back through Eyre"

# ---------------------------------------------------------------------------
# fixture 28 - a sale saves with an entered total, a kind, and a linked
# odometer, and reads back with the kind on its card
# ---------------------------------------------------------------------------
eyre_post add-disposal-event \
  "$(ownership_payload "$VEHICLE" "$SELL_AT" "$SELL_TOTAL" "$SELL_ODO" 'Sold' "$SELL_NOTE")" \
  "$(printf 'Saved disposal event - %s\n201' "$SELL_TOTAL")" 'fixture 28 sale'
view="$(eyre_view)"
card="$(event_card disposal "$SELL_NOTE")"
[ -n "$card" ] || fail "fixture 28 no disposal card carrying this run's note"
grep -qF "data-event-total=\"$SELL_TOTAL\"" <<<"$card" \
  || fail "fixture 28 the served sale card carries no entered total: $card"
grep -qF 'data-event-disposal-kind="Sold"' <<<"$card" \
  || fail "fixture 28 the served sale card carries no disposal kind: $card"
sell_odo_display="$(printf '%s' "$SELL_ODO" | sed 's/\([0-9]\{2\}\)\([0-9]\{3\}\)$/\1,\2/')"
grep -qF "data-event-odometer=\"$sell_odo_display mi\"" <<<"$card" \
  || fail "fixture 28 the served sale card carries no linked odometer: $card"
grep -q '%event-id' <<<"$(scoped_rows vehicle-disposals D event-id "$SELL_DA")" \
  || fail "fixture 28 the sale has no vehicle-disposals row"
grep -q '%event-id' <<<"$(scoped_rows vehicle-acquisitions A event-id "$SELL_DA")" \
  && fail "fixture 28 the sale also has a vehicle-acquisitions row"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-disposals X ON E.event-id = X.event-id JOIN disposal-kind-definitions D ON X.disposal-kind-id = D.disposal-kind-id WHERE V.label = '$VEHICLE' AND E.observed-start = $SELL_DA SELECT D.label AS disposal-kind;")"
grep -qF "%disposal-kind 116 'Sold'" <<<"$report" \
  || fail "fixture 28 the sale does not reference the Sold definition row: $report"
# A kind the catalog does not hold is a refusal, never a silent create.
eyre_post add-disposal-event \
  "$(ownership_payload "$VEHICLE" '2026-07-06T09:00' '$1.00' '' 'Vaporised' "Impossible kind $STAMP")" \
  $'%not-found: event.disposal-kind\n422' 'fixture 28 unknown disposal kind'
report="$(disposal_kind_labels)"
after_refusal="$(count_rows "$report" '%label')"
[ "$after_refusal" = "$reseeded_kinds" ] \
  || fail "fixture 28 a refused disposal invented a kind definition: $report"
note "fixture 28 PASS - a sale saves with an entered total, a kind, and a linked odometer, and an unknown kind is refused"

# ---------------------------------------------------------------------------
# fixture 29 - the buy-sell-rebuy case. Ruling 12: a person can buy a vehicle,
# sell it, and buy it back, so "at most one acquisition" is a false constraint.
# Nothing may reject the second purchase, and all three read back in order.
# ---------------------------------------------------------------------------
eyre_post add-acquisition-event \
  "$(ownership_payload "$VEHICLE" "$REBUY_AT" "$REBUY_TOTAL" "$REBUY_ODO" '' "$REBUY_NOTE")" \
  "$(printf 'Saved acquisition event - %s\n201' "$REBUY_TOTAL")" 'fixture 29 repurchase'
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-acquisitions A ON E.event-id = A.event-id WHERE V.label = '$VEHICLE' SELECT A.event-id, E.observed-start;")"
acquisitions="$(count_rows "$report" '%event-id')"
[ "$acquisitions" = 2 ] \
  || fail "fixture 29 the vehicle carries $acquisitions acquisitions, want 2: $report"
view="$(eyre_view)"
for needle in "$BUY_NOTE" "$SELL_NOTE" "$REBUY_NOTE"; do
  grep -qF "$needle" <<<"$view" \
    || fail "fixture 29 the ownership event '$needle' is not in the served history"
done
# History runs newest first, so the repurchase card precedes the sale card and
# the sale card precedes the purchase card in the document.
order_ok="$(python3 -c '
import sys
document = sys.stdin.read()
places = [document.find(needle) for needle in sys.argv[1:]]
print("yes" if all(p >= 0 for p in places) and places == sorted(places) else "no")
' "$REBUY_NOTE" "$SELL_NOTE" "$BUY_NOTE" <<<"$view")"
[ "$order_ok" = yes ] \
  || fail "fixture 29 the purchase, sale, and repurchase do not read back in order"
note "fixture 29 PASS - one vehicle carries a purchase, a sale, and a second purchase, and all three read back in order"

# ---------------------------------------------------------------------------
# fixture 30 - a trade-in is two independent events. Ruling 14: a %traded-in
# disposal on the old vehicle and an ordinary purchase on the new one, with no
# relation joining them. The out-of-pocket figure is a rendering, never a row.
# ---------------------------------------------------------------------------
eyre_post add-vehicle "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[]}' "$TRADE_VEHICLE")" \
  "$(printf 'Added vehicle - %s\n201' "$TRADE_VEHICLE")" 'fixture 30 trade-in vehicle'
eyre_post add-disposal-event \
  "$(ownership_payload "$VEHICLE" "$TRADE_OUT_AT" "$TRADE_OUT_TOTAL" "$TRADE_OUT_ODO" 'Traded In' "$TRADE_OUT_NOTE")" \
  "$(printf 'Saved disposal event - %s\n201' "$TRADE_OUT_TOTAL")" 'fixture 30 trade-out'
eyre_post add-acquisition-event \
  "$(ownership_payload "$TRADE_VEHICLE" "$TRADE_IN_AT" "$TRADE_IN_TOTAL" '' '' "$TRADE_IN_NOTE")" \
  "$(printf 'Saved acquisition event - %s\n201' "$TRADE_IN_TOTAL")" 'fixture 30 trade-in'
# No foreign key runs between the two children in either direction, and no
# relation anywhere keys to either of them. A key in either direction would
# make one vehicle's disposal amount a property of another vehicle's purchase.
report="$(rover_report 'FROM sys.foreign-keys WHERE parent-table = %vehicle-disposals SELECT child-table;')"
grep -q '%child-table' <<<"$report" \
  && fail "fixture 30 something keys to vehicle-disposals: $report"
report="$(rover_report 'FROM sys.foreign-keys WHERE parent-table = %vehicle-acquisitions SELECT child-table;')"
grep -q '%child-table' <<<"$report" \
  && fail "fixture 30 something keys to vehicle-acquisitions: $report"
report="$(rover_report 'FROM sys.foreign-keys WHERE child-table = %vehicle-acquisitions SELECT parent-table;')"
grep -q '%parent-table %tas %vehicle-disposals' <<<"$report" \
  && fail "fixture 30 a purchase keys to a disposal: $report"
report="$(rover_report 'FROM sys.foreign-keys WHERE child-table = %vehicle-disposals SELECT parent-table;')"
grep -q '%parent-table %tas %vehicle-acquisitions' <<<"$report" \
  && fail "fixture 30 a disposal keys to a purchase: $report"
# Every column of both children, named. A join between the two vehicles would
# need a column here that holds the other side's id.
report="$(rover_report 'FROM sys.columns WHERE namespace = %dbo SELECT name, col-name;')"
disposal_columns="$(grep -oE "%name %tas %vehicle-disposals[^%]*%col-name %tas %[a-z-]+" <<<"$report" | grep -oE '%[a-z-]+$' | sort | tr '\n' ' ')"
[ "$disposal_columns" = '%disposal-kind-id %event-id ' ] \
  || fail "fixture 30 vehicle-disposals carries columns beyond its identity and its kind: $disposal_columns"
acquisition_columns="$(grep -oE "%name %tas %vehicle-acquisitions[^%]*%col-name %tas %[a-z-]+" <<<"$report" | grep -oE '%[a-z-]+$' | sort | tr '\n' ' ')"
[ "$acquisition_columns" = '%event-id ' ] \
  || fail "fixture 30 vehicle-acquisitions carries columns beyond its identity: $acquisition_columns"
# The two events sit on two different vehicles and share no row.
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-disposals X ON E.event-id = X.event-id WHERE V.label = '$TRADE_VEHICLE' SELECT X.event-id;")"
grep -q '%event-id' <<<"$report" \
  && fail "fixture 30 the newly bought vehicle carries a disposal: $report"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-acquisitions A ON E.event-id = A.event-id WHERE V.label = '$TRADE_VEHICLE' SELECT A.event-id;")"
[ "$(count_rows "$report" '%event-id')" = 1 ] \
  || fail "fixture 30 the newly bought vehicle does not carry exactly one purchase: $report"
# The out-of-pocket figure is $31,750.00 less $9,500.00. It is a rendering, so
# it must exist in no cost row and on no card.
out_of_pocket_mills=$(( 31750000 - 9500000 ))
report="$(rover_report 'FROM vehicle-event-cost-totals T SELECT T.total-mills;')"
grep -qE "%total-mills 25717 ($out_of_pocket_mills|$(printf '0x%x' $out_of_pocket_mills))" <<<"$report" \
  && fail "fixture 30 the out-of-pocket figure was stored: $report"
view="$(eyre_view)"
grep -qF '$22,250.00' <<<"$view" \
  && fail "fixture 30 the out-of-pocket figure was stored and served"
grep -qF "data-event-disposal-kind=\"Traded In\"" <<<"$(event_card disposal "$TRADE_OUT_NOTE")" \
  || fail "fixture 30 the traded-in disposal does not carry its kind"
note "fixture 30 PASS - a trade-in is two independent events, joined by no relation, and the out-of-pocket figure is stored nowhere"

# ---------------------------------------------------------------------------
# fixture 31 - the purchase and sale readings join the vehicle's one
# odometer-observations list, beside its fill and its charge readings. These
# are the endpoints T5 needs to measure the distance owned.
# ---------------------------------------------------------------------------
report="$(rover_report "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = '$VEHICLE' SELECT O.odometer-id, O.value-digits;")"
for reading in 52000 "$SERVICE_ODO" "$CHARGE_ODO" "$BUY_ODO" "$SELL_ODO" "$REBUY_ODO" "$TRADE_OUT_ODO"; do
  grep -q "%value-digits 25717 $reading" <<<"$report" \
    || fail "fixture 31 the reading $reading is not in the vehicle odometer list: $report"
done
for observed in "$BUY_DA" "$SELL_DA" "$REBUY_DA" "$TRADE_OUT_DA"; do
  report="$(scoped_rows vehicle-event-odometers L odometer-id "$observed")"
  grep -q '%odometer-id' <<<"$report" \
    || fail "fixture 31 the ownership event at $observed has no odometer link: $report"
done
note "fixture 31 PASS - purchase and sale readings share the vehicle's one odometer-observations list with its fill and charge readings"

# ---------------------------------------------------------------------------
# fixture 32 - archived keeps its meaning. Ruling 12: it is a display state.
# Selling must not set it, and archiving must not write a disposal.
# ---------------------------------------------------------------------------
report="$(rover_report "FROM vehicles V WHERE V.label = '$VEHICLE' SELECT V.label, V.archived;")"
grep -q '%archived 102 0' <<<"$report" \
  && fail "fixture 32 the sold vehicle was archived by its disposal: $report"
eyre_post add-vehicle "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[]}' "$ARCHIVE_VEHICLE")" \
  "$(printf 'Added vehicle - %s\n201' "$ARCHIVE_VEHICLE")" 'fixture 32 archive vehicle'
eyre_post remove-vehicle "$(printf '{"vehicle":"%s"}' "$ARCHIVE_VEHICLE")" \
  $'Archived vehicle\n201' 'fixture 32 archive the vehicle'
report="$(rover_report "FROM vehicles V WHERE V.label = '$ARCHIVE_VEHICLE' SELECT V.label, V.archived;")"
grep -q '%archived 102 0' <<<"$report" \
  || fail "fixture 32 the archived vehicle does not carry the flag: $report"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-disposals X ON E.event-id = X.event-id WHERE V.label = '$ARCHIVE_VEHICLE' SELECT X.event-id;")"
grep -q '%event-id' <<<"$report" \
  && fail "fixture 32 archiving a vehicle wrote a disposal: $report"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = '$ARCHIVE_VEHICLE' SELECT E.event-id;")"
grep -q '%event-id' <<<"$report" \
  && fail "fixture 32 archiving a vehicle wrote an event: $report"
note "fixture 32 PASS - selling does not set archived, and archiving writes no disposal and no event"

# ---------------------------------------------------------------------------
# fixture 33 - the route decides the kind for the two new kinds too. A client
# that names a kind in the body must not be able to choose the typed child.
# ---------------------------------------------------------------------------
FORGED_DISPOSAL_NOTE="Forged disposal $STAMP"
FORGED_ACQUISITION_NOTE="Forged acquisition $STAMP"
eyre_post add-note-event \
  "$(printf '{"vehicle":"%s","kind":"disposal","observed":"2026-07-13T09:00","zone":"America/Chicago","total":"","currency":"usd","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","disposalKind":"Sold","notes":"%s"}' \
    "$VEHICLE" "$FORGED_DISPOSAL_NOTE")" \
  $'Saved note event\n201' 'fixture 33 forged disposal on the note route'
eyre_post add-acquisition-event \
  "$(printf '{"vehicle":"%s","kind":"note","observed":"2026-07-14T09:00","zone":"America/Chicago","total":"$1.00","currency":"usd","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","disposalKind":"","notes":"%s"}' \
    "$VEHICLE" "$FORGED_ACQUISITION_NOTE")" \
  $'Saved acquisition event - $1.00\n201' 'fixture 33 forged note on the acquisition route'
view="$(eyre_view)"
[ -z "$(event_card disposal "$FORGED_DISPOSAL_NOTE")" ] \
  || fail "fixture 33 a body kind overrode the note route and made a disposal"
[ -n "$(event_card note "$FORGED_DISPOSAL_NOTE")" ] \
  || fail "fixture 33 the note route did not write a note event"
[ -z "$(event_card note "$FORGED_ACQUISITION_NOTE")" ] \
  || fail "fixture 33 a body kind overrode the acquisition route and made a note"
[ -n "$(event_card acquisition "$FORGED_ACQUISITION_NOTE")" ] \
  || fail "fixture 33 the acquisition route did not write an acquisition"
report="$(scoped_rows vehicle-disposals D event-id '~2026.07.13..09.00.00')"
grep -q '%event-id' <<<"$report" \
  && fail "fixture 33 a disposal child row exists for an event the note route wrote: $report"
note "fixture 33 PASS - the route decides the kind for acquisition and disposal, and the body cannot override it"

# ---------------------------------------------------------------------------
# M7 T5 - ownership intervals bound every derivation.
#
# Three vehicles carry the SAME four fills and the same odometer readings. Only
# the ownership events differ, so any figure that differs between them differs
# because of ownership and nothing else.
#
#   fill   date          odometer   quantity   interval        economy
#   F1     2026-05-05      40,000   12.000 gal  -              baseline
#   F2     2026-05-15      40,300   10.000 gal  300 mi         30.000 mpg
#   F3     2026-07-05      41,100   10.000 gal  800 mi         80.000 mpg
#   F4     2026-07-15      41,400   12.000 gal  300 mi         25.000 mpg
#
# GAP VEHICLE  buys 2026-05-01, sells 2026-06-01 at 40,400, buys back
# 2026-07-01 at 40,800. The F2-to-F3 interval spans the sale and the
# repurchase. The odometer rises the whole way and nothing in the readings
# looks wrong, but 500 of those 800 miles belong to whoever held the vehicle
# in between.
#
# 80.000 mpg is the MAXIMUM of the three. That is deliberate: if the gap is
# not honoured it is what BEST ECONOMY reports.
#
# OPEN VEHICLE  buys 2026-05-01 and never sells. One interval, no gap.
# BARE VEHICLE  neither buys nor sells. Every installed database is in this
# state, and its figures must be exactly what they were before T5.
# ---------------------------------------------------------------------------
GAP_VEHICLE="Ownership Gap Vehicle $STAMP"
OPEN_VEHICLE="Ownership Open Vehicle $STAMP"
BARE_VEHICLE="Ownership Bare Vehicle $STAMP"
DEF_GAP_VEHICLE="Ownership DEF Gap Vehicle $STAMP"
DEF_BARE_VEHICLE="Ownership DEF Bare Vehicle $STAMP"

own_add_vehicle() {
  eyre_post add-vehicle "$(printf '{"label":"%s","energy":"%s","additionalEnergy":[]}' "$1" "$2")" \
    "$(printf 'Added vehicle - %s\n201' "$1")" "T5 vehicle $1"
}

# A fill write whose derived total is not what this fixture is about. The
# response code is asserted; the money is asserted by the fill battery.
own_add_fill() {
  # vehicle observed odometer quantity
  local response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"%s","price":"$3.29","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"%s","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' \
      "$1" "$4" "$2" "$3")" \
    "$URL/apps/rover/add-fill")"
  case "$response" in
    *$'\n'201)  ;;
    *)  fail "T5 fill on $1 at $2: $response" ;;
  esac
}

own_add_ownership_event() {
  # route vehicle observed total odometer disposalKind
  local response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(ownership_payload "$2" "$3" "$4" "$5" "$6" "$2 $3")" \
    "$URL/apps/rover/$1")"
  case "$response" in
    *$'\n'201)  ;;
    *)  fail "T5 $1 on $2 at $3: $response" ;;
  esac
}

set_default_vehicle() {
  local response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s"}' "$1")" \
    "$URL/apps/rover/set-default-vehicle")"
  [ "$response" = $'Saved default vehicle\n201' ] \
    || fail "T5 could not make $1 the default vehicle: $response"
}

# The served view scoped to one vehicle. The statistics screen renders the
# vehicle named here; the hub always renders the app default.
eyre_view_vehicle() {
  curl -s -b "$JAR" -H 'content-type: application/json' \
    --data-raw "$(printf '{"page":"0","vehicle":"%s"}' "$1")" "$URL/apps/rover/view"
}

# The value of one hub readout, by the label above it.
hub_readout() {
  python3 -c '
import re, sys
document = sys.stdin.read()
found = re.search(
    r"<article[^>]*><span>%s</span><strong>(.*?)</strong>" % re.escape(sys.argv[1]),
    document, re.S)
sys.stdout.write(found.group(1) if found else "")
' "$1"
}

# Every economy cell of the statistics economy table, newest fill first, one
# per line. A cell is either a figure or the word Unavailable.
economy_cells() {
  python3 -c '
import re, sys
document = sys.stdin.read()
table = re.search(r"data-statistic=\"economy-by-subtype\".*?</section>", document, re.S)
if table:
    for row in re.finditer(r"data-economy=\"(.*?)\"", table.group(0), re.S):
        print(row.group(1))
'
}

# Every figure cell of one interval statistics table, newest fill first, one
# per line, each with the break term the row carries.
interval_cells() {
  python3 -c '
import re, sys
document = sys.stdin.read()
table = re.search(r"data-statistic=\"%s\".*?</section>" % re.escape(sys.argv[1]), document, re.S)
if not table:
    sys.exit(0)
for row in re.finditer(r"<tr data-statistics-vehicle=.*?</tr>", table.group(0), re.S):
    cells = re.findall(r"<td>(.*?)</td>", row.group(0), re.S)
    brk = re.search(r"data-interval-break=\"(.*?)\"", row.group(0))
    print("%s %s" % (cells[1], brk.group(1) if brk else "-"))
' "$1"
}

# The whole economy row whose figure cell holds this value.
economy_row() {
  python3 -c '
import re, sys
document = sys.stdin.read()
table = re.search(r"data-statistic=\"economy-by-subtype\".*?</section>", document, re.S)
if not table:
    sys.exit(0)
for row in re.finditer(r"<tr [^>]*data-economy-vehicle=.*?</tr>", table.group(0), re.S):
    if "data-economy=\"%s\"" % sys.argv[1] in row.group(0):
        sys.stdout.write(row.group(0))
        break
' "$1"
}

own_seed_fills() {
  own_add_fill "$1" '2026-05-05T12:00' 40000 12.000
  own_add_fill "$1" '2026-05-15T12:00' 40300 10.000
  own_add_fill "$1" '2026-07-05T12:00' 41100 10.000
  own_add_fill "$1" '2026-07-15T12:00' 41400 12.000
}

own_add_vehicle "$GAP_VEHICLE" Gasoline
own_add_vehicle "$OPEN_VEHICLE" Gasoline
own_add_vehicle "$BARE_VEHICLE" Gasoline
own_seed_fills "$GAP_VEHICLE"
own_seed_fills "$OPEN_VEHICLE"
own_seed_fills "$BARE_VEHICLE"
own_add_ownership_event add-acquisition-event "$GAP_VEHICLE" '2026-05-01T09:00' '$18,000.00' 39800 ''
own_add_ownership_event add-disposal-event "$GAP_VEHICLE" '2026-06-01T09:00' '$16,400.00' 40400 'Sold'
own_add_ownership_event add-acquisition-event "$GAP_VEHICLE" '2026-07-01T09:00' '$16,900.00' 40800 ''
own_add_ownership_event add-acquisition-event "$OPEN_VEHICLE" '2026-05-01T09:00' '$18,000.00' 39800 ''

# ---------------------------------------------------------------------------
# fixture 36 - the fixture that decides the task. The cross-gap interval would
# be the best economy on record. Asserting that a break exists proves nothing,
# because the write side and the read side are separate code and the historical
# defect was a correct break row that the read side ignored. So this asserts on
# the AGGREGATE: the served BEST ECONOMY readout.
# ---------------------------------------------------------------------------
set_default_vehicle "$GAP_VEHICLE"
view="$(eyre_view)"
gap_best="$(hub_readout 'BEST ECONOMY' <<<"$view")"
[ "$gap_best" != '80.000 mpg' ] \
  || fail "fixture 36 the cross-gap interval is reported as the best economy: BEST ECONOMY = $gap_best"
[ "$gap_best" = '30.000 mpg' ] \
  || fail "fixture 36 the best economy is not the within-ownership figure 30.000 mpg: $gap_best"
gap_worst="$(hub_readout 'WORST ECONOMY' <<<"$view")"
[ "$gap_worst" = '25.000 mpg' ] \
  || fail "fixture 36 the worst economy is not 25.000 mpg: $gap_worst"
note "fixture 36 PASS - the cross-gap interval is not reported as best economy, and the reported best is the within-ownership figure"

# ---------------------------------------------------------------------------
# fixture 37 - the cross-gap interval does not enter the mean either. With the
# gap honoured the mean is of 30.000 and 25.000. With it ignored 80.000 joins
# them and the mean is 45.000.
# ---------------------------------------------------------------------------
gap_mean="$(hub_readout 'ECONOMY - LIFETIME' <<<"$view")"
[ "$gap_mean" != '45.000 mpg' ] \
  || fail "fixture 37 the cross-gap interval entered the mean: ECONOMY - LIFETIME = $gap_mean"
[ "$gap_mean" = '27.500 mpg' ] \
  || fail "fixture 37 the mean is not the mean of the two within-ownership intervals: $gap_mean"
note "fixture 37 PASS - the cross-gap interval does not enter the mean"

# ---------------------------------------------------------------------------
# fixture 38 - the cross-gap interval renders unavailable with a human reason
# that names the ownership gap. It never renders as zero, and the reason is a
# sentence rather than a term dump.
# ---------------------------------------------------------------------------
view="$(eyre_view_vehicle "$GAP_VEHICLE")"
mapfile -t gap_cells < <(economy_cells <<<"$view")
[ "${#gap_cells[@]}" = 4 ] \
  || fail "fixture 38 the economy table has ${#gap_cells[@]} rows, want 4: ${gap_cells[*]}"
[ "${gap_cells[0]}" = '25.000 mpg' ] \
  || fail "fixture 38 the newest interval is ${gap_cells[0]}, want 25.000 mpg"
[ "${gap_cells[1]}" = 'Unavailable' ] \
  || fail "fixture 38 the cross-gap interval renders ${gap_cells[1]}, want Unavailable"
[ "${gap_cells[1]}" != '0.000 mpg' ] \
  || fail "fixture 38 the cross-gap interval rendered as zero"
gap_row="$(economy_row Unavailable <<<"$view")"
grep -q 'data-economy-break="%ownership-gap"' <<<"$gap_row" \
  || fail "fixture 38 the unavailable interval carries no ownership break: $gap_row"
grep -qF 'The vehicle was not owned for part of this interval' <<<"$gap_row" \
  || fail "fixture 38 the unavailable interval gives no human ownership reason: $gap_row"
grep -q 'ownership-gap</td>' <<<"$gap_row" \
  && fail "fixture 38 the eligibility cell dumps the term instead of a sentence: $gap_row"
# The bound covers every figure derived across the interval, not the economy
# alone. Distance between fills and time between fills are the other two.
mapfile -t gap_distance < <(interval_cells distance-between-fills <<<"$view")
distance_expected=('300.000 mi -' 'Unavailable %ownership-gap' '300.000 mi -' 'Unavailable -')
[ "${gap_distance[*]}" = "${distance_expected[*]}" ] \
  || fail "fixture 38 the distance figures are ${gap_distance[*]}, want ${distance_expected[*]}"
mapfile -t gap_time < <(interval_cells time-between-fills <<<"$view")
time_expected=('240.000 h -' 'Unavailable %ownership-gap' '240.000 h -' 'Unavailable -')
[ "${gap_time[*]}" = "${time_expected[*]}" ] \
  || fail "fixture 38 the elapsed-time figures are ${gap_time[*]}, want ${time_expected[*]}"
note "fixture 38 PASS - the cross-gap economy, distance, and elapsed-time figures all render unavailable with a human reason naming the ownership gap, and none renders as zero"

# ---------------------------------------------------------------------------
# fixture 39 - a within-ownership interval on the same vehicle still computes.
# The break is bounded to the gap; it does not swallow the whole vehicle.
# ---------------------------------------------------------------------------
[ "${gap_cells[2]}" = '30.000 mpg' ] \
  || fail "fixture 39 the interval inside the first ownership period is ${gap_cells[2]}, want 30.000 mpg"
[ "${gap_cells[3]}" = 'Unavailable' ] \
  || fail "fixture 39 the first fill of the record is ${gap_cells[3]}, want Unavailable"
within_row="$(economy_row '30.000 mpg' <<<"$view")"
grep -q 'data-economy-break=' <<<"$within_row" \
  && fail "fixture 39 a within-ownership interval carries a break: $within_row"
grep -qF 'Eligible full-fill interval.' <<<"$within_row" \
  || fail "fixture 39 a within-ownership interval is not labelled eligible: $within_row"
note "fixture 39 PASS - a within-ownership interval on the same vehicle still computes"

# ---------------------------------------------------------------------------
# fixture 40 - the compatibility rule. A vehicle with no acquisition and no
# disposal derives exactly what it derived before T5. Its fills, odometers and
# quantities are identical to the gap vehicle's, so 80.000 mpg still stands as
# the best and still enters the mean.
# ---------------------------------------------------------------------------
set_default_vehicle "$BARE_VEHICLE"
view="$(eyre_view)"
bare_best="$(hub_readout 'BEST ECONOMY' <<<"$view")"
[ "$bare_best" = '80.000 mpg' ] \
  || fail "fixture 40 T5 changed the best economy of a vehicle with no ownership events: $bare_best"
bare_mean="$(hub_readout 'ECONOMY - LIFETIME' <<<"$view")"
[ "$bare_mean" = '45.000 mpg' ] \
  || fail "fixture 40 T5 changed the mean of a vehicle with no ownership events: $bare_mean"
bare_worst="$(hub_readout 'WORST ECONOMY' <<<"$view")"
[ "$bare_worst" = '25.000 mpg' ] \
  || fail "fixture 40 T5 changed the worst economy of a vehicle with no ownership events: $bare_worst"
bare_last="$(hub_readout 'ECONOMY - LAST FILL' <<<"$view")"
[ "$bare_last" = '25.000 mpg' ] \
  || fail "fixture 40 T5 changed the last-fill economy of a vehicle with no ownership events: $bare_last"
view="$(eyre_view_vehicle "$BARE_VEHICLE")"
mapfile -t bare_cells < <(economy_cells <<<"$view")
bare_expected=('25.000 mpg' '80.000 mpg' '30.000 mpg' 'Unavailable')
[ "${bare_cells[*]}" = "${bare_expected[*]}" ] \
  || fail "fixture 40 T5 changed a per-interval figure with no ownership events: ${bare_cells[*]}"
mapfile -t bare_distance < <(interval_cells distance-between-fills <<<"$view")
bare_distance_expected=('300.000 mi -' '800.000 mi -' '300.000 mi -' 'Unavailable -')
[ "${bare_distance[*]}" = "${bare_distance_expected[*]}" ] \
  || fail "fixture 40 T5 changed a distance figure with no ownership events: ${bare_distance[*]}"
grep -q 'data-economy-break=' <<<"$view" \
  && fail "fixture 40 a vehicle with no ownership events gained a break"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = '$BARE_VEHICLE' SELECT E.event-id;")"
grep -q '%event-id' <<<"$report" \
  && fail "fixture 40 the control vehicle carries an event after all: $report"
note "fixture 40 PASS - a vehicle with no acquisition and no disposal derives exactly what it derived before T5"

# ---------------------------------------------------------------------------
# fixture 41 - a vehicle owned from one purchase to now, with no disposal,
# derives across its whole history with no break. The open end of an ownership
# interval is not a gap.
# ---------------------------------------------------------------------------
set_default_vehicle "$OPEN_VEHICLE"
view="$(eyre_view)"
open_best="$(hub_readout 'BEST ECONOMY' <<<"$view")"
[ "$open_best" = '80.000 mpg' ] \
  || fail "fixture 41 a vehicle owned from one purchase to now lost its best economy: $open_best"
open_mean="$(hub_readout 'ECONOMY - LIFETIME' <<<"$view")"
[ "$open_mean" = '45.000 mpg' ] \
  || fail "fixture 41 a vehicle owned from one purchase to now lost intervals from its mean: $open_mean"
view="$(eyre_view_vehicle "$OPEN_VEHICLE")"
mapfile -t open_cells < <(economy_cells <<<"$view")
open_expected=('25.000 mpg' '80.000 mpg' '30.000 mpg' 'Unavailable')
[ "${open_cells[*]}" = "${open_expected[*]}" ] \
  || fail "fixture 41 a vehicle owned to now derives differently: ${open_cells[*]}"
grep -q 'data-economy-break=' <<<"$view" \
  && fail "fixture 41 a vehicle owned from one purchase to now carries a break"
note "fixture 41 PASS - a vehicle owned from one purchase to now derives across its whole history with no break"

# ---------------------------------------------------------------------------
# fixture 42 - consumable economy is an interval derivation too, so the same
# bound applies. Two DEF vehicles carry the same two purchases 500 miles apart.
# Only the ownership events differ.
# ---------------------------------------------------------------------------
own_add_vehicle "$DEF_GAP_VEHICLE" Diesel
own_add_vehicle "$DEF_BARE_VEHICLE" Diesel
for def_vehicle in "$DEF_GAP_VEHICLE" "$DEF_BARE_VEHICLE"; do
  eyre_post edit-vehicle "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"","energySources":["Diesel"],"drivingModes":[],"defEnabled":"yes","defTankSize":"5","defTankUnit":"gal"}' "$def_vehicle" "$def_vehicle")" \
    $'Saved vehicle settings\n201' "fixture 42 DEF enablement on $def_vehicle"
  eyre_post add-consumable "$(printf '{"vehicle":"%s","consumable":"DEF","quantity":"2.000","price":"$4.29","observed":"2026-05-10T14:00","zone":"America/Chicago","mileage":"70000","mileageUnit":"mi"}' "$def_vehicle")" \
    $'Saved consumable purchase - $8.60\n201' "fixture 42 DEF purchase 1 on $def_vehicle"
  eyre_post add-consumable "$(printf '{"vehicle":"%s","consumable":"DEF","quantity":"2.000","price":"$4.29","observed":"2026-07-10T14:00","zone":"America/Chicago","mileage":"70500","mileageUnit":"mi"}' "$def_vehicle")" \
    $'Saved consumable purchase - $8.60\n201' "fixture 42 DEF purchase 2 on $def_vehicle"
done
own_add_ownership_event add-acquisition-event "$DEF_GAP_VEHICLE" '2026-05-01T09:00' '$41,000.00' 69800 ''
own_add_ownership_event add-disposal-event "$DEF_GAP_VEHICLE" '2026-06-01T09:00' '$38,000.00' 70100 'Sold'
own_add_ownership_event add-acquisition-event "$DEF_GAP_VEHICLE" '2026-07-01T09:00' '$37,500.00' 70400 ''
view="$(eyre_view_vehicle "$DEF_BARE_VEHICLE")"
grep -qF "data-def-economy=\"250.000 mi/gal DEF\"" <<<"$view" \
  || fail "fixture 42 the control DEF interval does not compute"
view="$(eyre_view_vehicle "$DEF_GAP_VEHICLE")"
grep -qF "data-def-economy=\"250.000 mi/gal DEF\"" <<<"$view" \
  && fail "fixture 42 the cross-gap DEF interval was reported as a figure"
grep -qF "data-def-economy-unavailable=\"$DEF_GAP_VEHICLE\"" <<<"$view" \
  || fail "fixture 42 the cross-gap DEF interval is not marked unavailable"
grep -qF 'The vehicle was not owned for part of this interval' <<<"$view" \
  || fail "fixture 42 the cross-gap DEF interval gives no human ownership reason"
note "fixture 42 PASS - consumable economy respects ownership gaps the same way fuel economy does"

# ---------------------------------------------------------------------------
# M7 T6 - reminders.
#
# A reminder is DERIVED on every read from four facts: the stored interval, the
# stored due point, the current date, and the derived current odometer. Rover
# holds no timer for one, so there is no wire to orphan and no wakeup to
# duplicate. Fixture 53 asserts that on the source and over a real restart.
#
# Every reminder below sits on a vehicle carrying this run's stamp, so a row a
# previous run left behind can never satisfy this run's assertion.
# ---------------------------------------------------------------------------
REM_VEHICLE="Reminder Vehicle $STAMP"
REM_EMPTY_VEHICLE="Reminder Empty Vehicle $STAMP"
REM_RESET_VEHICLE="Reminder Reset Vehicle $STAMP"

reminder_payload() {
  # vehicle subtype timeInterval timeUnit timeDue distanceInterval distanceDue
  printf '{"vehicle":"%s","subtype":"%s","timeInterval":"%s","timeUnit":"%s","timeDue":"%s","distanceInterval":"%s","distanceDue":"%s","distanceUnit":"mi"}' \
    "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

add_reminder() {
  eyre_post add-reminder "$(reminder_payload "$@")" \
    "$(printf 'Saved reminder - %s\n201' "$2")" "reminder $2 on $1"
}

# A real odometer observation through the product endpoint a browser calls.
# Nothing here pokes a value into the derivation.
add_odometer_reading() {
  # vehicle reading observed display
  eyre_post add-odometer \
    "$(printf '{"vehicle":"%s","reading":"%s","unit":"mi","observed":"%s","zone":"America/Chicago"}' "$1" "$2" "$3")" \
    "$(printf 'Saved odometer - %s mi\n201' "$4")" "odometer $2 on $1"
}

# One reminder card of the served hub, by the service subtype it names. The hub
# renders the app default vehicle, so each read below sets the default first.
reminder_card() {
  python3 -c '
import re, sys
document = sys.stdin.read()
pattern = r"<article class=\"reminder\"[^>]*data-reminder=\"%s\".*?</article>" % re.escape(sys.argv[1])
found = re.search(pattern, document, re.S)
sys.stdout.write(found.group(0) if found else "")
' "$1" <<<"$view"
}

reminder_attribute() {
  # card attribute
  python3 -c '
import re, sys
found = re.search(r"%s=\"(.*?)\"" % re.escape(sys.argv[1]), sys.stdin.read(), re.S)
sys.stdout.write(found.group(1) if found else "")
' "$2" <<<"$1"
}

# The three states of one reminder, as one line: state, headline, detail. A
# reminder that is not on the page at all reads as the empty string, which no
# assertion below accepts.
reminder_state() {
  local card
  card="$(reminder_card "$1")"
  [ -n "$card" ] || { printf 'absent\n'; return 0; }
  printf '%s\n' "$(reminder_attribute "$card" data-reminder-state)"
}
reminder_due() {
  reminder_attribute "$(reminder_card "$1")" data-reminder-due
}
reminder_detail() {
  reminder_attribute "$(reminder_card "$1")" data-reminder-detail
}

rem_rows() {
  # relation alias column vehicle subtype
  rover_report "FROM vehicles V JOIN service-reminders R ON V.vehicle-id = R.vehicle-id JOIN service-subtype-definitions S ON R.service-subtype-id = S.service-subtype-id JOIN $1 $2 ON R.reminder-id = $2.reminder-id WHERE V.label = '$4' AND S.label = '$5' SELECT $2.$3;"
}

# ---------------------------------------------------------------------------
# fixture 44 - the three T6 relations exist. The reminder parent keys to the
# vehicle and to the service subtype; each optional interval is its own child
# keyed to the reminder. An interval that is not set is an ABSENT ROW, so no
# column on the parent can ever hold a zero interval.
# ---------------------------------------------------------------------------
ensure_def_schema
report="$(rover_report 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
for relation in service-reminders service-reminder-time service-reminder-distance; do
  grep -q "%name %tas %$relation" <<<"$report" \
    || fail "fixture 44 the pour is missing $relation"
done
report="$(rover_report 'FROM sys.foreign-keys WHERE child-table = %service-reminders SELECT parent-table, parent-column, child-column, on-delete, on-update;')"
grep -q '%parent-table %tas %vehicles' <<<"$report" \
  || fail "fixture 44 the reminder does not key to a vehicle: $report"
grep -q '%parent-table %tas %service-subtype-definitions' <<<"$report" \
  || fail "fixture 44 the reminder does not key to a service subtype: $report"
grep -q '%on-delete %tas %restrict' <<<"$report" \
  || fail "fixture 44 the reminder keys are not RESTRICT: $report"
for child in service-reminder-time service-reminder-distance; do
  report="$(rover_report "FROM sys.foreign-keys WHERE child-table = %$child SELECT parent-table, on-delete, on-update;")"
  grep -q '%parent-table %tas %service-reminders' <<<"$report" \
    || fail "fixture 44 $child does not key to service-reminders: $report"
  grep -q '%on-delete %tas %restrict' <<<"$report" \
    || fail "fixture 44 $child is not RESTRICT: $report"
done
report="$(rover_report 'FROM service-reminders R SELECT R.reminder-id, R.vehicle-id, R.service-subtype-id, R.archived, R.recorded-at;')"
grep -q '%due' <<<"$report" \
  && fail "fixture 44 the reminder parent carries a due column"
note "fixture 44 PASS - the reminder parent keys to a vehicle and a service subtype, and each interval is its own child relation"

# ---------------------------------------------------------------------------
# fixture 45 - a reminder saves with a time interval, a distance interval, or
# both, keyed to a service subtype, and reads back through Eyre.
# ---------------------------------------------------------------------------
own_add_vehicle "$REM_VEHICLE" Gasoline
add_odometer_reading "$REM_VEHICLE" 10000 '2026-08-01T08:00' '10,000'
add_reminder "$REM_VEHICLE" 'Engine Oil'    ''   ''      ''           3000  13000
add_reminder "$REM_VEHICLE" 'Brake Fluid'   3    month   '2026-08-01' ''    ''
add_reminder "$REM_VEHICLE" 'Inspection'    12   month   '2027-06-01' ''    ''
add_reminder "$REM_VEHICLE" 'Air Filter'    12   month   '2027-01-01' 1000  12000
add_reminder "$REM_VEHICLE" 'Spark Plugs'   1    month   '2026-07-01' 50000 90000
set_default_vehicle "$REM_VEHICLE"
view="$(eyre_view)"
for label in 'Engine Oil' 'Brake Fluid' 'Inspection' 'Air Filter' 'Spark Plugs'; do
  [ -n "$(reminder_card "$label")" ] \
    || fail "fixture 45 the served hub has no reminder card for $label"
done
grep -q '%interval-count' <<<"$(rem_rows service-reminder-time T interval-count "$REM_VEHICLE" 'Brake Fluid')" \
  || fail "fixture 45 the time-only reminder wrote no time row"
grep -q '%due-digits' <<<"$(rem_rows service-reminder-distance D due-digits "$REM_VEHICLE" 'Engine Oil')" \
  || fail "fixture 45 the distance-only reminder wrote no distance row"
report="$(rem_rows service-reminder-time T interval-unit "$REM_VEHICLE" 'Air Filter')"
grep -q '%interval-unit %tas %month' <<<"$report" \
  || fail "fixture 45 the both-interval reminder lost its time unit: $report"
grep -q '%due-digits' <<<"$(rem_rows service-reminder-distance D due-digits "$REM_VEHICLE" 'Air Filter')" \
  || fail "fixture 45 the both-interval reminder wrote no distance row"
# A raw machine ID never reaches the served page.
grep -q 'data-reminder-id' <<<"$view" \
  && fail "fixture 45 the served reminder card carries a raw reminder id"
note "fixture 45 PASS - a reminder saves with a time interval, a distance interval, or both, keyed to a service subtype, and reads back through Eyre"

# ---------------------------------------------------------------------------
# fixture 46 - a time-only reminder writes NO distance row and no zero. The
# absence of the row is what "no distance interval" means.
# ---------------------------------------------------------------------------
report="$(rem_rows service-reminder-distance D due-digits "$REM_VEHICLE" 'Brake Fluid')"
grep -q '%due-digits' <<<"$report" \
  && fail "fixture 46 a time-only reminder wrote a distance row: $report"
report="$(rem_rows service-reminder-distance D interval-digits "$REM_VEHICLE" 'Inspection')"
grep -q '%interval-digits' <<<"$report" \
  && fail "fixture 46 a time-only reminder wrote a zero distance interval: $report"
report="$(rem_rows service-reminder-time T interval-count "$REM_VEHICLE" 'Engine Oil')"
grep -q '%interval-count' <<<"$report" \
  && fail "fixture 46 a distance-only reminder wrote a time row: $report"
note "fixture 46 PASS - a time-only reminder writes no distance row and no zero, and a distance-only reminder writes no time row"

# ---------------------------------------------------------------------------
# fixture 47 - the fixture that decides the distance half. The reminder is not
# due below its threshold, and it becomes due after a REAL odometer observation
# crosses it. The crossing comes from the product endpoint, never from a poked
# value.
# ---------------------------------------------------------------------------
[ "$(reminder_state 'Engine Oil')" = not-due ] \
  || fail "fixture 47 the distance reminder is $(reminder_state 'Engine Oil') below its threshold, want not-due"
[ "$(reminder_due 'Engine Oil')" = 'Due in 3,000 mi' ] \
  || fail "fixture 47 the distance remaining is $(reminder_due 'Engine Oil'), want Due in 3,000 mi"
add_odometer_reading "$REM_VEHICLE" 13050 '2026-08-10T08:00' '13,050'
view="$(eyre_view)"
[ "$(reminder_state 'Engine Oil')" = due ] \
  || fail "fixture 47 the distance reminder is $(reminder_state 'Engine Oil') after a reading crossed it, want due"
grep -qF '13,050 mi' <<<"$(reminder_detail 'Engine Oil')" \
  || fail "fixture 47 the due reminder does not name the reading that crossed it: $(reminder_detail 'Engine Oil')"
note "fixture 47 PASS - a distance reminder is not due below its threshold and is due after a real odometer reading crosses it"

# ---------------------------------------------------------------------------
# fixture 48 - a time reminder is due on or after its date, and one whose date
# has not arrived is not due. The clock is the real one; no stored due date is
# edited mid-assertion.
# ---------------------------------------------------------------------------
[ "$(reminder_state 'Brake Fluid')" = due ] \
  || fail "fixture 48 the past-dated time reminder is $(reminder_state 'Brake Fluid'), want due"
grep -qF '2026-08-01' <<<"$(reminder_detail 'Brake Fluid')" \
  || fail "fixture 48 the due time reminder does not name its date: $(reminder_detail 'Brake Fluid')"
[ "$(reminder_state 'Inspection')" = not-due ] \
  || fail "fixture 48 the future-dated time reminder is $(reminder_state 'Inspection'), want not-due"
[ "$(reminder_due 'Inspection')" = 'Due 2027-06-01' ] \
  || fail "fixture 48 the future time reminder reads $(reminder_due 'Inspection'), want Due 2027-06-01"
note "fixture 48 PASS - a time reminder is due on and after its date, and is not due before it"

# ---------------------------------------------------------------------------
# fixture 49 - a reminder carrying both intervals is due when EITHER fires.
# Air Filter fires by distance while its date is a year away; Spark Plugs fires
# by time while its reading is 77,000 miles away.
# ---------------------------------------------------------------------------
[ "$(reminder_state 'Air Filter')" = due ] \
  || fail "fixture 49 the both-interval reminder did not fire on distance alone: $(reminder_state 'Air Filter')"
grep -qF '12,000 mi' <<<"$(reminder_detail 'Air Filter')" \
  || fail "fixture 49 the distance-fired reminder does not name its distance due point: $(reminder_detail 'Air Filter')"
[ "$(reminder_state 'Spark Plugs')" = due ] \
  || fail "fixture 49 the both-interval reminder did not fire on time alone: $(reminder_state 'Spark Plugs')"
grep -qF '2026-07-01' <<<"$(reminder_detail 'Spark Plugs')" \
  || fail "fixture 49 the time-fired reminder does not name its date: $(reminder_detail 'Spark Plugs')"
note "fixture 49 PASS - a reminder with both intervals is due when either one fires"

# ---------------------------------------------------------------------------
# fixture 50 - ruling 12 applied to a new figure. The gap vehicle was bought,
# sold at 40,400 and bought back at 40,800, so 400 of the miles on its odometer
# belong to whoever held it in between.
#
#   GAP REMINDER   due 41,300 mi, every 1,200 mi. The countdown therefore runs
#                  from 40,100, and the last reading at or below that point is
#                  40,000 on 2026-05-05 - before the sale. The current reading
#                  is 41,400 on 2026-07-15, after the repurchase.
#                  Counting the gap's miles as progress makes it DUE, because
#                  41,400 is past 41,300. The owner drove only 1,000 of those
#                  1,300 miles, so DUE is the wrong answer.
#   INSIDE         due 41,500 mi, every 500 mi. The countdown runs from 41,000,
#                  and the last reading at or below it is 40,800 on 2026-07-01,
#                  the repurchase. That window sits inside ONE ownership
#                  interval, so the same vehicle still answers.
# ---------------------------------------------------------------------------
add_reminder "$GAP_VEHICLE" 'Engine Oil'     '' '' '' 1200 41300
add_reminder "$GAP_VEHICLE" 'Tire Rotation'  '' '' '' 500  41500
set_default_vehicle "$GAP_VEHICLE"
view="$(eyre_view)"
gap_reminder="$(reminder_state 'Engine Oil')"
[ "$gap_reminder" != due ] \
  || fail "fixture 50 the reminder counted the gap's miles as progress and reported due"
[ "$gap_reminder" != not-due ] \
  || fail "fixture 50 the cross-gap reminder reported a confident not-due"
[ "$gap_reminder" = unavailable ] \
  || fail "fixture 50 the cross-gap reminder is $gap_reminder, want unavailable"
grep -qF 'The vehicle was not owned for part of this interval' <<<"$(reminder_detail 'Engine Oil')" \
  || fail "fixture 50 the cross-gap reminder gives no human ownership reason: $(reminder_detail 'Engine Oil')"
[ "$(reminder_state 'Tire Rotation')" = not-due ] \
  || fail "fixture 50 the within-ownership reminder is $(reminder_state 'Tire Rotation'), want not-due"
[ "$(reminder_due 'Tire Rotation')" = 'Due in 100 mi' ] \
  || fail "fixture 50 the within-ownership reminder reads $(reminder_due 'Tire Rotation'), want Due in 100 mi"
note "fixture 50 PASS - a distance reminder whose countdown crosses an ownership gap does not count the gap's miles as progress, and a reminder inside one ownership interval on the same vehicle still answers"

# ---------------------------------------------------------------------------
# fixture 51 - a vehicle with no odometer reading cannot answer a distance
# question. That is unavailable with a human reason. Two states are not enough.
# ---------------------------------------------------------------------------
own_add_vehicle "$REM_EMPTY_VEHICLE" Gasoline
add_reminder "$REM_EMPTY_VEHICLE" 'Engine Oil' '' '' '' 3000 5000
set_default_vehicle "$REM_EMPTY_VEHICLE"
view="$(eyre_view)"
empty_state="$(reminder_state 'Engine Oil')"
[ "$empty_state" != due ] \
  || fail "fixture 51 a vehicle with no odometer reading reported due"
[ "$empty_state" != not-due ] \
  || fail "fixture 51 a vehicle with no odometer reading reported not-due"
[ "$empty_state" = unavailable ] \
  || fail "fixture 51 a vehicle with no odometer reading is $empty_state, want unavailable"
[ "$(reminder_due 'Engine Oil')" = Unavailable ] \
  || fail "fixture 51 the headline is $(reminder_due 'Engine Oil'), want Unavailable"
grep -qF 'no odometer reading' <<<"$(reminder_detail 'Engine Oil')" \
  || fail "fixture 51 the unavailable reminder gives no human reason: $(reminder_detail 'Engine Oil')"
grep -qE '0 mi|0\.000' <<<"$(reminder_due 'Engine Oil')" \
  && fail "fixture 51 the unavailable reminder rendered a zero distance"
note "fixture 51 PASS - a vehicle with no odometer readings renders the distance reminder unavailable with a human reason, not due and not not-due"

# ---------------------------------------------------------------------------
# fixture 52 - recording the service the reminder names resets it. The next due
# point becomes that service plus one interval, and never earlier than the
# point the owner entered.
# ---------------------------------------------------------------------------
own_add_vehicle "$REM_RESET_VEHICLE" Gasoline
add_odometer_reading "$REM_RESET_VEHICLE" 20000 '2026-08-01T08:00' '20,000'
add_reminder "$REM_RESET_VEHICLE" 'Oil Filter'      '' ''    ''           3000 20100
add_reminder "$REM_RESET_VEHICLE" 'Coolant System'  3  month '2026-08-10' ''   ''
set_default_vehicle "$REM_RESET_VEHICLE"
view="$(eyre_view)"
[ "$(reminder_due 'Oil Filter')" = 'Due in 100 mi' ] \
  || fail "fixture 52 the distance reminder reads $(reminder_due 'Oil Filter') before the service, want Due in 100 mi"
[ "$(reminder_state 'Coolant System')" = due ] \
  || fail "fixture 52 the time reminder is $(reminder_state 'Coolant System') before the service, want due"
RESET_NOTE="Oil filter and coolant $STAMP"
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"2026-08-05T09:00","zone":"America/Chicago","total":"$92.00","currency":"usd","mileage":"20150","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"%s","subtypes":["Oil Filter","Coolant System"]}' \
    "$REM_RESET_VEHICLE" "$RESET_NOTE")" \
  $'Saved service event - $92.00\n201' 'fixture 52 the recorded service'
view="$(eyre_view)"
[ "$(reminder_state 'Oil Filter')" = not-due ] \
  || fail "fixture 52 the distance reminder is $(reminder_state 'Oil Filter') after the service, want not-due"
[ "$(reminder_due 'Oil Filter')" = 'Due in 3,000 mi' ] \
  || fail "fixture 52 the service did not reset the distance reminder: $(reminder_due 'Oil Filter')"
[ "$(reminder_state 'Coolant System')" = not-due ] \
  || fail "fixture 52 the service did not reset the time reminder: $(reminder_state 'Coolant System')"
[ "$(reminder_due 'Coolant System')" = 'Due 2026-11-05' ] \
  || fail "fixture 52 the reset time reminder reads $(reminder_due 'Coolant System'), want Due 2026-11-05"
# The reset is DERIVED. Nothing rewrote the stored due point.
report="$(rem_rows service-reminder-distance D due-digits "$REM_RESET_VEHICLE" 'Oil Filter')"
grep -q '%due-digits 25717 20100' <<<"$report" \
  || fail "fixture 52 the stored distance due point was rewritten: $report"
note "fixture 52 PASS - recording the service the reminder names resets it, and the stored due point is never rewritten"

# ---------------------------------------------------------------------------
# M7 T7 - vehicle identity and specification
#
# EVERY VIN AND EVERY PLATE BELOW IS SYNTHETIC. The VINs contain the letters
# I and O, which the real VIN alphabet excludes, so none of them can ever be a
# real vehicle identification number. The plates carry the word FAKE. The
# owner's aCar export is not read by this battery and none of its values
# appears here.
# ---------------------------------------------------------------------------
SPEC_VEHICLE="Spec Vehicle $STAMP"
SPEC_PARTIAL_VEHICLE="Spec Partial Vehicle $STAMP"
SPEC_FREE_VEHICLE="Spec Free Vehicle $STAMP"
SPEC_LATE_VIN_VEHICLE="Spec Late VIN Vehicle $STAMP"
SPEC_PLATE_ONLY_VEHICLE="Spec Plate Only Vehicle $STAMP"
SPEC_VIN='ROVERFAKEVIN00001'
SPEC_VIN_TYPO='ROVERFAKEVIN00009'
SPEC_VIN_LATE='ROVERFAKEVIN00002'
SPEC_PLATE='ROVER-FAKE-01'
SPEC_PLATE_ONLY='ROVER-FAKE-02'
SPEC_NOTE="Bought used with a full service history $STAMP"

# Every specification field the vehicle settings form carries. The names match
# the form controls, so a browser body and a JSON body take the same path.
spec_payload() {
  # vehicle vin plate year make model subModel bodyType color engine
  # transmission driveType bedType notes
  printf '{"vehicle":"%s","label":"%s","specVin":"%s","specPlate":"%s","specYear":"%s","specMake":"%s","specModel":"%s","specSubModel":"%s","specBodyType":"%s","specColor":"%s","specEngine":"%s","specTransmission":"%s","specDriveType":"%s","specBedType":"%s","specNotes":"%s"}' \
    "$1" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}" "${14}"
}

edit_vehicle() {
  # payload label
  eyre_post edit-vehicle "$1" $'Saved vehicle settings\n201' "$2"
}

# The rows one specification relation holds for one vehicle.
spec_rows() {
  # relation alias column vehicle
  rover_report "FROM vehicles V JOIN $1 $2 ON V.vehicle-id = $2.vehicle-id WHERE V.label = '$4' SELECT $2.$3;"
}

# The settings panel of one vehicle, as the browser receives it.
vehicle_card() {
  python3 -c '
import re, sys
document = sys.stdin.read()
pattern = r"<article class=\"vehicle-card\" data-vehicle-settings-panel data-vehicle=\"%s\".*?</article>" % re.escape(sys.argv[1])
found = re.search(pattern, document, re.S)
sys.stdout.write(found.group(0) if found else "")
' "$1" <<<"$view"
}

# One rendered specification line of a vehicle card, by the part it carries.
spec_line() {
  # card part
  python3 -c '
import re, sys
document = sys.stdin.read()
pattern = r"<p [^>]*data-vehicle-spec=\"%s\"[^>]*>(.*?)</p>" % re.escape(sys.argv[1])
found = re.search(pattern, document, re.S)
sys.stdout.write(re.sub(r"<[^>]+>", "", found.group(1)) if found else "")
' "$2" <<<"$1"
}

# The thirteen relations of the specification family, with the one column each
# of them adds. The list is the battery's own copy: if the desk renames a
# relation or a column, every assertion below fails rather than passing on a
# relation that is no longer there.
SPEC_RELATIONS='vehicle-vin:vin vehicle-license-plate:plate vehicle-model-year:model-year vehicle-make:make vehicle-model:model vehicle-sub-model:sub-model vehicle-body-type:body-type vehicle-color:color vehicle-engine:engine vehicle-transmission:transmission vehicle-drive-type:drive-type vehicle-bed-type:bed-type vehicle-notes:note'

# ---------------------------------------------------------------------------
# fixture 55 - the specification family is poured, one relation per field.
#
# Thirteen relations, because every one of these fields is INDIVIDUALLY
# optional and a row must use every column it defines. A sedan has no bed at
# all, so a `vehicle-drivetrain` row holding engine, transmission, drive type
# and bed type would bunt one column for every vehicle that is not a pickup -
# the conditionally-meaningless-column defect this project has now refused a
# dozen times.
#
# The identifiers are two relations of their own. VIN and plate share no
# relation with a descriptive field and none with each other, so a grant can
# reach either one alone. Fixture 61 proves that on the columns.
# ---------------------------------------------------------------------------
ensure_def_schema
report="$(rover_report 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
for pair in $SPEC_RELATIONS; do
  grep -q "%name %tas %${pair%%:*}" <<<"$report" \
    || fail "fixture 55 the pour is missing ${pair%%:*}"
done
# No column reached a populated relation. `vehicles` carries the four columns
# it shipped with and no fourteenth.
report="$(rover_report "FROM sys.columns WHERE namespace = %dbo AND name = %vehicles SELECT col-name;")"
vehicle_columns="$(count_rows "$report" '%col-name')"
[ "$vehicle_columns" = 4 ] \
  || fail "fixture 55 vehicles now has $vehicle_columns columns, want the 4 it shipped with: $report"
# Nothing keys to a VIN or a plate. `vehicle-id` is still the only identity.
report="$(rover_report 'FROM sys.foreign-keys SELECT parent-table, parent-column, child-table, child-column;')"
grep -qE '%parent-column %tas %(vin|plate)' <<<"$report" \
  && fail "fixture 55 a foreign key targets a VIN or a plate: $report"
for pair in $SPEC_RELATIONS; do
  grep -q "%child-table %tas %${pair%%:*}" <<<"$report" \
    || fail "fixture 55 ${pair%%:*} has no foreign key to vehicles"
done
note "fixture 55 PASS - thirteen specification relations exist, one per field, vehicles gained no column, and no foreign key targets a VIN or a plate"

# ---------------------------------------------------------------------------
# fixture 56 - every field saves and reads back through Eyre, and the vehicle
# screen reads like a description of a vehicle rather than a table of terms
# ---------------------------------------------------------------------------
own_add_vehicle "$SPEC_VEHICLE" Gasoline
edit_vehicle "$(spec_payload "$SPEC_VEHICLE" "$SPEC_VIN" "$SPEC_PLATE" 2019 Ford F-150 Lariat 'crew cab pickup' 'Oxford White' '3.5L V6 EcoBoost' '10-speed automatic' 'four-wheel drive' '5.5 ft bed' "$SPEC_NOTE")" \
  'fixture 56 the full specification'
view="$(eyre_view)"
card="$(vehicle_card "$SPEC_VEHICLE")"
[ -n "$card" ] || fail "fixture 56 no vehicle card for $SPEC_VEHICLE"
[ "$(spec_line "$card" headline)" = '2019 Ford F-150 Lariat' ] \
  || fail "fixture 56 the headline reads '$(spec_line "$card" headline)'"
[ "$(spec_line "$card" detail)" = 'Oxford White crew cab pickup, 3.5L V6 EcoBoost, 10-speed automatic, four-wheel drive, 5.5 ft bed.' ] \
  || fail "fixture 56 the description reads '$(spec_line "$card" detail)'"
[ "$(spec_line "$card" vin)" = "VIN $SPEC_VIN" ] \
  || fail "fixture 56 the VIN line reads '$(spec_line "$card" vin)'"
[ "$(spec_line "$card" plate)" = "PLATE $SPEC_PLATE" ] \
  || fail "fixture 56 the plate line reads '$(spec_line "$card" plate)'"
[ "$(spec_line "$card" note)" = "$SPEC_NOTE" ] \
  || fail "fixture 56 the note line reads '$(spec_line "$card" note)'"
# Every one of the thirteen reached its own relation.
for pair in $SPEC_RELATIONS; do
  relation="${pair%%:*}"
  column="${pair##*:}"
  report="$(spec_rows "$relation" S "$column" "$SPEC_VEHICLE")"
  grep -q "%$column" <<<"$report" \
    || fail "fixture 56 $relation holds no row for the fully specified vehicle: $report"
done
report="$(spec_rows vehicle-model-year S model-year "$SPEC_VEHICLE")"
grep -q '%model-year 25717 2019' <<<"$report" \
  || fail "fixture 56 the year is not stored as a number: $report"
note "fixture 56 PASS - twelve specification fields and the vehicle note save, reach thirteen relations, and read back as a description"

# ---------------------------------------------------------------------------
# fixture 57 - each field is independently absent. A vehicle with a make and a
# model writes two rows and eleven absences: no empty string, no zero, no bunt.
# The absence is proved on the relations, not read off the render.
# ---------------------------------------------------------------------------
own_add_vehicle "$SPEC_PARTIAL_VEHICLE" Gasoline
edit_vehicle "$(printf '{"vehicle":"%s","label":"%s","specMake":"Toyota","specModel":"Corolla"}' \
  "$SPEC_PARTIAL_VEHICLE" "$SPEC_PARTIAL_VEHICLE")" 'fixture 57 a partial specification'
for pair in $SPEC_RELATIONS; do
  relation="${pair%%:*}"
  column="${pair##*:}"
  report="$(spec_rows "$relation" S "$column" "$SPEC_PARTIAL_VEHICLE")"
  present="$(count_rows "$report" "%$column")"
  case "$relation" in
    vehicle-make|vehicle-model)
      [ "$present" = 1 ] \
        || fail "fixture 57 $relation holds $present rows for the partial vehicle, want 1: $report" ;;
    *)
      [ "$present" = 0 ] \
        || fail "fixture 57 $relation holds a row for a field the owner left blank: $report" ;;
  esac
done
view="$(eyre_view)"
card="$(vehicle_card "$SPEC_PARTIAL_VEHICLE")"
[ "$(spec_line "$card" headline)" = 'Toyota Corolla' ] \
  || fail "fixture 57 the partial headline reads '$(spec_line "$card" headline)'"
[ -z "$(spec_line "$card" detail)" ] \
  || fail "fixture 57 a description line appeared with nothing to describe: '$(spec_line "$card" detail)'"
[ -z "$(spec_line "$card" vin)" ] \
  || fail "fixture 57 a VIN line appeared for a vehicle with no VIN"
# A blank sent again clears the row rather than writing an empty string.
edit_vehicle "$(printf '{"vehicle":"%s","label":"%s","specMake":"","specModel":"Corolla"}' \
  "$SPEC_PARTIAL_VEHICLE" "$SPEC_PARTIAL_VEHICLE")" 'fixture 57 a cleared make'
report="$(spec_rows vehicle-make S make "$SPEC_PARTIAL_VEHICLE")"
[ "$(count_rows "$report" '%make')" = 0 ] \
  || fail "fixture 57 a cleared make left a row behind: $report"
report="$(spec_rows vehicle-model S model "$SPEC_PARTIAL_VEHICLE")"
[ "$(count_rows "$report" '%model')" = 1 ] \
  || fail "fixture 57 clearing the make disturbed the model: $report"
note "fixture 57 PASS - each specification field is independently absent, and a cleared field removes its row rather than storing an empty string"

# ---------------------------------------------------------------------------
# fixture 58 - THE COMPATIBILITY GUARD. Every installed database holds vehicles
# with no specification data at all, so a vehicle in that state must render
# exactly as it did before T7.
#
# `bin/spec-free-vehicle-card.html` is the settings panel of a vehicle created
# by `add-vehicle` and never edited, captured from the PRE-T7 desk on this
# pier. The served panel is compared against it character for character. Two
# normalizations are applied to both sides and to neither side alone:
#
#   * the vehicle label, which carries this run's stamp
#   * the two membership check grids, whose contents follow the energy-source
#     and driving-mode catalogs of the database rather than anything T7 does
#   * the options in the default-subtype selector, whose contents follow the
#     imported subtype catalog and whose order follows random IDs. Dedicated
#     selector fixtures cover that catalog; this compatibility guard covers
#     the specification-free vehicle card around it.
#
# The specification fieldset is removed from the served panel before the
# comparison, exactly as the tank-size input arrived: an optional field gets a
# blank control in the settings form and says nothing at all on the read
# surface until the owner fills it in. Everything else must match.
# ---------------------------------------------------------------------------
own_add_vehicle "$SPEC_FREE_VEHICLE" Gasoline
view="$(eyre_view)"
card="$(vehicle_card "$SPEC_FREE_VEHICLE")"
[ -n "$card" ] || fail "fixture 58 no vehicle card for $SPEC_FREE_VEHICLE"
grep -q 'data-vehicle-spec' <<<"$card" \
  && fail "fixture 58 a vehicle with no specification data renders a specification line"
served_card="$(mktemp ${ROVER_TEST_TMP}/rover-spec-card.XXXXXX.html)"
printf '%s' "$card" > "$served_card"
compat="$(python3 - "$REPO/bin/spec-free-vehicle-card.html" "$SPEC_FREE_VEHICLE" "$served_card" <<'PY'
import pathlib, re, sys
baseline = pathlib.Path(sys.argv[1]).read_text()
served = pathlib.Path(sys.argv[3]).read_text()
label = sys.argv[2]

def normalize(document, label):
    document = document.replace(label, "VEHICLE")
    document = re.sub(
        r"<fieldset class=\"vehicle-settings-group\" data-settings-group=\"specification\">.*?</fieldset>",
        "", document, flags=re.S)
    document = re.sub(r"<div class=\"check-grid\">.*?</div>", "<div class=\"check-grid\">CHECKS</div>",
                      document, flags=re.S)
    document = re.sub(
        r"(<select name=\"defaultSubtype\">).*?(</select>)",
        r"\1OPTIONS\2", document, flags=re.S)
    return document

baseline = normalize(baseline, "Spec Baseline Vehicle")
served = normalize(served, label)
if baseline == served:
    print("IDENTICAL")
else:
    for index, (left, right) in enumerate(zip(baseline, served)):
        if left != right:
            print("DIFFERS at %d" % index)
            print("pre-T7 : ..." + baseline[max(0, index - 80):index + 120])
            print("served : ..." + served[max(0, index - 80):index + 120])
            break
    else:
        print("DIFFERS in length: pre-T7 %d, served %d" % (len(baseline), len(served)))
        print("pre-T7 tail: " + baseline[-200:])
        print("served tail: " + served[-200:])
PY
)"
rm -f "$served_card"
grep -q '^IDENTICAL$' <<<"$compat" \
  || fail "fixture 58 a vehicle with no specification data no longer renders as it did before T7: $compat"
note "fixture 58 PASS - a vehicle with no specification data renders exactly as it did before T7, character for character"

# ---------------------------------------------------------------------------
# fixture 59 - a vehicle created without a VIN gains one later, and nothing is
# re-keyed. VIN is evidence, not a key: the vehicle existed before the VIN was
# known, so the vehicle-id it was created with is the one it keeps.
# ---------------------------------------------------------------------------
own_add_vehicle "$SPEC_LATE_VIN_VEHICLE" Gasoline
add_odometer_reading "$SPEC_LATE_VIN_VEHICLE" 31000 '2026-07-02T08:00' '31,000'
LATE_NOTE="Timing belt $STAMP"
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"2026-07-03T09:00","zone":"America/Chicago","total":"$740.00","currency":"usd","mileage":"31100","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"%s","subtypes":[]}' \
    "$SPEC_LATE_VIN_VEHICLE" "$LATE_NOTE")" \
  $'Saved service event - $740.00\n201' 'fixture 59 the service before the VIN'
report="$(rover_report "FROM vehicles V WHERE V.label = '$SPEC_LATE_VIN_VEHICLE' SELECT V.vehicle-id;")"
before_id="$(grep -oE '%vehicle-id [0-9]+ [0-9.]+' <<<"$report" | head -1)"
[ -n "$before_id" ] || fail "fixture 59 the vehicle has no id before the VIN: $report"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = '$SPEC_LATE_VIN_VEHICLE' SELECT E.event-id;")"
before_event="$(count_rows "$report" '%event-id')"
[ "$before_event" = 1 ] || fail "fixture 59 the vehicle has $before_event events before the VIN"
edit_vehicle "$(printf '{"vehicle":"%s","label":"%s","specVin":"%s"}' \
  "$SPEC_LATE_VIN_VEHICLE" "$SPEC_LATE_VIN_VEHICLE" "$SPEC_VIN_LATE")" \
  'fixture 59 the VIN recorded later'
report="$(rover_report "FROM vehicles V WHERE V.label = '$SPEC_LATE_VIN_VEHICLE' SELECT V.vehicle-id;")"
after_id="$(grep -oE '%vehicle-id [0-9]+ [0-9.]+' <<<"$report" | head -1)"
[ "$after_id" = "$before_id" ] \
  || fail "fixture 59 recording a VIN re-keyed the vehicle: $before_id became $after_id"
[ "$(count_rows "$report" '%vehicle-id')" = 1 ] \
  || fail "fixture 59 recording a VIN made a second vehicle: $report"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-notes Z ON E.event-id = Z.event-id WHERE V.label = '$SPEC_LATE_VIN_VEHICLE' SELECT Z.note;")"
grep -qF "$LATE_NOTE" <<<"$report" \
  || fail "fixture 59 the service event lost its vehicle when the VIN arrived: $report"
report="$(rover_report "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = '$SPEC_LATE_VIN_VEHICLE' SELECT O.odometer-id;")"
[ "$(count_rows "$report" '%odometer-id')" = 2 ] \
  || fail "fixture 59 the odometer list changed when the VIN arrived: $report"
view="$(eyre_view)"
card="$(vehicle_card "$SPEC_LATE_VIN_VEHICLE")"
grep -qF "$LATE_NOTE" <<<"$card" \
  || fail "fixture 59 the history no longer reads after the VIN arrived"
[ "$(spec_line "$card" vin)" = "VIN $SPEC_VIN_LATE" ] \
  || fail "fixture 59 the recorded VIN does not read back: '$(spec_line "$card" vin)'"
note "fixture 59 PASS - a vehicle created without a VIN gains one later, keeps its vehicle-id, and its history still reads"

# ---------------------------------------------------------------------------
# fixture 60 - a mistyped VIN is corrected. The correction is an ordinary
# update to one evidence row: it makes no new vehicle, touches no history, and
# every existing link still targets the same vehicle.
# ---------------------------------------------------------------------------
edit_vehicle "$(printf '{"vehicle":"%s","label":"%s","specVin":"%s"}' \
  "$SPEC_VEHICLE" "$SPEC_VEHICLE" "$SPEC_VIN_TYPO")" 'fixture 60 the mistyped VIN'
report="$(spec_rows vehicle-vin S vin "$SPEC_VEHICLE")"
grep -qF "$SPEC_VIN_TYPO" <<<"$report" \
  || fail "fixture 60 the mistyped VIN was not stored: $report"
report="$(rover_report "FROM vehicles V WHERE V.label = '$SPEC_VEHICLE' SELECT V.vehicle-id;")"
typo_id="$(grep -oE '%vehicle-id [0-9]+ [0-9.]+' <<<"$report" | head -1)"
edit_vehicle "$(printf '{"vehicle":"%s","label":"%s","specVin":"%s"}' \
  "$SPEC_VEHICLE" "$SPEC_VEHICLE" "$SPEC_VIN")" 'fixture 60 the corrected VIN'
report="$(spec_rows vehicle-vin S vin "$SPEC_VEHICLE")"
[ "$(count_rows "$report" '%vin')" = 1 ] \
  || fail "fixture 60 the correction left two VIN rows behind: $report"
grep -qF "$SPEC_VIN" <<<"$report" \
  || fail "fixture 60 the corrected VIN is not stored: $report"
grep -qF "$SPEC_VIN_TYPO" <<<"$report" \
  && fail "fixture 60 the mistyped VIN survived the correction: $report"
report="$(rover_report "FROM vehicles V WHERE V.label = '$SPEC_VEHICLE' SELECT V.vehicle-id;")"
fixed_id="$(grep -oE '%vehicle-id [0-9]+ [0-9.]+' <<<"$report" | head -1)"
[ "$fixed_id" = "$typo_id" ] \
  || fail "fixture 60 correcting the VIN re-keyed the vehicle: $typo_id became $fixed_id"
[ "$(count_rows "$report" '%vehicle-id')" = 1 ] \
  || fail "fixture 60 correcting the VIN made a second vehicle: $report"
# Correcting the VIN disturbed no other specification field.
report="$(spec_rows vehicle-make S make "$SPEC_VEHICLE")"
grep -q "%make 116 'Ford'" <<<"$report" \
  || fail "fixture 60 correcting the VIN disturbed the make: $report"
report="$(spec_rows vehicle-license-plate S plate "$SPEC_VEHICLE")"
grep -qF "$SPEC_PLATE" <<<"$report" \
  || fail "fixture 60 correcting the VIN disturbed the plate: $report"
note "fixture 60 PASS - a mistyped VIN is corrected in place, and every link still targets the same vehicle"

# ---------------------------------------------------------------------------
# fixture 61 - VIN AND PLATE ARE INDEPENDENTLY GATEABLE.
#
# A grant can only be as fine-grained as the rows it gates, so the shape has to
# allow the gating before the gating exists. This fixture proves the shape on
# the columns rather than on the intention:
#
#   * `vehicle-vin` holds the VIN, the vehicle it belongs to, and when it was
#     recorded. Nothing else. `vehicle-license-plate` likewise.
#   * No descriptive column lives in either relation, so a grant that reaches
#     the make cannot reach the VIN by accident.
#   * The two relations are separate, so a person can hand a plate to a
#     parking service and never a VIN, or a VIN to a mechanic and never a
#     plate. Each is present or absent without the other.
# ---------------------------------------------------------------------------
report="$(rover_report 'FROM sys.columns WHERE namespace = %dbo AND name = %vehicle-vin SELECT col-name;')"
[ "$(count_rows "$report" '%col-name')" = 3 ] \
  || fail "fixture 61 vehicle-vin does not hold exactly three columns: $report"
for column in vehicle-id vin recorded-at; do
  grep -q "%col-name %tas %$column" <<<"$report" \
    || fail "fixture 61 vehicle-vin has no $column column: $report"
done
report="$(rover_report 'FROM sys.columns WHERE namespace = %dbo AND name = %vehicle-license-plate SELECT col-name;')"
[ "$(count_rows "$report" '%col-name')" = 3 ] \
  || fail "fixture 61 vehicle-license-plate does not hold exactly three columns: $report"
for column in vehicle-id plate recorded-at; do
  grep -q "%col-name %tas %$column" <<<"$report" \
    || fail "fixture 61 vehicle-license-plate has no $column column: $report"
done
# No relation anywhere holds an identifying column beside a descriptive one.
report="$(rover_report 'FROM sys.columns WHERE namespace = %dbo SELECT name, col-name;')"
identifier_homes="$(python3 -c '
import re, sys
report = sys.stdin.read()
pairs = re.findall(r"%name %tas %([a-z0-9-]+) %col-name %tas %([a-z0-9-]+)", report)
descriptive = {"make", "model", "sub-model", "model-year", "body-type", "color",
               "engine", "transmission", "drive-type", "bed-type", "note"}
homes = {}
for relation, column in pairs:
    homes.setdefault(relation, set()).add(column)
bad = []
for relation, columns in homes.items():
    identifying = columns & {"vin", "plate"}
    if identifying and (columns & descriptive):
        bad.append(relation)
    if len(identifying) > 1:
        bad.append(relation)
print(" ".join(sorted(bad)) if bad else "SEPARATE")
' <<<"$report")"
[ "$identifier_homes" = SEPARATE ] \
  || fail "fixture 61 an identifying column shares a relation it must not: $identifier_homes"
# A plate with no VIN, on a vehicle that also carries descriptive fields. The
# plate row exists and the VIN row does not, so a grant over one is not a grant
# over the other.
own_add_vehicle "$SPEC_PLATE_ONLY_VEHICLE" Gasoline
edit_vehicle "$(printf '{"vehicle":"%s","label":"%s","specPlate":"%s","specMake":"Honda","specModel":"Civic"}' \
  "$SPEC_PLATE_ONLY_VEHICLE" "$SPEC_PLATE_ONLY_VEHICLE" "$SPEC_PLATE_ONLY")" \
  'fixture 61 a plate with no VIN'
report="$(spec_rows vehicle-license-plate S plate "$SPEC_PLATE_ONLY_VEHICLE")"
grep -qF "$SPEC_PLATE_ONLY" <<<"$report" \
  || fail "fixture 61 the plate-only vehicle has no plate: $report"
report="$(spec_rows vehicle-vin S vin "$SPEC_PLATE_ONLY_VEHICLE")"
[ "$(count_rows "$report" '%vin')" = 0 ] \
  || fail "fixture 61 the plate-only vehicle gained a VIN row: $report"
# And the mirror: the late-VIN vehicle of fixture 59 carries a VIN and no plate.
report="$(spec_rows vehicle-license-plate S plate "$SPEC_LATE_VIN_VEHICLE")"
[ "$(count_rows "$report" '%plate')" = 0 ] \
  || fail "fixture 61 the VIN-only vehicle gained a plate row: $report"
# The whole descriptive read of every vehicle, with no identifying value in it.
report="$(rover_report "FROM vehicle-make M SELECT M.vehicle-id, M.make; FROM vehicle-model D SELECT D.vehicle-id, D.model;")"
grep -qF "$SPEC_VIN" <<<"$report" \
  && fail "fixture 61 a descriptive read returned a VIN: $report"
grep -qF "$SPEC_PLATE" <<<"$report" \
  && fail "fixture 61 a descriptive read returned a plate: $report"
note "fixture 61 PASS - VIN and plate each hold a relation of their own, share none with a descriptive field, and are present or absent independently of each other"

# ---------------------------------------------------------------------------
# fixture 62 - insurance is not built. Ruled 2026-08-18: a bare policy string
# is a stub of a feature, not a feature, and shipping the stub makes the real
# insurance feature harder because the stub's shape becomes a migration
# obligation. The fence stays shut until insurance is designed whole.
# ---------------------------------------------------------------------------
report="$(rover_report 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
grep -qi 'insurance' <<<"$report" \
  && fail "fixture 62 an insurance relation exists: $report"
report="$(rover_report 'FROM sys.columns WHERE namespace = %dbo SELECT name, col-name;')"
grep -qi 'insurance' <<<"$report" \
  && fail "fixture 62 an insurance column exists: $report"
# `Insurance` is a T2 SERVICE SUBTYPE LABEL, and it stays. A person records
# what they paid the insurer as an expense, which is a different thing from the
# policy machinery the fence covers. What must not exist is an insurance FIELD:
# a policy string on a vehicle, or a relation to hold one.
shipping_insurance="$(grep -rniE 'insurance-(policy|reference)|vehicle-insurance|specInsurance|insurancePolicy' "$REPO/desk" 2>/dev/null | tr '\n' ' ')"
[ -z "${shipping_insurance// /}" ] \
  || fail "fixture 62 the shipped desk carries an insurance field: $shipping_insurance"
starter_insurance="$(grep -c '"Insurance"' "$REPO/desk/lib/rover-act.hoon")"
[ "$starter_insurance" = 1 ] \
  || fail "fixture 62 the T2 Insurance service subtype starter changed, want exactly one"
note "fixture 62 PASS - no insurance relation, column, or field exists anywhere in the shipped desk, and the T2 expense subtype label is untouched"

# ---------------------------------------------------------------------------
# fixture 63 - no real VIN and no real plate is anywhere in the tree.
#
# A real VIN is seventeen characters drawn from an alphabet that EXCLUDES the
# letters I, O and Q, precisely so that they are never confused with 1 and 0.
# Every seventeen-character token in the tree that could be a real VIN is
# therefore a finding, and every VIN this battery writes contains I and O and
# so cannot be one.
#
# The owner's aCar export holds a real VIN and a real plate for two vehicles.
# It is gitignored and no VIN or plate out of it may reach the tree.
#
# M8 changed one thing here. Fixture 104 loads the owner's real corpus, so
# this battery does now open the export. Exactly one file may: the check below
# names it, and the shipped desk and the probes still may not.
# ---------------------------------------------------------------------------
vin_shaped="$(cd "$REPO" && git ls-files \
  | grep -vE '^desk/app/rover/assets/' \
  | while read -r tracked; do
      grep -oEn '\b[A-HJ-NPR-Z0-9]{17}\b' "$tracked" 2>/dev/null \
        | sed "s|^|$tracked:|"
    done | head -5 | tr '\n' ' ')"
[ -z "${vin_shaped// /}" ] \
  || fail "fixture 63 a token in the tree has the shape of a real VIN: $vin_shaped"
for synthetic in "$SPEC_VIN" "$SPEC_VIN_TYPO" "$SPEC_VIN_LATE"; do
  [ "${#synthetic}" = 17 ] \
    || fail "fixture 63 the synthetic VIN $synthetic is not seventeen characters"
  grep -qE '[IOQ]' <<<"$synthetic" \
    || fail "fixture 63 the synthetic VIN $synthetic could be a real one"
done
for synthetic in "$SPEC_PLATE" "$SPEC_PLATE_ONLY"; do
  grep -q 'FAKE' <<<"$synthetic" \
    || fail "fixture 63 the plate $synthetic is not marked synthetic"
done
# What names the export as a PATH is named here. A directory to open is a
# reader; naming it in prose - this comment does - is not.
# The needle is assembled at run time so this line is not itself a match.
export_needle="$(printf 'rover/aCar %s' 'export')"
export_readers="$(grep -rlF "$export_needle" "$REPO/probes" "$REPO/desk" 2>/dev/null | tr '\n' ' ')"
[ -z "${export_readers// /}" ] \
  || fail "fixture 63 the shipped desk or a probe opens the owner's aCar export: $export_readers"
export_readers="$(grep -rlF "$export_needle" "$REPO/bin" 2>/dev/null \
  | grep -v '/event-test\.sh$' | tr '\n' ' ')"
[ -z "${export_readers// /}" ] \
  || fail "fixture 63 something other than fixture 104 opens the owner's aCar export: $export_readers"
grep -q 'aCar export/' "$REPO/.gitignore" \
  || fail "fixture 63 the owner's aCar export is no longer gitignored"
note "fixture 63 PASS - every VIN in the tree contains a letter the real VIN alphabet excludes, every plate is marked FAKE, and the only file that opens the owner's export is the one fixture 104 runs from"

# ===========================================================================
# M7 T8 - the definition lifecycle.
#
# Nine owner-editable definition families, each with a label and an
# `archived @f` that the M0 and M7 pours already wrote. T8 adds rename,
# archive and restore, and it adds no relation and no column, because
# `archived` was there from the first row of every one of these families.
#
# Every family is proved. The families with a create endpoint get a
# definition of this run's own, stamped, so a row an earlier run left behind
# can never satisfy an assertion here. The families whose definitions only
# arrive in the starter pack are exercised ON a starter definition and put
# back the way they were found - which is the T8 rule that the starter pack
# is a convenience, not a protected set.
# ===========================================================================
T8_VEHICLE="Definition Vehicle $STAMP"
T8_ENERGY="T8 Fuel $STAMP"
T8_MODE="T8 Mode $STAMP"
T8_TAG="T8 Tag $STAMP"
T8_PAYMENT="T8 Card $STAMP"
T8_ADDITIVE="T8 Additive $STAMP"
T8_FIELD="T8 Field $STAMP"
T8_LONE_TAG="T8 Unused Tag $STAMP"
# Starter labels no earlier fixture touches, so a run of this battery that
# stops inside T8 cannot change what an earlier fixture sees.
T8_SUBTYPE='Muffler'
T8_DISPOSAL='Gifted'
T8_CONSUMABLE='DEF'
T8_FAMILIES='energy driving-mode consumable service-subtype disposal-kind additive tag payment-method custom-field'

t8_relation() {
  case "$1" in
    energy)           printf 'energy-definitions' ;;
    driving-mode)     printf 'driving-mode-definitions' ;;
    consumable)       printf 'consumable-definitions' ;;
    service-subtype)  printf 'service-subtype-definitions' ;;
    disposal-kind)    printf 'disposal-kind-definitions' ;;
    additive)         printf 'additive-definitions' ;;
    tag)              printf 'tag-definitions' ;;
    payment-method)   printf 'payment-method-definitions' ;;
    custom-field)     printf 'custom-field-definitions' ;;
    *)  fail "t8_relation: no such family $1" ;;
  esac
}

t8_id_column() {
  case "$1" in
    energy)           printf 'energy-definition-id' ;;
    driving-mode)     printf 'mode-id' ;;
    consumable)       printf 'consumable-id' ;;
    service-subtype)  printf 'service-subtype-id' ;;
    disposal-kind)    printf 'disposal-kind-id' ;;
    additive)         printf 'additive-id' ;;
    tag)              printf 'tag-id' ;;
    payment-method)   printf 'method-id' ;;
    custom-field)     printf 'field-id' ;;
    *)  fail "t8_id_column: no such family $1" ;;
  esac
}

# The label this run works with in each family.
t8_label() {
  case "$1" in
    energy)           printf '%s' "$T8_ENERGY" ;;
    driving-mode)     printf '%s' "$T8_MODE" ;;
    consumable)       printf '%s' "$T8_CONSUMABLE" ;;
    service-subtype)  printf '%s' "$T8_SUBTYPE" ;;
    disposal-kind)    printf '%s' "$T8_DISPOSAL" ;;
    additive)         printf '%s' "$T8_ADDITIVE" ;;
    tag)              printf '%s' "$T8_TAG" ;;
    payment-method)   printf '%s' "$T8_PAYMENT" ;;
    custom-field)     printf '%s' "$T8_FIELD" ;;
  esac
}

# The three writes, each through the endpoint a browser control calls.
t8_rename() {
  # family label newLabel note
  eyre_post rename-definition \
    "$(printf '{"family":"%s","label":"%s","newLabel":"%s"}' "$1" "$2" "$3")" \
    $'Renamed definition\n201' "$4"
}
t8_archive() {
  # family label note
  eyre_post archive-definition \
    "$(printf '{"family":"%s","label":"%s"}' "$1" "$2")" \
    $'Archived definition\n201' "$3"
}
t8_restore() {
  # family label note
  eyre_post restore-definition \
    "$(printf '{"family":"%s","label":"%s"}' "$1" "$2")" \
    $'Restored definition\n201' "$3"
}

# `Y` is archived and `N` is active, because the @f bunt is %.y. The report
# prints the flag as an atom: 0 is archived and 1 is active. An absent
# definition prints nothing at all, which no assertion below accepts.
t8_archived_flag() {
  # family label
  local report
  report="$(rover_report "FROM $(t8_relation "$1") D WHERE D.label = '$2' SELECT D.archived;")"
  grep -oE '%archived 102 [01]' <<<"$report" | head -1 | awk '{print $3}'
}

# How many rows of one family carry one label. Archive must never change this,
# and rename must never make it two.
t8_row_count() {
  # family label
  local report column
  column="$(t8_id_column "$1")"
  report="$(rover_report "FROM $(t8_relation "$1") D WHERE D.label = '$2' SELECT D.$column;")"
  count_rows "$report" "%$column"
}

# Is this label OFFERED to a person filling in a form? The check is scoped to
# the entry screen that offers the family, so a label that survives on the
# edit form of a record already naming it - which it must - is not mistaken
# for a selector that still offers it.
t8_offers() {
  # family label
  local screen control kind
  case "$1" in
    energy)           screen='vehicle-create-screen'; control='energy';        kind=select ;;
    driving-mode)     screen='add-fill';              control='drivingMode';   kind=select ;;
    consumable)       screen='add-consumable';        control='consumable';    kind=select ;;
    service-subtype)  screen='add-event';             control='subtypes';      kind=check ;;
    disposal-kind)    screen='add-event';             control='disposalKind';  kind=select ;;
    additive)         screen='add-fill';              control='additives';     kind=check ;;
    tag)              screen='add-fill';              control='tags';          kind=check ;;
    payment-method)   screen='add-fill';              control='paymentMethod'; kind=select ;;
    custom-field)     screen='add-fill';              control='';              kind=custom ;;
    *)  fail "t8_offers: no such family $1" ;;
  esac
  python3 -c '
import re, sys
document = sys.stdin.read()
screen, control, kind, label = sys.argv[1:5]
found = re.search(
    r"<section id=\"%s\"[^>]*>.*?(?=<section id=\"[a-z-]+\"[^>]*class=\"[^\"]*app-screen)"
    % re.escape(screen), document, re.S)
slice = found.group(0) if found else ""
if not slice:
    sys.stdout.write("no-screen")
    sys.exit(0)
if kind == "custom":
    hit = ("data-custom-label=\"%s\"" % label) in slice
elif kind == "select":
    picked = re.search(
        r"<select name=\"%s\"[^>]*>(.*?)</select>" % re.escape(control), slice, re.S)
    hit = picked is not None and ("value=\"%s\"" % label) in picked.group(1)
else:
    hit = ("name=\"%s\" value=\"%s\"" % (control, label)) in slice
sys.stdout.write("yes" if hit else "no")
' "$screen" "$control" "$kind" "$2" <<<"$view"
}

# The membership grids of the vehicle settings form, which are a second
# selector for two of the families.
t8_settings_offers() {
  # control label
  local card
  card="$(vehicle_card "$T8_VEHICLE")"
  if grep -qF "name=\"$1\" value=\"$2\"" <<<"$card"; then
    printf 'yes'
  else
    printf 'no'
  fi
}

# The one served fill card that carries a given text. The class is
# `history-card fill`, so a charge and an event card cannot be mistaken for
# one.
fill_card_with() {
  python3 -c '
import re, sys
document = sys.stdin.read()
for match in re.finditer(r"<article class=\"history-card fill\".*?</article>", document, re.S):
    if sys.argv[1] in match.group(0):
        sys.stdout.write(match.group(0))
        break
' "$1" <<<"$view"
}

# The history row of this run's fill, with the edit form inside it. The
# history screen is scoped to one vehicle, so this is the only row it holds.
fill_edit_form() {
  python3 -c '
import re, sys
document = sys.stdin.read()
found = re.search(
    r"<article class=\"history-table-row\" data-history-vehicle=\"%s\".*?</article>"
    % re.escape(sys.argv[1]), document, re.S)
sys.stdout.write(found.group(0) if found else "")
' "$T8_VEHICLE" <<<"$view"
}

# --- the state every T8 fixture reads -------------------------------------
# One vehicle, one definition of this run's own in each family that has a
# create endpoint, and one real record naming every one of the nine.
own_add_vehicle "$T8_VEHICLE" Gasoline
eyre_post add-energy-source-type \
  "$(printf '{"label":"%s","physicalKind":"reservoir","quantityUnit":"gal"}' "$T8_ENERGY")" \
  $'Created energy source type\n201' 'T8 energy source'
eyre_post add-driving-mode-type "$(printf '{"label":"%s"}' "$T8_MODE")" \
  $'Created driving mode type\n201' 'T8 driving mode'
eyre_post add-custom-field \
  "$(printf '{"label":"%s","contentType":"text","mandatory":"no"}' "$T8_FIELD")" \
  $'Created custom field\n201' 'T8 custom field'
# Tags, payment methods and additives have no create endpoint of their own;
# the import path is the product surface that makes them.
curl -s -b "$JAR" -H 'content-type: application/json' \
  --data-raw "$(printf '{"rover-import":1,"source":{"app":"rover-event-test"},"definitions":{"energy":[],"additives":[{"label":"%s"}],"driving-modes":[],"tags":[{"label":"%s"},{"label":"%s"}],"payment-methods":[{"label":"%s"}]},"places":[],"vehicles":[]}' \
    "$T8_ADDITIVE" "$T8_TAG" "$T8_LONE_TAG" "$T8_PAYMENT")" \
  "$URL/apps/rover/import" > /dev/null
# The vehicle takes the new energy source and the new driving mode, and turns
# DEF on, so all three are selectable on its forms.
edit_vehicle "$(printf '{"vehicle":"%s","label":"%s","energySources":["Gasoline","%s"],"drivingModes":["%s"],"defEnabled":"yes","defTankSize":"5","defTankUnit":"gal"}' \
  "$T8_VEHICLE" "$T8_VEHICLE" "$T8_ENERGY" "$T8_MODE")" 'T8 vehicle configuration'
add_odometer_reading "$T8_VEHICLE" 70000 '2026-06-01T08:00' '70,000'
# One fill that names the energy source, the driving mode, the tag, the
# payment method, the additive and the custom field at once.
T8_FILL_AT='2026-06-02T10:00'
T8_FILL_DA='~2026.06.02..10.00.00'
T8_FIELD_VALUE="Receipt $STAMP"
eyre_post add-fill \
  "$(printf '{"vehicle":"%s","definition":"%s","quantity":"10.000","price":"$4.10","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"70100","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":["%s"],"subtype":"","missedFill":"no","drivingMode":"%s","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":["%s"],"newTag":"","notes":"","paymentMethod":"%s","custom-%s":"%s"}' \
    "$T8_VEHICLE" "$T8_ENERGY" "$T8_FILL_AT" "$T8_ADDITIVE" "$T8_MODE" "$T8_TAG" "$T8_PAYMENT" "$T8_FIELD" "$T8_FIELD_VALUE")" \
  $'Saved fill - $4.109 - derived $41.09\n201' 'T8 fill'
# One service event that names the starter subtype.
T8_SERVICE_AT='2026-06-03T10:00'
T8_SERVICE_DA='~2026.06.03..10.00.00'
T8_SERVICE_NOTE="T8 muffler work $STAMP"
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"%s","zone":"America/Chicago","total":"$210.00","currency":"usd","mileage":"70200","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"%s","subtypes":["%s"]}' \
    "$T8_VEHICLE" "$T8_SERVICE_AT" "$T8_SERVICE_NOTE" "$T8_SUBTYPE")" \
  $'Saved service event - $210.00\n201' 'T8 service event'
# One disposal that names the starter disposal kind.
T8_DISPOSAL_AT='2026-06-04T10:00'
T8_DISPOSAL_NOTE="T8 given away $STAMP"
eyre_post add-disposal-event \
  "$(ownership_payload "$T8_VEHICLE" "$T8_DISPOSAL_AT" '$0.00' 70300 "$T8_DISPOSAL" "$T8_DISPOSAL_NOTE")" \
  $'Saved disposal event - $0.00\n201' 'T8 disposal event'
# One DEF purchase, the record that names the consumable definition.
T8_DEF_AT='2026-06-05T10:00'
eyre_post add-consumable \
  "$(printf '{"vehicle":"%s","consumable":"%s","quantity":"2.500","price":"$8.00","profile":"us-usd-gal","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"70400","mileageUnit":"mi"}' \
    "$T8_VEHICLE" "$T8_CONSUMABLE" "$T8_DEF_AT")" \
  $'Saved consumable purchase - $20.02\n201' 'T8 DEF purchase'

# ---------------------------------------------------------------------------
# fixture 66 - every one of the nine families renames, and the new label is on
# the row rather than on a second row beside it. The old label is gone from
# the relation entirely: a rename is an UPDATE, not an insert.
# ---------------------------------------------------------------------------
for family in $T8_FAMILIES; do
  before="$(t8_label "$family")"
  after="$before (renamed $STAMP)"
  [ "$(t8_row_count "$family" "$before")" = 1 ] \
    || fail "fixture 66 $family has no single row labelled $before before the rename"
  t8_rename "$family" "$before" "$after" "fixture 66 rename in $family"
  [ "$(t8_row_count "$family" "$after")" = 1 ] \
    || fail "fixture 66 $family has no row labelled $after after the rename"
  [ "$(t8_row_count "$family" "$before")" = 0 ] \
    || fail "fixture 66 $family kept a row under the old label $before"
  t8_rename "$family" "$after" "$before" "fixture 66 rename back in $family"
  [ "$(t8_row_count "$family" "$before")" = 1 ] \
    || fail "fixture 66 $family did not come back to $before"
done
note "fixture 66 PASS - all nine definition families rename in place, one row keeps one identity, and the old label leaves the relation"

# ---------------------------------------------------------------------------
# fixture 67 - archive is not delete. Every family archives, the row stays in
# the relation, and the flag is what moved.
# ---------------------------------------------------------------------------
for family in $T8_FAMILIES; do
  label="$(t8_label "$family")"
  [ "$(t8_archived_flag "$family" "$label")" = 1 ] \
    || fail "fixture 67 $family definition $label is not active before the archive"
  t8_archive "$family" "$label" "fixture 67 archive in $family"
  [ "$(t8_archived_flag "$family" "$label")" = 0 ] \
    || fail "fixture 67 $family definition $label did not archive"
  [ "$(t8_row_count "$family" "$label")" = 1 ] \
    || fail "fixture 67 archiving removed the $family row for $label"
done
note "fixture 67 PASS - all nine families archive by flipping a flag, and no row leaves any relation"

# ---------------------------------------------------------------------------
# fixture 68 - an archived definition leaves every selector it was offered in.
# Read from the served view, which is the document the browser renders.
# ---------------------------------------------------------------------------
view="$(eyre_view_vehicle "$T8_VEHICLE")"
for family in $T8_FAMILIES; do
  label="$(t8_label "$family")"
  [ "$(t8_offers "$family" "$label")" = no ] \
    || fail "fixture 68 the $family selector still offers the archived $label"
done
# The two families that have a second selector - the membership grids of the
# vehicle settings form - leave that one too.
[ "$(t8_settings_offers energySources "$T8_ENERGY")" = no ] \
  || fail "fixture 68 the vehicle settings energy grid still offers the archived $T8_ENERGY"
[ "$(t8_settings_offers drivingModes "$T8_MODE")" = no ] \
  || fail "fixture 68 the vehicle settings driving-mode grid still offers the archived $T8_MODE"
note "fixture 68 PASS - an archived definition in each of the nine families is gone from every selector that offered it"

# ---------------------------------------------------------------------------
# fixture 69 - and it still renders on every historical record that names it.
# This is the half that makes archive honest: a fill from 2019 still says
# which fuel it was, whether or not that fuel is still offered today.
# ---------------------------------------------------------------------------
fill_card="$(fill_card_with "$T8_ENERGY")"
[ -n "$fill_card" ] || fail "fixture 69 the fill this run wrote is not in the served history"
for archived_label in "$T8_ENERGY" "$T8_ADDITIVE"; do
  grep -qF "$archived_label" <<<"$fill_card" \
    || fail "fixture 69 the fill card lost $archived_label when it was archived"
done
# The tag, the payment method and the driving mode of a fill render on the
# record's own edit form rather than on its card. An archived definition the
# record already names must still be there AND still be selected: dropping it
# would make saving an unrelated edit quietly delete an association nobody
# touched.
edit_form="$(fill_edit_form)"
[ -n "$edit_form" ] || fail "fixture 69 the fill this run wrote has no edit form"
grep -qF "name=\"tags\" value=\"$T8_TAG\" checked" <<<"$edit_form" \
  || fail "fixture 69 the fill edit form lost the archived tag $T8_TAG"
grep -qF "<option value=\"$T8_PAYMENT\" selected>" <<<"$edit_form" \
  || fail "fixture 69 the fill edit form lost the archived payment method $T8_PAYMENT"
grep -qF "<option value=\"$T8_MODE\" selected>" <<<"$edit_form" \
  || fail "fixture 69 the fill edit form lost the archived driving mode $T8_MODE"
grep -qF "name=\"additives\" value=\"$T8_ADDITIVE\" checked" <<<"$edit_form" \
  || fail "fixture 69 the fill edit form lost the archived additive $T8_ADDITIVE"
# And an archived definition this record does NOT name is gone from the same
# form, so the rule is "what this record already says", not "show everything".
t8_archive tag "$T8_LONE_TAG" 'fixture 69 archive a tag no record names'
view="$(eyre_view_vehicle "$T8_VEHICLE")"
edit_form="$(fill_edit_form)"
grep -qF "name=\"tags\" value=\"$T8_LONE_TAG\"" <<<"$edit_form" \
  && fail "fixture 69 the fill edit form offers an archived tag the record never named"
grep -qF "name=\"tags\" value=\"$T8_TAG\" checked" <<<"$edit_form" \
  || fail "fixture 69 the fill edit form dropped the archived tag it does name"
t8_restore tag "$T8_LONE_TAG" 'fixture 69 restore the tag no record names'
service_card="$(event_card service "$T8_SERVICE_NOTE")"
[ -n "$service_card" ] || fail "fixture 69 the service event this run wrote is not in the served history"
grep -qF "$T8_SUBTYPE" <<<"$service_card" \
  || fail "fixture 69 the service card lost the archived subtype $T8_SUBTYPE"
disposal_card="$(event_card disposal "$T8_DISPOSAL_NOTE")"
[ -n "$disposal_card" ] || fail "fixture 69 the disposal this run wrote is not in the served history"
grep -qF "$T8_DISPOSAL" <<<"$disposal_card" \
  || fail "fixture 69 the disposal card lost the archived kind $T8_DISPOSAL"
# The consumable and the custom field render nowhere on a history card, so
# their records are read where they live: an archived definition must still
# join to the record that names it.
report="$(rover_report "FROM consumable-definitions D JOIN consumable-acquisitions A ON D.consumable-id = A.consumable-id JOIN vehicles V ON A.vehicle-id = V.vehicle-id WHERE V.label = '$T8_VEHICLE' SELECT D.label, A.observed-start;")"
grep -qF "%label 116 '$T8_CONSUMABLE'" <<<"$report" \
  || fail "fixture 69 the DEF purchase lost its archived definition: $report"
report="$(rover_report "FROM custom-field-definitions D JOIN custom-field-values-text X ON D.field-id = X.field-id WHERE D.label = '$T8_FIELD' SELECT X.value;")"
grep -qF "$T8_FIELD_VALUE" <<<"$report" \
  || fail "fixture 69 the custom field value lost its archived definition: $report"
note "fixture 69 PASS - every historical record still renders the definition it names after that definition is archived"

# ---------------------------------------------------------------------------
# fixture 70 - archive is reversible, and a restored definition comes back to
# every selector it left.
# ---------------------------------------------------------------------------
for family in $T8_FAMILIES; do
  label="$(t8_label "$family")"
  t8_restore "$family" "$label" "fixture 70 restore in $family"
  [ "$(t8_archived_flag "$family" "$label")" = 1 ] \
    || fail "fixture 70 $family definition $label did not come back"
done
view="$(eyre_view_vehicle "$T8_VEHICLE")"
for family in $T8_FAMILIES; do
  label="$(t8_label "$family")"
  [ "$(t8_offers "$family" "$label")" = yes ] \
    || fail "fixture 70 the $family selector did not take $label back after the restore"
done
[ "$(t8_settings_offers energySources "$T8_ENERGY")" = yes ] \
  || fail "fixture 70 the vehicle settings energy grid did not take $T8_ENERGY back"
[ "$(t8_settings_offers drivingModes "$T8_MODE")" = yes ] \
  || fail "fixture 70 the vehicle settings driving-mode grid did not take $T8_MODE back"
note "fixture 70 PASS - every archived definition restores, and each one returns to the selectors it left"

# ---------------------------------------------------------------------------
# fixture 71 - a rename reaches the historical records. The old label appears
# nowhere in the served document and the new one appears where the old one
# was. Rover renders a label by joining to the definition, so there is no
# copy of the old text anywhere to go stale.
# ---------------------------------------------------------------------------
# Neither corrected label contains the label it replaces, so a document that
# still holds the old text cannot pass by being a prefix of the new one.
T8_TAG_FIXED="T8 Corrected Label $STAMP"
T8_SUBTYPE_FIXED="Exhaust Silencer $STAMP"
T8_ENERGY_FIXED="T8 Corrected Fuel $STAMP"
t8_rename tag "$T8_TAG" "$T8_TAG_FIXED" 'fixture 71 the corrected tag'
t8_rename service-subtype "$T8_SUBTYPE" "$T8_SUBTYPE_FIXED" 'fixture 71 the corrected subtype'
t8_rename energy "$T8_ENERGY" "$T8_ENERGY_FIXED" 'fixture 71 the corrected energy source'
view="$(eyre_view_vehicle "$T8_VEHICLE")"
# The old text is nowhere in the whole served document. Rover renders a label
# by joining to the definition, so there is no second copy to go stale.
grep -qF ">$T8_SUBTYPE<" <<<"$view" \
  && fail "fixture 71 the old subtype label is still rendered somewhere"
grep -qF "$T8_TAG" <<<"$view" \
  && fail "fixture 71 the old tag label is still rendered somewhere"
grep -qF "$T8_ENERGY" <<<"$view" \
  && fail "fixture 71 the old energy source label is still rendered somewhere"
service_card="$(event_card service "$T8_SERVICE_NOTE")"
grep -qF "$T8_SUBTYPE_FIXED" <<<"$service_card" \
  || fail "fixture 71 the service card does not carry the corrected subtype"
fill_card="$(fill_card_with "$T8_ENERGY_FIXED")"
[ -n "$fill_card" ] || fail "fixture 71 no fill card carries the corrected energy source"
edit_form="$(fill_edit_form)"
grep -qF "name=\"tags\" value=\"$T8_TAG_FIXED\" checked" <<<"$edit_form" \
  || fail "fixture 71 the fill this run wrote does not carry the corrected tag"
[ "$(t8_offers tag "$T8_TAG_FIXED")" = yes ] \
  || fail "fixture 71 the tag selector does not offer the corrected label"
t8_rename tag "$T8_TAG_FIXED" "$T8_TAG" 'fixture 71 the tag put back'
t8_rename service-subtype "$T8_SUBTYPE_FIXED" "$T8_SUBTYPE" 'fixture 71 the subtype put back'
t8_rename energy "$T8_ENERGY_FIXED" "$T8_ENERGY" 'fixture 71 the energy source put back'
note "fixture 71 PASS - a rename reaches every record that names the definition, the old label renders nowhere, and the corrected one is offered again"

# ---------------------------------------------------------------------------
# fixture 72 - seed-starters does not resurrect an archived starter. The
# starter pack is a convenience, not a protected set: an owner who archives a
# starter definition must not find it back tomorrow.
# ---------------------------------------------------------------------------
t8_archive service-subtype "$T8_SUBTYPE" 'fixture 72 archive a seeded starter'
t8_archive disposal-kind "$T8_DISPOSAL" 'fixture 72 archive a seeded disposal kind'
t8_archive consumable "$T8_CONSUMABLE" 'fixture 72 archive a seeded consumable'
seed_starters() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(~))' > /dev/null
}
seed_starters
seed_starters
for pair in "service-subtype:$T8_SUBTYPE" "disposal-kind:$T8_DISPOSAL" "consumable:$T8_CONSUMABLE"; do
  family="${pair%%:*}"
  label="${pair##*:}"
  [ "$(t8_archived_flag "$family" "$label")" = 0 ] \
    || fail "fixture 72 seeding brought the archived $family definition $label back"
  [ "$(t8_row_count "$family" "$label")" = 1 ] \
    || fail "fixture 72 seeding wrote a second $family row for $label"
done
t8_restore service-subtype "$T8_SUBTYPE" 'fixture 72 put the starter back'
t8_restore disposal-kind "$T8_DISPOSAL" 'fixture 72 put the disposal kind back'
t8_restore consumable "$T8_CONSUMABLE" 'fixture 72 put the consumable back'
note "fixture 72 PASS - two runs of seed-starters leave an archived starter definition archived, and add no second row"

# ---------------------------------------------------------------------------
# fixture 73 - a definition no record references archives and restores just
# the same. Archive is a display decision, not a consequence of the record
# count, and nothing here reads one.
# ---------------------------------------------------------------------------
report="$(rover_report "FROM tag-definitions D JOIN fuel-fill-tags L ON D.tag-id = L.tag-id WHERE D.label = '$T8_LONE_TAG' SELECT L.acquisition-id;")"
[ "$(count_rows "$report" '%acquisition-id')" = 0 ] \
  || fail "fixture 73 the unreferenced tag is referenced after all: $report"
report="$(rover_report "FROM tag-definitions D JOIN vehicle-event-tags L ON D.tag-id = L.tag-id WHERE D.label = '$T8_LONE_TAG' SELECT L.event-id;")"
[ "$(count_rows "$report" '%event-id')" = 0 ] \
  || fail "fixture 73 the unreferenced tag is on an event after all: $report"
t8_archive tag "$T8_LONE_TAG" 'fixture 73 archive an unreferenced definition'
[ "$(t8_archived_flag tag "$T8_LONE_TAG")" = 0 ] \
  || fail "fixture 73 the unreferenced tag did not archive"
view="$(eyre_view_vehicle "$T8_VEHICLE")"
[ "$(t8_offers tag "$T8_LONE_TAG")" = no ] \
  || fail "fixture 73 the archived unreferenced tag is still offered"
t8_restore tag "$T8_LONE_TAG" 'fixture 73 restore an unreferenced definition'
[ "$(t8_archived_flag tag "$T8_LONE_TAG")" = 1 ] \
  || fail "fixture 73 the unreferenced tag did not restore"
view="$(eyre_view_vehicle "$T8_VEHICLE")"
[ "$(t8_offers tag "$T8_LONE_TAG")" = yes ] \
  || fail "fixture 73 the restored unreferenced tag is not offered again"
note "fixture 73 PASS - a definition no record references archives and restores, and no usage count is consulted"

# ---------------------------------------------------------------------------
# fixture 74 - one label, one family. A rename that would put two rows of one
# family under one label is refused, because the label is the only handle
# Rover has on a definition and a collision makes BOTH rows unreachable.
#
# The refusal is per family and nothing else. The T2 starter catalog puts
# Car Wash, Insurance and Registration in more than one family on purpose,
# and this rule must not disturb that.
# ---------------------------------------------------------------------------
response="$(curl -s -b "$JAR" -w $'\n%{http_code}' -H 'content-type: application/json' \
  --data-raw "$(printf '{"family":"tag","label":"%s","newLabel":"%s"}' "$T8_LONE_TAG" "$T8_TAG")" \
  "$URL/apps/rover/rename-definition")"
[ "$response" = $'%duplicate-label: definition\n409' ] \
  || fail "fixture 74 a colliding rename was not refused: $response"
[ "$(t8_row_count tag "$T8_LONE_TAG")" = 1 ] \
  || fail "fixture 74 the refused rename changed the row it named"
[ "$(t8_row_count tag "$T8_TAG")" = 1 ] \
  || fail "fixture 74 the refused rename made a second row under $T8_TAG"
# A collision with an ARCHIVED row is a collision too: the archived row is
# still addressed by its label, and restoring it later must still work.
t8_archive tag "$T8_TAG" 'fixture 74 archive the collision target'
response="$(curl -s -b "$JAR" -w $'\n%{http_code}' -H 'content-type: application/json' \
  --data-raw "$(printf '{"family":"tag","label":"%s","newLabel":"%s"}' "$T8_LONE_TAG" "$T8_TAG")" \
  "$URL/apps/rover/rename-definition")"
[ "$response" = $'%duplicate-label: definition\n409' ] \
  || fail "fixture 74 a rename onto an archived label was allowed: $response"
t8_restore tag "$T8_TAG" 'fixture 74 restore the collision target'
# The same label in two different families is untouched. Car Wash is a
# service subtype in the T2 catalog; making it a tag as well must succeed.
t8_rename tag "$T8_LONE_TAG" 'Car Wash' 'fixture 74 the cross-family label'
[ "$(t8_row_count tag 'Car Wash')" = 1 ] \
  || fail "fixture 74 the cross-family rename did not land"
[ "$(t8_row_count service-subtype 'Car Wash')" = 1 ] \
  || fail "fixture 74 the cross-family rename disturbed the service subtype"
t8_rename tag 'Car Wash' "$T8_LONE_TAG" 'fixture 74 the cross-family label put back'
note "fixture 74 PASS - a label collides only inside its own family, an archived row still holds its label, and the shared T2 catalog labels are undisturbed"

# ---------------------------------------------------------------------------
# fixture 75 - the refusals. A request that names no family Rover knows, a
# definition that is not there, or an empty new label is refused, and nothing
# is written.
# ---------------------------------------------------------------------------
t8_refusal() {
  # path payload expected note
  local response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' -H 'content-type: application/json' \
    --data-raw "$2" "$URL/apps/rover/$1")"
  [ "$response" = "$3" ] || fail "fixture 75 $4: $response"
}
t8_refusal archive-definition '{"family":"vehicle","label":"Gasoline"}' \
  $'%unknown-family: definition.family\n400' 'a family Rover does not manage'
t8_refusal archive-definition '{"family":"tag","label":"No Such Tag At All"}' \
  $'%not-found: definition\n404' 'a definition that is not there'
t8_refusal rename-definition "$(printf '{"family":"tag","label":"%s","newLabel":""}' "$T8_TAG")" \
  $'%bad-shape: definition.new-label\n400' 'an empty new label'
t8_refusal rename-definition "$(printf '{"family":"tag","label":"%s"}' "$T8_TAG")" \
  $'%missing-key: definition.new-label\n400' 'a rename with no new label'
t8_refusal archive-definition '{"label":"anything"}' \
  $'%missing-key: definition.family\n400' 'a body with no family'
# The route decides the operation. A body that asks to be renamed at the
# archive endpoint is archived, because the endpoint is what was called.
[ "$(t8_row_count tag "$T8_TAG")" = 1 ] \
  || fail "fixture 75 a refused request changed the tag relation"
[ "$(t8_archived_flag tag "$T8_TAG")" = 1 ] \
  || fail "fixture 75 a refused request archived a definition"
note "fixture 75 PASS - an unknown family, an absent definition, and a missing or empty new label are each refused, and none of them writes"


# ===========================================================================
# M7 T12 - correcting an event
# ===========================================================================
# A correction is an UPDATE in place at NOW and the event keeps its identity.
# No fixture below reads a revision row or a reversing entry, because Rover
# writes neither: Obelisk retains the prior content state and fixture 87 reads
# it back AS OF.

# ---------------------------------------------------------------------------
# fixture 87 - a service cost is corrected and the event keeps its identity.
# Modelled on fixture 60: the parent id before and after are one id, every
# association row still names that id, and the pre-correction content is still
# readable AS OF. A read AS OF is allowed; Rover never mutates AS OF.
# ---------------------------------------------------------------------------
eyre_post add-vehicle \
  "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[]}' "$FIX_VEHICLE")" \
  "$(printf 'Added vehicle - %s\n201' "$FIX_VEHICLE")" 'fixture 87 the correction vehicle'
eyre_post add-service-event \
  "$(fix_payload "$FIX_AT" "$FIX_TOTAL" "$FIX_ODO" "$STATION" "[\"$TAG\"]" "$PAYMENT" "$FIX_NOTE" '["Engine Oil"]')" \
  $'Saved service event - $300.00\n201' 'fixture 87 the event to correct'
fix_id_before="$(event_id_at "$FIX_DA" "$FIX_VEHICLE")"
[ -n "$fix_id_before" ] || fail "fixture 87 the event to correct was not stored"
# The AS OF stamp has to fall strictly between the two writes, and the host
# clock has one-second resolution, so it is fenced by a second on each side.
sleep 2
FIX_AS_OF="$(date -u +'~%Y.%m.%d..%H.%M.%S')"
sleep 2
eyre_post edit-event \
  "$(edit_payload service "$FIX_AT" "$FIX_AT" "$FIX_TOTAL_FIXED" "$FIX_ODO" \
    "$STATION" "[\"$TAG\"]" "$PAYMENT" "$FIX_NOTE" '["Engine Oil"]' "$FIX_VEHICLE")" \
  $'Corrected service event - $355.25\n200' 'fixture 87 the correction'
fix_id_after="$(event_id_at "$FIX_DA" "$FIX_VEHICLE")"
[ "$fix_id_after" = "$fix_id_before" ] \
  || fail "fixture 87 the correction re-keyed the event: $fix_id_before became $fix_id_after"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$FIX_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 355250 ] \
  || fail "fixture 87 the corrected total is not 355,250 mills: $report"
# Every association still targets the same parent, including the typed child.
for pair in \
  'service-events C' \
  'vehicle-event-costs C' \
  'vehicle-event-cost-totals T' \
  'vehicle-event-odometers L' \
  'vehicle-event-stations S' \
  'vehicle-event-tags G' \
  'vehicle-event-service-subtypes B' \
  'vehicle-event-payment-method P' \
  'vehicle-event-notes Z'
do
  set -- $pair
  report="$(scoped_rows "$1" "$2" event-id "$FIX_DA" "$FIX_VEHICLE")"
  linked="$(grep -oE '%event-id [0-9]+ [0-9a-fx.]+' <<<"$report" | head -1)"
  [ "$linked" = "$fix_id_before" ] \
    || fail "fixture 87 the $1 row no longer targets the corrected event: $linked"
done
# The audit trail the correction posture relies on. The prior content state is
# still there, and only a read reaches it.
report="$(rover_report "FROM vehicles AS OF $FIX_AS_OF V JOIN vehicle-events AS OF $FIX_AS_OF E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-cost-totals AS OF $FIX_AS_OF T ON E.event-id = T.event-id WHERE V.label = '$FIX_VEHICLE' AND E.observed-start = $FIX_DA SELECT E.event-id, T.total-mills;")"
[ "$(cell_number "$report" total-mills)" = 300000 ] \
  || fail "fixture 87 the pre-correction total is not readable AS OF: $report"
# The identity the whole task turns on, printed so the run itself carries it.
as_of_id="$(grep -oE '%event-id [0-9]+ [0-9a-fx.]+' <<<"$report" | head -1)"
[ "$as_of_id" = "$fix_id_before" ] \
  || fail "fixture 87 the event AS OF the earlier time is a different row: $as_of_id"
note "fixture 87 identity - before: $fix_id_before"
note "fixture 87 identity - after:  $fix_id_after"
note "fixture 87 identity - AS OF $FIX_AS_OF: $as_of_id at 300,000 mills"
note "fixture 87 PASS - a corrected cost keeps the event id, every association still targets it, and the prior total reads back AS OF"

# ---------------------------------------------------------------------------
# fixture 88 - the correction produced no second event. The family row count
# for the vehicle is what it was, and History renders one card, not two.
# ---------------------------------------------------------------------------
event_count_for_vehicle() {
  count_rows \
    "$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = '$FIX_VEHICLE' SELECT E.event-id;")" \
    '%event-id'
}
count_before="$(event_count_for_vehicle)"
eyre_post edit-event \
  "$(edit_payload service "$FIX_AT" "$FIX_AT" "$FIX_TOTAL_FIXED" "$FIX_ODO" \
    "$STATION" "[\"$TAG\"]" "$PAYMENT" "$FIX_NOTE" '["Engine Oil"]' "$FIX_VEHICLE")" \
  $'Corrected service event - $355.25\n200' 'fixture 88 a second correction'
count_after="$(event_count_for_vehicle)"
[ "$count_after" = "$count_before" ] \
  || fail "fixture 88 the correction changed the event count from $count_before to $count_after"
report="$(scoped_rows service-events C event-id "$FIX_DA" "$FIX_VEHICLE")"
[ "$(count_rows "$report" '%event-id')" = 1 ] \
  || fail "fixture 88 the correction left two typed child rows: $report"
view="$(eyre_view)"
cards="$(event_card_count service "$FIX_NOTE")"
[ "$cards" = 1 ] \
  || fail "fixture 88 History renders $cards cards for one corrected event"
card="$(event_card service "$FIX_NOTE")"
grep -qF 'data-event-total="$355.25"' <<<"$card" \
  || fail "fixture 88 the rendered card does not carry the corrected total: $card"
note "fixture 88 PASS - correcting twice made no second event, no second typed child, and one card"

# ---------------------------------------------------------------------------
# fixture 89 - an association is removed by correction. The tag and the
# payment method were present, the corrected form carries neither, and no row
# survives keyed to the event.
# ---------------------------------------------------------------------------
report="$(scoped_rows vehicle-event-tags G tag-id "$FIX_DA" "$FIX_VEHICLE")"
[ "$(count_rows "$report" '%tag-id')" = 1 ] \
  || fail "fixture 89 the event did not carry a tag before the correction: $report"
report="$(scoped_rows vehicle-event-payment-method P method-id "$FIX_DA" "$FIX_VEHICLE")"
[ "$(count_rows "$report" '%method-id')" = 1 ] \
  || fail "fixture 89 the event did not carry a payment method before: $report"
eyre_post edit-event \
  "$(edit_payload service "$FIX_AT" "$FIX_AT" "$FIX_TOTAL_FIXED" "$FIX_ODO" \
    "$STATION" '[]' '' "$FIX_NOTE" '["Engine Oil"]' "$FIX_VEHICLE")" \
  $'Corrected service event - $355.25\n200' 'fixture 89 the removing correction'
report="$(scoped_rows vehicle-event-tags G tag-id "$FIX_DA" "$FIX_VEHICLE")"
grep -q '%tag-id' <<<"$report" \
  && fail "fixture 89 a tag link survived its removal: $report"
report="$(scoped_rows vehicle-event-payment-method P method-id "$FIX_DA" "$FIX_VEHICLE")"
grep -q '%method-id' <<<"$report" \
  && fail "fixture 89 a payment-method link survived its removal: $report"
# The definitions themselves are untouched. Removing an association removes a
# link, never the thing it named.
report="$(rover_report "FROM tag-definitions T WHERE T.label = '$TAG' SELECT T.tag-id;")"
[ "$(count_rows "$report" '%tag-id')" = 1 ] \
  || fail "fixture 89 removing the link removed the tag definition: $report"
report="$(rover_report "FROM payment-method-definitions P WHERE P.label = '$PAYMENT' SELECT P.method-id;")"
[ "$(count_rows "$report" '%method-id')" = 1 ] \
  || fail "fixture 89 removing the link removed the payment method: $report"
view="$(eyre_view)"
card="$(event_card service "$FIX_NOTE")"
grep -q 'data-event-tag=' <<<"$card" \
  && fail "fixture 89 the card still renders a tag: $card"
grep -q 'PAYMENT METHOD' <<<"$card" \
  && fail "fixture 89 the card still renders a payment method: $card"
note "fixture 89 PASS - a tag and a payment method go from present to absent by correction, with no orphan row and no lost definition"

# ---------------------------------------------------------------------------
# fixture 90 - an association is added by correction to an event that had
# none. The bare event gains a total, an odometer, a station, a tag, and a
# payment method, and each one keys to the same parent.
# ---------------------------------------------------------------------------
eyre_post add-note-event \
  "$(fix_payload "$BARE_EDIT_AT" '' '' none '[]' '' "$BARE_EDIT_NOTE" '[]')" \
  $'Saved note event\n201' 'fixture 90 the bare event'
bare_id_before="$(event_id_at "$BARE_EDIT_DA" "$FIX_VEHICLE")"
[ -n "$bare_id_before" ] || fail "fixture 90 the bare event was not stored"
for pair in 'vehicle-event-costs C cost-state' 'vehicle-event-odometers L odometer-id' \
  'vehicle-event-stations S station-id' 'vehicle-event-tags G tag-id' \
  'vehicle-event-payment-method P method-id'
do
  set -- $pair
  report="$(scoped_rows "$1" "$2" "$3" "$BARE_EDIT_DA" "$FIX_VEHICLE")"
  grep -q "%$3" <<<"$report" \
    && fail "fixture 90 the bare event already carried a $1 row: $report"
done
eyre_post edit-event \
  "$(edit_payload note "$BARE_EDIT_AT" "$BARE_EDIT_AT" "$BARE_EDIT_TOTAL" \
    "$BARE_EDIT_ODO" "$STATION" "[\"$TAG\"]" "$PAYMENT" "$BARE_EDIT_NOTE" '[]' "$FIX_VEHICLE")" \
  $'Corrected note event - $62.50\n200' 'fixture 90 the adding correction'
[ "$(event_id_at "$BARE_EDIT_DA" "$FIX_VEHICLE")" = "$bare_id_before" ] \
  || fail "fixture 90 adding associations re-keyed the event"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$BARE_EDIT_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 62500 ] \
  || fail "fixture 90 the added total is not 62,500 mills: $report"
for pair in 'vehicle-event-costs C' 'vehicle-event-cost-totals T' \
  'vehicle-event-odometers L' 'vehicle-event-stations S' \
  'vehicle-event-tags G' 'vehicle-event-payment-method P'
do
  set -- $pair
  report="$(scoped_rows "$1" "$2" event-id "$BARE_EDIT_DA" "$FIX_VEHICLE")"
  linked="$(grep -oE '%event-id [0-9]+ [0-9a-fx.]+' <<<"$report" | head -1)"
  [ "$linked" = "$bare_id_before" ] \
    || fail "fixture 90 the added $1 row does not target the event: $linked"
done
# The added reading joins the vehicle's one odometer list, the way a created
# one does. It is not a second stream.
report="$(rover_report "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = '$FIX_VEHICLE' SELECT O.value-digits;")"
grep -qE "%value-digits [0-9]+ ($BARE_EDIT_ODO|0x$(printf '%x' "$BARE_EDIT_ODO"))" <<<"$report" \
  || fail "fixture 90 the added reading is not in the vehicle odometer stream: $report"
view="$(eyre_view)"
card="$(event_card note "$BARE_EDIT_NOTE")"
grep -qF 'data-event-total="$62.50"' <<<"$card" \
  || fail "fixture 90 the card does not render the added total: $card"
grep -qF "data-event-station=\"$STATION\"" <<<"$card" \
  || fail "fixture 90 the card does not render the added station: $card"
grep -qF "data-event-tag=\"$TAG\"" <<<"$card" \
  || fail "fixture 90 the card does not render the added tag: $card"
note "fixture 90 PASS - a total, an odometer, a station, a tag, and a payment method are added by correction, all keyed to the same parent"

# ---------------------------------------------------------------------------
# fixture 91 - a corrected cost flows through to the derived figures. T11
# statistics has merged on this branch, so the assertion is on the exact
# ownership total, which is arithmetic a reader can check by hand.
# ---------------------------------------------------------------------------
eyre_post add-vehicle \
  "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[]}' "$STAT_FIX_VEHICLE")" \
  "$(printf 'Added vehicle - %s\n201' "$STAT_FIX_VEHICLE")" 'fixture 91 the statistics vehicle'
eyre_post add-acquisition-event \
  "$(ownership_payload "$STAT_FIX_VEHICLE" '2026-03-01T09:00' '$10,000.00' '1000' '' "Correction purchase $STAMP")" \
  $'Saved acquisition event - $10,000.00\n201' 'fixture 91 the purchase'
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"2026-03-10T09:00","zone":"America/Chicago","total":"$200.00","currency":"usd","mileage":"1500","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"Correction service %s","subtypes":[]}' \
    "$STAT_FIX_VEHICLE" "$STAMP")" \
  $'Saved service event - $200.00\n201' 'fixture 91 the service to correct'
stat_view="$(scoped_event_view "$STAT_FIX_VEHICLE")"
grep -q 'data-total-cost-mills="10200000"' <<<"$stat_view" \
  || fail "fixture 91 the pre-correction ownership total is not 10,200,000 mills"
grep -q 'data-cost-family="service" data-family-total-mills="200000"' <<<"$stat_view" \
  || fail "fixture 91 the pre-correction service spend is not 200,000 mills"
eyre_post edit-event \
  "$(edit_payload service '2026-03-10T09:00' '2026-03-10T09:00' '$450.00' 1500 \
    none '[]' '' "Correction service $STAMP" '[]' "$STAT_FIX_VEHICLE")" \
  $'Corrected service event - $450.00\n200' 'fixture 91 the cost correction'
stat_view="$(scoped_event_view "$STAT_FIX_VEHICLE")"
grep -q 'data-total-cost-mills="10450000"' <<<"$stat_view" \
  || fail "fixture 91 the corrected cost did not reach the ownership total"
grep -q 'data-cost-family="service" data-family-total-mills="450000"' <<<"$stat_view" \
  || fail "fixture 91 the corrected cost did not reach the spend-by-family row"
grep -q 'data-family-total-mills="200000"' <<<"$stat_view" \
  && fail "fixture 91 the pre-correction figure is still reported"
note "fixture 91 PASS - a corrected cost moves the exact ownership total and the spend-by-family row, and the old figure is gone"

# ---------------------------------------------------------------------------
# fixture 92 - correcting an event does not disturb a sibling event on the
# same vehicle.
# ---------------------------------------------------------------------------
eyre_post add-service-event \
  "$(fix_payload "$SIB_AT" "$SIB_TOTAL" "$SIB_ODO" none '[]' '' "$SIB_NOTE" '["Windshield Wipers"]')" \
  $'Saved service event - $41.00\n201' 'fixture 92 the sibling'
sib_id_before="$(event_id_at "$SIB_DA" "$FIX_VEHICLE")"
[ -n "$sib_id_before" ] || fail "fixture 92 the sibling was not stored"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$SIB_DA" "$FIX_VEHICLE")"
sib_total_before="$(cell_number "$report" total-mills)"
[ "$sib_total_before" = 41000 ] \
  || fail "fixture 92 the sibling total is not 41,000 mills: $report"
eyre_post edit-event \
  "$(edit_payload service "$FIX_AT" "$FIX_AT" '$399.99' "$FIX_ODO" \
    "$STATION" '[]' '' "$FIX_NOTE" '["Engine Oil"]' "$FIX_VEHICLE")" \
  $'Corrected service event - $399.99\n200' 'fixture 92 the neighbouring correction'
[ "$(event_id_at "$SIB_DA" "$FIX_VEHICLE")" = "$sib_id_before" ] \
  || fail "fixture 92 correcting the neighbour re-keyed the sibling"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$SIB_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 41000 ] \
  || fail "fixture 92 correcting the neighbour changed the sibling total: $report"
report="$(scoped_rows vehicle-event-service-subtypes B service-subtype-id "$SIB_DA" "$FIX_VEHICLE")"
[ "$(count_rows "$report" '%service-subtype-id')" = 1 ] \
  || fail "fixture 92 correcting the neighbour changed the sibling subtypes: $report"
report="$(scoped_rows vehicle-event-odometers L odometer-id "$SIB_DA" "$FIX_VEHICLE")"
[ "$(count_rows "$report" '%odometer-id')" = 1 ] \
  || fail "fixture 92 correcting the neighbour changed the sibling odometer link: $report"
view="$(eyre_view)"
card="$(event_card service "$SIB_NOTE")"
grep -qF 'data-event-total="$41.00"' <<<"$card" \
  || fail "fixture 92 the sibling card no longer renders its own total: $card"
note "fixture 92 PASS - a correction on one event leaves a sibling event on the same vehicle untouched"

# ---------------------------------------------------------------------------
# fixture 93 - a kind change is refused with a human reason. The kind is which
# typed child exists, so changing it would move the row between relations and
# break every link into it.
# ---------------------------------------------------------------------------
kind_change="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(edit_payload expense "$FIX_AT" "$FIX_AT" '$399.99' "$FIX_ODO" \
    "$STATION" '[]' '' "$FIX_NOTE" '[]' "$FIX_VEHICLE")" \
  "$URL/apps/rover/edit-event")"
grep -q '422$' <<<"$kind_change" \
  || fail "fixture 93 a kind change was not refused: $kind_change"
grep -q 'wrong-kind' <<<"$kind_change" \
  || fail "fixture 93 the refusal does not name the failure class: $kind_change"
grep -q 'an event keeps the kind it was recorded under' <<<"$kind_change" \
  || fail "fixture 93 the refusal carries no human reason: $kind_change"
# The refusal wrote nothing. The event is still a service event, it has no
# expense child, and its subtype links are the ones it had.
report="$(scoped_rows service-events C event-id "$FIX_DA" "$FIX_VEHICLE")"
[ "$(count_rows "$report" '%event-id')" = 1 ] \
  || fail "fixture 93 the refused request removed the service child: $report"
report="$(scoped_rows expense-events C event-id "$FIX_DA" "$FIX_VEHICLE")"
grep -q '%event-id' <<<"$report" \
  && fail "fixture 93 the refused request created an expense child: $report"
report="$(scoped_rows vehicle-event-service-subtypes B service-subtype-id "$FIX_DA" "$FIX_VEHICLE")"
[ "$(count_rows "$report" '%service-subtype-id')" = 1 ] \
  || fail "fixture 93 the refused request changed the subtype links: $report"
[ "$(event_id_at "$FIX_DA" "$FIX_VEHICLE")" = "$fix_id_before" ] \
  || fail "fixture 93 the refused request re-keyed the event"
note "fixture 93 PASS - a kind change is refused with a human reason and writes nothing"

# ---------------------------------------------------------------------------
# fixture 95 - a person corrects an event in a real browser at 390px. They
# open the card, press Edit, find their own entry in the form, change a value,
# save, and see one corrected card. An endpoint with no browser control is the
# same defect Gate 7 found wearing the other hat.
# ---------------------------------------------------------------------------
eyre_post add-service-event \
  "$(fix_payload "$BROWSER_FIX_AT" "$BROWSER_FIX_TOTAL" "$BROWSER_FIX_ODO" \
    "$STATION" "[\"$TAG\"]" "$PAYMENT" "$BROWSER_FIX_NOTE" '["Engine Oil"]')" \
  $'Saved service event - $120.00\n201' 'fixture 95 the event the browser corrects'
browser_fix_id="$(event_id_at "$BROWSER_FIX_DA" "$FIX_VEHICLE")"
[ -n "$browser_fix_id" ] || fail "fixture 95 the browser event was not stored"
playwright_module="${ROVER_PLAYWRIGHT_MODULE:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules/playwright}"
chromium_binary="${ROVER_CHROMIUM:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
[ -f "$playwright_module/package.json" ] \
  || fail "fixture 95 Playwright is unavailable at $playwright_module"
[ -x "$chromium_binary" ] \
  || fail "fixture 95 Chromium is unavailable at $chromium_binary"
auth_cookie_name="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $6; exit}' "$JAR")"
auth_cookie="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $7; exit}' "$JAR")"
[ -n "$auth_cookie" ] || fail "fixture 95 has no urbauth cookie to hand the browser"
correction_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/correction-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$FIX_VEHICLE" \
      "$BROWSER_FIX_NOTE" "$BROWSER_FIX_FIXED" "$TAG"
} 2>&1)" || fail "fixture 95 the browser could not correct an event: $correction_out"
# The form opened pre-filled with the person's own entry.
for want in \
  "FORM_VEHICLE=$FIX_VEHICLE" \
  'FORM_KIND=service' \
  "FORM_TOTAL=$BROWSER_FIX_TOTAL" \
  "FORM_NOTES=$BROWSER_FIX_NOTE" \
  "FORM_MILEAGE=$BROWSER_FIX_ODO" \
  "FORM_ORIGINAL=$BROWSER_FIX_AT" \
  "FORM_TAGS=$TAG" \
  'FORM_SUBMIT=Save correction'
do
  grep -qF "$want" <<<"$correction_out" \
    || fail "fixture 95 the pre-filled form lacks $want: $correction_out"
done
# The control and the form fit the phone they are used on.
grep -q 'EDIT_VISIBLE=yes' <<<"$correction_out" \
  || fail "fixture 95 the edit control is not visible at 390px: $correction_out"
edit_right="$(sed -n 's/^EDIT_RIGHT_EDGE=//p' <<<"$correction_out")"
[ -n "$edit_right" ] && [ "$edit_right" -le 390 ] \
  || fail "fixture 95 the edit control ends at ${edit_right}px, past 390: $correction_out"
form_overflow="$(sed -n 's/^FORM_OVERFLOW=//p' <<<"$correction_out")"
[ -n "$form_overflow" ] && [ "$form_overflow" -le 0 ] \
  || fail "fixture 95 the correction form overflows 390px by ${form_overflow}px"
# The correction landed, and it made one card rather than two.
grep -qF "EDIT_VERDICT=Corrected service event - $BROWSER_FIX_FIXED" <<<"$correction_out" \
  || fail "fixture 95 the correction verdict is wrong: $correction_out"
grep -q 'EDIT_CARDS=1' <<<"$correction_out" \
  || fail "fixture 95 the correction rendered more than one card: $correction_out"
grep -qF "EDIT_CARD_TOTAL=$BROWSER_FIX_FIXED" <<<"$correction_out" \
  || fail "fixture 95 the card does not show the corrected total: $correction_out"
grep -q 'EDIT_CARD_TAGS=$' <<<"$correction_out" \
  || fail "fixture 95 the tag the person unchecked is still on the card: $correction_out"
# Leaving the correction empties the form. A correction target must not
# outlive the screen a person left.
grep -q 'RESET_ORIGINAL=$' <<<"$correction_out" \
  || fail "fixture 95 the reopened form still names a correction target: $correction_out"
grep -q 'RESET_SUBMIT=Save event' <<<"$correction_out" \
  || fail "fixture 95 the reopened form still reads as a correction: $correction_out"
# The browser wrote what the endpoint battery writes, in the same rows.
[ "$(event_id_at "$BROWSER_FIX_DA" "$FIX_VEHICLE")" = "$browser_fix_id" ] \
  || fail "fixture 95 the browser correction re-keyed the event"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$BROWSER_FIX_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 137450 ] \
  || fail "fixture 95 the browser correction did not store 137,450 mills: $report"
report="$(scoped_rows vehicle-event-tags G tag-id "$BROWSER_FIX_DA" "$FIX_VEHICLE")"
grep -q '%tag-id' <<<"$report" \
  && fail "fixture 95 the unchecked tag left a row behind: $report"
note "fixture 95 PASS - a person corrects an event from the card in a real browser at 390px, sees one corrected card, and the form empties behind them"


# ---------------------------------------------------------------------------
# M8 - attachments. The blobs never enter Obelisk. The database holds a
# reference; the bytes live in Clay or in an S3 bucket, and the ship proxies
# them both ways.
# ---------------------------------------------------------------------------
urlenc() { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""))' "$1"; }

# Attach one file through the product endpoint a browser calls.
#   attach_file <owner> <vehicle> <observed> <file> <media-type> <path> <backend>
attach_file() {
  local owner="$1" vehicle="$2" observed="$3" file="$4" type="$5" src="$6" backend="${7:-clay}"
  local query
  query="owner=$owner&vehicle=$(urlenc "$vehicle")&file=$(urlenc "$file")&type=$(urlenc "$type")&backend=$backend"
  [ -n "$observed" ] && query="$query&observed=$(urlenc "$observed")"
  curl -sS -b "$JAR" -w $'\n%{http_code}' -H "content-type: $type" \
    --data-binary "@$src" "$URL/apps/rover/add-attachment?$query"
}

fetch_file() {
  local file="$1" target="$2"
  curl -sS -b "$JAR" -o "$target" -w '%{http_code}' \
    "$URL/apps/rover/attachment/$(urlenc "$file")"
}

digest() { sha256sum "$1" | awk '{print $1}'; }

# Which backend a reference names.
#
# The pinned engine renders a term that carries a digit as a bare number
# instead of as `%s3`, so the row reads `%backend %tas 13171`. 13171 is the
# cord `s3`: 's' is 0x73 in the low byte and '3' is 0x33 above it. The value
# stored is right and only its printing is not, so both forms are read here.
backend_named() {
  local report="$1" want="$2"
  case "$want" in
    (s3) grep -qE '%backend %tas (%s3|13171)' <<<"$report" ;;
    (*) grep -q "%backend %tas %$want" <<<"$report" ;;
  esac
}

# The fill this run's vehicle already carries, from fixture 3. An attachment
# hangs off a record that already exists; it does not need a record of its own.
M8_FILL_AT='2026-07-20T12:00'
M8_TRANSPORT="${ROVER_TEST_TMP}/rover-m8-transport-$STAMP.bin"
M8_TRANSPORT_BACK="${ROVER_TEST_TMP}/rover-m8-transport-back-$STAMP.bin"
M8_PHOTO="${ROVER_TEST_TMP}/rover-m8-photo-$STAMP.jpg"
M8_PHOTO_BACK="${ROVER_TEST_TMP}/rover-m8-photo-back-$STAMP.jpg"

# ---------------------------------------------------------------------------
# fixture 96 - outbound transport, measured before anything is built on it.
#
# Inbound was already proven at 64 MB. Nobody had served a corpus-sized
# response OUT of Gall through Eyre in one piece, and the whole export design
# rests on whether that works. So this fixture runs first and it uses the real
# product path: a photo goes in through the attach endpoint and comes back out
# through the serve endpoint, at the size the owner's real corpus reaches.
#
# If this fails, chunked download is the fallback and the tar format does not
# change.
# ---------------------------------------------------------------------------
python3 - "$M8_TRANSPORT" <<'TRANSPORT'
import sys
target = 50 * 1024 * 1024
chunk = bytes(range(256))
data = bytearray(b"\xff\xd8\xff\xe1")
while len(data) < target:
    data += chunk
open(sys.argv[1], "wb").write(bytes(data[:target]))
TRANSPORT
M8_TRANSPORT_BYTES="$(wc -c < "$M8_TRANSPORT")"
[ "$M8_TRANSPORT_BYTES" -ge 49000000 ] \
  || fail "fixture 96 the transport payload is smaller than the real corpus"
M8_TRANSPORT_HASH="$(digest "$M8_TRANSPORT")"
attach_response="$(attach_file vehicle "$VEHICLE" '' "transport-$STAMP.bin" 'image/jpeg' "$M8_TRANSPORT" clay)"
case "$attach_response" in
  (*$'\n'201) ;;
  (*) fail "fixture 96 the ship would not accept a corpus-sized upload: $attach_response";;
esac
transport_status="$(fetch_file "transport-$STAMP.bin" "$M8_TRANSPORT_BACK")"
[ "$transport_status" = 200 ] \
  || fail "fixture 96 the corpus-sized response did not serve: HTTP $transport_status"
transport_back_bytes="$(wc -c < "$M8_TRANSPORT_BACK")"
[ "$transport_back_bytes" = "$M8_TRANSPORT_BYTES" ] \
  || fail "fixture 96 sent $M8_TRANSPORT_BYTES bytes and received $transport_back_bytes"
[ "$(digest "$M8_TRANSPORT_BACK")" = "$M8_TRANSPORT_HASH" ] \
  || fail "fixture 96 the received bytes hash differently from the sent bytes"
note "fixture 96 outbound - $transport_back_bytes bytes, sha256 $M8_TRANSPORT_HASH"
note "fixture 96 PASS - a corpus-sized response leaves Gall through Eyre in one piece, with the received byte count and hash equal to what was sent"
rm -f "$M8_TRANSPORT" "$M8_TRANSPORT_BACK"

# ---------------------------------------------------------------------------
# fixture 97 - a photo attaches to a fill, and the stored bytes hash EQUAL to
# the source bytes. EXIF intact, no re-encode. The photo carries a real APP1
# marker with a GPS-shaped payload, so a silent strip or re-encode changes the
# digest and fails here.
# ---------------------------------------------------------------------------
python3 - "$M8_PHOTO" <<'PHOTO'
import sys
# A minimal JPEG carrying an APP1/Exif segment. Nothing here is decoded by
# Rover - the point is that these exact bytes come back.
exif = b"Exif\x00\x00MM\x00\x2a\x00\x00\x00\x08\x00\x01\x87\x69\x00\x04\x00\x00\x00\x01\x00\x00\x00\x1a"
app1 = b"\xff\xe1" + (len(exif) + 2).to_bytes(2, "big") + exif
body = bytes(range(256)) * 64
open(sys.argv[1], "wb").write(b"\xff\xd8" + app1 + b"\xff\xdb" + body + b"\xff\xd9")
PHOTO
M8_PHOTO_HASH="$(digest "$M8_PHOTO")"
M8_PHOTO_BYTES="$(wc -c < "$M8_PHOTO")"
fill_photo="fill-receipt-$STAMP.jpg"
attach_response="$(attach_file fill "$VEHICLE" "$M8_FILL_AT" "$fill_photo" 'image/jpeg' "$M8_PHOTO" clay)"
case "$attach_response" in
  (*$'\n'201) ;;
  (*) fail "fixture 97 the fill would not take a photo: $attach_response";;
esac
[ "$(fetch_file "$fill_photo" "$M8_PHOTO_BACK")" = 200 ] \
  || fail "fixture 97 the fill photo did not serve back"
[ "$(digest "$M8_PHOTO_BACK")" = "$M8_PHOTO_HASH" ] \
  || fail "fixture 97 the stored bytes do not hash equal to the source bytes"
cmp -s "$M8_PHOTO" "$M8_PHOTO_BACK" \
  || fail "fixture 97 the served photo is not byte-for-byte the source photo"
grep -aq 'Exif' "$M8_PHOTO_BACK" \
  || fail "fixture 97 the APP1 Exif segment did not survive storage"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$fill_photo' SELECT T.attachment-id, T.content-hash, T.byte-count;")"
grep -q "%content-hash 116 %$M8_PHOTO_HASH" <<<"$report" \
  || grep -q "%content-hash 116 '$M8_PHOTO_HASH'" <<<"$report" \
  || fail "fixture 97 the reference does not carry the source digest: $report"
grep -q "%byte-count 25717 $M8_PHOTO_BYTES" <<<"$report" \
  || fail "fixture 97 the reference does not carry the source byte count: $report"
# The link keys to the energy family PARENT, never to the fuel-fills child.
report="$(rover_report "FROM energy-acquisition-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$fill_photo' SELECT L.acquisition-id, L.attachment-id;")"
grep -q '%acquisition-id' <<<"$report" \
  || fail "fixture 97 no link row keyed to the energy acquisition: $report"
note "fixture 97 PASS - a photo attaches to a fill through the product endpoint, the stored bytes hash equal to the source bytes, and the link keys to the family parent"

# ---------------------------------------------------------------------------
# fixture 98 - the same photo path to an event and to a vehicle. Three owners,
# one reference relation, each link keyed to its family parent.
# ---------------------------------------------------------------------------
event_photo="event-receipt-$STAMP.jpg"
vehicle_photo="vehicle-plate-$STAMP.jpg"
attach_response="$(attach_file event "$VEHICLE" "$SERVICE_AT" "$event_photo" 'image/jpeg' "$M8_PHOTO" clay)"
case "$attach_response" in
  (*$'\n'201) ;;
  (*) fail "fixture 98 the service event would not take a photo: $attach_response";;
esac
attach_response="$(attach_file vehicle "$VEHICLE" '' "$vehicle_photo" 'image/jpeg' "$M8_PHOTO" clay)"
case "$attach_response" in
  (*$'\n'201) ;;
  (*) fail "fixture 98 the vehicle would not take a photo: $attach_response";;
esac
report="$(rover_report "FROM vehicle-event-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$event_photo' SELECT L.event-id, L.attachment-id;")"
grep -q '%event-id' <<<"$report" \
  || fail "fixture 98 no link row keyed to the vehicle event: $report"
report="$(rover_report "FROM vehicle-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$vehicle_photo' SELECT L.vehicle-id, L.attachment-id;")"
grep -q '%vehicle-id' <<<"$report" \
  || fail "fixture 98 no link row keyed to the vehicle: $report"
for name in "$event_photo" "$vehicle_photo"; do
  [ "$(fetch_file "$name" "$M8_PHOTO_BACK")" = 200 ] \
    || fail "fixture 98 $name did not serve back"
  [ "$(digest "$M8_PHOTO_BACK")" = "$M8_PHOTO_HASH" ] \
    || fail "fixture 98 $name did not hash equal to the source bytes"
done
# One relation, three owners: all three references live in `attachments`.
report="$(rover_report "FROM attachments T WHERE T.file-name = '$event_photo' SELECT T.attachment-id;")"
grep -q '%attachment-id' <<<"$report" \
  || fail "fixture 98 the event photo is not in the one reference relation"
# A record that does not exist is refused in human words, not with a raw error.
missing="$(attach_file event "$VEHICLE" '2001-01-01T00:00' "ghost-$STAMP.jpg" 'image/jpeg' "$M8_PHOTO" clay)"
case "$missing" in
  (*$'\n'404) ;;
  (*) fail "fixture 98 a photo attached to a record that does not exist: $missing";;
esac
grep -q 'No record on that vehicle at that moment' <<<"$missing" \
  || fail "fixture 98 the refusal is not in human words: $missing"
note "fixture 98 PASS - a photo attaches to an event and to a vehicle, three owners share one reference relation, and each link keys to its family parent"

# ---------------------------------------------------------------------------
# fixture 99 - the Clay backend end to end on a real pier. The bytes are in
# Clay, at the path the reference names, and they are the source bytes.
# ---------------------------------------------------------------------------
report="$(rover_report "FROM attachments T WHERE T.file-name = '$fill_photo' SELECT T.attachment-id, T.backend, T.locator;")"
backend_named "$report" clay \
  || fail "fixture 99 the reference does not name the Clay backend: $report"
# The probe reads the LOCATOR column rather than rebuilding a path from the
# id. That is what the column is for, and it is also the only correct source:
# Obelisk renders a @ux with no dot separators, so an id read back and pasted
# into a Hoon path is not a Hoon path at all.
clay_locator="$(grep -oE "%locator 116 '[^']*'" <<<"$report" | head -1 | sed "s/^.*'\(.*\)'\$/\1/")"
[ -n "$clay_locator" ] || fail "fixture 99 could not read the locator: $report"
clay_probe="$(click_file "=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
=/  pax  (weld /(scot %p our.bowl)/rover-files/(scot %da now.bowl) (stab '$clay_locator'))
=/  got  .^(mime %cx pax)
(pure:m !>([p.q.got (scot %ux (rev 3 32 (shay p.q.got q.q.got)))]))")"
grep -q " $M8_PHOTO_BYTES " <<<"$clay_probe" \
  || fail "fixture 99 Clay does not hold $M8_PHOTO_BYTES bytes at the reference path: $clay_probe"
clay_raw="$(grep -oE "'0x[0-9a-f.]+'" <<<"$clay_probe" | head -1 | tr -d "'")"
[ -n "$clay_raw" ] || fail "fixture 99 the Clay probe returned no digest: $clay_probe"
# `scot %ux` drops leading zeros and groups in fours, so the digest is
# normalised before it is compared with the one `sha256sum` printed.
clay_hash="$(python3 -c 'import sys;print(sys.argv[1][2:].replace(".","").rjust(64,"0"))' "$clay_raw")"
[ "$clay_hash" = "$M8_PHOTO_HASH" ] \
  || fail "fixture 99 the bytes in Clay hash to $clay_hash, not $M8_PHOTO_HASH"
# The attachments are NOT on the published %rover desk.
rover_desk_probe="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
=/  arch  .^(arch %cy /(scot %p our.bowl)/rover/(scot %da now.bowl)/attachments)
(pure:m !>(?=(~ fil.arch)))')"
grep -q '%noun 0' <<<"$rover_desk_probe" \
  || fail "fixture 99 an attachment reached the published %rover desk: $rover_desk_probe"
note "fixture 99 PASS - the Clay backend stores and serves a photo end to end on a real pier, and nothing lands on the published desk"

# ---------------------------------------------------------------------------
# fixture 105 - no blob reaches Obelisk. Proved by READING the relations, not
# by reading the code: every column of every attachment relation is checked
# against the size of the photo it refers to.
# ---------------------------------------------------------------------------
blob_probe="$(rover_report 'FROM attachments T SELECT T.attachment-id, T.backend, T.locator, T.content-hash, T.byte-count, T.media-type, T.file-name;')"
blob_size="$(printf '%s' "$blob_probe" | wc -c)"
[ "$blob_size" -lt 200000 ] \
  || fail "fixture 105 the attachments relation reads back $blob_size bytes, which is blob-sized"
grep -q "$(head -c 32 "$M8_PHOTO" | od -An -tx1 | tr -d ' \n')" <<<"$blob_probe" \
  && fail "fixture 105 photo bytes appear inside the attachments relation"
# Every column, by name, across all four relations. A blob could only hide in
# a text or binary column, and this reads all of them.
for relation in attachments energy-acquisition-attachments vehicle-event-attachments vehicle-attachments; do
  case "$relation" in
    attachments) projection='T.attachment-id, T.backend, T.locator, T.content-hash, T.byte-count, T.media-type, T.file-name';;
    energy-acquisition-attachments) projection='T.acquisition-id, T.attachment-id';;
    vehicle-event-attachments) projection='T.event-id, T.attachment-id';;
    vehicle-attachments) projection='T.vehicle-id, T.attachment-id';;
  esac
  report="$(rover_report "FROM $relation T SELECT $projection;")"
  widest="$(printf '%s' "$report" | grep -oE "'[^']*'" | awk '{ print length($0) }' | sort -rn | head -1)"
  [ -z "$widest" ] || [ "$widest" -lt 4096 ] \
    || fail "fixture 105 $relation holds a $widest-character value, which is not a reference"
done
# And the whole database is smaller than one photo's worth of blob columns.
note "fixture 105 PASS - no blob reaches Obelisk, proved by reading every column of all four attachment relations"

# ---------------------------------------------------------------------------
# fixture 100 - the S3 backend end to end against a REAL S3-compatible
# endpoint. Not a mock. The standing rule on configuration is that both
# backends are real and tested or neither ships, so this fixture needs a
# server and says so plainly when it cannot find one.
#
#   podman run -d --name rover-m8-rustfs -p 9200:9000 \
#     -e RUSTFS_ACCESS_KEY=roverm8key -e RUSTFS_SECRET_KEY=roverm8secret123 \
#     docker.io/rustfs/rustfs:latest
#
# The bucket `rover-attachments` must exist, and %storage on the pier must
# point at the endpoint with those credentials.
# ---------------------------------------------------------------------------
S3_ENDPOINT="${ROVER_S3_ENDPOINT:-http://localhost:9200}"
curl -sS -o /dev/null --max-time 5 "$S3_ENDPOINT/" 2>/dev/null
s3_reachable=$?
[ "$s3_reachable" = 0 ] \
  || fail "fixture 100 no S3-compatible endpoint answered at $S3_ENDPOINT - start one and create the rover-attachments bucket; a mocked backend does not count"
storage_configured() {
  click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
=/  c  .^(* %gx /(scot %p our.bowl)/storage/(scot %da now.bowl)/credentials/noun)
=/  f  .^(* %gx /(scot %p our.bowl)/storage/(scot %da now.bowl)/configuration/noun)
(pure:m !>([-.+.c -.+.+.f]))'
}
grep -q "''" <<<"$(storage_configured)" \
  && fail "fixture 100 %storage carries no endpoint or bucket on this pier - point it at $S3_ENDPOINT before running the battery"
s3_photo="s3-receipt-$STAMP.jpg"
presign_query="owner=fill&vehicle=$(urlenc "$VEHICLE")&observed=$(urlenc "$M8_FILL_AT")&file=$(urlenc "$s3_photo")&type=image%2Fjpeg&backend=s3&hash=$M8_PHOTO_HASH&bytes=$M8_PHOTO_BYTES"
presign_json="$ROVER_TEST_TMP/presign-$STAMP.json"
presign_code="$(curl -sS -b "$JAR" -X POST -o "$presign_json" -w '%{http_code}' \
  "$URL/apps/rover/attachment-url?$presign_query")"
[ "$presign_code" = 200 ] \
  || fail "fixture 100 the ship did not issue a PUT URL: HTTP $presign_code"
presign_urls="$(python3 - "$presign_json" "$S3_ENDPOINT" "$M8_PHOTO_HASH" <<'PRESIGN'
import json, sys, urllib.parse
data = json.load(open(sys.argv[1]))
put_url, get_url = data['putUrl'], data['getUrl']
put = urllib.parse.urlsplit(put_url)
query = urllib.parse.parse_qs(put.query, strict_parsing=True)
assert put.path == '/rover-attachments/attachments/' + sys.argv[3], 'The key is not the content hash'
assert query['X-Amz-Algorithm'] == ['AWS4-HMAC-SHA256']
assert query['X-Amz-Expires'] == ['300']
assert query['X-Amz-SignedHeaders'] == ['host']
assert len(query['X-Amz-Signature'][0]) == 64
assert 'roverm8secret123' not in put_url, 'The secret reached the URL'
assert get_url == sys.argv[2].rstrip('/') + put.path, 'The GET URL is not the public object URL'
assert not urllib.parse.urlsplit(get_url).query, 'The GET URL carries a credential'
print(put_url)
print(get_url)
PRESIGN
)" || fail "fixture 100 the issued URLs do not meet the presign contract"
put_url="$(head -1 <<<"$presign_urls")"
get_url="$(tail -1 <<<"$presign_urls")"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$s3_photo' SELECT T.attachment-id;")"
grep -q '%attachment-id' <<<"$report" \
  && fail "fixture 100 issuing a URL recorded a reference before the PUT"
put_code="$(curl -sS -X PUT -H 'content-type: image/jpeg' --data-binary "@$M8_PHOTO" \
  -o "$ROVER_TEST_TMP/put-$STAMP.txt" -w '%{http_code}' "$put_url")"
[ "$put_code" = 200 ] || fail "fixture 100 the bucket refused the presigned PUT: HTTP $put_code"
attach_response="$(curl -sS -b "$JAR" -X POST -w $'\n%{http_code}' \
  "$URL/apps/rover/record-attachment?$presign_query")"
case "$attach_response" in
  (*$'\n'201) ;;
  (*) fail "fixture 100 the ship did not record the uploaded photo: $attach_response";;
esac
report="$(rover_report "FROM attachments T WHERE T.file-name = '$s3_photo' SELECT T.attachment-id, T.backend, T.locator, T.byte-count;")"
backend_named "$report" s3 \
  || fail "fixture 100 the reference does not name the S3 backend: $report"
grep -q "%byte-count 25717 $M8_PHOTO_BYTES" <<<"$report" \
  || fail "fixture 100 the reference does not carry the source byte count: $report"
# The public GET serves the bytes without a ship cookie or S3 signature.
public_status="$(curl -sS -o "$M8_PHOTO_BACK" -w '%{http_code}' "$get_url")"
[ "$public_status" = 200 ] || fail "fixture 100 the public GET answered HTTP $public_status"
cmp -s "$M8_PHOTO" "$M8_PHOTO_BACK" \
  || fail "fixture 100 the public object differs from the uploaded photo"
# The proxy remains available to clients that use it.
s3_headers="$(mktemp ${ROVER_TEST_TMP}/rover-m8-s3-headers.XXXXXX)"
s3_status="$(curl -sS -b "$JAR" -D "$s3_headers" -o "$M8_PHOTO_BACK" -w '%{http_code}' \
  "$URL/apps/rover/attachment/$(urlenc "$s3_photo")")"
[ "$s3_status" = 200 ] \
  || fail "fixture 100 the S3-backed photo did not serve back: HTTP $s3_status"
grep -qiE '^location:|X-Amz-Signature|X-Amz-Credential' "$s3_headers" \
  && fail "fixture 100 the ship handed the browser a redirect or a presigned URL"
rm -f "$s3_headers"
[ "$(digest "$M8_PHOTO_BACK")" = "$M8_PHOTO_HASH" ] \
  || fail "fixture 100 the S3 round trip did not return the source bytes"
# And the bytes really are in the bucket, read with a client that is not Rover.
s3_locator="$(grep -oE "%locator 116 '[^']*'" <<<"$report" | head -1 | sed "s/^.*'\(.*\)'$/\1/")"
[ -n "$s3_locator" ] || fail "fixture 100 the reference carries no locator: $report"
bucket_digest="$(python3 - "$S3_ENDPOINT" "$s3_locator" <<'BUCKET'
import sys, hashlib, boto3, botocore
endpoint, locator = sys.argv[1], sys.argv[2]
bucket, key = locator.lstrip("/").split("/", 1)
s3 = boto3.client("s3", endpoint_url=endpoint,
                  aws_access_key_id="roverm8key",
                  aws_secret_access_key="roverm8secret123",
                  region_name="us-east-1",
                  config=botocore.config.Config(s3={"addressing_style": "path"}))
body = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
print(hashlib.sha256(body).hexdigest(), len(body))
BUCKET
)" || fail "fixture 100 could not read the object back out of the bucket"
[ "$(awk '{print $1}' <<<"$bucket_digest")" = "$M8_PHOTO_HASH" ] \
  || fail "fixture 100 the object in the bucket does not hash equal to the source: $bucket_digest"
[ "$(awk '{print $2}' <<<"$bucket_digest")" = "$M8_PHOTO_BYTES" ] \
  || fail "fixture 100 the object in the bucket is not $M8_PHOTO_BYTES bytes: $bucket_digest"
note "fixture 100 bucket - $s3_locator holds $bucket_digest"
note "fixture 100 PASS - the ship signs, curl uploads to the real bucket, and Rover records a reference after HTTP 200"

# Fixture 117 reads the persisted locator, after the signed URL was consumed.
grep -qi 'X-Amz-Signature' <<<"$s3_locator" \
  && fail "fixture 117 the stored locator carries an expiring signature"
[ "$s3_locator" = "/rover-attachments/attachments/$M8_PHOTO_HASH" ] \
  || fail "fixture 117 the stored locator is not the content address"
note "fixture 117 PASS - the stored locator carries the content hash and no presigned credential"

# ---------------------------------------------------------------------------
# fixture 101 - a ship with no %storage configuration says so in human words
# and offers Clay. It does not fail with a raw error and it does not silently
# pick a backend for the owner.
#
# The configuration is removed and put back, so this proves the refusal on a
# ship that is otherwise identical to the one fixture 100 just used.
# ---------------------------------------------------------------------------
storage_poke() {
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %storage] %storage-action !>($1))
;<  ~  bind:m  (sleep ~s2)
(pure:m !>(~))" > /dev/null
}
S3_SAVED_KEY='roverm8key'
storage_poke "[%set-access-key-id '']"
s3_response="$(attach_file vehicle "$VEHICLE" '' "s3-refused-$STAMP.jpg" 'image/jpeg' "$M8_PHOTO" s3)"
storage_poke "[%set-access-key-id '$S3_SAVED_KEY']"
s3_code="$(tail -1 <<<"$s3_response")"
[ "$s3_code" = 409 ] \
  || fail "fixture 101 an unconfigured ship did not refuse the S3 request: $s3_response"
grep -q 'no S3 storage set up yet' <<<"$s3_response" \
  || fail "fixture 101 the refusal is not in human words: $s3_response"
grep -qi 'clay' <<<"$s3_response" \
  || fail "fixture 101 the refusal does not offer Clay: $s3_response"
grep -qE 'nest-fail|%bad-shape|%database-refused|\[%|0x[0-9a-f]{8}' <<<"$s3_response" \
  && fail "fixture 101 the refusal leaks a raw error or a machine id: $s3_response"
# Nothing was stored, and no backend was picked on the owner's behalf.
report="$(rover_report "FROM attachments T WHERE T.file-name = 's3-refused-$STAMP.jpg' SELECT T.attachment-id;")"
grep -q '%attachment-id' <<<"$report" \
  && fail "fixture 101 the refused request stored something anyway: $report"
# The same photo goes in when the owner takes the offer.
clay_offer="$(attach_file vehicle "$VEHICLE" '' "s3-refused-$STAMP.jpg" 'image/jpeg' "$M8_PHOTO" clay)"
case "$clay_offer" in
  (*$'\n'201) ;;
  (*) fail "fixture 101 Clay was offered but would not take the photo: $clay_offer";;
esac
note "fixture 101 PASS - a ship with no %storage configuration says so in human words, stores nothing, and the Clay it offers works"

# ---------------------------------------------------------------------------
# fixtures 107, 108, 109, 110 - the entry surface.
#
# Everything above this point moves the bytes with `curl`. These four prove a
# PERSON can move them: a file input on Add Fill and on Add Event, a photo on
# the card afterwards, a way to open it full size, and all of it at 390px.
#
# One browser run drives all four, because they are one journey. Splitting it
# into four browsers would prove four disconnected things and cost four
# logins.
#
# The photos are real PNG images with real pixels. The full-size view is
# checked by the decoded size the browser reports, so a broken link or a
# placeholder cannot pass as a photograph.
# ---------------------------------------------------------------------------
M8_BROWSER_FILL_PHOTO="${ROVER_TEST_TMP}/rover-m8-browser-fill-$STAMP.png"
M8_BROWSER_EVENT_PHOTO="${ROVER_TEST_TMP}/rover-m8-browser-event-$STAMP.png"
python3 - "$M8_BROWSER_FILL_PHOTO" "$M8_BROWSER_EVENT_PHOTO" <<'PNG'
import struct
import sys
import zlib


def png(path, red):
    width = height = 24
    raw = b"".join(
        b"\x00" + bytes([red, (row * 9) % 256, 40] * width) for row in range(height)
    )

    def chunk(tag, body):
        return (
            struct.pack(">I", len(body))
            + tag
            + body
            + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
        )

    open(path, "wb").write(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


png(sys.argv[1], 220)
png(sys.argv[2], 60)
PNG
# The entry surface gets a vehicle of its own. It writes two NEW records, and
# a record this run's other fixtures count must not arrive from a browser.
M8_BROWSER_VEHICLE="Photo Vehicle $STAMP"
own_add_vehicle "$M8_BROWSER_VEHICLE" Gasoline
M8_BROWSER_FILL_HASH="$(digest "$M8_BROWSER_FILL_PHOTO")"
M8_BROWSER_EVENT_HASH="$(digest "$M8_BROWSER_EVENT_PHOTO")"
M8_BROWSER_FILL_BYTES="$(wc -c < "$M8_BROWSER_FILL_PHOTO")"
M8_BROWSER_NOTE="Browser attachment $STAMP"
attachment_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/attachment-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$M8_BROWSER_VEHICLE" \
      "$M8_BROWSER_FILL_PHOTO" "$M8_BROWSER_EVENT_PHOTO" \
      "$M8_BROWSER_NOTE" clay
} 2>&1)" || fail "fixture 107 the browser could not drive the entry surface: $attachment_out"

# --- fixture 107 - a photo attaches to a fill FROM THE BROWSER --------------
grep -q '^FILL_VERDICT=Saved fill' <<<"$attachment_out" \
  || fail "fixture 107 the browser could not save the fill: $attachment_out"
grep -q '^FILL_VERDICT=.*Attached ' <<<"$attachment_out" \
  || fail "fixture 107 the fill form did not report the photo: $attachment_out"
m8_browser_fill_photo_name="$(sed -n 's/^FILL_CARD_PHOTO_NAME=//p' <<<"$attachment_out")"
[ -n "$m8_browser_fill_photo_name" ] \
  || fail "fixture 107 the browser named no stored photo: $attachment_out"
M8_BROWSER_FILL_BACK="${ROVER_TEST_TMP}/rover-m8-browser-fill-back-$STAMP.png"
[ "$(fetch_file "$m8_browser_fill_photo_name" "$M8_BROWSER_FILL_BACK")" = 200 ] \
  || fail "fixture 107 the photo the browser attached did not serve back"
[ "$(digest "$M8_BROWSER_FILL_BACK")" = "$M8_BROWSER_FILL_HASH" ] \
  || fail "fixture 107 the stored bytes do not hash equal to the source bytes"
cmp -s "$M8_BROWSER_FILL_PHOTO" "$M8_BROWSER_FILL_BACK" \
  || fail "fixture 107 the served photo is not byte for byte the file the person chose"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$m8_browser_fill_photo_name' SELECT T.attachment-id, T.byte-count, T.media-type;")"
grep -q "%byte-count 25717 $M8_BROWSER_FILL_BYTES" <<<"$report" \
  || fail "fixture 107 the reference does not carry the source byte count: $report"
grep -q "image/png" <<<"$report" \
  || fail "fixture 107 the reference does not carry the media type the browser sent: $report"
# The link keys to the energy family parent, exactly as the endpoint path does.
report="$(rover_report "FROM energy-acquisition-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$m8_browser_fill_photo_name' SELECT L.acquisition-id, L.attachment-id;")"
grep -q '%acquisition-id' <<<"$report" \
  || fail "fixture 107 the browser attachment has no link to the energy acquisition: $report"
note "fixture 107 browser - $(grep '^FILL_BACKENDS=' <<<"$attachment_out"), $(grep '^FILL_OBSERVED=' <<<"$attachment_out")"
note "fixture 107 PASS - a person attaches a photo to a fill from the browser through the file input on the existing Add Fill form, and the stored bytes hash equal to the source bytes"

# --- fixture 108 - the same for an event -----------------------------------
grep -q '^EVENT_VERDICT=Saved note event' <<<"$attachment_out" \
  || fail "fixture 108 the browser could not save the event: $attachment_out"
grep -q '^EVENT_VERDICT=.*Attached ' <<<"$attachment_out" \
  || fail "fixture 108 the event form did not report the photo: $attachment_out"
m8_browser_event_photo_name="$(sed -n 's/^EVENT_CARD_PHOTO_NAME=//p' <<<"$attachment_out")"
[ -n "$m8_browser_event_photo_name" ] \
  || fail "fixture 108 the browser named no stored event photo: $attachment_out"
M8_BROWSER_EVENT_BACK="${ROVER_TEST_TMP}/rover-m8-browser-event-back-$STAMP.png"
[ "$(fetch_file "$m8_browser_event_photo_name" "$M8_BROWSER_EVENT_BACK")" = 200 ] \
  || fail "fixture 108 the photo the browser attached to the event did not serve back"
[ "$(digest "$M8_BROWSER_EVENT_BACK")" = "$M8_BROWSER_EVENT_HASH" ] \
  || fail "fixture 108 the stored event photo does not hash equal to the source bytes"
cmp -s "$M8_BROWSER_EVENT_PHOTO" "$M8_BROWSER_EVENT_BACK" \
  || fail "fixture 108 the served event photo is not byte for byte the file the person chose"
[ "$M8_BROWSER_FILL_HASH" != "$M8_BROWSER_EVENT_HASH" ] \
  || fail "fixture 108 the two photos are the same bytes, so this proves nothing"
report="$(rover_report "FROM vehicle-event-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$m8_browser_event_photo_name' SELECT L.event-id, L.attachment-id;")"
grep -q '%event-id' <<<"$report" \
  || fail "fixture 108 the browser event attachment has no link to the event: $report"
note "fixture 108 PASS - a person attaches a photo to an event from the browser through the file input on the existing Add Event form, and the stored bytes hash equal to the source bytes"

# --- fixture 109 - the photo on the card, and no empty frame ---------------
m8_fill_card_photos="$(sed -n 's/^FILL_CARD_PHOTOS=//p' <<<"$attachment_out")"
m8_event_card_photos="$(sed -n 's/^EVENT_CARD_PHOTOS=//p' <<<"$attachment_out")"
[ "$m8_fill_card_photos" = 1 ] \
  || fail "fixture 109 the fill card shows $m8_fill_card_photos photos, want 1: $attachment_out"
[ "$m8_event_card_photos" = 1 ] \
  || fail "fixture 109 the event card shows $m8_event_card_photos photos, want 1: $attachment_out"
grep -qx "PHOTO_VIEW_NAME=$m8_browser_fill_photo_name" <<<"$attachment_out" \
  || fail "fixture 109 the full-size view names the wrong photo: $attachment_out"
grep -q "^PHOTO_VIEW_SRC=/apps/rover/attachment/" <<<"$attachment_out" \
  || fail "fixture 109 the full-size view does not read the photo off this ship: $attachment_out"
grep -qx 'PHOTO_VIEW_NATURAL=24x24' <<<"$attachment_out" \
  || fail "fixture 109 the browser did not decode the full-size photo: $attachment_out"
m8_rendered="$(sed -n 's/^PHOTO_VIEW_RENDERED=//p' <<<"$attachment_out")"
[ -n "$m8_rendered" ] && [ "$m8_rendered" -gt 0 ] \
  || fail "fixture 109 the full-size photo rendered no pixels: $attachment_out"
grep -qx 'PHOTO_VIEW_CLOSED=yes' <<<"$attachment_out" \
  || fail "fixture 109 the full-size view would not close: $attachment_out"
# A record with no photo shows NOTHING. Not an empty frame.
grep -qx 'EMPTY_PHOTO_STRIPS=0' <<<"$attachment_out" \
  || fail "fixture 109 a record with no photo rendered an empty frame: $attachment_out"
m8_bare_cards="$(sed -n 's/^CARDS_WITHOUT_PHOTOS=//p' <<<"$attachment_out")"
[ -n "$m8_bare_cards" ] && [ "$m8_bare_cards" -gt 0 ] \
  || fail "fixture 109 no card without a photo was on the screen, so absence proves nothing"
note "fixture 109 cards - fill $m8_fill_card_photos, event $m8_event_card_photos, $m8_bare_cards cards carrying no photo and no frame"
note "fixture 109 PASS - the photo appears on the record's card in History and opens full size, and a record with no photo shows no empty frame"

# --- fixture 110 - 390px ----------------------------------------------------
m8_page_overflow="$(sed -n 's/^PAGE_OVERFLOW=//p' <<<"$attachment_out")"
m8_field_overflow="$(sed -n 's/^FILL_FIELD_OVERFLOW=//p' <<<"$attachment_out")"
[ -n "$m8_page_overflow" ] && [ "$m8_page_overflow" -le 0 ] \
  || fail "fixture 110 the entry surface overflows 390px by ${m8_page_overflow}px: $attachment_out"
[ -n "$m8_field_overflow" ] && [ "$m8_field_overflow" -le 0 ] \
  || fail "fixture 110 the photo control overflows 390px by ${m8_field_overflow}px: $attachment_out"
[ "$m8_rendered" -le 390 ] \
  || fail "fixture 110 the full-size photo is ${m8_rendered}px wide, past 390"
note "fixture 110 PASS - the entry surface and the full-size photo view fit 390px, with no horizontal overflow"
rm -f "$M8_BROWSER_FILL_BACK" "$M8_BROWSER_EVENT_BACK"


# ---------------------------------------------------------------------------
# fixture 12 - everything above survives a ship restart
# ---------------------------------------------------------------------------
# Stop the pier, start it again, and log back in. Fixture 12 proves the event
# families survive one restart. Fixture 114 proves what M8 added survives a
# SECOND one, after the imports and the archive endpoints have run. One
# restart is one piece of code, so the two fixtures cannot drift apart.
#
# PORT and URL are deliberately global: the restarted pier may bind a
# different one, and every fixture after this reads them.
restart_pier() {
  local fx="$1"
# The pier may be the pane's own process or a child of it. Which one it is
# depends on how the session was started, and this fixture restarts the pier
# itself, so the second run of the battery can meet a different shape than the
# first. Both are searched, and the `urbit work` serf is skipped: it carries
# the pier path but not the boot arguments.
pier_session=""
pier_args=""
while read -r session pane_pid; do
  for candidate in "$pane_pid" $(pgrep -P "$pane_pid" 2>/dev/null); do
    args="$(tr '\0' ' ' < "/proc/$candidate/cmdline" 2>/dev/null)"
    case "$args" in
      *'urbit work'*) continue ;;
      *"$PIER"*) pier_session="$session"; pier_args="$args"; break ;;
    esac
  done
  [ -n "$pier_session" ] && break
done < <(tmux list-panes -a -F '#{session_name} #{pane_pid}')
[ -n "$pier_session" ] || fail "fixture $fx cannot find the tmux session running $PIER"
# The boot command is not the run command. `-B <pill>` and `-c` create a pier
# and fail against one that exists, so only the Ames port carries over. The
# port is explicit because a second pier's mesa layer binds port+1, and two
# neighbouring piers otherwise refuse to start.
ames_port="$(sed -n 's/.*-p \([0-9]\{1,\}\).*/\1/p' <<<"$pier_args")"
[ -n "$ames_port" ] || fail "fixture $fx cannot read the Ames port for $PIER: $pier_args"
# The binary comes from the running command, not from PATH. A pier booted with
# a full path runs under a tmux server whose PATH may hold no `urbit` at all,
# and a restart that cannot find the binary reports a dead pier instead. The
# first argument is NOT the binary: the pane runs `script -c <binary> ...`, so
# the match is on the argument that names urbit itself.
pier_binary="$(grep -oE '(^| )[^ ]*urbit( |$)' <<<"$pier_args" | head -1 | tr -d ' ')"
[ -n "$pier_binary" ] || fail "fixture $fx cannot read the urbit binary for $PIER: $pier_args"
case "$PIER" in
  ("$REPO"/.scratch/*) ;;
  (*) fail "fixture $fx only restarts a disposable pier inside $REPO/.scratch" ;;
esac
case "$(tr '\0' ' ' < "/proc/$candidate/cmdline" 2>/dev/null)" in
  (*"$PIER"*) ;;
  (*) fail "fixture $fx the pier process changed before the restart" ;;
esac
tmux send-keys -t "$pier_session" '|exit' Enter
for attempt in $(seq 1 60); do
  pgrep -f "snap-dir $PIER" >/dev/null || break
  sleep 1
done
pgrep -f "snap-dir $PIER" >/dev/null && fail "fixture $fx the pier did not stop"
tmux kill-session -t "$pier_session" 2>/dev/null
# The serf exits first and the king outlives it, holding the pier lock on its
# way out. Starting the next pier while the king still holds it makes the new
# one exit at once, and the restart then reports as a pier that never came
# back. The wait has to cover every urbit process on this pier, not only the
# serf. It grows with the database, which is why two runs on a populated pier
# find it and one run on a fresh pour does not.
#
# The match is scoped to `pgrep -x urbit` because a bare path match also
# matches this battery's own command line, which never exits.
pier_holders() {
  local pid args held=""
  for pid in $(pgrep -x urbit 2>/dev/null); do
    args="$(ps -o args= -p "$pid" 2>/dev/null)"
    case "$args" in
      *"$PIER"*) held="$held $pid" ;;
    esac
  done
  printf '%s' "${held# }"
}
for attempt in $(seq 1 120); do
  [ -z "$(pier_holders)" ] && break
  sleep 1
done
[ -z "$(pier_holders)" ] \
  || fail "fixture $fx urbit still holds $PIER: $(pier_holders)"
# script(1) gives the run a pty; without one vere refuses to start interactive.
tmux new-session -d -s "$pier_session" \
  "exec script -q -f -e -O /dev/null -c $(printf '%q' "$pier_binary -p $ames_port $PIER")"
ready=0
for attempt in $(seq 1 180); do
  PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports" 2>/dev/null)"
  if [ -n "$PORT" ] && curl -s -o /dev/null "http://localhost:$PORT/~/login"; then
    ready=1
    break
  fi
  sleep 1
done
# A pier that will not come back says why. Without the pane text the failure
# reads as "the pier did not restart" and the reason is gone with the session.
[ "$ready" = 1 ] \
  || fail "fixture $fx the pier did not restart: $(tmux capture-pane -pt "$pier_session" -S -40 2>&1 | tail -20)"
URL="http://localhost:$PORT"
eyre_login
}

restart_pier 12
view="$(eyre_view)"
card="$(event_card service "$SERVICE_NOTE")"
[ -n "$card" ] || fail "fixture 12 the service event did not survive the restart"
grep -qF "data-event-total=\"$SERVICE_TOTAL\"" <<<"$card" \
  || fail "fixture 12 the entered total did not survive the restart"
grep -qF "data-event-odometer=\"$odo_display mi\"" <<<"$card" \
  || fail "fixture 12 the odometer link did not survive the restart"
grep -qF "data-event-station=\"$STATION\"" <<<"$card" \
  || fail "fixture 12 the station link did not survive the restart"
[ -n "$(event_card expense "$EXPENSE_NOTE")" ] \
  || fail "fixture 12 the expense event did not survive the restart"
[ -n "$(event_card note "$NOTE_NOTE")" ] \
  || fail "fixture 12 the note event did not survive the restart"
report="$(rover_report "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = '$VEHICLE' SELECT O.value-digits;")"
grep -q "%value-digits 25717 $SERVICE_ODO" <<<"$report" \
  || fail "fixture 12 the service reading left the odometer list after restart"
report="$(scoped_rows vehicle-event-costs C cost-state "$NOTE_DA")"
grep -q '%cost-state' <<<"$report" \
  && fail "fixture 12 a cost row appeared for the note event after restart"
note "fixture 12 PASS - every event, total, odometer link, station link, and reading survived a ship restart"

# ---------------------------------------------------------------------------
# fixture 21 - the subtype catalog and every subtype link survive the restart
# ---------------------------------------------------------------------------
report="$(subtype_labels)"
restart_count="$(count_rows "$report" '%label')"
[ "$restart_count" = "$reseeded_count" ] \
  || fail "fixture 21 the catalog changed from $reseeded_count to $restart_count over the restart"
card="$(event_card service "$MULTI_NOTE")"
[ -n "$card" ] || fail "fixture 21 the ten-subtype event did not survive the restart"
grep -qF 'data-event-subtype-count="10"' <<<"$card" \
  || fail "fixture 21 the ten subtypes did not survive the restart: $card"
card="$(event_card service "$SINGLE_NOTE")"
grep -qF 'data-event-subtype-count="1"' <<<"$card" \
  || fail "fixture 21 the one-subtype event did not survive the restart: $card"
card="$(event_card service "$BARE_NOTE")"
[ -n "$card" ] || fail "fixture 21 the zero-subtype event did not survive the restart"
grep -q 'data-event-subtype-count=' <<<"$card" \
  && fail "fixture 21 a subtype line appeared on the zero-subtype event after restart: $card"
report="$(scoped_rows vehicle-event-service-subtypes L service-subtype-id "$BARE_DA")"
grep -q '%service-subtype-id' <<<"$report" \
  && fail "fixture 21 a link row appeared for the zero-subtype event after restart: $report"
note "fixture 21 PASS - the subtype catalog, the ten links, the one link, and the absent link all survived a ship restart"

# ---------------------------------------------------------------------------
# fixture 24 - the charge mileage link, Eyre rendering, and derived current
# odometer survive the same real ship restart.
# ---------------------------------------------------------------------------
report="$(rover_report "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN energy-acquisition-odometers L ON A.acquisition-id = L.acquisition-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE V.label = '$VEHICLE' AND A.observed-end = $CHARGE_DA SELECT A.acquisition-id, O.value-digits, O.decimal-places, O.unit;")"
grep -q "%value-digits 25717 $CHARGE_ODO" <<<"$report" \
  || fail "fixture 24 the charge odometer link did not survive the restart: $report"
grep -qF "data-charge-odometer=\"$charge_odo_display mi\"" <<<"$view" \
  || fail "fixture 24 the restarted Eyre view omits charge mileage"
grep -qF "CURRENT ODOMETER - DERIVED</span><strong>$charge_odo_display mi" <<<"$view" \
  || fail "fixture 24 the restarted current odometer does not derive from the charge"
note "fixture 24 PASS - charge mileage and the derived current odometer survive restart"

# ---------------------------------------------------------------------------
# fixture 34 - every T4 fact survives the same real ship restart: the two
# purchases, the sale, its kind, the trade-in pair, the odometer links, and
# the disposal-kind catalog.
# ---------------------------------------------------------------------------
report="$(disposal_kind_labels)"
restart_kinds="$(count_rows "$report" '%label')"
[ "$restart_kinds" = "$reseeded_kinds" ] \
  || fail "fixture 34 the disposal-kind pack changed from $reseeded_kinds to $restart_kinds over the restart"
card="$(event_card acquisition "$BUY_NOTE")"
[ -n "$card" ] || fail "fixture 34 the purchase did not survive the restart"
grep -qF "data-event-total=\"$BUY_TOTAL\"" <<<"$card" \
  || fail "fixture 34 the purchase total did not survive the restart"
grep -qF "data-event-odometer=\"$buy_odo_display mi\"" <<<"$card" \
  || fail "fixture 34 the purchase odometer link did not survive the restart"
card="$(event_card disposal "$SELL_NOTE")"
[ -n "$card" ] || fail "fixture 34 the sale did not survive the restart"
grep -qF 'data-event-disposal-kind="Sold"' <<<"$card" \
  || fail "fixture 34 the disposal kind did not survive the restart: $card"
grep -qF "data-event-odometer=\"$sell_odo_display mi\"" <<<"$card" \
  || fail "fixture 34 the sale odometer link did not survive the restart"
[ -n "$(event_card acquisition "$REBUY_NOTE")" ] \
  || fail "fixture 34 the repurchase did not survive the restart"
grep -qF 'data-event-disposal-kind="Traded In"' <<<"$(event_card disposal "$TRADE_OUT_NOTE")" \
  || fail "fixture 34 the traded-in disposal did not survive the restart"
[ -n "$(event_card acquisition "$TRADE_IN_NOTE")" ] \
  || fail "fixture 34 the trade-in purchase did not survive the restart"
# The two purchases are named by their observed start rather than counted,
# because fixture 33 deliberately leaves a third acquisition behind.
for observed in "$BUY_DA" "$REBUY_DA"; do
  grep -q '%event-id' <<<"$(scoped_rows vehicle-acquisitions A event-id "$observed")" \
    || fail "fixture 34 the purchase at $observed did not survive the restart"
done
grep -q '%event-id' <<<"$(scoped_rows vehicle-disposals D event-id "$SELL_DA")" \
  || fail "fixture 34 the sale did not survive the restart as a typed child"
report="$(rover_report "FROM vehicles V WHERE V.label = '$VEHICLE' SELECT V.label, V.archived;")"
grep -q '%archived 102 0' <<<"$report" \
  && fail "fixture 34 the sold vehicle became archived over the restart: $report"
note "fixture 34 PASS - both purchases, the sale and its kind, the trade-in pair, the odometer links, and the disposal-kind pack survived a ship restart"

# ---------------------------------------------------------------------------
# fixture 43 - the ownership bound survives the same real ship restart. The
# break is derived on every read rather than stored, so a restart is the check
# that the derivation still runs, not that a row is still there.
# ---------------------------------------------------------------------------
set_default_vehicle "$GAP_VEHICLE"
view="$(eyre_view)"
restart_best="$(hub_readout 'BEST ECONOMY' <<<"$view")"
[ "$restart_best" = '30.000 mpg' ] \
  || fail "fixture 43 the best economy after restart is $restart_best, want 30.000 mpg"
restart_mean="$(hub_readout 'ECONOMY - LIFETIME' <<<"$view")"
[ "$restart_mean" = '27.500 mpg' ] \
  || fail "fixture 43 the mean after restart is $restart_mean, want 27.500 mpg"
view="$(eyre_view_vehicle "$GAP_VEHICLE")"
mapfile -t restart_cells < <(economy_cells <<<"$view")
restart_expected=('25.000 mpg' 'Unavailable' '30.000 mpg' 'Unavailable')
[ "${restart_cells[*]}" = "${restart_expected[*]}" ] \
  || fail "fixture 43 the per-interval figures changed over the restart: ${restart_cells[*]}"
grep -q 'data-economy-break="%ownership-gap"' <<<"$view" \
  || fail "fixture 43 the derived ownership break is gone after the restart"
set_default_vehicle "$BARE_VEHICLE"
view="$(eyre_view)"
restart_bare="$(hub_readout 'BEST ECONOMY' <<<"$view")"
[ "$restart_bare" = '80.000 mpg' ] \
  || fail "fixture 43 the no-ownership-event vehicle changed over the restart: $restart_bare"
view="$(eyre_view_vehicle "$DEF_GAP_VEHICLE")"
grep -qF "data-def-economy-unavailable=\"$DEF_GAP_VEHICLE\"" <<<"$view" \
  || fail "fixture 43 the cross-gap DEF interval computed again after the restart"
note "fixture 43 PASS - the derived ownership break, the bounded aggregates, and the untouched control vehicle all survived a ship restart"

# ---------------------------------------------------------------------------
# fixture 53 - every reminder answer survives the same real ship restart, and
# Rover holds no timer for any of them.
#
# The second half is the point of the T6 design. Rover schedules no wakeup for
# a reminder, so the restart cannot leave a duplicate wakeup or an orphaned
# wire behind. That is asserted on the shipping source: every Behn card the
# agent sends is a one-second sequencing delay, and `on-arvo` answers a named
# set of wires that holds no reminder.
#
# The wires are named rather than counted. M8 gave `on-arvo` four more of
# them - one export fetch, the two Clay answers the attachment desk sends, and
# the bucket's answer to an imported photo - and a bare count cannot tell a
# new reminder timer from a new photo path.
# ---------------------------------------------------------------------------
waits="$(grep -c '%wait' "$REPO/desk/app/rover.hoon")"
one_shots="$(grep -c '%wait (add now.bowl ~s1)' "$REPO/desk/app/rover.hoon")"
[ "$waits" = "$one_shots" ] \
  || fail "fixture 53 the agent sends $waits Behn cards and only $one_shots are one-shot sequencing delays"
arvo_wires="$(grep -oE '\?=\(\[%rover-[a-z0-9-]+ \*\] wire\)' "$REPO/desk/app/rover.hoon" |
  sed -E 's/^.*\[%(rover-[a-z0-9-]+) .*$/\1/' | sort -u | tr '\n' ' ')"
arvo_wires_want='rover-attachment-s3-get rover-attachment-s3-put rover-bootstrap-delay rover-energy-odometer-drop-delay rover-energy-odometer-precheck-delay rover-export-fetch rover-files-desk rover-files-write rover-import-photo-s3-put rover-install-delay '
[ "$arvo_wires" = "$arvo_wires_want" ] \
  || fail "fixture 53 on-arvo answers [$arvo_wires], want [$arvo_wires_want]"
grep -qE '%rover-reminder[a-z-]*-(delay|wake|timer)' "$REPO/desk/app/rover.hoon" \
  && fail "fixture 53 the agent carries a reminder timer wire"
set_default_vehicle "$REM_VEHICLE"
view="$(eyre_view)"
[ "$(reminder_state 'Engine Oil')" = due ] \
  || fail "fixture 53 the crossed distance reminder is $(reminder_state 'Engine Oil') after the restart, want due"
[ "$(reminder_state 'Inspection')" = not-due ] \
  || fail "fixture 53 the future time reminder is $(reminder_state 'Inspection') after the restart, want not-due"
[ "$(reminder_state 'Brake Fluid')" = due ] \
  || fail "fixture 53 the past time reminder is $(reminder_state 'Brake Fluid') after the restart, want due"
set_default_vehicle "$GAP_VEHICLE"
view="$(eyre_view)"
[ "$(reminder_state 'Engine Oil')" = unavailable ] \
  || fail "fixture 53 the cross-gap reminder is $(reminder_state 'Engine Oil') after the restart, want unavailable"
[ "$(reminder_due 'Tire Rotation')" = 'Due in 100 mi' ] \
  || fail "fixture 53 the within-ownership reminder reads $(reminder_due 'Tire Rotation') after the restart"
set_default_vehicle "$REM_EMPTY_VEHICLE"
view="$(eyre_view)"
[ "$(reminder_state 'Engine Oil')" = unavailable ] \
  || fail "fixture 53 the no-reading reminder is $(reminder_state 'Engine Oil') after the restart, want unavailable"
set_default_vehicle "$REM_RESET_VEHICLE"
view="$(eyre_view)"
[ "$(reminder_due 'Oil Filter')" = 'Due in 3,000 mi' ] \
  || fail "fixture 53 the reset distance reminder reads $(reminder_due 'Oil Filter') after the restart"
report="$(rem_rows service-reminder-distance D due-digits "$REM_RESET_VEHICLE" 'Oil Filter')"
grep -q '%due-digits 25717 20100' <<<"$report" \
  || fail "fixture 53 the stored distance due point did not survive the restart: $report"
note "fixture 53 PASS - every reminder answer survived a ship restart, and the agent holds no reminder timer, no duplicate wakeup, and no orphaned wire"

# ---------------------------------------------------------------------------
# fixture 64 - the whole specification family survives the same real restart:
# the stored rows, the corrected VIN, the absences, and the rendered
# description. The compatibility guard is checked again on the far side,
# because a vehicle with no specification data is the state every installed
# database is in and a restart must not move it.
# ---------------------------------------------------------------------------
view="$(eyre_view)"
card="$(vehicle_card "$SPEC_VEHICLE")"
[ "$(spec_line "$card" headline)" = '2019 Ford F-150 Lariat' ] \
  || fail "fixture 64 the headline reads '$(spec_line "$card" headline)' after the restart"
[ "$(spec_line "$card" detail)" = 'Oxford White crew cab pickup, 3.5L V6 EcoBoost, 10-speed automatic, four-wheel drive, 5.5 ft bed.' ] \
  || fail "fixture 64 the description reads '$(spec_line "$card" detail)' after the restart"
[ "$(spec_line "$card" vin)" = "VIN $SPEC_VIN" ] \
  || fail "fixture 64 the corrected VIN did not survive the restart: '$(spec_line "$card" vin)'"
[ "$(spec_line "$card" note)" = "$SPEC_NOTE" ] \
  || fail "fixture 64 the vehicle note did not survive the restart"
report="$(spec_rows vehicle-vin S vin "$SPEC_VEHICLE")"
[ "$(count_rows "$report" '%vin')" = 1 ] \
  || fail "fixture 64 the restart left more than one VIN row: $report"
for pair in $SPEC_RELATIONS; do
  relation="${pair%%:*}"
  column="${pair##*:}"
  report="$(spec_rows "$relation" S "$column" "$SPEC_VEHICLE")"
  grep -q "%$column" <<<"$report" \
    || fail "fixture 64 $relation lost its row over the restart: $report"
done
# The absences survived too. Eleven relations still hold nothing for the
# partly specified vehicle, and the plate-only vehicle still has no VIN.
for pair in $SPEC_RELATIONS; do
  relation="${pair%%:*}"
  column="${pair##*:}"
  case "$relation" in
    vehicle-model) continue ;;
  esac
  report="$(spec_rows "$relation" S "$column" "$SPEC_PARTIAL_VEHICLE")"
  [ "$(count_rows "$report" "%$column")" = 0 ] \
    || fail "fixture 64 $relation gained a row for the partial vehicle over the restart: $report"
done
report="$(spec_rows vehicle-vin S vin "$SPEC_PLATE_ONLY_VEHICLE")"
[ "$(count_rows "$report" '%vin')" = 0 ] \
  || fail "fixture 64 the plate-only vehicle gained a VIN over the restart: $report"
card="$(vehicle_card "$SPEC_FREE_VEHICLE")"
[ -n "$card" ] || fail "fixture 64 the specification-free vehicle is gone after the restart"
grep -q 'data-vehicle-spec' <<<"$card" \
  && fail "fixture 64 the specification-free vehicle gained a specification line over the restart"
note "fixture 64 PASS - every specification row, absence, correction, and rendered description survived a ship restart"

# ---------------------------------------------------------------------------
# fixture 76 - every T8 fact survives the same real ship restart: the renames,
# the archive flags, the restores, and the seeded starters that stayed
# archived while the seeding ran twice.
# ---------------------------------------------------------------------------
for family in $T8_FAMILIES; do
  label="$(t8_label "$family")"
  [ "$(t8_row_count "$family" "$label")" = 1 ] \
    || fail "fixture 76 the $family definition $label did not survive the restart"
  [ "$(t8_archived_flag "$family" "$label")" = 1 ] \
    || fail "fixture 76 the $family definition $label came back archived"
done
# The label a rename left behind must still be gone after the restart.
[ "$(t8_row_count service-subtype "$T8_SUBTYPE_FIXED")" = 0 ] \
  || fail "fixture 76 a label a rename replaced came back after the restart"
[ "$(t8_row_count tag "$T8_LONE_TAG")" = 1 ] \
  || fail "fixture 76 the unreferenced tag did not survive the restart"
[ "$(t8_archived_flag tag "$T8_LONE_TAG")" = 1 ] \
  || fail "fixture 76 the restored unreferenced tag came back archived"
# Archive and restore across a restart, on a definition that has been through
# both already. The flag is state in the database, not state in the agent.
t8_archive additive "$T8_ADDITIVE" 'fixture 76 archive after the restart'
[ "$(t8_archived_flag additive "$T8_ADDITIVE")" = 0 ] \
  || fail "fixture 76 archiving after the restart did not take"
view="$(eyre_view_vehicle "$T8_VEHICLE")"
[ "$(t8_offers additive "$T8_ADDITIVE")" = no ] \
  || fail "fixture 76 the additive selector still offers the archived $T8_ADDITIVE after the restart"
t8_restore additive "$T8_ADDITIVE" 'fixture 76 restore after the restart'
[ "$(t8_archived_flag additive "$T8_ADDITIVE")" = 1 ] \
  || fail "fixture 76 restoring after the restart did not take"
# The historical records still name what they named.
view="$(eyre_view_vehicle "$T8_VEHICLE")"
service_card="$(event_card service "$T8_SERVICE_NOTE")"
grep -qF "$T8_SUBTYPE" <<<"$service_card" \
  || fail "fixture 76 the service card lost its subtype across the restart"
disposal_card="$(event_card disposal "$T8_DISPOSAL_NOTE")"
grep -qF "$T8_DISPOSAL" <<<"$disposal_card" \
  || fail "fixture 76 the disposal card lost its kind across the restart"
note "fixture 76 PASS - every rename, archive flag and restore survived a ship restart, and archive and restore still work after it"

# ---------------------------------------------------------------------------
# fixture 94 - every correction survived the same real ship restart: the
# corrected total, the identity behind it, the association that was removed,
# the associations that were added, and the derived ownership figure.
# ---------------------------------------------------------------------------
[ "$(event_id_at "$FIX_DA" "$FIX_VEHICLE")" = "$fix_id_before" ] \
  || fail "fixture 94 the corrected event was re-keyed by the restart"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$FIX_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 399990 ] \
  || fail "fixture 94 the corrected total did not survive the restart: $report"
report="$(scoped_rows vehicle-event-tags G tag-id "$FIX_DA" "$FIX_VEHICLE")"
grep -q '%tag-id' <<<"$report" \
  && fail "fixture 94 a removed tag link came back over the restart: $report"
report="$(scoped_rows vehicle-event-payment-method P method-id "$FIX_DA" "$FIX_VEHICLE")"
grep -q '%method-id' <<<"$report" \
  && fail "fixture 94 a removed payment link came back over the restart: $report"
[ "$(event_id_at "$BARE_EDIT_DA" "$FIX_VEHICLE")" = "$bare_id_before" ] \
  || fail "fixture 94 the event that gained associations was re-keyed by the restart"
for pair in 'vehicle-event-cost-totals T' 'vehicle-event-odometers L' \
  'vehicle-event-stations S' 'vehicle-event-tags G' \
  'vehicle-event-payment-method P'
do
  set -- $pair
  report="$(scoped_rows "$1" "$2" event-id "$BARE_EDIT_DA" "$FIX_VEHICLE")"
  linked="$(grep -oE '%event-id [0-9]+ [0-9a-fx.]+' <<<"$report" | head -1)"
  [ "$linked" = "$bare_id_before" ] \
    || fail "fixture 94 the added $1 row did not survive the restart: $linked"
done
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$SIB_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 41000 ] \
  || fail "fixture 94 the untouched sibling changed over the restart: $report"
# The correction a person made with a pointer survives on the same terms.
[ "$(event_id_at "$BROWSER_FIX_DA" "$FIX_VEHICLE")" = "$browser_fix_id" ] \
  || fail "fixture 94 the browser-corrected event was re-keyed by the restart"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$BROWSER_FIX_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 137450 ] \
  || fail "fixture 94 the browser correction did not survive the restart: $report"
stat_view="$(scoped_event_view "$STAT_FIX_VEHICLE")"
grep -q 'data-total-cost-mills="10450000"' <<<"$stat_view" \
  || fail "fixture 94 the corrected ownership total did not survive the restart"
card="$(event_card service "$FIX_NOTE")"
grep -qF 'data-event-total="$399.99"' <<<"$card" \
  || fail "fixture 94 the corrected card did not survive the restart: $card"
[ "$(event_card_count service "$FIX_NOTE")" = 1 ] \
  || fail "fixture 94 the restart produced a second card for the corrected event"
# A correction still works after the restart, and it still keeps the identity.
eyre_post edit-event \
  "$(edit_payload service "$FIX_AT" "$FIX_AT" '$401.00' "$FIX_ODO" \
    "$STATION" '[]' '' "$FIX_NOTE" '["Engine Oil"]' "$FIX_VEHICLE")" \
  $'Corrected service event - $401.00\n200' 'fixture 94 a correction after the restart'
[ "$(event_id_at "$FIX_DA" "$FIX_VEHICLE")" = "$fix_id_before" ] \
  || fail "fixture 94 a correction after the restart re-keyed the event"
report="$(scoped_rows vehicle-event-cost-totals T total-mills "$FIX_DA" "$FIX_VEHICLE")"
[ "$(cell_number "$report" total-mills)" = 401000 ] \
  || fail "fixture 94 a correction after the restart did not store: $report"
note "fixture 94 PASS - every correction, removal, addition and derived figure survived a ship restart, and correcting still works after it"

# ---------------------------------------------------------------------------
# fixture 106 - every M8 fact survived the same real ship restart: the
# references, the links to all three owner families, the bytes in both
# backends, and the rule that keeps blobs out of Obelisk.
#
# The bytes are the point. A reference that survives while the file behind it
# does not is worse than losing both, because the database would then promise
# a photo the ship cannot produce. So each one is read back through the
# serving endpoint and hashed, not merely counted.
# ---------------------------------------------------------------------------
for name in "$fill_photo" "$event_photo" "$vehicle_photo" "$s3_photo"; do
  [ "$(fetch_file "$name" "$M8_PHOTO_BACK")" = 200 ] \
    || fail "fixture 106 $name did not serve back after the restart"
  [ "$(digest "$M8_PHOTO_BACK")" = "$M8_PHOTO_HASH" ] \
    || fail "fixture 106 $name does not hash equal to the source bytes after the restart"
  cmp -s "$M8_PHOTO" "$M8_PHOTO_BACK" \
    || fail "fixture 106 $name is no longer byte for byte the source photo"
done
# The S3-backed photo came out of the bucket, not out of Clay. Its reference
# still names the backend it was stored in.
report="$(rover_report "FROM attachments T WHERE T.file-name = '$s3_photo' SELECT T.attachment-id, T.backend, T.locator;")"
backend_named "$report" s3 \
  || fail "fixture 106 the S3 reference lost its backend over the restart: $report"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$fill_photo' SELECT T.attachment-id, T.backend, T.locator;")"
backend_named "$report" clay \
  || fail "fixture 106 the Clay reference lost its backend over the restart: $report"
# One link per owner family, each still keyed to its family parent.
report="$(rover_report "FROM energy-acquisition-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$fill_photo' SELECT L.acquisition-id, L.attachment-id;")"
grep -q '%acquisition-id' <<<"$report" \
  || fail "fixture 106 the energy link did not survive the restart: $report"
report="$(rover_report "FROM vehicle-event-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$event_photo' SELECT L.event-id, L.attachment-id;")"
grep -q '%event-id' <<<"$report" \
  || fail "fixture 106 the event link did not survive the restart: $report"
report="$(rover_report "FROM vehicle-attachments L JOIN attachments T ON L.attachment-id = T.attachment-id WHERE T.file-name = '$vehicle_photo' SELECT L.vehicle-id, L.attachment-id;")"
grep -q '%vehicle-id' <<<"$report" \
  || fail "fixture 106 the vehicle link did not survive the restart: $report"
# Still no blob in Obelisk on the far side of the restart.
blob_probe="$(rover_report 'FROM attachments T SELECT T.attachment-id, T.backend, T.locator, T.content-hash, T.byte-count, T.media-type, T.file-name;')"
[ "$(printf '%s' "$blob_probe" | wc -c)" -lt 200000 ] \
  || fail "fixture 106 the attachments relation reads back blob-sized after the restart"
# And attaching still works, to a record that predates the restart.
restart_photo="restart-receipt-$STAMP.jpg"
attach_response="$(attach_file fill "$VEHICLE" "$M8_FILL_AT" "$restart_photo" 'image/jpeg' "$M8_PHOTO" clay)"
case "$attach_response" in
  (*$'\n'201) ;;
  (*) fail "fixture 106 a photo would not attach after the restart: $attach_response";;
esac
[ "$(fetch_file "$restart_photo" "$M8_PHOTO_BACK")" = 200 ] \
  || fail "fixture 106 the photo attached after the restart did not serve back"
[ "$(digest "$M8_PHOTO_BACK")" = "$M8_PHOTO_HASH" ] \
  || fail "fixture 106 the photo attached after the restart does not hash equal to the source"
note "fixture 106 PASS - every reference, every link, and the bytes in both backends survived a ship restart, no blob is in Obelisk on the far side, and attaching still works after it"

# ---------------------------------------------------------------------------
# fixture 13 - the Gate 7 fence stays shut
# ---------------------------------------------------------------------------
arms="$(python3 - "$REPO/desk/sur/rover.hoon" <<'PY'
import pathlib, re, sys
source = pathlib.Path(sys.argv[1]).read_text()
union = source.split("+$  action", 1)[1].split("==", 1)[0]
print(len(re.findall(r"\[%[a-z-]+ ~\]", union)))
PY
)"
[ "$arms" = 5 ] || fail "fixture 13 the shipping action union has $arms arms, want 5"
note "fixture 13 PASS - the shipping action union still has five arms"

# ---------------------------------------------------------------------------
# fixture 15 - the route selects the kind, and a body cannot override it.
# The three kinds share one handler, so the only thing separating them is the
# route. A client that names a kind in the body must not be able to make the
# server write a different typed child than the route selected.
# ---------------------------------------------------------------------------
FORGE_NOTE="Forged kind $STAMP"
FORGE_AT="2026-08-01T13:00"
forge_payload="$(printf '{"vehicle":"%s","kind":"service","observed":"%s","zone":"America/Chicago","total":"","currency":"usd","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"%s"}' \
  "$VEHICLE" "$FORGE_AT" "$FORGE_NOTE")"
eyre_post add-note-event "$forge_payload" $'Saved note event\n201' \
  'fixture 15 forged-kind note event'

# event_card reads $view, so refresh it before asserting on the new card.
view="$(eyre_view)"
forged_service="$(event_card service "$FORGE_NOTE")"
[ -z "$forged_service" ] \
  || fail "fixture 15 a body kind overrode the route and made a service event"
forged_note="$(event_card note "$FORGE_NOTE")"
[ -n "$forged_note" ] \
  || fail "fixture 15 the note route did not write a note event"
note "fixture 15 PASS - the route decides the kind, and the body cannot override it"

# ---------------------------------------------------------------------------
# fixture 14 - a person can reach the endpoint. Gate 7 deleted two real user
# actions for shipping with no way to invoke them, so an endpoint with no
# browser control is the same defect wearing the other hat.
# ---------------------------------------------------------------------------
playwright_module="${ROVER_PLAYWRIGHT_MODULE:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules/playwright}"
chromium_binary="${ROVER_CHROMIUM:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
[ -f "$playwright_module/package.json" ] \
  || fail "fixture 14 Playwright is unavailable at $playwright_module"
[ -x "$chromium_binary" ] \
  || fail "fixture 14 Chromium is unavailable at $chromium_binary"
auth_cookie_name="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $6; exit}' "$JAR")"
auth_cookie="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $7; exit}' "$JAR")"
[ -n "$auth_cookie" ] || fail "fixture 14 has no urbauth cookie to hand the browser"
BROWSER_NOTE="Browser service $STAMP"
BROWSER_ODO="$((53000 + STAMP % 1000))"
BROWSER_SUBTYPES='Engine Oil,Oil Filter,Tire Rotation'
browser_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/event-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$VEHICLE" "$STATION" "$TAG" \
      "$PAYMENT" '$88.40' "$BROWSER_ODO" "$BROWSER_NOTE" "$BROWSER_SUBTYPES"
} 2>&1)" || fail "fixture 14 the browser could not save an event: $browser_out"
grep -q 'EVENT_VERDICT=Saved service event - \$88.40' <<<"$browser_out" \
  || fail "fixture 14 the form verdict is wrong: $browser_out"
grep -q 'EVENT_CARDS=1' <<<"$browser_out" \
  || fail "fixture 14 the saved event did not appear in the reloaded view: $browser_out"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-notes X ON E.event-id = X.event-id WHERE V.label = '$VEHICLE' SELECT X.note;")"
grep -qF "$BROWSER_NOTE" <<<"$report" \
  || fail "fixture 14 the browser-entered event is not in the database: $report"
note "fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back"

# ---------------------------------------------------------------------------
# fixture 22 - a person selects several subtypes in the browser form and sees
# them come back on the card. The endpoint battery proves the write; this
# proves the selection is reachable with a pointer.
# ---------------------------------------------------------------------------
grep -q "EVENT_SUBTYPES=$BROWSER_SUBTYPES" <<<"$browser_out" \
  || fail "fixture 22 the reloaded card does not carry the chosen subtypes: $browser_out"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-notes X ON E.event-id = X.event-id JOIN vehicle-event-service-subtypes L ON E.event-id = L.event-id JOIN service-subtype-definitions S ON L.service-subtype-id = S.service-subtype-id WHERE V.label = '$VEHICLE' AND X.note = '$BROWSER_NOTE' SELECT S.label AS chosen;")"
chosen_rows="$(count_rows "$report" '%chosen')"
[ "$chosen_rows" = 3 ] \
  || fail "fixture 22 the browser event has $chosen_rows subtype links, want 3: $report"
for label in 'Engine Oil' 'Oil Filter' 'Tire Rotation'; do
  grep -qF "%chosen 116 '$label'" <<<"$report" \
    || fail "fixture 22 the browser-chosen subtype $label is not in the database: $report"
done
note "fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card"

# ---------------------------------------------------------------------------
# fixture 35 - a person records a purchase and a sale from the Add Event form
# and sees both come back. Gate 7 removed two real actions for shipping with
# no way to invoke them, so an endpoint with no browser control is the same
# defect wearing the other hat.
# ---------------------------------------------------------------------------
BROWSER_BUY_NOTE="Browser purchase $STAMP"
BROWSER_SELL_NOTE="Browser sale $STAMP"
BROWSER_BUY_ODO="$((55000 + STAMP % 1000))"
BROWSER_SELL_ODO="$((56000 + STAMP % 1000))"
ownership_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/ownership-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$VEHICLE" \
      '$21,500.00' "$BROWSER_BUY_ODO" "$BROWSER_BUY_NOTE" \
      '$16,750.00' "$BROWSER_SELL_ODO" "$BROWSER_SELL_NOTE" 'Gifted'
} 2>&1)" || fail "fixture 35 the browser could not record ownership: $ownership_out"
grep -q 'ACQUISITION_VERDICT=Saved acquisition event - \$21,500.00' <<<"$ownership_out" \
  || fail "fixture 35 the purchase verdict is wrong: $ownership_out"
grep -q 'DISPOSAL_VERDICT=Saved disposal event - \$16,750.00' <<<"$ownership_out" \
  || fail "fixture 35 the sale verdict is wrong: $ownership_out"
grep -q 'ACQUISITION_CARDS=1' <<<"$ownership_out" \
  || fail "fixture 35 the saved purchase did not appear in the reloaded view: $ownership_out"
grep -q 'DISPOSAL_CARDS=1' <<<"$ownership_out" \
  || fail "fixture 35 the saved sale did not appear in the reloaded view: $ownership_out"
grep -q 'DISPOSAL_KIND=Gifted' <<<"$ownership_out" \
  || fail "fixture 35 the reloaded sale card does not carry the chosen kind: $ownership_out"
# A disposal kind belongs on a disposal. The picker must not offer itself on a
# purchase, the way the subtype picker hides for a note.
grep -q 'KIND_FIELD_ON_ACQUISITION=hidden' <<<"$ownership_out" \
  || fail "fixture 35 the disposal-kind picker shows on a purchase: $ownership_out"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-disposals X ON E.event-id = X.event-id JOIN disposal-kind-definitions D ON X.disposal-kind-id = D.disposal-kind-id JOIN vehicle-event-notes N ON E.event-id = N.event-id WHERE V.label = '$VEHICLE' AND N.note = '$BROWSER_SELL_NOTE' SELECT D.label AS chosen-kind;")"
grep -qF "%chosen-kind 116 'Gifted'" <<<"$report" \
  || fail "fixture 35 the browser-chosen disposal kind is not in the database: $report"
note "fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history"

# ---------------------------------------------------------------------------
# fixture 54 - a person records a reminder from the Add Reminder form and sees
# what is due come back on the hub. Gate 7 removed two real actions for
# shipping with no way to invoke them, so an endpoint with no browser control
# is the same defect wearing the other hat.
#
# The reminder goes on the vehicle the hub is showing, because the hub renders
# the app default vehicle and this fixture proves the round trip a person sees.
# ---------------------------------------------------------------------------
set_default_vehicle "$REM_VEHICLE"
reminder_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/reminder-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$REM_VEHICLE" \
      'Wheel Alignment' '5000' '20000'
} 2>&1)" || fail "fixture 54 the browser could not save a reminder: $reminder_out"
grep -q 'REMINDER_VERDICT=Saved reminder - Wheel Alignment' <<<"$reminder_out" \
  || fail "fixture 54 the form verdict is wrong: $reminder_out"
grep -q 'REMINDER_STATE=not-due' <<<"$reminder_out" \
  || fail "fixture 54 the saved reminder did not come back not due: $reminder_out"
grep -q 'REMINDER_DUE=Due in 6,950 mi' <<<"$reminder_out" \
  || fail "fixture 54 the reloaded hub does not count down from the derived odometer: $reminder_out"
report="$(rem_rows service-reminder-distance D due-digits "$REM_VEHICLE" 'Wheel Alignment')"
grep -q '%due-digits 25717 20000' <<<"$report" \
  || fail "fixture 54 the browser-entered reminder is not in the database: $report"
report="$(rem_rows service-reminder-time T interval-count "$REM_VEHICLE" 'Wheel Alignment')"
grep -q '%interval-count' <<<"$report" \
  && fail "fixture 54 the blank time interval was stored as a row: $report"
note "fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub"

# ---------------------------------------------------------------------------
# fixture 65 - a person records the specification in the vehicle settings form
# and sees the vehicle screen come back reading like a description. Gate 7
# removed two real actions for shipping with no way to invoke them, so an
# endpoint with no browser control is the same defect wearing the other hat.
#
# THE VIN AND THE PLATE BELOW ARE SYNTHETIC. Fixture 63 asserts their shape.
# ---------------------------------------------------------------------------
BROWSER_SPEC_VEHICLE="Spec Browser Vehicle $STAMP"
BROWSER_VIN='ROVERFAKEVIN00003'
BROWSER_PLATE='ROVER-FAKE-03'
BROWSER_SPEC_NOTE="Second owner $STAMP"
own_add_vehicle "$BROWSER_SPEC_VEHICLE" Gasoline
spec_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/spec-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$BROWSER_SPEC_VEHICLE" \
      "$BROWSER_VIN" "$BROWSER_PLATE" '1981' 'Chevrolet' 'C10' 'Scottsdale' \
      'regular cab pickup' 'Carmine Red' '5.7L V8' '4-speed manual' \
      'rear-wheel drive' '8 ft bed' "$BROWSER_SPEC_NOTE"
} 2>&1)" || fail "fixture 65 the browser could not save a specification: $spec_out"
grep -q 'SPEC_FIELDSET=present' <<<"$spec_out" \
  || fail "fixture 65 the settings form has no specification section: $spec_out"
grep -q 'SPEC_VERDICT=Saved vehicle settings' <<<"$spec_out" \
  || fail "fixture 65 the form verdict is wrong: $spec_out"
grep -q 'SPEC_HEADLINE=1981 Chevrolet C10 Scottsdale' <<<"$spec_out" \
  || fail "fixture 65 the reloaded description headline is wrong: $spec_out"
grep -q 'SPEC_DETAIL=Carmine Red regular cab pickup, 5.7L V8, 4-speed manual, rear-wheel drive, 8 ft bed.' <<<"$spec_out" \
  || fail "fixture 65 the reloaded description is wrong: $spec_out"
grep -q "SPEC_VIN_LINE=VIN $BROWSER_VIN" <<<"$spec_out" \
  || fail "fixture 65 the reloaded VIN line is wrong: $spec_out"
grep -q "SPEC_PLATE_LINE=PLATE $BROWSER_PLATE" <<<"$spec_out" \
  || fail "fixture 65 the reloaded plate line is wrong: $spec_out"
grep -q "SPEC_NOTE_LINE=$BROWSER_SPEC_NOTE" <<<"$spec_out" \
  || fail "fixture 65 the reloaded note line is wrong: $spec_out"
report="$(spec_rows vehicle-model-year S model-year "$BROWSER_SPEC_VEHICLE")"
grep -q '%model-year 25717 1981' <<<"$report" \
  || fail "fixture 65 the browser-entered year is not a number in the database: $report"
report="$(spec_rows vehicle-vin S vin "$BROWSER_SPEC_VEHICLE")"
grep -qF "$BROWSER_VIN" <<<"$report" \
  || fail "fixture 65 the browser-entered VIN is not in the database: $report"
note "fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description"


# ---------------------------------------------------------------------------
# fixture 77 - a person renames, archives and restores a definition in a real
# browser. Gate 7 deleted two real user actions for shipping with no endpoint,
# and T8 exists because of that ruling, so an endpoint with no browser control
# would repeat the same defect wearing the other hat.
#
# The definition is a tag of this run's own. The fixture drives the Settings
# screen, answers the prompt and the confirm the controls raise, and then
# reads the Add Fill tag list to prove the archived definition left a selector
# a person actually picks from.
# ---------------------------------------------------------------------------
BROWSER_DEF_TAG="T8 Browser Tag $STAMP"
BROWSER_DEF_RENAMED="T8 Browser Tag $STAMP fixed"
curl -s -b "$JAR" -H 'content-type: application/json' \
  --data-raw "$(printf '{"rover-import":1,"source":{"app":"rover-event-test"},"definitions":{"energy":[],"additives":[],"driving-modes":[],"tags":[{"label":"%s"}],"payment-methods":[]},"places":[],"vehicles":[]}' \
    "$BROWSER_DEF_TAG")" \
  "$URL/apps/rover/import" > /dev/null
[ "$(t8_row_count tag "$BROWSER_DEF_TAG")" = 1 ] \
  || fail "fixture 77 the browser fixture has no tag to work on"
definition_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/definition-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" \
      tag "$BROWSER_DEF_TAG" "$BROWSER_DEF_RENAMED"
} 2>&1)" || fail "fixture 77 the browser could not drive the definition controls: $definition_out"
grep -q 'DEF_PANEL=present' <<<"$definition_out" \
  || fail "fixture 77 the settings screen has no definitions panel: $definition_out"
grep -q 'DEF_RENAME_VERDICT=Renamed definition' <<<"$definition_out" \
  || fail "fixture 77 the rename control did not report a rename: $definition_out"
grep -q "DEF_RENAMED_ENTRY=$BROWSER_DEF_RENAMED" <<<"$definition_out" \
  || fail "fixture 77 the renamed definition is not on the reloaded panel: $definition_out"
grep -q 'DEF_ARCHIVE_VERDICT=Archived definition' <<<"$definition_out" \
  || fail "fixture 77 the archive control did not report an archive: $definition_out"
grep -q 'DEF_ARCHIVED_FLAG=yes' <<<"$definition_out" \
  || fail "fixture 77 the archived definition is not marked archived on the panel: $definition_out"
grep -q 'DEF_SELECTOR_WHILE_ARCHIVED=absent' <<<"$definition_out" \
  || fail "fixture 77 the archived definition is still in the Add Fill tag list: $definition_out"
grep -q 'DEF_RESTORE_VERDICT=Restored definition' <<<"$definition_out" \
  || fail "fixture 77 the restore control did not report a restore: $definition_out"
grep -q 'DEF_ARCHIVED_FLAG_AFTER_RESTORE=no' <<<"$definition_out" \
  || fail "fixture 77 the restored definition is still marked archived: $definition_out"
grep -q 'DEF_SELECTOR_AFTER_RESTORE=present' <<<"$definition_out" \
  || fail "fixture 77 the restored definition did not come back to the Add Fill tag list: $definition_out"
# The browser session's writes are in the database, not only on the screen.
[ "$(t8_row_count tag "$BROWSER_DEF_RENAMED")" = 1 ] \
  || fail "fixture 77 the browser rename is not in the database"
[ "$(t8_row_count tag "$BROWSER_DEF_TAG")" = 0 ] \
  || fail "fixture 77 the browser rename left the old label behind"
[ "$(t8_archived_flag tag "$BROWSER_DEF_RENAMED")" = 1 ] \
  || fail "fixture 77 the browser restore is not in the database"
note "fixture 77 PASS - a person renames, archives and restores a definition in the browser, and the archived one leaves the Add Fill tag list and comes back"

# ---------------------------------------------------------------------------
# M7 T9 - the widened aCar import enters through the same product writes.
# This document is synthetic. Its VIN contains letters the real VIN alphabet
# excludes, and its plate says FAKE, so neither can be mistaken for owner data.
# ---------------------------------------------------------------------------
T9_IMPORT_VEHICLE="T9 Import Vehicle $STAMP"
T9_IMPORT_SUBTYPE="T9 Service Type $STAMP"
T9_IMPORT_STATION="T9 Workshop $STAMP"
T9_IMPORT_TAG="T9 Import Tag $STAMP"
T9_IMPORT_PAYMENT="T9 Import Card $STAMP"
T9_IMPORTED_AT='~2026.08.10..10.00.00'
T9_HAND_AT='~2026.08.11..10.00.00'
T9_IMPORT_DOCUMENT="$(python3 - "$STAMP" <<'PY'
import json
import sys

stamp = sys.argv[1]
vehicle = f"T9 Import Vehicle {stamp}"
subtype = f"T9 Service Type {stamp}"
station = f"T9 Workshop {stamp}"
tag = f"T9 Import Tag {stamp}"
payment = f"T9 Import Card {stamp}"

def fill(observed, mileage, quantity, source_id):
    return {
        "additives": [],
        "definition": "Gasoline",
        "mileage": str(mileage),
        "mileageUnit": "mi",
        "missedFill": "no",
        "observed": observed,
        "price": "3.290",
        "profile": "us-usd-gal",
        "quantity": quantity,
        "settlement": "standard",
        "sourceApp": "acar",
        "sourceRecordId": source_id,
        "station": "none",
        "tags": [],
        "tank": "full",
        "vehicle": vehicle,
        "zone": "America/Chicago",
    }

document = {
    "rover-import": 1,
    "source": {"app": "aCar"},
    "definitions": {
        "energy": [],
        "additives": [],
        "driving-modes": [],
        "tags": [{"label": tag}],
        "payment-methods": [{"label": payment}],
        "service-subtypes": [{
            "label": subtype,
            "defaultDistanceInterval": "5000",
            "defaultDistanceUnit": "mi",
            "defaultTimeInterval": "6",
            "defaultTimeUnit": "month",
        }],
    },
    "places": [{"label": station, "stationKind": "private"}],
    "vehicles": [{
        "label": vehicle,
        "distanceUnit": "mi",
        "volumeUnit": "gal",
        "defaultEnergy": "Gasoline",
        "fills": [
            fill("2026-05-05T12:00", 40000, "12.000", f"t9-{stamp}-fill-1"),
            fill("2026-05-15T12:00", 40300, "10.000", f"t9-{stamp}-fill-2"),
            fill("2026-07-05T12:00", 41100, "10.000", f"t9-{stamp}-fill-3"),
            fill("2026-07-15T12:00", 41400, "12.000", f"t9-{stamp}-fill-4"),
        ],
        "serviceEvents": [{
            "vehicle": vehicle,
            "observed": "2026-08-10T10:00",
            "zone": "America/Chicago",
            "currency": "usd",
            "total": "88.40",
            "mileage": "41500",
            "mileageUnit": "mi",
            "station": station,
            "tags": [tag],
            "paymentMethod": payment,
            "notes": f"Imported service note {stamp}",
            "subtypes": [subtype],
            "sourceApp": "acar",
            "sourceRecordId": f"t9-{stamp}-service",
        }],
        "noteEvents": [{
            "vehicle": vehicle,
            "observed": "2026-08-12T10:00",
            "zone": "America/Chicago",
            "currency": "usd",
            "mileage": "41600",
            "mileageUnit": "mi",
            "station": "none",
            "tags": [],
            "notes": f"Imported plain note {stamp}",
            "sourceApp": "acar",
            "sourceRecordId": f"t9-{stamp}-note",
        }],
        "reminders": [{
            "vehicle": vehicle,
            "subtype": subtype,
            "distanceInterval": "5000",
            "distanceDue": "46500",
            "distanceUnit": "mi",
            "timeInterval": "6",
            "timeUnit": "month",
            "timeDue": "2027-02-10",
        }],
        "specification": {
            "specVin": f"ROVERFAKEVIN{stamp[-5:]}",
            "specPlate": f"ROVER-FAKE-{stamp[-5:]}",
            "specYear": "2020",
            "specMake": "Example Make",
            "specModel": "Example Model",
            "specSubModel": "Example Trim",
            "specBodyType": "Example Body",
            "specColor": "Example Blue",
            "specEngine": "Example Engine",
            "specTransmission": "Example Transmission",
            "specDriveType": "Example Drive",
            "specBedType": "Example Bed",
            "specNotes": f"Synthetic specification note {stamp}",
        },
    }],
}
print(json.dumps(document, separators=(",", ":")))
PY
)"

# ---------------------------------------------------------------------------
# fixture 78 - the converter owns the source-specific policy. Its unit suite
# covers duplicate service/expense labels, reminders, specification fields,
# exact decimal work, omission reporting, and byte-exact owner JPEGs.
# ---------------------------------------------------------------------------
t9_converter_out="$(python3 -m unittest discover -s "$REPO/tools/acar-import" -p 'test_convert.py' 2>&1)" \
  || fail "fixture 78 the converter suite failed: $t9_converter_out"
grep -q '^OK$' <<<"$t9_converter_out" \
  || fail "fixture 78 the converter suite did not finish cleanly: $t9_converter_out"
note "fixture 78 PASS - the source-specific converter suite carries the widened sections and reports every ruled omission"

# ---------------------------------------------------------------------------
# fixture 79 - one product import writes the widened definitions, two event
# kinds, reminder defaults, a reminder, all specification fields, and fills.
# The vehicle exists first, as it does after running the narrower pre-T9
# importer; widening it must not require deleting the owner's existing row.
# ---------------------------------------------------------------------------
own_add_vehicle "$T9_IMPORT_VEHICLE" Gasoline
t9_first="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-binary "$T9_IMPORT_DOCUMENT" \
  "$URL/apps/rover/import")"
case "$t9_first" in (*$'\n'200) ;; (*) fail "fixture 79 import failed: $t9_first";; esac
grep -q 'Fills: imported 4, already-imported 0, conflicts 0, failures 0' <<<"$t9_first" \
  || fail "fixture 79 the four fills did not import: $t9_first"
grep -q 'Events: imported 2, already-imported 0, conflicts 0' <<<"$t9_first" \
  || fail "fixture 79 the service and note did not import: $t9_first"
grep -q 'Reminders: imported 1, already-imported 0' <<<"$t9_first" \
  || fail "fixture 79 the reminder did not import: $t9_first"
grep -q 'Subtype defaults: created 1, reused 0' <<<"$t9_first" \
  || fail "fixture 79 the subtype default did not import: $t9_first"
note "fixture 79 PASS - a widened product import writes fills, service and note events, a reminder, and its subtype default"

# The shape signature counts parent, typed child, and every association. Each
# projection includes the relation key, so Obelisk cannot collapse equal rows.
t9_event_shape() {
  local observed="$1" result
  result="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT E.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN service-events S ON E.event-id = S.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT S.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-costs C ON E.event-id = C.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT C.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-cost-totals T ON E.event-id = T.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT T.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-odometers O ON E.event-id = O.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT O.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-stations S ON E.event-id = S.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT S.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-tags T ON E.event-id = T.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT T.event-id, T.tag-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-payment-method P ON E.event-id = P.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT P.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-notes Z ON E.event-id = Z.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT Z.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-service-subtypes S ON E.event-id = S.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' AND E.observed-start = $observed SELECT S.event-id, S.service-subtype-id;")"
  grep -oE '%vector-count [0-9]+' <<<"$result" | awk '{print $2}' | paste -sd' ' -
}

# ---------------------------------------------------------------------------
# fixture 80 - an imported service and a hand-entered service occupy the same
# ten relations. Both calls reach the same decoder and insert-event gate.
# ---------------------------------------------------------------------------
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"2026-08-11T10:00","zone":"America/Chicago","total":"$88.40","currency":"usd","mileage":"41550","mileageUnit":"mi","station":"%s","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":["%s"],"newTag":"","paymentMethod":"%s","notes":"Hand service note %s","subtypes":["%s"]}' \
    "$T9_IMPORT_VEHICLE" "$T9_IMPORT_STATION" "$T9_IMPORT_TAG" "$T9_IMPORT_PAYMENT" "$STAMP" "$T9_IMPORT_SUBTYPE")" \
  $'Saved service event - $88.40\n201' 'fixture 80 hand-entered service'
t9_import_shape="$(t9_event_shape "$T9_IMPORTED_AT")"
t9_hand_shape="$(t9_event_shape "$T9_HAND_AT")"
[ "$t9_import_shape" = '1 1 1 1 1 1 1 1 1 1' ] \
  || fail "fixture 80 imported event relation shape is wrong: $t9_import_shape"
[ "$t9_hand_shape" = "$t9_import_shape" ] \
  || fail "fixture 80 hand and import relation shapes differ: import=$t9_import_shape hand=$t9_hand_shape"
note "fixture 80 PASS - an imported service and a hand-entered service use the same parent, typed child, and eight association relations"

# ---------------------------------------------------------------------------
# fixture 81 - the exact document is a no-op the second time. Counts are
# scoped to this run's vehicle, not to a marker an earlier stamped run left.
# ---------------------------------------------------------------------------
t9_again="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-binary "$T9_IMPORT_DOCUMENT" \
  "$URL/apps/rover/import")"
case "$t9_again" in (*$'\n'200) ;; (*) fail "fixture 81 repeated import failed: $t9_again";; esac
grep -q 'Fills: imported 0, already-imported 4, conflicts 0, failures 0' <<<"$t9_again" \
  || fail "fixture 81 repeated fills were not recognized: $t9_again"
grep -q 'Events: imported 0, already-imported 2, conflicts 0' <<<"$t9_again" \
  || fail "fixture 81 repeated events were not recognized: $t9_again"
grep -q 'Reminders: imported 0, already-imported 1' <<<"$t9_again" \
  || fail "fixture 81 repeated reminder was not recognized: $t9_again"
grep -q 'Subtype defaults: created 0, reused 1' <<<"$t9_again" \
  || fail "fixture 81 repeated subtype default was not reused: $t9_again"
[ "$(count_rows "$(rover_report "FROM vehicles V WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT V.vehicle-id;")" '%vehicle-id')" = 1 ] \
  || fail "fixture 81 the import vehicle is not unique"
[ "$(count_rows "$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT E.event-id;")" '%event-id')" = 3 ] \
  || fail "fixture 81 repeated import duplicated or removed an event"
[ "$(count_rows "$(rover_report "FROM service-subtype-definitions S WHERE S.label = '$T9_IMPORT_SUBTYPE' SELECT S.service-subtype-id;")" '%service-subtype-id')" = 1 ] \
  || fail "fixture 81 the imported subtype definition is not unique"
note "fixture 81 PASS - re-import creates no second vehicle, fill, event, reminder, or subtype definition"

# ---------------------------------------------------------------------------
# fixture 82 - source defaults, the reminder intervals, and every one of the
# thirteen T7 specification children are present with their product shapes.
# ---------------------------------------------------------------------------
report="$(rover_report "FROM service-subtype-definitions S JOIN service-subtype-reminder-defaults D ON S.service-subtype-id = D.service-subtype-id WHERE S.label = '$T9_IMPORT_SUBTYPE' SELECT D.time-interval, D.time-unit, D.distance-digits, D.distance-decimals, D.distance-unit; FROM vehicles V JOIN service-reminders R ON V.vehicle-id = R.vehicle-id JOIN service-reminder-time T ON R.reminder-id = T.reminder-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT T.interval-count, T.interval-unit, T.due-at; FROM vehicles V JOIN service-reminders R ON V.vehicle-id = R.vehicle-id JOIN service-reminder-distance D ON R.reminder-id = D.reminder-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT D.interval-digits, D.interval-decimals, D.due-digits, D.due-decimals, D.distance-unit;")"
grep -q '%time-interval 25717 6.*%time-unit %tas %month.*%distance-digits 25717 5000.*%distance-decimals 25717 0.*%distance-unit %tas 26989' <<<"$report" \
  || fail "fixture 82 the imported subtype default is wrong: $report"
grep -q '%interval-count 25717 6.*%interval-unit %tas %month' <<<"$report" \
  || fail "fixture 82 the imported time reminder is wrong: $report"
grep -q '%interval-digits 25717 5000.*%interval-decimals 25717 0.*%due-digits 25717 46500.*%due-decimals 25717 0.*%distance-unit %tas 26989' <<<"$report" \
  || fail "fixture 82 the imported distance reminder is wrong: $report"
t9_spec_report="$(rover_report "FROM vehicles V JOIN vehicle-vin S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-license-plate S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-model-year S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-make S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-model S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-sub-model S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-body-type S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-color S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-engine S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-transmission S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-drive-type S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-bed-type S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id; FROM vehicles V JOIN vehicle-notes S ON V.vehicle-id = S.vehicle-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT S.vehicle-id;")"
t9_spec_counts="$(grep -oE '%vector-count [0-9]+' <<<"$t9_spec_report" | awk '{print $2}' | paste -sd' ' -)"
[ "$t9_spec_counts" = '1 1 1 1 1 1 1 1 1 1 1 1 1' ] \
  || fail "fixture 82 one of the thirteen specification children is absent: $t9_spec_counts"
note "fixture 82 PASS - source defaults, both reminder intervals, and all thirteen specification children land"

# ---------------------------------------------------------------------------
# fixture 83 - importing history does not invent ownership. The four imported
# fills are the T5 compatibility corpus, so the pre-T5 whole-history figures
# remain 80 best, 45 mean, 25 worst, and 25 last.
# ---------------------------------------------------------------------------
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-acquisitions A ON E.event-id = A.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT A.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-disposals D ON E.event-id = D.event-id WHERE V.label = '$T9_IMPORT_VEHICLE' SELECT D.event-id;")"
[ "$(grep -oE '%vector-count [0-9]+' <<<"$report" | awk '{print $2}' | paste -sd' ' -)" = '0 0' ] \
  || fail "fixture 83 import invented an ownership event: $report"
set_default_vehicle "$T9_IMPORT_VEHICLE"
view="$(eyre_view)"
[ "$(hub_readout 'BEST ECONOMY' <<<"$view")" = '80.000 mpg' ] \
  || fail "fixture 83 imported no-ownership history changed best economy"
[ "$(hub_readout 'ECONOMY - LIFETIME' <<<"$view")" = '45.000 mpg' ] \
  || fail "fixture 83 imported no-ownership history changed mean economy"
[ "$(hub_readout 'WORST ECONOMY' <<<"$view")" = '25.000 mpg' ] \
  || fail "fixture 83 imported no-ownership history changed worst economy"
[ "$(hub_readout 'ECONOMY - LAST FILL' <<<"$view")" = '25.000 mpg' ] \
  || fail "fixture 83 imported no-ownership history changed last-fill economy"
note "fixture 83 PASS - imported history creates no ownership events and keeps the pre-T5 whole-history derivation"

# ---------------------------------------------------------------------------
# M7 T10 - a complete Rover export uses the Rover import format.
#
# fixture 84 - the owner-only download endpoint and its browser control exist.
# The authenticated response is JSON with a download name. An unauthenticated
# request receives the same login redirect as every Rover write endpoint.
# ---------------------------------------------------------------------------
export_unauthenticated="$(curl -sS -D - -o /dev/null "$URL/apps/rover/export")"
grep -q '^HTTP/1.1 303 ' <<<"$export_unauthenticated" \
  || fail "fixture 84 an unauthenticated export request did not redirect to login: $export_unauthenticated"

export_headers="$(mktemp ${ROVER_TEST_TMP}/rover-export-headers.XXXXXX)"
export_document="$(mktemp ${ROVER_TEST_TMP}/rover-export-document.XXXXXX.json)"
export_status="$(curl -sS -b "$JAR" -D "$export_headers" -o "$export_document" -w '%{http_code}' \
  "$URL/apps/rover/export")"
[ "$export_status" = 200 ] \
  || fail "fixture 84 the authenticated export returned HTTP $export_status: $(cat "$export_document")"
grep -qi '^content-type: application/json' "$export_headers" \
  || fail "fixture 84 the export response is not JSON: $(cat "$export_headers")"
grep -qi '^content-disposition: attachment; filename="rover-export-' "$export_headers" \
  || fail "fixture 84 the export response has no Rover download name: $(cat "$export_headers")"
python3 -m json.tool "$export_document" >/dev/null \
  || fail "fixture 84 the export response is not valid JSON"
python3 - "$export_document" <<'PY' \
  || fail "fixture 84 the export source and attachment notice are incomplete"
import json
import pathlib
import sys

document = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert document["rover-import"] == 1
assert document["source"]["app"] == "Rover"
# M8, second leg. This endpoint serves the DOCUMENT alone, so its manifest
# says the photos are not in this file, counts them anyway, and names the
# download that does carry them. A false positive claim is worse than silence.
attachments = document["source"]["attachments"]
assert attachments["included"] is False
assert attachments["container"] == "tar"
assert attachments["directory"] == "attachments/"
assert attachments["download"] == "/apps/rover/export.tar"
assert "export.tar" in attachments["reason"]
assert int(attachments["photoCount"]) == len(attachments["files"])
assert int(attachments["photoCount"]) > 0
assert "manifest" not in attachments
for photo in attachments["files"]:
    # No path: this file holds no member for the path to name.
    assert "path" not in photo
    assert photo["name"]
    assert len(photo["hash"]) == 64
    assert int(photo["bytes"]) > 0
    assert photo["mediaType"]
assert document["source"]["omissions"] == []
PY
view="$(eyre_view)"
grep -q 'data-rover-export-download' <<<"$view" \
  || fail "fixture 84 the settings screen has no export download control"
export_browser_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/export-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie"
} 2>&1)" || fail "fixture 84 the browser could not download the export: $export_browser_out"
grep -q '^EXPORT_FILENAME=rover-export-complete.tar$' <<<"$export_browser_out" \
  || fail "fixture 84 the browser received the wrong filename: $export_browser_out"
grep -q '^EXPORT_FIRST_MEMBER=rover-import.json$' <<<"$export_browser_out" \
  || fail "fixture 84 the archive does not lead with the import document: $export_browser_out"
grep -q '^EXPORT_FORMAT=1$' <<<"$export_browser_out" \
  || fail "fixture 84 the browser download is not a Rover import: $export_browser_out"
grep -q '^EXPORT_SOURCE=Rover$' <<<"$export_browser_out" \
  || fail "fixture 84 the browser download does not name Rover: $export_browser_out"
grep -q '^EXPORT_ATTACHMENTS_INCLUDED=true$' <<<"$export_browser_out" \
  || fail "fixture 84 the browser download still says the photos were left behind: $export_browser_out"
browser_photo_count="$(sed -n 's/^EXPORT_PHOTO_COUNT=//p' <<<"$export_browser_out")"
browser_photo_members="$(sed -n 's/^EXPORT_PHOTO_MEMBERS=//p' <<<"$export_browser_out")"
[ -n "$browser_photo_count" ] && [ "$browser_photo_count" -gt 0 ] \
  || fail "fixture 84 the browser download names no photos: $export_browser_out"
[ "$browser_photo_count" = "$browser_photo_members" ] \
  || fail "fixture 84 the manifest names $browser_photo_count photos and the archive holds $browser_photo_members"
rm -f "$export_headers" "$export_document"
note "fixture 84 PASS - an authenticated owner presses the browser control and gets the named Rover archive, whose manifest names every photo it really carries, while unauthenticated requests redirect to login"

# ---------------------------------------------------------------------------
# fixture 85 - the export carries each stored record family and no derived
# value. This run leaves one synthetic tag archived so the payload must keep
# that display state instead of reviving the definition on the next ship.
# ---------------------------------------------------------------------------
t8_archive tag "$T8_LONE_TAG" 'fixture 85 archived export definition'
set_default_vehicle "$VEHICLE"
ROUNDTRIP_BEFORE="$(mktemp ${ROVER_TEST_TMP}/rover-export-before.XXXXXX.json)"
export_status="$(curl -sS -b "$JAR" -o "$ROUNDTRIP_BEFORE" -w '%{http_code}' \
  "$URL/apps/rover/export")"
[ "$export_status" = 200 ] \
  || fail "fixture 85 the complete export returned HTTP $export_status: $(cat "$ROUNDTRIP_BEFORE")"
python3 - "$ROUNDTRIP_BEFORE" "$VEHICLE" "$T8_VEHICLE" "$REM_VEHICLE" \
  "$SPEC_VEHICLE" "$T8_LONE_TAG" "$T8_FIELD" "$T8_FIELD_VALUE" <<'PY' \
  || fail "fixture 85 the export omitted a stored family, an archive flag, or a custom value"
import json
import pathlib
import sys

path, event_vehicle, t8_vehicle, reminder_vehicle, spec_vehicle, archived_tag, field, field_value = sys.argv[1:]
document = json.loads(pathlib.Path(path).read_text())
definitions = document["definitions"]
expected_definition_families = {
    "energy", "service-subtypes", "additives", "driving-modes", "tags",
    "payment-methods", "consumables", "disposal-kinds", "custom-fields",
}
assert expected_definition_families <= definitions.keys()
tag = next(row for row in definitions["tags"] if row["label"] == archived_tag)
assert tag["archived"] is True

vehicles = {row["label"]: row for row in document["vehicles"]}
event = vehicles[event_vehicle]
assert event["chargingSessions"]
assert any(len(row["subtypes"]) == 10 for row in event["serviceEvents"])
assert event["expenseEvents"] and event["noteEvents"]
assert event["acquisitionEvents"] and event["disposalEvents"]

t8 = vehicles[t8_vehicle]
assert t8["fills"] and t8["consumableAcquisitions"]
fill = t8["fills"][0]
assert fill["additives"] and fill["tags"]
custom = next(row for row in fill["customFields"] if row["label"] == field)
assert custom == {"label": field, "type": "text", "value": field_value}

assert vehicles[reminder_vehicle]["reminders"]
assert vehicles[spec_vehicle]["specification"]["specVin"].startswith("ROVERFAKEVIN")
assert document["places"]

forbidden = {
    "currentodometer", "economy", "fuelefficiency", "costpermile",
    "distancebetweenfills", "timebetweenfills", "derivedtotal",
}

def check(value):
    if isinstance(value, dict):
        assert forbidden.isdisjoint(key.lower() for key in value)
        for child in value.values():
            check(child)
    elif isinstance(value, list):
        for child in value:
            check(child)

check(document)
PY
note "fixture 85 PASS - the export carries every product record family, keeps an archived definition and a custom value, and carries no derived value"

# ---------------------------------------------------------------------------
# fixture 102 - the complete export is a tar the system `tar` command unpacks,
# and the `rover-import.json` inside it is the payload the JSON endpoint
# serves, byte for byte everywhere except the manifest.
#
# The second half is what makes the container honest. A reader who wants only
# the facts takes one member out and stops; nothing is re-serialized on the
# way into the archive, so the two cannot drift apart. The tar is fetched
# first and the JSON second, with no write between them.
#
# The two manifests differ ON PURPOSE and the difference is asserted exactly:
# the document says the photos are NOT included and names the archive that
# carries them. Everything else - every record, every definition, every field
# order and every separator - is still compared byte for byte, because a
# semantic comparison of the whole document would drop the formatting check
# this fixture exists for.
#
# Every photo in the archive is checked against the manifest that names it:
# the member is at the path the manifest gives, it is the size the manifest
# gives, and it hashes to the digest the manifest gives.
# ---------------------------------------------------------------------------
M8_EXPORT_TAR="$(mktemp ${ROVER_TEST_TMP}/rover-export-complete.XXXXXX.tar)"
M8_EXPORT_JSON="$(mktemp ${ROVER_TEST_TMP}/rover-export-member.XXXXXX.json)"
M8_UNPACKED="$(mktemp -d ${ROVER_TEST_TMP}/rover-export-unpacked.XXXXXX)"
tar_headers="$(mktemp ${ROVER_TEST_TMP}/rover-export-tar-headers.XXXXXX)"
tar_status="$(curl -sS -b "$JAR" -D "$tar_headers" -o "$M8_EXPORT_TAR" -w '%{http_code}' \
  "$URL/apps/rover/export.tar")"
[ "$tar_status" = 200 ] \
  || fail "fixture 102 the archive endpoint returned HTTP $tar_status"
json_status="$(curl -sS -b "$JAR" -o "$M8_EXPORT_JSON" -w '%{http_code}' \
  "$URL/apps/rover/export")"
[ "$json_status" = 200 ] \
  || fail "fixture 102 the JSON endpoint returned HTTP $json_status"
grep -qi '^content-type: application/x-tar' "$tar_headers" \
  || fail "fixture 102 the archive is not served as a tar: $(cat "$tar_headers")"
grep -qi '^content-disposition: attachment; filename="rover-export-complete.tar"' "$tar_headers" \
  || fail "fixture 102 the archive has no Rover download name: $(cat "$tar_headers")"
rm -f "$tar_headers"
# The system tar, not a reader Rover wrote. If the headers are wrong this is
# where it shows.
tar -tf "$M8_EXPORT_TAR" > /dev/null \
  || fail "fixture 102 the system tar cannot list the archive"
tar -xf "$M8_EXPORT_TAR" -C "$M8_UNPACKED" \
  || fail "fixture 102 the system tar cannot unpack the archive"
[ -f "$M8_UNPACKED/rover-import.json" ] \
  || fail "fixture 102 the archive holds no rover-import.json"
m8_manifest_diff="$(python3 - "$M8_UNPACKED/rover-import.json" "$M8_EXPORT_JSON" 2>&1 <<'PY'
# Excise the attachment manifest from each document by BYTE SPAN, compare
# everything that is left byte for byte, and then compare the two manifests
# field by field. A re-serialization that reorders a key anywhere else still
# fails the byte comparison.
import json
import sys

def source_manifest_span(raw):
    anchor = raw.index(b'"source":')
    start = raw.index(b'"attachments":', anchor) + len(b'"attachments":')
    assert raw[start:start + 1] == b"{", "the source manifest is not an object"
    depth, index, in_string, escaped = 0, start, False, False
    while index < len(raw):
        byte = raw[index:index + 1]
        if in_string:
            if escaped:
                escaped = False
            elif byte == b"\\":
                escaped = True
            elif byte == b'"':
                in_string = False
        elif byte == b'"':
            in_string = True
        elif byte == b"{":
            depth += 1
        elif byte == b"}":
            depth -= 1
            if depth == 0:
                return start, index + 1
        index += 1
    raise AssertionError("the source manifest never closes")

archive_raw = open(sys.argv[1], "rb").read()
document_raw = open(sys.argv[2], "rb").read()
archive_span = source_manifest_span(archive_raw)
document_span = source_manifest_span(document_raw)
archive_rest = archive_raw[:archive_span[0]] + archive_raw[archive_span[1]:]
document_rest = document_raw[:document_span[0]] + document_raw[document_span[1]:]
assert archive_rest == document_rest, "the two documents differ outside the manifest"

archive = json.loads(archive_raw[archive_span[0]:archive_span[1]])
document = json.loads(document_raw[document_span[0]:document_span[1]])
assert archive["included"] is True, "the archive manifest does not claim the photos"
assert document["included"] is False, "the document manifest claims photos it does not carry"
assert document["download"] == "/apps/rover/export.tar", document.get("download")
assert "export.tar" in document["reason"], document.get("reason")
assert "download" not in archive and "reason" not in archive, sorted(archive)
assert int(archive["photoCount"]) == int(document["photoCount"])
assert int(archive["photoCount"]) == len(archive["files"]) == len(document["files"])
# Every difference between the two manifests, named. Nothing else may differ.
changed = {key for key in set(archive) | set(document)
           if archive.get(key) != document.get(key)}
assert changed == {"included", "download", "reason", "files"}, sorted(changed)
by_name = {photo["name"]: photo for photo in document["files"]}
for photo in archive["files"]:
    twin = by_name[photo["name"]]
    assert photo["path"] == f"attachments/{photo['name']}", photo["name"]
    assert "path" not in twin, photo["name"]
    assert {key: photo[key] for key in ("name", "hash", "bytes", "mediaType")} == twin
print(f"PHOTOS={len(archive['files'])} BYTES_COMPARED={len(archive_rest)}")
PY
)" || fail "fixture 102 the archive member and the document endpoint disagree beyond the manifest: $m8_manifest_diff"
note "fixture 102 manifests - $m8_manifest_diff"
python3 - "$M8_UNPACKED" <<'PY' \
  || fail "fixture 102 the archive and its manifest disagree"
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
document = json.loads((root / "rover-import.json").read_text())
manifest = document["source"]["attachments"]
assert manifest["included"] is True
assert manifest["container"] == "tar"
photos = manifest["files"]
assert int(manifest["photoCount"]) == len(photos)
assert photos, "the manifest names no photo"
unpacked = sorted(str(p.relative_to(root)) for p in root.rglob("*") if p.is_file())
assert unpacked == sorted(["rover-import.json"] + [p["path"] for p in photos]), unpacked
for photo in photos:
    member = root / photo["path"]
    body = member.read_bytes()
    assert len(body) == int(photo["bytes"]), photo["name"]
    assert hashlib.sha256(body).hexdigest() == photo["hash"], photo["name"]
print(f"MEMBERS={len(unpacked)} PHOTOS={len(photos)}")
PY
tar_members="$(tar -tf "$M8_EXPORT_TAR" | wc -l)"
tar_photos="$(tar -tf "$M8_EXPORT_TAR" | grep -c '^attachments/')"
note "fixture 102 archive - $(wc -c < "$M8_EXPORT_TAR") bytes, $tar_members members, $tar_photos photos"
note "fixture 102 PASS - the complete export unpacks with the system tar, its rover-import.json is byte for byte the payload the JSON endpoint serves, and every photo matches the manifest that names it"

# The four attachment relations, counted by primary key. Obelisk returns sets,
# so both key columns are projected and the count is taken over one of them.
m8_attachment_counts() {
  printf '%s %s %s %s\n' \
    "$(count_rows "$(rover_report 'FROM attachments T SELECT T.attachment-id;')" '%attachment-id')" \
    "$(count_rows "$(rover_report 'FROM energy-acquisition-attachments L SELECT L.acquisition-id, L.attachment-id;')" '%attachment-id')" \
    "$(count_rows "$(rover_report 'FROM vehicle-event-attachments L SELECT L.event-id, L.attachment-id;')" '%attachment-id')" \
    "$(count_rows "$(rover_report 'FROM vehicle-attachments L SELECT L.vehicle-id, L.attachment-id;')" '%attachment-id')"
}
# What the source ship holds, read before fixture 86 puts it aside.
M8_ATTACHMENT_COUNTS_BEFORE="$(m8_attachment_counts)"

# ---------------------------------------------------------------------------
# fixture 113 - both download endpoints tell the truth about themselves.
#
# `/apps/rover/export` serves the document alone, so its manifest says the
# photos are NOT in this file and names the archive that carries them.
# `/apps/rover/export.tar` serves the archive, so its manifest says they are.
# Both counts are the count the database really holds, read from the relation
# by primary key rather than from either document.
#
# Ruling 19 says nothing is silently absent. A claim to carry photographs a
# file does not hold is worse than silence, because a reader who believes it
# stops looking for them.
# ---------------------------------------------------------------------------
m8_reference_count="$(awk '{print $1}' <<<"$M8_ATTACHMENT_COUNTS_BEFORE")"
[ -n "$m8_reference_count" ] && [ "$m8_reference_count" -gt 0 ] \
  || fail "fixture 113 the database holds no attachment reference to count"
m8_manifest_counts="$(python3 - "$M8_EXPORT_JSON" "$M8_UNPACKED/rover-import.json" "$m8_reference_count" 2>&1 <<'PY'
import json
import sys

document = json.loads(open(sys.argv[1], "rb").read())["source"]["attachments"]
archive = json.loads(open(sys.argv[2], "rb").read())["source"]["attachments"]
stored = int(sys.argv[3])

assert document["included"] is False, "the document claims to carry the photos"
assert document["download"] == "/apps/rover/export.tar", document.get("download")
assert "export.tar" in document["reason"], document.get("reason")
assert archive["included"] is True, "the archive disowns the photos it carries"

for name, manifest in (("document", document), ("archive", archive)):
    counted = int(manifest["photoCount"])
    assert counted == stored, f"{name} counts {counted}, the database holds {stored}"
    assert len(manifest["files"]) == stored, f"{name} names {len(manifest['files'])}"
print(f"DOCUMENT_INCLUDED=false ARCHIVE_INCLUDED=true PHOTO_COUNT={stored}")
PY
)" || fail "fixture 113 a manifest does not tell the truth about itself: $m8_manifest_counts"
note "fixture 113 manifests - $m8_manifest_counts"
note "fixture 113 PASS - the document manifest says the photos are not included and names the archive that carries them, the archive manifest says they are, and both counts are the count the database holds"
M8_MANIFEST="$(mktemp ${ROVER_TEST_TMP}/rover-export-manifest.XXXXXX)"
python3 - "$M8_UNPACKED/rover-import.json" > "$M8_MANIFEST" <<'PY'
import json
import pathlib
import sys

document = json.loads(pathlib.Path(sys.argv[1]).read_text())
for photo in document["source"]["attachments"]["files"]:
    print(photo["name"], photo["hash"], photo["bytes"])
PY
[ -s "$M8_MANIFEST" ] || fail "fixture 102 the manifest names no photo to round-trip"

# ---------------------------------------------------------------------------
# fixture 86 - the deciding round trip. Preserve the populated owner database
# under a temporary Obelisk name, initialize a fresh Rover database on the same
# real substrate, import the unmodified download, and compare relation
# counts, rendered history, archive state, and an order-independent re-export.
# The original database is restored after the proof and by the EXIT trap.
#
# M8 moved what the download is. The complete export is the archive fixture
# 102 pulled, and that is what goes back in here.
# ---------------------------------------------------------------------------
mapfile -t roundtrip_sql_chunks < <(
  python3 "$REPO/bin/export-semantic.py" count-sql \
    "$REPO/desk/lib/rover-act.hoon" "$REPO/docs/schema-m0.sql" --chunk-size 1
)
mapfile -t roundtrip_relations < <(
  python3 "$REPO/bin/export-semantic.py" relations "$REPO/desk/lib/rover-act.hoon"
)
[ "${#roundtrip_relations[@]}" = 101 ] \
  || fail "fixture 86 the count probe names ${#roundtrip_relations[@]} relations, want 101"

# The count probe reads one whole relation per query, and `click` cannot carry
# back an arbitrarily large result. This database grows every run, so a
# relation eventually outgrows one read and the probe returns nothing at all:
#
#   FROM odometer-observations X SELECT X.odometer-id;   ->  cue failed
#
# Measured at 656 rows on a pier with several runs behind it. That is the
# accumulation defect the two-run rule exists to find, and it reports as a
# missing count rather than a wrong one.
#
# A relation that will not read in one piece is counted in key ranges and the
# parts are added. The split is on the first projected column, which is the
# leading column of the primary key. Rover ids are random 128-bit, so the
# halves are even. A range that still will not read after six splits fails the
# fixture: a count this probe cannot take is never reported as zero.
roundtrip_count() {
  local relation="$1" projection="$2" column="$3" lo="$4" hi="$5" depth="${6:-0}"
  local predicate="" out value mid left right
  if [ -n "$lo" ] && [ -n "$hi" ]; then
    predicate=" WHERE X.$column >= $lo AND X.$column < $hi"
  elif [ -n "$lo" ]; then
    predicate=" WHERE X.$column >= $lo"
  elif [ -n "$hi" ]; then
    predicate=" WHERE X.$column < $hi"
  fi
  out="$(rover_report "FROM $relation X$predicate SELECT $projection;")"
  value="$(grep -oE '%vector-count [0-9]+' <<<"$out" | awk '{print $2}' | head -1)"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
    return 0
  fi
  [ "$depth" -ge 6 ] && return 1
  mid="$(python3 -c '
import sys


def bound(text, default):
    text = text.replace(".", "").replace("0x", "")
    return int(text, 16) if text else default


low = bound(sys.argv[1], 0)
high = bound(sys.argv[2], 1 << 128)
raw = format(low + (high - low) // 2, "032x")
print("0x" + ".".join(raw[i:i + 4] for i in range(0, len(raw), 4)))
' "$lo" "$hi")"
  left="$(roundtrip_count "$relation" "$projection" "$column" "$lo" "$mid" $((depth + 1)))" \
    || return 1
  right="$(roundtrip_count "$relation" "$projection" "$column" "$mid" "$hi" $((depth + 1)))" \
    || return 1
  printf '%s\n' "$((left + right))"
}

roundtrip_counts() {
  local target="$1" sql relation projection column
  : > "$target"
  for sql in "${roundtrip_sql_chunks[@]}"; do
    relation="$(sed -n 's/^FROM \([^ ]*\) X SELECT.*/\1/p' <<<"$sql")"
    projection="$(sed -n 's/^FROM [^ ]* X SELECT \(.*\);$/\1/p' <<<"$sql")"
    column="$(sed -n 's/^X\.\([a-z0-9-]*\).*/\1/p' <<<"$projection")"
    roundtrip_count "$relation" "$projection" "$column" '' '' 0 >> "$target"
  done
}

ROUNDTRIP_COUNTS_BEFORE="$(mktemp ${ROVER_TEST_TMP}/rover-export-counts-before.XXXXXX)"
roundtrip_counts "$ROUNDTRIP_COUNTS_BEFORE"
[ "$(wc -l < "$ROUNDTRIP_COUNTS_BEFORE")" = 101 ] \
  || fail "fixture 86 the source count probe did not return all 101 relations"

ROUNDTRIP_HISTORY_BEFORE="$(mktemp ${ROVER_TEST_TMP}/rover-export-history-before.XXXXXX)"
eyre_view | python3 "$REPO/bin/export-semantic.py" history > "$ROUNDTRIP_HISTORY_BEFORE"
[ -s "$ROUNDTRIP_HISTORY_BEFORE" ] \
  || fail "fixture 86 the source vehicle rendered no history cards"

database_report="$(obelisk_report sys 'FROM sys.sys.databases SELECT database;')"
database_exists "$database_report" "$ROUNDTRIP_BACKUP" \
  && fail "fixture 86 the temporary database $ROUNDTRIP_BACKUP already exists"
obelisk_report sys "ALTER DATABASE rover RENAME TO $ROUNDTRIP_BACKUP;" >/dev/null \
  || fail "fixture 86 could not isolate the populated Rover database"
ROUNDTRIP_SWAPPED=1
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null
database_report="$(obelisk_report sys 'FROM sys.sys.databases SELECT database;')"
database_exists "$database_report" rover \
  || fail "fixture 86 the fresh Rover database was not created"

# M8. The download is the archive, so the round trip takes the archive back.
# The document alone no longer carries everything the export carries, and a
# round trip that dropped the photos would report itself as equal.
#
# The request names a backend. M8's second leg stopped the import from
# choosing one: an archive that carries photographs is refused until the owner
# says where to keep them.
roundtrip_import="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/x-tar' --data-binary "@$M8_EXPORT_TAR" \
  "$URL/apps/rover/import?backend=clay")"
case "$roundtrip_import" in (*$'\n'200) ;; (*) fail "fixture 86 the exported file was not accepted unchanged: $roundtrip_import";; esac
grep -qE 'Photos: imported [0-9]+, already-imported [0-9]+, failures 0' <<<"$roundtrip_import" \
  || fail "fixture 86 a photo failed on the way into the fresh database: $roundtrip_import"
grep -q 'failures 0' <<<"$roundtrip_import" \
  || fail "fixture 86 the empty-database import reported a failed fill: $roundtrip_import"
grep -q 'conflicts 0' <<<"$roundtrip_import" \
  || fail "fixture 86 the empty-database import reported a conflict: $roundtrip_import"

set_default_vehicle "$VEHICLE"
ROUNDTRIP_HISTORY_AFTER="$(mktemp ${ROVER_TEST_TMP}/rover-export-history-after.XXXXXX)"
eyre_view | python3 "$REPO/bin/export-semantic.py" history > "$ROUNDTRIP_HISTORY_AFTER"
cmp -s "$ROUNDTRIP_HISTORY_BEFORE" "$ROUNDTRIP_HISTORY_AFTER" \
  || fail "fixture 86 the same vehicle did not render the same history after import"
[ "$(t8_archived_flag tag "$T8_LONE_TAG")" = 0 ] \
  || fail "fixture 86 the archived definition was resurrected"

ROUNDTRIP_AFTER="$(mktemp ${ROVER_TEST_TMP}/rover-export-after.XXXXXX.json)"
export_status="$(curl -sS -b "$JAR" -o "$ROUNDTRIP_AFTER" -w '%{http_code}' \
  "$URL/apps/rover/export")"
[ "$export_status" = 200 ] \
  || fail "fixture 86 the round-tripped database could not re-export: HTTP $export_status"
semantic_comparison="$(python3 "$REPO/bin/export-semantic.py" compare \
  "$ROUNDTRIP_BEFORE" "$ROUNDTRIP_AFTER")" \
  || fail "fixture 86 the two exports differ semantically: $semantic_comparison"
grep -q '^SEMANTIC_EQUAL=yes$' <<<"$semantic_comparison" \
  || fail "fixture 86 the semantic comparator did not report equality: $semantic_comparison"
while IFS= read -r line; do note "round-trip $line"; done <<<"$semantic_comparison"

ROUNDTRIP_COUNTS_AFTER="$(mktemp ${ROVER_TEST_TMP}/rover-export-counts-after.XXXXXX)"
roundtrip_counts "$ROUNDTRIP_COUNTS_AFTER"
[ "$(wc -l < "$ROUNDTRIP_COUNTS_AFTER")" = 101 ] \
  || fail "fixture 86 the destination count probe did not return all 101 relations"
cmp -s "$ROUNDTRIP_COUNTS_BEFORE" "$ROUNDTRIP_COUNTS_AFTER" \
  || fail "fixture 86 at least one relation count changed across the round trip"
paste <(printf '%s\n' "${roundtrip_relations[@]}") \
      "$ROUNDTRIP_COUNTS_BEFORE" "$ROUNDTRIP_COUNTS_AFTER" |
  while IFS=$'\t' read -r relation before after; do
    note "round-trip relation $relation: $before -> $after"
  done

note "fixture 86 PASS - an unchanged export archive imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal"

# ---------------------------------------------------------------------------
# fixture 103 - the round trip with the bytes. The database fixture 86 filled
# from the archive is still in place, so this is where the photos in it are
# read back and checked against what the source ship recorded.
#
# This extends fixture 86 rather than replacing it. Fixture 86 counts the 101
# relations the document carries; this counts the four the photos carry, on
# the same before-and-after terms, and then reads every photo back through the
# serving endpoint and compares its digest with the source manifest's.
#
# The archive goes in a second time first. Nothing may change: no record and
# no photo is written twice. An import that wrote a second copy of everything
# would show up right here.
# ---------------------------------------------------------------------------
roundtrip_archive="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/x-tar' --data-binary "@$M8_EXPORT_TAR" \
  "$URL/apps/rover/import?backend=clay")"
case "$roundtrip_archive" in
  (*$'\n'200) ;;
  (*) fail "fixture 103 the archive was not accepted: $roundtrip_archive";;
esac
grep -q 'Photos: imported' <<<"$roundtrip_archive" \
  || fail "fixture 103 the import report says nothing about photos: $roundtrip_archive"
grep -qE 'Photos: imported [0-9]+, already-imported [0-9]+, failures 0' <<<"$roundtrip_archive" \
  || fail "fixture 103 a photo failed to import: $roundtrip_archive"
grep -q 'Fills: imported 0' <<<"$roundtrip_archive" \
  || fail "fixture 103 the archive imported a second copy of a fill: $roundtrip_archive"
grep -q 'Photos: imported 0' <<<"$roundtrip_archive" \
  || fail "fixture 103 the archive stored a second copy of a photo: $roundtrip_archive"
archive_photos="$(sed -n 's/^Photos: imported \([0-9]*\).*/\1/p' <<<"$roundtrip_archive")"
archive_known="$(sed -n 's/^Photos: .*already-imported \([0-9]*\).*/\1/p' <<<"$roundtrip_archive")"
[ "$((archive_photos + archive_known))" = "$(wc -l < "$M8_MANIFEST")" ] \
  || fail "fixture 103 the archive carried $(wc -l < "$M8_MANIFEST") photos and the import accounted for $((archive_photos + archive_known))"
# Every photo, read back the way a browser reads one, and compared with the
# digest the SOURCE ship recorded before any of this started.
roundtrip_photo="$(mktemp ${ROVER_TEST_TMP}/rover-roundtrip-photo.XXXXXX)"
while read -r photo_name photo_hash photo_bytes; do
  photo_status="$(curl -sS -b "$JAR" -o "$roundtrip_photo" -w '%{http_code}' \
    "$URL/apps/rover/attachment/$(urlenc "$photo_name")")"
  [ "$photo_status" = 200 ] \
    || fail "fixture 103 $photo_name did not serve back on the destination: HTTP $photo_status"
  [ "$(wc -c < "$roundtrip_photo")" = "$photo_bytes" ] \
    || fail "fixture 103 $photo_name arrived as $(wc -c < "$roundtrip_photo") bytes, not $photo_bytes"
  [ "$(digest "$roundtrip_photo")" = "$photo_hash" ] \
    || fail "fixture 103 $photo_name arrived with a different digest than the source recorded"
done < "$M8_MANIFEST"
rm -f "$roundtrip_photo"
M8_ATTACHMENT_COUNTS_AFTER="$(m8_attachment_counts)"
[ "$M8_ATTACHMENT_COUNTS_AFTER" = "$M8_ATTACHMENT_COUNTS_BEFORE" ] \
  || fail "fixture 103 the attachment relations hold [$M8_ATTACHMENT_COUNTS_AFTER] after the round trip and held [$M8_ATTACHMENT_COUNTS_BEFORE] before it"
# No blob crossed with them. The destination relations are references too.
blob_probe="$(rover_report 'FROM attachments T SELECT T.attachment-id, T.backend, T.locator, T.content-hash, T.byte-count, T.media-type, T.file-name;')"
[ "$(printf '%s' "$blob_probe" | wc -c)" -lt 200000 ] \
  || fail "fixture 103 the destination attachments relation reads back blob-sized"
note "fixture 103 counts - attachments/energy/event/vehicle: $M8_ATTACHMENT_COUNTS_BEFORE -> $M8_ATTACHMENT_COUNTS_AFTER"
note "fixture 103 PASS - the archive imports into the database fixture 86 filled, every photo arrives with the digest and byte count the source recorded, the four attachment relation counts are equal, and re-reading the same archive writes no second record"

# ---------------------------------------------------------------------------
# fixture 111 - the import asks which backend, and honors the answer.
#
# It used to put every imported photograph in Clay. On an S3-configured ship
# that is the store the owner chose against, and the stated remedy was to
# attach all of them again by hand. For the real corpus that is 121
# photographs. A default that is expensive to undo is a decision made for the
# owner.
#
# BOTH choices are proved, and each one is read back out of the store it named
# rather than out of the reference row alone. The S3 half is read with a
# client that is not Rover.
#
# The archive is the export this run already made, with one photograph added
# to one vehicle. Every record in it is already imported, so the document
# phase writes nothing and the photo phase is what this fixture measures.
# ---------------------------------------------------------------------------
m8_backend_archive() {
  local target="$1" photo="$2" name="$3"
  python3 - "$M8_UNPACKED/rover-import.json" "$photo" "$name" "$target" <<'PHOTOTAR'
import hashlib
import io
import json
import pathlib
import sys
import tarfile

document = json.loads(pathlib.Path(sys.argv[1]).read_text())
body = pathlib.Path(sys.argv[2]).read_bytes()
name = sys.argv[3]


def strip(node):
    # Every photograph the source ship holds is already on the destination.
    # The archive names ONE and carries it, so the report reads plainly.
    if isinstance(node, dict):
        node.pop("attachments", None)
        for value in node.values():
            strip(value)
    elif isinstance(node, list):
        for value in node:
            strip(value)


for vehicle in document["vehicles"]:
    strip(vehicle)

# A photo OF THE VEHICLE. It hangs off no moment, which is the shortest
# address the import understands.
document["vehicles"][0]["attachments"] = [name]
document["source"]["attachments"]["files"] = [
    {
        "name": name,
        "path": "attachments/" + name,
        "hash": hashlib.sha256(body).hexdigest(),
        "bytes": str(len(body)),
        "mediaType": "image/png",
    }
]
document["source"]["attachments"]["photoCount"] = 1
payload = json.dumps(document).encode()

with tarfile.open(sys.argv[4], "w", format=tarfile.USTAR_FORMAT) as archive:
    for member, content in (
        ("rover-import.json", payload),
        ("attachments/" + name, body),
    ):
        info = tarfile.TarInfo(member)
        info.size = len(content)
        archive.addfile(info, io.BytesIO(content))
print(document["vehicles"][0]["label"])
PHOTOTAR
}

# The document the browser uploads. It names no photograph, so pressing Start
# import proves what the CONTROL sends without storing anything.
m8_photoless_document() {
  python3 - "$M8_EXPORT_JSON" "$1" <<'PHOTOLESS'
import json
import pathlib
import sys

document = json.loads(pathlib.Path(sys.argv[1]).read_text())


def strip(node):
    if isinstance(node, dict):
        node.pop("attachments", None)
        for value in node.values():
            strip(value)
    elif isinstance(node, list):
        for value in node:
            strip(value)


for vehicle in document["vehicles"]:
    strip(vehicle)
document["source"]["attachments"]["files"] = []
document["source"]["attachments"]["photoCount"] = 0
pathlib.Path(sys.argv[2]).write_text(json.dumps(document))
PHOTOLESS
}

m8_import_backend() {
  local archive="$1" backend="$2"
  curl -sS -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/x-tar' --data-binary "@$archive" \
    "$URL/apps/rover/import?backend=$backend"
}

M8_IMPORT_CLAY_PHOTO="${ROVER_TEST_TMP}/rover-m8-import-clay-$STAMP.png"
M8_IMPORT_S3_PHOTO="${ROVER_TEST_TMP}/rover-m8-import-s3-$STAMP.png"
python3 - "$M8_IMPORT_CLAY_PHOTO" "$M8_IMPORT_S3_PHOTO" <<'PNG'
import struct
import sys
import zlib


def png(path, red):
    width = height = 16
    raw = b"".join(
        b"\x00" + bytes([red, (row * 13) % 256, 90] * width) for row in range(height)
    )

    def chunk(tag, body):
        return (
            struct.pack(">I", len(body))
            + tag
            + body
            + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
        )

    open(path, "wb").write(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


png(sys.argv[1], 17)
png(sys.argv[2], 211)
PNG
M8_IMPORT_CLAY_NAME="import-clay-$STAMP.png"
M8_IMPORT_S3_NAME="import-s3-$STAMP.png"
M8_IMPORT_CLAY_HASH="$(digest "$M8_IMPORT_CLAY_PHOTO")"
M8_IMPORT_S3_HASH="$(digest "$M8_IMPORT_S3_PHOTO")"
[ "$M8_IMPORT_CLAY_HASH" != "$M8_IMPORT_S3_HASH" ] \
  || fail "fixture 111 the two photos are the same bytes, so the store cannot be told apart"

# An archive that carries a photograph and names no backend is refused, in
# human words, and it writes nothing.
M8_IMPORT_CLAY_TAR="${ROVER_TEST_TMP}/rover-m8-import-clay-$STAMP.tar"
M8_IMPORT_S3_TAR="${ROVER_TEST_TMP}/rover-m8-import-s3-$STAMP.tar"
m8_backend_archive "$M8_IMPORT_CLAY_TAR" "$M8_IMPORT_CLAY_PHOTO" "$M8_IMPORT_CLAY_NAME" >/dev/null \
  || fail "fixture 111 could not build the Clay import archive"
m8_backend_archive "$M8_IMPORT_S3_TAR" "$M8_IMPORT_S3_PHOTO" "$M8_IMPORT_S3_NAME" >/dev/null \
  || fail "fixture 111 could not build the S3 import archive"
unchosen="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/x-tar' --data-binary "@$M8_IMPORT_CLAY_TAR" \
  "$URL/apps/rover/import")"
case "$unchosen" in
  (*$'\n'400) ;;
  (*) fail "fixture 111 an archive with photos and no backend was not refused: $unchosen";;
esac
grep -q 'Choose where to keep them' <<<"$unchosen" \
  || fail "fixture 111 the refusal is not in human words: $unchosen"
grep -qE 'nest-fail|%bad-shape|%missing-key|0x[0-9a-f]{8}' <<<"$unchosen" \
  && fail "fixture 111 the refusal leaks a raw error or a machine id: $unchosen"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$M8_IMPORT_CLAY_NAME' SELECT T.attachment-id;")"
grep -q '%attachment-id' <<<"$report" \
  && fail "fixture 111 the refused import stored a photo anyway: $report"

# Choice one: Clay.
clay_import="$(m8_import_backend "$M8_IMPORT_CLAY_TAR" clay)"
case "$clay_import" in
  (*$'\n'200) ;;
  (*) fail "fixture 111 the Clay import was refused: $clay_import";;
esac
grep -q 'Photos: imported 1,' <<<"$clay_import" \
  || fail "fixture 111 the Clay import did not store exactly one photo: $clay_import"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$M8_IMPORT_CLAY_NAME' SELECT T.attachment-id, T.backend, T.locator;")"
backend_named "$report" clay \
  || fail "fixture 111 the imported photo did not land in Clay: $report"

# Choice two: S3, on the same archive shape and the same records.
s3_import="$(m8_import_backend "$M8_IMPORT_S3_TAR" s3)"
case "$s3_import" in
  (*$'\n'200) ;;
  (*) fail "fixture 111 the S3 import was refused: $s3_import";;
esac
grep -q 'Photos: imported 1,' <<<"$s3_import" \
  || fail "fixture 111 the S3 import did not store exactly one photo: $s3_import"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$M8_IMPORT_S3_NAME' SELECT T.attachment-id, T.backend, T.locator;")"
backend_named "$report" s3 \
  || fail "fixture 111 the imported photo did not land in S3: $report"
m8_s3_locator="$(grep -oE "%locator 116 '[^']*'" <<<"$report" | head -1 | sed "s/^.*'\(.*\)'$/\1/")"
[ -n "$m8_s3_locator" ] || fail "fixture 111 the S3 reference carries no locator: $report"
# Read it out of the bucket with a client that is not Rover.
m8_import_bucket="$(python3 - "$S3_ENDPOINT" "$m8_s3_locator" <<'BUCKET'
import sys, hashlib, boto3, botocore
endpoint, locator = sys.argv[1], sys.argv[2]
bucket, key = locator.lstrip("/").split("/", 1)
s3 = boto3.client("s3", endpoint_url=endpoint,
                  aws_access_key_id="roverm8key",
                  aws_secret_access_key="roverm8secret123",
                  region_name="us-east-1",
                  config=botocore.config.Config(s3={"addressing_style": "path"}))
body = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
print(hashlib.sha256(body).hexdigest(), len(body))
BUCKET
)" || fail "fixture 111 could not read the imported object out of the bucket"
[ "$(awk '{print $1}' <<<"$m8_import_bucket")" = "$M8_IMPORT_S3_HASH" ] \
  || fail "fixture 111 the object in the bucket is not the imported photo: $m8_import_bucket"
# Both serve back, byte for byte, whichever store holds them.
M8_IMPORT_BACK="${ROVER_TEST_TMP}/rover-m8-import-back-$STAMP.png"
[ "$(fetch_file "$M8_IMPORT_CLAY_NAME" "$M8_IMPORT_BACK")" = 200 ] \
  || fail "fixture 111 the Clay-imported photo did not serve back"
cmp -s "$M8_IMPORT_CLAY_PHOTO" "$M8_IMPORT_BACK" \
  || fail "fixture 111 the Clay-imported photo is not byte for byte the source"
[ "$(fetch_file "$M8_IMPORT_S3_NAME" "$M8_IMPORT_BACK")" = 200 ] \
  || fail "fixture 111 the S3-imported photo did not serve back"
cmp -s "$M8_IMPORT_S3_PHOTO" "$M8_IMPORT_BACK" \
  || fail "fixture 111 the S3-imported photo is not byte for byte the source"
rm -f "$M8_IMPORT_BACK"

# And the CONTROL on the import screen is what sends the answer. The browser
# drives the real screen and the request it makes is read off the wire.
M8_BROWSER_IMPORT_DOC="${ROVER_TEST_TMP}/rover-m8-import-document-$STAMP.json"
m8_photoless_document "$M8_BROWSER_IMPORT_DOC" \
  || fail "fixture 111 could not build the document the browser uploads"
import_backend_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/import-backend-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$M8_BROWSER_IMPORT_DOC" s3 send
} 2>&1)" || fail "fixture 111 the browser could not drive the import screen: $import_backend_out"
grep -qx 'IMPORT_BACKENDS=clay,s3' <<<"$import_backend_out" \
  || fail "fixture 111 the import screen does not offer both backends: $import_backend_out"
grep -q '^IMPORT_REQUEST=/apps/rover/import?backend=s3$' <<<"$import_backend_out" \
  || fail "fixture 111 the import screen did not send the owner's choice: $import_backend_out"
grep -qx 'IMPORT_REQUEST_COUNT_DISAGREEING=0' <<<"$import_backend_out" \
  || fail "fixture 111 a batch went out under a different backend: $import_backend_out"
note "fixture 111 backends - $(grep '^IMPORT_BACKENDS=' <<<"$import_backend_out"), bucket $m8_import_bucket"
note "fixture 111 PASS - the import asks once which backend to use, refuses an archive of photos that names none, and both choices land the photo in the store the owner named"

# ---------------------------------------------------------------------------
# fixture 112 - a ship with no %storage configuration offers Clay only, and
# says why in human words.
#
# The configuration is removed and put back, so this runs on a ship that is
# otherwise identical to the one fixture 111 just used.
# ---------------------------------------------------------------------------
storage_poke "[%set-access-key-id '']"
backends_json="$(curl -sS -b "$JAR" "$URL/apps/rover/backends.json")"
m8_backend_state="$(python3 - <<PY
import json
backends = {b["name"]: b for b in json.loads('''$backends_json''')["backends"]}
assert backends["clay"]["available"] is True, "Clay is not offered"
assert backends["s3"]["available"] is False, "S3 is offered on a ship with no bucket"
reason = backends["s3"]["reason"]
assert "no S3 storage set up yet" in reason, reason
assert "Landscape storage settings" in reason, reason
for token in ("nest-fail", "%bad-shape", "0x"):
    assert token not in reason, reason
print(reason)
PY
)" || fail "fixture 112 the backend route does not refuse S3 in human words: $backends_json"
# The endpoint refuses the choice the screen no longer offers.
refused="$(m8_import_backend "$M8_IMPORT_S3_TAR" s3)"
case "$refused" in
  (*$'\n'409) ;;
  (*) fail "fixture 112 an unconfigured ship accepted an S3 import: $refused";;
esac
grep -q 'no S3 storage set up yet' <<<"$refused" \
  || fail "fixture 112 the import refusal is not in human words: $refused"
# The screen offers Clay alone, and prints the reason the ship gave.
import_clay_only="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/import-backend-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$M8_BROWSER_IMPORT_DOC" clay hold
} 2>&1)" || fail "fixture 112 the browser could not read the import screen: $import_clay_only"
storage_poke "[%set-access-key-id '$S3_SAVED_KEY']"
grep -qx 'IMPORT_BACKENDS=clay' <<<"$import_clay_only" \
  || fail "fixture 112 the import screen still offers S3 with no bucket configured: $import_clay_only"
grep -q '^IMPORT_BACKEND_NOTE=.*no S3 storage set up yet' <<<"$import_clay_only" \
  || fail "fixture 112 the import screen does not say why S3 is missing: $import_clay_only"
grep -qx 'IMPORT_REQUEST_COUNT=0' <<<"$import_clay_only" \
  || fail "fixture 112 the screen sent an import it was only asked to read: $import_clay_only"
note "fixture 112 reason - $m8_backend_state"
note "fixture 112 PASS - a ship with no %storage configuration offers Clay only on the import screen, says why in human words, and the endpoint refuses the S3 choice the same way"
# ---------------------------------------------------------------------------
# fixture 115 - a batch of photographs into S3, and a bucket that refuses.
#
# Fixture 111 imports ONE photograph, so it cannot tell an import that answers
# after the last photograph from one that answers after the first. This one
# carries three, and the count in the answer is what proves the request waited
# for all of them.
#
# Then the same import meets a bucket that refuses. The rule is that one
# photograph which will not store never stops the rest, and the person still
# gets an answer. Two photographs go in and BOTH are named as failures, which
# is what proves the loop ran past the first refusal.
# ---------------------------------------------------------------------------
m8_png() {
  python3 - "$1" "$2" <<'PNG'
import struct
import sys
import zlib

path, red = sys.argv[1], int(sys.argv[2])
width = height = 16
raw = b"".join(
    b"\x00" + bytes([red, (row * 13) % 256, 90] * width) for row in range(height)
)


def chunk(tag, body):
    return (
        struct.pack(">I", len(body))
        + tag
        + body
        + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
    )


open(path, "wb").write(
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(raw, 9))
    + chunk(b"IEND", b"")
)
PNG
}

# One archive carrying SEVERAL photographs, all on the first vehicle. Every
# other record in it is already imported, so the photographs are the only work
# the run has left to do.
m8_batch_archive() {
  local target="$1"
  shift
  python3 - "$M8_UNPACKED/rover-import.json" "$target" "$@" <<'BATCHTAR'
import hashlib
import io
import json
import pathlib
import sys
import tarfile

document = json.loads(pathlib.Path(sys.argv[1]).read_text())
target = sys.argv[2]
pairs = sys.argv[3:]


def strip(node):
    if isinstance(node, dict):
        node.pop("attachments", None)
        for value in node.values():
            strip(value)
    elif isinstance(node, list):
        for value in node:
            strip(value)


for vehicle in document["vehicles"]:
    strip(vehicle)

names = []
bodies = {}
for pair in pairs:
    name, path = pair.split("=", 1)
    names.append(name)
    bodies[name] = pathlib.Path(path).read_bytes()

document["vehicles"][0]["attachments"] = names
document["source"]["attachments"]["files"] = [
    {
        "name": name,
        "path": "attachments/" + name,
        "hash": hashlib.sha256(bodies[name]).hexdigest(),
        "bytes": str(len(bodies[name])),
        "mediaType": "image/png",
    }
    for name in names
]
document["source"]["attachments"]["photoCount"] = len(names)
payload = json.dumps(document).encode()

with tarfile.open(target, "w", format=tarfile.USTAR_FORMAT) as archive:
    members = [("rover-import.json", payload)]
    members += [("attachments/" + name, bodies[name]) for name in names]
    for member, content in members:
        info = tarfile.TarInfo(member)
        info.size = len(content)
        archive.addfile(info, io.BytesIO(content))
BATCHTAR
}

# Read one object out of the bucket with a client that is not Rover.
m8_bucket_object() {
  python3 - "$S3_ENDPOINT" "$1" <<'BUCKET'
import sys, hashlib, boto3, botocore
endpoint, locator = sys.argv[1], sys.argv[2]
bucket, key = locator.lstrip("/").split("/", 1)
s3 = boto3.client("s3", endpoint_url=endpoint,
                  aws_access_key_id="roverm8key",
                  aws_secret_access_key="roverm8secret123",
                  region_name="us-east-1",
                  config=botocore.config.Config(s3={"addressing_style": "path"}))
body = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
print(hashlib.sha256(body).hexdigest(), len(body))
BUCKET
}

M8_BATCH_TAR="${ROVER_TEST_TMP}/rover-m8-batch-$STAMP.tar"
M8_BATCH_PAIRS=''
m8_batch_names=''
for m8_shade in 31 97 163; do
  m8_batch_photo="${ROVER_TEST_TMP}/rover-m8-batch-$m8_shade-$STAMP.png"
  m8_batch_name="batch-$m8_shade-$STAMP.png"
  m8_png "$m8_batch_photo" "$m8_shade"
  M8_BATCH_PAIRS="$M8_BATCH_PAIRS $m8_batch_name=$m8_batch_photo"
  m8_batch_names="$m8_batch_names $m8_batch_name"
done
m8_batch_archive "$M8_BATCH_TAR" $M8_BATCH_PAIRS \
  || fail "fixture 115 could not build the three-photo archive"
m8_batch_import="$(m8_import_backend "$M8_BATCH_TAR" s3)"
case "$m8_batch_import" in
  (*$'\n'200) ;;
  (*) fail "fixture 115 the three-photo S3 import was refused: $m8_batch_import";;
esac
# The count is the proof. An import that answered after the first photograph
# could not report three, and one that answered twice could not report any
# number at all, because the second answer has no request left to carry it.
grep -q 'Photos: imported 3, already-imported 0, failures 0' <<<"$m8_batch_import" \
  || fail "fixture 115 the batch did not answer after the last photograph: $m8_batch_import"
m8_batch_checked=0
for m8_batch_name in $m8_batch_names; do
  m8_shade="$(sed 's/^batch-\([0-9]*\)-.*/\1/' <<<"$m8_batch_name")"
  report="$(rover_report "FROM attachments T WHERE T.file-name = '$m8_batch_name' SELECT T.attachment-id, T.backend, T.locator;")"
  backend_named "$report" s3 \
    || fail "fixture 115 the batch photo $m8_batch_name did not land in S3: $report"
  m8_batch_locator="$(grep -oE "%locator 116 '[^']*'" <<<"$report" | head -1 | sed "s/^.*'\(.*\)'$/\1/")"
  [ -n "$m8_batch_locator" ] || fail "fixture 115 a batch reference carries no locator: $report"
  m8_batch_read="$(m8_bucket_object "$m8_batch_locator")" \
    || fail "fixture 115 could not read $m8_batch_name out of the bucket"
  [ "$(awk '{print $1}' <<<"$m8_batch_read")" \
    = "$(digest "${ROVER_TEST_TMP}/rover-m8-batch-$m8_shade-$STAMP.png")" ] \
    || fail "fixture 115 the object in the bucket is not $m8_batch_name: $m8_batch_read"
  m8_batch_checked=$((m8_batch_checked + 1))
done
[ "$m8_batch_checked" = 3 ] \
  || fail "fixture 115 checked $m8_batch_checked of the three batch photos"

# The refusal. The secret key is made wrong, so the bucket answers 403 for
# every PUT. The endpoint still accepts the import, because the ship IS
# configured for S3, and the report is where the failure is named.
#
# Every shade here is its own, and no other fixture generates it. Bytes this
# ship already holds take the reuse path and never reach the bucket, so a
# repeated shade would silently import instead of being refused.
M8_REFUSED_TAR="${ROVER_TEST_TMP}/rover-m8-refused-$STAMP.tar"
M8_REFUSED_PAIRS=''
m8_refused_names=''
for m8_shade in 43 149; do
  m8_refused_photo="${ROVER_TEST_TMP}/rover-m8-refused-$m8_shade-$STAMP.png"
  m8_refused_name="refused-$m8_shade-$STAMP.png"
  m8_png "$m8_refused_photo" "$m8_shade"
  M8_REFUSED_PAIRS="$M8_REFUSED_PAIRS $m8_refused_name=$m8_refused_photo"
  m8_refused_names="$m8_refused_names $m8_refused_name"
done
m8_batch_archive "$M8_REFUSED_TAR" $M8_REFUSED_PAIRS \
  || fail "fixture 115 could not build the refused archive"
storage_poke "[%set-secret-access-key 'wrong-secret-$STAMP']"
m8_refused_import="$(m8_import_backend "$M8_REFUSED_TAR" s3)"
storage_poke "[%set-secret-access-key 'roverm8secret123']"
case "$m8_refused_import" in
  (*$'\n'200) ;;
  (*) fail "fixture 115 a refusing bucket left the request unanswered: $m8_refused_import";;
esac
grep -q 'Photos: imported 0, already-imported 0, failures 2' <<<"$m8_refused_import" \
  || fail "fixture 115 the refusal did not fail exactly the two photographs: $m8_refused_import"
for m8_refused_name in $m8_refused_names; do
  grep -qF "Photo $m8_refused_name" <<<"$m8_refused_import" \
    || fail "fixture 115 the report does not name $m8_refused_name: $m8_refused_import"
  report="$(rover_report "FROM attachments T WHERE T.file-name = '$m8_refused_name' SELECT T.attachment-id;")"
  grep -q '%attachment-id' <<<"$report" \
    && fail "fixture 115 a refused photograph left a reference behind: $report"
done
grep -q 'S3 storage' <<<"$m8_refused_import" \
  || fail "fixture 115 the refusal is not in human words: $m8_refused_import"
# And the ship is not stuck. The next import runs, on the same records.
m8_after_refusal="$(m8_import_backend "$M8_BATCH_TAR" s3)"
case "$m8_after_refusal" in
  (*$'\n'200) ;;
  (*) fail "fixture 115 the ship refused the next import after a bucket refusal: $m8_after_refusal";;
esac
grep -q 'Photos: imported 0, already-imported 3, failures 0' <<<"$m8_after_refusal" \
  || fail "fixture 115 reading the same batch twice did not add nothing: $m8_after_refusal"
note "fixture 115 batch - three imported and read back out of the bucket, two refused and named"
note "fixture 115 PASS - a three-photograph S3 import answers once, after the last one, a bucket that refuses fails every photograph it refuses and still answers the request, and the run that follows a refusal still works"

# ---------------------------------------------------------------------------
# fixture 114 - everything M8 added survives a ship restart.
#
# Fixture 106 proves the ATTACH path across the first restart. Everything M8
# built after it - the import that carries photographs, the choice of backend,
# the complete archive and its manifest - had never met one. This is a SECOND
# restart, taken after those fixtures have run, so the state it reads is the
# state they left.
#
# The S3 half matters most. A reference the import wrote names bytes that are
# not on this ship, and reading it back after a restart is what proves the
# reference, the locator, and the credential path all survived together.
# ---------------------------------------------------------------------------
m8_restart_refs_before="$(count_rows "$(rover_report 'FROM attachments T SELECT T.attachment-id;')" '%attachment-id')"
[ -n "$m8_restart_refs_before" ] && [ "$m8_restart_refs_before" -gt 0 ] \
  || fail "fixture 114 the database holds no reference to carry across the restart"
restart_pier 114
auth_cookie_name="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $6; exit}' "$JAR")"
auth_cookie="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $7; exit}' "$JAR")"
[ -n "$auth_cookie" ] || fail "fixture 114 has no urbauth cookie after the restart"
m8_restart_refs_after="$(count_rows "$(rover_report 'FROM attachments T SELECT T.attachment-id;')" '%attachment-id')"
[ "$m8_restart_refs_after" = "$m8_restart_refs_before" ] \
  || fail "fixture 114 the reference count moved from $m8_restart_refs_before to $m8_restart_refs_after over the restart"

# Both imported photographs serve back, byte for byte, out of the store the
# owner named for each.
M8_RESTART_BACK="${ROVER_TEST_TMP}/rover-m8-restart-back-$STAMP.png"
[ "$(fetch_file "$M8_IMPORT_CLAY_NAME" "$M8_RESTART_BACK")" = 200 ] \
  || fail "fixture 114 the Clay-imported photo did not serve back after the restart"
cmp -s "$M8_IMPORT_CLAY_PHOTO" "$M8_RESTART_BACK" \
  || fail "fixture 114 the Clay-imported photo is not byte for byte the source after the restart"
[ "$(fetch_file "$M8_IMPORT_S3_NAME" "$M8_RESTART_BACK")" = 200 ] \
  || fail "fixture 114 the S3-imported photo did not serve back after the restart"
cmp -s "$M8_IMPORT_S3_PHOTO" "$M8_RESTART_BACK" \
  || fail "fixture 114 the S3-imported photo is not byte for byte the source after the restart"
rm -f "$M8_RESTART_BACK"
report="$(rover_report "FROM attachments T WHERE T.file-name = '$M8_IMPORT_S3_NAME' SELECT T.attachment-id, T.backend, T.locator;")"
backend_named "$report" s3 \
  || fail "fixture 114 the imported S3 reference no longer names its backend: $report"

# The backend question the import asks is still answered the same way.
M8_RESTART_BACKENDS="${ROVER_TEST_TMP}/rover-m8-restart-backends-$STAMP.json"
curl -sS -b "$JAR" -o "$M8_RESTART_BACKENDS" "$URL/apps/rover/backends.json"
m8_restart_offers="$(python3 - "$M8_RESTART_BACKENDS" 2>&1 <<'PY'
import json
import sys

backends = {b["name"]: b for b in json.load(open(sys.argv[1]))["backends"]}
assert backends["clay"]["available"] is True, "Clay is not offered after the restart"
assert backends["s3"]["available"] is True, "S3 is not offered after the restart"
print("BACKENDS=clay,s3")
PY
)" || fail "fixture 114 the backend route changed over the restart: $m8_restart_offers"
rm -f "$M8_RESTART_BACKENDS"

# The complete archive still serves, and its manifest still tells the truth
# about the photographs the database holds.
M8_RESTART_TAR="${ROVER_TEST_TMP}/rover-m8-restart-export-$STAMP.tar"
m8_restart_status="$(curl -sS -b "$JAR" -o "$M8_RESTART_TAR" -w '%{http_code}' "$URL/apps/rover/export.tar")"
[ "$m8_restart_status" = 200 ] \
  || fail "fixture 114 the archive endpoint answered $m8_restart_status after the restart"
m8_restart_manifest="$(python3 - "$M8_RESTART_TAR" "$m8_restart_refs_after" <<'PY'
import json
import sys
import tarfile

with tarfile.open(sys.argv[1]) as archive:
    names = archive.getnames()
    document = json.loads(archive.extractfile("rover-import.json").read())

manifest = document["source"]["attachments"]
stored = int(sys.argv[2])
assert manifest["included"] is True, "the archive disowns the photos it carries"
assert int(manifest["photoCount"]) == stored, f'{manifest["photoCount"]} against {stored}'
carried = [name for name in names if name.startswith("attachments/")]
assert len(carried) == stored, f"{len(carried)} members against {stored} references"
print(f"MEMBERS={len(names)} PHOTOS={len(carried)}")
PY
)" || fail "fixture 114 the archive manifest is not true after the restart: $m8_restart_manifest"
rm -f "$M8_RESTART_TAR"

# And an import with photographs still works on the far side. Re-reading the
# batch adds nothing, which is the same rule ruling 18 gives every record.
m8_restart_import="$(m8_import_backend "$M8_BATCH_TAR" s3)"
case "$m8_restart_import" in
  (*$'\n'200) ;;
  (*) fail "fixture 114 an S3 import was refused after the restart: $m8_restart_import";;
esac
grep -q 'Photos: imported 0, already-imported 3, failures 0' <<<"$m8_restart_import" \
  || fail "fixture 114 the batch was not recognised after the restart: $m8_restart_import"
note "fixture 114 restart - $m8_restart_refs_after references, $m8_restart_manifest"
note "fixture 114 PASS - every imported photograph, both backends, the archive and its manifest survived a second ship restart, and an S3 import still answers after it"
rm -f "$M8_BATCH_TAR" "$M8_REFUSED_TAR"
rm -f ${ROVER_TEST_TMP}/rover-m8-batch-*-"$STAMP".png ${ROVER_TEST_TMP}/rover-m8-refused-*-"$STAMP".png

rm -f "$M8_IMPORT_CLAY_PHOTO" "$M8_IMPORT_S3_PHOTO" "$M8_IMPORT_CLAY_TAR" "$M8_IMPORT_S3_TAR"
rm -f "$M8_BROWSER_IMPORT_DOC"

rm -f "$M8_MANIFEST" "$M8_EXPORT_TAR" "$M8_EXPORT_JSON"
rm -rf "$M8_UNPACKED"

restore_roundtrip_owner \
  || fail "fixture 86 could not restore the populated pre-round-trip database"

# ---------------------------------------------------------------------------
# fixture 104 - the owner's real corpus loads. 121 photos against 114 records,
# stored bytes hashing equal to the source bytes, on a real pier.
#
# The corpus is the owner's own data. This fixture reports COUNTS and never a
# file name, a label, a date, or a digest out of it.
#
# It runs in a database of its own, put in place the way fixture 86 puts one
# in place. Two reasons: the owner's history is not the battery's data, and a
# battery that ran twice would otherwise meet a different state the second
# time. Here the second run does exactly what the first one did.
#
# The load goes through `/apps/rover/add-attachment`, the same endpoint a
# browser calls. An import has no privileged path.
# ---------------------------------------------------------------------------
CORPUS_SOURCE="${ROVER_CORPUS:-$HOME/workspace/rover/aCar export}"
CORPUS_OUT="${ROVER_CORPUS_OUT:-$ROVER_TEST_TMP/converted-corpus}"
[ -d "$CORPUS_SOURCE" ] \
  || fail "fixture 104 the real corpus is not at $CORPUS_SOURCE - this fixture does not run on synthetic data"
rm -rf "$CORPUS_OUT"
python3 "$REPO/tools/acar-import/convert.py" --out "$CORPUS_OUT" "$CORPUS_SOURCE" > /dev/null \
  || fail "fixture 104 the converter could not read the corpus"
[ -f "$CORPUS_OUT/rover-import.json" ] && [ -f "$CORPUS_OUT/attachments.json" ] \
  || fail "fixture 104 the converter wrote no import document or no photo manifest"
corpus_photos="$(python3 -c '
import json, sys
document = json.load(open(sys.argv[1]))
entries = document["attachments"] if isinstance(document, dict) else document
print(len(entries))
' "$CORPUS_OUT/attachments.json")"
[ "$corpus_photos" = 121 ] \
  || fail "fixture 104 the corpus holds $corpus_photos photos, and this fixture is written against 121"

database_report="$(obelisk_report sys 'FROM sys.sys.databases SELECT database;')"
database_exists "$database_report" "$CORPUS_BACKUP" \
  && fail "fixture 104 the temporary database $CORPUS_BACKUP already exists"
obelisk_report sys "ALTER DATABASE rover RENAME TO $CORPUS_BACKUP;" >/dev/null \
  || fail "fixture 104 could not put the battery database aside"
CORPUS_SWAPPED=1
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null
database_report="$(obelisk_report sys 'FROM sys.sys.databases SELECT database;')"
database_exists "$database_report" rover \
  || fail "fixture 104 the corpus database was not created"

corpus_import="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-binary "@$CORPUS_OUT/rover-import.json" \
  "$URL/apps/rover/import")"
case "$corpus_import" in
  (*$'\n'200) ;;
  (*) fail "fixture 104 the corpus document was refused: $(tail -3 <<<"$corpus_import")";;
esac
grep -q 'failures 0' <<<"$corpus_import" \
  || fail "fixture 104 the corpus document import reported a failure"

# The pier is measured on either side of the PHOTO load alone, so the figure
# is the cost of the bytes and not the cost of the records they hang off.
corpus_pier_before="$(du -sb "$PIER" | awk '{print $1}')"
corpus_cookie_name="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $6; exit}' "$JAR")"
corpus_cookie="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $7; exit}' "$JAR")"
[ -n "$corpus_cookie" ] || fail "fixture 104 has no urbauth cookie for the loader"
corpus_out="$(python3 "$REPO/tools/rover-import/attachments.py" \
  "$CORPUS_OUT/attachments.json" --url "$URL" \
  --cookie "$corpus_cookie_name=$corpus_cookie" --backend clay --verify 2>&1)" \
  || fail "fixture 104 the corpus photo load refused or mismatched: $(grep -c . <<<"$corpus_out") lines reported"
corpus_pier_after="$(du -sb "$PIER" | awk '{print $1}')"
for want in ATTACHMENTS_IN_MANIFEST=121 ATTACHMENTS_STORED=121 ATTACHMENTS_ALREADY=0 \
  ATTACHMENTS_REFUSED=0 ATTACHMENTS_FILL=116 ATTACHMENTS_EVENT=3 ATTACHMENTS_VEHICLE=2 \
  ATTACHMENTS_VERIFIED=121 ATTACHMENTS_MISMATCHED=0; do
  grep -qx "$want" <<<"$corpus_out" \
    || fail "fixture 104 the corpus load did not report $want: $(grep '^ATTACHMENTS_' <<<"$corpus_out" | tr '\n' ' ')"
done
# One photo in the corpus is a byte-identical duplicate of another, under its
# own name. Both names are kept and the bytes are stored once, so the count of
# distinct digests is one lower than the count of photos.
grep -qx 'ATTACHMENTS_DISTINCT_DIGESTS=120' <<<"$corpus_out" \
  || fail "fixture 104 the corpus digests do not show the one known duplicate: $(grep '^ATTACHMENTS_DIST' <<<"$corpus_out")"

# What the database holds: one reference per photo, and the records they hang
# off counted by distinct owner id across the three link relations.
corpus_refs="$(count_rows "$(rover_report 'FROM attachments T SELECT T.attachment-id;')" '%attachment-id')"
[ "$corpus_refs" = 121 ] \
  || fail "fixture 104 the corpus left $corpus_refs references, want 121"
corpus_owners=0
for pair in 'energy-acquisition-attachments L acquisition-id' \
  'vehicle-event-attachments L event-id' 'vehicle-attachments L vehicle-id'; do
  set -- $pair
  report="$(rover_report "FROM $1 $2 SELECT $2.$3, $2.attachment-id;")"
  owners="$(grep -oE "%$3 [0-9]+ [0-9a-fx.]+" <<<"$report" | sort -u | wc -l)"
  corpus_owners=$((corpus_owners + owners))
done
[ "$corpus_owners" = 114 ] \
  || fail "fixture 104 the corpus photos hang off $corpus_owners records, want 114"
# And no blob went in with them.
blob_probe="$(rover_report 'FROM attachments T SELECT T.attachment-id, T.backend, T.locator, T.content-hash, T.byte-count, T.media-type, T.file-name;')"
[ "$(printf '%s' "$blob_probe" | wc -c)" -lt 200000 ] \
  || fail "fixture 104 the corpus attachments relation reads back blob-sized"

# The same load, run again. Ruling 18 applied to photos: it adds nothing.
corpus_again="$(python3 "$REPO/tools/rover-import/attachments.py" \
  "$CORPUS_OUT/attachments.json" --url "$URL" \
  --cookie "$corpus_cookie_name=$corpus_cookie" --backend clay 2>&1)" \
  || fail "fixture 104 the second corpus load refused a photo"
grep -qx 'ATTACHMENTS_STORED=0' <<<"$corpus_again" \
  || fail "fixture 104 the second load stored a photo again: $(grep '^ATTACHMENTS_STORED' <<<"$corpus_again")"
grep -qx 'ATTACHMENTS_ALREADY=121' <<<"$corpus_again" \
  || fail "fixture 104 the second load did not recognise all 121 photos: $(grep '^ATTACHMENTS_ALREADY' <<<"$corpus_again")"
corpus_refs_again="$(count_rows "$(rover_report 'FROM attachments T SELECT T.attachment-id;')" '%attachment-id')"
[ "$corpus_refs_again" = 121 ] \
  || fail "fixture 104 the second load changed the reference count to $corpus_refs_again"

note "fixture 104 corpus - 121 photos, 116 fill, 3 event, 2 vehicle, 120 distinct digests, 114 records"
note "fixture 104 pier - $corpus_pier_before bytes before the photo load, $corpus_pier_after after, growth $((corpus_pier_after - corpus_pier_before))"
restore_corpus_owner \
  || fail "fixture 104 could not restore the battery database"
rm -rf "$CORPUS_OUT"
note "fixture 104 PASS - the real corpus loads through the product endpoint: 121 photos against 114 records, every stored photo hashing equal to its source, and a second load adding nothing"


# ---------------------------------------------------------------------------
# fixture 116 - a fill card shows its mileage and its DERIVED economy, and a
# photograph can reach a record that already exists
# ---------------------------------------------------------------------------
# Three M9 repairs, and the reason they are one fixture: all three were
# invisible to 115 fixtures that assert on served HTML, because a fixture
# cannot see a field that was never written.
#
# The owner found them by reading his own 420 fills. Every card showed no
# mileage and the same sentence, economy unavailable. Nothing was missing from
# the database: 420 fills, 420 odometer links. Two renderers disagreed.
# +history-row always took the odometer links; +fill-card took neither them nor
# the derivations, so it rendered no mileage and inferred economy from the
# PRESENCE of a break row. That inference ran backwards. A break row is the
# thing that says an interval cannot be derived, so its absence is the licence
# to show a figure.
#
# Economy is DERIVED, never imported. Two full fills on one vehicle with
# odometer readings are all Rover needs, and the second card must carry a real
# number computed from the distance and the volume between them.
note "fixture 116 - mileage, derived economy, and a photo on an existing record"

ECONOMY_VEHICLE="Economy Vehicle $STAMP"
eyre_post add-vehicle \
  "$(printf '{"label":"%s","energy":"Gasoline","distanceUnit":"mi","volumeUnit":"gal"}' "$ECONOMY_VEHICLE")" \
  "$(printf 'Added vehicle - %s\n201' "$ECONOMY_VEHICLE")" \
  'fixture 116 the economy vehicle'

# Two full fills, 300 miles apart, the second taking 15 gallons. 300 / 15 is
# exactly 20 mpg, so the rendered figure is checked against arithmetic done
# here rather than against whatever the card happens to print.
economy_fill() {
  # observed mileage quantity note label expected
  eyre_post add-fill \
    "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"%s","price":"$3.00","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"%s","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"fuel","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"%s","paymentMethod":""}' \
      "$ECONOMY_VEHICLE" "$3" "$1" "$2" "$4")" \
    "$5" "fixture 116 $6"
}
economy_fill '2026-08-01T09:00' '40000' '10.000' "econ-first-$STAMP" \
  "$(printf 'Saved fill - $3.009 - derived $30.09\n201')" 'the first fill'
economy_fill '2026-08-15T09:00' '40300' '15.000' "econ-second-$STAMP" \
  "$(printf 'Saved fill - $3.009 - derived $45.14\n201')" 'the second fill'

view="$(eyre_view)"

# The first fill has no earlier fill to measure from, so it is honestly
# unavailable. The second has one, and must show a figure.
first_card="$(fill_card_with 'data-photo-observed="2026-08-01T09:00"')"
[ -n "$first_card" ] || fail "fixture 116 the first fill card is not in the view"
second_card="$(fill_card_with 'data-photo-observed="2026-08-15T09:00"')"
[ -n "$second_card" ] || fail "fixture 116 the second fill card is not in the view"

# MILEAGE. The field has to EXIST and carry the figure that was entered. This
# is the assertion whose absence let the defect ship.
grep -q '<dt>MILEAGE</dt>' <<<"$second_card" \
  || fail "fixture 116 the fill card renders no MILEAGE field at all: $second_card"
second_mileage="$(sed -n 's/.*<dt>MILEAGE<\/dt><dd>\([^<]*\)<.*/\1/p' <<<"$second_card")"
[ "$second_mileage" = '40,300 mi' ] \
  || fail "fixture 116 the second fill shows mileage '$second_mileage', want '40,300 mi'"
first_mileage="$(sed -n 's/.*<dt>MILEAGE<\/dt><dd>\([^<]*\)<.*/\1/p' <<<"$first_card")"
[ "$first_mileage" = '40,000 mi' ] \
  || fail "fixture 116 the first fill shows mileage '$first_mileage', want '40,000 mi'"

# ECONOMY, derived. 300 miles on 15.000 gallons is 20 mpg exactly.
second_economy="$(sed -n 's/.*<dt>ECONOMY<\/dt><dd>\([^<]*\)<.*/\1/p' <<<"$second_card")"
[ "$second_economy" = '20.000 mpg' ] \
  || fail "fixture 116 the second fill shows economy '$second_economy', want '20.000 mpg'"

# And the card that genuinely cannot derive one says so, without claiming a
# break that does not exist.
first_economy="$(sed -n 's/.*<dt>ECONOMY<\/dt><dd>\([^<]*\)<.*/\1/p' <<<"$first_card")"
case "$first_economy" in
  Unavailable*) : ;;
  *) fail "fixture 116 the first fill shows economy '$first_economy', want an unavailability" ;;
esac
# The old inverted sentence must be gone from every card in the document. It
# was printed whenever NO break row existed, which is almost every fill.
grep -q 'another eligible full fill is required' <<<"$view" \
  && fail "fixture 116 the inverted economy sentence is still served"

# A photograph can reach a record that already exists. Until M9 the only way to
# attach one was at creation, so an imported record could never gain one.
# The history screen serves the rows of ONE vehicle, the selected one, so
# this fixture asks for its own vehicle's view rather than reading the
# default one. `fill_edit_form` is scoped to the T8 vehicle by design and
# three earlier fixtures depend on that, so it is left alone.
economy_view="$(scoped_event_view "$ECONOMY_VEHICLE")"
edit_form="$(python3 -c '
import re, sys
document = sys.stdin.read()
found = re.search(
    r"<article class=\"history-table-row\" data-history-vehicle=\"%s\".*?</article>"
    % re.escape(sys.argv[1]), document, re.S)
sys.stdout.write(found.group(0) if found else "")
' "$ECONOMY_VEHICLE" <<<"$economy_view")"
[ -n "$edit_form" ] || fail "fixture 116 the history edit form is not in the view"
grep -q 'data-photo-field="history"' <<<"$edit_form" \
  || fail "fixture 116 the history edit form carries no photo field"

# The camera stays a menu, not a camera. `accept="image/*"` alone makes a phone
# offer the camera BESIDE the photo library; `capture` forces camera-only and
# removes the library, which is how most of a corpus arrives.
grep -q 'accept="image/\*"' <<<"$edit_form" \
  || fail "fixture 116 the history photo input does not accept an image"
grep -q 'capture=' <<<"$view" \
  && fail "fixture 116 a capture attribute is served, which would force camera-only"

# The photo really attaches, through the endpoint the form calls.
econ_photo="fixture-116-$STAMP.jpg"
printf '\377\330\377\340\000\020JFIF\000\001\001\000\000\001\000\001\000\000\377\331' \
  > "${ROVER_TEST_TMP}/$econ_photo"
econ_query="owner=fill&vehicle=$(printf '%s' "$ECONOMY_VEHICLE" | sed 's/ /+/g')"
econ_query="$econ_query&file=$econ_photo&type=image/jpeg&backend=clay"
econ_query="$econ_query&observed=2026-08-15T09:00"
attach_status="$(curl -s -o ${ROVER_TEST_TMP}/attach-116.txt -w '%{http_code}' -b "$JAR" \
  -X POST -H 'content-type: image/jpeg' --data-binary "@${ROVER_TEST_TMP}/$econ_photo" \
  "$URL/apps/rover/add-attachment?$econ_query")"
[ "$attach_status" = 201 ] \
  || fail "fixture 116 attaching to an existing fill answered $attach_status: $(cat ${ROVER_TEST_TMP}/attach-116.txt)"
readback="$(curl -s -o ${ROVER_TEST_TMP}/attach-116-back.jpg -w '%{http_code}' -b "$JAR" \
  "$URL/apps/rover/attachment/$econ_photo")"
[ "$readback" = 200 ] \
  || fail "fixture 116 the attached photo did not read back: HTTP $readback"
cmp -s "${ROVER_TEST_TMP}/$econ_photo" ${ROVER_TEST_TMP}/attach-116-back.jpg \
  || fail "fixture 116 the attached photo read back with different bytes"
rm -f "${ROVER_TEST_TMP}/$econ_photo" ${ROVER_TEST_TMP}/attach-116.txt ${ROVER_TEST_TMP}/attach-116-back.jpg

note "fixture 116 PASS - mileage 40,000 and 40,300 mi, economy 20.000 mpg derived from 300 mi on 15.000 gal, and a photo attached to a record that already existed"

. "$(dirname "$0")/event-coverage-gate.sh"
