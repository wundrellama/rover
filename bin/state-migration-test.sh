#!/usr/bin/env bash
# Exercise the Rover v15 to v16 state migration on a real fake pier.
set -uo pipefail

PIER="${1:-${ROVER_PIER:-}}"
SESSION="${2:-${ROVER_TMUX_SESSION:-}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
V15_REF="ec318141c047ebc36383d93071b896d5353a6690"

if [ -z "$PIER" ] || [ -z "$SESSION" ]; then
  cat >&2 <<'USAGE'
state-migration-test: the pier and tmux session are required.

  usage: bin/state-migration-test.sh <pier> <tmux-session>
USAGE
  exit 2
fi

fail() { echo "state-migration-test: FAIL - $*" >&2; exit 1; }
pass() { echo "state-migration-test: PASS - $*"; }

[ -S "$PIER/.urb/conn.sock" ] || fail "the pier has no conn.sock"
[ -d "$PIER/rover" ] || fail "the Rover desk is not mounted"
tmux has-session -t "$SESSION" 2>/dev/null || fail "the tmux session is absent"
command -v click >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || fail "click is not available"
command -v urbit >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v urbit >/dev/null 2>&1 || fail "urbit is not available"

TASK_TMP="$(mktemp -d /tmp/rover-state-migration.XXXXXX)"
JAR="$TASK_TMP/cookie"
CURL_OUT="$TASK_TMP/charge-response"
CURL_PID=""
OBELISK_SUSPENDED=0

cleanup() {
  if [ -n "$CURL_PID" ] && kill -0 "$CURL_PID" 2>/dev/null; then
    kill "$CURL_PID" 2>/dev/null || true
    wait "$CURL_PID" 2>/dev/null || true
  fi
  if [ "$OBELISK_SUSPENDED" -eq 1 ]; then
    control_obelisk revive >/dev/null 2>&1 || true
  fi
  rm -rf "$TASK_TMP"
}
trap cleanup EXIT

click_file() {
  local body="$1" file out
  file="$TASK_TMP/thread-$(date +%s%N).hoon"
  printf '%s\n' "$body" > "$file"
  out="$(click -k -i "$file" "$PIER" 2>/dev/null | tail -1)"
  printf '%s\n' "$out"
}

commit_rover() {
  local out
  out="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %hood] %kiln-commit !>([%rover |]))
(pure:m !>(%synced))')"
  grep -q '%synced' <<<"$out" || fail "the Rover desk commit failed: $out"
}

control_obelisk() {
  local action="$1" out
  out="$(click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %hood] %kiln-$action !>(\`@tas\`%obelisk))
(pure:m !>(%$action))")"
  grep -q "%$action" <<<"$out" || fail "Obelisk did not $action: $out"
}

obelisk_query() {
  local query="$1"
  click_file "=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-state-migration-query
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector \"$query\"]))
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

git -C "$REPO" cat-file -e "$V15_REF^{commit}" 2>/dev/null \
  || fail "the v15 source commit is absent"
git -C "$REPO" archive "$V15_REF" desk | tar -x -C "$TASK_TMP"
grep -q '^++  on-save  !>(\[%15 state\])' "$TASK_TMP/desk/app/rover.hoon" \
  || fail "the archived app is not state version 15"

rsync -a --delete "$TASK_TMP/desk/" "$PIER/rover/"
find "$PIER/rover" -type d -empty -delete
commit_rover

before_boot="$(tmux capture-pane -t "$SESSION" -p -S -2000 | grep -c 'gall: booted %rover' || true)"
tmux send-keys -t "$SESSION" C-e C-u
tmux send-keys -t "$SESSION" -l '|install our %rover'
tmux send-keys -t "$SESSION" Enter
sleep 3
tmux send-keys -t "$SESSION" C-e C-u
tmux send-keys -t "$SESSION" -l '|start %rover %rover'
tmux send-keys -t "$SESSION" Enter
for ignored in $(seq 1 120); do
  after_boot="$(tmux capture-pane -t "$SESSION" -p -S -2000 | grep -c 'gall: booted %rover' || true)"
  [ "$after_boot" -gt "$before_boot" ] && break
  sleep 1
done
[ "${after_boot:-0}" -gt "$before_boot" ] || fail "the v15 Rover agent did not boot"

baseline="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
;<  ~  bind:m  (sleep ~s10)
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
;<  ~  bind:m  (sleep ~s10)
(pure:m !>(%baseline-ready))')"
grep -q '%baseline-ready' <<<"$baseline" || fail "the v15 owner baseline failed"

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || fail "the Eyre public port is absent"
URL="http://localhost:$PORT"
CODE="$(derive_code)"
[ -n "$CODE" ] || fail "the login code is unavailable"
curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
grep -q urbauth "$JAR" || fail "the login did not create an auth cookie"

vehicle_response="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"label":"Migration Charge Vehicle","energy":"Electricity"}' \
  "$URL/apps/rover/add-vehicle")"
[ "$vehicle_response" = $'Added vehicle - Migration Charge Vehicle\n201' ] \
  || fail "the v15 agent could not create durable data: $vehicle_response"

before_query="$(obelisk_query "FROM vehicles V WHERE V.label = 'Migration Charge Vehicle' SELECT V.label;")"
grep -q "Migration Charge Vehicle" <<<"$before_query" \
  || fail "the durable vehicle is absent before the upgrade"

control_obelisk suspend >/dev/null
OBELISK_SUSPENDED=1
curl -sS --max-time 45 -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Migration Charge Vehicle","definition":"Electricity","start":"2026-08-11T20:00","end":"2026-08-11T20:01","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"free","currency":"usd"}' \
  "$URL/apps/rover/add-charge" > "$CURL_OUT" 2>&1 &
CURL_PID=$!
sleep 3
kill -0 "$CURL_PID" 2>/dev/null || fail "the charge request did not stay in flight"

rsync -a --delete "$REPO/desk/" "$PIER/rover/"
find "$PIER/rover" -type d -empty -delete
commit_rover
sleep 8

control_obelisk revive >/dev/null
OBELISK_SUSPENDED=0
wait "$CURL_PID" 2>/dev/null || true
CURL_PID=""
charge_response="$(cat "$CURL_OUT")"
[ "$charge_response" = $'Rover restarted while saving. Please submit again.\n503' ] \
  || fail "the migrated request did not receive the restart response: ${charge_response:-<no response>}"
pass "the v15 charge request received the human 503 response after the v16 upgrade"

after_query="$(obelisk_query "FROM vehicles V WHERE V.label = 'Migration Charge Vehicle' SELECT V.label;")"
grep -q "Migration Charge Vehicle" <<<"$after_query" \
  || fail "the durable vehicle did not survive the upgrade"
pass "durable Obelisk data survived the v15 to v16 state migration"
