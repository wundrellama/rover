#!/usr/bin/env bash
# Rover browser-half fixtures over real Eyre. No loopback auto-auth and no mocks.
set -uo pipefail

PIER="${1:-${ROVER_PIER:-}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$PIER" ]; then
  cat >&2 <<'USAGE'
ui-test: no pier given.

  usage: bin/ui-test.sh <pier>          e.g. bin/ui-test.sh ~/piers/rover-binbel
     or: ROVER_PIER=<pier> bin/ui-test.sh

There is deliberately no default. A hardcoded default silently tested a retired
pier and reported an app failure that did not exist (2026-07-29). Name the pier.

Candidate piers with a live conn.sock:
USAGE
  for p in "$HOME"/piers/*/; do
    [ -S "$p/.urb/conn.sock" ] && printf '  %s\n' "${p%/}" >&2
  done
  exit 2
fi

fail() { echo "ui-test: FAIL - $*" >&2; exit 1; }

# Every fixture reports through note(), so record which ones actually ran.
# See the coverage gate at the end of this file.
_ROVER_RAN=""
note() {
  case "$*" in
    fixture\ [0-9]*)
      _ROVER_RAN="$_ROVER_RAN $(printf '%s' "$*" | awk '{print $2}')" ;;
  esac
  echo "ui-test: $*"
}

[ -S "$PIER/.urb/conn.sock" ] || { echo "no conn.sock under $PIER" >&2; exit 2; }
command -v click >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || { echo "click not on PATH" >&2; exit 2; }

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || { echo "no public http port in $PIER/.http.ports" >&2; exit 2; }
URL="http://localhost:$PORT"

click_file() {
  local body="$1" target="${2:-$PIER}" file out
  file="$(mktemp /tmp/rover-ui-test.XXXXXX.hoon)"
  printf '%s\n' "$body" > "$file"
  out="$(click -k -i "$file" "$target" 2>/dev/null | tail -1)"
  rm -f "$file"
  printf '%s\n' "$out"
}

# Gate 7 T1: readback reports poke %obelisk directly with the same urQL the
# retired %rover-action wrappers carried. The urQL text below is lifted
# verbatim from lib/rover-act.hoon.
URQL_APP_STRUCTURE="$(cat <<'URQL_EOF'
FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id JOIN energy-subtype-octane O ON S.subtype-id = O.subtype-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, S.label AS subtype, O.rating, O.method; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN economy-breaks B ON A.acquisition-id = B.acquisition-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, B.reason; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-driving-mode L ON A.acquisition-id = L.acquisition-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, D.label AS driving-mode; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-average-speed S ON A.acquisition-id = S.acquisition-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, S.digits, S.decimals, S.speed-unit; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-drive-balance B ON A.acquisition-id = B.acquisition-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, B.highway-percent; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-tags L ON A.acquisition-id = L.acquisition-id JOIN tag-definitions T ON L.tag-id = T.tag-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, T.label AS tag; FROM app-default-vehicle A JOIN vehicles V ON A.vehicle-id = V.vehicle-id SELECT A.scope, V.label AS default-vehicle; FROM custom-field-definitions C JOIN custom-field-values-number V ON C.field-id = V.field-id SELECT C.label AS custom-field, V.digits, V.decimals, V.value-unit; FROM custom-field-definitions C JOIN custom-field-values-text V ON C.field-id = V.field-id SELECT C.label AS custom-field, V.value; FROM custom-field-definitions C JOIN custom-field-values-boolean V ON C.field-id = V.field-id SELECT C.label AS custom-field, V.value;
URQL_EOF
)"
URQL_STARTER="$(cat <<'URQL_EOF'
FROM energy-definitions E WHERE E.archived = N SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived; FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id SELECT E.label AS energy, S.label AS subtype, S.archived; FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-octane O ON S.subtype-id = O.subtype-id SELECT E.label AS energy, S.label AS subtype, O.rating, O.method; FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-blend B ON S.subtype-id = B.subtype-id SELECT E.label AS energy, S.label AS subtype, B.blend-kind, B.percent-digits, B.percent-decimals;
URQL_EOF
)"
URQL_DEMO_STARTER="$(cat <<'URQL_EOF'
FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Rover Demo Gasoline' OR V.label = 'Rover Demo Diesel' SELECT V.label AS vehicle, A.energy-definition-id AS demo-energy-definition-id, E.energy-definition-id AS starter-energy-definition-id, E.label AS starter-energy; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = 'Rover Demo Gasoline' OR V.label = 'Rover Demo Diesel' SELECT V.label AS vehicle, A.energy-definition-id AS demo-energy-definition-id, S.energy-definition-id AS subtype-parent-definition-id, L.subtype-id AS demo-subtype-id, S.subtype-id AS starter-subtype-id, S.label AS starter-subtype;
URQL_EOF
)"
URQL_VEHICLE_HISTORY="$(cat <<'URQL_EOF'
FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, V.archived AS vehicle-archived, E.label AS energy, E.physical-kind, E.archived AS energy-archived, L.archived AS link-archived; FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id JOIN vehicle-energy-definitions L ON D.vehicle-id = L.vehicle-id AND D.energy-definition-id = L.energy-definition-id JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, E.label AS default-energy, L.archived AS link-archived; FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, O.value-digits, O.decimal-places, O.unit, O.observed-start, O.observed-end, O.recorded-at; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, E.label AS energy, F.quantity-milli, F.quantity-unit, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills, A.observed-start, A.observed-end;
URQL_EOF
)"
URQL_DISPLAY_PREFERENCE="$(cat <<'URQL_EOF'
FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'Preference Vehicle' SELECT V.label AS vehicle, O.value-digits, O.decimal-places, O.unit; FROM vehicles V JOIN vehicle-display-preferences P ON V.vehicle-id = P.vehicle-id WHERE V.label = 'Preference Vehicle' SELECT V.label AS vehicle, P.distance-unit, P.currency;
URQL_EOF
)"
URQL_TRY_SECOND_DEFAULT="$(cat <<'URQL_EOF'
INSERT INTO app-default-vehicle VALUES (%app, 0x1, ~2026.08.11..12.00.00);
URQL_EOF
)"
URQL_VEHICLE_SETTINGS="$(cat <<'URQL_EOF'
FROM vehicles V WHERE V.label = 'XLABELX' SELECT V.label AS vehicle, V.archived; FROM vehicles V JOIN vehicle-tank-size T ON V.vehicle-id = T.vehicle-id WHERE V.label = 'XLABELX' SELECT V.label AS vehicle, T.digits, T.decimals, T.size-unit; FROM vehicles V JOIN vehicle-refill-reserve R ON V.vehicle-id = R.vehicle-id WHERE V.label = 'XLABELX' SELECT V.label AS vehicle, R.reserve-percent; FROM vehicles V JOIN vehicle-default-energy-subtype D ON V.vehicle-id = D.vehicle-id JOIN energy-definition-subtypes S ON D.subtype-id = S.subtype-id WHERE V.label = 'XLABELX' SELECT V.label AS vehicle, S.label AS default-subtype; FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = 'XLABELX' SELECT E.label AS energy, L.archived AS link-archived; FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = 'XLABELX' SELECT D.label AS driving-mode, L.archived AS link-archived; FROM vehicles V JOIN vehicle-consumables L ON V.vehicle-id = L.vehicle-id JOIN consumable-definitions C ON L.consumable-id = C.consumable-id WHERE V.label = 'XLABELX' AND C.label = 'DEF' SELECT C.label AS consumable, L.archived AS link-archived; FROM vehicles V JOIN vehicle-consumable-tank-size T ON V.vehicle-id = T.vehicle-id JOIN consumable-definitions C ON T.consumable-id = C.consumable-id WHERE V.label = 'XLABELX' AND C.label = 'DEF' SELECT T.digits, T.decimals, T.unit; FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id WHERE V.label = 'XLABELX' SELECT E.label AS default-energy;
URQL_EOF
)"
URQL_FILL_EDIT="$(cat <<'URQL_EOF'
FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT V.label AS vehicle, A.acquisition-id, A.observed-start, A.source-zone, F.quantity-milli, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT S.label AS subtype; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-acquisition-stations L ON A.acquisition-id = L.acquisition-id JOIN stations S ON L.station-id = S.station-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT S.label AS station; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-driving-mode L ON A.acquisition-id = L.acquisition-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT D.label AS driving-mode; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-average-speed S ON A.acquisition-id = S.acquisition-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT S.digits, S.decimals, S.speed-unit; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-drive-balance B ON A.acquisition-id = B.acquisition-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT B.highway-percent; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fill-notes X ON A.acquisition-id = X.acquisition-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT X.note; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-payment-method L ON A.acquisition-id = L.acquisition-id JOIN payment-method-definitions P ON L.method-id = P.method-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT P.label AS payment-method; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-additives L ON A.acquisition-id = L.acquisition-id JOIN additive-definitions D ON L.additive-id = D.additive-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT D.label AS additive; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-tags L ON A.acquisition-id = L.acquisition-id JOIN tag-definitions T ON L.tag-id = T.tag-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT T.label AS tag; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-acquisition-odometers L ON A.acquisition-id = L.acquisition-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT O.odometer-id, O.value-digits, O.decimal-places, O.unit;
URQL_EOF
)"
URQL_STATION="$(cat <<'URQL_EOF'
FROM stations S JOIN places P ON S.place-id = P.place-id WHERE S.label = 'XLABELX' SELECT S.label AS station, P.label AS place, S.station-kind; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-addresses A ON P.place-id = A.place-id WHERE S.label = 'XLABELX' SELECT A.source; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-address-formatted F ON P.place-id = F.place-id WHERE S.label = 'XLABELX' SELECT F.formatted; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-address-parts A ON P.place-id = A.place-id WHERE S.label = 'XLABELX' SELECT A.part, A.value; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-coordinates C ON P.place-id = C.place-id WHERE S.label = 'XLABELX' SELECT C.latitude-scaled, C.longitude-scaled, C.coord-scale, C.source;
URQL_EOF
)"
URQL_CONSUMABLE_REPORT="$(cat <<'URQL_EOF'
FROM vehicles V JOIN consumable-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN consumable-definitions D ON A.consumable-id = D.consumable-id JOIN consumable-purchases P ON A.consumable-acquisition-id = P.consumable-acquisition-id WHERE V.label = 'XLABELX' AND D.label = 'XCONSX' AND A.observed-start = ~2000.01.01 SELECT V.label AS vehicle, D.label AS consumable, P.quantity-milli, P.quantity-unit, P.unit-price-mills, P.currency, P.settlement-mode, P.price-profile, P.minor-unit-decimals, P.cash-increment-mills; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = 'XLABELX' SELECT A.acquisition-id AS fuel-acquisition;
URQL_EOF
)"
URQL_CHARGE_SUBTYPE="$(cat <<'URQL_EOF'
FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN charging-session-subtype L ON C.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = 'XLABELX' AND A.observed-start = ~2000.01.01 SELECT V.label AS vehicle, S.label AS charging-subtype;
URQL_EOF
)"

rover_report() {
  local script="$1"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-ui-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector \"$script\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
}

urql_vehicle_settings() { printf '%s' "${URQL_VEHICLE_SETTINGS//XLABELX/$1}"; }
urql_station() { printf '%s' "${URQL_STATION//XLABELX/$1}"; }
urql_fill_edit() {
  local t="${URQL_FILL_EDIT//XLABELX/$1}"
  printf '%s' "${t//'~2000.01.01'/$2}"
}
urql_consumable() {
  local t="${URQL_CONSUMABLE_REPORT//XLABELX/$1}"
  t="${t//XCONSX/$2}"
  printf '%s' "${t//'~2000.01.01'/$3}"
}
urql_charge_subtype() {
  local t="${URQL_CHARGE_SUBTYPE//XLABELX/$1}"
  printf '%s' "${t//'~2000.01.01'/$2}"
}

# Gate 7 T1: fixture state that a user can create arrives through the same
# HTTP endpoints the browser uses. eyre_post asserts the exact endpoint
# response so a refused write fails loudly at the write, not downstream.
eyre_post() {
  local path="$1" payload="$2" expected="$3" label="$4" response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$payload" "$URL/apps/rover/$path")"
  [ "$response" = "$expected" ] || fail "$label: $response"
}

import_definitions() {
  local payload="$1" expected="$2" label="$3" report
  report="$(curl -s -b "$JAR" -H 'content-type: application/json' \
    --data-raw "$payload" "$URL/apps/rover/import")"
  grep -q "$expected" <<<"$report" || fail "$label: $report"
}

demo_fill() {
  # vehicle definition subtype station payment observed mileage quantity
  # price saved-suffix missed [new-station-label new-place-label]
  local vehicle="$1" definition="$2" subtype="$3" station="$4" payment="$5"
  local observed="$6" mileage="$7" quantity="$8" price="$9" saved="${10}"
  local missed="${11}" newstation="${12:-}" newplace="${13:-}"
  local payload
  payload="$(printf '{"vehicle":"%s","definition":"%s","quantity":"%s","price":"%s","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"%s","mileageUnit":"mi","station":"%s","newStationLabel":"%s","newPlaceLabel":"%s","newStationKind":"fuel","additives":[],"subtype":"%s","missedFill":"%s","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":"%s"}' \
    "$vehicle" "$definition" "$quantity" "$price" "$observed" "$mileage" \
    "$station" "$newstation" "$newplace" "$subtype" "$missed" "$payment")"
  eyre_post add-fill "$payload" "Saved fill - $saved"$'\n201' "demo fill ($vehicle $observed)"
}

seed_demo_fuel_via_eyre() {
  import_definitions \
    '{"rover-import":1,"source":{"app":"rover-demo"},"definitions":{"energy":[],"additives":[],"driving-modes":[],"tags":[],"payment-methods":[{"label":"Demo Cash"},{"label":"Demo Fleet Card"}]},"places":[],"vehicles":[]}' \
    'Definitions: created 2, reused 0' 'demo payment methods via import'
  eyre_post add-vehicle '{"label":"Rover Demo Gasoline","energy":"Gasoline"}' \
    $'Added vehicle - Rover Demo Gasoline\n201' 'demo gasoline vehicle'
  eyre_post add-vehicle '{"label":"Rover Demo Diesel","energy":"Diesel"}' \
    $'Added vehicle - Rover Demo Diesel\n201' 'demo diesel vehicle'
  eyre_post edit-vehicle '{"vehicle":"Rover Demo Gasoline","label":"Rover Demo Gasoline","tankSize":"15.5","tankUnit":"gal","defaultSubtype":"","energySources":["Gasoline"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    $'Saved vehicle settings\n201' 'demo gasoline tank size'
  eyre_post edit-vehicle '{"vehicle":"Rover Demo Diesel","label":"Rover Demo Diesel","tankSize":"26","tankUnit":"gal","defaultSubtype":"","energySources":["Diesel"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    $'Saved vehicle settings\n201' 'demo diesel tank size'
  demo_fill 'Rover Demo Gasoline' Gasoline 87 new 'Demo Cash' 2026-07-01T12:00 10000 10.000 '$3.39' '$3.399 - derived $33.99' no 'North Fuel' 'Rover Demo North'
  demo_fill 'Rover Demo Gasoline' Gasoline 93 new 'Demo Fleet Card' 2026-07-02T12:00 10300 10.000 '$3.49' '$3.499 - derived $34.99' no 'South Fuel' 'Rover Demo South'
  demo_fill 'Rover Demo Gasoline' Gasoline 87 'North Fuel' 'Demo Fleet Card' 2026-07-03T12:00 10608 11.000 '$3.45' '$3.459 - derived $38.05' no
  demo_fill 'Rover Demo Gasoline' Gasoline 93 'South Fuel' 'Demo Cash' 2026-07-04T12:00 10908 10.000 '$3.57' '$3.579 - derived $35.79' yes
  demo_fill 'Rover Demo Gasoline' Gasoline 87 'North Fuel' 'Demo Fleet Card' 2026-07-05T12:00 11232 12.000 '$3.42' '$3.429 - derived $41.15' no
  demo_fill 'Rover Demo Gasoline' Gasoline 93 'South Fuel' 'Demo Fleet Card' 2026-07-06T12:00 11522 10.000 '$3.61' '$3.619 - derived $36.19' no
  demo_fill 'Rover Demo Diesel' Diesel '#2' 'North Fuel' 'Demo Fleet Card' 2026-07-02T13:00 50000 12.000 '$3.89' '$3.899 - derived $46.79' no
  demo_fill 'Rover Demo Diesel' Diesel B20 'South Fuel' 'Demo Cash' 2026-07-03T13:00 50400 12.500 '$3.97' '$3.979 - derived $49.74' no
  demo_fill 'Rover Demo Diesel' Diesel '#2' 'North Fuel' 'Demo Fleet Card' 2026-07-04T13:00 50810 12.500 '$4.02' '$4.029 - derived $50.36' no
  demo_fill 'Rover Demo Diesel' Diesel B20 'South Fuel' 'Demo Fleet Card' 2026-07-05T13:00 51200 12.000 '$3.94' '$3.949 - derived $47.39' no
  demo_fill 'Rover Demo Diesel' Diesel '#2' 'North Fuel' 'Demo Cash' 2026-07-06T13:00 51620 14.000 '$4.09' '$4.099 - derived $57.39' no
  demo_fill 'Rover Demo Diesel' Diesel B20 'South Fuel' 'Demo Fleet Card' 2026-07-07T13:00 52020 12.500 '$4.05' '$4.059 - derived $50.74' no
}

seed_demo_def_via_eyre() {
  eyre_post edit-vehicle '{"vehicle":"Rover Demo Diesel","label":"Rover Demo Diesel","tankSize":"26","tankUnit":"gal","defaultSubtype":"","energySources":["Diesel"],"drivingModes":[],"defEnabled":"yes","defTankSize":"5","defTankUnit":"gal"}' \
    $'Saved vehicle settings\n201' 'demo DEF enablement'
  eyre_post add-consumable '{"vehicle":"Rover Demo Diesel","consumable":"DEF","quantity":"1.000","price":"$4.29","observed":"2026-07-10T14:00","zone":"America/Chicago","mileage":"50200","mileageUnit":"mi"}' \
    $'Saved consumable purchase - $4.30\n201' 'demo DEF purchase 1'
  eyre_post add-consumable '{"vehicle":"Rover Demo Diesel","consumable":"DEF","quantity":"2.000","price":"$4.29","observed":"2026-07-24T14:00","zone":"America/Chicago","mileage":"51200","mileageUnit":"mi"}' \
    $'Saved consumable purchase - $8.60\n201' 'demo DEF purchase 2'
  eyre_post add-consumable '{"vehicle":"Rover Demo Diesel","consumable":"DEF","quantity":"2.000","price":"$4.29","observed":"2026-07-29T14:00","zone":"America/Chicago","mileage":"52200","mileageUnit":"mi"}' \
    $'Saved consumable purchase - $8.60\n201' 'demo DEF purchase 3'
}

seed_fill_edit_support_via_eyre() {
  local vehicle="$1"
  import_definitions \
    '{"rover-import":1,"source":{"app":"rover-fixture"},"definitions":{"energy":[],"additives":[{"label":"Octane Booster"}],"driving-modes":[{"label":"Mixed Driving"}],"tags":[{"label":"Road Trip"}],"payment-methods":[{"label":"Personal Visa"}]},"places":[],"vehicles":[]}' \
    'Definitions: created 4, reused 0' 'fill-edit support definitions via import'
  eyre_post edit-vehicle "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"","energySources":["Gasoline"],"drivingModes":["Mixed Driving"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$vehicle" "$vehicle")" \
    $'Saved vehicle settings\n201' 'fill-edit vehicle mode link'
}

seed_spike_via_eyre() {
  eyre_post add-energy-source-type '{"label":"Regular 87","physicalKind":"reservoir","quantityUnit":"gal"}' \
    $'Created energy source type\n201' 'spike energy definition'
  eyre_post add-vehicle '{"label":"Phase A Vehicle","energy":"Regular 87","additionalEnergy":["Electricity"]}' \
    $'Added vehicle - Phase A Vehicle\n201' 'spike vehicle'
  eyre_post add-odometer '{"vehicle":"Phase A Vehicle","reading":"10000.0","unit":"mi","observed":"2026-07-27T12:00","zone":"America/Chicago"}' \
    $'Saved odometer - 10,000.0 mi\n201' 'spike first odometer'
  eyre_post add-fill '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"12.345","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T12:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' \
    $'Saved fill - $3.499 - derived $43.20\n201' 'spike fill'
  eyre_post add-odometer '{"vehicle":"Phase A Vehicle","reading":"10012.5","unit":"mi","observed":"2026-07-28T12:00","zone":"America/Chicago"}' \
    $'Saved odometer - 10,012.5 mi\n201' 'spike second odometer'
}

seed_app_structure_via_eyre() {
  import_definitions \
    '{"rover-import":1,"source":{"app":"rover-fixture"},"definitions":{"energy":[{"label":"Structure Gasoline","physicalKind":"reservoir","quantityUnit":"gal","subtypes":[{"label":"Structure 87 AKI","octane":"87","method":"aki"},{"label":"Structure 91 AKI","octane":"91","method":"aki"},{"label":"Structure 93 AKI","octane":"93","method":"aki"}]}],"additives":[],"driving-modes":[{"label":"Tow / Haul"}],"tags":[{"label":"Road trip"},{"label":"Winter"}],"payment-methods":[]},"places":[],"vehicles":[]}' \
    'Definitions: created 4, reused 0' 'structure definitions via import'
  eyre_post add-vehicle '{"label":"Structure Vehicle","energy":"Structure Gasoline","drivingModes":["Tow / Haul"]}' \
    $'Added vehicle - Structure Vehicle\n201' 'structure vehicle'
  eyre_post edit-vehicle '{"vehicle":"Structure Vehicle","label":"Structure Vehicle","tankSize":"","tankUnit":"gal","defaultSubtype":"Structure 91 AKI","energySources":["Structure Gasoline"],"drivingModes":["Tow / Haul"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    $'Saved vehicle settings\n201' 'structure default subtype'
  eyre_post add-vehicle '{"label":"Mode Scope Vehicle","energy":"Structure Gasoline"}' \
    $'Added vehicle - Mode Scope Vehicle\n201' 'mode scope vehicle'
}

seed_charging_cost_via_eyre() {
  eyre_post add-energy-source-type '{"label":"Cost Fixture Electricity","physicalKind":"electricity","quantityUnit":"kwh"}' \
    $'Created energy source type\n201' 'charging cost energy definition'
  eyre_post add-vehicle '{"label":"Charging Cost Vehicle","energy":"Cost Fixture Electricity"}' \
    $'Added vehicle - Charging Cost Vehicle\n201' 'charging cost vehicle'
  eyre_post add-charge '{"vehicle":"Charging Cost Vehicle","definition":"Cost Fixture Electricity","start":"2026-07-28T16:00","end":"2026-07-28T16:01","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"free","currency":"usd"}' \
    $'Saved charge - Energy delivered not recorded\n201' 'free charge'
  eyre_post add-charge '{"vehicle":"Charging Cost Vehicle","definition":"Cost Fixture Electricity","start":"2026-07-28T16:01","end":"2026-07-28T16:02","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"unknown","currency":"usd"}' \
    $'Saved charge - Energy delivered not recorded\n201' 'unknown charge'
  eyre_post add-charge '{"vehicle":"Charging Cost Vehicle","definition":"Cost Fixture Electricity","start":"2026-07-28T16:02","end":"2026-07-28T16:03","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[{"component":"energy","quantity":"45.678","unit":"kwh","rate":"0.250","amount":"11.420"},{"component":"time","quantity":"30","unit":"minute","rate":"0.100","amount":"3.000"},{"component":"session","quantity":"1","unit":"session","rate":"1.500","amount":"1.500"},{"component":"idle","quantity":"5","unit":"minute","rate":"0.500","amount":"2.500"},{"component":"tax","quantity":"1","unit":"session","rate":"1.000","amount":"1.000"},{"component":"discount","quantity":"1","unit":"session","rate":"2.000","amount":"2.000"}]}' \
    $'Saved charge - Energy delivered not recorded - itemized total $17.420\n201' 'itemized charge'
  eyre_post add-charge '{"vehicle":"Charging Cost Vehicle","definition":"Cost Fixture Electricity","start":"2026-07-28T16:03","end":"2026-07-28T16:04","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"receipt-total-only","currency":"usd","sourceTotal":"22.340","components":[]}' \
    $'Saved charge - Energy delivered not recorded - receipt total $22.340\n201' 'receipt-total charge'
}

derive_code() {
  local target="$1" raw decimal dotted
  raw="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
(pure:m !>(.^(@p %j /(scot %p our.bowl)/code/(scot %da now.bowl)/(scot %p our.bowl))))' "$target" \
    | sed 's/^\[0 %avow 0 %noun //; s/\]$//')"
  decimal="$(python3 -c "print(int('$raw', 0))" 2>/dev/null)" || return 1
  case "$decimal" in (''|*[!0-9]*) return 1;; esac
  dotted="$(printf '%s' "$decimal" | rev | sed 's/[0-9]\{3\}/&./g' | rev | sed 's/^\.//')"
  printf '`@p`%s\n' "$dotted" | urbit eval 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
    | grep -oE '[a-z]{6}(-[a-z]{6}){3}' | head -1
}

resolve_pier_tmux() {
  local target session pid command
  while read -r target session pid; do
    [ -r "/proc/$pid/cmdline" ] || continue
    command="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
    case "$command" in
      *" $PIER "*)
        printf '%s %s %s\n' "$target" "$session" "$pid"
        return 0
        ;;
    esac
  done < <(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{session_name} #{pane_pid}')
  return 1
}

restart_test_pier() {
  local target session pid command attempt index log_offset ready=0
  local -a current_command pier_command
  read -r target session pid < <(resolve_pier_tmux) \
    || fail "bootstrap latch fixtures cannot find the tmux pane for $PIER"
  ROVER_TMUX_SESSION="$session"
  if [ "${#ROVER_PIER_COMMAND[@]}" -eq 0 ]; then
    mapfile -d '' current_command < "/proc/$pid/cmdline"
    case "${current_command[0]}" in
      */script|script)
        for index in "${!current_command[@]}"; do
          if [ "${current_command[$index]}" = -c ]; then
            read -r -a pier_command <<<"${current_command[$((index + 1))]}"
            break
          fi
        done
        ;;
      *)
        pier_command=("${current_command[0]}")
        for index in "${!current_command[@]}"; do
          if [ "${current_command[$index]}" = -p ]; then
            pier_command+=(-p "${current_command[$((index + 1))]}")
            break
          fi
        done
        pier_command+=("$PIER")
        ;;
    esac
    [ "${#pier_command[@]}" -gt 0 ] \
      || fail "bootstrap latch fixtures could not reconstruct the command for $PIER"
    ROVER_PIER_COMMAND=("${pier_command[@]}")
  fi
  printf -v command '%q ' "${ROVER_PIER_COMMAND[@]}"
  tmux send-keys -t "$target" '|exit' Enter
  for attempt in $(seq 1 30); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
  done
  kill -0 "$pid" 2>/dev/null \
    && fail "bootstrap latch fixtures could not stop $PIER"
  for attempt in $(seq 1 30); do
    ! pgrep -f "snap-dir $PIER" >/dev/null && break
    sleep 1
  done
  pgrep -f "snap-dir $PIER" >/dev/null \
    && fail "bootstrap latch fixtures found a Rover worker after shutdown"
  if tmux has-session -t "$session" 2>/dev/null; then
    fail "bootstrap latch fixtures found another pane in tmux session $session"
  fi
  : > "$PIER_LOG"
  tmux new-session -d -s "$session" \
    "exec script -q -f -e -O $(printf '%q' "$PIER_LOG") -c $(printf '%q' "$command")"
  for attempt in $(seq 1 120); do
    PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports" 2>/dev/null)"
    if [ -n "$PORT" ] && curl -s -o /dev/null "http://localhost:$PORT/~/login"; then
      ready=1
      break
    fi
    sleep 1
  done
  [ "$ready" = 1 ] \
    || fail "bootstrap latch fixtures could not restart $PIER"
  URL="http://localhost:$PORT"
  CODE="$(derive_code "$PIER")"
  [ -n "$CODE" ] || fail "bootstrap latch fixtures could not derive +code after restart"
  : > "$JAR"
  curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
  grep -q urbauth "$JAR" \
    || fail "bootstrap latch fixtures could not log in after restart"
  log_offset="$(wc -c < "$PIER_LOG")"
  tmux send-keys -t "$session" '|verb' Enter
  for attempt in $(seq 1 30); do
    if tail -c "+$((log_offset + 1))" "$PIER_LOG" | grep -q ':dojo>'; then
      return 0
    fi
    sleep 1
  done
  fail "bootstrap latch fixtures could not enable the private pier trace"
}

restore_pier_output() {
  local target pid command attempt ready=0
  [ -n "$ROVER_TMUX_SESSION" ] || return 0
  printf -v command '%q ' "${ROVER_PIER_COMMAND[@]}"
  if tmux has-session -t "$ROVER_TMUX_SESSION" 2>/dev/null; then
    target="$(tmux list-panes -t "$ROVER_TMUX_SESSION" -F '#{session_name}:#{window_index}.#{pane_index}' | head -1)"
    pid="$(tmux list-panes -t "$ROVER_TMUX_SESSION" -F '#{pane_pid}' | head -1)"
    tmux send-keys -t "$target" '|exit' Enter
    for attempt in $(seq 1 30); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    kill -0 "$pid" 2>/dev/null && return 1
  fi
  tmux has-session -t "$ROVER_TMUX_SESSION" 2>/dev/null && return 1
  tmux new-session -d -s "$ROVER_TMUX_SESSION" "$command"
  for attempt in $(seq 1 120); do
    PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports" 2>/dev/null)"
    if [ -n "$PORT" ] && curl -s -o /dev/null "http://localhost:$PORT/~/login"; then
      ready=1
      break
    fi
    sleep 1
  done
  [ "$ready" -eq 1 ]
}

count_view_probes() {
  local label="$1" trace="$2"
  [ -s "$trace" ] \
    || fail "$label captured an empty trace; the instrument is broken"
  grep -q '%obelisk %poke]' "$trace" \
    || fail "$label captured no Obelisk poke lines at all; refusing to report a count"
  read -r TRACE_PROBES TRACE_VIEWS < <(python3 -c 'import sys
lines = open(sys.argv[1], "rb").read().decode("utf-8").replace("\r", "").splitlines()
def pokes(marker):
    count = 0
    for index, line in enumerate(lines):
        if "%obelisk %poke]" not in line:
            continue
        if marker in "\n".join(lines[index:index + 12]):
            count += 1
    return count
print(pokes("rover-bootstrap-probe"), pokes("rover-http"))' "$trace")
  [ "$TRACE_VIEWS" -ge 1 ] \
    || fail "$label captured $TRACE_VIEWS Rover view pokes; refusing to report a probe count"
}

count_install_pokes() {
  local label="$1" trace="$2"
  [ -s "$trace" ] \
    || fail "$label captured an empty trace; the instrument is broken"
  grep -q '%obelisk %poke]' "$trace" \
    || fail "$label captured no Obelisk poke lines at all; refusing to report install counts"
  read -r INSTALL_PROBES INSTALL_POURS INSTALL_STARTER_CHECKS INSTALL_STARTER_WRITES < <(
    python3 -c 'import sys
lines = open(sys.argv[1], "rb").read().decode("utf-8").replace("\r", "").splitlines()
def pokes(marker):
    return sum(
        marker in "\n".join(lines[index:index + 12])
        for index, line in enumerate(lines)
        if "%obelisk %poke]" in line
    )
print(*(pokes(marker) for marker in (
    "rover-install-probe",
    "rover-install-pour",
    "rover-install-starter-check",
    "rover-install-starter-write",
)))' "$trace"
  )
  [ "$INSTALL_PROBES" -ge 1 ] \
    || fail "$label captured $INSTALL_PROBES install probes; refusing to trust absence counts"
}

reinstall_rover() {
  local result status attempt
  result="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-nuke !>([%rover %.y]))
;<  ~  bind:m  (sleep ~s3)
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-install !>([%rover our.bowl %rover]))
;<  ~  bind:m  (sleep ~s3)
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-revive !>(%rover))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(%rover-installed))')"
  case "$result" in
    *%rover-installed*) ;;
    *) fail "Rover reinstall did not acknowledge: $result" ;;
  esac
  for attempt in $(seq 1 60); do
    status="$(curl -s -b "$JAR" -o /dev/null -w '%{http_code}' "$URL/apps/rover")"
    [ "$status" = 200 ] && return 0
    sleep 1
  done
  fail "Rover did not serve its shell after reinstall"
}

