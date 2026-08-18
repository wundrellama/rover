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
JAR="$(mktemp /tmp/rover-event-test-jar.XXXXXX)"
trap 'rm -f "$JAR"' EXIT

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

click_file() {
  local body="$1" file out
  file="$(mktemp /tmp/rover-event-test.XXXXXX.hoon)"
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
rover_report() {
  local script="$1"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-event-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector \"$script\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
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
  local relation="$1" alias="$2" column="$3" observed="$4"
  rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN $relation $alias ON E.event-id = $alias.event-id WHERE V.label = '$VEHICLE' AND E.observed-start = $observed SELECT $alias.$column;"
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
  vehicle-event-notes energy-acquisition-odometers service-reminders \
  reminder-time-intervals reminder-distance-intervals \
  reminder-service-events service-subtype-time-defaults \
  service-subtype-distance-defaults; do
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
# M7 T6 - reminders are stored facts with a read-time due derivation. These
# three vehicles separate an ordinary odometer crossing, no-reading state, and
# a buy-sell-rebuy ownership gap. Every name carries this run's stamp.
# ---------------------------------------------------------------------------
REMINDER_VEHICLE="Reminder Vehicle $STAMP"
REMINDER_EMPTY_VEHICLE="Reminder Empty Vehicle $STAMP"
REMINDER_GAP_VEHICLE="Reminder Gap Vehicle $STAMP"

reminder_payload() {
  # vehicle subtype timeInterval timeUnit timeDue distanceInterval distanceDue unit
  printf '{"vehicle":"%s","subtype":"%s","timeInterval":"%s","timeUnit":"%s","timeDue":"%s","distanceInterval":"%s","distanceDue":"%s","distanceUnit":"%s"}' \
    "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}

add_reminder() {
  eyre_post add-reminder "$1" $'Saved reminder\n201' "$2"
}

add_reminder_odometer() {
  # vehicle reading observed
  local response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s","reading":"%s","unit":"mi","observed":"%s","zone":"America/Chicago"}' "$1" "$2" "$3")" \
    "$URL/apps/rover/add-odometer")"
  case "$response" in
    Saved\ odometer\ -*$'\n'201) ;;
    *) fail "$4: $response" ;;
  esac
}

reminder_card() {
  python3 -c '
import re, sys
document = sys.stdin.read()
label = sys.argv[1]
for match in re.finditer(r"<article class=\"reminder-card\".*?</article>", document, re.S):
    if match.group(0).find("data-reminder=\"%s\"" % label) >= 0:
        sys.stdout.write(match.group(0))
        break
' "$1"
}

own_add_vehicle "$REMINDER_VEHICLE" Gasoline
own_add_vehicle "$REMINDER_EMPTY_VEHICLE" Gasoline
own_add_vehicle "$REMINDER_GAP_VEHICLE" Gasoline

# ---------------------------------------------------------------------------
# fixture 44 - time, distance, and both shapes save through Eyre. The
# time-only reminder has no distance child row at all, not a zero row.
# ---------------------------------------------------------------------------
add_reminder_odometer "$REMINDER_VEHICLE" 900 '2026-08-10T09:00' 'fixture 44 initial odometer'
add_reminder "$(reminder_payload "$REMINDER_VEHICLE" 'Engine Oil' '' '' '' 100 1000 mi)" 'fixture 44 distance reminder'
add_reminder "$(reminder_payload "$REMINDER_VEHICLE" 'Oil Filter' 3 months '2025-10-01' '' '' '')" 'fixture 44 time reminder'
add_reminder "$(reminder_payload "$REMINDER_VEHICLE" 'Tire Rotation' 1 years '2099-01-01' 500 950 mi)" 'fixture 44 combined reminder'
report="$(rover_report "FROM vehicles V JOIN service-reminders R ON V.vehicle-id = R.vehicle-id JOIN service-subtype-definitions S ON R.service-subtype-id = S.service-subtype-id WHERE V.label = '$REMINDER_VEHICLE' SELECT R.reminder-id, S.label; FROM vehicles V JOIN service-reminders R ON V.vehicle-id = R.vehicle-id JOIN service-subtype-definitions S ON R.service-subtype-id = S.service-subtype-id JOIN reminder-distance-intervals D ON R.reminder-id = D.reminder-id WHERE V.label = '$REMINDER_VEHICLE' AND S.label = 'Oil Filter' SELECT R.reminder-id, D.due-digits;")"
[ "$(count_rows "$report" '%reminder-id')" = 3 ] \
  || fail "fixture 44 reminder parent count is wrong: $report"
