# Rover Phase A - First Real Integration Spike (historical)

Date: 2026-07-28

Substrate:

- Fake ship/pier: `~bel`, `/home/michael/piers/rover-bel`
- Runtime: zuse 408, `brass-408k-1.pill`
- Obelisk: stock `master` at `eecab1b8`
- Rover desk: `/home/michael/piers/rover-bel/rover`
- Git branch: `master`

Every application fixture below was sent to `%rover`. `%rover` then used Gall
`%watch` and `%poke` cards to talk to `%obelisk`; no fixture poked Obelisk
directly. Click's `TERM=dumb` warning and loom startup lines are omitted from the
quoted output because they are identical wrapper noise on every invocation.
Obelisk server timestamps are omitted where they do not prove the stated
property.

## Compile and install

Probe:

```text
probes/compile-rover.hoon
```

Command:

```bash
cd /home/michael/workspace/urbit/bin
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/compile-rover.hoon /home/michael/piers/rover-bel
```

Real output:

```text
[0 %avow 0 %noun 0]
```

The clean-pier compile showed that the reported `mint-lost` was a stale Clay
failure. Installation initially found a separate real blocker: the unused
`mar/docket-0.hoon` imported `%docket`, which this zuse 408 `%base` does not
provide. Removing that unused mark allowed the desk to install.

Real install output:

```text
gall: installing %rover
> |install our %rover
>=
gall: booted %rover
```

Result: **PASS**

## Fixture 1 - initialize and verify the eleven-relation schema

Probe:

```text
probes/init-db.hoon
```

Command:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/init-db.hoon /home/michael/piers/rover-bel
```

Real output, with the result metadata reduced to its exact action cells:

```text
[0 %avow 0 %noun
  ...
  [%action 'CREATE TABLE %vehicles']
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
  ...
]
```

Verification probe:

```text
probes/verify-schema.hoon
```

Command:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/verify-schema.hoon /home/michael/piers/rover-bel
```

Real `sys.tables` output:

```text
[%result-set
  [%vector [%name %tas %charging-sessions] 0]
  [%vector [%name %tas %energy-acquisition-stations] 0]
  [%vector [%name %tas %energy-acquisitions] 0]
  [%vector [%name %tas %energy-definitions] 0]
  [%vector [%name %tas %fuel-fills] 0]
  [%vector [%name %tas %odometer-observations] 0]
  [%vector [%name %tas %places] 0]
  [%vector [%name %tas %stations] 0]
  [%vector [%name %tas %vehicle-default-energy-definitions] 0]
  [%vector [%name %tas %vehicle-energy-definitions] 0]
  [%vector [%name %tas %vehicles] 0]
0]
[%vector-count 11]
```

Real `sys.columns` result count:

```text
[%relation 'rover.sys.columns']
[%vector-count 50]
```

Real `sys.foreign-keys` output, transcribed one row per returned vector:

```text
energy-acquisitions -> charging-sessions                 1  %restrict  %restrict
energy-acquisitions -> energy-acquisition-stations       1  %restrict  %restrict
energy-acquisitions -> fuel-fills                        1  %restrict  %restrict
energy-definitions -> vehicle-energy-definitions         1  %restrict  %restrict
places -> stations                                       1  %restrict  %restrict
stations -> energy-acquisition-stations                  1  %restrict  %restrict
vehicle-energy-definitions -> energy-acquisitions        1  %restrict  %restrict
vehicle-energy-definitions -> energy-acquisitions        2  %restrict  %restrict
vehicle-energy-definitions -> vehicle-default-energy-definitions 1 %restrict %restrict
vehicle-energy-definitions -> vehicle-default-energy-definitions 2 %restrict %restrict
vehicles -> odometer-observations                        1  %restrict  %restrict
vehicles -> vehicle-energy-definitions                   1  %restrict  %restrict
[%vector-count 12]
```

The multi-FK parser syntax at this pin is `FOREIGN KEY (...) REFERENCES ...,
(...) REFERENCES ...`; repeating the `FOREIGN KEY` keyword after the comma is
rejected. The final DDL follows the checked-out parser tests and retains both
constraints.

Result: **PASS**

## Fixtures 2-5 - atomic seed, links, odometer, and fill

