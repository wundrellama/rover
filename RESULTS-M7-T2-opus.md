# RESULTS — M7 T2, service subtype catalog (branch `ab-m7t2-opus`)

Date: 2026-08-17. Every result below comes from a run on a real pier against the
pinned Obelisk agent. No result comes from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t2-opus`, branch `ab-m7t2-opus` |
| Pier | `~/piers/rover-m7t2-opus-bel`, ship `~bel`, tmux session `m7t2opus` |
| Ames port | 31802 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` @ `9de6332` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |

The pier is a fake `~bel`, so it cannot reach `~dister-nomryg-nilref` over Ames.
The `|install ~dister-nomryg-nilref %obelisk` command left `bad desk: %obelisk`.
Obelisk therefore came from the pinned local checkout at `/tmp/obelisk-fresh`,
which is `master` @ `9de6332`. The copied `sur/obelisk-ast.hoon` in that checkout
has the SHA-256 the standing orders pin, and it matches the copy in the Rover
desk byte for byte. The desk went in with `|merge %obelisk our %base`, a file
copy, `|commit %obelisk`, `|install our %obelisk`, and
`|start %obelisk %obelisk`.

## What T2 adds

Two relations, both new. No column reaches a populated relation.

```text
service-subtype-definitions
  (service-subtype-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (service-subtype-id)

vehicle-event-service-subtypes
  (event-id @ux, service-subtype-id @ux)
  PRIMARY KEY (event-id, service-subtype-id)
  FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id)
  (service-subtype-id) REFERENCES service-subtype-definitions (service-subtype-id)
```

The starter pack holds 66 definitions. It reaches the database through
`seed-starters` and its new child `seed-service-subtypes`. The shipping
`$action` union still holds five arms.

## Done-check results

| # | Check | Result |
|---|---|---|
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | PASS |
| 2 | A fresh database gets the starter pack without a page load | PASS |
| 3 | A service event saves with 10 subtypes and renders all 10 | PASS, fixture 18 |
| 4 | One subtype, and zero subtypes with no link row and no sentinel | PASS, fixture 19 |
| 5 | Two events on one definition make no second definition | PASS, fixture 20 |
| 6 | The subtype link rows key to `vehicle-events` | PASS, fixture 16 |
| 7 | Everything above survives a ship restart | PASS, fixture 21 |
| 8 | A person selects several subtypes in the browser and sees them | PASS, fixture 22 |
| 9 | The shipping action union still has five arms | PASS, fixture 13 |
| 10 | Two back-to-back runs, same verdict, no skipped fixture | PASS |

### Done-check 1 — the install

The Rover desk compiled on the first `|install our %rover`. The pier printed:

```text
gall: installing %rover
> |install our %rover
>=
gall: booted %rover
```

No `nest-fail` appeared in the trace.

### Done-check 2 — the starter pack with no page load

`probes/service-subtype-report.hoon` ran through `click` right after the
install, before any HTTP request reached `/apps/rover`. It read 66 rows out of
`service-subtype-definitions`:

```text
Air Conditioning Service, Air Filter, Alternator, Battery, Belts, Body Work,
Brake Fluid, Brake Rotors, Brakes Front, Brakes Rear, Cabin Air Filter,
Car Wash, Catalytic Converter, Clutch, Coolant System, Detailing, Diagnostics,
Diesel Exhaust Fluid, Diesel Particulate Filter, Differential Fluid, EGR Valve,
Emissions Test, Engine Antifreeze, Engine Oil, Engine Tune-Up, Exhaust System,
Fuel Filter, Fuel Injectors, Fuel Pump, Glow Plugs, Headlights, Hoses,
Ignition Coils, Inspection, Insurance, Muffler, New Tires, Oil Filter,
Oxygen Sensor, Parking, Power Steering Fluid, Registration,
Roadside Assistance, Shocks and Struts, Spark Plugs, Starter Motor, Suspension,
Thermostat, Throttle Body Cleaning, Timing Belt, Timing Chain, Tire Repair,
Tire Rotation, Tolls, Towing, Transfer Case Fluid, Transmission Filter,
Transmission Fluid, Turbocharger, Valve Adjustment, Water Pump,
Wheel Alignment, Wheel Balancing, Windshield, Windshield Washer Fluid,
Windshield Wipers
```

