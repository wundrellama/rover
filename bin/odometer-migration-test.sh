#!/usr/bin/env bash
# Rover M7 T3 populated energy-odometer migration battery.
#
# This battery deliberately begins on the published pre-T3 desk, writes three
# fills through Eyre, takes a stopped full-pier backup, upgrades the desk, and
# invokes the shipping ensure-def-schema action. Reads go to real Obelisk or
# through the served Eyre view; there is no fixture action and no mock database.
set -uo pipefail

PIER="${1:-${ROVER_PIER:-}}"
if [ -z "$PIER" ]; then
  echo "odometer-migration-test: no pier given. usage: bin/odometer-migration-test.sh <pier>" >&2
  exit 2
fi
PIER="${PIER/#\~/$HOME}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PATH="$HOME/workspace/urbit/bin:$PATH"
OLD_COMMIT=9a4003e

fail() { echo "odometer-migration-test: FAIL - $*" >&2; exit 1; }
note() { echo "odometer-migration-test: $*"; }

case "$(basename "$PIER")" in
  rover-m7t3-*-bel) ;;
  *) fail "refusing destructive rehearsal outside a dedicated rover-m7t3-*-bel pier: $PIER" ;;
esac
[ -S "$PIER/.urb/conn.sock" ] || fail "no live conn.sock under $PIER"
command -v click >/dev/null 2>&1 || fail "click not on PATH"

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || fail "no public HTTP port in $PIER/.http.ports"
URL="http://localhost:$PORT"
JAR="$(mktemp /tmp/rover-m7t3-migration-cookie.XXXXXX)"
OLDDIR="$(mktemp -d /tmp/rover-m7t3-old.XXXXXX)"
trap 'rm -f "$JAR"; rm -rf "$OLDDIR"' EXIT

click_file() {
  local body="$1" file out
  file="$(mktemp /tmp/rover-m7t3-migration.XXXXXX.hoon)"
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

obelisk() {
  local database="$1" script="$2"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-m7t3-migration-read
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %$database %vector \"$script\"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)"
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

login() {
  local code
  code="$(derive_code)" || fail "could not derive +code"
  : > "$JAR"
  curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$code"
  grep -q urbauth "$JAR" || fail "could not log in to $URL"
}

eyre_post() {
  local path="$1" payload="$2" expected="$3" label="$4" response
  response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
    -H 'content-type: application/json' --data-raw "$payload" \
    "$URL/apps/rover/$path")"
  [ "$response" = "$expected" ] || fail "$label: $response"
}

eyre_view() {
  curl -s -b "$JAR" -H 'content-type: application/json' \
    --data-raw '{"page":"0"}' "$URL/apps/rover/view"
}

sync_desk() {
  local source="$1"
  rsync -a --delete --exclude='tests/' --exclude='gen/' "$source/" "$PIER/rover/"
  find "$PIER/rover" -type d -empty -delete
}

pair_fingerprint() {
  python3 -c '
import hashlib, re, sys
text = sys.stdin.read()
acquisitions = re.findall(r"\[%acquisition-id [^]]+\]", text)
odometers = re.findall(r"\[%odometer-id [^]]+\]", text)
if len(acquisitions) != len(odometers):
    raise SystemExit("unpaired migration rows")
rows = sorted(a + " " + o for a, o in zip(acquisitions, odometers))
print(str(len(rows)) + " " + hashlib.sha256("\n".join(rows).encode()).hexdigest())
'
}

ensure_def_schema() {
  click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%ensure-def-schema ~]))
;<  ~  bind:m  (sleep ~s8)
(pure:m !>(~))' >/dev/null
}

restart_pier() {
  local session="$1" ames_port="$2" ready=0
  tmux send-keys -t "$session" '|exit' Enter
  for attempt in $(seq 1 90); do
    pgrep -f "snap-dir $PIER" >/dev/null || break
    sleep 1
  done
  pgrep -f "snap-dir $PIER" >/dev/null && fail "the pier did not stop"
  tmux kill-session -t "$session" 2>/dev/null || true
  tmux new-session -d -s "$session" \
    "exec script -q -f -e -O /dev/null -c $(printf '%q' "urbit -p $ames_port $PIER")"
  for attempt in $(seq 1 180); do
    PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports" 2>/dev/null)"
    if [ -n "$PORT" ] && curl -s -o /dev/null "http://localhost:$PORT/~/login"; then
      ready=1
      break
    fi
    sleep 1
  done
  [ "$ready" = 1 ] || fail "the pier did not restart"
  URL="http://localhost:$PORT"
}