wait_install_ready() {
  local attempt report starters
  for attempt in $(seq 1 "${ROVER_INSTALL_WAIT_ATTEMPTS:-60}"); do
    report="$(read_database_report)"
    if database_exists "$report" rover; then
      starters="$(read_starter_report)"
      if grep -Fq "[%label 116 'Gasoline']" <<<"$starters" &&
         grep -Fq "[%label 116 'Diesel']" <<<"$starters"; then
        return 0
      fi
    fi
    sleep 1
  done
  return 1
}

trace_view_probes() {
  local label="$1" trace body response offset _attempt captured=0
  trace="$BOOTSTRAP_TRACE"
  body="$BOOTSTRAP_VIEW"
  offset="$(wc -c < "$PIER_LOG")"
  response="$(curl -sS -b "$JAR" -o "$body" -w '%{http_code}' "$URL/apps/rover/view")" \
    || fail "$label could not load the Rover view"
  for _attempt in $(seq 1 30); do
    tail -c "+$((offset + 1))" "$PIER_LOG" > "$trace"
    if grep -q 'rover-http' "$trace"; then
      captured=1
      break
    fi
    sleep 1
  done
  [ "$captured" -eq 1 ] \
    || fail "$label did not capture a Rover view trace from the private pier log"
  TRACE_STATUS="$response"
  TRACE_HTML="$(<"$body")"
  count_view_probes "$label" "$trace"
}

read_structure_report() {
  rover_report "$URQL_APP_STRUCTURE"
}

read_starter_report() {
  rover_report "$URQL_STARTER"
}

read_demo_starter_report() {
  rover_report "$URQL_DEMO_STARTER"
}

html_slice() {
  python3 -c 'import sys
start, end = sys.argv[1:3]
document = sys.stdin.read()
left = document.find(start)
if left < 0:
    print("")
    raise SystemExit
right = document.find(end, left + len(start))
print(document[left:] if right < 0 else document[left:right])' "$1" "$2"
}

scoped_view() {
  local page="$1" vehicle="$2"
  curl -s -b "$JAR" -w $'\nROVER_HTTP_STATUS=%{http_code}' \
    -H 'content-type: application/json' \
    --data-binary "$(printf '{\"page\":\"%s\",\"vehicle\":\"%s\"}' "$page" "$vehicle")" \
    "$URL/apps/rover/view"
}

scoped_view_status() {
  sed -n 's/^ROVER_HTTP_STATUS=//p' <<<"$1"
}

scoped_view_html() {
  sed '$d' <<<"$1"
}

if [ -n "${ROVER_BOOTSTRAP_TRACE_CHECK:-}" ]; then
  count_view_probes "bootstrap trace self-check" "$ROVER_BOOTSTRAP_TRACE_CHECK"
  note "bootstrap trace self-check PASS - probe-pokes=$TRACE_PROBES view-pokes=$TRACE_VIEWS"
  exit 0
fi

CODE="$(derive_code "$PIER")"
[ -n "$CODE" ] || fail "could not derive +code"
JAR="$(mktemp /tmp/rover-ui-cookie.XXXXXX)"
HDRS="$(mktemp /tmp/rover-ui-headers.XXXXXX)"
ASSET="$(mktemp /tmp/rover-ui-asset.XXXXXX)"
IMPORT_VEHICLES="$(mktemp /tmp/rover-ui-import-vehicles.XXXXXX.json)"
IMPORT_VERSION="$(mktemp /tmp/rover-ui-import-version.XXXXXX.json)"
IMPORT_FILLS="$(mktemp /tmp/rover-ui-import-fills.XXXXXX.json)"
IMPORT_REFUSED="$(mktemp /tmp/rover-ui-import-refused.XXXXXX.json)"
IMPORT_STATSCOPE="$(mktemp /tmp/rover-ui-import-statscope.XXXXXX.json)"
BOOTSTRAP_TRACE="$(mktemp /tmp/rover-bootstrap-trace.XXXXXX.txt)"
BOOTSTRAP_VIEW="$(mktemp /tmp/rover-bootstrap-view.XXXXXX.html)"
PIER_LOG="$(mktemp /tmp/rover-private-pier.XXXXXX.log)"
declare -a ROVER_PIER_COMMAND=()
ROVER_TMUX_SESSION=""
ROVER_TEST_BACKUP_DB="rovertestowner"
ROVER_TEST_DB_SWAPPED=0

obelisk_mutate() {
  local database="$1" query="$2"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-ui-test-mutation
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %$database %vector \"$query\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
}

read_database_report() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-ui-test-databases
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %sys %vector "FROM sys.sys.databases SELECT database;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)'
}

database_exists() {
  local report="$1" database="$2"
  grep -Fq "[%database %tas %$database]" <<<"$report"
}

rover_row_counts() {
  local report
  report="$(rover_report "FROM fuel-fills F SELECT F.acquisition-id; FROM energy-definitions E WHERE E.label = 'Gasoline' OR E.label = 'Diesel' OR E.label = 'Electricity' OR E.label = 'Propane' OR E.label = 'Hydrogen' OR E.label = 'CNG' OR E.label = 'LNG' OR E.label = 'Ethanol' SELECT E.energy-definition-id, E.label;")"
  printf 'fills=%s starter-energy-definitions=%s\n' \
    "$(grep -o '\[%acquisition-id ' <<<"$report" | wc -l)" \
    "$(grep -o '\[%energy-definition-id ' <<<"$report" | wc -l)"
}

restore_test_database() {
  local database_report
  [ "$ROVER_TEST_DB_SWAPPED" -eq 1 ] || return 0
  database_report="$(read_database_report)"
  if ! database_exists "$database_report" "$ROVER_TEST_BACKUP_DB"; then
    echo "ui-test: cleanup refused: owner backup database is absent" >&2
    return 1
  fi
  if database_exists "$database_report" rover; then
    obelisk_mutate sys "DROP DATABASE FORCE rover" >/dev/null || return 1
  fi
  obelisk_mutate sys "ALTER DATABASE $ROVER_TEST_BACKUP_DB RENAME TO rover" >/dev/null || return 1
  ROVER_TEST_DB_SWAPPED=0
}

cleanup() {
  restore_pier_output \
    || echo "ui-test: cleanup could not restore the normal pier output" >&2
  restore_test_database
  rm -f "$JAR" "$HDRS" "$ASSET" "$IMPORT_VEHICLES" \
    "$IMPORT_VERSION" "$IMPORT_FILLS" "$IMPORT_REFUSED" "$IMPORT_STATSCOPE" \
    "$BOOTSTRAP_TRACE" "$BOOTSTRAP_VIEW" "$PIER_LOG"
}
trap cleanup EXIT

response="$(curl -s -o /dev/null -w '%{http_code} %{size_download} %{redirect_url}' "$URL/apps/rover")"
case "$response" in
  "303 0 $URL/~/login?redirect="*) ;;
  *) fail "logged-out GET /apps/rover -> '$response' (want 303, empty login redirect)" ;;
esac
note "logged-out browser receives login redirect with no Rover body"

curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
grep -q urbauth "$JAR" || fail "login with +code did not yield urbauth cookie"

playwright_module="${ROVER_PLAYWRIGHT_MODULE:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules/playwright}"
chromium_binary="${ROVER_CHROMIUM:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
[ -f "$playwright_module/package.json" ] \
  || fail "fixture 129 Playwright module is unavailable at $playwright_module"
[ -x "$chromium_binary" ] \
  || fail "fixture 129 Chromium is unavailable at $chromium_binary"
auth_cookie_name="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $6; exit}' "$JAR")"
auth_cookie="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $7; exit}' "$JAR")"
normal_status="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/ui-browser-fixtures.cjs" \
      bootstrap-status-normal "$URL" "$auth_cookie_name" "$auth_cookie" '' '' ''
} 2>&1)" || fail "fixture 129 normal status is dishonest: $normal_status"
grep -q '^BOOTSTRAP_STATUS=' <<<"$normal_status" \
  || fail "fixture 129 normal status probe returned no observation: $normal_status"
note "status normal transcript - ${normal_status#*BOOTSTRAP_STATUS=}"
note "fixture 129 PASS - a normal first paint says Loading and no response marker makes a bootstrap claim"
if [ "${ROVER_FIXTURE_STOP:-}" = 129 ]; then
  exit 0
fi

owner_view_before="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
owner_vehicles_before="$(
  python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
screen = document.split("<section id=\"vehicles-screen\"", 1)[1].split("</section>", 1)[0]
active = screen.split("<details class=\"archived-vehicles\"", 1)[0]
labels = sorted(set(re.findall(r"data-open-vehicle-settings data-vehicle=\"([^\"]+)\"", active)))
print("|".join(labels))' <<<"$owner_view_before"
)"

if [ "${ROVER_NO_FIXTURE_ISOLATION:-}" != 1 ]; then
  database_report="$(read_database_report)"
  if database_exists "$database_report" "$ROVER_TEST_BACKUP_DB"; then
    fail "fixture isolation backup database already exists: $ROVER_TEST_BACKUP_DB"
  fi
  rename_result="$(obelisk_mutate sys "ALTER DATABASE rover RENAME TO $ROVER_TEST_BACKUP_DB")"
  database_report="$(read_database_report)"
  database_exists "$database_report" "$ROVER_TEST_BACKUP_DB" \
    || fail "fixture isolation could not verify the renamed owner database: $rename_result"
  if database_exists "$database_report" rover; then
    fail "fixture isolation still sees rover after renaming the owner database"
  fi
  ROVER_TEST_DB_SWAPPED=1
  obelisk_mutate sys "CREATE DATABASE rover" >/dev/null \
    || fail "fixture 124 could not create the unusable database"
  refused_view="$(curl -s -b "$JAR" -w $'\nROVER_HTTP_STATUS=%{http_code}' \
    "$URL/apps/rover/view")"
  [ "$(scoped_view_status "$refused_view")" = 503 ] \
    || fail "fixture 124 unusable database returned $(scoped_view_status "$refused_view"): $refused_view"
  refused_html="$(scoped_view_html "$refused_view")"
  grep -q 'Rover could not load the vehicle log' <<<"$refused_html" \
    || fail "fixture 124 refusal does not name the failed view query: $refused_html"
  if grep -q 'HTTP 503' <<<"$refused_html"; then
    fail "fixture 124 refusal exposes a bare HTTP status: $refused_html"
  fi
  obelisk_mutate sys "DROP DATABASE FORCE rover" >/dev/null \
    || fail "fixture 124 could not remove the unusable database"
  note "fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status"

  restart_test_pier
  install_case="${ROVER_INSTALL_CASE:-all}"
  if [ "$install_case" = idempotence ]; then
    setup_status="$(curl -s -b "$JAR" -o /dev/null -w '%{http_code}' "$URL/apps/rover/view")"
    [ "$setup_status" = 200 ] \
      || fail "fixture 133 could not prepare its populated database: HTTP $setup_status"
  else
    install_offset="$(wc -c < "$PIER_LOG")"
    reinstall_rover
    if ! wait_install_ready; then
      fail "fixture 131 install did not create and seed Rover before any page load"
    fi
    tail -c "+$((install_offset + 1))" "$PIER_LOG" > "$BOOTSTRAP_TRACE"
    count_install_pokes "fixture 131 install bootstrap" "$BOOTSTRAP_TRACE"
    [ "$INSTALL_POURS" -eq 1 ] \
      || fail "fixture 131 install sent $INSTALL_POURS schema pours, want 1"
    [ "$INSTALL_STARTER_CHECKS" -eq 1 ] \
      || fail "fixture 131 install sent $INSTALL_STARTER_CHECKS starter checks, want 1"
    [ "$INSTALL_STARTER_WRITES" -eq 1 ] \
      || fail "fixture 131 install sent $INSTALL_STARTER_WRITES starter writes, want 1"
    note "install bootstrap transcript - page-loads=0 install-probes=$INSTALL_PROBES pours=$INSTALL_POURS starter-checks=$INSTALL_STARTER_CHECKS starter-writes=$INSTALL_STARTER_WRITES database=present starters=Gasoline|Diesel"
    note "fixture 131 PASS - on-init creates and seeds Rover before the first page load"
    if [ "$install_case" = happy ]; then
      exit 0
    fi
  fi

  idempotent_before="$(rover_row_counts)"
  idempotent_offset="$(wc -c < "$PIER_LOG")"
  reinstall_rover
  sleep 3
  idempotent_after="$(rover_row_counts)"
  tail -c "+$((idempotent_offset + 1))" "$PIER_LOG" > "$BOOTSTRAP_TRACE"
  count_install_pokes "fixture 133 populated install" "$BOOTSTRAP_TRACE"
  [ "$INSTALL_POURS" -eq 0 ] \
    || fail "fixture 133 populated install sent $INSTALL_POURS schema pours, want 0"
  [ "$idempotent_after" = "$idempotent_before" ] \
    || fail "fixture 133 populated install changed rows: before=$idempotent_before after=$idempotent_after"
  note "install idempotence transcript - install-probes=$INSTALL_PROBES pours=$INSTALL_POURS before=$idempotent_before after=$idempotent_after"
  note "fixture 133 PASS - install against populated Rover re-pours nothing and changes no row counts"
  if [ "$install_case" = idempotence ]; then
    exit 0
  fi

  obelisk_mutate sys "DROP DATABASE FORCE rover" >/dev/null \
    || fail "fixture 130 could not remove Rover before the marked lazy bootstrap"

  bootstrap_offset="$(wc -c < "$PIER_LOG")"
  bootstrap_status="$({
    ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
    ROVER_CHROMIUM="$chromium_binary" \
      node "$REPO/bin/ui-browser-fixtures.cjs" \
        bootstrap-status-performed "$URL" "$auth_cookie_name" "$auth_cookie" '' '' ''
  } 2>&1)" || fail "fixture 130 bootstrap status is dishonest: $bootstrap_status"
  bootstrap_captured=0
  for _attempt in $(seq 1 30); do
    tail -c "+$((bootstrap_offset + 1))" "$PIER_LOG" > "$BOOTSTRAP_TRACE"
    if grep -q 'rover-http' "$BOOTSTRAP_TRACE"; then
      bootstrap_captured=1
      break
    fi
    sleep 1
  done
  [ "$bootstrap_captured" -eq 1 ] \
    || fail "fixtures 122 and 130 did not capture the cold browser trace"
  count_view_probes "fixtures 122 and 130 cold browser" "$BOOTSTRAP_TRACE"
  [ "$TRACE_PROBES" = 1 ] \
    || fail "fixtures 122, 128, and 130 cold browser sent $TRACE_PROBES database probes, want 1"
  note "fixture 128 PASS - the cold path proves the probe counter is live before any zero-probe assertion"
  grep -q '"gasoline":true' <<<"$bootstrap_status" \
    || fail "fixture 122 cold view has no Gasoline starter"
  grep -q '"diesel":true' <<<"$bootstrap_status" \
    || fail "fixture 122 cold view has no Diesel starter"
  grep -q '"emptyState":true' <<<"$bootstrap_status" \
    || fail "fixture 122 cold view has no usable empty state"
  database_report="$(read_database_report)"
  database_exists "$database_report" rover \
    || fail "fixture 122 cold view did not create the disposable rover database"
  database_exists "$database_report" "$ROVER_TEST_BACKUP_DB" \
    || fail "fixture isolation lost the renamed owner database"
  note "status bootstrap transcript - ${bootstrap_status#*BOOTSTRAP_STATUS=}"
  note "fixture 130 PASS - a response that performs bootstrap carries the marker and the shell echoes the setup status"
  note "bootstrap cold transcript - database-before=absent GET-status=200 probe-pokes=$TRACE_PROBES view-pokes=$TRACE_VIEWS starters=Gasoline|Diesel empty-state=Add-a-fill-to-begin-tracking"
  note "fixture 122 PASS - a cold GET creates the database, seeds starters, and serves the usable empty state"

  trace_view_probes "fixture 125 second view"
  [ "$TRACE_STATUS" = 200 ] \
    || fail "fixture 125 second view returned $TRACE_STATUS: $TRACE_HTML"
  [ "$TRACE_PROBES" = 0 ] \
    || fail "fixture 125 second view sent $TRACE_PROBES database probes, want 0"
  note "bootstrap second-load transcript - GET-status=$TRACE_STATUS probe-pokes=$TRACE_PROBES view-pokes=$TRACE_VIEWS"
  note "fixture 125 PASS - the second view skips the database probe"

  restart_counts_before="$(rover_row_counts)"
  restart_test_pier
  trace_view_probes "fixture 126 restarted view"
  [ "$TRACE_STATUS" = 200 ] \
    || fail "fixture 126 restarted view returned $TRACE_STATUS: $TRACE_HTML"
  [ "$TRACE_PROBES" = 0 ] \
    || fail "fixture 126 restarted view sent $TRACE_PROBES database probes, want 0"
  restart_counts_after="$(rover_row_counts)"
  [ "$restart_counts_after" = "$restart_counts_before" ] \
    || fail "fixture 126 restart changed data: before=$restart_counts_before after=$restart_counts_after"
  note "bootstrap restart transcript - GET-status=$TRACE_STATUS probe-pokes=$TRACE_PROBES view-pokes=$TRACE_VIEWS before=$restart_counts_before after=$restart_counts_after"
  note "fixture 126 PASS - the saved latch skips the probe after restart and keeps the data"

  obelisk_mutate sys "DROP DATABASE FORCE rover" >/dev/null \
    || fail "fixture 127 could not remove the isolated Rover database"
  trace_view_probes "fixture 127 self-heal view"
  [ "$TRACE_STATUS" = 200 ] \
    || fail "fixture 127 self-heal view returned $TRACE_STATUS: $TRACE_HTML"
  [ "$TRACE_PROBES" = 1 ] \
    || fail "fixture 127 self-heal sent $TRACE_PROBES database probes, want 1"
  database_report="$(read_database_report)"
  database_exists "$database_report" rover \
    || fail "fixture 127 self-heal did not restore the Rover database"
  grep -q '>Gasoline</option>' <<<"$TRACE_HTML" \
    || fail "fixture 127 self-heal did not restore the starter definitions"
  note "bootstrap self-heal transcript - database-before=absent GET-status=$TRACE_STATUS probe-pokes=$TRACE_PROBES view-pokes=$TRACE_VIEWS database-after=present starter=Gasoline"
  note "fixture 127 PASS - one failed latched view re-probes, restores the database, and serves"
  if [ "${ROVER_BOOTSTRAP_LATCH_ONLY:-}" = 1 ]; then
    exit 0
  fi
fi

body="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "authenticated GET /apps/rover not 200"
grep -qi '^content-type: text/html' "$HDRS" || fail "shell content-type is not text/html"
grep -q 'ROVER' <<<"$body" || fail "served shell has no Rover designation"
note "authenticated Rover shell served over real Eyre"
if grep -q '~bel' <<<"$body"; then
  fail "fixture 103 served shell still carries the hardcoded ~bel footer identity"
fi
note "fixture 103 PASS - served footer carries the Rover label and no hardcoded ship literal"
if [ "${ROVER_FIXTURE_STOP:-}" = 103 ]; then
  exit 0
fi

grep -q -- '--rv-bg: #0b0a08' <<<"$body" || fail "UA 571-C background token missing"
grep -q -- '--rv-amber: #d8b843' <<<"$body" || fail "UA 571-C amber token missing"
[ "$(grep -c '@font-face' <<<"$body")" -eq 2 ] || fail "shell does not declare the two JetBrains Mono faces"
grep -q 'font-feature-settings: "zero" 1' <<<"$body" || fail "slashed-zero feature is not enabled"
grep -q 'slashed-zero tabular-nums' <<<"$body" || fail "slashed-zero numeric variant is not set"
grep -q 'font-variant-numeric: slashed-zero tabular-nums' <<<"$body" || fail "tabular numerals are not active"
grep -q 'id="glow-toggle"' <<<"$body" || fail "glow control is missing"
grep -q 'min-height: 44px' <<<"$body" || fail "44px touch target rule is missing"
grep -q '@media (min-width: 48rem)' <<<"$body" || fail "mobile-first wide breakpoint is missing"
grep -q 'overflow-x: hidden' <<<"$body" || fail "narrow viewport overflow guard is missing"
note "UA 571-C palette, fonts, glow control, and mobile rules served"

if [ "${ROVER_T11_ONLY:-}" != 1 ]; then
view="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover/view")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "vehicle view not 200"
if [ "${ROVER_LEGACY_ONLY:-}" != 1 ]; then
starter_sources="$(
  python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
labels = re.findall(r"<option[^>]+data-starter-source[^>]*>([^<]+)</option>", document)
print("|".join(sorted(set(label.strip() for label in labels))))' <<<"$view"
)"
expected_sources='CNG|Diesel|Electricity|Ethanol|Gasoline|Hydrogen|LNG|Propane'
[ "$starter_sources" = "$expected_sources" ] \
  || fail "fixture 68 served Energy Source set is not exactly the eight starters; actual labels: ${starter_sources:-<none>}"
if grep -Eq '<option[^>]+data-starter-source[^>]*>(Structure |Pricing |Location Fixture )' <<<"$view"; then
  fail "fixture 32 fixture-debris definition remains in served live data"
fi
note "fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels"
note "fixture 68 PASS - served Energy Source set is exactly the eight starters with zero Demo definitions"
if [ "${ROVER_FRESH_ONLY:-}" = 1 ]; then
  fresh_summary="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
pairs = set(re.findall(
    r"<option value=\"([^\"]+)\" data-definition=\"([^\"]+)\">",
    document,
))
subtypes = "|".join(sorted(f"{definition}:{label}" for label, definition in pairs))
additives = "|".join(sorted(set(re.findall(
    r"name=\"additives\" value=\"([^\"]+)\"",
    document,
))))
mode_match = re.search(
    r"<select name=\"drivingModes\" multiple>(.*?)</select>",
    document,
    re.S,
)
modes = "|".join(sorted(set(re.findall(
    r"<option[^>]*>([^<]+)</option>",
    mode_match.group(1) if mode_match else "",
))))
consumable_match = re.search(
    r"<select name=\"consumable\" required>(.*?)</select>",
    document,
    re.S,
)
consumables = "|".join(sorted(set(re.findall(
    r"<option[^>]*>([^<]+)</option>",
    consumable_match.group(1) if consumable_match else "",
))))
print(f"{subtypes}\n{additives}\n{modes}\n{consumables}")' <<<"$view"
  )"
  mapfile -t fresh_parts <<<"$fresh_summary"
  expected_subtypes='CNG:CNG|Diesel:#1|Diesel:#2|Diesel:Arctic|Diesel:B20|Diesel:B7|Diesel:HVO100|Diesel:Off-road (dyed)|Diesel:Premium|Diesel:R99|Diesel:Winter|Electricity:AC Level 1|Electricity:AC Level 2|Electricity:DC Fast|Ethanol:E100 hydrous|Ethanol:E85|Gasoline:100|Gasoline:85|Gasoline:87|Gasoline:88|Gasoline:89|Gasoline:90|Gasoline:91|Gasoline:92|Gasoline:93|Gasoline:95|Gasoline:98|Hydrogen:H35|Hydrogen:H70|LNG:LNG|Propane:Autogas|Propane:HD-5'
  [ "${fresh_parts[0]:-}" = "$expected_subtypes" ] ||
    fail "fixture 57 starter subtype set mismatch; actual: ${fresh_parts[0]:-<none>}"
  [ "${fresh_parts[1]:-}" = 'Fuel stabilizer|Injector cleaner' ] ||
    fail "fixture 57 starter additive set mismatch; actual: ${fresh_parts[1]:-<none>}"
  [ "${fresh_parts[2]:-}" = 'Economy|Normal|Sport|Towing|Winter' ] ||
    fail "fixture 57 starter driving-mode set mismatch; actual: ${fresh_parts[2]:-<none>}"
  [ "${fresh_parts[3]:-}" = 'Coolant|DEF|Motor Oil|Washer Fluid' ] ||
    fail "fixture 57 starter consumable set mismatch; actual: ${fresh_parts[3]:-<none>}"
  if grep -Eq 'Structure |Pricing |Location Fixture |Fixture Vehicle|Phase A Vehicle' <<<"$view"; then
    fail "fixture 57 fresh served database contains scenario fixture data"
  fi
  note "fixture 57 PASS - fresh ship serves exact energy, subtype, additive, driving-mode, and consumable starter packs with zero scenario data"
  grep -q 'Add a fill to begin tracking economy' <<<"$view" ||
    fail "fixture 62 no-fill statistics state lacks the dedicated getting-started message"
  if grep -Eq 'Adjacent odometer-linked full fills|Two eligible ordered fills|Tank size and an eligible economy interval' <<<"$view"; then
    fail "fixture 62 no-fill statistics state leaks interval-not-eligible wording"
  fi
  note "fixture 62 PASS - starter-only ship shows a no-data-yet instruction distinct from interval refusal reasons"
  exit 0
fi
if [ "${ROVER_FIXTURE_STOP:-}" = 32 ]; then
  exit 0
fi

if [ "${ROVER_DEMO_ONLY:-}" = 1 ]; then
  demo_pack_check="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
pairs = set(re.findall(
    r"<option value=\"([^\"]+)\" data-definition=\"([^\"]+)\">",
    document,
))
required_pairs = {
    ("CNG", "CNG"),
    ("#1", "Diesel"), ("#2", "Diesel"), ("Arctic", "Diesel"),
    ("B20", "Diesel"), ("B7", "Diesel"), ("HVO100", "Diesel"),
    ("Off-road (dyed)", "Diesel"), ("Premium", "Diesel"),
    ("R99", "Diesel"), ("Winter", "Diesel"),
    ("AC Level 1", "Electricity"), ("AC Level 2", "Electricity"),
    ("DC Fast", "Electricity"),
    ("E100 hydrous", "Ethanol"), ("E85", "Ethanol"),
    ("100", "Gasoline"), ("85", "Gasoline"), ("87", "Gasoline"),
    ("88", "Gasoline"), ("89", "Gasoline"), ("90", "Gasoline"),
    ("91", "Gasoline"), ("92", "Gasoline"), ("93", "Gasoline"),
    ("95", "Gasoline"), ("98", "Gasoline"),
    ("H35", "Hydrogen"), ("H70", "Hydrogen"),
    ("LNG", "LNG"), ("Autogas", "Propane"), ("HD-5", "Propane"),
}
required_additives = {"Fuel stabilizer", "Injector cleaner"}
required_options = {
    "Economy", "Normal", "Sport", "Towing", "Winter",
    "Coolant", "DEF", "Motor Oil", "Washer Fluid",
}
missing_pairs = sorted(required_pairs - pairs)
missing_additives = sorted(
    label for label in required_additives
    if f"name=\"additives\" value=\"{label}\"" not in document
)
missing_options = sorted(
    label for label in required_options
    if f">{label}</option>" not in document
)
print("yes" if not missing_pairs and not missing_additives and not missing_options else
      f"missing pairs={missing_pairs!r} additives={missing_additives!r} options={missing_options!r}")' <<<"$view"
  )"
  [ "$demo_pack_check" = yes ] \
    || fail "fixture 57 populated starter-pack control failed: $demo_pack_check"
  note "fixture 57 PASS - demo run serves every starter subtype, additive, driving mode, and consumable alongside the exact eight source starters"
fi

settings_vehicle="Fixture 70 Settings $(date +%s%N)"
settings_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Gasoline"}' "$settings_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$settings_created" = "Added vehicle - $settings_vehicle"$'\n201' ] \
  || fail "fixture 70 setup vehicle failed: $settings_created"
settings_tank_first="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"17.5","tankUnit":"gal","defaultSubtype":"87","energySources":["Gasoline"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_vehicle" "$settings_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_tank_first" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 70 first tank-size edit failed: $settings_tank_first"
settings_tank_second="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"18.5","tankUnit":"gal","defaultSubtype":"87","energySources":["Gasoline"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_vehicle" "$settings_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_tank_second" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 70 second tank-size edit failed: $settings_tank_second"
settings_tank_report="$(rover_report "$(urql_vehicle_settings "$settings_vehicle")")"
grep -q '\[%digits 25717 185\] \[%decimals 25717 1\] \[%size-unit %tas %gal\]' \
  <<<"$settings_tank_report" \
  || fail "fixture 70 second tank size did not persist exactly: $settings_tank_report"
note "fixture 70 PASS - two consecutive tank-size edits succeeded and the second exact value persisted"
if [ "${ROVER_FIXTURE_STOP:-}" = 70 ]; then
  exit 0
fi

settings_subtype_first="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"18.5","tankUnit":"gal","defaultSubtype":"91","energySources":["Gasoline"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_vehicle" "$settings_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_subtype_first" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 71 first default-subtype edit failed: $settings_subtype_first"
settings_subtype_second="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"18.5","tankUnit":"gal","defaultSubtype":"93","energySources":["Gasoline"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_vehicle" "$settings_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_subtype_second" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 71 second default-subtype edit failed: $settings_subtype_second"
settings_subtype_report="$(rover_report "$(urql_vehicle_settings "$settings_vehicle")")"
grep -q '\[%default-subtype 116 13113\]' <<<"$settings_subtype_report" \
  || fail "fixture 71 second default subtype did not persist: $settings_subtype_report"
note "fixture 71 PASS - two consecutive default-subtype edits succeeded and the latest subtype persisted"
if [ "${ROVER_FIXTURE_STOP:-}" = 71 ]; then
  exit 0
fi

settings_combined="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"20.25","tankUnit":"gal","defaultSubtype":"87","energySources":["Gasoline"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_vehicle" "$settings_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_combined" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 72 combined tank/subtype edit failed: $settings_combined"
settings_combined_report="$(rover_report "$(urql_vehicle_settings "$settings_vehicle")")"
grep -q '\[%digits 25717 2025\] \[%decimals 25717 2\] \[%size-unit %tas %gal\]' \
  <<<"$settings_combined_report" \
  || fail "fixture 72 combined tank size did not persist exactly: $settings_combined_report"
grep -q '\[%default-subtype 116 14136\]' <<<"$settings_combined_report" \
  || fail "fixture 72 combined default subtype did not persist: $settings_combined_report"
note "fixture 72 PASS - one submission persisted both exact tank size and default subtype"
if [ "${ROVER_FIXTURE_STOP:-}" = 72 ]; then
  exit 0
fi

settings_cleared="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"87","energySources":["Gasoline"],"drivingModes":[],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_vehicle" "$settings_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_cleared" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 73 clear tank-size edit failed: $settings_cleared"
settings_cleared_report="$(rover_report "$(urql_vehicle_settings "$settings_vehicle")")"
if grep -q '\[%size-unit ' <<<"$settings_cleared_report"; then
  fail "fixture 73 clear left a vehicle-tank-size row: $settings_cleared_report"
fi
settings_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s"}' "$settings_vehicle")" \
  "$URL/apps/rover/set-default-vehicle")"
[ "$settings_default" = $'Saved default vehicle\n201' ] \
  || fail "fixture 73 could not set settings vehicle as default: $settings_default"
settings_clear_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
settings_clear_hub="$(html_slice 'id="main-hub"' 'id="add-fill"' <<<"$settings_clear_view")"
grep -q '<strong>Unavailable</strong>' <<<"$settings_clear_hub" \
  || fail "fixture 73 cleared tank did not make distance-to-next-fill unavailable"
grep -q 'Tank size is not recorded for this vehicle.' <<<"$settings_clear_hub" \
  || fail "fixture 73 cleared tank lacks the concrete unavailable reason: $settings_clear_hub"
note "fixture 73 PASS - clearing tank size leaves no row and restores the hub unavailable reason"
if [ "${ROVER_DEMO_ONLY:-}" = 1 ]; then
  PLAYWRIGHT_ROOT="${PLAYWRIGHT_ROOT:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules}"
  CHROMIUM_BIN="${CHROMIUM_BIN:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
  [ -d "$PLAYWRIGHT_ROOT/playwright" ] \
    || fail "fixture 62 Playwright package not found at $PLAYWRIGHT_ROOT"
  [ -x "$CHROMIUM_BIN" ] \
    || fail "fixture 62 Chromium not found at $CHROMIUM_BIN"
  settings_no_data_summary="$(
    URL="$URL" JAR="$JAR" CHROMIUM_BIN="$CHROMIUM_BIN" \
      NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_BIN
  });
  const page = await browser.newPage();
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/\s(urbauth-[^\s]+)\s+([^\s]+)/);
  await page.context().addCookies([{
    name: cookie[1], value: cookie[2], domain: 'localhost', path: '/'
  }]);
  await page.goto(`${process.env.URL}/apps/rover`);
  await page.locator('[data-open-screen="statistics-screen"]').click();
  const empty = page.locator('#statistics-screen [data-statistics-state="no-data"]');
  const visible = await empty.isVisible();
  const text = (await empty.innerText()).replace(/\s+/g, ' ').trim();
  const rows = await page.locator('section.stat-table tbody tr:visible').count();
  console.log(`${visible}|${text}|${rows}`);
  await browser.close();
})().catch(error => {
  console.error(error);
  process.exit(1);
});
NODE
  )" || fail "fixture 62 Chromium no-fill statistics check failed"
  [ "$settings_no_data_summary" = 'true|No data yet Add a fill to begin tracking economy.|0' ] \
    || fail "fixture 62 no-fill scoped statistics state is not empty: $settings_no_data_summary"
  note "fixture 62 PASS - a scoped no-fill vehicle shows an explicit no-data state with zero visible interval rows"
