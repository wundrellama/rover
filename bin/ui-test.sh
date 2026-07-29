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

read_structure_report() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%app-structure-report ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))'
}

read_starter_report() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%starter-report ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))'
}

read_demo_starter_report() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%demo-starter-report ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))'
}

read_consumable_starter_report() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%consumable-starter-report ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))'
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

CODE="$(derive_code "$PIER")"
[ -n "$CODE" ] || fail "could not derive +code"
JAR="$(mktemp /tmp/rover-ui-cookie.XXXXXX)"
HDRS="$(mktemp /tmp/rover-ui-headers.XXXXXX)"
ASSET="$(mktemp /tmp/rover-ui-asset.XXXXXX)"
ROVER_TEST_BACKUP_DB="rovertestowner"
ROVER_TEST_DB_SWAPPED=0

obelisk_mutate() {
  local database="$1" query="$2"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-ui-test-mutation
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %$database \"$query\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
}

read_database_report() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-ui-test-databases
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %sys "FROM sys.sys.databases SELECT database;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)'
}

database_exists() {
  local report="$1" database="$2"
  grep -Fq "[%database %tas %$database]" <<<"$report"
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
  restore_test_database
  rm -f "$JAR" "$HDRS" "$ASSET"
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
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s8)
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null
  database_report="$(read_database_report)"
  database_exists "$database_report" rover \
    || fail "fixture isolation did not create the disposable rover database"
  database_exists "$database_report" "$ROVER_TEST_BACKUP_DB" \
    || fail "fixture isolation lost the renamed owner database"
fi

body="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "authenticated GET /apps/rover not 200"
grep -qi '^content-type: text/html' "$HDRS" || fail "shell content-type is not text/html"
grep -q 'ROVER' <<<"$body" || fail "served shell has no Rover designation"
note "authenticated Rover shell served over real Eyre"

grep -q -- '--rv-bg: #0b0a08' <<<"$body" || fail "UA 571-C background token missing"
grep -q -- '--rv-amber: #d8b843' <<<"$body" || fail "UA 571-C amber token missing"
[ "$(grep -c '@font-face' <<<"$body")" -eq 4 ] || fail "shell does not declare four Berkeley Mono faces"
grep -q 'font-variant-numeric: tabular-nums' <<<"$body" || fail "tabular numerals are not active"
grep -q 'id="glow-toggle"' <<<"$body" || fail "glow control is missing"
grep -q 'min-height: 44px' <<<"$body" || fail "44px touch target rule is missing"
grep -q '@media (min-width: 48rem)' <<<"$body" || fail "mobile-first wide breakpoint is missing"
grep -q 'overflow-x: hidden' <<<"$body" || fail "narrow viewport overflow guard is missing"
note "UA 571-C palette, fonts, glow control, and mobile rules served"

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
settings_tank_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
settings_subtype_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
settings_combined_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
settings_cleared_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
settings_other_first_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_label_first\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
settings_other_second_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_label_second\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
settings_def_clear_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_label_second\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
if grep -q '\[%unit %tas %gal\]' <<<"$settings_def_clear_report"; then
  fail "fixture 74 clearing optional DEF tank size left a child row: $settings_def_clear_report"
fi

settings_def_disabled="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"93","energySources":["Gasoline","Diesel"],"drivingModes":["Sport"],"defEnabled":"no","defTankSize":"","defTankUnit":"gal"}' "$settings_label_second" "$settings_label_second")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_def_disabled" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 74 disabling DEF failed: $settings_def_disabled"
settings_def_disabled_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_label_second\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%link-archived 102 0\\]" \
  <<<"$settings_def_disabled_report" \
  || fail "fixture 74 disabling DEF did not archive its membership: $settings_def_disabled_report"

