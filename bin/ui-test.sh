#!/usr/bin/env bash
# Rover browser-half fixtures over real Eyre. No loopback auto-auth and no mocks.
set -uo pipefail

PIER="${1:-$HOME/piers/rover-bel}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "ui-test: FAIL - $*" >&2; exit 1; }
note() { echo "ui-test: $*"; }

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

CODE="$(derive_code "$PIER")"
[ -n "$CODE" ] || fail "could not derive +code"
JAR="$(mktemp /tmp/rover-ui-cookie.XXXXXX)"
HDRS="$(mktemp /tmp/rover-ui-headers.XXXXXX)"
cleanup() { rm -f "$JAR" "$HDRS"; }
trap cleanup EXIT

response="$(curl -s -o /dev/null -w '%{http_code} %{size_download} %{redirect_url}' "$URL/apps/rover")"
case "$response" in
  "303 0 $URL/~/login?redirect="*) ;;
  *) fail "logged-out GET /apps/rover -> '$response' (want 303, empty login redirect)" ;;
esac
note "logged-out browser receives login redirect with no Rover body"

curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
grep -q urbauth "$JAR" || fail "login with +code did not yield urbauth cookie"

body="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "authenticated GET /apps/rover not 200"
grep -qi '^content-type: text/html' "$HDRS" || fail "shell content-type is not text/html"
grep -q 'ROVER' <<<"$body" || fail "served shell has no Rover designation"
note "PASS - authenticated Rover shell served over real Eyre"
