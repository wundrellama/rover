# Rover Obelisk v0.9.0 poke migration results

Date: 2026-08-06

Target: `~/piers/rover-v09-bel` (`~bel`, tmux `rover-v09`, HTTP 8082)

Obelisk: `master` at `9de633299b373a1047490b48281a40b457fb2043`
(v0.9.0-beta)

## Deprecated-action sweep

The baseline was read from `HEAD`, so the manager's uncommitted upstream AST
bump did not affect the application-call counts.

```text
before rover deprecated calls: 77
before scoped deprecated tokens: 98
after rover deprecated calls: 0
after scoped deprecated tokens: 0
after Rover script/vector calls: 77
after Rover cmd-list/vector calls: 1
unchanged Rover parse calls: 1
```

The scoped sweep is the requested `desk/ probes/ bin/ tests/` search with
`desk/sur/obelisk-ast.hoon` excluded. The upstream mold still declares the
deprecated compatibility variants. Its bytes remain identical to upstream:

```text
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2  desk/sur/obelisk-ast.hoon
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2  /tmp/obelisk-fresh/desk/sur/obelisk-ast.hoon
```

## Live verification gates

### 1. Rover compiles

Command:

```text
click -k -i probes/compile-rover.hoon ~/piers/rover-v09-bel
```

Output:

```text
[0 %avow 0 %noun 0]
```

### 2. Migrated agent installs and runs

The desk commit live-reloaded the already-running agent, and the explicit
install returned successfully. The pane also retained the real install/boot
transcript from this pier:

```text
gall: installing %rover
> |install our %rover
>=
gall: booted %rover
> |commit %rover
>=
gall: reloading %rover
eyre: replacing existing binding at /apps/rover
: /~bel/rover/3/app/rover/hoon
gall: bumped %rover
> |install our %rover
>=
```

### 3. Clean database drop and fresh 68-relation pour

The existing database was present, was dropped through `%script %sys %vector`,
and was absent before the pour:

```text
[%action 'DROP DATABASE %rover']
[%message 'database %rover dropped']
```

`probes/init-db.hoon` then returned these real action results through Rover's
migrated `%script %rover %vector` call:

