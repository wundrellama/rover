#!/usr/bin/env bash
# Install bootstrap fixtures for a dedicated fresh fake pier.
set -uo pipefail

PIER="${1:-}"
CASE="${2:-${ROVER_INSTALL_CASE:-deferred}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "install-bootstrap-test: FAIL - $*" >&2; exit 1; }
note() { echo "install-bootstrap-test: $*"; }

[ -n "$PIER" ] || fail "no pier given"
case "$(basename "$PIER")" in
  rover-install-*) ;;
  *) fail "the pier name must start with rover-install-; this fixture requires a dedicated fresh pier" ;;
esac
case "$CASE" in
  deferred|interim-lazy) ;;
  *) fail "unknown case '$CASE'; use deferred or interim-lazy" ;;
esac
[ -S "$PIER/.urb/conn.sock" ] || fail "no live conn.sock under $PIER"
[ -d "$PIER/rover" ] || fail "the dedicated pier has no mounted Rover desk"
[ -d "$PIER/obelisk" ] || fail "the dedicated pier has no mounted Obelisk desk"
command -v click >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || fail "click is not on PATH"

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || fail "the dedicated pier has no public HTTP port"
URL="http://localhost:$PORT"
JAR="$(mktemp /tmp/rover-install-cookie.XXXXXX)"
HDRS="$(mktemp /tmp/rover-install-headers.XXXXXX)"
BODY="$(mktemp /tmp/rover-install-view.XXXXXX.html)"
TRACE="$(mktemp /tmp/rover-install-trace.XXXXXX)"
trap 'rm -f "$JAR" "$HDRS" "$BODY" "$TRACE"' EXIT

resolve_pier_pane() {
  local target pid command
  while read -r target pid; do
    [ -r "/proc/$pid/cmdline" ] || continue
    command="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
    case "$command" in
      *" $PIER"*) printf '%s\n' "$target"; return 0 ;;
    esac
  done < <(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_pid}')
  return 1
}

capture_trace() {
  tmux capture-pane -pt "$PANE" -S -12000 | tr -d '\r' > "$TRACE"
}

wait_for_trace() {
  local marker="$1" attempt
  for attempt in $(seq 1 120); do
    capture_trace
    grep -q "$marker" "$TRACE" && return 0
    sleep 1
  done
  return 1
}

probe() {
  local file="$1"
  timeout 30 click -k -i "$REPO/probes/$file" "$PIER" 2>/dev/null | tail -1
}

read_database_report() {
  probe live-database-list.hoon
}

read_starter_report() {
  probe starter-report.hoon
}

database_exists() {
  grep -Fq "[%database %tas %$2]" <<<"$1"
}

starter_ready() {
  grep -Fq "[%label 116 'Gasoline']" <<<"$1" &&
    grep -Fq "[%label 116 'Diesel']" <<<"$1"
}

row_counts() {
  local report counts
  report="$(probe bootstrap-row-counts.hoon)"
  grep -q '%vector-count' <<<"$report" \
    || fail "the row-count instrument observed no result sets"
  counts="$(python3 -c 'import re, sys
text = sys.stdin.read()
markers = (
    "energy-definition-id", "subtype-id", "octane-subtype-id", "cetane-subtype-id", "blend-subtype-id",
    "consumable-id", "additive-id", "mode-id",
)
print(" ".join("{}={}".format(marker, len(re.findall(r"\[%" + marker + r" ", text))) for marker in markers))
' <<<"$report")"
  grep -Eq 'energy-definition-id=[1-9][0-9]*' <<<"$counts" \
    || fail "the row-count control was zero: $counts"
  printf '%s\n' "$counts"
}

wait_install_ready() {
  local attempt databases starters
  for attempt in $(seq 1 90); do
    databases="$(read_database_report)"
    if database_exists "$databases" rover; then
      starters="$(read_starter_report)"
      starter_ready "$starters" && return 0
    fi
    sleep 1
  done
  return 1
}

validate_trace() {
  local label="$1"
  [ -s "$TRACE" ] || fail "$label captured an empty trace"
  grep -q '%obelisk %poke]' "$TRACE" \
    || fail "$label captured no Obelisk poke lines; the instrument is blind"
}

count_pokes() {
  python3 -c 'import sys
lines = open(sys.argv[1], "rb").read().decode("utf-8").replace("\r", "").splitlines()
markers = (
    "rover-install-probe", "rover-install-pour",
    "rover-install-starter-check", "rover-install-starter-write",
    "rover-bootstrap-probe", "rover-bootstrap-pour",
    "rover-bootstrap-starter-check", "rover-bootstrap-starter-write",
    "rover-http",
)
def pokes(marker):
    return sum(
        marker in "\n".join(lines[index:index + 12])
        for index, line in enumerate(lines)
        if "%obelisk %poke]" in line
    )
def facts(marker):
    return sum(
        marker in "\n".join(lines[index:index + 12])
        for index, line in enumerate(lines)
        if "%unto %fact" in line
    )
print(facts(markers[0]), *(pokes(marker) for marker in markers[1:]))
' "$TRACE"
}

