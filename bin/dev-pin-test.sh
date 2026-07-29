#!/usr/bin/env bash
# Rover/Obelisk dev-pin compatibility-unit checks.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OBELISK="${OBELISK_WORKTREE:-/tmp/rover-obelisk-2b72856e}"
EXPECTED_COMMIT="2b72856e9fc0ca50391eb653540edf6574bffd04"
EXPECTED_AST="c74bf1c911b61b7abb4de8c98b28b30d684e5e3c0b10a0c65f759f64ee9f93dd"

fail() { echo "dev-pin-test: FAIL - $*" >&2; exit 1; }
pass() { echo "dev-pin-test: PASS - $*"; }

[ -d "$OBELISK/.git" ] || [ -f "$OBELISK/.git" ] ||
  fail "Obelisk worktree missing at $OBELISK"

actual_commit="$(git -C "$OBELISK" rev-parse HEAD)"
[ "$actual_commit" = "$EXPECTED_COMMIT" ] ||
  fail "Obelisk worktree is $actual_commit (want $EXPECTED_COMMIT)"

upstream_ast="$(sha256sum "$OBELISK/desk/sur/obelisk-ast.hoon" | awk '{print $1}')"
[ "$upstream_ast" = "$EXPECTED_AST" ] ||
  fail "upstream dev AST SHA is $upstream_ast (want $EXPECTED_AST)"

rover_ast="$(sha256sum "$REPO/desk/sur/obelisk-ast.hoon" | awk '{print $1}')"
[ "$rover_ast" = "$EXPECTED_AST" ] ||
  fail "Rover AST SHA is $rover_ast (want $EXPECTED_AST)"

grep -q 'Working pin: Obelisk `dev` @ `2b72856e`' "$REPO/AGENTS.md" ||
  fail "AGENTS.md does not name the dev working pin"
grep -q 'Obelisk | `dev` @ `2b72856e`' "$REPO/README.md" ||
  fail "README substrate table does not name the dev pin"

pass "fixture 55 source gate - dev commit and compatibility mold SHA match"