```text
[%action 'CREATE TABLE %vehicles']
[%action 'CREATE TABLE %vehicle-display-preferences']
[%action 'CREATE TABLE %odometer-observations']
[%action 'CREATE TABLE %energy-definitions']
[%action 'CREATE TABLE %vehicle-energy-definitions']
[%action 'CREATE TABLE %vehicle-default-energy-definitions']
[%action 'CREATE TABLE %energy-acquisitions']
[%action 'CREATE TABLE %fuel-fills']
[%action 'CREATE TABLE %charging-sessions']
[%action 'CREATE TABLE %places']
[%action 'CREATE TABLE %stations']
[%action 'CREATE TABLE %energy-acquisition-stations']
[%action 'CREATE TABLE %energy-definition-subtypes']
[%action 'CREATE TABLE %energy-subtype-octane']
[%action 'CREATE TABLE %energy-subtype-cetane']
[%action 'CREATE TABLE %energy-subtype-blend']
[%action 'CREATE TABLE %energy-subtype-grade-code']
[%action 'CREATE TABLE %vehicle-default-energy-subtype']
[%action 'CREATE TABLE %fuel-fill-odometers']
[%action 'CREATE TABLE %additive-definitions']
[%action 'CREATE TABLE %fuel-fill-additives']
[%action 'CREATE TABLE %economy-breaks']
[%action 'CREATE TABLE %charging-energy-measurements']
[%action 'CREATE TABLE %battery-observations']
[%action 'CREATE TABLE %battery-observation-percent']
[%action 'CREATE TABLE %battery-observation-segments']
[%action 'CREATE TABLE %charging-session-batteries']
[%action 'CREATE TABLE %charging-efficiency-breaks']
[%action 'CREATE TABLE %charging-costs']
[%action 'CREATE TABLE %charging-cost-components']
[%action 'CREATE TABLE %charging-cost-source-totals']
[%action 'CREATE TABLE %consumption-observations']
[%action 'CREATE TABLE %place-addresses']
[%action 'CREATE TABLE %place-address-formatted']
[%action 'CREATE TABLE %place-address-parts']
[%action 'CREATE TABLE %place-coordinates']
[%action 'CREATE TABLE %place-coordinate-accuracy']
[%action 'CREATE TABLE %station-brand-operator']
[%action 'CREATE TABLE %station-identifiers']
[%action 'CREATE TABLE %acquisition-station-equipment']
[%action 'CREATE TABLE %app-default-vehicle']
[%action 'CREATE TABLE %vehicle-tank-size']
[%action 'CREATE TABLE %vehicle-refill-reserve']
[%action 'CREATE TABLE %fuel-fill-subtype']
[%action 'CREATE TABLE %driving-mode-definitions']
[%action 'CREATE TABLE %vehicle-driving-modes']
[%action 'CREATE TABLE %fuel-fill-driving-mode']
[%action 'CREATE TABLE %fuel-fill-average-speed']
[%action 'CREATE TABLE %fuel-fill-drive-balance']
[%action 'CREATE TABLE %tag-definitions']
[%action 'CREATE TABLE %fuel-fill-tags']
[%action 'CREATE TABLE %custom-field-definitions']
[%action 'CREATE TABLE %custom-field-options']
[%action 'CREATE TABLE %custom-field-values-number']
[%action 'CREATE TABLE %custom-field-values-text']
[%action 'CREATE TABLE %custom-field-values-boolean']
[%action 'CREATE TABLE %payment-method-definitions']
[%action 'CREATE TABLE %fuel-fill-payment-method']
[%action 'CREATE TABLE %fill-notes']
[%action 'CREATE TABLE %acquisition-imports']
[%action 'CREATE TABLE %charging-session-subtype']
[%action 'CREATE TABLE %consumable-definitions']
[%action 'CREATE TABLE %vehicle-consumables']
[%action 'CREATE TABLE %vehicle-consumable-tank-size']
[%action 'CREATE TABLE %consumable-acquisitions']
[%action 'CREATE TABLE %consumable-purchases']
[%action 'CREATE TABLE %consumable-acquisition-stations']
[%action 'CREATE TABLE %consumable-acquisition-odometers']
create_table_actions=68
```

### 4. Schema metadata

Command:

```text
click -k -i probes/verify-schema.hoon ~/piers/rover-v09-bel
```

Extracted directly from the returned fact:

```text
%vector-count 68 %vector-count 272 %vector-count 78
```

### 5. Schema battery

Command:

```text
bash bin/schema-test.sh ~/piers/rover-v09-bel
```

Output:

