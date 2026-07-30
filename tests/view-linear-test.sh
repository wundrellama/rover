#!/usr/bin/env bash
# Fast structural guard for the view's measured quadratic regression.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$REPO/desk/lib/rover-view.hoon"

fail() {
  echo "view-linear-test: FAIL - $*" >&2
  exit 1
}

grep -q '^++  derive-fill-series$' "$VIEW" \
  || fail "missing the single ordered economy derivation pass"

statistics_body="$(
  sed -n '/^++  statistic-interval-rows$/,/^++  statistic-fill-rows$/p' "$VIEW"
  sed -n '/^++  statistic-fill-rows$/,/^++  statistics-screen$/p' "$VIEW"
)"
grep -q 'derivations=(map @ derived-fill)' <<<"$statistics_body" \
  || fail "statistics do not consume the request-local derivation index"
if grep -Eq '[(](economy-for-fill|interval-for-fill|fill-interval-break-reason) ' \
    <<<"$statistics_body"; then
  fail "statistics still repeat whole-history interval walks"
fi

grep -q 'history-window-size.*25' "$VIEW" \
  || fail "default history/statistics render is not bounded to 25 rows"
grep -q 'order-vectors:act %observed-start %.y' "$VIEW" \
  || fail "default history is not newest-first"
grep -q 'data-view-page' "$VIEW" \
  || fail "the bounded window has no older/newer pagination controls"
grep -q 'history-page=@ud' "$VIEW" \
  || fail "the renderer cannot select a requested history page"

echo "view-linear-test: PASS - one-pass derivation feeds a bounded newest-first view"