fi
if [ "${ROVER_FIXTURE_STOP:-}" = 73 ]; then
  exit 0
fi

settings_label_first="$settings_vehicle First"
settings_other_first="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"91","energySources":["Gasoline","Electricity"],"drivingModes":["Economy"],"defEnabled":"yes","defTankSize":"5.5","defTankUnit":"gal"}' "$settings_vehicle" "$settings_label_first")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_other_first" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 74 first all-settings edit failed: $settings_other_first"
settings_other_first_report="$(rover_report "$(urql_vehicle_settings "$settings_label_first")")"
grep -q "\\[%vehicle 116 '$settings_label_first'\\]" <<<"$settings_other_first_report" \
  || fail "fixture 74 first label edit did not persist: $settings_other_first_report"
grep -q "\\[%energy 116 'Electricity'\\].*\\[%link-archived 102 1\\]" \
  <<<"$settings_other_first_report" \
  || fail "fixture 74 first energy-source edit did not persist: $settings_other_first_report"
grep -q "\\[%driving-mode 116 'Economy'\\].*\\[%link-archived 102 1\\]" \
  <<<"$settings_other_first_report" \
  || fail "fixture 74 first driving-mode edit did not persist: $settings_other_first_report"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%link-archived 102 1\\]" \
  <<<"$settings_other_first_report" \
  || fail "fixture 74 first DEF enablement did not persist: $settings_other_first_report"
grep -q '\[%digits 25717 55\] \[%decimals 25717 1\] \[%unit %tas %gal\]' \
  <<<"$settings_other_first_report" \
  || fail "fixture 74 first DEF tank size did not persist: $settings_other_first_report"

settings_label_second="$settings_vehicle Second"
settings_other_second="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"93","energySources":["Gasoline","Diesel"],"drivingModes":["Sport"],"defEnabled":"yes","defTankSize":"6.5","defTankUnit":"gal"}' "$settings_label_first" "$settings_label_second")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_other_second" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 74 second all-settings edit failed: $settings_other_second"
settings_other_second_report="$(rover_report "$(urql_vehicle_settings "$settings_label_second")")"
grep -q "\\[%vehicle 116 '$settings_label_second'\\]" <<<"$settings_other_second_report" \
  || fail "fixture 74 second label edit did not persist: $settings_other_second_report"
grep -q "\\[%energy 116 'Diesel'\\].*\\[%link-archived 102 1\\]" \
  <<<"$settings_other_second_report" \
  || fail "fixture 74 second energy-source edit did not persist: $settings_other_second_report"
grep -q "\\[%energy 116 'Electricity'\\].*\\[%link-archived 102 0\\]" \
  <<<"$settings_other_second_report" \
  || fail "fixture 74 replaced energy source was not archived: $settings_other_second_report"
grep -q "\\[%driving-mode 116 'Sport'\\].*\\[%link-archived 102 1\\]" \
  <<<"$settings_other_second_report" \
  || fail "fixture 74 second driving-mode edit did not persist: $settings_other_second_report"
grep -q "\\[%driving-mode 116 'Economy'\\].*\\[%link-archived 102 0\\]" \
  <<<"$settings_other_second_report" \
  || fail "fixture 74 replaced driving mode was not archived: $settings_other_second_report"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%link-archived 102 1\\]" \
  <<<"$settings_other_second_report" \
  || fail "fixture 74 second DEF enablement did not persist: $settings_other_second_report"
grep -q '\[%digits 25717 65\] \[%decimals 25717 1\] \[%unit %tas %gal\]' \
  <<<"$settings_other_second_report" \
  || fail "fixture 74 second DEF tank size did not persist: $settings_other_second_report"

settings_preference_first="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","distanceUnit":"mi","currency":"usd"}' "$settings_label_second")" \
  "$URL/apps/rover/set-preference")"
[ "$settings_preference_first" = $'Saved display preference - mi\n201' ] \
  || fail "fixture 74 first display-preference edit failed: $settings_preference_first"
settings_preference_second="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","distanceUnit":"km","currency":"eur"}' "$settings_label_second")" \
  "$URL/apps/rover/set-preference")"
[ "$settings_preference_second" = $'Saved display preference - km\n201' ] \
  || fail "fixture 74 second display-preference edit failed: $settings_preference_second"
settings_other_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
settings_other_panel="$(html_slice "data-vehicle-settings-panel data-vehicle=\"$settings_label_second\"" '</article>' <<<"$settings_other_view")"
grep -q 'value="km" selected' <<<"$settings_other_panel" \
  || fail "fixture 74 latest distance display preference did not re-render"
grep -q 'value="eur" selected' <<<"$settings_other_panel" \
  || fail "fixture 74 latest currency display preference did not re-render"

settings_def_clear="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"93","energySources":["Gasoline","Diesel"],"drivingModes":["Sport"],"defEnabled":"yes","defTankSize":"","defTankUnit":"gal"}' "$settings_label_second" "$settings_label_second")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_def_clear" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 74 clearing the optional DEF tank size failed: $settings_def_clear"
settings_def_clear_report="$(rover_report "$(urql_vehicle_settings "$settings_label_second")")"
if grep -q '\[%unit %tas %gal\]' <<<"$settings_def_clear_report"; then
  fail "fixture 74 clearing optional DEF tank size left a child row: $settings_def_clear_report"
fi

settings_def_disabled="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"93","energySources":["Gasoline","Diesel"],"drivingModes":["Sport"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_label_second" "$settings_label_second")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_def_disabled" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 74 disabling DEF failed: $settings_def_disabled"
settings_def_disabled_report="$(rover_report "$(urql_vehicle_settings "$settings_label_second")")"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%link-archived 102 0\\]" \
  <<<"$settings_def_disabled_report" \
  || fail "fixture 74 disabling DEF did not archive its membership: $settings_def_disabled_report"

settings_def_reenabled="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"93","energySources":["Gasoline","Diesel"],"drivingModes":["Sport"],"defEnabled":"yes","defTankSize":"","defTankUnit":"gal"}' "$settings_label_second" "$settings_label_second")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_def_reenabled" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 74 re-enabling DEF failed: $settings_def_reenabled"
settings_def_reenabled_report="$(rover_report "$(urql_vehicle_settings "$settings_label_second")")"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%link-archived 102 1\\]" \
  <<<"$settings_def_reenabled_report" \
  || fail "fixture 74 re-enabling DEF did not restore its membership: $settings_def_reenabled_report"
if grep -q '\[%unit %tas %gal\]' <<<"$settings_def_reenabled_report"; then
  fail "fixture 74 re-enabling DEF without a tank size recreated a child row: $settings_def_reenabled_report"
fi
note "fixture 74 PASS - label, display preference, energy sources, driving modes, DEF enablement, and DEF tank size survive repeated edits"
if [ "${ROVER_FIXTURE_STOP:-}" = 74 ]; then
  exit 0
fi

if [ "${ROVER_DEMO_ONLY:-}" = 1 ]; then
  seed_demo_fuel_via_eyre
  demo_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline"}' \
    "$URL/apps/rover/set-default-vehicle")"
  [ "$demo_default" = $'Saved default vehicle\n201' ] \
    || fail "fixture 63 could not set the demo app-default-vehicle: $demo_default"
  demo_before_def="$(scoped_view_html "$(scoped_view 0 'Rover Demo Gasoline')")"
  demo_diesel_before_def="$(scoped_view_html "$(scoped_view 0 'Rover Demo Diesel')")"
  demo_summary="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
def values(vehicle):
    return sorted(v for v in re.findall(
        rf"data-economy-vehicle=\"{re.escape(vehicle)}\" data-economy=\"([^\"]+)\"",
        document,
    ) if v != "Unavailable")
gas = values("Rover Demo Gasoline")
diesel = values("Rover Demo Diesel")
computed = {
    "economy": bool(gas and diesel),
    "cost": "data-fuel-cost=" in document,
    "distance": "data-distance-between-fills=" in document,
    "time": "data-time-between-fills=" in document,
    "price": "data-average-price=" in document,
    "tank": "data-distance-per-tank=" in document,
}
print("|".join(gas))
print("|".join(diesel))
print("|".join(name for name, present in computed.items() if present))
print("yes" if "data-economy-break=\"%missed-fill\"" in document else "no")' \
      <<<"$demo_before_def$demo_diesel_before_def"
  )"
  mapfile -t demo_parts <<<"$demo_summary"
  [ "$(tr '|' '\n' <<<"${demo_parts[0]:-}" | grep -c ' mpg$')" -ge 4 ] ||
    fail "fixture 58 gasoline demo has fewer than four computed human-unit intervals: ${demo_parts[0]:-<none>}"
  [ "$(tr '|' '\n' <<<"${demo_parts[1]:-}" | grep -c ' mpg$')" -ge 5 ] ||
    fail "fixture 58 diesel demo has fewer than five computed human-unit intervals: ${demo_parts[1]:-<none>}"
  note "fixture 58 PASS - six full fills per demo vehicle render real interval economy: gas=${demo_parts[0]} diesel=${demo_parts[1]}"
  demo_fill_truth="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
rows = []
for article in re.findall(r"<article class=\"history-table-row\" data-history-vehicle=\"Rover Demo Gasoline\">.*?</article>", document, re.S):
    date = re.search(r"data-history-column=\"DATE\">([^<]+)", article)
    odo = re.search(r"data-history-column=\"ODOMETER\">([^<]+)", article)
    partial = re.search(r"<dt>Partial fill</dt><dd><label[^>]*><input type=\"checkbox\" disabled( checked)?", article)
    if date and odo and partial:
        rows.append((date.group(1).strip(), "partial" if partial.group(1) else "full", odo.group(1).strip()))
rows.sort()
for row in rows:
    print("|".join(row))
print("ELIGIBLE=" + ("yes" if len(rows) >= 2 and all(state == "full" and odo != "Not recorded" for _, state, odo in rows) else "no"))' <<<"$demo_before_def"
  )"
  grep -q '^ELIGIBLE=yes$' <<<"$demo_fill_truth" \
    || fail "fixture 76 demo gasoline lacks a genuine linked full-to-full interval: $demo_fill_truth"
  note "fixture 76 PASS - observed-order gasoline rows are odometer-linked full fills: $(tr '\n' ';' <<<"$demo_fill_truth")"

  hub_truth="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
hub = document.split("<section id=\"main-hub\"", 1)[1].split("<section id=\"add-fill\"", 1)[0]
rows = []
for article in re.findall(r"<article[^>]*>(.*?)</article>", hub, re.S):
    label = re.search(r"<span>(.*?)</span>", article, re.S)
    value = re.search(r"<strong>(.*?)</strong>", article, re.S)
    reason = re.search(r"<small>(.*?)</small>", article, re.S)
    if label and value and reason:
        clean = lambda text: re.sub(r"<[^>]+>", "", text).strip()
        rows.append((clean(label.group(1)), clean(value.group(1)), clean(reason.group(1))))
for row in rows:
    print("|".join(row))
required = rows[:6]
print("COMPUTED=" + ("yes" if len(required) == 6 and all(value != "Unavailable" for _, value, _ in required) else "no"))
print("DEF_REASON=" + ("yes" if len(rows) > 6 and rows[6][1] == "Unavailable" and "purchase" in rows[6][2].lower() else "no"))' <<<"$demo_before_def"
  )"
  grep -q '^COMPUTED=yes$' <<<"$hub_truth" \
    || fail "fixture 77 default-vehicle hub still has a non-computing readout: $hub_truth"
  grep -q '^DEF_REASON=yes$' <<<"$hub_truth" \
    || fail "fixture 77 genuinely unavailable DEF readout lacks a factual reason: $hub_truth"
  note "fixture 77 PASS - every gasoline hub readout computes; DEF alone refuses with its factual no-purchase reason"

  tank_honesty="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
history = re.findall(r"<article class=\"history-table-row\" data-history-vehicle=\"Rover Demo Gasoline\">.*?</article>", document, re.S)
panel = re.search(r"<article class=\"vehicle-card\" data-vehicle-settings-panel data-vehicle=\"Rover Demo Gasoline\".*?</article>", document, re.S)
history_partial = bool(history and re.search(r"<dt>Partial fill</dt>.*?<input type=\"checkbox\" disabled checked", history[0], re.S))
settings_partial = bool(panel and re.search(r"<dt>PARTIAL FILL</dt>.*?<input type=\"checkbox\" disabled checked", panel.group(0), re.S))
print(f"{history_partial}|{settings_partial}")' <<<"$demo_before_def"
  )"
  [ "$tank_honesty" = 'False|False' ] \
    || fail "fixture 78 History and vehicle settings disagree about the same stored full fill: $tank_honesty"
  note "fixture 78 PASS - History and vehicle settings both render the stored full state as an unchecked Partial fill checkbox"

  grep -q 'name="energySources" value="Gasoline" checked' <<<"$demo_before_def" \
    || fail "fixture 81 energy sources are not checkbox controls"
  grep -q 'name="drivingModes" value=' <<<"$demo_before_def" \
    || fail "fixture 81 driving modes are not checkbox controls"
  grep -q 'data-add-energy-source' <<<"$demo_before_def" \
    || fail "fixture 81 energy-source add control is missing"
  grep -q 'data-add-driving-mode' <<<"$demo_before_def" \
    || fail "fixture 81 driving-mode add control is missing"
  note "fixture 81 PASS - vehicle energy sources and driving modes are checkbox groups with add controls"

  average_truth="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
section = document.split("data-statistic=\"average-price-per-unit\"", 1)[1].split("</section>", 1)[0]
rows = re.findall(r"<tr data-statistics-vehicle=\"Rover Demo Gasoline\"[^>]*data-average-price=\"([^\"]+)\"[^>]*>(.*?)</tr>", section, re.S)
print(f"{len(rows)}|" + (rows[0][0] if rows else ""))' <<<"$demo_before_def"
  )"
  [ "$average_truth" = '1|$3.497' ] \
    || fail "fixture 83 lifetime mean is not the hand-checked 20,984 mills / 6 = 3,497 mills: $average_truth"
  note "fixture 83 PASS - one lifetime row reports the exact half-up mean \$3.497 from six fills"
  [ "${demo_parts[2]:-}" = 'economy|cost|distance|time|price|tank' ] ||
    fail "fixture 59 pre-DEF computed statistics mismatch: ${demo_parts[2]:-<none>}"
  [ "${demo_parts[3]:-}" = yes ] ||
    fail "fixture 60 deliberate missed-fill interval lacks its explicit reason"
  grep -q '28.000 mpg' <<<"${demo_parts[0]}" ||
    fail "fixture 60 computed gasoline interval before break is absent"
  grep -q '27.000 mpg' <<<"${demo_parts[0]}" ||
    fail "fixture 60 computed gasoline interval after break is absent"
  note "fixture 60 PASS - missed-fill interval is unavailable with reason while 28.000 mpg and 27.000 mpg neighbours compute"

  break_truth="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
row = re.search(
    r"<tr[^>]*data-economy-break=\"%missed-fill\"[^>]*>(.*?)</tr>",
    document,
    re.S,
)
card = re.search(
    r"<article class=\"history-card fill\">"
    r"(?:(?!</article>).)*2026-07-04 12:00:00"
    r"(?:(?!</article>).)*</article>",
    document,
    re.S,
)
history = re.search(
    r"<article class=\"history-table-row\" data-history-vehicle=\"Rover Demo Gasoline\">"
    r"(?:(?!</article>).)*2026-07-04 12:00:00"
    r"(?:(?!</article>).)*</article>",
    document,
    re.S,
)
sentence = "A missed fill was recorded, so this economy interval is unavailable."
print("ROW=" + ("yes" if row and "Unavailable" in row.group(1) and sentence in row.group(1) else "no"))
card_ok = card and all(value in card.group(0) for value in (
    "10.000 gal", "$3.579", "$35.79", sentence,
))
history_ok = history and all(value in history.group(0) for value in (
    "10,908 mi", "10.000 gal", "$35.79",
))
print("FILL=" + ("yes" if card_ok and history_ok else "no"))' <<<"$demo_before_def"
  )"
  grep -q '^ROW=yes$' <<<"$break_truth" \
    || fail "fixture 94 missed-fill boundary is not unavailable with its human reason: $break_truth"
  grep -q '^FILL=yes$' <<<"$break_truth" \
    || fail "fixture 94 break hid the fill or its quantity, price, total, odometer, or human reason: $break_truth"
  note "fixture 94 PASS - missed-fill makes only the economy unavailable, names the reason in human text, and preserves the fill facts"
  if [ "${ROVER_FIXTURE_STOP:-}" = 94 ]; then
    exit 0
  fi

  obelisk_mutate rover \
    "UPDATE economy-breaks SET reason = %excluded WHERE reason = %missed-fill" >/dev/null
  excluded_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  grep -q 'data-economy-break="%excluded"' <<<"$excluded_view" \
    || fail "fixture 95 excluded break row is absent from the economy rendering"
  grep -q 'The owner excluded this fill from economy calculations.' <<<"$excluded_view" \
    || fail "fixture 95 excluded break lacks its distinct human reason"
  obelisk_mutate rover \
    "UPDATE economy-breaks SET reason = %owner-marked WHERE reason = %excluded" >/dev/null
  owner_marked_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  grep -q 'data-economy-break="%owner-marked"' <<<"$owner_marked_view" \
    || fail "fixture 95 owner-marked break row is absent from the economy rendering"
  grep -q 'The owner marked this fill as an economy-chain break.' <<<"$owner_marked_view" \
    || fail "fixture 95 owner-marked break lacks its distinct human reason"
  obelisk_mutate rover \
    "UPDATE economy-breaks SET reason = %missed-fill WHERE reason = %owner-marked" >/dev/null
  note "fixture 95 PASS - excluded and owner-marked breaks retain distinct human explanations"

  obelisk_mutate rover \
    "UPDATE odometer-observations SET value-digits = 20000 WHERE value-digits = 10908 AND decimal-places = 0" >/dev/null
  poisoned_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  poisoned_truth="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
hub = document.split("<section id=\"main-hub\"", 1)[1].split("<section id=\"add-fill\"", 1)[0]
pairs = {}
for article in re.findall(r"<article[^>]*>(.*?)</article>", hub, re.S):
    label = re.search(r"<span>(.*?)</span>", article, re.S)
    value = re.search(r"<strong>(.*?)</strong>", article, re.S)
    if label and value:
        clean = lambda text: re.sub(r"<[^>]+>", "", text).strip()
        pairs[clean(label.group(1))] = clean(value.group(1))
expected = {
    "ECONOMY - LAST FILL": "29.000 mpg",
    "ECONOMY - LIFETIME": "29.000 mpg",
    "ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL": "450 mi",
    "BEST ECONOMY": "30.000 mpg",
    "WORST ECONOMY": "28.000 mpg",
}
broken = re.search(r"data-economy=\"Unavailable\" data-economy-break=\"%missed-fill\"", document)
print("AGGREGATES=" + ("yes" if all(pairs.get(key) == value for key, value in expected.items()) else "no"))
print("BROKEN=" + ("yes" if broken and "939.200 mpg" not in document else "no"))' <<<"$poisoned_view"
  )"
  grep -q '^AGGREGATES=yes$' <<<"$poisoned_truth" \
    || fail "fixture 96 impossible broken interval poisoned last, lifetime, tank, best, or worst: $poisoned_truth"
  grep -q '^BROKEN=yes$' <<<"$poisoned_truth" \
    || fail "fixture 96 impossible broken interval rendered as an economy value: $poisoned_truth"
  obelisk_mutate rover \
    "UPDATE odometer-observations SET value-digits = 10908 WHERE value-digits = 20000 AND decimal-places = 0" >/dev/null
  note "fixture 96 PASS - an impossible broken interval is unavailable and excluded from last, lifetime, tank, best, and worst"

  restored_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  grep -q 'data-economy-vehicle="Rover Demo Gasoline" data-economy="30.000 mpg"' <<<"$restored_view" \
    || fail "fixture 97 ordinary unbroken eligible interval no longer renders its economy"
  grep -q '>30.000 mpg</td><td>Eligible full-fill interval.</td>' <<<"$restored_view" \
    || fail "fixture 97 ordinary interval lost its eligible explanation"
  note "fixture 97 PASS - an ordinary unbroken eligible interval remains unchanged"
  if [ "${ROVER_FIXTURE_STOP:-}" = 97 ]; then
    exit 0
  fi

  rolling_hub="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
hub = document.split("<section id=\"main-hub\"", 1)[1].split("<section id=\"add-fill\"", 1)[0]
match = re.search(
    r"<article[^>]*><span>ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL</span>"
    r"<strong>([^<]+)</strong><small>([^<]+)</small></article>",
    hub,
    re.S,
)
print("|".join(part.strip() for part in match.groups()) if match else "")' <<<"$restored_view"
  )"
  [ "$rolling_hub" = '442 mi|Mean of the last 4 eligible intervals, full tank.' ] \
    || fail "fixture 98 hub did not use the rolling eligible mean with honest label/precision: ${rolling_hub:-<missing>}"
  note "fixture 98 PASS - hub uses the newest-first rolling eligible mean, excludes the broken interval, states the four-interval basis, and renders whole miles"
  if [ "${ROVER_FIXTURE_STOP:-}" = 98 ]; then
    exit 0
  fi

  for invalid_reserve in 100 101; do
    reserve_refusal="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
      -H 'content-type: application/json' \
      --data-raw "{\"vehicle\":\"Rover Demo Gasoline\",\"label\":\"Rover Demo Gasoline\",\"tankSize\":\"15.5\",\"tankUnit\":\"gal\",\"refillReserve\":\"$invalid_reserve\",\"defaultSubtype\":\"87\",\"defaultEnergy\":\"Gasoline\",\"energySources\":[\"Gasoline\"],\"drivingModes\":[\"Normal\"],\"defEnabled\":\"no\",\"defTankSize\":\"\",\"defTankUnit\":\"gal\"}" \
      "$URL/apps/rover/edit-vehicle")"
    [ "$reserve_refusal" = $'%out-of-range: vehicle.refill-reserve\n400' ] \
      || fail "fixture 99 reserve $invalid_reserve was not refused by name at entry: $reserve_refusal"
  done
  note "fixture 99 PASS - refill reserves of 100 percent and above are refused by name at entry"
  if [ "${ROVER_FIXTURE_STOP:-}" = 99 ]; then
    exit 0
  fi

  reserve_25="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline","label":"Rover Demo Gasoline","tankSize":"15.5","tankUnit":"gal","refillReserve":"25","defaultSubtype":"87","defaultEnergy":"Gasoline","energySources":["Gasoline"],"drivingModes":["Normal"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    "$URL/apps/rover/edit-vehicle")"
  [ "$reserve_25" = $'Saved vehicle settings\n201' ] \
    || fail "fixture 100 could not save a 25 percent refill reserve: $reserve_25"
  reserve_report="$(
    obelisk_mutate rover \
      "FROM vehicles V JOIN vehicle-refill-reserve R ON V.vehicle-id = R.vehicle-id WHERE V.label = 'Rover Demo Gasoline' SELECT R.reserve-percent;"
  )"
  grep -q '\[%reserve-percent 25717 25\]' <<<"$reserve_report" \
    || fail "fixture 100 did not persist reserve-percent 25 in its child row: $reserve_report"
  reserve_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  reserve_summary="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
hub = document.split("<section id=\"main-hub\"", 1)[1].split("<section id=\"add-fill\"", 1)[0]
readout = re.search(
    r"<span>ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL</span>"
    r"<strong>([^<]+)</strong><small>([^<]+)</small>",
    hub,
    re.S,
)
panel = re.search(
    r"data-vehicle-settings-panel data-vehicle=\"Rover Demo Gasoline\".*?</article>",
    document,
    re.S,
)
control = re.search(
    r"Fill up when tank reaches\s*<input[^>]*name=\"refillReserve\"[^>]*value=\"([^\"]*)\"",
    panel.group(0) if panel else "",
    re.S,
)
parts = list(readout.groups()) if readout else ["", ""]
parts.append(control.group(1) if control else "")
print("|".join(part.strip() for part in parts))' <<<"$reserve_view"
  )"
  [ "$reserve_summary" = '331 mi|Mean of the last 4 eligible intervals, 25% reserve.|25' ] \
    || fail "fixture 100 reserve was not applied or re-rendered honestly: ${reserve_summary:-<missing>}"
  note "fixture 100 PASS - a human 25 percent reserve persists, re-renders, and reduces the rolling estimate from 442 mi to 331 mi"
  if [ "${ROVER_FIXTURE_STOP:-}" = 100 ]; then
    exit 0
  fi

  reserve_0="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline","label":"Rover Demo Gasoline","tankSize":"15.5","tankUnit":"gal","refillReserve":"0","defaultSubtype":"87","defaultEnergy":"Gasoline","energySources":["Gasoline"],"drivingModes":["Normal"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    "$URL/apps/rover/edit-vehicle")"
  [ "$reserve_0" = $'Saved vehicle settings\n201' ] \
    || fail "fixture 101 could not save an explicit zero-percent refill reserve: $reserve_0"
  reserve_zero_report="$(
    obelisk_mutate rover \
      "FROM vehicles V JOIN vehicle-refill-reserve R ON V.vehicle-id = R.vehicle-id WHERE V.label = 'Rover Demo Gasoline' SELECT R.reserve-percent;"
  )"
  grep -q '\[%reserve-percent 25717 0\]' <<<"$reserve_zero_report" \
    || fail "fixture 101 did not persist reserve-percent 0 in its child row: $reserve_zero_report"
  reserve_zero_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  reserve_zero_summary="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
hub = document.split("<section id=\"main-hub\"", 1)[1].split("<section id=\"add-fill\"", 1)[0]
match = re.search(
    r"<span>ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL</span>"
    r"<strong>([^<]+)</strong><small>([^<]+)</small>",
    hub,
    re.S,
)
print("|".join(part.strip() for part in match.groups()) if match else "")' <<<"$reserve_zero_view"
  )"
  [ "$reserve_zero_summary" = '442 mi|Mean of the last 4 eligible intervals, 0% reserve.' ] \
    || fail "fixture 101 explicit zero reserve did not retain full usable capacity: ${reserve_zero_summary:-<missing>}"
  note "fixture 101 PASS - the same data renders 442 mi at zero reserve and 331 mi at 25 percent, with the reserved distance strictly smaller"
  if [ "${ROVER_FIXTURE_STOP:-}" = 101 ]; then
    exit 0
  fi

  reserve_absent="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline","label":"Rover Demo Gasoline","tankSize":"15.5","tankUnit":"gal","refillReserve":"","defaultSubtype":"87","defaultEnergy":"Gasoline","energySources":["Gasoline"],"drivingModes":["Normal"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    "$URL/apps/rover/edit-vehicle")"
  [ "$reserve_absent" = $'Saved vehicle settings\n201' ] \
    || fail "fixture 102 could not clear the refill reserve: $reserve_absent"
  reserve_absent_report="$(
    obelisk_mutate rover \
      "FROM vehicles V JOIN vehicle-refill-reserve R ON V.vehicle-id = R.vehicle-id WHERE V.label = 'Rover Demo Gasoline' SELECT R.reserve-percent;"
  )"
  grep -q '\[%vector-count 0\]' <<<"$reserve_absent_report" \
    || fail "fixture 102 clearing reserve did not remove the optional child row: $reserve_absent_report"
  reserve_absent_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  reserve_absent_summary="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
hub = document.split("<section id=\"main-hub\"", 1)[1].split("<section id=\"add-fill\"", 1)[0]
match = re.search(
    r"<span>ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL</span>"
    r"<strong>([^<]+)</strong><small>([^<]+)</small>",
    hub,
    re.S,
)
print("|".join(part.strip() for part in match.groups()) if match else "")' <<<"$reserve_absent_view"
  )"
  [ "$reserve_absent_summary" = '442 mi|Mean of the last 4 eligible intervals, full tank.' ] \
    || fail "fixture 102 absent reserve did not behave as a fully usable tank: ${reserve_absent_summary:-<missing>}"
  note "fixture 102 PASS - clearing the optional child row restores the exact full-tank result and caption"
  if [ "${ROVER_FIXTURE_STOP:-}" = 102 ]; then
    exit 0
  fi

  diesel_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Diesel"}' \
    "$URL/apps/rover/set-default-vehicle")"
  [ "$diesel_default" = $'Saved default vehicle\n201' ] \
    || fail "fixture 104 could not scope the five-interval estimate to the diesel vehicle: $diesel_default"
  diesel_rolling_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  diesel_rolling_summary="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
hub = document.split("<section id=\"main-hub\"", 1)[1].split("<section id=\"add-fill\"", 1)[0]
match = re.search(
    r"<span>ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL</span>"
    r"<strong>([^<]+)</strong><small>([^<]+)</small>",
    hub,
    re.S,
)
print("|".join(part.strip() for part in match.groups()) if match else "")' <<<"$diesel_rolling_view"
  )"
  [ "$diesel_rolling_summary" = '828 mi|Mean of the last 5 eligible intervals, full tank.' ] \
    || fail "fixture 104 did not use all five eligible diesel intervals: ${diesel_rolling_summary:-<missing>}"
  gasoline_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline"}' \
    "$URL/apps/rover/set-default-vehicle")"
  [ "$gasoline_default" = $'Saved default vehicle\n201' ] \
    || fail "fixture 104 could not restore the gasoline demo default: $gasoline_default"
  note "fixture 104 PASS - a five-interval vehicle renders the exact rolling-five mean rather than its latest interval"
  if [ "${ROVER_FIXTURE_STOP:-}" = 104 ]; then
    exit 0
  fi

  diesel_before_def="${demo_parts[1]}"
  seed_demo_def_via_eyre
  demo_after_def="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  demo_diesel_after_def="$(scoped_view_html "$(scoped_view 0 'Rover Demo Diesel')")"
  demo_sources_after="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
labels = re.findall(r"<option[^>]+data-starter-source[^>]*>([^<]+)</option>", document)
print("|".join(sorted(set(label.strip() for label in labels))))' <<<"$demo_after_def"
  )"
  [ "$demo_sources_after" = "$expected_sources" ] \
    || fail "fixture 68 demo seed changed the served starter source set; actual labels: ${demo_sources_after:-<none>}"
  if grep -Eq '<option[^>]+data-starter-source[^>]*>Demo ' <<<"$demo_after_def"; then
    fail "fixture 68 demo seed exposed a Demo energy definition"
  fi
  note "fixture 68 PASS - post-seed Energy Source set remains exactly the eight starters with zero Demo definitions"
  statistics_html="$(
    html_slice 'id="statistics-screen"' 'id="settings-screen"' <<<"$demo_after_def"
  )"
  grep -q 'data-statistics-vehicle=' <<<"$statistics_html" \
    || fail "fixture 63 statistics screen lacks an explicit vehicle scope"
  grep -q 'id="statistics-vehicle-select"' <<<"$statistics_html" \
    || fail "fixture 63 statistics screen lacks the History-pattern vehicle selector"
  if grep -q '<th>Vehicle</th>' <<<"$statistics_html"; then
    fail "fixture 63 a statistics table still contains a Vehicle column"
  fi
  note "fixture 63 PASS - statistics exposes the app-default scope and selector with zero Vehicle table columns"
  grep -q 'data-statistics-scope-heading' <<<"$statistics_html" \
    || fail "fixture 64 statistics header lacks the single scope-name marker"
  statistics_scope_name="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
