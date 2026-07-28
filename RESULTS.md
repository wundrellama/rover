# Rover Phase A - First Real Integration Spike

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