derive_code() {
  local attempt code
  tmux send-keys -t "$PANE" '+code' Enter
  for attempt in $(seq 1 30); do
    code="$(tmux capture-pane -pt "$PANE" -S -120 | tr -d '\r' | grep -xE '[a-z]{6}(-[a-z]{6}){3}' | tail -1)"
    [ -n "$code" ] && printf '%s\n' "$code" && return 0
    sleep 1
  done
  return 1
}

PANE="$(resolve_pier_pane)" || fail "the dedicated pier is not running under tmux"
tmux clear-history -t "$PANE"
tmux send-keys -t "$PANE" '|verb' Enter
sleep 2
tmux send-keys -t "$PANE" '|install our %rover' Enter
wait_for_trace 'gall: booted %rover' || fail "Rover did not boot from its explicit desk"

capture_trace
grep -q 'rover-install-probe' "$TRACE" \
  || fail "the trace observed no install probe"
grep -q 'not running %obelisk yet, got %watch' "$TRACE" \
  || fail "the trace observed no queued watch for absent Obelisk"
grep -q 'not running %obelisk yet, got %poke' "$TRACE" \
  || fail "the trace observed no queued poke for absent Obelisk"

CODE="$(derive_code)" || fail "could not derive the login code"
curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
grep -q urbauth "$JAR" || fail "login did not yield an Eyre cookie"
shell_probe="$(curl -sS -b "$JAR" -w $'\nROVER_HTTP_STATUS=%{http_code}' "$URL/apps/rover")"
grep -q 'id="rover-designation"' <<<"$shell_probe" \
  || fail "login did not reach the Rover shell"
grep -q 'ROVER_HTTP_STATUS=200' <<<"$shell_probe" \
  || fail "the authenticated Rover shell was not HTTP 200"

view_pid=''
if [ "$CASE" = interim-lazy ]; then
  curl -sS --max-time 300 -b "$JAR" -D "$HDRS" -o "$BODY" \
    "$URL/apps/rover/view" &
  view_pid=$!
  wait_for_trace 'rover-bootstrap-probe' \
    || fail "the waiting page did not queue a lazy bootstrap probe"
  capture_trace
  [ "$(grep -c 'not running %obelisk yet, got %poke' "$TRACE")" -ge 2 ] \
    || fail "the trace did not prove both queued pokes"
fi

tmux send-keys -t "$PANE" '|install our %obelisk' Enter

if [ "$CASE" = interim-lazy ]; then
  wait "$view_pid" || fail "the waiting lazy page failed after Obelisk started"
  grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "the lazy page did not return HTTP 200"
  grep -qi '^x-rover-bootstrap: performed' "$HDRS" \
    || fail "the lazy page did not carry the bootstrap marker"
  grep -q '>Gasoline</option>' "$BODY" || fail "the lazy page did not contain Gasoline"
  grep -q '>Diesel</option>' "$BODY" || fail "the lazy page did not contain Diesel"
  wait_for_trace 'rover-install-starter-write' \
    || fail "the first queued install did not finish its starter seed"
  sleep 2
  counts_before="$(row_counts)" || fail "the before-count instrument failed"
  capture_trace
  validate_trace "interim lazy bootstrap"
  read -r install_probes install_pours install_checks install_writes \
    bootstrap_probes bootstrap_pours bootstrap_checks bootstrap_writes view_pokes \
    < <(count_pokes)
  [ "$install_writes" -eq 1 ] \
    || fail "the initial install path sent $install_writes starter writes, want 1"
  [ "$bootstrap_writes" -eq 0 ] \
    || fail "the overlapping lazy path sent $bootstrap_writes starter writes, want 0"
  [ "$bootstrap_checks" -ge 2 ] \
    || fail "the lazy path sent $bootstrap_checks starter checks, want at least 2"

  suspend_result="$(probe suspend-obelisk.hoon)"
  [[ "$suspend_result" == *%obelisk-suspended* ]] \
    || fail "Obelisk suspension did not acknowledge: $suspend_result"
  tmux send-keys -t "$PANE" C-l
  tmux clear-history -t "$PANE"
  reinstall_result="$(probe reinstall-rover.hoon)"
  [[ "$reinstall_result" == *%rover-reinstalled* ]] \
    || fail "Rover reinstall did not acknowledge: $reinstall_result"
  wait_for_trace 'gall: booted %rover' || fail "the reinstalled Rover did not boot"
  capture_trace
  grep -q 'rover-install-probe' "$TRACE" \
    || fail "the reinstalled Rover emitted no install probe"
  grep -q 'not running %obelisk yet, got %poke' "$TRACE" \
    || fail "the late install probe was not queued against suspended Obelisk"

  revive_result="$(probe revive-obelisk.hoon)"
  [[ "$revive_result" == *%obelisk-revived* ]] \
    || fail "Obelisk revival did not acknowledge: $revive_result"
  install_probes=0
  for attempt in $(seq 1 60); do
    capture_trace
    if ! grep -q '%obelisk %poke]' "$TRACE"; then
      sleep 1
      continue
    fi
    read -r install_probes install_pours install_checks install_writes \
      bootstrap_probes bootstrap_pours bootstrap_checks bootstrap_writes view_pokes \
      < <(count_pokes)
    [ "$install_probes" -ge 1 ] && break
    sleep 1
  done
  [ "$install_probes" -eq 1 ] \
    || fail "the late queue delivered $install_probes install probes, want 1"
  validate_trace "late queued install probe"
  sleep 2
  counts_after="$(row_counts)" || fail "the after-count instrument failed"
  capture_trace
  validate_trace "late install completion"
  read -r install_probes install_pours install_checks install_writes \
    bootstrap_probes bootstrap_pours bootstrap_checks bootstrap_writes view_pokes \
    < <(count_pokes)
  [ "$install_probes" -eq 1 ] || fail "the late queue delivered $install_probes install probes, want 1"
  [ "$install_pours" -eq 0 ] || fail "the late install path sent $install_pours schema pours, want 0"
  [ "$install_checks" -eq 0 ] || fail "the late install path sent $install_checks starter checks, want 0"
  [ "$install_writes" -eq 0 ] \
    || fail "the late install completion sent $install_writes starter writes, want 0"
  [ "$counts_before" = "$counts_after" ] \
    || fail "the late install completion changed rows: before=$counts_before after=$counts_after"
  note "interim transcript - waiting-lazy-marker=performed initial-starter-writes=1 late-queued-install-probe=1 late-pours=0 late-starter-writes=0"
  note "row counts before late completion - $counts_before"
  note "row counts after late completion  - $counts_after"
  note "fixture 134 PASS - the waiting page observes one completed seed, and a later queued install probe changes no starter rows"
  exit 0