match = re.search(
    r"<header class=\"view-header\">.*?<p id=\"statistics-vehicle-name\"[^>]*>([^<]+)</p>.*?</header>",
    document,
    re.S,
)
print(match.group(1).strip() if match else "")' <<<"$statistics_html"
  )"
  [ "$statistics_scope_name" = 'Rover Demo Gasoline' ] \
    || fail "fixture 64 statistics header scope is not the app default: ${statistics_scope_name:-<none>}"
  [ "$(grep -o 'data-statistics-scope-heading' <<<"$statistics_html" | wc -l)" -eq 1 ] \
    || fail "fixture 64 statistics scope marker is not unique"
  note "fixture 64 PASS - the header names Rover Demo Gasoline exactly once as the statistics subject"

  PLAYWRIGHT_ROOT="${PLAYWRIGHT_ROOT:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules}"
  CHROMIUM_BIN="${CHROMIUM_BIN:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
  fill_context="$(
    URL="$URL" JAR="$JAR" EMPTY_VEHICLE="$settings_label_second" CHROMIUM_BIN="$CHROMIUM_BIN" NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_BIN
  });
  const page = await browser.newPage({viewport: {width: 390, height: 844}});
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/\s(urbauth-[^\s]+)\s+([^\s]+)/);
  await page.context().addCookies([{
    name: cookie[1], value: cookie[2], domain: 'localhost', path: '/'
  }]);
  await page.goto(`${process.env.URL}/apps/rover`);
  const form = page.locator('#fill-form');
  await form.waitFor({state: 'attached'});
  await page.locator('[data-open-screen="add-fill"]').click();
  await form.locator('[name="vehicle"]').selectOption({label: 'Rover Demo Gasoline'});
  await form.locator('[name="observed"]').evaluate((input) => {
    input.value = '2026-07-07T12:00';
    input.dispatchEvent(new Event('change', {bubbles: true}));
  });
  const prior = await page.locator('#fill-previous-odometer').evaluate((output) => output.value);
  await form.locator('[name="vehicle"]').selectOption({label: process.env.EMPTY_VEHICLE || 'Fixture 70 Settings'});
  const unavailable = await page.locator('#fill-previous-odometer').evaluate((output) => output.value);
  await page.locator('#add-fill .back-control').click();
  await page.locator('[data-open-screen="vehicles-screen"]').first().click();
  await page.locator('[data-open-vehicle-settings][data-vehicle="Rover Demo Gasoline"]').click();
  const panel = page.locator('[data-vehicle-settings-panel][data-vehicle="Rover Demo Gasoline"]');
  if (process.env.ROVER_SETTINGS_ARTIFACT) {
    const fragment = await panel.evaluate((article) =>
      `<!-- Authenticated Eyre DOM for Rover Demo Gasoline settings. -->\n${article.outerHTML}\n`
    );
    fs.writeFileSync(process.env.ROVER_SETTINGS_ARTIFACT, fragment);
  }
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > innerWidth);
  const targets = await panel.locator(
    '.membership-checks .check-option, [data-add-energy-source], [data-add-driving-mode]'
  ).evaluateAll((items) => items.map((item) => item.getBoundingClientRect().height));
  console.log(JSON.stringify({prior, unavailable, overflow, minTarget: Math.min(...targets)}));
  await browser.close();
})().catch((error) => {
  console.error(error.stack || error);
  process.exit(1);
});
NODE
  )" || fail "fixtures 79/81 Chromium check failed"
  fill_context_summary="$(
    python3 -c 'import json, sys
d=json.loads(sys.stdin.read())
print("|".join([d["prior"], d["unavailable"], str(d["overflow"]).lower(), str(d["minTarget"] >= 44)]))' \
      <<<"$fill_context"
  )"
  case "$fill_context_summary" in
    '11,522 mi|Unavailable - this vehicle has no earlier odometer observation|false|True') ;;
    *) fail "fixtures 79/81 previous odometer or mobile controls mismatch: $fill_context_summary" ;;
  esac
  note "fixture 79 PASS - Add Fill derives 11,522 mi from the preceding gasoline observation and gives the factual no-earlier-observation refusal"
  note "fixture 81 PASS - at 390px checkbox/add controls have no horizontal overflow and every target is at least 44px"

  invalid_default_energy="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline","label":"Rover Demo Gasoline","tankSize":"15","tankUnit":"gal","defaultSubtype":"87","defaultEnergy":"Diesel","energySources":["Gasoline"],"drivingModes":["Normal"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    "$URL/apps/rover/edit-vehicle")"
  [ "$invalid_default_energy" = $'%not-allowed: vehicle.default-energy-source\n422' ] \
    || fail "fixture 82 accepted a default energy source outside the allowed set: $invalid_default_energy"
  valid_default_energy="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline","label":"Rover Demo Gasoline","tankSize":"15","tankUnit":"gal","defaultSubtype":"87","defaultEnergy":"Gasoline","energySources":["Gasoline"],"drivingModes":["Normal"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' \
    "$URL/apps/rover/edit-vehicle")"
  [ "$valid_default_energy" = $'Saved vehicle settings\n201' ] \
    || fail "fixture 82 could not persist the allowed default energy source: $valid_default_energy"
  default_energy_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  grep -q '<select name="defaultEnergy"><option value="">Not set</option><option value="Gasoline" selected>' \
    <<<"$default_energy_view" \
    || fail "fixture 82 saved default energy is not selected in vehicle settings"
  note "fixture 82 PASS - settings persists Gasoline as the default and rejects/offers no disallowed Diesel default"
  statistics_switch="$(
    URL="$URL" JAR="$JAR" CHROMIUM_BIN="$CHROMIUM_BIN" NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_BIN
  });
  const page = await browser.newPage();
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/\s(urbauth-[^\s]+)\s+([^\s]+)/);
  await page.context().addCookies([{
    name: cookie[1], value: cookie[2], domain: 'localhost', path: '/'
  }]);
  await page.goto(`${process.env.URL}/apps/rover`);
  const selector = page.locator('#statistics-vehicle-select');
  await selector.waitFor({state: 'attached'});
  const snapshot = async () => page.locator('#statistics-screen').evaluate((screen) => {
    const selected = screen.querySelector('#statistics-vehicle-select').value;
    const tables = [...screen.querySelectorAll('[data-statistic]')].map((table) => {
      const rows = [...table.querySelectorAll('tbody tr')].filter((row) => !row.hidden);
      if (rows.some((row) => (row.dataset.statisticsVehicle || table.dataset.statisticsVehicle) !== selected)) {
        throw new Error(`${table.dataset.statistic} leaks a row outside ${selected}`);
      }
      return [table.dataset.statistic, rows.map((row) => row.textContent.trim()).join('|')];
    });
    return {
      selected,
      header: screen.querySelector('#statistics-vehicle-name').textContent.trim(),
      tables: Object.fromEntries(tables),
    };
  });
  const before = await snapshot();
  if (process.env.ROVER_STATISTICS_ARTIFACT) {
    const fragment = await page.locator('#statistics-screen').evaluate((screen) => {
      const copy = screen.cloneNode(true);
      copy.hidden = false;
      copy.querySelectorAll('tbody tr[hidden]').forEach((row) => row.remove());
      return `<!-- Authenticated Eyre DOM after default-vehicle filtering. -->\n${copy.outerHTML}\n`;
    });
    fs.writeFileSync(process.env.ROVER_STATISTICS_ARTIFACT, fragment);
  }
  await Promise.all([
    page.waitForResponse((response) =>
      response.url().endsWith('/apps/rover/view') &&
      response.request().method() === 'POST'
    ),
    selector.evaluate((select) => {
      const option = [...select.options].find(
        (candidate) => candidate.textContent === 'Rover Demo Diesel'
      );
      if (!option) throw new Error('Rover Demo Diesel selector option is missing');
      select.value = option.value;
      select.dispatchEvent(new Event('change', {bubbles: true}));
    })
  ]);
  const after = await snapshot();
  const names = Object.keys(before.tables);
  const changed = names.filter((name) => before.tables[name] !== after.tables[name]);
  console.log(JSON.stringify({before, after, changed}));
  await browser.close();
})().catch((error) => {
  console.error(error.stack || error);
  process.exit(1);
});
NODE
  )" || fail "fixture 65 Chromium statistics selector check failed"
  statistics_switch_summary="$(
    python3 -c 'import json, sys
data = json.loads(sys.stdin.read())
print("|".join([
    data["before"]["selected"],
    data["before"]["header"],
    data["after"]["selected"],
    data["after"]["header"],
    ",".join(data["changed"]),
]))' <<<"$statistics_switch"
  )"
  expected_statistics_switch='Rover Demo Gasoline|Rover Demo Gasoline|Rover Demo Diesel|Rover Demo Diesel|total-cost-of-ownership,cost-per-distance,spend-by-family,economy-by-subtype,fuel-costs,distance-between-fills,time-between-fills,average-price-per-unit,distance-per-tank,def-economy'
  [ "$statistics_switch_summary" = "$expected_statistics_switch" ] \
    || fail "fixture 65 switching scope did not change every table and header: $statistics_switch_summary"
  note "fixture 65 PASS - selector changed the header and all seven statistics tables from gasoline to diesel"

  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "DELETE FROM app-default-vehicle WHERE scope = %app;"]))
;<  ~  bind:m  (sleep ~s2)
(pure:m !>(~))' >/dev/null
  no_default_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  no_default_statistics="$(
    html_slice 'id="statistics-screen"' 'id="settings-screen"' <<<"$no_default_view"
  )"
  no_default_browser="$(
    URL="$URL" JAR="$JAR" CHROMIUM_BIN="$CHROMIUM_BIN" NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_BIN
  });
  const page = await browser.newPage();
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/\s(urbauth-[^\s]+)\s+([^\s]+)/);
  await page.context().addCookies([{
    name: cookie[1], value: cookie[2], domain: 'localhost', path: '/'
  }]);
  await page.goto(`${process.env.URL}/apps/rover`);
  const result = await page.locator('#statistics-screen').evaluate((screen) => ({
    selected: screen.querySelector('#statistics-vehicle-select').value,
    header: screen.querySelector('#statistics-vehicle-name').textContent.trim(),
    visible: [...screen.querySelectorAll('tbody tr')].filter((row) => !row.hidden).length,
  }));
  console.log(JSON.stringify(result));
  await browser.close();
})().catch((error) => {
  console.error(error.stack || error);
  process.exit(1);
});
NODE
  )"
  no_default_browser_status=$?
  restored_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline"}' \
    "$URL/apps/rover/set-default-vehicle")"
  [ "$restored_default" = $'Saved default vehicle\n201' ] \
    || fail "fixture 66 could not restore the demo app-default-vehicle: $restored_default"
  [ "$no_default_browser_status" -eq 0 ] \
    || fail "fixture 66 Chromium no-default check failed"
  grep -q 'data-statistics-no-default' <<<"$no_default_statistics" \
    || fail "fixture 66 statistics screen does not mark the absent default"
  grep -q 'No default vehicle set.' <<<"$no_default_statistics" \
    || fail "fixture 66 statistics screen does not plainly state that no default is set"
  grep -q 'id="statistics-vehicle-select"' <<<"$no_default_statistics" \
    || fail "fixture 66 no-default state does not offer the vehicle selector"
  no_default_summary="$(
    python3 -c 'import json, sys
data = json.loads(sys.stdin.read())
print("|".join([data["selected"], data["header"], str(data["visible"])]))' \
      <<<"$no_default_browser"
  )"
  [ "$no_default_summary" = '|No default vehicle set.|0' ] \
    || fail "fixture 66 no-default state selected or pooled vehicle rows: $no_default_summary"
  note "fixture 66 PASS - absent app default is stated plainly; selector remains; zero vehicle rows are pooled"

  scoped_hub_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
  scoped_hub="$(
    html_slice 'id="main-hub"' 'id="add-fill"' <<<"$scoped_hub_view"
  )"
  [ "$(grep -Fo 'data-hub-statistics-vehicle="Rover Demo Gasoline"' <<<"$scoped_hub" | wc -l)" -eq 5 ] \
    || fail "fixture 67 five fuel-statistics hub readouts are not explicitly scoped to the default vehicle"
  if grep -Fq 'data-hub-statistics-vehicle="Rover Demo Diesel"' <<<"$scoped_hub"; then
    fail "fixture 67 second-vehicle fills moved a default-vehicle hub readout"
  fi
  note "fixture 67 PASS - all five fuel-statistics hub readouts remain scoped to Rover Demo Gasoline despite diesel fills"
  demo_starter_report="$(read_demo_starter_report)"
  demo_starter_check="$(
    python3 -c 'import re, sys
report = sys.stdin.read()
vectors = re.findall(r"\[%vector (.*?) 0\]", report)
def field(vector, name):
    match = re.search(rf"\[%{re.escape(name)} [^ ]+ (\x27[^\x27]*\x27|[^ \]]+)\]", vector)
    return match.group(1).strip(chr(39)) if match else None
definition_rows = [
    (field(v, "vehicle"), field(v, "demo-energy-definition-id"),
     field(v, "starter-energy-definition-id"), field(v, "starter-energy"))
    for v in vectors if field(v, "starter-energy") is not None
]
subtype_rows = [
    (field(v, "vehicle"), field(v, "demo-energy-definition-id"),
     field(v, "subtype-parent-definition-id"), field(v, "demo-subtype-id"),
     field(v, "starter-subtype-id"), field(v, "starter-subtype"))
    for v in vectors if field(v, "starter-subtype") is not None
]
definitions = {(vehicle, energy, demo == starter)
               for vehicle, demo, starter, energy in definition_rows}
cords = {"14136": "87", "13113": "93", "12835": "#2"}
subtypes = {
    (vehicle, cords.get(subtype, subtype.strip(chr(39))),
     definition == parent, demo == starter)
    for vehicle, definition, parent, demo, starter, subtype in subtype_rows
}
expected_definitions = {
    ("Rover Demo Gasoline", "Gasoline", True),
    ("Rover Demo Diesel", "Diesel", True),
}
expected_subtypes = {
    ("Rover Demo Gasoline", "87", True, True),
    ("Rover Demo Gasoline", "93", True, True),
    ("Rover Demo Diesel", "#2", True, True),
    ("Rover Demo Diesel", "B20", True, True),
}
print("yes" if definitions == expected_definitions else repr(sorted(definitions)))
print("yes" if subtypes == expected_subtypes else repr(sorted(subtypes)))' \
      <<<"$demo_starter_report"
  )"
  mapfile -t demo_starter_parts <<<"$demo_starter_check"
  [ "${demo_starter_parts[0]:-}" = yes ] \
    || fail "fixture 69 demo fill energy-definition IDs do not match starter rows: ${demo_starter_parts[0]:-<none>}"
  [ "${demo_starter_parts[1]:-}" = yes ] \
    || fail "fixture 69 demo fill subtype IDs do not match starter rows: ${demo_starter_parts[1]:-<none>}"
  note "fixture 69 PASS - demo fills use starter Gasoline/Diesel IDs and starter 87/93/#2/B20 subtype IDs"
  after_summary="$(
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
diesel = sorted(v for v in re.findall(
    r"data-economy-vehicle=\"Rover Demo Diesel\" data-economy=\"([^\"]+)\"",
    document,
) if v != "Unavailable")
def_values = re.findall(
    r"data-def-economy-vehicle=\"Rover Demo Diesel\" data-def-economy=\"([^\"]+)\"",
    document,
)
required = (
    "data-economy=",
    "data-fuel-cost=",
    "data-distance-between-fills=",
    "data-time-between-fills=",
    "data-average-price=",
    "data-distance-per-tank=",
    "data-def-economy=",
)
print("|".join(diesel))
print("|".join(def_values))
print("yes" if all(item in document for item in required) else "no")' <<<"$demo_diesel_after_def"
  )"
  mapfile -t after_parts <<<"$after_summary"
  [ "${after_parts[0]:-}" = "$diesel_before_def" ] ||
    fail "fixture 61 diesel fuel economy changed after DEF purchases: before=$diesel_before_def after=${after_parts[0]:-<none>}"
  [ "${after_parts[1]:-}" = '500.000 mi/gal DEF' ] ||
    fail "fixture 61 DEF economy mismatch: ${after_parts[1]:-<none>}"
  [ "${after_parts[2]:-}" = yes ] ||
    fail "fixture 59 at least one statistics table lacks a computed row"
  note "fixture 59 PASS - every statistics table renders a computed demo row"
  note "fixture 61 PASS - DEF economy is 500.000 mi/gal DEF and diesel fuel economy is byte-identical before and after DEF purchases"
  if [ "${ROVER_PRINT_STATISTICS:-}" = 1 ]; then
    python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
for table in re.findall(
    r"<section class=\"stat-table\" data-statistic=\"[^\"]+\">.*?</section>",
    document,
    re.S,
):
    print(table)' <<<"$demo_after_def"
  fi
fi

gas_vehicle="Starter Gasoline $(date +%s%N)"
diesel_vehicle="Starter Diesel $(date +%s%N)"
for vehicle_source in "$gas_vehicle:Gasoline" "$diesel_vehicle:Diesel"; do
  vehicle="${vehicle_source%:*}"
  source="${vehicle_source##*:}"
  created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"label":"%s","energy":"%s"}' "$vehicle" "$source")" \
    "$URL/apps/rover/add-vehicle")"
  [ "$created" = "Added vehicle - $vehicle"$'\n201' ] \
    || fail "fixture 33 could not create $source vehicle: $created"
done

PLAYWRIGHT_ROOT="${PLAYWRIGHT_ROOT:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules}"
CHROMIUM_BIN="${CHROMIUM_BIN:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
cascade="$(
  URL="$URL" JAR="$JAR" GAS_VEHICLE="$gas_vehicle" DIESEL_VEHICLE="$diesel_vehicle" \
    CHROMIUM_BIN="$CHROMIUM_BIN" NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_BIN
  });
  const page = await browser.newPage({viewport: {width: 390, height: 844}});
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/\s(urbauth-[^\s]+)\s+([^\s]+)/);
  await page.context().addCookies([{
    name: cookie[1], value: cookie[2], domain: 'localhost', path: '/'
  }]);
  await page.goto(`${process.env.URL}/apps/rover`);
  await page.locator('#fill-form').waitFor({state: 'attached'});
  const read = async vehicle => {
    await page.locator('#fill-form [name="vehicle"]').evaluate((select, label) => {
      const option = [...select.options].find(candidate => candidate.textContent === label);
      if (!option) throw new Error(`vehicle option missing: ${label}`);
      select.value = option.value;
      select.dispatchEvent(new Event('change', {bubbles: true}));
    }, vehicle);
    return page.locator('#fill-form [name="subtype"]').evaluate(select =>
      [...select.options]
        .filter(option => option.dataset.definition && !option.hidden)
        .map(option => option.value)
        .sort()
        .join('|')
    );
  };
  const gasoline = await read(process.env.GAS_VEHICLE);
  const diesel = await read(process.env.DIESEL_VEHICLE);
  console.log(`gasoline=${gasoline} diesel=${diesel}`);
  await browser.close();
})().catch(error => {
  console.error(error);
  process.exit(1);
});
NODE
)"
[ "$cascade" = 'gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter' ] \
  || fail "fixture 33 cascading subtype mismatch; actual Chromium measurement: $cascade"
note "fixture 33 PASS - Chromium selection exposes only source-owned subtypes: $cascade"

starter_report="$(read_starter_report)"
grep -q '\[%rating 25717 87\] \[%method %tas %aki\]' <<<"$starter_report" \
  || fail "fixture 34 cannot read 87 AKI metadata from energy-subtype-octane; actual: $starter_report"
grep -q '\[%rating 25717 95\] \[%method %tas %ron\]' <<<"$starter_report" \
  || fail "fixture 34 cannot read 95 RON metadata from energy-subtype-octane; actual: $starter_report"
starter_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q '>87</option>' <<<"$starter_view" \
  || fail "fixture 34 human subtype label 87 is absent from live HTML"
grep -q '>95</option>' <<<"$starter_view" \
  || fail "fixture 34 human subtype label 95 is absent from live HTML"
if grep -Eq '<option[^>]*>[^<]*(AKI|RON)[^<]*</option>' <<<"$starter_view"; then
  fail "fixture 34 leaked AKI/RON into a subtype label"
fi
note "fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata"

for vehicle in "$gas_vehicle" "$diesel_vehicle"; do
  removed="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s"}' "$vehicle")" \
    "$URL/apps/rover/remove-vehicle")"
  [ "$removed" = $'Archived vehicle\n201' ] \
    || fail "fixture 33 cleanup failed for $vehicle: $removed"
done
if [ "${ROVER_FIXTURE_STOP:-}" = 34 ]; then
  exit 0
fi

edit_vehicle="Edit Vehicle $(date +%s%N)"
edited_vehicle="$edit_vehicle Renamed"
created_edit_vehicle="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Gasoline"}' "$edit_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$created_edit_vehicle" = "Added vehicle - $edit_vehicle"$'\n201' ] \
  || fail "fixture 36 setup vehicle failed: $created_edit_vehicle"
vehicle_screen_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
vehicles_screen="$(html_slice 'id="vehicles-screen"' '</section>' <<<"$vehicle_screen_view")"
grep -q 'class="vehicle-list"' <<<"$vehicles_screen" \
  || fail "fixture 36 Vehicles screen is not a plain vehicle list; actual HTML: $vehicles_screen"
grep -q 'data-open-screen="vehicle-create-screen"' <<<"$vehicles_screen" \
  || fail "fixture 36 Vehicles screen Add Vehicle does not open a creation screen; actual HTML: $vehicles_screen"
if grep -q 'id="vehicle-add-form"' <<<"$vehicles_screen"; then
  fail "fixture 36 Vehicles screen still embeds the creation form"
fi
grep -q '<section id="vehicle-create-screen"' <<<"$vehicle_screen_view" \
  || fail "fixture 36 dedicated vehicle creation screen is absent"
grep -q '<section id="vehicle-settings-screen"' <<<"$vehicle_screen_view" \
  || fail "fixture 36 dedicated vehicle settings screen is absent"
grep -q 'data-open-vehicle-settings' <<<"$vehicles_screen" \
  || fail "fixture 36 vehicle list entries do not open settings"
note "fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens"
if [ "${ROVER_FIXTURE_STOP:-}" = 36 ]; then
  exit 0
fi

edited_vehicle_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"18.5","tankUnit":"gal","defaultSubtype":"95"}' "$edit_vehicle" "$edited_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$edited_vehicle_result" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 37 vehicle edit failed: $edited_vehicle_result"
vehicle_settings_report="$(rover_report "$(urql_vehicle_settings "$edited_vehicle")")"
grep -q "\\[%vehicle 116 '$edited_vehicle'\\]" <<<"$vehicle_settings_report" \
  || fail "fixture 37 edited label did not persist in Obelisk; actual: $vehicle_settings_report"
grep -q '\[%digits 25717 185\] \[%decimals 25717 1\] \[%size-unit %tas %gal\]' <<<"$vehicle_settings_report" \
  || fail "fixture 37 tank size did not persist exactly; actual: $vehicle_settings_report"
grep -q '\[%default-subtype 116 13625\]' <<<"$vehicle_settings_report" \
  || fail "fixture 37 default subtype 95 did not persist; actual: $vehicle_settings_report"
edited_vehicle_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q "value=\"$edited_vehicle\"" <<<"$edited_vehicle_view" \
  || fail "fixture 37 edited label did not re-render"
grep -q 'value="18.5"' <<<"$edited_vehicle_view" \
  || fail "fixture 37 edited tank size did not re-render"
grep -q 'value="95" selected' <<<"$edited_vehicle_view" \
  || fail "fixture 37 edited default subtype did not re-render"
note "fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render"
removed_edit_vehicle="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s"}' "$edited_vehicle")" \
  "$URL/apps/rover/remove-vehicle")"
[ "$removed_edit_vehicle" = $'Archived vehicle\n201' ] \
  || fail "fixture 37 cleanup failed: $removed_edit_vehicle"
if [ "${ROVER_FIXTURE_STOP:-}" = 37 ]; then
  exit 0
fi

fill_edit_vehicle="Fill Edit Vehicle $(date +%s%N)"
fill_edit_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Gasoline"}' "$fill_edit_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$fill_edit_created" = "Added vehicle - $fill_edit_vehicle"$'\n201' ] \
  || fail "fixture 38 setup vehicle failed: $fill_edit_created"
fill_edit_baseline_observed='2026-07-26T11:45'
fill_edit_baseline="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"8.000","price":"$3.39","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"19900.0","mileageUnit":"mi","station":"new","newStationLabel":"Edit Station","newPlaceLabel":"Edit Station Place","newStationKind":"fuel","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":""}' "$fill_edit_vehicle" "$fill_edit_baseline_observed")" \
  "$URL/apps/rover/add-fill")"
[ "$fill_edit_baseline" = $'Saved fill - $3.399 - derived $27.19\n201' ] \
  || fail "fixture 39 baseline fill failed: $fill_edit_baseline"
fill_edit_observed='2026-07-27T10:15'
fill_edit_setup="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"10.000","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":""}' "$fill_edit_vehicle" "$fill_edit_observed")" \
  "$URL/apps/rover/add-fill")"
[ "$fill_edit_setup" = $'Saved fill - $3.499 - derived $34.99\n201' ] \
  || fail "fixture 38 setup fill failed: $fill_edit_setup"
fill_edit_view="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")")"
fill_edit_html="$(html_slice 'class="history-edit-form"' '</form>' <<<"$fill_edit_view")"
for field in quantity price observed partialFill subtype station drivingMode averageSpeed \
  driveBalance notes paymentMethod mileage; do
  grep -Eq "name=\"$field\"" <<<"$fill_edit_html" \
    || fail "fixture 38 fill-edit screen lacks editable $field; actual form HTML: $fill_edit_html"
  if grep -Eq "type=\"hidden\"[^>]*name=\"$field\"" <<<"$fill_edit_html"; then
    fail "fixture 38 fill-edit screen hides $field instead of exposing an owner control; actual form HTML: $fill_edit_html"
  fi
done
note "fixture 38 field gate PASS - fill-edit screen exposes owner controls, including Partial fill, for every editable field"
seed_fill_edit_support_via_eyre "$fill_edit_vehicle"
fill_edit_new_observed='2026-07-27T11:45'
fill_edit_payload="$(
  printf '{"vehicle":"%s","definition":"Gasoline","originalObserved":"%s","quantity":"11.111","price":"$3.59","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"Edit Station","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":["Octane Booster"],"subtype":"95","missedFill":"no","drivingMode":"Mixed Driving","averageSpeed":"55.5","speedUnit":"mph","driveBalance":"64","tags":["Road Trip"],"newTag":"","notes":"Owner corrected every field","paymentMethod":"Personal Visa"}' \
    "$fill_edit_vehicle" "$fill_edit_observed" "$fill_edit_new_observed"
)"
fill_edit_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-raw "$fill_edit_payload" \
  "$URL/apps/rover/edit-fill")"
[ "$fill_edit_result" = $'Saved fill changes - $39.99\n201' ] \
  || fail "fixture 38 full fill edit failed: $fill_edit_result"
fill_edit_report="$(rover_report "$(urql_fill_edit "$fill_edit_vehicle" '~2026.07.27..11.45.00')")"
grep -q '\[%quantity-milli 25717 11111\].*\[%tank-state %tas %partial\].*\[%unit-price-mills 25717 3599\]' <<<"$fill_edit_report" \
  || fail "fixture 38 main fill fields did not round-trip; actual: $fill_edit_report"
grep -q '\[%minor-unit-decimals 25717 2\] \[%cash-increment-mills 25717 50\]' <<<"$fill_edit_report" \
  || fail "fixture 38 untouched rounding integers changed; actual: $fill_edit_report"
for expected in \
  "\\[%subtype 116 13625\\]" \
  "\\[%station 116 'Edit Station'\\]" \
  "\\[%driving-mode 116 'Mixed Driving'\\]" \
  "\\[%digits 25717 555\\] \\[%decimals 25717 1\\]" \
  "\\[%highway-percent 25717 64\\]" \
  "\\[%note 116 'Owner corrected every field'\\]" \
  "\\[%payment-method 116 'Personal Visa'\\]" \
  "\\[%additive 116 'Octane Booster'\\]" \
  "\\[%tag 116 'Road Trip'\\]"; do
  grep -q "$expected" <<<"$fill_edit_report" \
    || fail "fixture 38 child field missing ($expected); actual: $fill_edit_report"
done
fill_edit_rerender="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")")"
grep -q 'value="11.111"' <<<"$fill_edit_rerender" \
  || fail "fixture 38 edited quantity did not re-render"
grep -q '\$39\.99' <<<"$fill_edit_rerender" \
  || fail "fixture 38 edited derived total did not re-render"
grep -Eq 'name="additives" value="Octane Booster" checked' <<<"$fill_edit_rerender" \
  || fail "fixture 38 edited additive did not re-render as an editable selected control"
grep -Eq 'name="tags" value="Road Trip" checked' <<<"$fill_edit_rerender" \
  || fail "fixture 38 edited tag did not re-render as an editable selected control"
note "fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact"
if [ "${ROVER_FIXTURE_STOP:-}" = 38 ]; then
  exit 0
fi

fill_edit_pre_odometer="$(rover_report "$(urql_fill_edit "$fill_edit_vehicle" '~2026.07.27..11.45.00')")"
[ "$(grep -oF '[%vector-count 0]' <<<"$fill_edit_pre_odometer" | wc -l)" -eq 1 ] \
  || fail "fixture 39 target fill unexpectedly had an odometer link before edit: $fill_edit_pre_odometer"
fill_edit_odometer_payload="$(
  printf '{"vehicle":"%s","definition":"Gasoline","originalObserved":"%s","quantity":"11.111","price":"$3.59","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"20000.0","mileageUnit":"mi","station":"Edit Station","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":["Octane Booster"],"subtype":"95","missedFill":"no","drivingMode":"Mixed Driving","averageSpeed":"55.5","speedUnit":"mph","driveBalance":"64","tags":["Road Trip"],"newTag":"","notes":"Owner corrected every field","paymentMethod":"Personal Visa"}' \
    "$fill_edit_vehicle" "$fill_edit_new_observed" "$fill_edit_new_observed"
)"
fill_edit_odometer_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-raw "$fill_edit_odometer_payload" \
  "$URL/apps/rover/edit-fill")"
[ "$fill_edit_odometer_result" = $'Saved fill changes - $39.99\n201' ] \
  || fail "fixture 39 historical odometer edit failed: $fill_edit_odometer_result"
fill_edit_post_odometer="$(rover_report "$(urql_fill_edit "$fill_edit_vehicle" '~2026.07.27..11.45.00')")"
grep -Fq '[%value-digits 25717 0x30d40] [%decimal-places 25717 1] [%unit %tas 26989]' <<<"$fill_edit_post_odometer" \
  || fail "fixture 39 did not create and link the exact historical odometer observation: $fill_edit_post_odometer"
fill_edit_economy_view="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")")"
grep -Fq "data-economy-vehicle=\"$fill_edit_vehicle\" data-economy=\"9.000 mpg\"" <<<"$fill_edit_economy_view" \
  || fail "fixture 39 economy interval did not update to exact 9.000 mpg; actual statistics HTML: ${fill_edit_economy_view#*data-statistic=\"economy-by-subtype\"}"
note "fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg"
if [ "${ROVER_FIXTURE_STOP:-}" = 39 ]; then
  exit 0
fi

station_form_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
station_form="$(html_slice 'id="fill-new-station"' '</div>' <<<"$station_form_view")"
for field in newAddressFormatted newAddressLine1 newAddressLine2 newLocality \
  newRegion newPostalCode newCountry newLatitude newLongitude; do
  grep -q "name=\"$field\"" <<<"$station_form" \
    || fail "fixture 40 manual-station form lacks $field; actual HTML: $station_form"
done
address_station="Address Station $(date +%s%N)"
address_place="Address Place $(date +%s%N)"
address_station_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"5.000","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-28T12:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"%s","newPlaceLabel":"%s","newStationKind":"fuel","newAddressFormatted":"123 Market St, Chicago, IL 60601, US","newAddressLine1":"123 Market St","newAddressLine2":"","newLocality":"Chicago","newRegion":"IL","newPostalCode":"60601","newCountry":"US","newLatitude":"41.8781136","newLongitude":"-87.6297982","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' "$fill_edit_vehicle" "$address_station" "$address_place")" \
  "$URL/apps/rover/add-fill")"
[ "$address_station_result" = $'Saved fill - $3.499 - derived $17.50\n201' ] \
  || fail "fixture 40 manual station create failed: $address_station_result"
address_station_report="$(rover_report "$(urql_station "$address_station")")"
for expected in \
  "$address_station" \
  '123 Market St, Chicago, IL 60601, US' \
  '123 Market St' \
  'Chicago' \
  '60601'; do
  grep -Fq "$expected" <<<"$address_station_report" \
    || fail "fixture 40 address evidence missing ($expected); actual: $address_station_report"