grep -q '%due-digits' <<<"$(tail -c +1 <<<"$report" | sed 's/\[%action/\n[%action/g' | tail -1)" \
  && fail "fixture 44 the time-only reminder wrote a distance row: $report"
note "fixture 44 PASS - time, distance, and combined reminders save, and time-only writes no distance row or zero"

# ---------------------------------------------------------------------------
# fixture 45 - the distance threshold reads the real derived odometer. It is
# pending below the threshold, then due only after a product odometer write.
# ---------------------------------------------------------------------------
set_default_vehicle "$REMINDER_VEHICLE"
view="$(eyre_view)"
card="$(reminder_card 'Engine Oil' <<<"$view")"
grep -q 'data-reminder-state="not-due"' <<<"$card" \
  || fail "fixture 45 the below-threshold reminder is not pending: $card"
grep -q 'Due in 100 mi' <<<"$card" \
  || fail "fixture 45 the pending reminder is not human-readable: $card"
add_reminder_odometer "$REMINDER_VEHICLE" 1001 '2026-08-11T09:00' 'fixture 45 crossing odometer'
view="$(eyre_view)"
card="$(reminder_card 'Engine Oil' <<<"$view")"
grep -q 'data-reminder-state="due"' <<<"$card" \
  || fail "fixture 45 the real odometer crossing did not make the reminder due: $card"
note "fixture 45 PASS - a real odometer observation crosses the threshold and changes the distance reminder from pending to due"

# ---------------------------------------------------------------------------
# fixture 46 - real ship time makes a past date due. A combined reminder is
# due because its distance fired even though its time date is still future.
# ---------------------------------------------------------------------------
card="$(reminder_card 'Oil Filter' <<<"$view")"
grep -q 'data-reminder-state="due"' <<<"$card" \
  || fail "fixture 46 the past date is not due against the real ship clock: $card"
grep -q 'Time due since 2025-10-01' <<<"$card" \
  || fail "fixture 46 the due date is not rendered as a date: $card"
card="$(reminder_card 'Tire Rotation' <<<"$view")"
grep -q 'data-reminder-state="due"' <<<"$card" \
  || fail "fixture 46 either did not make the combined reminder due: $card"
grep -q 'Time due 2099-01-01' <<<"$card" \
  || fail "fixture 46 the future time component disappeared: $card"
note "fixture 46 PASS - real ship time fires a past date, and either component makes a combined reminder due"

# ---------------------------------------------------------------------------
# fixture 47 - no odometer is a third state. It is neither due nor not due and
# names the missing evidence in ordinary language.
# ---------------------------------------------------------------------------
add_reminder "$(reminder_payload "$REMINDER_EMPTY_VEHICLE" 'Engine Oil' '' '' '' 500 500 mi)" 'fixture 47 unavailable reminder'
set_default_vehicle "$REMINDER_EMPTY_VEHICLE"
view="$(eyre_view)"
card="$(reminder_card 'Engine Oil' <<<"$view")"
grep -q 'data-reminder-state="unavailable"' <<<"$card" \
  || fail "fixture 47 no-reading reminder is not unavailable: $card"
grep -q 'No odometer readings are recorded for this vehicle' <<<"$card" \
  || fail "fixture 47 no-reading reminder gives no human reason: $card"
grep -q 'data-reminder-state="due"\|data-reminder-state="not-due"' <<<"$card" \
  && fail "fixture 47 unavailable was collapsed to a two-state answer: $card"
note "fixture 47 PASS - a distance reminder with no readings renders unavailable with a human reason"

# ---------------------------------------------------------------------------
# fixture 48 - reset a reminder by a real service, then sell and buy back. The
# post-repurchase odometer is above the threshold, but the interval crosses an
# ownership gap and must remain unavailable instead of counting those miles.
# ---------------------------------------------------------------------------
own_add_ownership_event add-acquisition-event "$REMINDER_GAP_VEHICLE" '2026-01-01T09:00' '$10,000.00' 1000 ''
add_reminder "$(reminder_payload "$REMINDER_GAP_VEHICLE" 'Engine Oil' '' '' '' 500 1500 mi)" 'fixture 48 gap reminder'
eyre_post add-service-event "$(printf '{"vehicle":"%s","observed":"2026-01-10T09:00","zone":"America/Chicago","total":"","currency":"usd","mileage":"1000","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":["Engine Oil"],"disposalKind":"","notes":"Reminder baseline %s"}' "$REMINDER_GAP_VEHICLE" "$STAMP")" \
  $'Saved service event\n201' 'fixture 48 baseline service'
