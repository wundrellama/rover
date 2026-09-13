#!/usr/bin/env bash
# Build a fresh Rover test pier from nothing, ready for bin/event-test.sh.
#
# bin/event-test.sh tests a PREPARED ship. It does not build one. Without this
# script the only way to run the battery is to reuse a pier a previous run
# already filled, and accumulated photos change the result: a pier that passes
# on its second run can kill the ship on its fifth, because fixture 86 builds
# the whole export archive in ship memory and that archive grows with every run.
#
#   usage: bin/build-test-pier.sh <pier-dir> <http-port> <ames-port> [loom]
#
# STANDING RULE: boot every pier with --loom 33 or 34. The default loom is too
# small for work this project does in ship memory. Fixture 86 builds the whole
# export archive there, and that archive grows with every battery run: a pier
# booted without a loom flag died at 368 MB after four runs, taking eight
# fixtures down with it. 33 is the default here; pass 34 for a large corpus.
#
# The pier directory must not exist. The script boots ~bel from the brass pill,
# mirrors the pinned Obelisk desk and this worktree's Rover desk, installs both,
# and leaves the ship running with a live conn.sock.
set -uo pipefail

PIER="${1:?pier directory}"
HTTP="${2:?http port}"
AMES="${3:?ames port}"
LOOM="${4:-33}"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
URBIT="$HOME/workspace/urbit/bin/urbit"
PILL="/var/home/michael/workspace/urbit/pills/brass-408k-1.pill"
OBELISK="/var/home/michael/workspace/urbit/pins/obelisk-fresh/desk"
SESSION="$(basename "$PIER")"

# The shared local RustFS the battery's S3 fixtures write to. Override in the
# environment when the bucket lives somewhere else.
S3_ENDPOINT="${ROVER_S3_ENDPOINT:-http://localhost:9200}"
S3_BUCKET="${ROVER_S3_BUCKET:-rover-attachments}"
S3_REGION="${ROVER_S3_REGION:-us-east-1}"
S3_KEY="${ROVER_S3_KEY:-roverm8key}"
S3_SECRET="${ROVER_S3_SECRET:-roverm8secret123}"

die() { echo "build-test-pier: $*" >&2; exit 1; }

[ -e "$PIER" ] && die "$PIER already exists; this script builds a FRESH pier"
[ -x "$URBIT" ] || die "no urbit binary at $URBIT"
[ -f "$PILL" ] || die "no pill at $PILL"
[ -d "$OBELISK" ] || die "no pinned Obelisk desk at $OBELISK"
command -v click >/dev/null || die "click is not on PATH"

PIER="$(mkdir -p "$(dirname "$PIER")" && cd "$(dirname "$PIER")" && pwd)/$(basename "$PIER")"

echo "build-test-pier: booting ~bel at $PIER (http $HTTP, ames $AMES, loom $LOOM)"
tmux kill-session -t "$SESSION" 2>/dev/null
tmux new-session -d -s "$SESSION" -x 200 -y 50 \
  "script -qfc '$URBIT -F bel -B $PILL --loom $LOOM --http-port $HTTP -p $AMES -c $PIER' /dev/null"

for _ in $(seq 1 120); do
  [ -S "$PIER/.urb/conn.sock" ] && break
  sleep 5
done
[ -S "$PIER/.urb/conn.sock" ] || die "no conn.sock after 10 minutes"
sleep 20

dojo() { tmux send-keys -t "$SESSION" "$1" Enter; sleep "${2:-5}"; }

echo "build-test-pier: mirroring the pinned Obelisk desk"
# `|merge` alone leaves the desk unmounted, and `|commit` on an unmounted desk
# answers "kiln: desk not live". Mount first, THEN copy, THEN commit. The
# empty-directory sweep has to run after the copy, not before it: a stale empty
# app/debug/ makes Gall try to compile /app//hoon.
dojo '|merge %obelisk our %base' 12
dojo '|mount %obelisk' 12
rm -rf "$PIER/obelisk"/* 2>/dev/null
cp -r "$OBELISK"/* "$PIER/obelisk/"
find "$PIER/obelisk" -type d -empty -delete
dojo '|commit %obelisk' 40
# A freshly merged desk installs SUSPENDED. `|start` cannot wake it and Rover
# then logs "gall: not running %obelisk yet" on every watch and poke, which
# surfaces as fixture 1 failing with a gateway timeout. `|revive` is the arm
# that boots the agents on a suspended desk.
dojo '|revive %obelisk' 45

echo "build-test-pier: mirroring the Rover desk from $REPO"
dojo '|merge %rover our %base' 10
dojo '|mount %rover' 8
rm -rf "$PIER/rover"/* 2>/dev/null
cp -r "$REPO/desk"/* "$PIER/rover/"
find "$PIER/rover" -type d -empty -delete
dojo '|commit %rover' 30
dojo '|install our %rover' 25

echo "build-test-pier: pointing %storage at the local RustFS bucket"
# Fixture 100 tests the S3 backend end to end and answers HTTP 409
# (storage-unconfigured) on a pier that has no bucket. A pier is not ready for
# the battery until Rover reports the s3 backend available.
for poke in \
  "[%set-endpoint '$S3_ENDPOINT']" \
  "[%set-access-key-id '$S3_KEY']" \
  "[%set-secret-access-key '$S3_SECRET']" \
  "[%add-bucket '$S3_BUCKET']" \
  "[%set-current-bucket '$S3_BUCKET']" \
  "[%set-region '$S3_REGION']" ; do
  dojo ":storage &storage-action $poke" 3
done

echo "build-test-pier: waiting for the agent to answer"
ready=no
for _ in $(seq 1 40); do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://localhost:$HTTP/apps/rover/view")"
  # 303 is the auth fence, which means the agent is installed and serving.
  [ "$code" = 303 ] && { ready=yes; break; }
  sleep 10
done
[ "$ready" = yes ] || die "the Rover view never answered on port $HTTP"

echo "build-test-pier: READY  pier=$PIER  http=$HTTP  tmux=$SESSION"