done
grep -Fq '[%latitude-scaled 25715 0x31ec2fa0] [%longitude-scaled 25715 0x68767dfb] [%coord-scale 25717 7]' <<<"$address_station_report" \
  || fail "fixture 40 coordinates did not retain exact signed scale-7 values: $address_station_report"
if grep -Fq "[%part %tas %line2]" <<<"$address_station_report"; then
  fail "fixture 40 omitted address line2 wrote a child row: $address_station_report"
fi
parts_only_station="Parts Address Station $(date +%s%N)"
parts_only_place="Parts Address Place $(date +%s%N)"
parts_only_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"4.000","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-28T13:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"%s","newPlaceLabel":"%s","newStationKind":"fuel","newAddressLine1":"20 Example Road","newLocality":"Sampletown","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' "$fill_edit_vehicle" "$parts_only_station" "$parts_only_place")" \
  "$URL/apps/rover/add-fill")"
[ "$parts_only_result" = $'Saved fill - $3.499 - derived $14.00\n201' ] \
  || fail "fixture 40 parts-only station create failed: $parts_only_result"
parts_only_report="$(rover_report "$(urql_station "$parts_only_station")")"
grep -Fq "$parts_only_station" <<<"$parts_only_report" \
  || fail "fixture 40 parts-only station row missing: $parts_only_report"
grep -Fq '20 Example Road' <<<"$parts_only_report" \
  || fail "fixture 40 parts-only line1 missing: $parts_only_report"
grep -Fq 'Sampletown' <<<"$parts_only_report" \
  || fail "fixture 40 parts-only locality missing: $parts_only_report"
if grep -Fq '[%formatted ' <<<"$parts_only_report"; then
  fail "fixture 40 parts-only station synthesized a formatted child: $parts_only_report"
fi
note "fixture 40 PASS - manual stations persist formatted+parts and parts-only address evidence; omitted children create no rows"

name_only_station="Name Only Station $(date +%s%N)"
name_only_place="Name Only Place $(date +%s%N)"
name_only_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"4.000","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-29T12:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"%s","newPlaceLabel":"%s","newStationKind":"fuel","newAddressFormatted":"","newAddressLine1":"","newAddressLine2":"","newLocality":"","newRegion":"","newPostalCode":"","newCountry":"","newLatitude":"","newLongitude":"","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' "$fill_edit_vehicle" "$name_only_station" "$name_only_place")" \
  "$URL/apps/rover/add-fill")"
[ "$name_only_result" = $'Saved fill - $3.499 - derived $14.00\n201' ] \
  || fail "fixture 41 name-only station create failed: $name_only_result"
name_only_report="$(rover_report "$(urql_station "$name_only_station")")"
grep -Fq "$name_only_station" <<<"$name_only_report" \
  || fail "fixture 41 station row missing: $name_only_report"
[ "$(grep -oF '[%vector-count 0]' <<<"$name_only_report" | wc -l)" -eq 4 ] \
  || fail "fixture 41 name-only station wrote address/formatted/part/coordinate evidence: $name_only_report"
note "fixture 41 PASS - name-only manual station writes no empty address or formatted rows and no zero-coordinate row"
if [ "${ROVER_FIXTURE_STOP:-}" = 41 ]; then
  exit 0
fi

consumable_seed="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s3)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -q '%noun 0' <<<"$consumable_seed" \
  || fail "fixture 42 consumable starter seed failed: $consumable_seed"
consumable_view="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")")"
for starter in DEF 'Washer Fluid' 'Motor Oil' Coolant; do
  grep -q "<option value=\"$starter\"" <<<"$consumable_view" \
    || fail "fixture 42 consumable starter missing from purchase entry: $starter"
done
economy_before="$(grep -oF "data-economy-vehicle=\"$fill_edit_vehicle\" data-economy=\"9.000 mpg\"" <<<"$consumable_view" | wc -l)"
def_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","consumable":"DEF","quantity":"2.500","price":"$4.49","profile":"us-usd-gal","settlement":"standard","observed":"2026-07-30T12:00","zone":"America/Chicago"}' "$fill_edit_vehicle")" \
  "$URL/apps/rover/add-consumable")"
[ "$def_result" = $'Saved consumable purchase - $11.25\n201' ] \
  || fail "fixture 42 DEF purchase failed: $def_result"
def_report="$(rover_report "$(urql_consumable "$fill_edit_vehicle" 'DEF' '~2026.07.30..12.00.00')")"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%quantity-milli 25717 2500\\].*\\[%unit-price-mills 25717 4499\\].*\\[%settlement-mode %tas %standard\\].*\\[%price-profile %tas %us-usd-gal\\].*\\[%minor-unit-decimals 25717 2\\].*\\[%cash-increment-mills 25717 50\\]" <<<"$def_report" \
  || fail "fixture 42 DEF purchase did not retain exact snapshotted pricing: $def_report"
consumable_after="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")")"
economy_after="$(grep -oF "data-economy-vehicle=\"$fill_edit_vehicle\" data-economy=\"9.000 mpg\"" <<<"$consumable_after" | wc -l)"
[ "$economy_before" -eq 1 ] && [ "$economy_after" -eq 1 ] \
  || fail "fixture 42 consumable changed fuel-economy derivation: before=$economy_before after=$economy_after"
note "fixture 42 PASS - DEF purchase uses snapshotted exact pricing and remains outside fuel-economy derivation"
if [ "${ROVER_FIXTURE_STOP:-}" = 42 ]; then
  exit 0
fi

charge_subtype_vehicle="Charge Subtype Vehicle $(date +%s%N)"
charge_subtype_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Electricity"}' "$charge_subtype_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$charge_subtype_created" = "Added vehicle - $charge_subtype_vehicle"$'\n201' ] \
  || fail "fixture 43 setup vehicle failed: $charge_subtype_created"
charge_subtype_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-07-31T12:00","end":"2026-07-31T12:30","zone":"America/Chicago","energyDelivered":"40.0","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"unknown","currency":"usd"}' "$charge_subtype_vehicle")" \
  "$URL/apps/rover/add-charge")"
[ "$charge_subtype_result" = $'Saved charge - Energy delivered 40.0 kWh\n201' ] \
  || fail "fixture 43 charge with subtype failed: $charge_subtype_result"
charge_subtype_report="$(rover_report "$(urql_charge_subtype "$charge_subtype_vehicle" '~2026.07.31..12.00.00')")"
grep -q "\\[%vehicle 116 '$charge_subtype_vehicle'\\].*\\[%charging-subtype 116 'DC Fast'\\]" <<<"$charge_subtype_report" \
  || fail "fixture 43 charging-session-subtype link missing: $charge_subtype_report"
note "fixture 43 PASS - charge persists its electricity subtype through charging-session-subtype"
if [ "${ROVER_FIXTURE_STOP:-}" = 43 ]; then
  exit 0
fi

cost_vehicle="Charge Cost Vehicle $(date +%s%N)"
cost_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Electricity"}' "$cost_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$cost_created" = "Added vehicle - $cost_vehicle"$'\n201' ] \
  || fail "fixture 105 setup vehicle failed: $cost_created"

cost_components='[{"component":"energy","quantity":"45.678","unit":"kwh","rate":"0.250","amount":"11.420"},{"component":"time","quantity":"30","unit":"minute","rate":"0.100","amount":"3.000"},{"component":"session","quantity":"1","unit":"session","rate":"1.500","amount":"1.500"},{"component":"idle","quantity":"5","unit":"minute","rate":"0.500","amount":"2.500"},{"component":"tax","quantity":"1","unit":"session","rate":"1.000","amount":"1.000"},{"component":"discount","quantity":"1","unit":"session","rate":"2.000","amount":"2.000"}]'

itemized_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T12:00","end":"2026-08-01T12:45","zone":"America/Chicago","energyDelivered":"45.678","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":%s}' "$cost_vehicle" "$cost_components")" \
  "$URL/apps/rover/add-charge")"
[ "$itemized_result" = $'Saved charge - Energy delivered 45.678 kWh - itemized total $17.420\n201' ] \
  || fail "fixture 105 itemized charge was not saved: $itemized_result"

itemized_proof="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
;<  res=(unit vase)  bind:m
  (build-file [our %rover da+now] /lib/rover-act/hoon)
?~  res  (pure:m !>(%build-failed))
(pure:m (slap u.res (ream (crip "(derive-charging-total ~[[%energy 11.420] [%time 3.000] [%session 1.500] [%idle 2.500] [%tax 1.000] [%discount 2.000]])"))))')"
grep -q '19420 2000 17420' <<<"$itemized_proof" \
  || fail "fixture 105 derive-charging-total did not report the expected proof: $itemized_proof"

charge_card_for() {
  python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
vehicle, state = sys.argv[1:3]
marker = "data-vehicle-settings-panel data-vehicle=\"%s\"" % vehicle
at = document.find(marker)
if at < 0:
    raise SystemExit("vehicle settings panel is absent")
end = document.find("<article class=\"vehicle-card\"", at)
panel = document[at:] if end < 0 else document[at:end]
for card in re.findall(r"<article class=\"history-card charge\".*?</article>", panel, re.S):
    if "data-cost-state=\"%s\"" % state in card:
        print(card)
        break
else:
    raise SystemExit("no %s charge card for %s" % (state, vehicle))' "$1" "$2"
}

cost_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
cost_card="$(charge_card_for "$cost_vehicle" itemized <<<"$cost_view")" \
  || fail "fixture 105 could not read the itemized charge back through the view"
grep -q 'data-cost-state="itemized"' <<<"$cost_card" \
  || fail "fixture 105 view does not report the itemized cost state: $cost_card"
grep -q 'data-itemized-total="\$17.420"' <<<"$cost_card" \
  || fail "fixture 105 view does not derive the itemized total: $cost_card"
for expected in \
  'data-cost-component="energy">energy</span><span>45.678 kwh</span><span>$0.250</span><span>$11.420<' \
  'data-cost-component="time">time</span><span>30 minute</span><span>$0.100</span><span>$3.000<' \
  'data-cost-component="session">session</span><span>1 session</span><span>$1.500</span><span>$1.500<' \
  'data-cost-component="idle">idle</span><span>5 minute</span><span>$0.500</span><span>$2.500<' \
  'data-cost-component="tax">tax</span><span>1 session</span><span>$1.000</span><span>$1.000<' \
  'data-cost-component="discount">discount</span><span>1 session</span><span>$2.000</span><span>-$2.000<' \
  ; do
  grep -qF "$expected" <<<"$cost_card" \
    || fail "fixture 105 itemized component row is missing or inexact: want '$expected' in $cost_card"
done
cost_order="$(grep -oE 'data-cost-component="[a-z]+"' <<<"$cost_card" \
  | sed 's/.*"\([a-z]*\)"/\1/' | tr '\n' ' ')"
[ "$cost_order" = "energy time session idle tax discount " ] \
  || fail "fixture 105 itemized components are not in the ratified order: $cost_order"
note "fixture 105 PASS - the add-charge surface records six itemized components and the view derives the same total derive-charging-total proves"

receipt_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T14:00","end":"2026-08-01T14:30","zone":"America/Chicago","energyDelivered":"40.0","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"receipt-total-only","currency":"usd","sourceTotal":"22.34","components":[]}' "$cost_vehicle")" \
  "$URL/apps/rover/add-charge")"
[ "$receipt_result" = $'Saved charge - Energy delivered 40.0 kWh - receipt total $22.340\n201' ] \
  || fail "fixture 106 receipt-total-only charge was not saved: $receipt_result"
receipt_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
receipt_card="$(charge_card_for "$cost_vehicle" receipt-total-only <<<"$receipt_view")" \
  || fail "fixture 106 could not read the receipt total back through the view"
grep -q 'data-receipt-total="\$22.340"' <<<"$receipt_card" \
  || fail "fixture 106 view does not preserve the source-reported receipt total: $receipt_card"
grep -q 'source reported' <<<"$receipt_card" \
  || fail "fixture 106 view does not mark the receipt total as source reported: $receipt_card"
if grep -q 'data-cost-component=' <<<"$receipt_card"; then
  fail "fixture 106 receipt-total-only charge carries component rows: $receipt_card"
fi
if grep -q 'data-itemized-total=' <<<"$receipt_card"; then
  fail "fixture 106 receipt-total-only charge derives an itemized total: $receipt_card"
fi
note "fixture 106 PASS - a receipt-only total survives as reported evidence with no components and no derived total"

empty_itemized="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[]}' "$cost_vehicle")" \
  "$URL/apps/rover/add-charge")"
[ "$empty_itemized" = $'%bad-shape: charge.components\n400' ] \
  || fail "fixture 107 itemized charge without components was accepted: $empty_itemized"

receipt_with_components="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"receipt-total-only","currency":"usd","sourceTotal":"22.34","components":%s}' "$cost_vehicle" "$cost_components")" \
  "$URL/apps/rover/add-charge")"
[ "$receipt_with_components" = $'%bad-shape: charge.components\n400' ] \
  || fail "fixture 107 receipt-total-only charge with components was accepted: $receipt_with_components"

bad_kind="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[{"component":"parking","quantity":"1","unit":"session","rate":"1.000","amount":"1.000"}]}' "$cost_vehicle")" \
  "$URL/apps/rover/add-charge")"
[ "$bad_kind" = $'%bad-shape: charge.component\n400' ] \
  || fail "fixture 107 component with an unknown kind was accepted: $bad_kind"

free_with_total="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"free","currency":"usd","sourceTotal":"22.34","components":[]}' "$cost_vehicle")" \
  "$URL/apps/rover/add-charge")"
[ "$free_with_total" = $'%bad-shape: charge.source-total\n400' ] \
  || fail "fixture 107 free charge with a source total was accepted: $free_with_total"

missing_total="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"receipt-total-only","currency":"usd","sourceTotal":"","components":[]}' "$cost_vehicle")" \
  "$URL/apps/rover/add-charge")"
[ "$missing_total" = $'%bad-shape: charge.source-total\n400' ] \
  || fail "fixture 107 receipt-total-only charge without a total was accepted: $missing_total"

over_discount="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","subtype":"DC Fast","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[{"component":"energy","quantity":"1","unit":"kwh","rate":"1.000","amount":"1.000"},{"component":"discount","quantity":"1","unit":"session","rate":"2.000","amount":"2.000"}]}' "$cost_vehicle")" \
  "$URL/apps/rover/add-charge")"
[ "$over_discount" = $'%bad-range: charge.components\n400' ] \
  || fail "fixture 107 discount larger than the charged components was accepted: $over_discount"

refused_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
refused_cards="$(grep -c 'history-card charge' <<<"$refused_view")"
accepted_cards="$(grep -c 'history-card charge' <<<"$receipt_view")"
[ "$refused_cards" = "$accepted_cards" ] \
  || fail "fixture 107 a refused charge still reached the database: before=$accepted_cards after=$refused_cards"
note "fixture 107 PASS - Rover refuses an empty itemized set, a receipt total with components, an unknown component kind, a cost total on a free charge, and a discount larger than its charges, and writes none of them"
if [ "${ROVER_FIXTURE_STOP:-}" = 107 ]; then
  exit 0
fi

payment_base_payload="$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"1.000","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":""' "$fill_edit_vehicle")"
without_payment_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "${payment_base_payload},\"observed\":\"2026-07-28T18:00\",\"paymentMethod\":\"\"}" \
  "$URL/apps/rover/add-fill")"
with_payment_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "${payment_base_payload},\"observed\":\"2026-07-28T19:00\",\"paymentMethod\":\"Personal Visa\"}" \
  "$URL/apps/rover/add-fill")"
[ "$without_payment_result" = $'Saved fill - $3.499 - derived $3.50\n201' ] \
  || fail "fixture 44 no-payment control failed: $without_payment_result"
[ "$with_payment_result" = "$without_payment_result" ] \
  || fail "fixture 44 payment link changed derived total: without=$without_payment_result with=$with_payment_result"
payment_without_report="$(rover_report "$(urql_fill_edit "$fill_edit_vehicle" '~2026.07.28..18.00.00')")"
payment_with_report="$(rover_report "$(urql_fill_edit "$fill_edit_vehicle" '~2026.07.28..19.00.00')")"
for report in "$payment_without_report" "$payment_with_report"; do
  grep -q '\[%unit-price-mills 25717 3499\].*\[%settlement-mode %tas %standard\]' <<<"$report" \
    || fail "fixture 44 settlement/arithmetic evidence changed: $report"
done
[ "$(grep -oF '[%vector-count 0]' <<<"$payment_without_report" | wc -l)" -ge 6 ] \
  || fail "fixture 44 no-payment control unexpectedly has optional link evidence: $payment_without_report"
grep -q "\\[%payment-method 116 'Personal Visa'\\]" <<<"$payment_with_report" \
  || fail "fixture 44 payment-method link missing: $payment_with_report"
note "fixture 44 PASS - payment method is descriptive; settlement mode and derived total are identical with or without its link"
if [ "${ROVER_FIXTURE_STOP:-}" = 44 ]; then
  exit 0
fi

fixture45_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
fixture45_sources="$(
  python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
labels = re.findall(r"<option[^>]+data-starter-source[^>]*>([^<]+)</option>", document)
print("|".join(sorted(set(label.strip() for label in labels))))' <<<"$fixture45_view"
)"
[ "$fixture45_sources" = 'CNG|Diesel|Electricity|Ethanol|Gasoline|Hydrogen|LNG|Propane' ] \
  || fail "fixture 45 clean-run source set contains fixture debris: ${fixture45_sources:-<none>}"
note "fixture 45 PASS - the run reached fixture 44 and the served source selector still has exactly eight owner sources"
if [ "${ROVER_FIXTURE_STOP:-}" = 45 ]; then
  exit 0
fi

phev_vehicle="Fixture 46 PHEV $(date +%s%N)"
phev_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":["Electricity"],"drivingModes":[]}' "$phev_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$phev_created" = "Added vehicle - $phev_vehicle"$'\n201' ] \
  || fail "fixture 46 PHEV create failed: $phev_created"
phev_report="$(rover_report "$(urql_vehicle_settings "$phev_vehicle")")"
grep -q "\\[%energy 116 'Gasoline'\\].*\\[%link-archived 102 1\\]" <<<"$phev_report" \
  || fail "fixture 46 active Gasoline link missing: $phev_report"
grep -q "\\[%energy 116 'Electricity'\\].*\\[%link-archived 102 1\\]" <<<"$phev_report" \
  || fail "fixture 46 active Electricity link missing: $phev_report"
phev_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
phev_panel="$(html_slice "data-vehicle-settings-panel data-vehicle=\"$phev_vehicle\"" '</article>' <<<"$phev_view")"
grep -q 'data-vehicle-action="fill"' <<<"$phev_panel" \
  || fail "fixture 46 PHEV hub lacks Add Fill"
grep -q 'data-vehicle-action="charge"' <<<"$phev_panel" \
  || fail "fixture 46 PHEV hub lacks Add Charge"
note "fixture 46 PASS - create persisted active Gasoline and Electricity links and the vehicle hub offers fill and charge"
if [ "${ROVER_FIXTURE_STOP:-}" = 46 ]; then
  exit 0
fi

phev_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"5.000","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-29T08:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' "$phev_vehicle")" \
  "$URL/apps/rover/add-fill")"
[ "$phev_fill" = $'Saved fill - $3.499 - derived $17.50\n201' ] \
  || fail "fixture 47 historical-fill setup failed: $phev_fill"
phev_edited="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","energySources":["Electricity"],"drivingModes":[]}' "$phev_vehicle" "$phev_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$phev_edited" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 47 energy-set edit failed: $phev_edited"
phev_edited_report="$(rover_report "$(urql_vehicle_settings "$phev_vehicle")")"
grep -q "\\[%energy 116 'Gasoline'\\].*\\[%link-archived 102 0\\]" <<<"$phev_edited_report" \
  || fail "fixture 47 removed source was not retired with archived Y: $phev_edited_report"
grep -q "\\[%energy 116 'Electricity'\\].*\\[%link-archived 102 1\\]" <<<"$phev_edited_report" \
  || fail "fixture 47 retained source is not active: $phev_edited_report"
phev_edited_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
phev_edited_panel="$(html_slice "data-vehicle-settings-panel data-vehicle=\"$phev_vehicle\"" '</article>' <<<"$phev_edited_view")"
grep -q '<dt>ENERGY</dt><dd>Gasoline</dd>' <<<"$phev_edited_panel" \
  || fail "fixture 47 historical Gasoline fill disappeared after unlink"
if grep -q 'data-vehicle-action="fill"' <<<"$phev_edited_panel"; then
  fail "fixture 47 retired reservoir source still offers Add Fill"
fi
grep -q 'data-vehicle-action="charge"' <<<"$phev_edited_panel" \
  || fail "fixture 47 retained electricity source no longer offers Add Charge"
note "fixture 47 PASS - edit retired Gasoline with literal Y, retained Electricity, and preserved the historical fill"
if [ "${ROVER_FIXTURE_STOP:-}" = 47 ]; then
  exit 0
fi

mode_vehicle="Fixture 48 Modes $(date +%s%N)"
mode_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[],"drivingModes":["Towing"]}' "$mode_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$mode_created" = "Added vehicle - $mode_vehicle"$'\n201' ] \
  || fail "fixture 48 mode create failed: $mode_created"
mode_create_report="$(rover_report "$(urql_vehicle_settings "$mode_vehicle")")"
grep -q "\\[%driving-mode 116 'Towing'\\].*\\[%link-archived 102 1\\]" <<<"$mode_create_report" \
  || fail "fixture 48 create-mode membership missing: $mode_create_report"
mode_edited="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","energySources":["Gasoline"],"drivingModes":["Mixed Driving"]}' "$mode_vehicle" "$mode_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$mode_edited" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 48 mode edit failed: $mode_edited"
mode_edit_report="$(rover_report "$(urql_vehicle_settings "$mode_vehicle")")"
grep -q "\\[%driving-mode 116 'Towing'\\].*\\[%link-archived 102 0\\]" <<<"$mode_edit_report" \
  || fail "fixture 48 removed mode was not retired with archived Y: $mode_edit_report"
grep -q "\\[%driving-mode 116 'Mixed Driving'\\].*\\[%link-archived 102 1\\]" <<<"$mode_edit_report" \
  || fail "fixture 48 edit-mode membership missing: $mode_edit_report"
mode_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
mode_options="$(
  MODE_VEHICLE="$mode_vehicle" python3 -c 'import html, os, re, sys
document = html.unescape(sys.stdin.read())
vehicle = re.escape(os.environ["MODE_VEHICLE"])
match = re.search(rf"<article[^>]+data-vehicle=\"{vehicle}\".*?</article>", document, re.S)
panel = match.group(0) if match else ""
modes = re.findall(r"<input type=\"checkbox\" name=\"drivingModes\" value=\"([^\"]+)\" checked", panel)
print("|".join(modes))' <<<"$mode_view"
)"
grep -q 'Mixed Driving' <<<"$mode_options" \
  || fail "fixture 48 edited member mode is not selected in settings: $mode_options"
if grep -q 'Towing' <<<"$mode_options"; then
  fail "fixture 48 non-member Towing remains selected for the vehicle"
fi
note "fixture 48 PASS - create and edit mode memberships persist; the non-member mode is absent for the vehicle"
if [ "${ROVER_FIXTURE_STOP:-}" = 48 ]; then
  exit 0
fi

def_vehicle="Fixture 49 DEF $(date +%s%N)"
no_def_vehicle="Fixture 49 No DEF $(date +%s%N)"
def_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Diesel","additionalEnergy":[],"drivingModes":[],"defEnabled":"yes","defTankSize":"5.5","defTankUnit":"gal"}' "$def_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
no_def_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Diesel","additionalEnergy":[],"drivingModes":[]}' "$no_def_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$def_created" = "Added vehicle - $def_vehicle"$'\n201' ] \
  || fail "fixture 49 DEF-enabled vehicle create failed: $def_created"
[ "$no_def_created" = "Added vehicle - $no_def_vehicle"$'\n201' ] \
  || fail "fixture 49 DEF-disabled control create failed: $no_def_created"
def_report="$(rover_report "$(urql_vehicle_settings "$def_vehicle")")"
no_def_report="$(rover_report "$(urql_vehicle_settings "$no_def_vehicle")")"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%link-archived 102 1\\]" <<<"$def_report" \
  || fail "fixture 49 DEF enablement link missing or archived: $def_report"
if grep -q "\\[%consumable 116 'DEF'\\]" <<<"$no_def_report"; then
  fail "fixture 49 disabled control has a vehicle-consumables row: $no_def_report"
fi
note "fixture 49 PASS - enabled Diesel has an active DEF link; disabled Diesel has no link row"
if [ "${ROVER_FIXTURE_STOP:-}" = 49 ]; then
  exit 0
fi

grep -q '\[%digits 25717 55\].*\[%decimals 25717 1\].*\[%unit %tas %gal\]' <<<"$def_report" \
  || fail "fixture 50 exact DEF tank size missing: $def_report"
if grep -q '\[%digits 25717 ' <<<"$no_def_report"; then
  fail "fixture 50 no-tank control has a vehicle-consumable-tank-size row: $no_def_report"
fi
def_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
def_panel="$(
  DEF_VEHICLE="$def_vehicle" python3 -c 'import os, re, sys
document = sys.stdin.read()
vehicle = re.escape(os.environ["DEF_VEHICLE"])
match = re.search(rf"<article[^>]+data-vehicle-settings-panel data-vehicle=\"{vehicle}\".*?</article>", document, re.S)
print(match.group(0) if match else "")' <<<"$def_view"
)"
grep -q 'name="defEnabled" value="yes" checked' <<<"$def_panel" \
  || fail "fixture 50 served Diesel settings do not show DEF enabled: $def_panel"
grep -q 'name="defTankSize"[^>]*value="5.5"' <<<"$def_panel" \
  || fail "fixture 50 served Diesel settings do not show exact DEF tank size: $def_panel"
if [ -n "${ROVER_CAPTURE_DIR:-}" ]; then
  mkdir -p "$ROVER_CAPTURE_DIR"
  printf '%s\n' "$def_panel" > "$ROVER_CAPTURE_DIR/served-vehicle-settings-def.html"
fi
note "fixture 50 PASS - composite DEF tank size stores exact 55/1/gal, absence creates no row, and settings re-render 5.5 gal"
if [ "${ROVER_FIXTURE_STOP:-}" = 50 ]; then
  exit 0
fi

for def_interval in \
  '2026-08-10T08:00|1.500|10000.0' \
  '2026-08-15T08:00|2.000|11000.0'; do
  IFS='|' read -r def_observed def_quantity def_mileage <<<"$def_interval"
  def_interval_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s","consumable":"DEF","quantity":"%s","price":"$4.49","profile":"us-usd-gal","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"%s","mileageUnit":"mi"}' "$def_vehicle" "$def_quantity" "$def_observed" "$def_mileage")" \
    "$URL/apps/rover/add-consumable")"
  case "$def_interval_result" in
    'Saved consumable purchase - '*$'\n201') ;;
    *) fail "fixture 51 DEF interval purchase failed: $def_interval_result" ;;
  esac
done
default_def_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s"}' "$def_vehicle")" \
  "$URL/apps/rover/set-default-vehicle")"
[ "$default_def_result" = $'Saved default vehicle\n201' ] \
  || fail "fixture 51 could not set DEF vehicle as default: $default_def_result"
def_economy_response="$(curl -s -b "$JAR" -w $'\nROVER_HTTP_STATUS=%{http_code}' "$URL/apps/rover/view")"
[ "$(scoped_view_status "$def_economy_response")" = 200 ] \
  || fail "fixture 51 Statistics view returned $(scoped_view_status "$def_economy_response"): $(scoped_view_html "$def_economy_response")"
def_economy_view="$(scoped_view_html "$def_economy_response")"
grep -q "data-def-economy-vehicle=\"$def_vehicle\" data-def-economy=\"500.000 mi/gal DEF\"" <<<"$def_economy_view" \
  || fail "fixture 51 exact DEF economy is absent from statistics"
grep -q 'DEF ECONOMY - LAST INTERVAL' <<<"$def_economy_view" \
  || fail "fixture 51 hub lacks DEF economy readout"
grep -q '>500.000 mi/gal DEF<' <<<"$def_economy_view" \
  || fail "fixture 51 hub does not render exact human DEF economy"
note "fixture 51 PASS - two odometer-linked DEF purchases derive and render exact 500.000 mi/gal DEF"
if [ "${ROVER_FIXTURE_STOP:-}" = 51 ]; then
  exit 0
fi

def_break_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","consumable":"DEF","quantity":"1.000","price":"$4.49","profile":"us-usd-gal","settlement":"standard","observed":"2026-08-20T08:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi"}' "$def_vehicle")" \
  "$URL/apps/rover/add-consumable")"
[ "$def_break_result" = $'Saved consumable purchase - $4.50\n201' ] \
  || fail "fixture 52 break purchase failed: $def_break_result"
def_break_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q "data-def-economy-unavailable=\"$def_vehicle\"" <<<"$def_break_view" \
  || fail "fixture 52 latest DEF interval is not marked unavailable"
grep -q 'Latest DEF purchase has no odometer reading' <<<"$def_break_view" \
  || fail "fixture 52 unavailable DEF interval lacks a human reason"
if grep -Eq 'data-def-economy="(0|estimated)' <<<"$def_break_view"; then
  fail "fixture 52 fabricated a zero or estimated DEF economy"
fi
note "fixture 52 PASS - missing odometer evidence explicitly breaks the latest DEF interval with a human reason"
if [ "${ROVER_FIXTURE_STOP:-}" = 52 ]; then
  exit 0
fi

fuel_before_fixture53="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")" | grep -oF "data-economy-vehicle=\"$fill_edit_vehicle\" data-economy=\"9.000 mpg\"" | wc -l)"
def_outside_fuel="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","consumable":"DEF","quantity":"1.000","price":"$4.49","profile":"us-usd-gal","settlement":"standard","observed":"2026-08-21T08:00","zone":"America/Chicago","mileage":"20200.0","mileageUnit":"mi"}' "$fill_edit_vehicle")" \
  "$URL/apps/rover/add-consumable")"
[ "$def_outside_fuel" = $'Saved consumable purchase - $4.50\n201' ] \
  || fail "fixture 53 DEF control purchase failed: $def_outside_fuel"
fuel_after_view="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")")"
fuel_after_fixture53="$(grep -oF "data-economy-vehicle=\"$fill_edit_vehicle\" data-economy=\"9.000 mpg\"" <<<"$fuel_after_view" | wc -l)"
[ "$fuel_before_fixture53" -eq 1 ] && [ "$fuel_after_fixture53" -eq 1 ] \
  || fail "fixture 53 DEF changed fuel economy: before=$fuel_before_fixture53 after=$fuel_after_fixture53"
fixture53_report="$(rover_report "$(urql_consumable "$fill_edit_vehicle" 'DEF' '~2026.08.21..08.00.00')")"
grep -q "\\[%consumable 116 'DEF'\\]" <<<"$fixture53_report" \
  || fail "fixture 53 DEF purchase missing from consumable parent: $fixture53_report"
note "fixture 53 PASS - DEF remains outside fuel acquisitions and leaves exact 9.000 mpg unchanged"
if [ "${ROVER_FIXTURE_STOP:-}" = 53 ]; then
  exit 0
fi

fi

if ! grep -q 'Phase A Vehicle' <<<"$view"; then
  seed_spike_via_eyre
  seed_app_structure_via_eyre
  seed_charging_cost_via_eyre
fi
view="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover/view")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "seeded vehicle view not 200"
view="$(scoped_view_html "$(scoped_view 0 "$fill_edit_vehicle")")"

grep -q '<section id="main-hub"' <<<"$view" || fail "main hub is missing"
grep -Eq 'DEFAULT VEHICLE NOT SET|Structure Vehicle|Mode Scope Vehicle' <<<"$view" ||
  fail "hub does not name its default state"
for destination in add-odometer vehicles-screen history-screen statistics-screen settings-screen; do
  grep -q "data-open-screen=\"$destination\"" <<<"$view" ||
    fail "hub navigation is missing $destination"
done
for readout in 'MOST RECENT ODOMETER' 'ECONOMY - LAST FILL' 'ECONOMY - LIFETIME' \
  'ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL' 'BEST ECONOMY' 'WORST ECONOMY'; do
  grep -q "$readout" <<<"$view" || fail "hub readout missing: $readout"
done
grep -q '&lsaquo; MAIN' <<<"$view" || fail "screens do not name MAIN in back controls"
grep -q 'id="history-vehicle-filter"' <<<"$view" \
  || fail "History screen lacks vehicle filter"