fi

wait_for_trace 'gall: booted %obelisk' || fail "Obelisk did not boot from its explicit desk"
wait_install_ready || fail "the queued install did not create and seed Rover"
counts="$(row_counts)" || fail "the deferred row-count instrument failed"
capture_trace
validate_trace "deferred install bootstrap"
read -r install_probes install_pours install_checks install_writes \
  bootstrap_probes bootstrap_pours bootstrap_checks bootstrap_writes view_pokes \
  < <(count_pokes)
[ "$install_probes" -eq 1 ] || fail "the queue delivered $install_probes install probes, want 1"
[ "$install_pours" -eq 1 ] || fail "the install path sent $install_pours schema pours, want 1"
[ "$install_checks" -eq 1 ] || fail "the install path sent $install_checks starter checks, want 1"
[ "$install_writes" -eq 1 ] || fail "the install path sent $install_writes starter writes, want 1"
[ "$bootstrap_probes" -eq 0 ] \
  || fail "the no-page phase sent $bootstrap_probes lazy probes, want 0"
[ "$view_pokes" -eq 0 ] || fail "the no-page phase sent $view_pokes view queries, want 0"

playwright_module="${ROVER_PLAYWRIGHT_MODULE:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules/playwright}"
chromium_binary="${ROVER_CHROMIUM:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
[ -f "$playwright_module/package.json" ] || fail "Playwright is unavailable at $playwright_module"
[ -x "$chromium_binary" ] || fail "Chromium is unavailable at $chromium_binary"
auth_name="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $6; exit}' "$JAR")"
auth_value="$(awk '$0 !~ /^#/ && $6 ~ /^urbauth-/ {print $7; exit}' "$JAR")"
tmux clear-history -t "$PANE"
normal_status="$({
  ROVER_PLAYWRIGHT_MODULE="$playwright_module" \
  ROVER_CHROMIUM="$chromium_binary" \
    node "$REPO/bin/ui-browser-fixtures.cjs" \
      bootstrap-status-normal "$URL" "$auth_name" "$auth_value" '' '' ''
} 2>&1)" || fail "the normal status was dishonest: $normal_status"
grep -q '^BOOTSTRAP_STATUS=' <<<"$normal_status" \
  || fail "the normal browser returned no status observation"
capture_trace
validate_trace "normal page after deferred install"
read -r _ _ _ _ bootstrap_probes _ _ _ view_pokes \
  < <(count_pokes)
[ "$view_pokes" -ge 1 ] || fail "the normal page trace had no positive view control"
[ "$bootstrap_probes" -eq 0 ] \
  || fail "the ready database sent $bootstrap_probes lazy probes, want 0"

note "deferred transcript - absent-watch=queued absent-poke=queued database=rover starters=Gasoline|Diesel no-page-bootstrap-probes=0"
note "starter row counts - $counts"
note "normal page transcript - ${normal_status#*BOOTSTRAP_STATUS=}"
note "fixture 132 PASS - starting Obelisk delivers the queued install and makes Rover ready before any page load"
