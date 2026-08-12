#!/usr/bin/env bash
# Coverage gate for bin/ui-test.sh — sourced from its final line.
#
# Fixtures live behind env gates (ROVER_DEMO_ONLY, ROVER_LEGACY_ONLY,
# ROVER_FIXTURE_STOP, ...). On 2026-07-29 a plain run exited 0 with zero
# failures while silently never executing fixtures 63-67 and 69: they sat
# inside a ROVER_DEMO_ONLY block. A green run that skipped a third of its
# fixtures is worse than a red one, because it looks finished.
#
# Compares fixtures DEFINED in ui-test.sh against those that actually
# reported through note(), and names the gap.

_cov_script="$(dirname "${BASH_SOURCE[0]}")/ui-test.sh"

# comm compares lexically, so both lists are sorted lexically here and only the
# report is sorted numerically. Sorting the comm inputs with -n made comm reject
# its own input once fixture numbers reached three digits, and every fixture
# above 99 was then reported as skipped while it had just passed.
_cov_defined="$(grep -oE '"fixture [0-9]+ (PASS|FAIL)' "$_cov_script" \
  | grep -oE '[0-9]+' | sort -u)"
_cov_ran="$(printf '%s\n' ${_ROVER_RAN:-} | grep -E '^[0-9]+$' | sort -u)"

_cov_total="$(printf '%s\n' "$_cov_defined" | grep -c '[0-9]')"
_cov_run_n="$(printf '%s\n' "$_cov_ran" | grep -c '[0-9]')"

_cov_missing="$(comm -23 \
  <(printf '%s\n' "$_cov_defined" | grep '[0-9]') \
  <(printf '%s\n' "$_cov_ran" | grep '[0-9]') | sort -n | tr '\n' ' ')"

if [ -n "${_cov_missing// /}" ]; then
  note "COVERAGE - ran $_cov_run_n of $_cov_total defined fixtures"
  note "COVERAGE - SKIPPED, not executed this run: ${_cov_missing% }"
  note "COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>"
else
  note "COVERAGE - all $_cov_total defined fixtures executed"
fi