for column in 'DATE' 'ODOMETER' 'GALLONS' 'TOTAL COST'; do
  grep -q "data-history-column=\"$column\"" <<<"$view" ||
    fail "History table lacks $column"
done
grep -q 'class="history-record-detail"' <<<"$view" \
  || fail "History rows do not open a record detail"
grep -q 'class="history-edit-form"' <<<"$view" \
  || fail "History record detail lacks edit"
for statistic in economy-by-subtype fuel-costs distance-between-fills \
  time-between-fills average-price-per-unit distance-per-tank; do
  grep -q "data-statistic=\"$statistic\"" <<<"$view" ||
    fail "Statistics screen lacks table: $statistic"
done
statistics_html="$(html_slice 'id="statistics-screen"' 'id="settings-screen"' <<<"$view")"
if grep -Eqi '<(canvas|svg)|chart' <<<"$statistics_html"; then
  fail "Statistics contains charting in the tables-only milestone"
fi
grep -q 'id="custom-field-definition-form"' <<<"$view" \
  || fail "Settings lacks custom-field definition management"
grep -q 'data-settings-section="theme"' <<<"$view" \
  || fail "Settings lacks theme controls"
grep -q 'data-settings-section="import"' <<<"$view" \
  || fail "Settings lacks the import entry point"
grep -q 'data-settings-section="export"' <<<"$view" \
  || fail "Settings lacks the export section"
grep -q 'data-rover-export-download' <<<"$view" \
  || fail "Settings export section lacks the download anchor"
grep -q 'href="/apps/rover/export"' <<<"$view" \
  || fail "Settings export download does not address /apps/rover/export"
if grep -q 'EXPORT.*COMING LATER' <<<"$view"; then
  fail "Settings still shows the export placeholder"
fi
grep -q 'GRANTS.*COMING LATER' <<<"$view" \
  || fail "Settings lacks grants placeholder"
grep -q 'id="vehicle-add-form"' <<<"$view" \
  || fail "Vehicles screen lacks Add Vehicle"
grep -q 'data-set-default-vehicle' <<<"$view" \
  || fail "Vehicles screen lacks Set Default"
grep -q 'data-remove-vehicle' <<<"$view" \
  || fail "Vehicles screen lacks Archive"
for setting in 'ENERGY SOURCE' 'FUEL SUBTYPES' 'TANK SIZE' 'DRIVING MODES' \
  'DISPLAY PREFERENCE'; do
  grep -q "$setting" <<<"$view" ||
    fail "per-vehicle settings missing: $setting"
done
for action in 'Add Fill' 'Add Charge' 'Add Odometer'; do
  grep -q "$action" <<<"$view" ||
    fail "per-vehicle action missing: $action"
done
grep -q 'Phase A Vehicle' <<<"$view" || fail "vehicle view has no seeded vehicle"
grep -Eq '[0-9]{1,3}(,[0-9]{3})+\.[0-9]+ (mi|km)' <<<"$view" \
  || fail "current odometer is not human-formatted"
grep -q '12.345 gal' <<<"$view" || fail "fill quantity is not human-formatted"
grep -q '\$3\.499' <<<"$view" || fail "unit price is not human-formatted"
grep -q '\$43\.20' <<<"$view" || fail "derived fill total is not rendered"
grep -q 'CALCULATED TOTAL' <<<"$view" || fail "fill total is not labelled Calculated Total"
grep -q 'FUEL SUBTYPE' <<<"$view" || fail "fill detail has no Fuel Subtype field"
if grep -Eq '(^|[^0-9,.])(12345|3499)([^0-9,.]|$)|0x[0-9a-fA-F]+' <<<"$view"; then
  fail "vehicle view leaked a raw machine value or ID"
fi
note "vehicle list/detail render real rows in human units with no raw IDs"

grep -q 'id="fill-form"' <<<"$view" || fail "add-fill form is missing"
fill_html="$(html_slice 'id="add-fill"' '</section>' <<<"$view")"
field_order="$(
  FILL_HTML="$fill_html" python3 - <<'PY'
import os
import re

html = os.environ["FILL_HTML"]
fields = re.findall(r'data-fill-field="([^"]+)"', html)
print(",".join(fields))
PY
)"
[ "$field_order" = 'vehicle,odometer,previous-odometer,price,quantity,calculated-total,partial-fill,missed-fill,fuel-subtype,additive,station,driving-mode,average-speed,drive-balance,tags,custom-fields,notes,payment-method' ] \
  || fail "Add Fill field order is wrong: $field_order"
grep -q '>Calculated Total<' <<<"$fill_html" \
  || fail "Add Fill does not use the owner-facing Calculated Total name"
grep -q 'name="partialFill" type="checkbox"' <<<"$fill_html" \
  || fail "Add Fill lacks the default-unchecked Partial Fill control"
grep -q 'name="missedFill" type="checkbox"' <<<"$fill_html" \
  || fail "Add Fill lacks the default-unchecked Missed Fill control"
grep -q 'name="subtype"' <<<"$fill_html" || fail "Fuel Subtype selector is missing"
grep -q 'name="drivingMode"' <<<"$fill_html" || fail "Driving Mode selector is missing"
grep -q 'name="averageSpeed"' <<<"$fill_html" || fail "Average Speed input is missing"
grep -q 'id="fill-drive-balance".*data-state="unset"' <<<"$fill_html" \
  || fail "city/highway slider does not start visibly unset"
grep -q 'id="fill-tags"' <<<"$fill_html" || fail "Tags picker is missing"
grep -q 'id="fill-custom-fields"' <<<"$fill_html" || fail "custom-field region is missing"
for subtype in 87 91 93; do
  grep -q ">$subtype</option>" <<<"$fill_html" ||
    fail "Add Fill is missing allowed subtype: $subtype"
done
grep -q 'value="Tow / Haul" data-vehicle="Structure Vehicle"' <<<"$fill_html" \
  || fail "vehicle-scoped driving mode is missing or unscoped"
if grep -q '>Definition<' <<<"$fill_html"; then
  fail "Add Fill exposes the retired Definition owner-facing name"
fi
grep -q 'id="fill-price-completed"' <<<"$view" || fail "completed-price preview is missing"
grep -q '<output id="fill-derived-total"' <<<"$view" \
  || fail "derived total is not a non-input output"
if grep -Eq '<input[^>]+name="(total|unitPriceMills|quantityMilli)"' <<<"$fill_html"; then
  fail "add-fill form asks for a derived total or machine representation"
fi
grep -q 'Energy delivered' <<<"$view" || fail "add-charge surface lacks Energy delivered wording"
grep -q 'id="charge-form"' <<<"$view" || fail "add-charge form is missing"
grep -q 'name="energyDelivered"' <<<"$view" \
  || fail "add-charge form lacks optional delivered energy"
grep -q 'name="energySource"' <<<"$view" \
  || fail "add-charge form lacks delivered-energy source"
grep -q 'name="costState"' <<<"$view" || fail "add-charge form lacks cost state"
charge_html="$(html_slice 'id="add-charge"' '</section>' <<<"$view")"
grep -q '>Energy Source<' <<<"$charge_html" \
  || fail "Add Charge does not use Energy Source owner naming"
if grep -Eqi '>[[:space:]]*[^<]*definition' <<<"$charge_html"; then
  fail "Add Charge exposes the retired Definition owner-facing name"
fi
if grep -Eqi 'full|partial|battery filled' <<<"$charge_html"; then
  fail "add-charge screen contains a fuel tank-state concept"
fi
for cost_option in unknown free itemized receipt-total-only; do
  grep -qF "<option value=\"$cost_option\"" <<<"$charge_html" \
    || fail "fixture 108 add-charge cost state omits $cost_option: $charge_html"
done
grep -q 'id="charge-itemized"' <<<"$charge_html" \
  || fail "fixture 108 add-charge has no itemized component group"
grep -q 'id="charge-receipt-total"' <<<"$charge_html" \
  || fail "fixture 108 add-charge has no receipt total group"
grep -q 'data-add-cost-component' <<<"$charge_html" \
  || fail "fixture 108 itemized component rows are not repeatable"
for component_field in componentKind componentQuantity componentUnit componentRate componentAmount; do
  grep -qF "name=\"$component_field\"" <<<"$charge_html" \
    || fail "fixture 108 itemized component row lacks $component_field: $charge_html"
done
grep -q 'name="sourceTotal"' <<<"$charge_html" \
  || fail "fixture 108 receipt total group lacks its total field"
for component_kind in energy time session idle tax discount; do
  grep -qF "<option value=\"$component_kind\"" <<<"$charge_html" \
    || fail "fixture 108 component kind $component_kind is not offered: $charge_html"
done
for quantity_unit in kwh minute session; do
  grep -qF "<option value=\"$quantity_unit\"" <<<"$charge_html" \
    || fail "fixture 108 component quantity unit $quantity_unit is not offered: $charge_html"
done
note "fixture 108 PASS - add-charge offers all four cost states with repeatable itemized component rows and a receipt total field"
grep -q 'id="odometer-form"' <<<"$view" || fail "standalone odometer form is missing"
grep -q 'name="reading"' <<<"$view" || fail "odometer form lacks source-native reading"
grep -q 'id="fill-station"' <<<"$view" || fail "fill station selector is missing"
grep -q '>No station recorded<' <<<"$view" \
  || fail "station selector lacks explicit no-station choice"
grep -q '>Add new station&hellip;<' <<<"$view" \
  || fail "station selector lacks add-new choice"
grep -q 'id="fill-additives"' <<<"$view" || fail "fill additives multi-select is missing"
if grep -Eqi '<[^>]+class="[^"]*chip[^"]*"[^>]*>None<' <<<"$view"; then
  fail "zero additives render as a synthetic None chip"
fi
grep -q 'class="preference-form"' <<<"$view" \
  || fail "per-vehicle display preference control is missing"

bad_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"wat","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T19:22","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[]}' \
  "$URL/apps/rover/add-fill")"
[ "$bad_fill" = $'%bad-shape: fill.quantity\n400' ] \
  || fail "malformed fill did not name its field: $bad_fill"
note "malformed fill refuses as %bad-shape: fill.quantity"

set_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Structure Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle")"
[ "$set_default" = $'Saved default vehicle\n201' ] \
  || fail "initial app default insert failed: $set_default"
default_report="$(read_structure_report)"
[ "$(grep -o '\[%scope %tas %app\]' <<<"$default_report" | wc -l)" -eq 1 ] \
  || fail "app-default-vehicle is not a one-row singleton after insert"
grep -q "\\[%default-vehicle 116 'Structure Vehicle'\\]" <<<"$default_report" \
  || fail "initial app default does not point to Structure Vehicle"

change_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Mode Scope Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle")"
[ "$change_default" = $'Saved default vehicle\n201' ] \
  || fail "app default UPDATE failed: $change_default"
changed_default_report="$(read_structure_report)"
[ "$(grep -o '\[%scope %tas %app\]' <<<"$changed_default_report" | wc -l)" -eq 1 ] \
  || fail "fixture 20 default UPDATE did not preserve singleton; actual Obelisk report: $changed_default_report"
grep -q "\\[%default-vehicle 116 'Mode Scope Vehicle'\\]" \
  <<<"$changed_default_report" || fail "fixture 20 app default did not update in place; actual Obelisk report: $changed_default_report"
second_insert="$(rover_report "$URQL_TRY_SECOND_DEFAULT")"
grep -q '%avow 0 %noun 1 ' <<<"$second_insert" \
  || fail "fixture 20 second %app INSERT was not rejected; actual response: $second_insert"
note "fixture 20 PASS - live Obelisk kept one %app row across INSERT/UPDATE and rejected a second INSERT"

remove_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Mode Scope Vehicle"}' \
  "$URL/apps/rover/remove-vehicle")"
[ "$remove_default" = $'%default-vehicle: choose a new default before archiving\n409' ] \
  || fail "fixture 21 app-default vehicle archive was not refused; actual HTTP response: $remove_default"
note "fixture 21 PASS - live HTTP refused archiving the app-default vehicle until redesignation"
default_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q 'data-vehicle="Mode Scope Vehicle"' <<<"$default_view" \
  || fail "entry surfaces do not receive the app default vehicle"
grep -q 'Tank size is not recorded for this vehicle.' <<<"$default_view" \
  || fail "missing tank size does not explain why distance estimate is unavailable"

phev_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle")"
[ "$phev_default" = $'Saved default vehicle\n201' ] \
  || fail "setting multi-source default failed: $phev_default"
phev_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
phev_hub="$(html_slice 'id="main-hub"' '</section>' <<<"$phev_view")"
grep -q '>Add Fill<' <<<"$phev_hub" ||
  fail "multi-source hub does not offer Add Fill"
grep -q '>Add Charge<' <<<"$phev_hub" ||
  fail "multi-source hub does not offer Add Charge"
curl -s -b "$JAR" -o /dev/null \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Mode Scope Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle"

temporary_vehicle="Temporary Vehicle $(date +%s%N)"
browser_scope_vehicle="Browser Scope Vehicle $(date +%s%N)"
temporary_payload="$(
  printf '{"label":"%s","energy":"Gasoline"}' "$temporary_vehicle"
)"
added_vehicle="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-raw "$temporary_payload" \
  "$URL/apps/rover/add-vehicle")"
[ "$added_vehicle" = "Added vehicle - $temporary_vehicle"$'\n201' ] \
  || fail "Add Vehicle failed: $added_vehicle"
browser_scope_added="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[],"drivingModes":["Tow / Haul"]}' "$browser_scope_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$browser_scope_added" = "Added vehicle - $browser_scope_vehicle"$'\n201' ] \
  || fail "browser scope vehicle failed: $browser_scope_added"
browser_scope_edited="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","energySources":["Gasoline"],"drivingModes":["Tow / Haul"],"defaultSubtype":"91"}' "$browser_scope_vehicle" "$browser_scope_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$browser_scope_edited" = $'Saved vehicle settings\n201' ] \
  || fail "browser scope default subtype failed: $browser_scope_edited"
browser_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s"}' "$temporary_vehicle")" \
  "$URL/apps/rover/set-default-vehicle")"
[ "$browser_default" = $'Saved default vehicle\n201' ] \
  || fail "browser fixture default failed: $browser_default"

PLAYWRIGHT_ROOT="${PLAYWRIGHT_ROOT:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules}"
CHROMIUM_BIN="${CHROMIUM_BIN:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
[ -d "$PLAYWRIGHT_ROOT/playwright" ] || fail "Playwright package not found at $PLAYWRIGHT_ROOT"
[ -x "$CHROMIUM_BIN" ] || fail "Chromium not found at $CHROMIUM_BIN"
preview="$(
  URL="$URL" JAR="$JAR" CHROMIUM_BIN="$CHROMIUM_BIN" \
    SUBTYPE_VEHICLE="$browser_scope_vehicle" MODELESS_VEHICLE="$temporary_vehicle" \
    HISTORY_VEHICLE="$fill_edit_vehicle" \
    NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_BIN
  });
  const page = await browser.newPage({viewport: {width: 390, height: 844}});
  page.setDefaultTimeout(90000);
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/\s(urbauth-[^\s]+)\s+([^\s]+)/);
  if (!cookie) throw new Error('urbauth cookie missing');
  await page.context().addCookies([{
    name: cookie[1],
    value: cookie[2],
    domain: 'localhost',
    path: '/'
  }]);
  await page.goto(`${process.env.URL}/apps/rover`);
  const fillForm = page.locator('#fill-form');
  await fillForm.waitFor({state: 'attached', timeout: 90000});
  await page.locator('[data-open-screen="add-fill"]').click();
  const initialVehicle = await fillForm.locator('[name="vehicle"]').inputValue();
  await fillForm.locator('[name="vehicle"]').selectOption({label: process.env.SUBTYPE_VEHICLE});
  const subtypeState = await fillForm.locator('[name="subtype"]').evaluate((select) => ({
    selected: select.value,
    visible: [...select.options]
      .filter((option) => option.dataset.definition && !option.hidden)
      .map((option) => option.value)
      .sort()
  }));
  const structureModes = await fillForm.locator('[name="drivingMode"]').evaluate(
    (select) => [...select.options]
      .filter((option) => option.dataset.vehicle && !option.hidden)
      .map((option) => option.value)
  );
  await fillForm.locator('[name="vehicle"]').selectOption({label: process.env.MODELESS_VEHICLE});
  const otherModes = await fillForm.locator('[name="drivingMode"]').evaluate(
    (select) => [...select.options]
      .filter((option) => option.dataset.vehicle && !option.hidden).length
  );
  await fillForm.locator('[name="vehicle"]').selectOption({label: 'Structure Vehicle'});
  await fillForm.locator('[name="quantity"]').fill('12.344');
  await fillForm.locator('[name="price"]').fill('$3.49');
  const read = selector => page.locator(selector).evaluate(element => element.value);
  const price = await read('#fill-price-completed');
  const standard = await read('#fill-derived-total');
  await fillForm.locator('[name="quantity"]').fill('12.345');
  const afterQuantity = await read('#fill-derived-total');
  await fillForm.locator('[name="quantity"]').fill('12.344');
  await fillForm.locator('[name="price"]').fill('$3.50');
  const afterPrice = await read('#fill-derived-total');
  await fillForm.locator('[name="price"]').fill('$3.49');
  await fillForm.locator('[name="partialFill"]').check();
  const afterTank = await read('#fill-derived-total');
  await fillForm.locator('[name="station"]').selectOption('Edit Station');
  const firstAdditive = fillForm.locator('[name="additives"]').first();
  if (await firstAdditive.count()) await firstAdditive.check();
  const afterEvidence = await read('#fill-derived-total');
  await fillForm.locator('[name="settlement"]').evaluate((element) => {
    element.value = 'cash';
    element.dispatchEvent(new Event('change', {bubbles: true}));
  });
  const cash = await read('#fill-derived-total');
  const energySourceVisible =
    await fillForm.locator('.energy-source-control').isVisible();
  const balanceState = await fillForm.locator('#fill-drive-balance')
    .getAttribute('data-state');
  const shape = await page.locator('#fill-derived-total').evaluate(element => ({
    tag: element.tagName,
    editable: element.isContentEditable
  }));
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > innerWidth
  );
  const mobile = await page.evaluate(async () => {
    const visible = [...document.querySelectorAll(
      'button, select, input:not([type="checkbox"]):not([type="hidden"])'
    )]
      .filter(element => element.offsetParent !== null);
    const minTouch = Math.min(...visible.map(
      element => element.getBoundingClientRect().height
    ));
    const project = html => {
      const documentCopy = new DOMParser().parseFromString(html, 'text/html');
      const vehicle = [...documentCopy.querySelectorAll('.vehicle-card')]
        .find(card => card.querySelector('h2')?.textContent === 'Phase A Vehicle');
      return [...vehicle.querySelectorAll('.history-card')].map(card => ({
        time: card.querySelector('time').textContent.slice(0, 19),
        text: card.textContent.replace(/\s+/g, ' ').trim()
      }));
    };
    const first = project(await (await fetch('/apps/rover/view')).text());
    const second = project(await (await fetch('/apps/rover/view')).text());
    const ordered = first.every(
      (event, index) => index === 0 || first[index - 1].time <= event.time
    );
    return {
      touch: minTouch >= 44,
      stacked: getComputedStyle(document.querySelector('#app'))
        .gridTemplateColumns === 'none',
      font: document.fonts.check('12px "JetBrains Mono"'),
      ordered,
      stable: JSON.stringify(first) === JSON.stringify(second)
    };
  });
  await page.locator('#add-fill .back-control').click();
  await page.locator('#main-hub [data-open-screen="history-screen"]').click();
  const historyFilter = page.locator('#history-vehicle-filter');
  const historyDefault = await historyFilter.inputValue();
  const defaultRowsHonest = await page.locator('[data-history-vehicle]')
    .evaluateAll((rows, vehicle) => rows
      .filter((row) => !row.hidden)
      .every((row) => row.dataset.historyVehicle === vehicle),
      process.env.MODELESS_VEHICLE);
  const historyTarget = process.env.HISTORY_VEHICLE;
  await Promise.all([
    page.waitForResponse((response) =>
      response.url().endsWith('/apps/rover/view') &&
      response.request().method() === 'POST'
    ),
    historyFilter.evaluate((select, target) => {
      select.value = target;
      select.dispatchEvent(new Event('change', {bubbles: true}));
    }, historyTarget)
  ]);
  const firstHistoryRow = page.locator('[data-history-vehicle]').first();
  if (await firstHistoryRow.getAttribute('data-history-vehicle') !== historyTarget) {
    throw new Error(`history response did not contain ${historyTarget}`);
  }
  if (await firstHistoryRow.getAttribute('hidden') !== null) {
    throw new Error(`${historyTarget} history row remained hidden after filter change`);
  }
  await firstHistoryRow.locator('.history-record-toggle').click();
  const detailVisible =
    await firstHistoryRow.locator('.history-record-detail').isVisible();
  console.log(
    `${price} standard=${standard} quantity=${afterQuantity} price=${afterPrice} ` +
    `after-tank=${afterTank} ` +
    `after-evidence=${afterEvidence} cash=${cash} ` +
    `total=${shape.tag}/${shape.editable ? 'editable' : 'readonly'} ` +
    `energy-source=${energySourceVisible ? 'visible' : 'vehicle-property'} ` +
    `balance=${balanceState} ` +
    `default=${initialVehicle} ` +
    `subtypes=${subtypeState.selected}/${subtypeState.visible.join('|')} ` +
    `modes=${structureModes.join('|')}/${otherModes} ` +
    `history=${historyDefault}/${defaultRowsHonest}/${detailVisible} ` +
    `overflow=${overflow} touch=${mobile.touch} stacked=${mobile.stacked} ` +
    `font=${mobile.font} ordered=${mobile.ordered} stable=${mobile.stable}`
  );
  await browser.close();
})().catch(error => {
  console.error(error);
  process.exit(1);
});
NODE
)"
expected_preview="\$3.499 standard=\$43.19 quantity=\$43.20 price=\$43.32 after-tank=\$43.19 after-evidence=\$43.19 cash=\$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=$temporary_vehicle subtypes=91/100|85|87|88|89|90|91|92|93|95|98 modes=Tow / Haul/0 history=$temporary_vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true"
[ "$preview" = "$expected_preview" ] \
  || fail "browser fill preview mismatch: $preview"
note "browser measurements: $preview"
note "browser completes \$3.49 to \$3.499 and derives an exact non-editable total"
note "fixture 19 PASS - Chromium measured every source subtype selectable with only the default preselected: $preview"
note "fixture 26 PASS - Chromium measured Tow / Haul for an assigned vehicle and zero modes for a non-member vehicle: $preview"
note "fixture 28 PASS - Chromium measured single-source as a vehicle property; live PHEV HTTP already exposed fill and charge: $preview"
note "fixture 31 PASS - Chromium measured 390px overflow, stacking, and touch targets: $preview"

curl -s -b "$JAR" -o /dev/null \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Mode Scope Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle"
for cleanup_vehicle in "$browser_scope_vehicle" "$temporary_vehicle"; do
  removed_vehicle="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s"}' "$cleanup_vehicle")" \
    "$URL/apps/rover/remove-vehicle")"
  [ "$removed_vehicle" = $'Archived vehicle\n201' ] \
    || fail "archiving browser fixture vehicle failed ($cleanup_vehicle): $removed_vehicle"
done
note "app default inserts once, changes via UPDATE, refuses archive, and Vehicles add/archive round-trips"

before_structure_report="$(read_structure_report)"
before_balance_count="$(grep -o '\[%highway-percent ' <<<"$before_structure_report" | wc -l)"
before_tag_count="$(grep -o '\[%tag 116 ' <<<"$before_structure_report" | wc -l)"

unset_balance_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Structure Vehicle","definition":"Structure Gasoline","quantity":"1.111","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T20:10","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"Structure 93 AKI","missedFill":"yes","drivingMode":"Tow / Haul","averageSpeed":"55.5","speedUnit":"mph","driveBalance":"","tags":[],"newTag":""}' \
  "$URL/apps/rover/add-fill")"
[ "$unset_balance_fill" = $'Saved fill - $3.499 - derived $3.89\n201' ] \
  || fail "structured fill with untouched balance failed: $unset_balance_fill"

unset_report="$(read_structure_report)"
grep -q "\\[%subtype 116 'Structure 93 AKI'\\].*\\[%rating 25717 93\\]" \
  <<<"$unset_report" || fail "fixture 18 subtype-level octane mismatch; actual Obelisk report: $unset_report"
note "fixture 18 PASS - live Obelisk report ties the selected subtype to rating 93"
grep -q '\[%reason %tas %missed-fill\]' <<<"$unset_report" \
  || fail "fixture 22 Missed Fill wrote no economy-breaks row; actual Obelisk report: $unset_report"
grep -q "\\[%driving-mode 116 'Tow / Haul'\\]" <<<"$unset_report" \
  || fail "vehicle-scoped driving mode was not written"
grep -q '\[%digits 25717 555\].*\[%decimals 25717 1\].*\[%speed-unit %tas' \
  <<<"$unset_report" || fail "average speed did not retain exact evidence"
after_unset_balance_count="$(grep -o '\[%highway-percent ' <<<"$unset_report" | wc -l)"
after_unset_tag_count="$(grep -o '\[%tag 116 ' <<<"$unset_report" | wc -l)"
if [ "$after_unset_balance_count" -ne "$before_balance_count" ]; then
  fail "fixture 23 untouched balance changed row count: before=$before_balance_count after=$after_unset_balance_count"
fi
if [ "$after_unset_tag_count" -ne "$before_tag_count" ]; then
  fail "fixture 27 zero-tag fill changed row count: before=$before_tag_count after=$after_unset_tag_count"
fi

inline_tag="Mountain-$(date +%s%N)"
structured_payload="$(
  printf '{"vehicle":"Structure Vehicle","definition":"Structure Gasoline","quantity":"2.222","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-28T20:20","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"Structure 87 AKI","missedFill":"no","drivingMode":"Tow / Haul","averageSpeed":"","speedUnit":"mph","driveBalance":"73","tags":["Road trip","Winter"],"newTag":"%s"}' "$inline_tag"
)"
touched_balance_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$structured_payload" \
  "$URL/apps/rover/add-fill")"
[ "$touched_balance_fill" = $'Saved fill - $3.499 - derived $7.77\n201' ] \
  || fail "structured fill with asserted evidence failed: $touched_balance_fill"

structure_report="$(read_structure_report)"
grep -q '\[%highway-percent 25717 73\]' <<<"$structure_report" \
  || fail "fixture 23 touched balance did not store 73; actual Obelisk report: $structure_report"
note "fixture 23 PASS - live Obelisk counts stayed equal for unset balance and report stored asserted 73"
for tag in 'Road trip' 'Winter' "$inline_tag"; do
  grep -q "\\[%tag 116 '$tag'\\]" <<<"$structure_report" \
    || fail "fixture 27 tag was not linked: expected=$tag actual Obelisk report=$structure_report"
done
note "fixture 27 PASS - live Obelisk counts stayed equal for zero tags and linked existing plus inline tags"
note "subtypes, missed-fill break, scoped mode, exact speed, unset/asserted balance, and zero/many tags persist through real Obelisk"
view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q 'Unavailable - A missed fill was recorded, so this economy interval is unavailable.' <<<"$view" \
  || fail "fixture 22 missed-fill reason did not render; actual served HTML: $view"
note "fixture 22 PASS - live Obelisk break and served HTML retain the missed-fill reason in human text"

history_vehicle="History Vehicle $(date +%s%N)"
history_vehicle_payload="$(
  printf '{"label":"%s","energy":"Gasoline"}' "$history_vehicle"
)"
history_vehicle_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-raw "$history_vehicle_payload" \
  "$URL/apps/rover/add-vehicle")"
[ "$history_vehicle_result" = "Added vehicle - $history_vehicle"$'\n201' ] \
  || fail "History vehicle setup failed: $history_vehicle_result"
history_observed='2026-07-30T12:34'
history_fill_payload="$(
  printf '{"vehicle":"%s","definition":"Gasoline","quantity":"3.000","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":""}' "$history_vehicle" "$history_observed"
)"
history_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-raw "$history_fill_payload" \
  "$URL/apps/rover/add-fill")"
[ "$history_fill" = $'Saved fill - $3.499 - derived $10.50\n201' ] \
  || fail "History setup fill failed: $history_fill"
history_edit_payload="$(
  printf '{"vehicle":"%s","definition":"Gasoline","quantity":"3.333","price":"$3.59","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":""}' "$history_vehicle" "$history_observed"
)"
history_edit="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' --data-raw "$history_edit_payload" \
  "$URL/apps/rover/edit-fill")"
[ "$history_edit" = $'Saved fill changes - $12.00\n201' ] \
  || fail "History edit failed: $history_edit"
view="$(scoped_view_html "$(scoped_view 0 "$history_vehicle")")"
grep -q 'value="3.333"' <<<"$view" ||
  fail "edited History quantity did not render back"
grep -q '\$12\.00' <<<"$view" ||
  fail "fixture 30 edited History calculated total did not render; actual served HTML: $view"
note "fixture 30 PASS - live History default/detail measurement and Obelisk edit round-trip rendered 3.333 / \$12.00"

saved_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"6.543","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-28T19:21","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[]}' \
  "$URL/apps/rover/add-fill")"
[ "$saved_fill" = $'Saved fill - $3.499 - derived $22.89\n201' ] \
  || fail "valid fill was not saved: $saved_fill"
history="$(rover_report "$URQL_VEHICLE_HISTORY")"
grep -q '\[%quantity-milli 25717 6543\].*\[%unit-price-mills 25717 3499\]' <<<"$history" \
  || fail "saved fill did not retain exact 6543/3499 machine integers"
view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q '6.543 gal' <<<"$view" || fail "saved fill quantity did not render back to a human"
grep -q '\$22\.89' <<<"$view" || fail "saved fill derived total did not render"
note "valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived \$22.89"

new_station_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"5.111","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-29T00:10","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"UI Home Pump","newPlaceLabel":"UI Home","newStationKind":"private","additives":["Injector cleaner"]}' \
  "$URL/apps/rover/add-fill")"
[ "$new_station_fill" = $'Saved fill - $3.499 - derived $17.88\n201' ] \
  || fail "new-station fill failed: $new_station_fill"

saved_station_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"5.222","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-29T00:20","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"UI Home Pump","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":["Injector cleaner","Fuel stabilizer"]}' \
  "$URL/apps/rover/add-fill")"
[ "$saved_station_fill" = $'Saved fill - $3.499 - derived $18.27\n201' ] \
  || fail "saved-station fill failed: $saved_station_fill"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
[ "$(grep -o 'UI Home Pump' <<<"$view" | wc -l)" -ge 2 ] \
  || fail "new and saved private station fills did not both render"
grep -q 'Structure 93 AKI' <<<"$view" \
  || fail "fill detail does not render the stored subtype label"
grep -q 'Injector cleaner' <<<"$view" || fail "one-additive fill did not render"
grep -q 'Fuel stabilizer' <<<"$view" || fail "several-additive fill did not render"
grep -q 'No station recorded' <<<"$view" || fail "zero-station fill is not honest"
grep -q 'No additives recorded' <<<"$view" || fail "zero-additive fill is not honest"
if grep -Eq '<span class="chip">None</span>|0x[0-9a-fA-F]+' <<<"$view"; then
  fail "station/additive history leaked a synthetic None chip or raw ID"
fi
note "station none/saved/new and additive zero/one/several render honestly"

native_preference="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","distanceUnit":"native","currency":"usd"}' \
  "$URL/apps/rover/set-preference")"
[ "$native_preference" = $'Saved display preference - source-native\n201' ] \
  || fail "source-native preference failed: $native_preference"

preference_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"label":"Preference Vehicle","energy":"Gasoline"}' \
  "$URL/apps/rover/add-vehicle")"
[ "$preference_created" = $'Added vehicle - Preference Vehicle\n201' ] \
  || fail "preference vehicle create failed: $preference_created"
preference_odometer="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Preference Vehicle","reading":"20000.0","unit":"mi","observed":"2026-07-28T09:00","zone":"America/Chicago"}' \
  "$URL/apps/rover/add-odometer")"
[ "$preference_odometer" = $'Saved odometer - 20,000.0 mi\n201' ] \
  || fail "preference vehicle odometer failed: $preference_odometer"
preference_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Preference Vehicle","definition":"Gasoline","quantity":"10.000","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T09:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":""}' \
  "$URL/apps/rover/add-fill")"
[ "$preference_fill" = $'Saved fill - $3.499 - derived $34.99\n201' ] \
  || fail "preference vehicle fill failed: $preference_fill"