note "step 1 - install the published pre-T3 desk ($OLD_COMMIT)"
git -C "$REPO" archive "$OLD_COMMIT" desk | tar -x -C "$OLDDIR"
grep -q 'fuel-fill-odometers' "$OLDDIR/desk/lib/rover-act.hoon" \
  || fail "$OLD_COMMIT does not carry the old relation"
hood kiln-nuke '[%rover %.n]'
sleep 5
databases="$(obelisk sys 'FROM sys.databases SELECT database;')"
if grep -q "\[%database %tas %rover\]" <<<"$databases"; then
  obelisk sys 'DROP DATABASE FORCE rover;' >/dev/null \
    || fail "could not remove the prior disposable rover database"
fi
sync_desk "$OLDDIR/desk"
hood kiln-commit '[%rover %.n]'
sleep 25
hood kiln-revive '%rover'
sleep 10

note "step 2 - create an old-schema database and write three fills through Eyre"
click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s4)
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s4)
(pure:m !>(~))' >/dev/null
login
STAMP="$(date +%s)"
VEHICLE="Odometer Migration $STAMP"
eyre_post add-vehicle \
  "$(printf '{"label":"%s","energy":"Gasoline"}' "$VEHICLE")" \
  "$(printf 'Added vehicle - %s\n201' "$VEHICLE")" 'old-schema vehicle'
for spec in '01 61001' '02 61002' '03 61003'; do
  day="${spec%% *}"
  mileage="${spec##* }"
  payload="$(printf '{"vehicle":"%s","definition":"Gasoline","quantity":"10.000","price":"$3.00","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-%sT12:00","zone":"America/Chicago","mileage":"%s","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"fuel","additives":[],"subtype":"","missedFill":"no","drivingMode":"","averageSpeed":"","speedUnit":"mph","driveBalance":"","tags":[],"newTag":"","notes":"","paymentMethod":""}' "$VEHICLE" "$day" "$mileage")"
  eyre_post add-fill "$payload" $'Saved fill - $3.009 - derived $30.09\n201' "old-schema fill $day"
done
source_report="$(obelisk rover 'FROM fuel-fill-odometers F SELECT F.acquisition-id, F.odometer-id;')"
source_fingerprint="$(pair_fingerprint <<<"$source_report")" \
  || fail "could not fingerprint source rows"
source_count="${source_fingerprint%% *}"
[ "$source_count" = 3 ] || fail "source has $source_count rows, want 3"
source_hash="${source_fingerprint##* }"
note "source row count before copy: $source_count"
note "source content fingerprint before copy: $source_hash"

note "step 3 - stop the pier and take the required full-pier backup"
pier_slug="${PIER##*/rover-m7t3-}"
pier_slug="${pier_slug%-bel}"
pier_session="m7t3$pier_slug"
tmux has-session -t "$pier_session" 2>/dev/null \
  || fail "the required tmux session $pier_session is absent"
pier_pid="$(tmux display-message -p -t "$pier_session" '#{pane_pid}')"
pier_args="$(ps -o args= -p "$pier_pid" 2>/dev/null)"
case "$pier_args" in
  *"/piers/$(basename "$PIER")"*) ;;
  *) fail "tmux session $pier_session does not run $PIER: $pier_args" ;;
esac
ames_port="$(sed -n 's/.*-p \([0-9]\{1,\}\).*/\1/p' <<<"$pier_args")"
[ -n "$ames_port" ] || fail "cannot read the Ames port from: $pier_args"
tmux send-keys -t "$pier_session" '|exit' Enter
for attempt in $(seq 1 90); do
  pgrep -f "snap-dir $PIER" >/dev/null || break
  sleep 1