settings_def_reenabled="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","tankSize":"","tankUnit":"gal","defaultSubtype":"93","energySources":["Gasoline","Diesel"],"drivingModes":["Sport"],"defEnabled":"yes","defTankSize":"","defTankUnit":"gal"}' "$settings_label_second" "$settings_label_second")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$settings_def_reenabled" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 74 re-enabling DEF failed: $settings_def_reenabled"
settings_def_reenabled_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$settings_label_second\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-demo-fuel ~]))
;<  ~  bind:m  (sleep ~s4)
(pure:m !>(~))' >/dev/null
  demo_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw '{"vehicle":"Rover Demo Gasoline"}' \
    "$URL/apps/rover/set-default-vehicle")"
  [ "$demo_default" = $'Saved default vehicle\n201' ] \
    || fail "fixture 63 could not set the demo app-default-vehicle: $demo_default"
  demo_before_def="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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
print("yes" if "data-economy-break=\"%missed-fill\"" in document else "no")' <<<"$demo_before_def"
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

  diesel_before_def="${demo_parts[1]}"
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-demo-def ~]))
;<  ~  bind:m  (sleep ~s4)
(pure:m !>(~))' >/dev/null
  demo_after_def="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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
      if (rows.some((row) => row.dataset.statisticsVehicle !== selected)) {
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
  await selector.evaluate((select) => {
    const option = [...select.options].find(
      (candidate) => candidate.textContent === 'Rover Demo Diesel'
    );
    if (!option) throw new Error('Rover Demo Diesel selector option is missing');
    select.value = option.value;
    select.dispatchEvent(new Event('change', {bubbles: true}));
  });
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
  expected_statistics_switch='Rover Demo Gasoline|Rover Demo Gasoline|Rover Demo Diesel|Rover Demo Diesel|economy-by-subtype,fuel-costs,distance-between-fills,time-between-fills,average-price-per-unit,distance-per-tank,def-economy'
  [ "$statistics_switch_summary" = "$expected_statistics_switch" ] \
    || fail "fixture 65 switching scope did not change every table and header: $statistics_switch_summary"
  note "fixture 65 PASS - selector changed the header and all seven statistics tables from gasoline to diesel"

  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %rover "DELETE FROM app-default-vehicle WHERE scope = %app;"]))
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
print("yes" if all(item in document for item in required) else "no")' <<<"$demo_after_def"
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

rename_result="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%rename-energy-source (crip "Gasoline") (crip "Owner Gasoline Custom")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))')"
grep -q '%noun 0' <<<"$rename_result" \
  || fail "fixture 35 owner rename failed: $rename_result"
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(~))' >/dev/null
renamed_report="$(read_starter_report)"
[ "$(grep -o '\[%physical-kind ' <<<"$renamed_report" | wc -l)" -eq 8 ] \
  || fail "fixture 35 re-seed changed owner source count; actual: $renamed_report"
grep -q "\\[%label 116 'Owner Gasoline Custom'\\]" <<<"$renamed_report" \
  || fail "fixture 35 re-seed overwrote owner rename; actual: $renamed_report"
if grep -q "\\[%label 116 'Gasoline'\\]" <<<"$renamed_report"; then
  fail "fixture 35 re-seed inserted a duplicate Gasoline owner row"
fi
note "fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite"

click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%rename-energy-source (crip "Owner Gasoline Custom") (crip "Gasoline")]))
;<  ~  bind:m  (sleep ~s2)
(pure:m !>(~))' >/dev/null
for vehicle in "$gas_vehicle" "$diesel_vehicle"; do
  removed="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s"}' "$vehicle")" \
    "$URL/apps/rover/remove-vehicle")"
  [ "$removed" = $'Archived vehicle\n201' ] \
    || fail "fixture 33 cleanup failed for $vehicle: $removed"
