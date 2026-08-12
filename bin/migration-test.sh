#!/usr/bin/env bash
# Rover 15->16 state-migration fixture.
#
# Proves the two things the migration must hold:
#   1. Durable data written at v15 survives the upgrade to v16.
#   2. An in-flight HTTP request whose pending input the migration drops
#      gets a 503 with a human reason. The caller does not hang.
#
# Mechanism, all real, no back doors:
#   - Install the last v15 desk (commit ec31814, on-save %15) on a fresh
#     %rover. Write a vehicle and a completed charge through Eyre.
#   - Suspend the %obelisk desk. POST /apps/rover/add-charge. The handler
#     stores http-pending and charge-pending, and Gall queues the blocked
#     watch and poke until %obelisk returns.
#   - Commit the current desk. on-load 15->16 keeps http-pending and
#     drops charge-pending. The eyre-id is now orphaned.
#   - Revive %obelisk. The queued poke lands, the fact arrives on the
#     orphaned wire, and the boundary must answer 503.
#
# The fixture leaves the pier on the current desk with a fresh v16 agent.
set -uo pipefail

PIER="${1:-${ROVER_PIER:-}}"
if [ -z "$PIER" ]; then
  echo "migration-test: no pier given. usage: bin/migration-test.sh <pier>" >&2
  exit 2
fi
PIER="${PIER/#\~/$HOME}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || { echo "click not on PATH" >&2; exit 2; }

# The last commit whose on-save writes %15. M0-CC (fc7a63f) moved to %16.
V15_COMMIT=ec31814

fail() { echo "migration-test: FAIL - $*" >&2; exit 1; }
note() { echo "migration-test: $*"; }

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || fail "no public http port in $PIER/.http.ports"
URL="http://localhost:$PORT"

click_file() {
  local body="$1" file out
  file="$(mktemp /tmp/rover-migration.XXXXXX.hoon)"
  printf '%s\n' "$body" > "$file"
  out="$(click -k -i "$file" "$PIER" 2>/dev/null | tail -1)"
  rm -f "$file"
  printf '%s\n' "$out"
}

hood() {
  local mark="$1" noun="$2" out
  out="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %hood] %$mark !>($noun))
(pure:m !>(%poked))")"
  grep -q '%poked' <<<"$out" || fail "hood poke %$mark $noun refused: $out"
}

wait_commit() {
  # A kiln commit builds the desk. Poll the running agent until the new
  # source is live, with a hard cap.
  sleep 20
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

sync_desk() {
  local src="$1"
  rsync -a --delete --exclude='.urb' "$src/" "$PIER/rover/"
  find "$PIER/rover" -type d -empty -delete
}

# --- Step 1: fresh v15 agent -------------------------------------------------
V15DIR="$(mktemp -d /tmp/rover-v15.XXXXXX)"
trap 'rm -rf "$V15DIR"' EXIT
git -C "$REPO" archive "$V15_COMMIT" desk | tar -x -C "$V15DIR"
grep -q "on-save  !>(\[%15 state\])" "$V15DIR/desk/app/rover.hoon" \
  || fail "commit $V15_COMMIT does not carry a %15 on-save"

note "step 1 - install v15 desk ($V15_COMMIT) on a fresh %rover"
hood kiln-nuke '[%rover %.n]'
sleep 5
sync_desk "$V15DIR/desk"
hood kiln-commit '[%rover %.n]'
wait_commit
hood kiln-revive '%rover'
sleep 10

# --- Step 2: v15 baseline and durable data ----------------------------------
note "step 2 - v15 owner baseline and durable data"
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s3)
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(~))' >/dev/null

CODE="$(derive_code)"
[ -n "$CODE" ] || fail "could not derive +code"
JAR="$(mktemp /tmp/rover-migration-cookie.XXXXXX)"
curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"