km_preference="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Preference Vehicle","distanceUnit":"km","currency":"usd"}' \
  "$URL/apps/rover/set-preference")"
[ "$km_preference" = $'Saved display preference - km\n201' ] \
  || fail "per-vehicle km preference failed: $km_preference"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -Fq '32,186.9 km (converted)' <<<"$view" \
  || fail "Preference Vehicle did not render converted and labelled"
phase_card="$(html_slice '<h2>Phase A Vehicle</h2>' '<h2>' <<<"$view")"
grep -q 'value="native" selected' <<<"$phase_card" \
  || fail "Phase A Vehicle preference was affected by the other vehicle"
preference_report="$(rover_report "$URQL_DISPLAY_PREFERENCE")"
grep -q '\[%value-digits 25717 0x30d40\].*\[%decimal-places 25717 1\].*\[%unit %tas 26989\]' <<<"$preference_report" \
  || fail "display preference changed stored odometer evidence"
grep -q '\[%distance-unit %tas 28011\]' <<<"$preference_report" \
  || fail "per-vehicle km preference was not stored"
note "per-vehicle km preference converts and labels one vehicle without rewriting evidence"

human_hub_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Preference Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle")"
[ "$human_hub_default" = $'Saved default vehicle\n201' ] \
  || fail "setting human-readout fixture default failed: $human_hub_default"
human_hub_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
human_hub="$(html_slice 'id="main-hub"' 'id="add-fill"' <<<"$human_hub_view")"
grep -Eq '[0-9]{1,3}(,[0-9]{3})+\.[0-9]+ (mi|km)' <<<"$human_hub" \
  || fail "default-vehicle hub odometer is not rendered in human units"
grep -q '<strong>Unavailable</strong>' <<<"$human_hub" \
  || fail "default-vehicle hub does not mark unavailable derivations"
grep -q 'Tank size is not recorded for this vehicle.' <<<"$human_hub" \
  || fail "fixture 24/29 hub lacks concrete tank-size reason; actual hub HTML: $human_hub"
curl -s -b "$JAR" -o /dev/null \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Mode Scope Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle"
note "fixture 24 PASS - live hub says tank size is not recorded instead of storing or rendering a sentinel"
note "fixture 29 PASS - live hub combines human odometer units with concrete unavailable reasons"

bad_charge="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Electricity","start":"2026-07-28T22:00","end":"2026-07-28T21:00","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"unknown","currency":"usd"}' \
  "$URL/apps/rover/add-charge")"
[ "$bad_charge" = $'%bad-range: charge.end\n400' ] \
  || fail "malformed charge did not name its end field: $bad_charge"

saved_charge="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Electricity","start":"2026-07-28T22:00","end":"2026-07-28T23:00","zone":"America/Chicago","energyDelivered":"41.25","energySource":"charger-reported","startBattery":"21","endBattery":"79.5","mileage":"10022.0","mileageUnit":"mi","costState":"free","currency":"usd"}' \
  "$URL/apps/rover/add-charge")"
[ "$saved_charge" = $'Saved charge - Energy delivered 41.25 kWh\n201' ] \
  || fail "valid charge was not saved: $saved_charge"

bad_odometer="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","reading":"ten thousand","unit":"mi","observed":"2026-07-28T23:05","zone":"America/Chicago"}' \
  "$URL/apps/rover/add-odometer")"
[ "$bad_odometer" = $'%bad-shape: odometer.reading\n400' ] \
  || fail "malformed odometer did not name its reading field: $bad_odometer"

saved_odometer="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","reading":"10023.125","unit":"mi","observed":"2026-07-28T23:05","zone":"America/Chicago"}' \
  "$URL/apps/rover/add-odometer")"
[ "$saved_odometer" = $'Saved odometer - 10,023.125 mi\n201' ] \
  || fail "valid odometer was not saved: $saved_odometer"

overlap_odometer="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","reading":"10024.125","unit":"mi","observed":"2026-07-28T23:05","zone":"America/Chicago"}' \
  "$URL/apps/rover/add-odometer")"
[ "$overlap_odometer" = $'Saved odometer - 10,024.125 mi\n201' ] \
  || fail "overlapping odometer fixture was not saved: $overlap_odometer"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q '41.25 kWh' <<<"$view" || fail "saved delivered energy did not render"
grep -q '21%' <<<"$view" || fail "saved start battery did not render"
grep -q '79.5%' <<<"$view" || fail "saved end battery did not render"
grep -q 'charger / reported' <<<"$view" || fail "charging measurement source did not render"
grep -q 'Unavailable - latest observation times overlap' <<<"$view" \
  || fail "overlapping latest observations did not render unavailable with a reason"
if grep -Eq '(^|[^0-9,.])(4125|10023125)([^0-9,.]|$)|0x[0-9a-fA-F]+' <<<"$view"; then
  fail "charge/odometer view leaked a raw machine value or ID"
fi
note "charge and standalone odometer save through Obelisk and render source-native evidence"

custom_suffix="$(date +%s%N)"
number_field="Number-$custom_suffix"
text_field="Text-$custom_suffix"
boolean_field="Boolean-$custom_suffix"

create_custom_field() {
  local label="$1" content_type="$2" mandatory="$3" result
  result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf \
      '{"label":"%s","contentType":"%s","mandatory":"%s"}' \
      "$label" "$content_type" "$mandatory")" \
    "$URL/apps/rover/add-custom-field")"
  [ "$result" = $'Created custom field\n201' ] \
    || fail "creating $content_type custom field failed: $result"
}

create_custom_field "$number_field" number yes
create_custom_field "$text_field" text no
create_custom_field "$boolean_field" boolean no

custom_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
for field in "$number_field" "$text_field" "$boolean_field"; do
  grep -q "$field" <<<"$custom_view" \
    || fail "custom field does not render in Settings and Add Fill: $field"
done

missing_mandatory_payload="$(
  printf '{"vehicle":"Structure Vehicle","definition":"Structure Gasoline","quantity":"4.000","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-31T10:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"Structure 91 AKI","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","custom-%s":""}' \
    "$number_field"
)"
missing_mandatory="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$missing_mandatory_payload" \
  "$URL/apps/rover/add-fill")"
[ "$missing_mandatory" = "%mandatory-or-invalid: custom-field.$number_field"$'\n422' ] \
  || fail "empty mandatory custom field did not block save: $missing_mandatory"

typed_custom_payload="$(
  printf '{"vehicle":"Structure Vehicle","definition":"Structure Gasoline","quantity":"4.000","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-31T10:01","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"Structure 91 AKI","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","custom-%s":"12.345","custom-%s":"hello","custom-%s":"yes"}' \
    "$number_field" "$text_field" "$boolean_field"
)"
typed_custom_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$typed_custom_payload" \
  "$URL/apps/rover/add-fill")"
[ "$typed_custom_fill" = $'Saved fill - $3.499 - derived $14.00\n201' ] \
  || fail "typed custom values did not save: $typed_custom_fill"

custom_report="$(read_structure_report)"
grep -q "\\[%custom-field 116 '$number_field'\\].*\\[%digits 25717 12345\\].*\\[%decimals 25717 3\\].*\\[%value-unit %tas %unitless\\]" \
  <<<"$custom_report" || fail "number custom value did not land in its typed relation"
grep -q "\\[%custom-field 116 '$text_field'\\].*\\[%value 116 %hello\\]" \
  <<<"$custom_report" || fail "text custom value did not land in its typed relation"
grep -q "\\[%custom-field 116 '$boolean_field'\\].*\\[%value 102 0\\]" \
  <<<"$custom_report" || fail "boolean custom value did not land in its typed relation"

change_custom_type="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf \
    '{"label":"%s","contentType":"number","mandatory":"no"}' \
    "$text_field")" \
  "$URL/apps/rover/change-custom-field-type")"
[ "$change_custom_type" = $'%immutable: custom-field.content-type - archive and recreate\n409' ] \
  || fail "valued custom field content type was not immutable: $change_custom_type"

for field in "$number_field" "$text_field" "$boolean_field"; do
  archived="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"label":"%s"}' "$field")" \
    "$URL/apps/rover/archive-custom-field")"
  [ "$archived" = $'Archived custom field\n201' ] \
    || fail "archiving custom field failed: $archived"
done
note "fixture 25 PASS - live HTTP and Obelisk report prove typed values, mandatory validation, and immutable used type"

asset_check() {
  local path="$1" content_type="$2" source="$3"
  : > "$HDRS"
  curl -s -b "$JAR" -D "$HDRS" -o "$ASSET" "$URL$path"
  grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "asset $path not 200"
  grep -qi "^content-type: $content_type" "$HDRS" \
    || fail "asset $path content-type is not $content_type"
  if ! cmp -s "$ASSET" "$source"; then
    echo "served: $(wc -c < "$ASSET") bytes $(sha256sum "$ASSET" | awk '{print $1}')" >&2
    echo "source: $(wc -c < "$source") bytes $(sha256sum "$source" | awk '{print $1}')" >&2
    fail "asset $path differs from desk source"
  fi
}

asset_check /apps/rover/assets/tile.png image/png \
  "$REPO/desk/app/rover/assets/tile.png"
tile_sha="$(sha256sum "$REPO/desk/app/rover/assets/tile.png" | awk '{print $1}')"
[ "$tile_sha" = '26ad34c372e85691ff2953299fa3b6e27afe43f266eec87158be6b83c0f37a30' ] ||
  fail "fixture 88 desk tile is not the supplied new image: $tile_sha"
for face in Regular Bold; do
  asset_check "/apps/rover/assets/fonts/JetBrainsMono-$face.woff2" font/woff2 \
    "$REPO/desk/app/rover/assets/fonts/JetBrainsMono-$face.woff2"
done
note "tile and both JetBrains Mono faces have exact bytes and content-types"

install_result="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-install !>([%rover our.bowl %rover]))
(pure:m !>(%installed))')"
case "$install_result" in
  *%installed*) ;;
  *) fail "docket install did not acknowledge: $install_result" ;;
esac
sleep 1
charge="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
=/  charges  .^(* %gx /(scot %p our.bowl)/docket/(scot %da now.bowl)/charges/noun)
(pure:m !>(charges))')"
case "$charge" in
  *"%rover"*"[%site %apps %rover 0]"*"'/apps/rover/assets/tile.png'"*)
note "PASS - docket charge is site /apps/rover with same-origin tile and no glob"
    ;;
  *) fail "Rover site/tile docket charge not found: $charge" ;;
esac
note "fixture 88 PASS - new PNG serves exact bytes as image/png and the docket charges its same-origin tile path"

type_suffix="$(date +%s%N)"
added_energy_type="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"Fixture Energy %s","physicalKind":"reservoir","quantityUnit":"gal"}' "$type_suffix")" \
  "$URL/apps/rover/add-energy-source-type")"
[ "$added_energy_type" = $'Created energy source type\n201' ] \
  || fail "fixture 81 add-energy-source control endpoint failed: $added_energy_type"
added_mode_type="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"Fixture Mode %s"}' "$type_suffix")" \
  "$URL/apps/rover/add-driving-mode-type")"
[ "$added_mode_type" = $'Created driving mode type\n201' ] \
  || fail "fixture 81 add-driving-mode control endpoint failed: $added_mode_type"
added_type_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q "name=\"energySources\" value=\"Fixture Energy $type_suffix\"" <<<"$added_type_view" \
  || fail "fixture 81 newly added energy source is absent from checkbox choices"
grep -q "name=\"drivingModes\" value=\"Fixture Mode $type_suffix\"" <<<"$added_type_view" \
  || fail "fixture 81 newly added driving mode is absent from checkbox choices"
note "fixture 81 PASS - add controls persist new source/mode types and expose them as checkbox choices"
if [ "${ROVER_FIXTURE_STOP:-}" = 83 ]; then
  exit 0
fi

default_archive_refusal="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Mode Scope Vehicle"}' \
  "$URL/apps/rover/set-default-vehicle")"
[ "$default_archive_refusal" = $'Saved default vehicle\n201' ] \
  || fail "fixture 80 could not designate its refusal subject: $default_archive_refusal"
default_archive_refusal="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Mode Scope Vehicle"}' \
  "$URL/apps/rover/remove-vehicle")"
[ "$default_archive_refusal" = $'%default-vehicle: choose a new default before archiving\n409' ] \
  || fail "fixture 80 app-default archive was not refused with a human reason: $default_archive_refusal"
fixture_80_new_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{\"vehicle\":\"%s\"}' "$settings_label_second")" \
  "$URL/apps/rover/set-default-vehicle")"
[ "$fixture_80_new_default" = $'Saved default vehicle\n201' ] \
  || fail "fixture 80 could not redesignate its always-seeded settings vehicle: $fixture_80_new_default"
archive_history_vehicle="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Preference Vehicle"}' \
  "$URL/apps/rover/remove-vehicle")"
[ "$archive_history_vehicle" = $'Archived vehicle\n201' ] \
  || fail "fixture 80 could not archive a non-default vehicle with history: $archive_history_vehicle"
archived_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
if grep -Eq '<option value="Preference Vehicle"[^>]*>' <<<"$archived_view"; then
  fail "fixture 80 archived vehicle remains in a default selector"
fi
grep -q '<summary>View archived vehicles</summary>.*data-vehicle="Preference Vehicle"' \
  <<<"$(tr '\n' ' ' <<<"$archived_view")" \
  || fail "fixture 80 archived vehicle is absent from the archived-vehicle view"
grep -q 'data-vehicle-settings-panel data-vehicle="Preference Vehicle".*ARCHIVED.*ORDERED HISTORY.*history-card fill' \
  <<<"$(tr '\n' ' ' <<<"$archived_view")" \
  || fail "fixture 80 archived vehicle history is not intact and viewable"
note "fixture 80 PASS - literal-Y archive hides selectors, preserves history, and refuses the app default until redesignation"

no_default_result="$(
  obelisk_mutate rover \
    "DELETE FROM app-default-vehicle WHERE scope = %app"
)"
if grep -q '%error' <<<"$no_default_result"; then
  fail "fixture 85 could not clear the disposable app default: $no_default_result"
fi
running_ship="$(
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
(pure:m !>((scot %p our)))' |
    grep -oE '~[a-z]+(-[a-z]+)*' | tail -1
)"
[ -n "$running_ship" ] ||
  fail "fixture 84 could not read the running ship from the real pier"
auth_cookie_name="$(awk 'index($6, "urbauth") == 1 {print $6}' "$JAR" | tail -1)"
auth_cookie="$(awk 'index($6, "urbauth") == 1 {print $7}' "$JAR" | tail -1)"
[ -n "$auth_cookie_name" ] ||
  fail "fixture 84 could not read the real Eyre authentication cookie name"
[ -n "$auth_cookie" ] ||
  fail "fixture 84 could not read the real Eyre authentication cookie"
playwright_module="${ROVER_PLAYWRIGHT_MODULE:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules/playwright}"
chromium_binary="${ROVER_CHROMIUM:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
[ -f "$playwright_module/package.json" ] ||
  fail "fixture 84 Playwright module is unavailable at $playwright_module"
[ -x "$chromium_binary" ] ||
  fail "fixture 84 Chromium is unavailable at $chromium_binary"
header_browser="$(
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/ui-browser-fixtures.cjs" \
      header-scenarios "$URL" "$auth_cookie_name" "$auth_cookie" "$running_ship" \
      'Mode Scope Vehicle' "$settings_label_second"
)" ||
  fail "fixtures 84-86 live browser header assertions failed: $header_browser"
grep -q '^HEADER_FIRST=' <<<"$header_browser" ||
  fail "fixture 84 live browser did not report its rendered header: $header_browser"
note "fixture 84 PASS - rendered header contains the running ship and current default vehicle, with no decorative placeholders"
grep -q '^HEADER_NONE=.*NO DEFAULT VEHICLE' <<<"$header_browser" ||
  fail "fixture 85 live browser did not report an explicit no-default slot: $header_browser"
note "fixture 85 PASS - rendered header states NO DEFAULT VEHICLE when the singleton row is absent"
settings_label_upper="$(printf '%s' "$settings_label_second" | tr '[:lower:]' '[:upper:]')"
grep -Fq "HEADER_SECOND=ROVER · VEHICLE LOG · ${running_ship^^} · $settings_label_upper" <<<"$header_browser" ||
  fail "fixture 86 live browser did not report the changed default: $header_browser"
note "fixture 86 PASS - changing the app default refreshes the rendered header vehicle label"
grep -q '^GLOW=' <<<"$header_browser" ||
  fail "fixture 87 live browser did not report the persisted maximum glow: $header_browser"
note "fixture 87 PASS - bounded glow slider disables with the toggle, persists across reload, and drives a materially stronger CSS shadow"

browser_charge_vehicle="Browser Charge Cost Vehicle $(date +%s%N)"
browser_charge_created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Electricity"}' "$browser_charge_vehicle")" \
  "$URL/apps/rover/add-vehicle")"
[ "$browser_charge_created" = "Added vehicle - $browser_charge_vehicle"$'\n201' ] \
  || fail "fixture 109 setup vehicle failed: $browser_charge_created"
browser_charge_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s"}' "$browser_charge_vehicle")" \
  "$URL/apps/rover/set-default-vehicle")"
grep -q '201$' <<<"$browser_charge_default" \
  || fail "fixture 109 could not make the charging vehicle the app default: $browser_charge_default"
charge_browser="$(
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/ui-browser-fixtures.cjs" \
      charge-cost "$URL" "$auth_cookie_name" "$auth_cookie" "$running_ship" \
      "$browser_charge_vehicle" "$browser_charge_vehicle"
)" ||
  fail "fixture 109 live browser itemized charge entry failed: $charge_browser"
grep -q '^CHARGE_PREVIEW=\$17.420$' <<<"$charge_browser" \
  || fail "fixture 109 browser preview did not derive the itemized total: $charge_browser"
grep -q '^CHARGE_VERDICT=Saved charge - Energy delivered not recorded - itemized total \$17.420$' <<<"$charge_browser" \
  || fail "fixture 109 browser submission did not save the itemized charge: $charge_browser"
browser_charge_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
browser_charge_card="$(charge_card_for "$browser_charge_vehicle" itemized <<<"$browser_charge_view")" \
  || fail "fixture 109 browser-entered charge is absent from the view"
grep -q 'data-itemized-total="\$17.420"' <<<"$browser_charge_card" \
  || fail "fixture 109 browser-entered charge did not persist its derived total: $browser_charge_card"
[ "$(grep -o 'data-cost-component=' <<<"$browser_charge_card" | wc -l)" = 6 ] \
  || fail "fixture 109 browser-entered charge did not persist six component rows: $browser_charge_card"
note "fixture 109 PASS - a real browser fills repeatable itemized component rows, previews the exact derived total, and saves it through Eyre"
curl -s -b "$JAR" -o /dev/null \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s"}' "$settings_label_second")" \
  "$URL/apps/rover/set-default-vehicle"

settings_layout_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
settings_layout_report="$(
  python3 -c 'import re, sys
document = sys.stdin.read()
vehicle = sys.argv[1]
marker = f"data-vehicle-settings-panel data-vehicle=\"{vehicle}\""
at = document.find(marker)
start = document.rfind("<article", 0, at)
end = document.find("<article", at + len(marker))
panel = document[start:] if end < 0 else document[start:end]
fuel = re.search(r"<fieldset[^>]*data-settings-group=\"fuel-system\".*?</fieldset>", panel, re.S)
energy = re.search(r"<fieldset[^>]*data-settings-group=\"energy-sources\".*?</fieldset>", panel, re.S)
driving = re.search(r"<fieldset[^>]*data-settings-group=\"driving-modes\".*?</fieldset>", panel, re.S)
def_group = re.search(r"<fieldset[^>]*data-settings-group=\"def\".*?</fieldset>", panel, re.S)
fuel_text = fuel.group(0) if fuel else ""
energy_text = energy.group(0) if energy else ""
print("DEFDEF=" + ("yes" if "DEFDEF" in document else "no"))
print("DEF_SEPARATE=" + ("yes" if (
    "data-def-toggle-row" in panel and
    "data-def-tank-row" in panel and
    panel.find("data-def-toggle-row") < panel.find("data-def-tank-row")
) else "no"))
print("ENERGY_DEFAULT=" + ("yes" if (
    energy and
    energy_text.find("data-add-energy-source") >= 0 and
    energy_text.find("name=\"defaultEnergy\"") > energy_text.find("data-add-energy-source")
) else "no"))
print("FUEL_FIELDS=" + ("yes" if (
    fuel and
    all(name in fuel_text for name in (
        "name=\"defaultSubtype\"", "name=\"tankSize\"", "name=\"tankUnit\"",
        "name=\"refillReserve\""
    ))
) else "no"))
positions = [
    panel.find("data-settings-group=\"fuel-system\""),
    panel.find("data-settings-group=\"energy-sources\""),
    panel.find("data-settings-group=\"driving-modes\""),
    panel.find("data-settings-group=\"def\""),
]
print("ORDER=" + ("yes" if all(value >= 0 for value in positions) and positions == sorted(positions) else "no"))
print("GROUPS=" + ("yes" if all((fuel, energy, driving, def_group)) else "no"))' \
    "$settings_label_second" \
    <<<"$settings_layout_view"
)"
grep -q '^DEFDEF=no$' <<<"$settings_layout_report" ||
  fail "fixture 89 served HTML contains DEFDEF: $settings_layout_report"
grep -q '^DEF_SEPARATE=yes$' <<<"$settings_layout_report" ||
  fail "fixture 89 DEF enablement and tank size are not separate labelled rows: $settings_layout_report"
note "fixture 89 PASS - Enable DEF and DEF tank size are separate labelled controls and DEFDEF is absent"

grep -q '^ENERGY_DEFAULT=yes$' <<<"$settings_layout_report" ||
  fail "fixture 90 default energy source is not inside Energy Sources after its add button: $settings_layout_report"
forged_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{\"vehicle\":\"%s\",\"label\":\"%s\",\"tankSize\":\"30\",\"tankUnit\":\"gal\",\"defaultSubtype\":\"93\",\"defaultEnergy\":\"Electricity\",\"energySources\":[\"Gasoline\",\"Diesel\"],\"drivingModes\":[],\"defEnabled\":\"yes\",\"defTankSize\":\"5\",\"defTankUnit\":\"gal\"}' "$settings_label_second" "$settings_label_second")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$forged_default" = $'%not-allowed: vehicle.default-energy-source\n422' ] ||
  fail "fixture 90 forged disallowed default reached the database path: $forged_default"
note "fixture 90 PASS - default energy is inside its source group and Rover rejects a forged disallowed default before writing"

grep -q '^GROUPS=yes$' <<<"$settings_layout_report" ||
  fail "fixture 91 one or more vehicle settings groups are absent: $settings_layout_report"
grep -q '^FUEL_FIELDS=yes$' <<<"$settings_layout_report" ||
  fail "fixture 91 Fuel System does not contain subtype, size, units, and refill reserve: $settings_layout_report"
grep -q '^ORDER=yes$' <<<"$settings_layout_report" ||
  fail "fixture 91 vehicle settings group order is wrong: $settings_layout_report"
note "fixture 91 PASS - Fuel System contains subtype, tank size, units, and refill reserve and precedes Energy Sources, Driving Modes, and DEF"

grep -q '^LAYOUT=' <<<"$header_browser" ||
  fail "fixture 92 live browser did not report its 390px settings measurement: $header_browser"
note "fixture 92 PASS - at 390px the reorganised settings has no horizontal overflow and every enabled touch target is at least 44px"

# --- M1-IMPORT-GUI - the browser import surface ------------------------------
# The endpoint takes one document per POST, so the browser splits the document
# the way tools/rover-import/upload.py does and posts one batch at a time. These
# fixtures drive that surface through a real browser against the real endpoint.
IMPORT_SOURCE="$REPO/tests/fixtures/rover-import-synthetic.json"
[ -f "$IMPORT_SOURCE" ] || fail "fixture 110 the synthetic import document is absent"

import_provenance_count() {
  rover_report "FROM acquisition-imports I WHERE I.source-app = %synthetic SELECT I.acquisition-id;" |
    grep -o '\[%acquisition-id ' | wc -l | tr -d ' '
}

import_browser() {
  local browser_mode="$1" document="$2" size="$3"
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/ui-browser-fixtures.cjs" \
      "$browser_mode" "$URL" "$auth_cookie_name" "$auth_cookie" "$running_ship" \
      '' '' "$document" "$size"
}

import_result_field() {
  python3 -c 'import json, sys
result = json.loads(sys.stdin.read())
print(result[sys.argv[1]])' "$1"
}

import_line() {
  sed -n "s/^$1=//p" <<<"$2"
}

import_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
import_screen_html="$(html_slice '<section id="import-screen"' '<section id=' <<<"$import_view")"
import_settings_html="$(html_slice '<section id="settings-screen"' '<section id="import-screen"' <<<"$import_view")"
[ -n "$import_screen_html" ] || fail "fixture 110 the served view has no import screen"
grep -q 'class="entry-screen app-screen" hidden' <<<"$import_screen_html" ||
  fail "fixture 110 the import screen is not a hidden entry screen: $import_screen_html"
grep -q 'data-open-screen="import-screen"' <<<"$import_settings_html" ||
  fail "fixture 110 Settings does not open the import screen: $import_settings_html"
grep -q 'id="import-file"' <<<"$import_screen_html" ||
  fail "fixture 110 the import screen has no file input"
grep -q 'accept=".json,application/json"' <<<"$import_screen_html" ||
  fail "fixture 110 the file input does not accept .json"
grep -q 'id="import-validate"' <<<"$import_screen_html" ||
  fail "fixture 110 the import screen has no validate control"
grep -q 'id="import-submit"' <<<"$import_screen_html" ||
  fail "fixture 110 the import screen has no submit control"
grep -q 'id="import-batch-size"' <<<"$import_screen_html" ||
  fail "fixture 110 the import screen has no batch size control"
if grep -q 'IMPORT / EXPORT - COMING LATER' <<<"$import_view"; then
  fail "fixture 110 Settings still shows the import placeholder"
fi
note "fixture 110 PASS - Settings opens a hidden import entry screen carrying a .json file input, a batch size, a validate step, and a submit control"

# The parity check uses the whole two-vehicle synthetic document, so it covers
# the cross-vehicle flatten that +batch_documents performs.
import_prepared="$(import_browser import-prepare "$IMPORT_SOURCE" 2)" ||
  fail "fixture 111 the browser could not prepare the document: $import_prepared"
[ "$(import_line IMPORT_POSTS "$import_prepared")" = 0 ] ||
  fail "fixture 111 preparing a document posted to the endpoint: $import_prepared"
python3 -c 'import importlib.util, json, sys
repository, document_path = sys.argv[1:3]
spec = importlib.util.spec_from_file_location(
    "rover_upload", f"{repository}/tools/rover-import/upload.py"
)
upload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(upload)
prepared = json.loads(sys.stdin.read())
if not prepared["ok"]:
    raise SystemExit("browser refused the document: " + prepared["verdict"])
document = upload.load_document(document_path)
expected = list(upload.batch_documents(document, 2))
if prepared["batches"] != expected:
    raise SystemExit("browser batches differ from upload.py batches")
if prepared["fills"] != upload.fill_count(document):
    raise SystemExit("browser fill count differs from upload.py fill count")' \
  "$REPO" "$IMPORT_SOURCE" <<<"$(import_line IMPORT_PREPARED "$import_prepared")" ||
  fail "fixture 111 browser batching does not match tools/rover-import/upload.py"
note "fixture 111 PASS - the browser batch split equals the one tools/rover-import/upload.py builds for the same document and batch size"

# Two vehicles, six fills, three batches. Both vehicles are created by batch 1,
# and both carry fills in a batch that did not create them, so every batch after
# the first has to widen a vehicle it did not build.
import_before="$(import_provenance_count)"
[ "$import_before" = 0 ] ||
  fail "fixture 112 the disposable database already holds $import_before synthetic import records"
import_upload="$(import_browser import-upload "$IMPORT_SOURCE" 2)" ||
  fail "fixture 112 the live browser import failed: $import_upload"
import_result="$(import_line IMPORT_RESULT "$import_upload")"
[ -n "$import_result" ] ||
  fail "fixture 112 the browser reported no import result: $import_upload"
[ "$(import_result_field outcome <<<"$import_result")" = success ] ||
  fail "fixture 112 the browser import did not succeed: $import_result"
[ "$(import_line IMPORT_POSTS "$import_upload")" = 3 ] ||
  fail "fixture 112 the browser did not post exactly three batches: $import_upload"
[ "$(import_line IMPORT_VALIDATED "$import_upload")" = '"6 fills in 3 batches"' ] ||
  fail "fixture 112 the validate step did not plan three batches: $import_upload"
[ "$(import_result_field progress <<<"$import_result")" = \
  'Batch 3 of 3 - imported 6, already-imported 0, conflicts 0, failures 0' ] ||
  fail "fixture 112 the running tally is wrong: $import_result"
import_reports_sum="$(
  python3 -c 'import json, re, sys
result = json.loads(sys.stdin.read())
reports = result["reports"]
imported = already = conflicts = failures = 0
for report in reports:
    match = re.search(
        r"Fills: imported (\d+), already-imported (\d+), conflicts (\d+), failures (\d+)",
        report,
    )
    if match is None:
        raise SystemExit("batch report has no fill line: " + report)
    values = [int(value) for value in match.groups()]
    imported += values[0]
    already += values[1]
    conflicts += values[2]
    failures += values[3]
print(len(reports), imported, already, conflicts, failures)' <<<"$import_result"
)"
[ "$import_reports_sum" = "3 6 0 0 0" ] ||
  fail "fixture 112 the per-batch reports do not account for six imported fills: $import_reports_sum"
import_after="$(import_provenance_count)"
[ "$import_after" = 6 ] ||
  fail "fixture 112 the database holds $import_after synthetic import records, want 6"
note "fixture 112 PASS - a real browser split a two-vehicle six-fill document into three batches, posted them one at a time, and every record landed although both vehicles span batches"

python3 -c 'import importlib.util, json, sys
repository = sys.argv[1]
spec = importlib.util.spec_from_file_location(
    "rover_upload", f"{repository}/tools/rover-import/upload.py"
)
upload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(upload)
result = json.loads(sys.stdin.read())
rendered = result["aggregate"].strip()
expected = upload.render_aggregate(upload.aggregate_reports(result["reports"])).strip()
if rendered != expected:
    raise SystemExit(
        "browser aggregate\n" + rendered + "\ndiffers from\n" + expected
    )' "$REPO" <<<"$import_result" ||
  fail "fixture 113 the rendered aggregate is not the sum of the per-batch reports"
note "fixture 113 PASS - the aggregate the browser renders equals the sum of its per-batch reports, line for line with the one upload.py prints"

import_again="$(import_browser import-upload "$IMPORT_SOURCE" 2)" ||
  fail "fixture 114 the second live browser import failed: $import_again"
import_again_result="$(import_line IMPORT_RESULT "$import_again")"
[ "$(import_result_field outcome <<<"$import_again_result")" = success ] ||
  fail "fixture 114 the re-import did not succeed: $import_again_result"
import_again_aggregate="$(import_result_field aggregate <<<"$import_again_result")"
grep -q 'Fills: imported 0, already-imported 6, conflicts 0, failures 0' \
  <<<"$import_again_aggregate" ||
  fail "fixture 114 the re-import was not an already-imported no-op: $import_again_aggregate"
import_again_count="$(import_provenance_count)"
[ "$import_again_count" = 6 ] ||
  fail "fixture 114 the re-import changed the provenance row count to $import_again_count"
note "fixture 114 PASS - re-uploading the same document reported already-imported 6 and wrote nothing"

python3 -c 'import json, sys
source, vehicles_path, version_path, fills_path = sys.argv[1:5]
with open(source, encoding="utf-8") as handle:
    document = json.load(handle)
broken = json.loads(json.dumps(document))
broken["vehicles"] = {"label": "not a list"}
with open(vehicles_path, "w", encoding="utf-8") as handle:
    json.dump(broken, handle, separators=(",", ":"), sort_keys=True)
broken = json.loads(json.dumps(document))
broken["rover-import"] = 2
with open(version_path, "w", encoding="utf-8") as handle:
    json.dump(broken, handle, separators=(",", ":"), sort_keys=True)
broken = json.loads(json.dumps(document))
del broken["vehicles"][0]["fills"]
with open(fills_path, "w", encoding="utf-8") as handle:
    json.dump(broken, handle, separators=(",", ":"), sort_keys=True)' \
  "$IMPORT_SOURCE" "$IMPORT_VEHICLES" "$IMPORT_VERSION" "$IMPORT_FILLS" ||
  fail "fixture 115 could not build the malformed documents"
