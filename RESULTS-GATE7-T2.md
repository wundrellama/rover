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

### Slice b - the 11 seed actions

Deleted from the union, the poke handlers, and `lib/rover-act.hoon`:

- The six re-driven seeds: `seed-spike`, `seed-app-structure`,
  `seed-charging-cost`, `seed-demo-fuel`, `seed-demo-def`,
  `seed-fill-edit-support`. The T1 battery already creates their state
  through the 17 product endpoints.
- The five exempt seeds, per the 2026-08-11 ruling: `seed-fuel-evidence`,
  `seed-charging-evidence`, `seed-consumption`, `seed-location`,
  `seed-pricing`. Their areas leave M0 for M1. The relations stay in the
  pour.

The call chains went too: the nine `+$ *-ids` blocks, the
`demo-fuel-check`, `repair-demo-fuel`, `demo-def-check`,
`demo-def-purchase`, `demo-fill`, and `fill-edit-support-lookup`
helpers, and the three `on-agent` wires `%rover-demo-fuel`,
`%rover-demo-def`, and `%rover-fill-edit-support`.

Probe files deleted: the nine superseded seed probes
(`seed-spike`, `seed-app-structure`, `seed-charging-cost`,
`seed-charging-evidence`, `seed-consumption`, `seed-demo-fuel`,
`seed-fuel-evidence`, `seed-location`, `seed-pricing`) and the five
exempt-area report probes (`fuel-evidence-report`,
`charging-evidence-report`, `consumption-report`, `location-report`,
`pricing-report`). T1 measured those five reports as empty result sets
on a fence-clean pier, so no assertion is lost.

Union count after slice b: 11. `lib/rover-act.hoon`: 2.821 to 2.209
lines.

Verification, real output (`/tmp/t2-slice-b.log`):

```text
$ click -k -i probes/compile-rover.hoon ~/piers/rover-t2-opus-bel
[0 %avow 0 %noun 0]

ui-test: COVERAGE - all 89 defined fixtures executed
UI_EXIT=0        (zero FAIL lines)
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
SCHEMA_EXIT=0
import-test: COVERAGE - all 7 defined import fixtures executed
IMPORT_EXIT=0
```

### Slice c - calculator wrappers, renames, test files

The four calculator poke wrappers are deleted. The grep evidence for
each arm, run before the cut:

- `derive-fill-total:act` - product callers in `lib/rover-view.hoon`
  (1555, 2143, 2653), `lib/rover-import.hoon` (245), and the
  consumable, edit-fill, and fill write handlers in `app/rover.hoon`.
  **Arm kept.**
- `derive-charging-total:act` - product callers in
  `lib/rover-entry.hoon` (1250, the real add-charge product path),
  `lib/rover-view.hoon` (1701), and the charge write handler in
  `app/rover.hoon`. The plan's only-the-poke-calls-it note was stale, as
  the task brief warned. **Arm kept.**
- `preview-us:act`, `preview-eur:act` - after the wrappers and
  `gen/test-pricing.hoon` went, the only callers were the two
  `pricing-preview` probes, which are host-side scaffolding. No product
  path uses them. **Arms deleted**, with the two probes and the
  now-orphaned `format-mills` helper in `rover-act` (`rover-render` has
  its own, which the product keeps using).

`rename-energy-source` and `rename-consumable` are deleted per the
2026-08-12 ruling: union entries, poke handlers, the
`%rover-energy-rename` and `%rover-consumable-rename` wires, and the
`energy-definition-lookup`, `consumable-definition-lookup`,
`rename-energy-definition`, and `rename-consumable-definition` arms.

Battery fixtures removed with the renames:

- **Fixture 35** asserted that an owner rename of `Gasoline` survived a
  `seed-starters` re-seed. Every assertion depends on the renamed label,
  so the fixture came out whole, with its two rename pokes, its re-seed
  poke, and the rename-back poke. The fixture 33 vehicle cleanup that
  sat inside the same region stays.
- **Fixture 54** asserted the same for a `DEF` consumable rename. Same
  removal, plus the now-unused `read_consumable_starter_report` helper
  and `URQL_CONSUMABLE_STARTER` block.

The battery now pokes `%rover-action` three times, not the five the
task predicted: `init-db` x1 and `seed-starters` x2. The two missing
`seed-starters` pokes were the fixture 35 and fixture 54 re-seed pokes.
They existed only to prove a rename survives a re-seed, so they went
with their fixtures rather than staying as pokes with no assertion.

In-desk test files deleted: `desk/gen/test-entry.hoon`,
`test-import.hoon`, `test-pricing.hoon`, `test-render.hoon`, and
`desk/tests/lib/rover-enums.hoon`. Neither `desk.bill` nor
`app/rover.hoon` referenced them. Their host-side runner probes went
too: `compile-test-*`, `run-test-*`, and `compile-rover-enums`.

One dependency surfaced during the cut: `probes/rating-scale-report.hoon`
(the ratified import Q2 ignition-mode fixture) built the deleted
`tests/lib/rover-enums.hoon` mirror. The probe now builds
`lib/rover-act.hoon` and maps the eight energy labels through the live
`+rating-scale-for` product arm, so the assertion survives and reads
the real lookup instead of a mirror:

```text
$ click -k -i probes/rating-scale-report.hoon ~/piers/rover-t2-opus-bel
[0 %avow 0 %noun ['Gasoline' 0 %octane] ['Ethanol' 0 %octane] ['Propane' 0 %octane] ['Diesel' 0 %cetane] ['Electricity' 0] ['Hydrogen' 0] ['CNG' 0] ['LNG' 0] 0]
```

Union count after slice c: **5**. `lib/rover-act.hoon`: 2.209 to 2.138
lines.

Verification, real output (`/tmp/t2-slice-c.log`):

```text
$ click -k -i probes/compile-rover.hoon ~/piers/rover-t2-opus-bel
[0 %avow 0 %noun 0]

ui-test: COVERAGE - all 87 defined fixtures executed
UI_EXIT=0        (zero FAIL lines; 87 = 89 minus removed fixtures 35 and 54)
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
SCHEMA_EXIT=0
import-test: COVERAGE - all 7 defined import fixtures executed
IMPORT_EXIT=0
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match
PIN_EXIT=0
```