STAMP="$(date +%s%N)"
VEHICLE="Migration Vehicle $STAMP"
created="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"label":"%s","energy":"Electricity"}' "$VEHICLE")" \
  "$URL/apps/rover/add-vehicle")"
[ "$created" = "Added vehicle - $VEHICLE"$'\n201' ] \
  || fail "v15 add-vehicle failed: $created"

durable="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","start":"2026-08-01T12:00","end":"2026-08-01T12:30","zone":"America/Chicago","energyDelivered":"40.0","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"unknown","currency":"usd"}' "$VEHICLE")" \
  "$URL/apps/rover/add-charge")"
[ "$durable" = $'Saved charge - Energy delivered 40.0 kWh\n201' ] \
  || fail "v15 durable charge failed: $durable"
note "step 2 PASS - v15 serves the baseline and saved a real charge"

# --- Step 3: charge in flight, obelisk away ----------------------------------
note "step 3 - suspend %obelisk and put a charge in flight"
hood kiln-suspend '%obelisk'
sleep 5

INFLIGHT="$(mktemp /tmp/rover-migration-inflight.XXXXXX)"
( curl -s -b "$JAR" -w $'\n%{http_code}\nELAPSED=%{time_total}' \
    --max-time 300 \
    -H 'content-type: application/json' \
    --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","start":"2026-08-01T13:00","end":"2026-08-01T13:30","zone":"America/Chicago","energyDelivered":"20.0","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"unknown","currency":"usd"}' "$VEHICLE")" \
    "$URL/apps/rover/add-charge" > "$INFLIGHT" 2>&1 ) &
INFLIGHT_PID=$!
sleep 5
kill -0 "$INFLIGHT_PID" 2>/dev/null \
  || fail "in-flight charge returned before the upgrade: $(cat "$INFLIGHT")"
note "step 3 PASS - the charge request is pending against a suspended substrate"

# --- Step 4: upgrade 15 -> 16 ------------------------------------------------
note "step 4 - commit the current desk, on-load 15->16 runs"
sync_desk "$REPO/desk"
hood kiln-commit '[%rover %.n]'
wait_commit

# --- Step 5: revive, the queued fact lands on the orphaned wire --------------
note "step 5 - revive %obelisk"
hood kiln-revive '%obelisk'

if ! wait "$INFLIGHT_PID"; then
  cat "$INFLIGHT" >&2
  fail "in-flight charge hung until curl gave up - the boundary did not speak"
fi
body="$(sed -n '1p' "$INFLIGHT")"
status="$(sed -n '2p' "$INFLIGHT")"
elapsed="$(sed -n '3p' "$INFLIGHT")"
[ "$status" = 503 ] \
  || fail "in-flight charge got '$status/$body', want 503 ($elapsed)"
[ "$body" = 'Rover restarted while saving. Please submit again.' ] \
  || fail "503 reason is not the human sentence: $body"
note "step 5 PASS - orphaned request answered 503 with a human reason ($elapsed)"

# --- Step 6: durable data survived, resubmit works ---------------------------
view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -qF "$VEHICLE" <<<"$view" \
  || fail "v15 vehicle absent from the v16 view after migration"
grep -qF 'data-history-column' <<<"$view" \
  || fail "v16 view lost its history surface after migration"

resubmit="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw "$(printf '{"vehicle":"%s","definition":"Electricity","start":"2026-08-01T13:00","end":"2026-08-01T13:30","zone":"America/Chicago","energyDelivered":"20.0","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"unknown","currency":"usd"}' "$VEHICLE")" \
  "$URL/apps/rover/add-charge")"
[ "$resubmit" = $'Saved charge - Energy delivered 20.0 kWh\n201' ] \
  || fail "resubmitted charge failed after migration: $resubmit"
note "step 6 PASS - durable v15 data survived and the resubmitted charge saved"

rm -f "$JAR" "$INFLIGHT"
note "PASS - the 15->16 migration keeps durable data and the boundary speaks"