Probe:

```text
probes/seed-spike.hoon
```

Command:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/seed-spike.hoon /home/michael/piers/rover-bel
```

The one Rover action submitted one mutation-only urQL script. Real output:

```text
[0 %avow 0 %noun
  ...
  [%action 'INSERT INTO rover.dbo.energy-definitions'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.energy-definitions'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.vehicles'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.vehicle-energy-definitions'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.vehicle-energy-definitions'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.vehicle-default-energy-definitions'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.odometer-observations'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.energy-acquisitions'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.fuel-fills'] [%vector-count 1]
  [%action 'INSERT INTO rover.dbo.odometer-observations'] [%vector-count 1]
  ...
]
```

Read-back probe and command:

```text
probes/vehicle-history.hoon
```

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/vehicle-history.hoon /home/michael/piers/rover-bel
```

Real energy and allow-link rows:

```text
[%vector
  [%vehicle 116 'Phase A Vehicle']
  [%vehicle-archived 102 1]
  [%energy 116 'Regular 87']
  [%physical-kind %tas %reservoir]
  [%energy-archived 102 1]
  [%link-archived 102 1]
0]
[%vector
  [%vehicle 116 'Phase A Vehicle']
  [%vehicle-archived 102 1]
  [%energy 116 'Electricity']
  [%physical-kind %tas %electricity]
  [%energy-archived 102 1]
  [%link-archived 102 1]
0]
```

At aura `@f` (`102`), atom `1` is `N`/false. This proves the vehicle,
definitions, and both allow-links are active rather than bunt/default archived.
The insert source uses literal `N` in every one of those positions.

Real default read-back:

```text
[%vector
  [%vehicle 116 'Phase A Vehicle']
  [%default-energy 116 'Regular 87']
  [%link-archived 102 1]
0]
```

Real standalone odometer read-back:

```text
[%vector
  [%vehicle 116 'Phase A Vehicle']
  [%value-digits 25717 0x186a0]
  [%decimal-places 25717 1]
  [%unit %tas 26989]
  [%observed-start 24932 0x8000000d390555c00000000000000000]
  [%observed-end 24932 0x8000000d390555c10000000000000000]
  ...
0]
```

`0x186a0` is decimal `100000`, so this is exactly `10000.0 mi` under the
ratified digits/decimal-places representation.

Real fill read-back:

```text
[%vector
  [%vehicle 116 'Phase A Vehicle']
  [%energy 116 'Regular 87']
  [%quantity-milli 25717 12345]
  [%quantity-unit %tas %gal]
  [%tank-state %tas %full]
  [%observed-start 24932 0x8000000d3906a7400000000000000000]
  [%observed-end 24932 0x8000000d3906a7410000000000000000]
0]
```

The exact integer `12345` round-trips `12.345 gal`; no floating point was used.
The acquisition, its sole `fuel-fills` subtype, and the second ordinary odometer
observation were submitted in the same atomic mutation-only script. As required
by the corrected scope, there is no price state and no structural fill-to-
odometer link claim.

Results:

- Fixture 2: **PASS**
- Fixture 3: **PASS**
- Fixture 4: **PASS**
- Fixture 5: **PASS**

## Fixture 6 - ordered history in Rover

Probe and command are `probes/vehicle-history.hoon` and the command shown above.
The urQL contains no `ORDER BY`. `%rover` sorts returned vectors by
`observed-start`.

Real ordered odometer result:

```text
[%result-set
  [%vector
    [%value-digits 25717 0x186a0]
    [%observed-start 24932 0x8000000d390555c00000000000000000]
    ...
  0]
  [%vector
    [%value-digits 25717 0x1871d]
    [%observed-start 24932 0x8000000d3906a7400000000000000000]
    ...
  0]
0]
[%vector-count 2]
```

The older observation (`100000` digits) precedes the newer one (`100125`
digits), independent of Obelisk's returned row order.

Result: **PASS**

## Fixture 7 - derive current odometer without vehicle state

Probe:

```text
probes/current-odometer.hoon
```

