#!/usr/bin/env bash
# M7 T1 event-family battery over real Eyre and Obelisk.
set -uo pipefail

PIER="${1:-}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
EXPECTED_EVENT_COUNT="${M7T1_EXPECT_EVENT_COUNT:-3}"

fail() { echo "m7t1-test: FAIL - $*" >&2; exit 1; }
note() { echo "m7t1-test: $*"; }

[ -n "$PIER" ] || fail "no pier given"
[ "$(basename "$PIER")" = rover-m7t1-sol-bel ] \
  || fail "the pier must be rover-m7t1-sol-bel"
[ -S "$PIER/.urb/conn.sock" ] || fail "no live conn.sock under $PIER"
PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || fail "click is not on PATH"

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || fail "the pier has no public HTTP port"
URL="http://localhost:$PORT"
JAR="$(mktemp /tmp/rover-m7t1-cookie.XXXXXX)"
trap 'rm -f "$JAR"' EXIT

click_file() {
  timeout 60 click -k -i "$1" "$PIER" 2>/dev/null | tail -1
}

derive_code() {
  local raw decimal dotted
  raw="$(click_file "$REPO/probes/login-code.hoon" \
    | sed 's/^\[0 %avow 0 %noun //; s/\]$//')"
  decimal="$(python3 -c "print(int('$raw', 0))" 2>/dev/null)" || return 1
  dotted="$(printf '%s' "$decimal" | rev | sed 's/[0-9]\{3\}/&./g' | rev | sed 's/^\.//')"
  printf '`@p`%s\n' "$dotted" | urbit eval 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
    | grep -oE '[a-z]{6}(-[a-z]{6}){3}' | head -1
}

eyre_post() {
  local path="$1" payload="$2" expected="$3" label="$4" response
  response="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' --data-raw "$payload" \
    "$URL/apps/rover/$path")"
  [ "$response" = "$expected" ] || fail "$label: $response"
}

import_definitions() {
  local response
  response="$(curl -sS -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' --data-raw \
    '{"rover-import":1,"source":{"app":"m7t1-battery"},"definitions":{"energy":[],"additives":[],"driving-modes":[],"tags":[{"label":"Maintenance"}],"payment-methods":[{"label":"Fleet Card"}]},"places":[],"vehicles":[]}' \
    "$URL/apps/rover/import")"
  grep -q 'Rover import complete' <<<"$response" \
    || fail "event definitions: $response"
  grep -q '200$' <<<"$response" || fail "event definitions HTTP status: $response"
}

CODE="$(derive_code)"
[ -n "$CODE" ] || fail "could not derive the login code"
curl -sS -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
grep -q urbauth "$JAR" || fail "login did not yield an Eyre cookie"

setup="$(click_file "$REPO/probes/m7t1-setup.hoon")"
if ! grep -q "\[%label 116 'M7 T1 Vehicle'\]" <<<"$setup"; then
  import_definitions
  eyre_post add-vehicle '{"label":"M7 T1 Vehicle","energy":"Gasoline"}' \
    $'Added vehicle - M7 T1 Vehicle\n201' 'event vehicle'
fi

setup="$(click_file "$REPO/probes/m7t1-setup.hoon")"
if ! grep -q "\[%station-id " <<<"$setup"; then
  eyre_post add-fill \
    '{"vehicle":"M7 T1 Vehicle","definition":"Gasoline","quantity":"10.000","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-08-01T09:00","zone":"America/Chicago","mileage":"10000","mileageUnit":"mi","station":"new","newStationLabel":"M7 T1 Shop","newPlaceLabel":"M7 T1 Place","newStationKind":"fuel","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":"Fleet Card"}' \
    $'Saved fill - $3.499 - derived $34.99\n201' 'baseline fill and station'
  note "created the vehicle, baseline fill, and shared station"
fi

eyre_post add-service-event \
  '{"vehicle":"M7 T1 Vehicle","observed":"2026-08-01T10:00","zone":"America/Chicago","mileage":"10100","mileageUnit":"mi","total":"0","currency":"usd","station":"M7 T1 Shop","tags":[],"paymentMethod":"","notes":"Invalid zero total"}' \
  $'%bad-shape: event.total\n400' 'zero event total refusal'
eyre_post add-note-event \
  '{"vehicle":"M7 T1 Vehicle","observed":"2026-08-01T12:00","zone":"America/Chicago","mileage":"10102","mileageUnit":"mi","total":"","currency":"usd","station":"","tags":[],"paymentMethod":"","notes":""}' \
  $'%missing-key: event.notes\n400' 'empty note refusal'

view="$(curl -sS -b "$JAR" "$URL/apps/rover/view")"
if ! grep -q 'Oil and filter service' <<<"$view"; then
  eyre_post add-service-event \
    '{"vehicle":"M7 T1 Vehicle","observed":"2026-08-01T10:00","zone":"America/Chicago","mileage":"10100","mileageUnit":"mi","total":"123.450","currency":"usd","station":"M7 T1 Shop","tags":["Maintenance"],"paymentMethod":"Fleet Card","notes":"Oil and filter service"}' \
    $'Saved service event\n201' 'service event'
fi

view="$(curl -sS -b "$JAR" "$URL/apps/rover/view")"
if ! grep -q 'Parking expense' <<<"$view"; then
  eyre_post add-expense-event \
    '{"vehicle":"M7 T1 Vehicle","observed":"2026-08-01T11:00","zone":"America/Chicago","mileage":"10101","mileageUnit":"mi","total":"12.500","currency":"usd","station":"","tags":[],"paymentMethod":"Fleet Card","notes":"Parking expense"}' \
    $'Saved expense event\n201' 'expense event'
fi

view="$(curl -sS -b "$JAR" "$URL/apps/rover/view")"
if ! grep -q 'Roadside note' <<<"$view"; then
  eyre_post add-note-event \
    '{"vehicle":"M7 T1 Vehicle","observed":"2026-08-01T12:00","zone":"America/Chicago","mileage":"10102","mileageUnit":"mi","total":"","currency":"usd","station":"","tags":[],"paymentMethod":"","notes":"Roadside note"}' \
    $'Saved note event\n201' 'note event'
fi

view="$(curl -sS -b "$JAR" "$URL/apps/rover/view")"
grep -q 'Oil and filter service' <<<"$view" || fail "the service event is absent from Eyre readback"
grep -q 'Parking expense' <<<"$view" || fail "the expense event is absent from Eyre readback"
grep -q 'Roadside note' <<<"$view" || fail "the note event is absent from Eyre readback"
grep -q '\$123.450' <<<"$view" || fail "the service total is absent from Eyre readback"
grep -q '\$12.500' <<<"$view" || fail "the expense total is absent from Eyre readback"

verdict="$(click_file "$REPO/probes/m7t1-verdict.hoon")"
printf '%s\n' "$verdict"
case "$verdict" in
  *"%m7t1-pass $EXPECTED_EVENT_COUNT 4 1 1 1 2 0 0 1 1 1"*)
    note "PASS - typed fixture counts match"
    ;;
  *)
    fail "the final typed verdict is not a pass: $verdict"
    ;;
esac
