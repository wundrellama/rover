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
grep -q 'id="main-hub"' <<<"$view" || fail "fixture 1 the served view has no hub"
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
  vehicle-event-notes; do
  grep -q "%name %tas %$relation" <<<"$report" \
    || fail "fixture 2 the pour is missing $relation"
done
note "fixture 2 PASS - the eleven event relations exist after the definition-layer catch-up"
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
eyre_post add-vehicle "$(printf '{"label":"%s","energy":"Gasoline"}' "$VEHICLE")" \
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
# fixture 12 - everything above survives a ship restart
# ---------------------------------------------------------------------------
pier_session=""
pier_args=""
while read -r session pane_pid; do
  child="$(pgrep -P "$pane_pid" | head -1)"
  [ -n "$child" ] || continue
  args="$(ps -o args= -p "$child" 2>/dev/null)"
  case "$args" in
    *"$PIER"*) pier_session="$session"; pier_args="$args"; break ;;
  esac
done < <(tmux list-panes -a -F '#{session_name} #{pane_pid}')
[ -n "$pier_session" ] || fail "fixture 12 cannot find the tmux session running $PIER"
# The boot command is not the run command. `-B <pill>` and `-c` create a pier
# and fail against one that exists, so only the Ames port carries over. The
# port is explicit because a second pier's mesa layer binds port+1, and two
# neighbouring piers otherwise refuse to start.
ames_port="$(sed -n 's/.*-p \([0-9]\{1,\}\).*/\1/p' <<<"$pier_args")"
[ -n "$ames_port" ] || fail "fixture 12 cannot read the Ames port for $PIER"
tmux send-keys -t "$pier_session" '|exit' Enter
for attempt in $(seq 1 60); do
  pgrep -f "snap-dir $PIER" >/dev/null || break
  sleep 1
done
pgrep -f "snap-dir $PIER" >/dev/null && fail "fixture 12 the pier did not stop"
tmux kill-session -t "$pier_session" 2>/dev/null
# script(1) gives the run a pty; without one vere refuses to start interactive.
tmux new-session -d -s "$pier_session" \
  "exec script -q -f -e -O /dev/null -c $(printf '%q' "urbit -p $ames_port $PIER")"
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
browser_out="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/event-browser-fixture.cjs" \
      "$URL" "$auth_cookie_name" "$auth_cookie" "$VEHICLE" "$STATION" "$TAG" \
      "$PAYMENT" '$88.40' "$BROWSER_ODO" "$BROWSER_NOTE"
} 2>&1)" || fail "fixture 14 the browser could not save an event: $browser_out"
grep -q 'EVENT_VERDICT=Saved service event - \$88.40' <<<"$browser_out" \
  || fail "fixture 14 the form verdict is wrong: $browser_out"
grep -q 'EVENT_CARDS=1' <<<"$browser_out" \
  || fail "fixture 14 the saved event did not appear in the reloaded view: $browser_out"
report="$(rover_report "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-notes X ON E.event-id = X.event-id WHERE V.label = '$VEHICLE' SELECT X.note;")"
grep -qF "$BROWSER_NOTE" <<<"$report" \
  || fail "fixture 14 the browser-entered event is not in the database: $report"
note "fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back"

. "$(dirname "$0")/event-coverage-gate.sh"