done
if [ "${ROVER_FIXTURE_STOP:-}" = 35 ]; then
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
vehicle_settings_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$edited_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"8.000","price":"$3.39","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"%s","zone":"America/Chicago","mileage":"19900.0","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":""}' "$fill_edit_vehicle" "$fill_edit_baseline_observed")" \
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
fill_edit_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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
fill_edit_support="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-fill-edit-support (crip \"$fill_edit_vehicle\")]))
;<  ~  bind:m  (sleep ~s3)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -q '%noun 0' <<<"$fill_edit_support" \
  || fail "fixture 38 support definitions failed: $fill_edit_support"
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
fill_edit_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%fill-edit-report (crip \"$fill_edit_vehicle\") ~2026.7.27..11.45.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
fill_edit_rerender="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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

fill_edit_pre_odometer="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%fill-edit-report (crip \"$fill_edit_vehicle\") ~2026.7.27..11.45.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
fill_edit_post_odometer="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%fill-edit-report (crip \"$fill_edit_vehicle\") ~2026.7.27..11.45.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -Fq '[%value-digits 25717 0x30d40] [%decimal-places 25717 1] [%unit %tas 26989]' <<<"$fill_edit_post_odometer" \
  || fail "fixture 39 did not create and link the exact historical odometer observation: $fill_edit_post_odometer"
fill_edit_economy_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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
address_station_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%station-report (crip \"$address_station\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
note "fixture 40 PASS - manual station persists owner address parts and scale-7 coordinates while omitted parts create no rows"

name_only_station="Name Only Station $(date +%s%N)"
name_only_place="Name Only Place $(date +%s%N)"
name_only_result="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"4.000","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-29T12:00","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"%s","newPlaceLabel":"%s","newStationKind":"fuel","newAddressFormatted":"","newAddressLine1":"","newAddressLine2":"","newLocality":"","newRegion":"","newPostalCode":"","newCountry":"","newLatitude":"","newLongitude":"","additives":[],"subtype":"87","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' "$fill_edit_vehicle" "$name_only_station" "$name_only_place")" \
  "$URL/apps/rover/add-fill")"
[ "$name_only_result" = $'Saved fill - $3.499 - derived $14.00\n201' ] \
  || fail "fixture 41 name-only station create failed: $name_only_result"
name_only_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%station-report (crip \"$name_only_station\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -Fq "$name_only_station" <<<"$name_only_report" \
  || fail "fixture 41 station row missing: $name_only_report"
[ "$(grep -oF '[%vector-count 0]' <<<"$name_only_report" | wc -l)" -eq 3 ] \
  || fail "fixture 41 name-only station wrote address/part/coordinate evidence: $name_only_report"
note "fixture 41 PASS - name-only manual station writes no empty address rows and no zero-coordinate row"
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
consumable_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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
def_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%consumable-report (crip \"$fill_edit_vehicle\") 'DEF' ~2026.7.30..12.00.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -q "\\[%consumable 116 'DEF'\\].*\\[%quantity-milli 25717 2500\\].*\\[%unit-price-mills 25717 4499\\].*\\[%settlement-mode %tas %standard\\].*\\[%price-profile %tas %us-usd-gal\\].*\\[%minor-unit-decimals 25717 2\\].*\\[%cash-increment-mills 25717 50\\]" <<<"$def_report" \
  || fail "fixture 42 DEF purchase did not retain exact snapshotted pricing: $def_report"
consumable_after="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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
charge_subtype_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%charge-subtype-report (crip \"$charge_subtype_vehicle\") ~2026.7.31..12.00.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -q "\\[%vehicle 116 '$charge_subtype_vehicle'\\].*\\[%charging-subtype 116 'DC Fast'\\]" <<<"$charge_subtype_report" \
  || fail "fixture 43 charging-session-subtype link missing: $charge_subtype_report"
note "fixture 43 PASS - charge persists its electricity subtype through charging-session-subtype"
if [ "${ROVER_FIXTURE_STOP:-}" = 43 ]; then
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
payment_without_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%fill-edit-report (crip \"$fill_edit_vehicle\") ~2026.7.28..18.00.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
payment_with_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%fill-edit-report (crip \"$fill_edit_vehicle\") ~2026.7.28..19.00.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
phev_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$phev_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
phev_edited_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$phev_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
mode_create_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$mode_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -q "\\[%driving-mode 116 'Towing'\\].*\\[%link-archived 102 1\\]" <<<"$mode_create_report" \
  || fail "fixture 48 create-mode membership missing: $mode_create_report"
mode_edited="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","label":"%s","energySources":["Gasoline"],"drivingModes":["Mixed Driving"]}' "$mode_vehicle" "$mode_vehicle")" \
  "$URL/apps/rover/edit-vehicle")"
[ "$mode_edited" = $'Saved vehicle settings\n201' ] \
  || fail "fixture 48 mode edit failed: $mode_edited"
mode_edit_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$mode_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
def_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$def_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
no_def_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-settings-report (crip \"$no_def_vehicle\")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
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
def_economy_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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

fuel_before_fixture53="$(curl -s -b "$JAR" "$URL/apps/rover/view" | grep -oF "data-economy-vehicle=\"$fill_edit_vehicle\" data-economy=\"9.000 mpg\"" | wc -l)"
def_outside_fuel="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","consumable":"DEF","quantity":"1.000","price":"$4.49","profile":"us-usd-gal","settlement":"standard","observed":"2026-08-21T08:00","zone":"America/Chicago","mileage":"20200.0","mileageUnit":"mi"}' "$fill_edit_vehicle")" \
  "$URL/apps/rover/add-consumable")"
[ "$def_outside_fuel" = $'Saved consumable purchase - $4.50\n201' ] \
  || fail "fixture 53 DEF control purchase failed: $def_outside_fuel"
fuel_after_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
fuel_after_fixture53="$(grep -oF "data-economy-vehicle=\"$fill_edit_vehicle\" data-economy=\"9.000 mpg\"" <<<"$fuel_after_view" | wc -l)"
[ "$fuel_before_fixture53" -eq 1 ] && [ "$fuel_after_fixture53" -eq 1 ] \
  || fail "fixture 53 DEF changed fuel economy: before=$fuel_before_fixture53 after=$fuel_after_fixture53"
fixture53_report="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%consumable-report (crip \"$fill_edit_vehicle\") 'DEF' ~2026.8.21..08.00.00]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
grep -q "\\[%consumable 116 'DEF'\\]" <<<"$fixture53_report" \
  || fail "fixture 53 DEF purchase missing from consumable parent: $fixture53_report"
note "fixture 53 PASS - DEF remains outside fuel acquisitions and leaves exact 9.000 mpg unchanged"
if [ "${ROVER_FIXTURE_STOP:-}" = 53 ]; then
  exit 0
fi

consumable_rename="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%rename-consumable (crip "DEF") (crip "Owner DEF Custom")]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))')"
grep -q '%noun 0' <<<"$consumable_rename" \
  || fail "fixture 54 owner consumable rename failed: $consumable_rename"
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(~))' >/dev/null
consumable_starters="$(read_consumable_starter_report)"
[ "$(grep -o '\[%consumable-id ' <<<"$consumable_starters" | wc -l)" -eq 4 ] \
  || fail "fixture 54 re-seed changed consumable starter count: $consumable_starters"
for starter in 'Owner DEF Custom' 'Washer Fluid' 'Motor Oil' 'Coolant'; do
  grep -q "\\[%label 116 '$starter'\\]" <<<"$consumable_starters" \
    || fail "fixture 54 starter missing after re-seed ($starter): $consumable_starters"
done
if grep -q "\\[%label 116 'DEF'\\]" <<<"$consumable_starters"; then
  fail "fixture 54 re-seed inserted a duplicate DEF row"
fi
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%rename-consumable (crip "Owner DEF Custom") (crip "DEF")]))
;<  ~  bind:m  (sleep ~s2)
(pure:m !>(~))' >/dev/null
note "fixture 54 PASS - DEF, washer fluid, motor oil, and coolant seed once; an owner rename survives re-seeding"
if [ "${ROVER_FIXTURE_STOP:-}" = 54 ]; then
  exit 0