```text
schema-test: PASS - SQL/Hoon parity is 68/68 relations; DDL has 75 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

### 6. Import battery

Command:

```text
bash bin/import-test.sh ~/piers/rover-v09-bel
```

Output:

```text
import-test: fixture 1 PASS - seeded-parent reconciliation landed two missing energy subtypes plus the real 13-simple-definition shape, six fills, ratings, optional children, parts-only address, and no display preferences
import-test: fixture 2 PASS - one import created 51 places, two vehicles, and one fill with apostrophe-bearing labels plus a multiline note; its re-import was a no-op
import-test: fixture 3 PASS - identical re-import was a six-record no-op with unchanged provenance row count
import-test: fixture 4 PASS - changed provenance key reported a field-level conflict and preserved the original
import-test: fixture 5 PASS - one bad middle record failed alone while earlier and later records landed
import-test: fixture 6 PASS - provenance exists only for imports and never appears in rendered HTML
```

### 7. UI battery

Command (exit 0):

```text
bash bin/ui-test.sh ~/piers/rover-v09-bel
```

Final output tail:

```text
ui-test: fixture 80 PASS - literal-Y archive hides selectors, preserves history, and refuses the app default until redesignation
ui-test: fixture 84 PASS - rendered header contains the running ship and current default vehicle, with no decorative placeholders
ui-test: fixture 85 PASS - rendered header states NO DEFAULT VEHICLE when the singleton row is absent
ui-test: fixture 86 PASS - changing the app default refreshes the rendered header vehicle label
ui-test: fixture 87 PASS - bounded glow slider disables with the toggle, persists across reload, and drives a materially stronger CSS shadow
ui-test: fixture 89 PASS - Enable DEF and DEF tank size are separate labelled controls and DEFDEF is absent
ui-test: fixture 90 PASS - default energy is inside its source group and Rover rejects a forged disallowed default before writing
ui-test: fixture 91 PASS - Fuel System contains subtype, tank size, units, and refill reserve and precedes Energy Sources, Driving Modes, and DEF
ui-test: fixture 92 PASS - at 390px the reorganised settings has no horizontal overflow and every enabled touch target is at least 44px
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
comm: file 2 is not in sorted order
comm: file 1 is not in sorted order
comm: input is not in sorted order
ui-test: COVERAGE - ran 57 of 85 defined fixtures
ui-test: COVERAGE - SKIPPED, not executed this run: 57 58 59 60 61 62 63 64 65 66 67 69 76 77 78 79 82 83 94 95 96 97 98 99 100 101 102 103 104
ui-test: COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
```

The requested plain invocation runs 57 fixtures. The remaining 28 are explicit
flag-gated scenarios, and the existing coverage helper reports them rather than
silently treating them as executed. The three `comm` diagnostics are an existing
numeric-sort issue in the coverage reporter; the command exited 0 after every
non-gated fixture passed.

### 8. Pin compatibility unit

Command:

```text
bash bin/dev-pin-test.sh
```

Output:

```text
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match
```

### 9. Restart persistence

The target pier stopped cleanly (`conn.sock` absent), then restarted from its
existing pier directory:

```text
urbit 4.6
boot: home is /var/home/michael/piers/rover-v09-bel
disk: loaded epoch 0i0
conn: listening on /var/home/michael/piers/rover-v09-bel/.urb/conn.sock
http: web interface live on http://localhost:8082
pier (2346): live
~bel:dojo>
```

The post-restart `probes/verify-schema.hoon` fact contained:

```text
%vector-count 68 %vector-count 272 %vector-count 78
```

## Fixture drift found and fixed

No application assertion was weakened or removed. `bin/ui-test.sh` needed four
fixture-only corrections before its required plain invocation could reach the
end:

1. Fixture 84 defaulted to a deleted Hermes desktop Playwright path. It now uses
   the same installed Playwright 1.58.2 tree already used elsewhere in the
   script. The original real failure was:

   ```text
   ui-test: FAIL - fixture 84 Playwright module is unavailable at /home/michael/.hermes/hermes-agent/apps/desktop/node_modules/playwright
   ```

2. Fixtures 80 and 84-92 unconditionally named demo vehicles even though the
   plain invocation does not run the demo-only seed block. They now use the
   always-created `Mode Scope Vehicle` and settings fixture vehicle, and fixture
   80 verifies redesignation instead of discarding its HTTP response.
3. Fixture 86 now compares the header with the dynamic second vehicle it
   actually selected instead of the stale hardcoded `ROVER DEMO DIESEL` label.
4. Fixture 75 snapshots the owner's active vehicle labels before database
   isolation and proves the same set is restored afterward. This replaces its
   stale assumption that every owner database is pre-populated with exactly two
   demo vehicles and strengthens the isolation assertion for the clean database
   required by this run.

## Left undone

No required migration or live gate is left undone. The flag-gated UI scenarios
were not requested by the plain gate command and remain reported as skipped.
The coverage helper's existing numeric `comm` sort warning remains; it did not
affect fixture execution or exit status.
