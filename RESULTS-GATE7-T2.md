# Rover Gate 7 T2 results

Gate 7 T2 is complete on branch `ab-gate7-t2-sol` from `b41ce9a`. The
shipping desk exposes five actions, carries no `test-*` file, and passes the
real-substrate batteries on the assigned fresh `~bel` pier.

## Deletion sweep

The 21 MOVE-TO-PROBE actions are gone from the action mold, poke dispatch,
agent wires, response handlers, and `lib/rover-act.hoon` call chains.

- Readbacks: `app-structure-report`, `display-preference-report`,
  `charging-cost-report`, `charging-evidence-report`, `consumption-report`,
  `fuel-evidence-report`, `location-report`, `pricing-report`,
  `fill-edit-report`, `station-report`, `consumable-report`,
  `charge-subtype-report`, `vehicle-settings-report`, `demo-starter-report`,
  `starter-report`, and `consumable-starter-report`.
- Diagnostics: `run-integrity`, `try-second-app-default`, `content-report`,
  `vehicle-history`, and `current-odometer`.

The 11 RE-DRIVE actions and their orphaned fixture arms are gone.

- Re-driven by T1: `seed-charging-cost`, `seed-app-structure`,
  `seed-fill-edit-support`, `seed-demo-fuel`, `seed-demo-def`, and
  `seed-spike`.
- Exempt and deferred by the 2026-08-11 ruling: `seed-fuel-evidence`,
  `seed-charging-evidence`, `seed-consumption`, `seed-location`, and
  `seed-pricing`.

The four calculator poke wrappers are gone: `derive-fill-total`,
`derive-charging-total`, `preview-us`, and `preview-eur`.

The two ruled rename actions are also gone: `rename-energy-source` and
`rename-consumable`. Their lookup, update, wire, and response arms were removed.
Battery fixtures 35 and 54 went with them because their only assertions were
rename and rename-survives-reseed behavior. Their two `seed-starters` calls
remain. No other battery assertion was changed or removed.

The final battery poke evidence is exactly five calls:

```text
387:;<  ~  bind:m  (poke [our %rover] %rover-action !>([%init-db ~]))
389:;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
1635:;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
1874:;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
2329:;<  ~  bind:m  (poke [our %rover] %rover-action !>([%seed-starters ~]))
```

The four in-desk test generators and `desk/tests/lib/rover-enums.hoon` were
deleted after confirming that neither `desk.bill` nor `app/rover.hoon`
referenced them. Host probes that built those deleted files were deleted too.
Preview and Rover-side XOR probes were removed when their now-orphaned arms
left the shipping library. The five exempt report probes and superseded seed
probes also left the host probe set.

## Calculator caller audit

`derive-fill-total:act` stays. It has product callers in the app, import, and
view paths:

```text
desk/app/rover.hoon:1106:        %:  derive-fill-total:act
desk/app/rover.hoon:1588:        %:  derive-fill-total:act
desk/app/rover.hoon:3038:        %:  derive-fill-total:act
desk/lib/rover-import.hoon:245:    %:  derive-fill-total:act
desk/lib/rover-view.hoon:1555:    %:  derive-fill-total:act
desk/lib/rover-view.hoon:2143:    %:  derive-fill-total:act
desk/lib/rover-view.hoon:2653:    %:  derive-fill-total:act
```

`derive-charging-total:act` stays. The current product callers confirm both the
M0-CC entry path and rendered views:

```text
desk/app/rover.hoon:2180:            =/  proof  (derive-charging-total:act amounts)
desk/lib/rover-entry.hoon:1250:  =/  balance  (mule |.((derive-charging-total:act amounts)))
desk/lib/rover-view.hoon:1701:    =/  proof  (derive-charging-total:act amounts)
```

Whole-desk searches returned no `preview-us:act` or `preview-eur:act` caller
after their wrappers were deleted. Both preview arms were therefore deleted.

## Silent-drop fix and migration fixture

`restart-http` answers 503 as `text/plain` with this body:

```text
Rover restarted while saving. Please submit again.
```

Every handler with a secondary pending-input lookup now separates the two
failure cases. A missing `eyre-id` still returns bare `this`. A live `eyre-id`
with a missing input deletes the `http-pending` key and sends the human 503.

The source differs from the stale plan count. There are 25 handlers that read
`http-pending`, but only 16 have a secondary pending-input lookup that can be
lost during migration. Those 16 handlers changed. They contain 17 restart
branches because `rover-fill-lookup` reads both `fill-pending` and
`fill-body-pending`. The remaining nine handlers have no secondary pending
input to lose.

`bin/state-migration-test.sh` installs the last v15 source
(`ec318141c047ebc36383d93071b896d5353a6690`) on the assigned pier, establishes
the owner baseline, writes a durable vehicle through Eyre, suspends Obelisk to
hold an `add-charge` request in flight, and commits the v16 desk. The upgrade
keeps `http-pending`, drops the v15 charge input, and must answer that original
caller instead of hanging. The fixture then queries real Obelisk for the
durable vehicle.

The required red run before the fix was:

```text
state-migration-test: FAIL - the migrated request did not receive the restart response: curl: (28) Operation timed out after 45001 milliseconds with 0 bytes received
000
```