fi
fi

if ! grep -q 'Phase A Vehicle' <<<"$view"; then
  for support_action in seed-spike seed-app-structure seed-fuel-evidence \
    seed-charging-evidence seed-charging-cost seed-consumption seed-location seed-pricing; do
    support_result="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%$support_action ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))")"
    grep -q '%noun 0' <<<"$support_result" \
      || fail "real-substrate support seed failed ($support_action): $support_result"
  done
fi
view="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover/view")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "seeded vehicle view not 200"

grep -q '<section id="main-hub"' <<<"$view" || fail "main hub is missing"
grep -Eq 'DEFAULT VEHICLE NOT SET|Structure Vehicle|Mode Scope Vehicle' <<<"$view" ||
  fail "hub does not name its default state"
for destination in add-odometer vehicles-screen history-screen statistics-screen settings-screen; do
  grep -q "data-open-screen=\"$destination\"" <<<"$view" ||
    fail "hub navigation is missing $destination"
done
for readout in 'MOST RECENT ODOMETER' 'ECONOMY - LAST FILL' 'ECONOMY - LIFETIME' \
  'ESTIMATED DISTANCE TO NEXT FILL' 'BEST ECONOMY' 'WORST ECONOMY'; do
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
grep -q 'IMPORT / EXPORT.*COMING LATER' <<<"$view" \
  || fail "Settings lacks import/export placeholder"
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
grep -q 'Regular 87 E10' <<<"$view" ||
  fail "fill detail does not render the subtype label"
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
if grep -Eq '<input[^>]+name="(total|unitPriceMills|quantityMilli)"' <<<"$view"; then
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
second_insert="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%try-second-app-default ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))')"
grep -q '%noun 0 0 1 ' <<<"$second_insert" \
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
  --data-raw '{"vehicle":"Location Evidence Vehicle"}' \
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
  await fillForm.locator('[name="vehicle"]').selectOption({label: 'Fuel Evidence Vehicle'});
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
  await fillForm.locator('[name="station"]').selectOption('Home Charger');
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
      font: document.fonts.check('12px "Berkeley Mono"'),
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
  const firstHistoryRow = page.locator('[data-history-vehicle]').first();
  const historyTarget = await firstHistoryRow.getAttribute('data-history-vehicle');
  await historyFilter.evaluate((select, target) => {
    select.value = target;
    select.dispatchEvent(new Event('change', {bubbles: true}));
  }, historyTarget);
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
grep -Eq 'Unavailable - %?missed-fill' <<<"$view" \
  || fail "fixture 22 missed-fill reason did not render; actual served HTML: $view"