done
pgrep -f "snap-dir $PIER" >/dev/null && fail "the pier did not stop for backup"
tmux kill-session -t "$pier_session" 2>/dev/null || true
# The serf exits first. The king keeps running and removes conn.sock,
# .vere.lock, and .http.ports on its way out, so a tar started here races
# the teardown and fails on files that vanish mid-read. Wait for the urbit
# processes only: a bare path match also matches this script's own command
# line, which never exits.
for attempt in $(seq 1 90); do
  pgrep -x urbit -a 2>/dev/null | grep -qF "$PIER" || break
  sleep 1
done
pgrep -x urbit -a 2>/dev/null | grep -qF "$PIER" \
  && fail "an urbit process still holds $PIER after shutdown"
for attempt in $(seq 1 30); do
  [ -e "$PIER/.vere.lock" ] || break
  sleep 1
done
BACKUP="$HOME/piers/$(basename "$PIER")-before-energy-odometer-migration-$STAMP.tar.zst"
tar --zstd -cf "$BACKUP" -C "$(dirname "$PIER")" "$(basename "$PIER")" \
  || fail "full-pier backup failed"
[ -s "$BACKUP" ] || fail "full-pier backup is empty"
note "full-pier backup: $BACKUP"
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
[ "$ready" = 1 ] || fail "the pier did not restart after backup"
URL="http://localhost:$PORT"

note "step 4 - upgrade and run the shipping migration path"
sync_desk "$REPO/desk"
hood kiln-commit '[%rover %.n]'
sleep 30
ensure_def_schema
tables="$(obelisk rover 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
grep -q '%name %tas %energy-acquisition-odometers' <<<"$tables" \
  || fail "the destination relation is absent"
grep -q '%name %tas %fuel-fill-odometers' <<<"$tables" \
  && fail "the old relation still exists"
destination_report="$(obelisk rover 'FROM energy-acquisition-odometers L SELECT L.acquisition-id, L.odometer-id;')"
destination_fingerprint="$(pair_fingerprint <<<"$destination_report")" \
  || fail "could not fingerprint destination rows"
destination_count="${destination_fingerprint%% *}"
destination_hash="${destination_fingerprint##* }"
[ "$destination_count" = "$source_count" ] \
  || fail "destination has $destination_count rows, source had $source_count"
[ "$destination_hash" = "$source_hash" ] \
  || fail "destination content differs from the recorded source content"
note "destination row count after copy: $destination_count"
note "destination content fingerprint after copy: $destination_hash"
note "step 4 PASS - count and content match, and the old relation is gone"

note "step 5 - every migrated fill still reads through Eyre"
login
view="$(eyre_view)"
for mileage in '61,001 mi' '61,002 mi' '61,003 mi'; do
  grep -qF "$mileage" <<<"$view" \
    || fail "the Eyre view omits migrated fill mileage $mileage"
done
note "step 5 PASS - all three migrated fill mileages render"

note "step 6 - run the migration path a second time"
ensure_def_schema
second_report="$(obelisk rover 'FROM energy-acquisition-odometers L SELECT L.acquisition-id, L.odometer-id;')"
second_fingerprint="$(pair_fingerprint <<<"$second_report")" \
  || fail "could not fingerprint second-run rows"
[ "$second_fingerprint" = "$destination_fingerprint" ] \
  || fail "the second migration path changed destination rows"
tables="$(obelisk rover 'FROM sys.tables WHERE namespace = %dbo SELECT name;')"
grep -q '%name %tas %fuel-fill-odometers' <<<"$tables" \
  && fail "the second migration path recreated the old relation"
note "step 6 PASS - the second migration path changes nothing"

note "step 7 - restart and verify the migrated state"
restart_pier "$pier_session" "$ames_port"
login
restart_report="$(obelisk rover 'FROM energy-acquisition-odometers L SELECT L.acquisition-id, L.odometer-id;')"
restart_fingerprint="$(pair_fingerprint <<<"$restart_report")" \
  || fail "could not fingerprint restarted rows"
[ "$restart_fingerprint" = "$destination_fingerprint" ] \
  || fail "migrated rows changed across restart"
view="$(eyre_view)"
for mileage in '61,001 mi' '61,002 mi' '61,003 mi'; do
  grep -qF "$mileage" <<<"$view" \
    || fail "the restarted Eyre view omits migrated fill mileage $mileage"
done
note "step 7 PASS - the migration and every migrated fill survive restart"
note "PASS - populated migration preserved $source_count rows by count and content; backup $BACKUP"