own_add_ownership_event add-disposal-event "$REMINDER_GAP_VEHICLE" '2026-02-01T09:00' '$9,000.00' 1100 'Sold'
own_add_ownership_event add-acquisition-event "$REMINDER_GAP_VEHICLE" '2026-03-01T09:00' '$8,500.00' 2000 ''
add_reminder_odometer "$REMINDER_GAP_VEHICLE" 2100 '2026-03-02T09:00' 'fixture 48 post-gap odometer'
set_default_vehicle "$REMINDER_GAP_VEHICLE"
view="$(eyre_view)"
card="$(reminder_card 'Engine Oil' <<<"$view")"
grep -q 'data-reminder-state="unavailable"' <<<"$card" \
  || fail "fixture 48 the cross-gap reminder was treated as due or pending: $card"
grep -q 'not owned for part of this reminder interval' <<<"$card" \
  || fail "fixture 48 the cross-gap reminder gives no ownership reason: $card"
note "fixture 48 PASS - a service-reset distance reminder does not count an ownership gap's miles"

# ---------------------------------------------------------------------------
# fixture 49 - recording the named service advances each supplied interval.
# Time advances from the service date; distance advances from its real linked
# odometer. The reset link records which event supplied that provenance.
# ---------------------------------------------------------------------------
eyre_post add-service-event "$(printf '{"vehicle":"%s","observed":"2026-08-12T09:00","zone":"America/Chicago","total":"","currency":"usd","mileage":"1001.5","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":["Oil Filter"],"disposalKind":"","notes":"Time reset %s"}' "$REMINDER_VEHICLE" "$STAMP")" \
  $'Saved service event\n201' 'fixture 49 time reset service'
eyre_post add-service-event "$(printf '{"vehicle":"%s","observed":"2026-08-13T09:00","zone":"America/Chicago","total":"","currency":"usd","mileage":"1002","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":["Engine Oil"],"disposalKind":"","notes":"Distance reset %s"}' "$REMINDER_VEHICLE" "$STAMP")" \
  $'Saved service event\n201' 'fixture 49 distance reset service'
set_default_vehicle "$REMINDER_VEHICLE"
view="$(eyre_view)"
card="$(reminder_card 'Oil Filter' <<<"$view")"
grep -q 'data-reminder-state="not-due"' <<<"$card" \
  || fail "fixture 49 the time reminder did not advance after service: $card"
grep -q 'Time due 2026-11-12' <<<"$card" \
  || fail "fixture 49 the time reset due point is wrong: $card"
card="$(reminder_card 'Engine Oil' <<<"$view")"
grep -q 'data-reminder-state="not-due"' <<<"$card" \
  || fail "fixture 49 the distance reminder did not advance after service: $card"
grep -q 'Due in 100 mi' <<<"$card" \
  || fail "fixture 49 the distance reset did not add the interval: $card"
report="$(rover_report "FROM vehicles V JOIN service-reminders R ON V.vehicle-id = R.vehicle-id JOIN reminder-service-events L ON R.reminder-id = L.reminder-id WHERE V.label = '$REMINDER_VEHICLE' SELECT R.reminder-id, L.event-id;")"
[ "$(count_rows "$report" '%reminder-id')" = 2 ] \
  || fail "fixture 49 reset provenance links are missing: $report"
note "fixture 49 PASS - recording the named service advances time and distance due points with event provenance"

# ---------------------------------------------------------------------------
# fixture 12 - everything above survives a ship restart
# ---------------------------------------------------------------------------
# The pier may be the pane's own process or a child of it. Which one it is
# depends on how the session was started, and this fixture restarts the pier
# itself, so the second run of the battery can meet a different shape than the
# first. Both are searched, and the `urbit work` serf is skipped: it carries
# the pier path but not the boot arguments.
pier_session=""
pier_args=""
while read -r session pane_pid; do
  for candidate in "$pane_pid" $(pgrep -P "$pane_pid" 2>/dev/null); do
    args="$(ps -o args= -p "$candidate" 2>/dev/null)"
    case "$args" in
      *'urbit work'*) continue ;;
      *"$PIER"*) pier_session="$session"; pier_args="$args"; break ;;
    esac
  done
  [ -n "$pier_session" ] && break