The final clean run was:

```text
state-migration-test: PASS - the v15 charge request received the human 503 response after the v16 upgrade
state-migration-test: PASS - durable Obelisk data survived the v15 to v16 state migration
```

This one real-pier fixture supplies both the missing-input 503 proof and the
15-to-16 migration proof.

## Size and fence counts

```text
union-before=43
union-after=5
act-before=3304
act-after=2180
test-files=0
action-pokes=5
non-ascii=0
```

`lib/rover-act.hoon` shed 1,124 lines. The five action entries are
`init-db`, `ensure-ui-schema`, `ensure-def-schema`, `seed-starters`, and
`verify-schema`.

## Verification ledger

The disposable pier was `/var/home/michael/piers/rover-t2-sol-bel`, fake
`~bel`, under tmux session `rover-t2-sol-bel`, with Ames port 31420. The HTTP
port read from the boot log was 8085. Obelisk ran as its own desk and was
started explicitly with `|start %obelisk %obelisk`.

The substrate pin and copied mold match:

```text
pin=9de633299b373a1047490b48281a40b457fb2043
ast-sha=e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2  desk/sur/obelisk-ast.hoon
```

### Gate 1: compile the shipped Rover desk

```text
$ click -k -i probes/compile-rover.hoon /var/home/michael/piers/rover-t2-sol-bel
[0 %avow 0 %noun 0]
```

### Gate 2: real Eyre and Obelisk battery

The command exited 0 with no FAIL line. Its final output was:

```text
ui-test: fixture 109 PASS - a real browser fills repeatable itemized component rows, previews the exact derived total, and saves it through Eyre
ui-test: fixture 89 PASS - Enable DEF and DEF tank size are separate labelled controls and DEFDEF is absent
ui-test: fixture 90 PASS - default energy is inside its source group and Rover rejects a forged disallowed default before writing
ui-test: fixture 91 PASS - Fuel System contains subtype, tank size, units, and refill reserve and precedes Energy Sources, Driving Modes, and DEF
ui-test: fixture 92 PASS - at 390px the reorganised settings has no horizontal overflow and every enabled touch target is at least 44px
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - all 87 defined fixtures executed
```

### Gate 3: schema battery

```text
schema-test: PASS - SQL/Hoon parity is 68/68 relations; DDL has 75 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

### Gate 4: import battery

```text
import-test: fixture 1 PASS - seeded-parent reconciliation landed two missing energy subtypes plus the real 13-simple-definition shape, six fills, ratings, optional children, parts-only address, and no display preferences
import-test: fixture 2 PASS - one import created 51 places, two vehicles, and one fill with apostrophe-bearing labels plus a multiline note; its re-import was a no-op
import-test: fixture 3 PASS - identical re-import was a six-record no-op with unchanged provenance row count
import-test: fixture 4 PASS - changed provenance key reported a field-level conflict and preserved the original
import-test: fixture 5 PASS - one bad middle record failed alone while earlier and later records landed
import-test: fixture 6 PASS - provenance exists only for imports and never appears in rendered HTML
import-test: fixture 7 PASS - suspend/revive preserved imported rows and provenance
import-test: COVERAGE - all 7 defined import fixtures executed
```

### Gate 5: development pin

```text
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match
```

### Gate 6: restart persistence

The real Obelisk query returned `Migration Charge Vehicle` before and after a
full pier stop and tmux restart on port 31420. The explicit comparison printed:

```text
restart-test: PASS - Migration Charge Vehicle survived the pier restart
```

The restarted desk compiled again as `[0 %avow 0 %noun 0]`.

### Gate 7: action union

```text
$ awk '/^\+\$  action/,/^  ==$/' desk/sur/rover.hoon | grep -c '\[%'
5
```

### Gate 8: no shipping test files

```text
$ find desk -type f -name 'test-*' | wc -l
0
```

### Gate 9: no silent HTTP drop

The in-flight `add-charge` request in the migration fixture received this
exact response instead of reaching curl's 45-second timeout:

```text
Rover restarted while saving. Please submit again.
503
```

The fixture PASS output is recorded above. A static audit found 17
`restart-http` call sites across all 16 input-bearing handlers.

### Gate 10: v15 to v16 migration

```text
state-migration-test: PASS - the v15 charge request received the human 503 response after the v16 upgrade
state-migration-test: PASS - durable Obelisk data survived the v15 to v16 state migration
```

### Gate 11: shipping-library reduction

```text
$ git show b41ce9a:desk/lib/rover-act.hoon | wc -l
3304
$ wc -l desk/lib/rover-act.hoon
2180 desk/lib/rover-act.hoon
```

The verify-contract's supplementary performance battery also passed:

```text
view-performance-test: run 1 - 0.575696s, 277461 bytes, 25 of 420 fills
view-performance-test: run 2 - 0.561851s, 277461 bytes, 25 of 420 fills
view-performance-test: COVERAGE - synthetic 420-fill view stayed within 2.0s
```

## Anything left undone

Nothing in T2 remains undone. The ruled M1 definition-lifecycle work was not
built here, and every relation remains in the Obelisk pour.