note "fixture 22 PASS - live Obelisk break and served HTML both contain missed-fill"

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
view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
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
history="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-history ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))')"
grep -q '\[%quantity-milli 25717 6543\].*\[%unit-price-mills 25717 3499\]' <<<"$history" \
  || fail "saved fill did not retain exact 6543/3499 machine integers"
view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q '6.543 gal' <<<"$view" || fail "saved fill quantity did not render back to a human"
grep -q '\$22\.89' <<<"$view" || fail "saved fill derived total did not render"
note "valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived \$22.89"

saved_station_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"5.111","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-29T00:10","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"Home Charger","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":["Injector cleaner"]}' \
  "$URL/apps/rover/add-fill")"
[ "$saved_station_fill" = $'Saved fill - $3.499 - derived $17.88\n201' ] \
  || fail "saved-station fill failed: $saved_station_fill"

new_station_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"5.222","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-29T00:20","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"UI Home Pump","newPlaceLabel":"UI Home","newStationKind":"private","additives":["Injector cleaner","Fuel stabilizer"]}' \
  "$URL/apps/rover/add-fill")"
[ "$new_station_fill" = $'Saved fill - $3.499 - derived $18.27\n201' ] \
  || fail "new-station fill failed: $new_station_fill"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q 'Home Charger' <<<"$view" || fail "saved private station did not render"