The label `Brakes, Front` carries a comma. This table drops the comma to keep
the list readable. The database holds the comma.

### Done-check 6 — the link keys to the event parent

The same probe read `sys.foreign-keys` for the link relation. Both foreign keys
name a parent, and neither names a typed child:

```text
[%parent-table %tas %service-subtype-definitions]
  [%parent-column %tas %service-subtype-id]
  [%child-column %tas %service-subtype-id]
  [%on-delete %tas %restrict] [%on-update %tas %restrict]
[%parent-table %tas %vehicle-events]
  [%parent-column %tas %event-id]
  [%child-column %tas %event-id]
  [%on-delete %tas %restrict] [%on-update %tas %restrict]
```

Fixture 16 repeats this check on every battery run. It also fails the run if
`service-events`, `expense-events`, or `note-events` appears as a parent.

## The battery

`bin/event-test.sh` grew from 15 fixtures to 22. The new ones are 16 through 22.
Every new fixture writes on every run, and every value it asserts on carries the
run stamp. No fixture checks whether its data already exists.

| Fixture | What it proves |
|---|---|
| 16 | Both relations exist, and the link keys to `vehicle-events` |
| 17 | The starter pack is present, each duplicated source label once, and a second `%seed-starters` adds nothing |
| 18 | Ten subtypes on one service event, ten link rows, ten on the card |
| 19 | One subtype reads back. Zero subtypes writes no link row and no sentinel |
| 20 | Two events on one subtype reference one definition row |
| 21 | The catalog and all three link states survive a ship restart |
| 22 | A person picks three subtypes in a real browser and sees all three |

## Run 1, verbatim

```text
event-test: fixture 1 PASS - the owner view serves after bootstrap
event-test: fixture 2 PASS - the eleven event relations exist after the definition-layer catch-up
event-test: fixture 2 PASS - a second catch-up run changes nothing
event-test: fixture 3 PASS - baseline vehicle, fill, station, tag, and payment method exist
event-test: fixture 4 PASS - the service endpoint accepted an entered total
event-test: fixture 5 PASS - the service event, its entered total, its odometer, its station, its tag, and its payment method read back through Eyre
event-test: fixture 6 PASS - fill and service readings share one odometer-observations list
event-test: fixture 6 PASS - the event links to that reading through vehicle-event-odometers
event-test: fixture 7 PASS - the expense event reads back and wrote no sentinel station or odometer row
event-test: fixture 8 PASS - the note event reads back and wrote no zero-cost row
event-test: fixture 9 PASS - the service event and the fill share one station, with no duplicate place or station row
event-test: fixture 10 PASS - tag, payment method, and note rows key to vehicle-events
event-test: fixture 11 PASS - each event has exactly one typed child, and it is the right one
event-test: fixture 11 PASS - the common header carries no kind column
event-test: fixture 16 PASS - the subtype link relation keys to vehicle-events and not to a typed child
event-test: fixture 17 PASS - the subtype starter pack is present, and each duplicated source label is seeded once
event-test: fixture 17 PASS - a second starter seed adds no definition
event-test: fixture 18 PASS - a service event carries ten subtypes at once and renders all ten
event-test: fixture 19 PASS - one subtype reads back, and a zero-subtype event writes no link row and no sentinel
event-test: fixture 20 PASS - two events naming one subtype reference one definition row
event-test: fixture 12 PASS - every event, total, odometer link, station link, and reading survived a ship restart
event-test: fixture 21 PASS - the subtype catalog, the ten links, the one link, and the absent link all survived a ship restart
event-test: fixture 13 PASS - the shipping action union still has five arms
event-test: fixture 15 PASS - the route decides the kind, and the body cannot override it
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: COVERAGE - all 22 defined fixtures executed
```

Exit code 0.

## Run 2, verbatim

Run 2 started right after run 1 finished, on the same pier.