import_refused="$(import_browser import-upload "$IMPORT_VEHICLES" 2)" ||
  fail "fixture 115 the browser refusal run failed: $import_refused"
import_refused_result="$(import_line IMPORT_RESULT "$import_refused")"
[ "$(import_result_field outcome <<<"$import_refused_result")" = refused ] ||
  fail "fixture 115 the browser did not refuse a non-list vehicles key: $import_refused_result"
[ "$(import_result_field message <<<"$import_refused_result")" = '%bad-shape: import.vehicles' ] ||
  fail "fixture 115 the refusal verdict is not in the Rover vocabulary: $import_refused_result"
[ "$(import_line IMPORT_POSTS "$import_refused")" = 0 ] ||
  fail "fixture 115 the browser posted a document it had already refused: $import_refused"
for import_case in "$IMPORT_VERSION:%bad-shape: import.rover-import" \
                   "$IMPORT_FILLS:%bad-shape: import.vehicle.fills"; do
  import_bad_path="${import_case%%:*}"
  import_bad_verdict="${import_case#*:}"
  import_bad="$(import_browser import-prepare "$import_bad_path" 2)" ||
    fail "fixture 115 the browser could not read $import_bad_path: $import_bad"
  [ "$(import_line IMPORT_POSTS "$import_bad")" = 0 ] ||
    fail "fixture 115 reading a malformed document posted to the endpoint: $import_bad"
  python3 -c 'import json, sys
prepared = json.loads(sys.stdin.read())
wanted = sys.argv[1]
if prepared["ok"] or not prepared["verdict"].startswith(wanted):
    raise SystemExit("want a refusal starting " + wanted + ", got " + repr(prepared))' \
    "$import_bad_verdict" <<<"$(import_line IMPORT_PREPARED "$import_bad")" ||
    fail "fixture 115 a malformed document was not refused with its Rover verdict"
done
import_refused_count="$(import_provenance_count)"
[ "$import_refused_count" = 6 ] ||
  fail "fixture 115 a refused document changed the provenance row count to $import_refused_count"
note "fixture 115 PASS - the browser refuses a bad version, a non-list vehicles key, and a vehicle without fills, and posts nothing"

# The desk validates every document again with +decode-import. A document the
# browser shape check passes and the desk refuses proves that a refused batch
# stops the run where it stands, instead of sending the batches behind it.
python3 -c 'import json, sys
source, target = sys.argv[1:3]
with open(source, encoding="utf-8") as handle:
    document = json.load(handle)
del document["vehicles"][0]["distanceUnit"]
with open(target, "w", encoding="utf-8") as handle:
    json.dump(document, handle, separators=(",", ":"), sort_keys=True)' \
  "$IMPORT_SOURCE" "$IMPORT_REFUSED" ||
  fail "fixture 116 could not build the desk-refused document"
import_stopped="$(import_browser import-upload "$IMPORT_REFUSED" 2)" ||
  fail "fixture 116 the live browser run failed: $import_stopped"
import_stopped_result="$(import_line IMPORT_RESULT "$import_stopped")"
[ "$(import_result_field outcome <<<"$import_stopped_result")" = stopped ] ||
  fail "fixture 116 the browser did not stop on the desk refusal: $import_stopped_result"
import_stopped_message="$(import_result_field message <<<"$import_stopped_result")"
grep -q 'Import stopped at batch 1 of 3' <<<"$import_stopped_message" ||
  fail "fixture 116 the browser did not name the batch it stopped at: $import_stopped_message"
grep -q '%missing-key: import.vehicle.distanceUnit' <<<"$import_stopped_message" ||
  fail "fixture 116 the browser did not repeat the desk verdict: $import_stopped_message"
[ "$(import_line IMPORT_POSTS "$import_stopped")" = 1 ] ||
  fail "fixture 116 the browser sent batches behind a refused one: $import_stopped"
import_stopped_count="$(import_provenance_count)"
[ "$import_stopped_count" = 6 ] ||
  fail "fixture 116 a refused batch changed the provenance row count to $import_stopped_count"
note "fixture 116 PASS - a batch the desk refuses stops the browser where it stands, names the batch and the desk verdict, and holds back every batch behind it"

# This import creates the page boundary that the small fixtures did not test.
# The newer vehicle fills page 1. The older vehicle has three fills.
python3 -c 'import copy, json, sys
source, target = sys.argv[1:3]
with open(source, encoding="utf-8") as handle:
    base = json.load(handle)

def scoped_fill(template, vehicle, definition, subtype, observed, mileage, source_id):
    row = copy.deepcopy(template)
    for key in list(row):
        if key.startswith("new"):
            del row[key]
    for key in ("averageSpeed", "speedUnit", "driveBalance", "notes", "paymentMethod"):
        row.pop(key, None)
    row.update({
        "vehicle": vehicle,
        "definition": definition,
        "quantity": "10.000",
        "price": "3.000",
        "profile": "us-usd-gal",
        "tank": "full",
        "settlement": "standard",
        "observed": observed,
        "zone": "America/Chicago",
        "mileage": mileage,
        "mileageUnit": "mi",
        "station": "none",
        "additives": [],
        "subtype": subtype,
        "missedFill": "no",
        "tags": [],
        "sourceApp": "statscope",
        "sourceRecordId": source_id,
        "sourceTotal": "30.00",
    })
    return row

many_label = "Statscope Many Gasoline"
few_label = "Statscope Few Diesel"
gas_template = base["vehicles"][0]["fills"][2]
diesel_template = base["vehicles"][1]["fills"][2]
many_fills = [
    scoped_fill(
        gas_template,
        many_label,
        "Gasoline",
        "Synthetic 87 AKI",
        f"2026-04-{number:02d}T08:00",
        f"{1000 + number * 100}.0",
        f"many-{number:02d}",
    )
    for number in range(1, 31)
]
few_fills = [
    scoped_fill(
        diesel_template,
        few_label,
        "Diesel",
        "Synthetic ULSD 45",
        f"2025-05-{number:02d}T09:00",
        f"{5000 + number * 100}.0",
        f"few-{number:02d}",
    )
    for number in range(1, 4)
]
document = {
    "rover-import": 1,
    "source": {"app": "statscope"},
    "definitions": copy.deepcopy(base["definitions"]),
    "places": [],
    "vehicles": [
        {
            "label": many_label,
            "distanceUnit": "mi",
            "volumeUnit": "gal",
            "tankSize": {"value": "20.000", "unit": "gal"},
            "defaultEnergy": "Gasoline",
            "fills": many_fills,
        },
        {
            "label": few_label,
            "distanceUnit": "mi",
            "volumeUnit": "gal",
            "tankSize": {"value": "25.000", "unit": "gal"},
            "defaultEnergy": "Diesel",
            "fills": few_fills,
        },
    ],
}
with open(target, "w", encoding="utf-8") as handle:
    json.dump(document, handle, separators=(",", ":"), sort_keys=True)' \
  "$IMPORT_SOURCE" "$IMPORT_STATSCOPE" \
  || fail "fixture 117 could not build the skew import document"
statscope_import="$(import_browser import-upload "$IMPORT_STATSCOPE" 40)" \
  || fail "fixture 117 the skew browser import failed: $statscope_import"
statscope_result="$(import_line IMPORT_RESULT "$statscope_import")"
[ "$(import_result_field outcome <<<"$statscope_result")" = success ] \
  || fail "fixture 117 the skew import did not succeed: $statscope_result"
[ "$(import_line IMPORT_POSTS "$statscope_import")" = 1 ] \
  || fail "fixture 117 the browser did not send one skew import batch: $statscope_import"
grep -q 'Fills: imported 33, already-imported 0, conflicts 0, failures 0' \
  <<<"$(import_result_field aggregate <<<"$statscope_result")" \
  || fail "fixture 117 the skew import did not add 30 and 3 fills: $statscope_result"
note "fixture 117 PASS - the real import endpoint added a 30-fill vehicle and a 3-fill vehicle"

scope_census() {
  local document="$1" vehicle="$2" history_count="$3" statistics_count="$4"
  local first_date="$5" last_date="$6" subtype="$7" page_text="$8"
  python3 -c 'import html, re, sys
vehicle, history_want, statistics_want, first_date, last_date, subtype, page_text = sys.argv[1:8]
document = html.unescape(sys.stdin.read())
history = document.split("<section id=\"history-screen\"", 1)[1].split("</section>", 1)[0]
statistics = document.split("<section id=\"statistics-screen\"", 1)[1].split("<section id=\"settings-screen\"", 1)[0]
history_rows = re.findall(r"<article[^>]*data-history-vehicle=\"([^\"]+)\"", history)
statistics_rows = re.findall(r"<tr[^>]*data-statistics-vehicle=\"([^\"]+)\"", statistics)
if len(history_rows) != int(history_want):
    raise SystemExit(f"history rows {len(history_rows)}, want {history_want}: {history_rows}")
if len(statistics_rows) != int(statistics_want):
    raise SystemExit(f"statistics rows {len(statistics_rows)}, want {statistics_want}: {statistics_rows}")
if set(history_rows) != {vehicle}:
    raise SystemExit(f"history row vehicles {sorted(set(history_rows))}, want only {vehicle}")
if set(statistics_rows) != {vehicle}:
    raise SystemExit(f"statistics row vehicles {sorted(set(statistics_rows))}, want only {vehicle}")
for expected in (first_date, last_date, subtype, page_text):
    if expected not in history + statistics:
        raise SystemExit(f"scoped markup lacks {expected!r}")
print(f"history={len(history_rows)} statistics={len(statistics_rows)} vehicles={sorted(set(history_rows + statistics_rows))}")' \
    "$vehicle" "$history_count" "$statistics_count" "$first_date" "$last_date" \
    "$subtype" "$page_text" <<<"$document"
}

few_response="$(scoped_view 0 'Statscope Few Diesel')"
[ "$(scoped_view_status "$few_response")" = 200 ] \
  || fail "fixture 118 few-fill scope returned $(scoped_view_status "$few_response"): $few_response"
few_html="$(scoped_view_html "$few_response")"
few_census="$(scope_census "$few_html" 'Statscope Few Diesel' 3 16 \
  '2025-05-01' '2025-05-03' 'Synthetic ULSD 45' 'Showing 1-3 of 3')" \
  || fail "fixture 118 few-fill scope is not isolated: $few_census"
grep -q 'Unavailable' <<<"$few_html" \
  || fail "fixture 118 few-fill scope hides its unavailable interval result"
grep -q 'An eligible adjacent full-fill interval is required.' <<<"$few_html" \
  || fail "fixture 118 few-fill scope weakens the eligible-interval refusal"
note "statscope few-fill census - $few_census"
note "fixture 118 PASS - the selected 3-fill diesel vehicle keeps its honest interval refusal"

many_response="$(scoped_view 0 'Statscope Many Gasoline')"
[ "$(scoped_view_status "$many_response")" = 200 ] \
  || fail "fixture 119 many-fill scope returned $(scoped_view_status "$many_response"): $many_response"
many_html="$(scoped_view_html "$many_response")"
many_census="$(scope_census "$many_html" 'Statscope Many Gasoline' 25 126 \
  '2026-04-06' '2026-04-30' 'Synthetic 87 AKI' 'Showing 1-25 of 30')" \
  || fail "fixture 119 many-fill page 1 is not isolated: $many_census"
note "statscope many-fill page 1 census - $many_census"
note "fixture 119 PASS - History and Statistics page inside the selected 30-fill vehicle"

many_page_2_response="$(scoped_view 1 'Statscope Many Gasoline')"
[ "$(scoped_view_status "$many_page_2_response")" = 200 ] \
  || fail "fixture 120 many-fill page 2 returned $(scoped_view_status "$many_page_2_response"): $many_page_2_response"
many_page_2_html="$(scoped_view_html "$many_page_2_response")"
many_page_2_census="$(scope_census "$many_page_2_html" 'Statscope Many Gasoline' 5 26 \
  '2026-04-01' '2026-04-05' 'Synthetic 87 AKI' 'Showing 26-30 of 30')" \
  || fail "fixture 120 many-fill page 2 is not isolated: $many_page_2_census"
note "statscope many-fill page 2 census - $many_page_2_census"
note "fixture 120 PASS - page 2 stays inside the selected vehicle and serves its last 5 fills"

for default_case in 'Statscope Many Gasoline:25:126:2026-04-06:2026-04-30:Synthetic 87 AKI:Showing 1-25 of 30' \
                    'Statscope Few Diesel:3:16:2025-05-01:2025-05-03:Synthetic ULSD 45:Showing 1-3 of 3'; do
  IFS=: read -r default_vehicle default_history default_statistics default_first \
    default_last default_subtype default_page <<<"$default_case"
  default_write="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{\"vehicle\":\"%s\"}' "$default_vehicle")" \
    "$URL/apps/rover/set-default-vehicle")"
  [ "$default_write" = $'Saved default vehicle\n201' ] \
    || fail "fixture 121 could not set $default_vehicle as the app default: $default_write"
  default_response="$(curl -s -b "$JAR" -w $'\nROVER_HTTP_STATUS=%{http_code}' "$URL/apps/rover/view")"
  [ "$(scoped_view_status "$default_response")" = 200 ] \
    || fail "fixture 121 GET for $default_vehicle returned $(scoped_view_status "$default_response")"
  default_html="$(scoped_view_html "$default_response")"
  default_census="$(scope_census "$default_html" "$default_vehicle" "$default_history" \
    "$default_statistics" "$default_first" "$default_last" "$default_subtype" "$default_page")" \
    || fail "fixture 121 GET did not use the app default $default_vehicle: $default_census"
  note "statscope GET status=200 census for $default_vehicle - $default_census"
  if [ "$default_vehicle" = 'Statscope Many Gasoline' ]; then
    bare_response="$(curl -s -b "$JAR" -w $'\nROVER_HTTP_STATUS=%{http_code}' \
      -H 'content-type: text/plain' --data-binary '0' "$URL/apps/rover/view")"
    [ "$(scoped_view_status "$bare_response")" = 200 ] \
      || fail "fixture 121 bare page POST returned $(scoped_view_status "$bare_response")"
    bare_census="$(scope_census "$(scoped_view_html "$bare_response")" "$default_vehicle" \
      "$default_history" "$default_statistics" "$default_first" "$default_last" \
      "$default_subtype" "$default_page")" \
      || fail "fixture 121 bare page POST lost the app default scope: $bare_census"
    note "statscope bare-page POST status=200 census - $bare_census"
  fi
done
note "fixture 121 PASS - GET serves both defaults and the old bare-page POST stays compatible"

bootstrap_counts_before="$(rover_row_counts)"
bootstrap_idempotent_view="$(curl -s -b "$JAR" -w $'\nROVER_HTTP_STATUS=%{http_code}' \
  "$URL/apps/rover/view")"
[ "$(scoped_view_status "$bootstrap_idempotent_view")" = 200 ] \
  || fail "fixture 123 populated view returned $(scoped_view_status "$bootstrap_idempotent_view"): $bootstrap_idempotent_view"
bootstrap_counts_after="$(rover_row_counts)"
[ "$bootstrap_counts_after" = "$bootstrap_counts_before" ] \
  || fail "fixture 123 view changed populated rows: before=$bootstrap_counts_before after=$bootstrap_counts_after"
note "bootstrap idempotence counts - before $bootstrap_counts_before after $bootstrap_counts_after"
note "fixture 123 PASS - a populated view does not re-pour, re-seed, or change fill and starter counts"
fi

statistics_cost_stamp="$(date +%s%N)"
statistics_cost_vehicle="Statistics Cost Vehicle $statistics_cost_stamp"
eyre_post add-vehicle \
  "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[]}' "$statistics_cost_vehicle")" \
  "$(printf 'Added vehicle - %s\n201' "$statistics_cost_vehicle")" \
  'fixture 134 cost vehicle'
eyre_post add-acquisition-event \
  "$(printf '{"vehicle":"%s","observed":"2026-01-01T09:00","zone":"America/Chicago","total":"$10,000.00","currency":"usd","mileage":"1000","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":[],"disposalKind":"","notes":"Statistics purchase %s"}' "$statistics_cost_vehicle" "$statistics_cost_stamp")" \
  $'Saved acquisition event - $10,000.00\n201' 'fixture 134 acquisition cost'
eyre_post add-fill \
  "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"10.000","price":"$2.99","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-01-10T09:00","zone":"America/Chicago","mileage":"1200","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' "$statistics_cost_vehicle")" \
  $'Saved fill - $2.999 - derived $29.99\n201' 'fixture 134 fuel cost'
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"2026-01-15T09:00","zone":"America/Chicago","total":"$900.00","currency":"usd","mileage":"1400","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"Brake service %s","subtypes":["Brakes, Front"]}' "$statistics_cost_vehicle" "$statistics_cost_stamp")" \
  $'Saved service event - $900.00\n201' 'fixture 134 service cost'
eyre_post add-expense-event \
  "$(printf '{"vehicle":"%s","observed":"2026-01-20T09:00","zone":"America/Chicago","total":"$100.00","currency":"usd","mileage":"1500","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"Registration %s","subtypes":[]}' "$statistics_cost_vehicle" "$statistics_cost_stamp")" \
  $'Saved expense event - $100.00\n201' 'fixture 134 expense cost'
eyre_post add-consumable \
  "$(printf '{"vehicle":"%s","consumable":"Washer Fluid","quantity":"2.000","price":"$4.00","profile":"us-usd-gal","settlement":"standard","observed":"2026-01-25T09:00","zone":"America/Chicago","mileage":"1600","mileageUnit":"mi"}' "$statistics_cost_vehicle")" \
  $'Saved consumable purchase - $8.02\n201' 'fixture 134 consumable cost'
eyre_post add-disposal-event \
  "$(printf '{"vehicle":"%s","observed":"2026-02-01T09:00","zone":"America/Chicago","total":"$5,000.00","currency":"usd","mileage":"2000","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":[],"disposalKind":"Sold","notes":"Statistics sale %s"}' "$statistics_cost_vehicle" "$statistics_cost_stamp")" \
  $'Saved disposal event - $5,000.00\n201' 'fixture 134 disposal credit'
statistics_cost_view="$(scoped_view_html "$(scoped_view 0 "$statistics_cost_vehicle")")"
grep -q 'data-statistic="total-cost-of-ownership"' <<<"$statistics_cost_view" \
  || fail "fixture 134 Statistics lacks total cost of ownership"
grep -q 'data-total-cost-mills="6038010"' <<<"$statistics_cost_view" \
  || fail "fixture 134 total cost is not the exact 6,038,010-mill sum"
for family_total in service:900000 expense:100000 fuel:29990 consumables:8020 acquisition:10000000 disposal:-5000000; do
  IFS=: read -r family total <<<"$family_total"
  grep -q "data-cost-family=\"$family\" data-family-total-mills=\"$total\"" <<<"$statistics_cost_view" \
    || fail "fixture 134 spend-by-family lacks $family at $total mills"
done
grep -q 'data-service-subtype="Brakes, Front" data-service-count="1" data-service-total-mills="900000"' <<<"$statistics_cost_view" \
  || fail "fixture 134 service summary does not count and total Brakes, Front exactly"
note "fixture 134 PASS - total cost is the exact mill sum of fuel, consumable, service, expense, acquisition, and disposal rows, and service subtype totals match"
if [ "${ROVER_FIXTURE_STOP:-}" = 134 ]; then
  exit 0
fi

statistics_cost_per_distance_before="$(sed -n 's/.*data-cost-per-distance-mills="\([0-9-]*\)".*/\1/p' <<<"$statistics_cost_view" | head -1)"
[ "$statistics_cost_per_distance_before" = 6038 ] \
  || fail "fixture 135 initial all-in cost per mile is $statistics_cost_per_distance_before, want 6038 mills"
grep -q 'data-cost-family="fuel" data-family-total-mills="29990"' <<<"$statistics_cost_view" \
  || fail "fixture 135 initial fuel total moved from 29,990 mills"
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"2026-01-28T09:00","zone":"America/Chicago","total":"$100.00","currency":"usd","mileage":"1700","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"Second brake service %s","subtypes":["Brakes, Front"]}' "$statistics_cost_vehicle" "$statistics_cost_stamp")" \
  $'Saved service event - $100.00\n201' 'fixture 135 added service cost'
statistics_cost_after_service="$(scoped_view_html "$(scoped_view 0 "$statistics_cost_vehicle")")"
grep -q 'data-total-cost-mills="6138010"' <<<"$statistics_cost_after_service" \
  || fail "fixture 135 service cost did not enter all-in total"
grep -q 'data-cost-family="fuel" data-family-total-mills="29990"' <<<"$statistics_cost_after_service" \
  || fail "fixture 135 fuel total changed when only service changed"
grep -q 'data-cost-per-distance-mills="6138"' <<<"$statistics_cost_after_service" \
  || fail "fixture 135 all-in cost per mile did not change from 6038 to 6138 mills"
note 'fixture 135 PASS - a service-only $100 change raises all-in cost from 6038 to 6138 mills per mile while fuel stays at 29990 mills'
if [ "${ROVER_FIXTURE_STOP:-}" = 135 ]; then
  exit 0
fi

statistics_gap_stamp="$(date +%s%N)"
statistics_gap_vehicle="Statistics Gap Vehicle $statistics_gap_stamp"
eyre_post add-vehicle \
  "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[]}' "$statistics_gap_vehicle")" \
  "$(printf 'Added vehicle - %s\n201' "$statistics_gap_vehicle")" \
  'fixture 136 gap vehicle'
eyre_post add-acquisition-event \
  "$(printf '{"vehicle":"%s","observed":"2026-03-01T09:00","zone":"America/Chicago","total":"$10,000.00","currency":"usd","mileage":"1000","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":[],"disposalKind":"","notes":"First purchase %s"}' "$statistics_gap_vehicle" "$statistics_gap_stamp")" \
  $'Saved acquisition event - $10,000.00\n201' 'fixture 136 first acquisition'
eyre_post add-service-event \
  "$(printf '{"vehicle":"%s","observed":"2026-03-10T09:00","zone":"America/Chicago","total":"$100.00","currency":"usd","mileage":"1100","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"First interval service %s","subtypes":["Brakes, Front"]}' "$statistics_gap_vehicle" "$statistics_gap_stamp")" \
  $'Saved service event - $100.00\n201' 'fixture 136 first interval service'
eyre_post add-disposal-event \
  "$(printf '{"vehicle":"%s","observed":"2026-03-20T09:00","zone":"America/Chicago","total":"$5,000.00","currency":"usd","mileage":"1200","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":[],"disposalKind":"Sold","notes":"First sale %s"}' "$statistics_gap_vehicle" "$statistics_gap_stamp")" \
  $'Saved disposal event - $5,000.00\n201' 'fixture 136 first disposal'
eyre_post add-acquisition-event \
  "$(printf '{"vehicle":"%s","observed":"2026-05-01T09:00","zone":"America/Chicago","total":"$8,000.00","currency":"usd","mileage":"1300","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","subtypes":[],"disposalKind":"","notes":"Second purchase %s"}' "$statistics_gap_vehicle" "$statistics_gap_stamp")" \
  $'Saved acquisition event - $8,000.00\n201' 'fixture 136 second acquisition'
eyre_post add-expense-event \
  "$(printf '{"vehicle":"%s","observed":"2026-05-10T09:00","zone":"America/Chicago","total":"$200.00","currency":"usd","mileage":"1400","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"Second interval expense %s","subtypes":[]}' "$statistics_gap_vehicle" "$statistics_gap_stamp")" \
  $'Saved expense event - $200.00\n201' 'fixture 136 second interval expense'
statistics_gap_view="$(scoped_view_html "$(scoped_view 0 "$statistics_gap_vehicle")")"
grep -q 'data-total-cost-unavailable="ownership-gap"' <<<"$statistics_gap_view" \
  || fail "fixture 136 lifetime total crosses the ownership gap"
grep -q 'The vehicle was not owned for part of this interval, so the derived value is unavailable.' <<<"$statistics_gap_view" \
  || fail "fixture 136 ownership-gap refusal lacks the ratified human reason"
for interval_values in '1:5100000:25500' '2:8200000:82000'; do
  IFS=: read -r interval interval_total interval_rate <<<"$interval_values"
  grep -q "data-ownership-interval=\"$interval\" data-interval-total-mills=\"$interval_total\" data-interval-cost-per-distance-mills=\"$interval_rate\"" <<<"$statistics_gap_view" \
    || fail "fixture 136 interval $interval does not retain exact total $interval_total and rate $interval_rate"
done
note "fixture 136 PASS - lifetime aggregates refuse the buy-sell-rebuy gap and the two intervals retain exact totals and all-in rates"
if [ "${ROVER_FIXTURE_STOP:-}" = 136 ]; then
  exit 0
fi

statistics_empty_stamp="$(date +%s%N)"
statistics_empty_vehicle="Statistics No Service $statistics_empty_stamp"
eyre_post add-vehicle \
  "$(printf '{"label":"%s","energy":"Gasoline","additionalEnergy":[]}' "$statistics_empty_vehicle")" \
  "$(printf 'Added vehicle - %s\n201' "$statistics_empty_vehicle")" \
  'fixture 137 no-service vehicle'
eyre_post add-expense-event \
  "$(printf '{"vehicle":"%s","observed":"2026-06-01T09:00","zone":"America/Chicago","total":"$50.00","currency":"usd","mileage":"1000","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","tags":[],"newTag":"","paymentMethod":"","notes":"Expense without service %s","subtypes":[]}' "$statistics_empty_vehicle" "$statistics_empty_stamp")" \
  $'Saved expense event - $50.00\n201' 'fixture 137 expense only'
statistics_empty_view="$(scoped_view_html "$(scoped_view 0 "$statistics_empty_vehicle")")"
statistics_service_empty="$(
  python3 -c 'import re, sys
document = sys.stdin.read()
match = re.search(r"<section class=\"stat-table\" data-statistic=\"service-history-summary\"[^>]*>.*?</section>", document, re.S)
print(match.group(0) if match else "")' <<<"$statistics_empty_view"
)"
statistics_spend_empty="$(
  python3 -c 'import re, sys
document = sys.stdin.read()
match = re.search(r"<section class=\"stat-table\" data-statistic=\"spend-by-family\"[^>]*>.*?</section>", document, re.S)
print(match.group(0) if match else "")' <<<"$statistics_empty_view"
)"
grep -q 'No service events recorded for this vehicle.' <<<"$statistics_service_empty" \
  || fail "fixture 137 no-service vehicle lacks an honest empty state"
if grep -q 'data-cost-family="service"\|\$0\.00' <<<"$statistics_service_empty"; then
  fail "fixture 137 no-service vehicle fabricates a zero service total"
fi
grep -q 'data-cost-family="service"' <<<"$statistics_spend_empty" \
  || fail "fixture 137 spend table omits the required Service family row"
grep -q 'No costs recorded' <<<"$statistics_spend_empty" \
  || fail "fixture 137 absent Service spend does not speak human"
if grep -q 'data-family-total-mills="0"\|\$0\.00' <<<"$statistics_spend_empty"; then
  fail "fixture 137 absent Service spend fabricates a zero total"
fi
note "fixture 137 PASS - a vehicle with no service events keeps the Service family row, says so, and renders no zero-dollar claim"
if [ "${ROVER_FIXTURE_STOP:-}" = 137 ]; then
  exit 0
fi

eyre_post set-default-vehicle \
  "$(printf '{"vehicle":"%s"}' "$statistics_cost_vehicle")" \
  $'Saved default vehicle\n201' 'fixture 138 Statistics browser default'
PLAYWRIGHT_ROOT="${PLAYWRIGHT_ROOT:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules}"
CHROMIUM_BIN="${CHROMIUM_BIN:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
statistics_mobile="$({
  URL="$URL" JAR="$JAR" CHROMIUM_BIN="$CHROMIUM_BIN" NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({headless: true, executablePath: process.env.CHROMIUM_BIN});
  const page = await browser.newPage({viewport: {width: 390, height: 844}});
  page.setDefaultTimeout(90000);
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/\s(urbauth-[^\s]+)\s+([^\s]+)/);
  if (!cookie) throw new Error('urbauth cookie missing');
  await page.context().addCookies([{name: cookie[1], value: cookie[2], domain: 'localhost', path: '/'}]);
  await page.goto(`${process.env.URL}/apps/rover`);
  await page.locator('[data-open-screen="statistics-screen"]').click();
  const result = await page.locator('#statistics-screen').evaluate((screen) => {
    const names = [
      'total-cost-of-ownership',
      'cost-per-distance',
      'spend-by-family',
      'service-history-summary'
    ];
    const sections = names.map((name) => screen.querySelector(`[data-statistic="${name}"]`));
    const tables = sections.map((section) => section && section.querySelector('table'));
    return {
      allPresent: sections.every(Boolean),
      screenOverflow: screen.scrollWidth > screen.clientWidth,
      tableOverflow: tables.some((table) => !table || table.scrollWidth > table.parentElement.clientWidth),
      viewportOverflow: tables.some((table) => table && table.getBoundingClientRect().right > window.innerWidth + 0.5),
      forbiddenVisual: Boolean(screen.querySelector('canvas, svg, [class*="chart"], [id*="chart"]'))
    };
  });
  process.stdout.write(JSON.stringify(result));
  await browser.close();
})().catch((error) => { console.error(error); process.exit(1); });
NODE
} 2>&1)" || fail "fixture 138 Statistics browser failed: $statistics_mobile"
python3 -c 'import json, sys
result = json.loads(sys.argv[1])
assert result["allPresent"], result
assert not result["screenOverflow"], result
assert not result["tableOverflow"], result
assert not result["viewportOverflow"], result
assert not result["forbiddenVisual"], result' "$statistics_mobile" \
  || fail "fixture 138 Statistics mobile or tables-only measurement failed: $statistics_mobile"
note "fixture 138 PASS - all four new Statistics tables fit a real 390px browser with no chart, SVG, canvas, or horizontal overflow: $statistics_mobile"
if [ "${ROVER_FIXTURE_STOP:-}" = 138 ]; then
  exit 0
fi

if [ "${ROVER_T11_ONLY:-}" = 1 ]; then
  note "COVERAGE - all 5 T11 fixtures executed"
  exit 0
fi

restore_test_database
owner_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
python3 -c 'import sys
document = sys.stdin.read()
statistics_path, settings_path = sys.argv[1:3]
if statistics_path:
    start = document.find("<section id=\"statistics-screen\"")
    end = document.find("<section id=\"settings-screen\"", start)
    if start < 0 or end < 0:
        raise SystemExit("final owner statistics screen is absent")
    with open(statistics_path, "w", encoding="utf-8") as artifact:
        artifact.write("<!-- Authenticated final owner Eyre HTML. -->\n")
        artifact.write(document[start:end])
if settings_path:
    marker = "data-vehicle-settings-panel data-vehicle=\"Rover Demo Gasoline\""
    marker_at = document.find(marker)
    start = document.rfind("<article class=\"vehicle-card\"", 0, marker_at)
    end = document.find("<article class=\"vehicle-card\"", marker_at + len(marker))
    if marker_at < 0 or start < 0 or end < 0:
        raise SystemExit("final owner gasoline settings panel is absent")
    with open(settings_path, "w", encoding="utf-8") as artifact:
        artifact.write("<!-- Authenticated final owner Eyre HTML. -->\n")
        artifact.write(document[start:end])' \
  "${ROVER_STATISTICS_ARTIFACT:-}" "${ROVER_SETTINGS_ARTIFACT:-}" <<<"$owner_view" \
  || fail "final owner served-HTML artifact capture failed"
owner_vehicles="$(
  python3 -c 'import html, re, sys
document = html.unescape(sys.stdin.read())
screen = document.split("<section id=\"vehicles-screen\"", 1)[1].split("</section>", 1)[0]
active = screen.split("<details class=\"archived-vehicles\"", 1)[0]
labels = sorted(set(re.findall(r"data-open-vehicle-settings data-vehicle=\"([^\"]+)\"", active)))
print("|".join(labels))' <<<"$owner_view"
)"
[ "$owner_vehicles" = "$owner_vehicles_before" ] \
  || fail "fixture 75 owner vehicle set changed across disposable-database restoration: before=${owner_vehicles_before:-<none>} after=${owner_vehicles:-<none>}"
if grep -Eq 'data-vehicle="(Fixture |History Vehicle |Fill Edit Vehicle |Charge Subtype Vehicle |Pricing Fixture Vehicle)' <<<"$owner_view"; then
  fail "fixture 75 a named scenario artefact is served after disposable-database restoration"
fi
note "fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run"

. "$(dirname "$0")/coverage-gate.sh"