Command:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/current-odometer.hoon /home/michael/piers/rover-bel
```

Real output after Rover selected the latest effective non-overlapping
observation:

```text
[0 %avow 0 %noun
  ...
  [%result-set
    [%vector
      [%vehicle 116 'Phase A Vehicle']
      [%value-digits 25717 0x1871d]
      [%decimal-places 25717 1]
      [%unit %tas 26989]
      [%observed-start 24932 0x8000000d3906a7400000000000000000]
      [%observed-end 24932 0x8000000d3906a7410000000000000000]
      ...
    0]
  0]
  [%vector-count 1]
  ...
]
```

`0x1871d` is decimal `100125`, or exactly `10012.5 mi`.

The real `sys.columns` output for `vehicles` was:

```text
%vehicle-id  @ux
%label       @t
%archived    @f
%recorded-at @da
```

There is no stored current-odometer vehicle column.

Result: **PASS**

## Fixture 8 - restart persistence

Exact bounce command:

```bash
tmux kill-session -t rover-bel
tmux new-session -d -s rover-bel -x 220 -y 50 \
  "cd /home/michael/workspace/urbit/bin && ./urbit -p 31350 /home/michael/piers/rover-bel"
```

Real restart output:

```text
boot: home is /var/home/michael/piers/rover-bel
disk: loaded epoch 0i0
---------------- playback starting ----------------
play: events 443-459
play (459): done (~2026.07.28..07.54.07, now=~2026.07.28..07.55.04)
---------------- playback complete ----------------
pier (472): live
~bel:dojo>
```

Post-restart command:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/vehicle-history.hoon /home/michael/piers/rover-bel
```

Real post-restart evidence:

```text
[0 %avow 0 %noun
  ...
  [%energy 116 'Regular 87'] [%physical-kind %tas %reservoir]
  [%energy 116 'Electricity'] [%physical-kind %tas %electricity]
  [%default-energy 116 'Regular 87']
  [%value-digits 25717 0x186a0]
  [%value-digits 25717 0x1871d]
  [%quantity-milli 25717 12345]
  ...
  [%data-time 0x8000000d39066d235d2f000000000000]
]
```

The returned content and its Obelisk data timestamp match the pre-restart
content. The new query's server timestamp advanced, proving this was a fresh
post-restart query rather than cached probe text.

Result: **PASS**

## TDD red/green notes

The real red paths encountered before the green run were:

```text
"create table parse produce phase:
 \" rover..vehicle-energy-definitions ...\" ..."
```

This isolated the pinned parser's multi-FK continuation syntax.

```text
"table alias or CTE name 'vehicles' is not defined"
```

This was produced by the first history probe. Adding explicit `V`, `O`, `A`,
`F`, `E`, `L`, and `D` aliases made the same probe pass.

No mocked database was used. Diagnostic database scripts used while isolating
the pinned parser are not counted as fixture evidence.

## Final status

All eight required Phase A fixtures: **PASS**

Reject-path fixtures were not included in this phase-A run because they were
optional and the required real-pier proof path was completed first.

# Rover M0 - full 35-relation pour and evidence fixtures

Date: 2026-07-28

This section supersedes the historical eleven-relation scope above. Q9 split
`battery-observations` into a form-neutral parent and two typed children, so the
adopted M0 pour has 35 relations rather than the earlier draft's 33.

Substrate:

- Fake ship/pier: `~bel`, `/home/michael/piers/rover-bel`
- Runtime: zuse 408, `brass-408k-1.pill`
- Obelisk: stock `master` at `eecab1b8`
- Rover branch: `master`

Every application fixture below was poked to `%rover`; `%rover` sent the urQL
cards to `%obelisk`. Click wrapper warnings, loom lines, and server/schema/data
timestamps are omitted from the output excerpts. Returned domain cells and
`vector-count` cells are transcribed exactly. No mock database was used.

Unless a fixture shows another command, its exact invocation was:

```bash
cd /home/michael/workspace/urbit/bin
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/PROBE.hoon \
  /home/michael/piers/rover-bel
```

## Fixture 1 - adopted schema

Fresh-pier pour:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/init-db.hoon \
  /home/michael/piers/rover-bel
```

Real result: 35 successful `CREATE TABLE` actions through `%rover`.

Verification:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/verify-schema.hoon \
  /home/michael/piers/rover-bel
```

Real summary:

```text
[%relation 'rover.sys.tables']       [%vector-count 35]
[%relation 'rover.sys.columns']      [%vector-count 156]
[%relation 'rover.sys.foreign-keys'] [%vector-count 38]
```

All 38 returned FK rows contained:

```text
[%on-delete %tas %restrict] [%on-update %tas %restrict]
```

Column counts, transcribed from `sys.columns`:

```text
acquisition-station-equipment       3
additive-definitions                4
battery-observation-percent         3
battery-observation-segments        3
battery-observations                8
charging-cost-components            8
charging-cost-source-totals         2
charging-costs                      4
charging-efficiency-breaks          3
charging-energy-measurements        8
charging-session-batteries          3
charging-sessions                   1
consumption-observations           12
economy-breaks                      3
energy-acquisition-stations         2
energy-acquisitions                 8
energy-definition-blend             4
energy-definition-grade-code        2
energy-definition-octane            3
energy-definitions                  6
fuel-fill-additives                 2
fuel-fill-odometers                 2
fuel-fills                         10
odometer-observations              10
place-address-parts                 3
place-addresses                     4
place-coordinate-accuracy           4
place-coordinates                   6
places                              4
station-brand-operator              3
station-identifiers                 3
stations                            6
vehicle-default-energy-definitions  2
vehicle-energy-definitions          3
vehicles                            4
```

The Q8/Q9/Q10 shape checks are visible in that same output:

```text
battery-observations:
  battery-observation-id, vehicle-id, measure, observed-start, observed-end,
  observed-precision, source-zone, recorded-at
economy-breaks:
  acquisition-id, reason, recorded-at
charging-efficiency-breaks:
  acquisition-id, reason, recorded-at
place-addresses:
  place-id, formatted, source, recorded-at
fuel-fills:
  acquisition-id, quantity-milli, quantity-unit, tank-state,
  unit-price-mills, currency, settlement-mode, price-profile,
  minor-unit-decimals, cash-increment-mills
```

There is no battery `form`, no break `note`, no address `country`, and no fill
`total` column. Result: **PASS**

## Fixtures 2-7 - pricing and exact arithmetic

### Fixture 2 - visible US trailing-nine completion

Probe: `probes/pricing-preview.hoon`

Real output:

```text
[0 %avow 0 %noun 0 %usd %us-usd-gal 349 2 3499 '$3.499']
```

The completion is Rover state returned before any save action. Result: **PASS**

### Fixture 3 - exact quantity

Probe: `probes/pricing-report.hoon`

Real signature row:

```text
[%quantity-milli 25717 12345]
[%quantity-unit %tas %gal]
[%unit-price-mills 25717 3499]
```

`12.345 gal` is stored as integer `12345`. Result: **PASS**

### Fixture 4 - derived total and absent total column

Probe: `probes/pricing-total.hoon`

Real output:

```text
[0 %avow 0 %noun 0 12345 3499 2 50 %standard
  0x2931b13 43200 43200]
```

`0x2931b13` is decimal `43,195,155`. The exact half-up calculation is:

```text
12,345 * 3,499 = 43,195,155
floor((43,195,155 * 100 + 500,000) / 1,000,000) = 4,320 cents
4,320 * 10 = 43,200 mills = $43.20
```

The second result set from `probes/pricing-report.hoon` was:

```text
acquisition-id, quantity-milli, quantity-unit, tank-state,
unit-price-mills, currency, settlement-mode, price-profile,
minor-unit-decimals, cash-increment-mills
[%vector-count 10]
```

No `total` column exists. Result: **PASS**

### Fixture 5 - cash affects only final rounding

Probes: `probes/pricing-total-standard.hoon` and
`probes/pricing-total-cash.hoon`.

Real outputs:

```text
[0 %avow 0 %noun 0 12344 3499 2 50 %standard
  0x2930d68 43190 43190]
[0 %avow 0 %noun 0 12344 3499 2 50 %cash
  0x2930d68 43190 43200]
```

Quantity, unit price, decimals, cash increment, product, and the standard
minor-unit result are identical. Only the cash final result changes, from
`43190` to `43200` mills. Result: **PASS**

### Fixture 6 - Q7 snapshot proof

Probe: `probes/pricing-report.hoon`

Real old and new rows:

```text
old:
  quantity-milli=12344 unit-price-mills=3499 settlement-mode=%standard
  minor-unit-decimals=2 cash-increment-mills=50
new:
  quantity-milli=12344 unit-price-mills=3499 settlement-mode=%standard
  minor-unit-decimals=3 cash-increment-mills=0
```

Probes `probes/pricing-total-standard.hoon` and
`probes/pricing-total-snapshot.hoon` returned:

```text
old: [0 %avow 0 %noun 0 12344 3499 2 50 %standard 0x2930d68 43190 43190]
new: [0 %avow 0 %noun 0 12344 3499 3 0  %standard 0x2930d68 43192 43192]
```

The new fill's profile snapshot changes its own rounding; the old fill retains
its original inputs and remains `43190`. No profile lookup participates in
either derivation. Result: **PASS**

### Fixture 7 - EUR requires explicit mills

Probe: `probes/pricing-preview-eur.hoon`

Real output:

```text
[0 %avow 0 %noun 0 %eur %eu-eur-litre 1749 3 1749 'EUR 1.749']
```

The stored report row also returned `%eur`, `%litre`, `1749`, and
`%eu-eur-litre`; no trailing nine was added. Result: **PASS**

## Fixtures 8-11 - typed fuel evidence

Probe for all four fixtures: `probes/fuel-evidence-report.hoon`.

### Fixture 8 - typed definition attributes

Real output:

```text
[%energy 116 'Regular 87 E10'] [%rating 25717 87] [%method %tas %aki]
[%energy 116 'Regular 87 E10'] [%blend-kind %tas %ethanol]
[%percent-digits 25717 100] [%percent-decimals 25717 1]
```

The method is bound to the octane row; E10 is preserved as `100` with one
decimal place. Result: **PASS**

### Fixture 9 - zero, one, and several additives

The three fills all returned the same canonical price inputs:

```text
quantity-milli=1000 quantity-unit=%gal unit-price-mills=3499
currency=%usd settlement-mode=%standard
[%vector-count 3]
```

Link output by acquisition time:

```text
14:00 -> no additive row
14:01 -> 'Injector cleaner'
14:02 -> 'Injector cleaner'
14:02 -> 'Fuel stabilizer'
```

Definition output:

```text
'Injector cleaner'
'Fuel stabilizer'
[%vector-count 2]
```

There is no `None` definition. Additives did not mutate the fill inputs and
therefore cannot change its derived total. Result: **PASS**

### Fixture 10 - explicit economy break

Real output:

```text
[%vehicle 116 'Fuel Evidence Vehicle'] [%reason %tas %missed-fill]
[%vector-count 1]
```

The relation has no numeric estimate or zero sentinel. Result: **PASS**

### Fixture 11 - optional fill-to-odometer link

Three fills exist, while the link query returned:

```text
[%value-digits 25717 0x30d40] [%decimal-places 25717 1]
[%unit %tas 26989]
[%vector-count 1]
```

Only the 14:00 fill has the link; the other two are represented by absent rows,
not zero IDs. Result: **PASS**

## Fixtures 12-15 - charging, costs, and consumption

### Fixture 12 - distinct charging measurements

Probe: `probes/charging-evidence-report.hoon`

Real measurement rows:

```text
45678 decimals=3 measure-unit=%kwh point=%charger  evidence=%reported
72    decimals=1 measure-unit=%kw  point=%charger  evidence=%measured
50    decimals=0 measure-unit=%mi  point=%estimate evidence=%estimated
[%vector-count 3]
```

Delivered energy, power, and range remain three typed rows; kW and range never
substitute for kWh. Result: **PASS**

### Fixture 13 - battery forms and measures

Same probe, real output:

```text
parent measures: %charge-level, %charge-level, %health
percent children:
  %charge-level value-digits=805 value-decimals=1
  %health       value-digits=950 value-decimals=1
segments child:
  %charge-level filled=9 total=12
session endpoints:
  %start -> %charge-level
  %end   -> %charge-level
```

The segments row has whole `filled/total` counts and no invented percentage.
The parent has no redundant `form` discriminator. Result: **PASS**

### Fixture 14 - charging cost states and totals

Probes: `probes/charging-cost-report.hoon` and
`probes/charging-total.hoon`.