done < <(tmux list-panes -a -F '#{session_name} #{pane_pid}')
[ -n "$pier_session" ] || fail "fixture 12 cannot find the tmux session running $PIER"
# The boot command is not the run command. `-B <pill>` and `-c` create a pier
# and fail against one that exists, so only the Ames port carries over. The
# port is explicit because a second pier's mesa layer binds port+1, and two
# neighbouring piers otherwise refuse to start.
ames_port="$(sed -n 's/.*-p \([0-9]\{1,\}\).*/\1/p' <<<"$pier_args")"
[ -n "$ames_port" ] || fail "fixture 12 cannot read the Ames port for $PIER: $pier_args"
# The binary comes from the running command, not from PATH. A pier booted with
# a full path runs under a tmux server whose PATH may hold no `urbit` at all,
# and a restart that cannot find the binary reports a dead pier instead. The
# first argument is NOT the binary: the pane runs `script -c <binary> ...`, so
# the match is on the argument that names urbit itself.
pier_binary="$(grep -oE '(^| )[^ ]*urbit( |$)' <<<"$pier_args" | head -1 | tr -d ' ')"
[ -n "$pier_binary" ] || fail "fixture 12 cannot read the urbit binary for $PIER: $pier_args"
tmux send-keys -t "$pier_session" '|exit' Enter
for attempt in $(seq 1 60); do
  pgrep -f "snap-dir $PIER" >/dev/null || break
  sleep 1
done
pgrep -f "snap-dir $PIER" >/dev/null && fail "fixture 12 the pier did not stop"
tmux kill-session -t "$pier_session" 2>/dev/null
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
[ "$ready" = 1 ] || fail "fixture 12 the pier did not restart"
URL="http://localhost:$PORT"
eyre_login
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
# fixture 50 - reminder facts and all three derived states survive the same
# real ship restart. There is no timer to duplicate and no wire to orphan;
# serving the page recomputes each state from the persisted facts.
# ---------------------------------------------------------------------------
set_default_vehicle "$REMINDER_VEHICLE"
view="$(eyre_view)"
card="$(reminder_card 'Engine Oil' <<<"$view")"
grep -q 'data-reminder-state="not-due"' <<<"$card" \
  || fail "fixture 50 the reset distance reminder changed over restart: $card"
card="$(reminder_card 'Oil Filter' <<<"$view")"
grep -q 'data-reminder-state="not-due"' <<<"$card" \
  || fail "fixture 50 the reset time reminder changed over restart: $card"
card="$(reminder_card 'Tire Rotation' <<<"$view")"
grep -q 'data-reminder-state="due"' <<<"$card" \
  || fail "fixture 50 the combined OR reminder changed over restart: $card"
set_default_vehicle "$REMINDER_EMPTY_VEHICLE"
view="$(eyre_view)"
grep -q 'data-reminder="Engine Oil" data-reminder-state="unavailable"' <<<"$view" \
  || fail "fixture 50 the no-reading state changed over restart"
set_default_vehicle "$REMINDER_GAP_VEHICLE"
view="$(eyre_view)"
grep -q 'data-reminder="Engine Oil" data-reminder-state="unavailable"' <<<"$view" \
  || fail "fixture 50 the ownership-gap state changed over restart"
note "fixture 50 PASS - reminders, reset provenance, and due, pending, and unavailable derivations survived a ship restart"

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
# fixture 51 - a person opens Add Reminder, chooses a vehicle and service
# subtype, saves a time-only interval, and sees the rendered state reload.
# ---------------------------------------------------------------------------
set_default_vehicle "$REMINDER_VEHICLE"
reminder_browser_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/reminder-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$REMINDER_VEHICLE" 'Inspection'
} 2>&1)" || fail "fixture 51 the browser could not save a reminder: $reminder_browser_out"
grep -q 'REMINDER_VERDICT=Saved reminder' <<<"$reminder_browser_out" \
  || fail "fixture 51 the reminder form verdict is wrong: $reminder_browser_out"
grep -q 'REMINDER_STATE=not-due' <<<"$reminder_browser_out" \
  || fail "fixture 51 the saved reminder did not render after reload: $reminder_browser_out"
report="$(rover_report "FROM vehicles V JOIN service-reminders R ON V.vehicle-id = R.vehicle-id JOIN service-subtype-definitions S ON R.service-subtype-id = S.service-subtype-id JOIN reminder-time-intervals T ON R.reminder-id = T.reminder-id WHERE V.label = '$REMINDER_VEHICLE' AND S.label = 'Inspection' SELECT R.reminder-id, T.interval, T.time-unit, T.due-at;")"
grep -q '%reminder-id' <<<"$report" \
  || fail "fixture 51 the browser-entered reminder is absent from Obelisk: $report"
note "fixture 51 PASS - a person saves a reminder from the form and sees its pending state after reload"

. "$(dirname "$0")/event-coverage-gate.sh"
