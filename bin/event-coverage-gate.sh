#!/usr/bin/env bash
# Coverage gate for bin/event-test.sh - sourced from its final line.
#
# Compares fixtures DEFINED in event-test.sh against those that reported
# through note(), and names the gap. A green run that skipped fixtures is
# worse than a red one, because it looks finished.

_cov_script="$(dirname "${BASH_SOURCE[0]}")/event-test.sh"

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
else
  note "COVERAGE - all $_cov_total defined fixtures executed"
fi