Real states:

```text
%free, %unknown, %itemized, %receipt-total-only
[%vector-count 4]
```

Real itemized components:

```text
%energy=11420 %time=3000 %session=1500 %idle=2500 %tax=1000
%discount=2000
```

Integer derivation output:

```text
[0 %avow 0 %noun 0 19420 2000 17420]
```

The receipt-only source total was:

```text
[%total-mills 25717 22340] [%vector-count 1]
```

`%free` and `%unknown` have no amount child. Thus zero is never used for
missing cost, while a source-reported receipt total is preserved separately.
Result: **PASS**

### Fixture 15 - source-native consumption

Probe: `probes/consumption-report.hoon`

Real rows:

```text
275 decimals=0 %wh-mi     %instant      %dashboard America/Chicago
182 decimals=1 %kwh-100km %trip         %telematics Europe/Paris
37  decimals=1 %mi-kwh    %since-charge %dashboard America/Chicago
[%vector-count 3]
```

Each row also returned its original observed bounds and `%second` precision.
Result: **PASS**

## Fixtures 16-18 - location and station evidence

Probe: `probes/location-report.hoon`.

### Fixture 16 - optional and typed location facts

Real place/station output:

```text
'Private Home'  -> 'Home Charger'          %private
'Public Market' -> 'Market Mixed Station'  %mixed
```

Public address and typed parts:

```text
'123 Market St, Chicago, IL 60601, USA' source=%owner
%country='US' %locality='Chicago' %region='IL'
%postal-code='60601' %line1='123 Market St'
```

The exact private-home child queries returned:

```text
place-addresses:   [%result-set 0] [%vector-count 0]
place-coordinates: [%result-set 0] [%vector-count 0]
```

Public coordinate output:

```text
latitude-scaled  @sd 0x31ec2f9f
longitude-scaled @sd 0x68767dfc
coord-scale=7 source=%gps
radius-digits=47 radius-decimals=1 radius-unit=%metre
```

For `@sd`, `0x31ec2f9f = 2*418781136-1` and
`0x68767dfc = 2*876297982`, so the signed values are exactly
`41.8781136, -87.6297982`. Brand/operator/provider output:

```text
%brand='Shell'
%operator='Acme Mobility'
%provider=%chargepoint
```

Rover intentionally did not return the provider's raw external machine ID.
Empty strings and zero coordinates are not sentinels. Result: **PASS**

### Fixture 17 - one mixed station serves both kinds

Real output:

```text
'Location Evidence Vehicle' %reservoir   'Market Mixed Station' %mixed
'Location Evidence Vehicle' %electricity 'Market Mixed Station' %mixed
[%vector-count 2]
```

Result: **PASS**

### Fixture 18 - visit equipment is link-local

Two acquisition/station links exist. The equipment join returned only:

```text
'Market Mixed Station' equipment-label='Pump 7' receipt-text='PUMP 7'
[%vector-count 1]
```

The charging link remains valid without an equipment child, and the station
row itself is unchanged. Result: **PASS**

## Fixtures 19-22 - integrity

Each probe poked `%run-integrity` through `%rover`. Expected Obelisk tangs are
kept internal so random IDs never cross the probe boundary.

### Fixture 19 - acquisition pair must be allowed

Probe: `probes/integrity-missing-pair.hoon`

```text
[0 %avow 0 %noun 0 %missing-pair 0
 'rejected acquisition: vehicle and energy definition are not allowed']
```

Result: **PASS**

### Fixture 20 - default must be an allowed link

Probe: `probes/integrity-bad-default.hoon`

```text
[0 %avow 0 %noun 0 %bad-default 0
 'rejected default: energy definition is not an allowed vehicle link']
```

Result: **PASS**

### Fixture 21 - RESTRICT deletes

Probes and real outputs:

```text
integrity-delete-vehicle.hoon
  [0 %avow 0 %noun 0 %delete-vehicle 0
   'rejected deletion: vehicle is referenced']
integrity-delete-definition.hoon
  [0 %avow 0 %noun 0 %delete-definition 0
   'rejected deletion: energy definition is referenced']
integrity-delete-place.hoon
  [0 %avow 0 %noun 0 %delete-place 0
   'rejected deletion: place is referenced']
integrity-delete-station.hoon
  [0 %avow 0 %noun 0 %delete-station 0
   'rejected deletion: station is referenced']
```

