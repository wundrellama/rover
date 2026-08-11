# Rover Gate 7 T1 results

Date: 2026-08-11. Branch: `ab-gate7-t1-opus`. Worktree: `/tmp/g7-opus`.

Pier: `~/piers/rover-g7-opus-bel`. Fresh disposable fake `~bel`, Ames port
31402, pill `brass-408k-1.pill`, booted this run. Obelisk `master` at
`9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta), installed from
`/tmp/obelisk-fresh` and started with `|start %obelisk %obelisk`. `%rover`
installed from `desk/` in this worktree. The pier never poked one of the
32 doomed fixture actions. The owner baseline is `%init-db` plus
`%seed-starters`, both KEEP arms.

## What T1 delivers

- 21 readback and diagnostic probes poke `%obelisk` directly with
  `[%script %rover %vector "<urql>"]`. No probe pokes a `%rover-action`
  readback, diagnostic, or calculator arm.
- Six seeds run through the 17 product Eyre endpoints inside
  `bin/ui-test.sh`: `seed-spike`, `seed-app-structure`,
  `seed-charging-cost`, `seed-demo-fuel`, `seed-demo-def`,
  `seed-fill-edit-support`.
- Five seeds are exempt per the 2026-08-11 ruling and no battery or probe
  pokes them: `seed-fuel-evidence`, `seed-charging-evidence`,
  `seed-consumption`, `seed-location`, `seed-pricing`. Their areas leave
  M0 for M1. T2 deletes them.
- `desk/` is untouched. The action union still holds 43 arms.

## The six seeds, re-driven through Eyre

The battery replaces each privileged poke with a function of plain
endpoint calls. Each call asserts its exact HTTP response, so a refused
write fails at the write.

1. `seed-spike` → `seed_spike_via_eyre`: `add-energy-source-type`
   (Regular 87), `add-vehicle` (Phase A Vehicle with additional
   Electricity), `add-odometer` (10,000.0 mi), `add-fill` (12.345 gal at
   $3.49), `add-odometer` (10,012.5 mi).
2. `seed-app-structure` → `seed_app_structure_via_eyre`: `import`
   (Structure Gasoline with three AKI subtypes, Tow / Haul, two tags),
   `add-vehicle` (Structure Vehicle), `edit-vehicle` (default subtype
   Structure 91 AKI), `add-vehicle` (Mode Scope Vehicle).
3. `seed-charging-cost` → `seed_charging_cost_via_eyre`:
   `add-energy-source-type` (Cost Fixture Electricity), `add-vehicle`
   (Charging Cost Vehicle), four `add-charge` calls covering the free,
   unknown, itemized (six components), and receipt-total-only cost
   states.
4. `seed-demo-fuel` → `seed_demo_fuel_via_eyre`: `import` (two payment
   methods), two `add-vehicle`, two `edit-vehicle` (tank sizes), twelve
   `add-fill` calls across two demo vehicles and four stations.
5. `seed-demo-def` → `seed_demo_def_via_eyre`: `edit-vehicle` (DEF
   enablement plus DEF tank size), three `add-consumable` DEF purchases.
6. `seed-fill-edit-support` → `seed_fill_edit_support_via_eyre`: `import`
   (additive, driving mode, tag, payment method), `edit-vehicle` (mode
   link).

## Step 2 — what came out of the battery, and why

The ruling removes the five exempt seeds from the battery. Everything
below depended on their data.

Removed outright:

- The `for support_action in ...` poke loop and its `QUESTIONS.md`
  comment. This was the last fixture-action poke in any battery.
- **Fixture 93** and the `URQL_LOCATION` report. The fixture asserted
  only `seed-location` evidence: the parts-only address on Parts Only
  Depot, coordinate accuracy, brand/operator, and station identifiers.
  All of that is M1 scope with no entry surface. Nothing product-side
  remains to assert. The endpoint-reachable part of the same ground —
  formatted, parts-only, and absent address evidence through `add-fill`
  station creation — stays covered by fixtures 40 and 41.
- The `Regular 87 E10` render assertion. The label existed only in
  `seed-fuel-evidence`. The stored-subtype render check now reads
  `Structure 93 AKI`, which the fixture 18 fill writes through
  `add-fill`.

Retargeted onto endpoint-created state (the assertions are unchanged,
only the subject rows moved):

- The multi-source hub check used Location Evidence Vehicle. It now uses
  Phase A Vehicle, which `add-vehicle` creates with fuel plus
  electricity. The hub still must offer both Add Fill and Add Charge.
- The Chromium fill measurements (fixtures 19, 26, 28, 31) selected Fuel
  Evidence Vehicle and the Home Charger station. They now select
  Structure Vehicle (single source, so the energy-source control stays a
  vehicle property) and Edit Station (created through `add-fill` new
  station in fixture 38 setup).
- The fixture 25 station fills on Phase A Vehicle linked the seeded Home
  Charger for the saved-station path. The first fill now creates UI Home
  Pump through the new-station path and the second links it through the
  saved-station path. Both endpoint paths stay exercised and both fills
  must render.
- The display-preference fixtures (24, 29) and the archived-history
  subject of fixture 80 used Fuel Evidence Vehicle and its seeded
  20,000.0 mi odometer. The battery now creates Preference Vehicle
  through `add-vehicle`, `add-odometer` (20,000.0 mi), and `add-fill`.
  The expected strings are unchanged, including the exact
  `32,186.9 km (converted)` reading.

Probe defaults that named exempt rows moved to endpoint-created rows:
`display-preference-report` reads Preference Vehicle, `station-report`
reads Edit Station, `charge-subtype-report` keys on the fixture 43
observed start. The five exempt-area report probes
(`fuel-evidence-report`, `charging-evidence-report`,
`consumption-report`, `location-report`, `pricing-report`) stay in the
tree unchanged, execute cleanly, and return empty result sets on a
fence-clean pier. T2 deletes them with their seeds.

No assertion was weakened. Removed fixtures came out whole.

## The ten gates

### Gate 1 — compile-rover

```text
$ click -k -i probes/compile-rover.hoon ~/piers/rover-g7-opus-bel
[0 %avow 0 %noun 0]
```

### Gate 2 — ui-test battery

```text
$ ROVER_DEMO_ONLY=1 bash bin/ui-test.sh ~/piers/rover-g7-opus-bel
...
ui-test: fixture 109 PASS - a real browser fills repeatable itemized component rows, previews the exact derived total, and saves it through Eyre
ui-test: fixture 89 PASS - Enable DEF and DEF tank size are separate labelled controls and DEFDEF is absent
ui-test: fixture 90 PASS - default energy is inside its source group and Rover rejects a forged disallowed default before writing
ui-test: fixture 91 PASS - Fuel System contains subtype, tank size, units, and refill reserve and precedes Energy Sources, Driving Modes, and DEF
ui-test: fixture 92 PASS - at 390px the reorganised settings has no horizontal overflow and every enabled touch target is at least 44px
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - all 89 defined fixtures executed
EXIT=0
```

Zero FAIL lines (`grep -ci FAIL` = 0). 94 PASS notes. The coverage gate
reports every remaining fixture executed. Full log:
`/tmp/g7-ui-test.log`.

### Gate 3 — schema-test

```text
$ bash bin/schema-test.sh ~/piers/rover-g7-opus-bel
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
EXIT=0
```

### Gate 4 — import-test

```text
$ bash bin/import-test.sh ~/piers/rover-g7-opus-bel
...
import-test: fixture 5 PASS - one bad middle record failed alone while earlier and later records landed
import-test: fixture 6 PASS - provenance exists only for imports and never appears in rendered HTML
import-test: fixture 7 PASS - suspend/revive preserved imported rows and provenance
import-test: COVERAGE - all 7 defined import fixtures executed
EXIT=0
```

### Gate 5 — dev-pin-test

```text
$ bash bin/dev-pin-test.sh
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match
```

### Gate 6 — restart persistence

Procedure: capture `current-odometer` and `starter-report` probe output,
stop the pier with a plain kill, restart it (`urbit -t -p 31402
~/piers/rover-g7-opus-bel`), and rerun both probes.

```text
$ kill <king pid>   # graceful stop, waited for exit
stopped
port-free
$ urbit -t -p 31402 ~/piers/rover-g7-opus-bel
http: web interface live on http://localhost:8084
pier (1648): live
$ # compare pre-restart and post-restart probe vases, timestamp fields stripped
odo IDENTICAL-MODULO-TIMESTAMPS
starter IDENTICAL-MODULO-TIMESTAMPS
$ curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' http://localhost:8084/apps/rover
303 http://localhost:8084/~/login?redirect=/apps/rover
```

Every data row survives the restart and the Eyre binding is live again.
The import battery separately proves suspend/revive persistence (its
fixture 7).

### Gate 7 — union still 43

```text
$ awk '/^\+\$  action/,/^  ==$/' desk/sur/rover.hoon | grep -c '\[%'
43
```

### Gate 8 — desk untouched

```text
$ git status --short desk/
(empty)
```

### Gate 9 — every remaining %rover-action poke is a KEEP arm

```text
$ grep -n "rover-action" bin/ui-test.sh | grep -v "^[0-9]*:#"
387:  %init-db            (fixture-isolation disposable database)
389:  %seed-starters      (fixture-isolation starter pack)
1635: %rename-energy-source  (fixture 35 rename)
1645: %seed-starters      (fixture 35 re-seed)
1660: %rename-energy-source  (fixture 35 rename back)
1902: %seed-starters      (consumable starter baseline)
2357: %rename-consumable  (fixture 54 rename)
2367: %seed-starters      (fixture 54 re-seed)
2382: %rename-consumable  (fixture 54 rename back)
```

Nine hits, four distinct actions, all KEEP: `init-db`, `seed-starters`,
`rename-energy-source`, `rename-consumable`.

### Gate 10 — the 21 probes return real data

Evidence state: one clean isolated battery run (gate 2), then one
non-isolated run (`ROVER_NO_FIXTURE_ISOLATION=1 ROVER_FIXTURE_STOP=83`,
exit 0) so the fixture rows stay in the database the probes read. Every
probe below ran against the live pier after that run. Output is the tail
vase from `click -k -i probes/<name>.hoon ~/piers/rover-g7-opus-bel`,
truncated for length. The full capture is `/tmp/g7-probes.log`.

The 21 planned probes are the 16 readbacks plus 5 diagnostics
(`run-integrity` ships as 8 `integrity-*` probe files, so 12 diagnostic
files cover the 5 planned diagnostics). The 7 calculator probes ride
along.

Five readbacks — `charging-evidence-report`, `consumption-report`,
`fuel-evidence-report`, `location-report`, `pricing-report` — execute
cleanly and return well-formed **empty** result sets. That is the correct
result: their seeds are the five exempt actions, nothing pokes them on a
fence-clean pier, and the evidence they would read is M1 scope. T2
deletes these five probes with their seeds. The other 11 readbacks, all
12 diagnostics, and all 7 calculators return real data from
endpoint-created rows.

The 6 `integrity-*` mutation probes and `try-second-app-default` end in a
statement the substrate must refuse, so their expected output is an error
fact (`%noun 1 ...`) or the Rover XOR error cord. That refusal is the
assertion.

#### Readbacks (16)

**`app-structure-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%observed-start 24932 0x8000000d39071a180000000000000000] [%subtype 116 'Structure 93 AKI'] [%rating 25717 93] [%method %tas %aki] 0] [%vector [%observed-start 24932 0x8000000d39071c700000000000000000] [%subtype 116 'Structure 87 AKI'] [%rating 25717 87] [%method %tas %aki] 0] [%vector [%observed-start 24932 0x8000000d390a7fdc0 ...(truncated)
```

**`display-preference-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Preference Vehicle'] [%value-digits 25717 0x30d40] [%decimal-places 25717 1] [%unit %tas 26989] 0] 0] [%server-time 0x8000000d39197c86f288000000000000] [%relation-name 'rover.dbo.odometer-observations'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c7061f7000000000000] [%relation-nam ...(truncated)
```

**`charging-cost-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Charging Cost Vehicle'] [%observed-start 24932 0x8000000d3906dfbc0000000000000000] [%cost-state %tas %unknown] [%currency %tas %usd] 0] [%vector [%vehicle 116 'Charging Cost Vehicle'] [%observed-start 24932 0x8000000d3906df800000000000000000] [%cost-state %tas %free] [%currency %tas %usd] 0] [%vector [%vehicle 116 ...(truncated)
```

**`charging-evidence-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set 0] [%server-time 0x8000000d39197c8771fe000000000000] [%relation-name 'rover.dbo.charging-energy-measurements'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c70480e000000000000] [%relation-name 'rover.dbo.energy-acquisitions'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c711 ...(truncated)
```

**`consumption-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set 0] [%server-time 0x8000000d39197c87b9d5000000000000] [%relation-name 'rover.dbo.consumption-observations'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197afbf807000000000000] [%relation-name 'rover.dbo.vehicles'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c7061f7000000000000 ...(truncated)
```

**`fuel-evidence-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set 0] [%server-time 0x8000000d39197c87f8a7000000000000] [%relation-name 'rover.dbo.energy-definition-subtypes'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c711695000000000000] [%relation-name 'rover.dbo.energy-definitions'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c731187 ...(truncated)
```

**`location-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set 0] [%server-time 0x8000000d39197c884951000000000000] [%relation-name 'rover.dbo.places'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c6ed1db000000000000] [%relation-name 'rover.dbo.stations'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c6ee0f2000000000000] [%vector-count 0 ...(truncated)
```

**`pricing-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set 0] [%server-time 0x8000000d39197c889af2000000000000] [%relation-name 'rover.dbo.energy-acquisitions'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c711695000000000000] [%relation-name 'rover.dbo.energy-definitions'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c7311870000000 ...(truncated)
```

**`fill-edit-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Rover Demo Gasoline'] [%acquisition-id 30837 0x929cb0bdf69af2a66a74f2206c4d95e3] [%observed-start 24932 0x8000000d38e30ec00000000000000000] [%source-zone 116 'America/Chicago'] [%quantity-milli 25717 10000] [%tank-state %tas %full] [%unit-price-mills 25717 3399] [%currency %tas %usd] [%settlement-mode %tas %standa ...(truncated)
```

**`station-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%station 116 'Edit Station'] [%place 116 'Edit Station Place'] [%station-kind %tas %fuel] 0] 0] [%server-time 0x8000000d39197c893a4f000000000000] [%relation-name 'rover.dbo.places'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c6ed1db000000000000] [%relation-name 'rover.dbo.stations'] [%schema-ti ...(truncated)
```

**`consumable-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Rover Demo Diesel'] [%consumable 116 'DEF'] [%quantity-milli 25717 1000] [%quantity-unit %tas %gal] [%unit-price-mills 25717 4299] [%currency %tas %usd] [%settlement-mode %tas %standard] [%price-profile %tas %us-usd-gal] [%minor-unit-decimals 25717 2] [%cash-increment-mills 25717 50] 0] 0] [%server-time 0x8000000d ...(truncated)
```

**`charge-subtype-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Charge Subtype Vehicle 1786474201025646348'] [%charging-subtype 116 'DC Fast'] 0] 0] [%server-time 0x8000000d39197c89b9b8000000000000] [%relation-name 'rover.dbo.charging-session-subtype'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c59f324000000000000] [%relation-name 'rover.dbo.c ...(truncated)
```

**`vehicle-settings-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Rover Demo Gasoline'] [%archived 102 1] 0] 0] [%server-time 0x8000000d39197c89f77b000000000000] [%relation-name 'rover.dbo.vehicles'] [%schema-time 0x8000000d39197afbf807000000000000] [%data-time 0x8000000d39197c7061f7000000000000] [%vector-count 1] 0] [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 1 ...(truncated)
```

**`demo-starter-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Rover Demo Diesel'] [%demo-energy-definition-id 30837 0xdb36a8667d9f265739fb729f64e9190f] [%starter-energy-definition-id 30837 0xdb36a8667d9f265739fb729f64e9190f] [%starter-energy 116 'Diesel'] 0] [%vector [%vehicle 116 'Rover Demo Gasoline'] [%demo-energy-definition-id 30837 0xdb36a8667d9f265739fb729f64e9190c] [% ...(truncated)
```

**`starter-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%energy-definition-id 30837 0x19ee97a617c245e9bbd9fc97365da8dc] [%label 116 'Structure Gasoline'] [%physical-kind %tas %reservoir] [%quantity-unit %tas %gal] [%archived 102 1] 0] [%vector [%energy-definition-id 30837 0x2d160690006f9b9d7c8a82cf8c95e24b] [%label 116 'Cost Fixture Electricity'] [%physical-kind %tas %electricity] [ ...(truncated)
```

**`consumable-starter-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%consumable-id 30837 0xdb36a8667d9f265739fb729f64e93a21] [%label 116 'Coolant'] [%quantity-unit %tas %gal] [%archived 102 1] 0] [%vector [%consumable-id 30837 0xdb36a8667d9f265739fb729f64e93a24] [%label 116 'DEF'] [%quantity-unit %tas %gal] [%archived 102 1] 0] [%vector [%consumable-id 30837 0xdb36a8667d9f265739fb729f64e93a26]  ...(truncated)
```

#### Diagnostics (12 probe files covering the 5 planned diagnostics)

**`integrity-bad-default`**

```text
[0 %avow 0 %noun 1 [%rose [[58 0] 0 0] [%rose [[47 0] [47 0] 0] [%leaf 108 105 98 0] [%leaf 99 114 117 100 0] [%leaf 104 111 111 110 0] 0] [%leaf 60 91 50 46 54 56 53 32 53 49 93 46 91 50 46 54 56 53 32 53 51 93 62 0] 0] [%leaf 34 73 78 83 69 82 84 58 32 70 79 82 69 73 71 78 32 75 69 89 32 112 97 11 ...(truncated)
```

**`integrity-delete-definition`**

```text
[0 %avow 0 %noun 1 [%rose [[58 0] 0 0] [%rose [[47 0] [47 0] 0] [%leaf 108 105 98 0] [%leaf 99 114 117 100 0] [%leaf 104 111 111 110 0] 0] [%leaf 60 91 50 46 55 52 49 32 57 93 46 91 50 46 55 52 49 32 49 49 93 62 0] 0] [%leaf 34 68 69 76 69 84 69 58 32 70 79 82 69 73 71 78 32 75 69 89 32 114 101 115  ...(truncated)
```

**`integrity-delete-place`**

```text
[0 %avow 0 %noun 1 [%rose [[58 0] 0 0] [%rose [[47 0] [47 0] 0] [%leaf 108 105 98 0] [%leaf 99 114 117 100 0] [%leaf 104 111 111 110 0] 0] [%leaf 60 91 50 46 55 52 49 32 57 93 46 91 50 46 55 52 49 32 49 49 93 62 0] 0] [%leaf 34 68 69 76 69 84 69 58 32 70 79 82 69 73 71 78 32 75 69 89 32 114 101 115  ...(truncated)
```

**`integrity-delete-station`**

```text
[0 %avow 0 %noun 1 [%rose [[58 0] 0 0] [%rose [[47 0] [47 0] 0] [%leaf 108 105 98 0] [%leaf 99 114 117 100 0] [%leaf 104 111 111 110 0] 0] [%leaf 60 91 50 46 55 52 49 32 57 93 46 91 50 46 55 52 49 32 49 49 93 62 0] 0] [%leaf 34 68 69 76 69 84 69 58 32 70 79 82 69 73 71 78 32 75 69 89 32 114 101 115  ...(truncated)
```

**`integrity-delete-vehicle`**

```text
[0 %avow 0 %noun 1 [%rose [[58 0] 0 0] [%rose [[47 0] [47 0] 0] [%leaf 108 105 98 0] [%leaf 99 114 117 100 0] [%leaf 104 111 111 110 0] 0] [%leaf 60 91 50 46 55 52 49 32 57 93 46 91 50 46 55 52 49 32 49 49 93 62 0] 0] [%leaf 34 68 69 76 69 84 69 58 32 70 79 82 69 73 71 78 32 75 69 89 32 114 101 115  ...(truncated)
```

**`integrity-missing-pair`**

```text
[0 %avow 0 %noun 1 [%rose [[58 0] 0 0] [%rose [[47 0] [47 0] 0] [%leaf 108 105 98 0] [%leaf 99 114 117 100 0] [%leaf 104 111 111 110 0] 0] [%leaf 60 91 50 46 54 56 53 32 53 49 93 46 91 50 46 54 56 53 32 53 51 93 62 0] 0] [%leaf 34 73 78 83 69 82 84 58 32 70 79 82 69 73 71 78 32 75 69 89 32 112 97 11 ...(truncated)
```

**`integrity-two-subtypes`**

```text
[0 %avow 0 %noun %err 'exactly one acquisition subtype is required']
```

**`integrity-zero-subtype`**

```text
[0 %avow 0 %noun %err 'exactly one acquisition subtype is required']
```

**`try-second-app-default`**

```text
[0 %avow 0 %noun 1 [%rose [[58 0] 0 0] [%rose [[47 0] [47 0] 0] [%leaf 108 105 98 0] [%leaf 99 114 117 100 0] [%leaf 104 111 111 110 0] 0] [%leaf 60 91 52 52 51 32 56 48 93 46 91 52 52 51 32 56 50 93 62 0] 0] [%leaf 34 73 78 83 69 82 84 58 32 99 97 110 110 111 116 32 97 100 100 32 100 117 112 108 10 ...(truncated)
```

**`content-report`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%label 116 'Fixture 49 No DEF 1786474205845778876'] [%archived 102 1] 0] [%vector [%label 116 'Charge Cost Vehicle 1786474201364481345'] [%archived 102 1] 0] [%vector [%label 116 'Starter Diesel 1786474183898717271'] [%archived 1 ...(truncated)
```

**`vehicle-history`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Phase A Vehicle'] [%vehicle-archived 102 1] [%energy 116 'Electricity'] [%physical-kind %tas %electricity] [%energy-archived 102 1] [%link-archived 102 1] 0] [%vector [%vehicle 116 'Phase A Vehicle'] [%vehicle-archi ...(truncated)
```

**`current-odometer`**

```text
[0 %avow 0 %noun 0 [%results [%action 'SELECT'] [%result-set [%vector [%vehicle 116 'Phase A Vehicle'] [%value-digits 25717 0x98f4bd] [%decimal-places 25717 3] [%unit %tas 26989] [%observed-start 24932 0x8000000d3907431c0000000000000000] [%observed-end 24932 0x8000000d3907431d0000000000000000] [%rec ...(truncated)
```

#### Calculator probes (7)

**`pricing-preview`**

```text
[0 %avow 0 %noun %usd %us-usd-gal 349 2 3499 '$3.499']
```

**`pricing-preview-eur`**

```text
[0 %avow 0 %noun %eur %eu-eur-litre 1749 3 1749 'EUR 1.749']
```

**`pricing-total`**

```text
[0 %avow 0 %noun 12345 3499 2 50 %standard 0x2931b13 43200 43200]
```

**`pricing-total-standard`**

```text
[0 %avow 0 %noun 12344 3499 2 50 %standard 0x2930d68 43190 43190]
```

**`pricing-total-cash`**

```text
[0 %avow 0 %noun 12344 3499 2 50 %cash 0x2930d68 43190 43200]
```

**`pricing-total-snapshot`**

```text
[0 %avow 0 %noun 12344 3499 3 0 %standard 0x2930d68 43192 43192]
```

**`charging-total`**

```text
[0 %avow 0 %noun 19420 2000 17420]
```

## Supplementary — view-performance-test

Not one of the ten required gates, but part of the plan's full battery
list, so it ran too:

```text
$ bash bin/view-performance-test.sh ~/piers/rover-g7-opus-bel
view-performance-test: run 1 - 0.573435s, 277461 bytes, 25 of 420 fills
view-performance-test: run 2 - 0.572589s, 277461 bytes, 25 of 420 fills
view-performance-test: COVERAGE - synthetic 420-fill view stayed within 2.0s
EXIT=0
```

## Left undone

- Nothing from the T1 scope. All ten gates pass with real pier output.
- The five exempt-area report probes return empty result sets by design.
  If the operator wants a one-time proof that their urQL still parses
  against populated rows, the only source of those rows is the exempt
  seed pokes, which this task does not run. T2 deletes the probes, so
  the question expires with them.
- `QUESTIONS.md` (gitignored) now records that the previous run's five
  findings are ruled. The one open finding — no endpoint archives or
  renames a definition — is already relayed in the `PLAN-GATE7.md`
  header and needs a ruling before publish. It is not a T1 item.
- The pier `~/piers/rover-g7-opus-bel` is left running (Ames 31402, HTTP
  8084) with the fixture-populated owner database from the gate 10
  evidence run. It is disposable.
