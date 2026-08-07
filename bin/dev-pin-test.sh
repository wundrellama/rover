#!/usr/bin/env bash
# Rover/Obelisk pin compatibility-unit checks.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OBELISK="${OBELISK_WORKTREE:-/tmp/obelisk-fresh}"
EXPECTED_COMMIT="9de633299b373a1047490b48281a40b457fb2043"
EXPECTED_AST="e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2"

fail() { echo "dev-pin-test: FAIL - $*" >&2; exit 1; }
pass() { echo "dev-pin-test: PASS - $*"; }

[ -d "$OBELISK/.git" ] || [ -f "$OBELISK/.git" ] ||
  fail "Obelisk worktree missing at $OBELISK"

actual_commit="$(git -C "$OBELISK" rev-parse HEAD)"
[ "$actual_commit" = "$EXPECTED_COMMIT" ] ||
  fail "Obelisk worktree is $actual_commit (want $EXPECTED_COMMIT)"

upstream_ast="$(sha256sum "$OBELISK/desk/sur/obelisk-ast.hoon" | awk '{print $1}')"
[ "$upstream_ast" = "$EXPECTED_AST" ] ||
  fail "upstream AST SHA is $upstream_ast (want $EXPECTED_AST)"

rover_ast="$(sha256sum "$REPO/desk/sur/obelisk-ast.hoon" | awk '{print $1}')"
[ "$rover_ast" = "$EXPECTED_AST" ] ||
  fail "Rover AST SHA is $rover_ast (want $EXPECTED_AST)"

grep -q 'Working pin: Obelisk `master` @ `9de6332` (v0.9.0-beta)' "$REPO/AGENTS.md" ||
  fail "AGENTS.md does not name the v0.9.0-beta working pin"
grep -q 'Obelisk | `master` @ `9de6332` (v0.9.0-beta)' "$REPO/README.md" ||
  fail "README substrate table does not name the v0.9.0-beta pin"

pass "fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match"