Each was a separate real mutation-only Obelisk script. Result: **PASS**

### Fixture 22 - acquisition subtype XOR

Probes and real outputs:

```text
integrity-zero-subtype.hoon
  [0 %avow 0 %noun 0 %zero-subtype 0
   'rejected acquisition before mutation: zero subtypes']
integrity-two-subtypes.hoon
  [0 %avow 0 %noun 0 %two-subtypes 0
   'rejected acquisition before mutation: two subtypes']
```

Both paths use the same Rover XOR validator. It rejects before an Obelisk card
can be produced, so neither invalid acquisition can partially persist. Result:
**PASS**

## Fixture 23 - restart persistence for every relation

Pre-restart audit:

```bash
./click -k -i /var/home/michael/workspace/urbit/Rover/probes/content-report.hoon \
  /home/michael/piers/rover-bel
```

The report performs 35 urQL reads through `%rover`, one per relation, selecting
only safe non-ID evidence.

Exact bounce command:

```bash
tmux kill-session -t rover-bel
tmux new-session -d -s rover-bel -x 220 -y 50 \
  "cd /var/home/michael/workspace/urbit/bin && \
   ./urbit -p 31350 /home/michael/piers/rover-bel"
```

Real restart output:

```text
gall: reloading %rover
play (618): done (~2026.07.28..17.41.54, now=~2026.07.28..17.43.09)
---------------- playback complete ----------------
conn: listening on /var/home/michael/piers/rover-bel/.urb/conn.sock
pier (631): live
~bel:dojo>
```

No `%init-db` or seed action ran after the bounce. Post-restart schema output:

```text
sys.tables       vector-count=35
sys.columns      vector-count=156
sys.foreign-keys vector-count=38
```

Post-restart content report summary:

```text
result-set count: 35
vector-counts:
7,3,10,1,7,16,6,6,2,2,1,1,1,1,1,2,2,1,3,3,2,1,2,1,4,6,1,3,1,5,1,1,2,1,1
all-35-result-sets-nonempty
```

The counts are in `content-report:act` order and cover all 35 relations. Result:
**PASS**

## TDD and parser evidence

The first Q10 enum probe failed before `%country` was added:

```text
[0 %avow 0 %noun 1 ... nest-fail ... %country ...]
```

After adding the adopted address-part term:

```text
[0 %avow 0 %noun 0]
```

The first integrity probe failed before `%run-integrity` existed:

```text
[0 %avow 1 %thread-fail ... %poke-fail ... nest-fail
 [%run-integrity %missing-pair] ...]
```

The location seed produced two useful real red paths:

```text
insert parse produce phase:
  " place-coordinates VALUES (..., 418781136, -876297982, 7, %gps ..."
```

and, after correcting the signed-literal spelling:

```text
"INSERT": [%dbo %place-coordinates] row 1
"INSERT: type of column %column name=%latitude-scaled does not match input value type ~.ud"
```

After using the pinned parser's signed forms
`-418.781.136` and `--876.297.982`, the same transaction inserted every row.
Both failed attempts left the location report at `vector-count 0`, proving
atomic rollback.

The first 35-way content audit failed read-only with:

```text
"SELECT: column %value-digits not found"
```

Qualifying hyphenated names fixed the pinned parser ambiguity; the green report
returned all 35 non-empty result sets.

## M0 commits

```text
1cdc255 Q10: admit country address-part evidence
8a00b6c Implement exact fill pricing and derived totals
dbe556d Add typed fuel evidence and optional fill links
e2caaa6 Persist typed charging and battery evidence
499fa32 Add charging cost states and integer totals
50bbadb Round-trip source-native consumption evidence
f0be283 Persist location and station evidence
1d66e60 Enforce acquisition and reference integrity
668b6d3 Audit persisted content across all M0 relations
```

## M0 final status

Fixtures 1-23: **PASS** on the real restarted pier. No mocks, floating-point
arithmetic, mutation `AS OF`, `UPSERT`, `CASCADE`, `SET DEFAULT`, nullable
sentinels, or stored fill total were used.
