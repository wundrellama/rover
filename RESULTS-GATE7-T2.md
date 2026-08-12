# Rover Gate 7 T2 results

Date: 2026-08-11. Branch: `ab-gate7-t2-opus`. Worktree: `/tmp/g7t2-opus`.

Pier: `~/piers/rover-t2-opus-bel`. Fresh disposable fake `~bel`, Ames port
31421, pill `brass-408k-1.pill`, booted this run under tmux session
`t2opus`. Obelisk `master` at
`9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta), installed from
`/tmp/obelisk-fresh` and started with `|start %obelisk %obelisk`. HTTP
port 8086, read from the boot log. The owner baseline is `%init-db` plus
`%seed-starters`, both KEEP arms.

## Slice log

### Slice a - the 21 readback and diagnostic actions

Deleted from the union, the poke handlers, and `lib/rover-act.hoon`:

- Readbacks (16): `app-structure-report`, `display-preference-report`,
  `charging-cost-report`, `charging-evidence-report`,
  `consumption-report`, `fuel-evidence-report`, `location-report`,
  `pricing-report`, `fill-edit-report`, `station-report`,
  `consumable-report`, `charge-subtype-report`,
  `vehicle-settings-report`, `demo-starter-report`, `starter-report`,
  `consumable-starter-report`.
- Diagnostics (5): `run-integrity`, `try-second-app-default`,
  `content-report`, `vehicle-history`, `current-odometer`.

The whole call chain went with them: the `integrity-*` script builders,
the `+$ integrity-ids` id block, the result cooking for
`vehicle-history` and `current-odometer` in the `[%rover *]` fact
handler, and the now-orphaned `order-results`, `order-command-results`,
`latest-results`, and `latest-command-results` arms. `order-vectors` and
`vector-key` stay because `lib/rover-view.hoon` calls them.

`validate-acquisition-subtypes` stays. It encodes the ratified subtype
XOR invariant, and the T1 probes `integrity-zero-subtype` and
`integrity-two-subtypes` build the lib and call it directly, per the
arm-level-probe pattern the plan sanctions. Deleting it would delete the
T1 replacement for the two Rover-side `run-integrity` scenarios.

Union count after slice a: 22. `lib/rover-act.hoon`: 3.304 to 2.821
lines.

Verification, real output:

```text
$ click -k -i probes/compile-rover.hoon ~/piers/rover-t2-opus-bel
[0 %avow 0 %noun 0]

$ ROVER_DEMO_ONLY=1 bash bin/ui-test.sh ~/piers/rover-t2-opus-bel
...
ui-test: fixture 92 PASS - at 390px the reorganised settings has no horizontal overflow and every enabled touch target is at least 44px
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - all 89 defined fixtures executed
EXIT=0        (grep -ci FAIL = 0, 94 PASS notes)

$ bash bin/schema-test.sh ~/piers/rover-t2-opus-bel
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed

$ bash bin/import-test.sh ~/piers/rover-t2-opus-bel
import-test: fixture 6 PASS - provenance exists only for imports and never appears in rendered HTML
import-test: fixture 7 PASS - suspend/revive preserved imported rows and provenance
import-test: COVERAGE - all 7 defined import fixtures executed

$ bash bin/dev-pin-test.sh
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match
```