grep -q 'UI Home Pump' <<<"$view" || fail "new private station did not render"
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

km_preference="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Fuel Evidence Vehicle","distanceUnit":"km","currency":"usd"}' \
  "$URL/apps/rover/set-preference")"
[ "$km_preference" = $'Saved display preference - km\n201' ] \
  || fail "per-vehicle km preference failed: $km_preference"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -Fq '32,186.9 km (converted)' <<<"$view" \
  || fail "Fuel Evidence Vehicle did not render converted and labelled"
phase_card="$(html_slice '<h2>Phase A Vehicle</h2>' '<h2>' <<<"$view")"
grep -q 'value="native" selected' <<<"$phase_card" \
  || fail "Phase A Vehicle preference was affected by the other vehicle"
preference_report="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%display-preference-report ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))')"
grep -q '\[%value-digits 25717 0x30d40\].*\[%decimal-places 25717 1\].*\[%unit %tas 26989\]' <<<"$preference_report" \
  || fail "display preference changed stored odometer evidence"
grep -q '\[%distance-unit %tas 28011\]' <<<"$preference_report" \
  || fail "per-vehicle km preference was not stored"
note "per-vehicle km preference converts and labels one vehicle without rewriting evidence"

human_hub_default="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Fuel Evidence Vehicle"}' \
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
for face in Regular Bold Oblique Bold-Oblique; do
  asset_check "/apps/rover/assets/fonts/BerkeleyMono-$face.woff2" font/woff2 \
    "$REPO/desk/app/rover/assets/fonts/BerkeleyMono-$face.woff2"
done
note "tile and four font faces have exact bytes and content-types"

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
curl -s -b "$JAR" -o /dev/null \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Rover Demo Gasoline"}' \
  "$URL/apps/rover/set-default-vehicle"
archive_history_vehicle="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Fuel Evidence Vehicle"}' \
  "$URL/apps/rover/remove-vehicle")"
[ "$archive_history_vehicle" = $'Archived vehicle\n201' ] \
  || fail "fixture 80 could not archive a non-default vehicle with history: $archive_history_vehicle"
archived_view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
if grep -Eq '<option value="Fuel Evidence Vehicle"[^>]*>' <<<"$archived_view"; then
  fail "fixture 80 archived vehicle remains in a default selector"
fi
grep -q '<summary>View archived vehicles</summary>.*data-vehicle="Fuel Evidence Vehicle"' \
  <<<"$(tr '\n' ' ' <<<"$archived_view")" \
  || fail "fixture 80 archived vehicle is absent from the archived-vehicle view"
grep -q 'data-vehicle-settings-panel data-vehicle="Fuel Evidence Vehicle".*ARCHIVED.*ORDERED HISTORY.*history-card fill' \
  <<<"$(tr '\n' ' ' <<<"$archived_view")" \
  || fail "fixture 80 archived vehicle history is not intact and viewable"
note "fixture 80 PASS - literal-Y archive hides selectors, preserves history, and refuses the app default until redesignation"

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
[ "$owner_vehicles" = 'Rover Demo Diesel|Rover Demo Gasoline' ] \
  || fail "fixture 75 owner database was contaminated by the disposable battery, or was not a fresh demo-only owner: ${owner_vehicles:-<none>}"
if grep -Eq 'data-vehicle="(Fixture |History Vehicle |Fill Edit Vehicle |Charge Subtype Vehicle |Pricing Fixture Vehicle)' <<<"$owner_view"; then
  fail "fixture 75 a named scenario artefact is served after disposable-database restoration"
fi
note "fixture 75 PASS - after the full disposable battery the owner database serves only the two demo vehicles"

. "$(dirname "$0")/coverage-gate.sh"