```text
event-test: fixture 1 PASS - the owner view serves after bootstrap
event-test: fixture 2 PASS - the eleven event relations exist after the definition-layer catch-up
event-test: fixture 2 PASS - a second catch-up run changes nothing
event-test: fixture 3 PASS - baseline vehicle, fill, station, tag, and payment method exist
event-test: fixture 4 PASS - the service endpoint accepted an entered total
event-test: fixture 5 PASS - the service event, its entered total, its odometer, its station, its tag, and its payment method read back through Eyre
event-test: fixture 6 PASS - fill and service readings share one odometer-observations list
event-test: fixture 6 PASS - the event links to that reading through vehicle-event-odometers
event-test: fixture 7 PASS - the expense event reads back and wrote no sentinel station or odometer row
event-test: fixture 8 PASS - the note event reads back and wrote no zero-cost row
event-test: fixture 9 PASS - the service event and the fill share one station, with no duplicate place or station row
event-test: fixture 10 PASS - tag, payment method, and note rows key to vehicle-events
event-test: fixture 11 PASS - each event has exactly one typed child, and it is the right one
event-test: fixture 11 PASS - the common header carries no kind column
event-test: fixture 16 PASS - the subtype link relation keys to vehicle-events and not to a typed child
event-test: fixture 17 PASS - the subtype starter pack is present, and each duplicated source label is seeded once
event-test: fixture 17 PASS - a second starter seed adds no definition
event-test: fixture 18 PASS - a service event carries ten subtypes at once and renders all ten
event-test: fixture 19 PASS - one subtype reads back, and a zero-subtype event writes no link row and no sentinel
event-test: fixture 20 PASS - two events naming one subtype reference one definition row
event-test: fixture 12 PASS - every event, total, odometer link, station link, and reading survived a ship restart
event-test: fixture 21 PASS - the subtype catalog, the ten links, the one link, and the absent link all survived a ship restart
event-test: fixture 13 PASS - the shipping action union still has five arms
event-test: fixture 15 PASS - the route decides the kind, and the body cannot override it
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: COVERAGE - all 22 defined fixtures executed
```

Exit code 0. The two runs are line for line the same.

## Other batteries

| Battery | Result |
|---|---|
| `tests/view-linear-test.sh` | PASS |
| `bin/schema-test.sh` | PASS after the relation counts moved from 79 to 81 |
| `bin/ui-test.sh` | Reaches its last check and FAILS there. The failure is not from T2. See below. |

`bin/schema-test.sh` holds the schema contract as literal counts. T2 adds two
relations and two foreign keys, so the numbers moved: 79 relations to 81, 90
declared foreign keys to 92, and 93 live foreign-key metadata rows to 95. The
live pour on the pier reports the new numbers:

```text
schema-test: PASS - SQL/Hoon parity is 81/81 relations; DDL has 92 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 81 relations; all 92 FK constraints (95 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

### A defect T2 found but did not fix

`bin/ui-test.sh` ends with:

```text
ui-test: FAIL - add-fill form asks for a derived total or machine representation
```

Every fixture before it passes. The guard reads:

```bash
if grep -Eq '<input[^>]+name="(total|unitPriceMills|quantityMilli)"' <<<"$view"; then
  fail "add-fill form asks for a derived total or machine representation"
```

It searches the whole served document, not the Add Fill section. M7 T1 added an
Add Event form with `<input name="total">`, and that total is entered on
purpose: a shop invoice has no quantity and no unit price. The string is in
`master`:

```text
$ git show master:desk/lib/rover-view.hoon | grep -o '<input name=\"total\"[^>]*'
<input name=\"total\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"$412.75\"
```

The guard has failed since T1 merged. T2 did not cause it, and T2 did not fix
it. Narrowing another task's guard would hide the question of whether the guard
or the form is wrong. The fix is one line — scope the search to `$fill_html`,
which is what the message already claims — but that call belongs to whoever owns
the T1 form.

## Two substrate findings

Both are recorded in `probes/README.md` beside the earlier pitfalls.

**Identical projected rows come back as one.** Two link rows on two different
events named one definition. A query that projected only
`L.service-subtype-id` returned one vector and `%vector-count 1`. The engine
returns a set, so the two identical projected rows collapsed. Adding
`E.event-id` to the projection returned both rows. A fixture that reads a link
count from a single-column projection under-reports it.

**The battery's pier-restart lookup was fragile.** Fixture 12 read the Ames port
out of the process arguments of the first child of the tmux pane. After the
fixture restarts the pier, the pane process can be the urbit king itself, and
its first child is the `urbit work` serf. The serf carries the pier path but no
`-p` flag, so the lookup returned nothing and the third consecutive run failed
with `cannot read the Ames port`. The lookup now searches the pane process and
its children, and skips the serf. This is battery infrastructure, not the T1
event shape.
