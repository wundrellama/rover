# Bootstrap latch results

Date: 2026-08-13

Branch: `fix/bootstrap-latch`

Base commit: `f0b0a05`

Pier: `/home/michael/piers/rover-statscope-bel`

## State design

`state-17` adds `bootstrap-ready=?`. A Boolean latch is sufficient because
Rover needs only the saved readiness fact. No product or recovery decision uses
the completion time. A timestamp would add state that has no consumer.

The `%16` load arm copies every `state-16` field and sets the latch to
`%.n`. The `%0` through `%15` arms remain in their original order and also
produce a clear latch. `on-save` writes `%17`.

A clear latch starts the database probe. Rover sets the latch after it confirms
an existing database, after it confirms that no starter rows are missing, or
after it writes the missing starters. A set latch starts the view query
directly. A refused direct view moves the same request to one database probe.
Every view query after that probe uses a `final` wire. A refusal on that wire
returns the existing human-readable view refusal and cannot start another
probe.

## Observation method

The new fixtures use the Urbit runtime event trace. Each request enables
`|verb`, drives the authenticated Eyre request, captures the tmux pane, and
counts outbound Gall deal cards to `%obelisk %poke`. A database probe is a
poke whose wire contains `rover-bootstrap-probe`. A view query is a poke whose
wire contains `rover-http`.

The counter checks outbound poke cards, so acknowledgements, facts, and kicks
do not increase the count. This is runtime observation of the real Gall cards
on the real pier. It does not inspect the Hoon source to infer a count.

## RED proof

I temporarily changed both view entry paths back to the unconditional
`sys.databases` probe, committed that desk to the pier, and ran the focused
fixtures. The command exited with status 1:

```text
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: bootstrap cold transcript - database-before=absent GET-status=200 probe-pokes=1 view-pokes=1 starters=Gasoline|Diesel empty-state=Add-a-fill-to-begin-tracking
ui-test: fixture 122 PASS - a cold GET creates the database, seeds starters, and serves the usable empty state
ui-test: FAIL - fixture 125 second view sent 1 database probes, want 0
```

I then restored the latch before all final GREEN runs.

## Focused GREEN proof

Command:

```text
ROVER_BOOTSTRAP_LATCH_ONLY=1 bash bin/ui-test.sh /home/michael/piers/rover-statscope-bel
```

Output:

```text
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: bootstrap cold transcript - database-before=absent GET-status=200 probe-pokes=1 view-pokes=2 starters=Gasoline|Diesel empty-state=Add-a-fill-to-begin-tracking
ui-test: fixture 122 PASS - a cold GET creates the database, seeds starters, and serves the usable empty state
ui-test: bootstrap second-load transcript - GET-status=200 probe-pokes=0 view-pokes=1
ui-test: fixture 125 PASS - the second view skips the database probe
ui-test: bootstrap restart transcript - GET-status=200 probe-pokes=0 view-pokes=1 before=fills=0 starter-energy-definitions=8 after=fills=0 starter-energy-definitions=8
ui-test: fixture 126 PASS - the saved latch skips the probe after restart and keeps the data
ui-test: bootstrap self-heal transcript - database-before=absent GET-status=200 probe-pokes=1 view-pokes=2 database-after=present starter=Gasoline
ui-test: fixture 127 PASS - one failed latched view re-probes, restores the database, and serves
```

The first request observed one probe. The second request observed none. The
cold and self-heal requests each show two view pokes because the saved true
latch first sends a direct view and the final wire serves after the one probe.
After the real pier stopped and restarted, the next request observed none. The
row counts remained `fills=0 starter-energy-definitions=8`. After the isolated
`rover` database was dropped with the latch set, one request observed one
probe, recreated the database, restored the starters, and returned HTTP 200.

## State migration transcript

The mounted pier held the state saved by `f0b0a05`. I committed the
`state-17` desk without a nuke. Gall loaded and bumped the agent:

```text
> |commit %rover
>=
gall: reloading %rover
eyre: replacing existing binding at /apps/rover
: /~bel/rover/19/app/rover/hoon
gall: bumped %rover
~bel:dojo>
```

This exercises the `%16` to `%17` load arm on saved agent state.

## Full UI battery

Command:

```text
bash bin/ui-test.sh /home/michael/piers/rover-statscope-bel
```

The command exited with status 0. Full output:

```text
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: bootstrap cold transcript - database-before=absent GET-status=200 probe-pokes=1 view-pokes=2 starters=Gasoline|Diesel empty-state=Add-a-fill-to-begin-tracking
ui-test: fixture 122 PASS - a cold GET creates the database, seeds starters, and serves the usable empty state
ui-test: bootstrap second-load transcript - GET-status=200 probe-pokes=0 view-pokes=1
ui-test: fixture 125 PASS - the second view skips the database probe
ui-test: bootstrap restart transcript - GET-status=200 probe-pokes=0 view-pokes=1 before=fills=0 starter-energy-definitions=8 after=fills=0 starter-energy-definitions=8
ui-test: fixture 126 PASS - the saved latch skips the probe after restart and keeps the data
ui-test: bootstrap self-heal transcript - database-before=absent GET-status=200 probe-pokes=1 view-pokes=2 database-after=present starter=Gasoline
ui-test: fixture 127 PASS - one failed latched view re-probes, restores the database, and serves
ui-test: authenticated Rover shell served over real Eyre
ui-test: fixture 103 PASS - served footer carries the Rover label and no hardcoded ship literal
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 68 PASS - served Energy Source set is exactly the eight starters with zero Demo definitions
ui-test: fixture 70 PASS - two consecutive tank-size edits succeeded and the second exact value persisted
ui-test: fixture 71 PASS - two consecutive default-subtype edits succeeded and the latest subtype persisted
ui-test: fixture 72 PASS - one submission persisted both exact tank size and default subtype
ui-test: fixture 73 PASS - clearing tank size leaves no row and restores the hub unavailable reason
ui-test: fixture 74 PASS - label, display preference, energy sources, driving modes, DEF enablement, and DEF tank size survive repeated edits
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: fixture 38 field gate PASS - fill-edit screen exposes owner controls, including Partial fill, for every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: fixture 40 PASS - manual stations persist formatted+parts and parts-only address evidence; omitted children create no rows
ui-test: fixture 41 PASS - name-only manual station writes no empty address or formatted rows and no zero-coordinate row
ui-test: fixture 42 PASS - DEF purchase uses snapshotted exact pricing and remains outside fuel-economy derivation
ui-test: fixture 43 PASS - charge persists its electricity subtype through charging-session-subtype
ui-test: fixture 105 PASS - the add-charge surface records six itemized components and the view derives the same total derive-charging-total proves
ui-test: fixture 106 PASS - a receipt-only total survives as reported evidence with no components and no derived total
ui-test: fixture 107 PASS - Rover refuses an empty itemized set, a receipt total with components, an unknown component kind, a cost total on a free charge, and a discount larger than its charges, and writes none of them
ui-test: fixture 44 PASS - payment method is descriptive; settlement mode and derived total are identical with or without its link
ui-test: fixture 45 PASS - the run reached fixture 44 and the served source selector still has exactly eight owner sources
ui-test: fixture 46 PASS - create persisted active Gasoline and Electricity links and the vehicle hub offers fill and charge
ui-test: fixture 47 PASS - edit retired Gasoline with literal Y, retained Electricity, and preserved the historical fill
ui-test: fixture 48 PASS - create and edit mode memberships persist; the non-member mode is absent for the vehicle
ui-test: fixture 49 PASS - enabled Diesel has an active DEF link; disabled Diesel has no link row
ui-test: fixture 50 PASS - composite DEF tank size stores exact 55/1/gal, absence creates no row, and settings re-render 5.5 gal
ui-test: fixture 51 PASS - two odometer-linked DEF purchases derive and render exact 500.000 mi/gal DEF
ui-test: fixture 52 PASS - missing odometer evidence explicitly breaks the latest DEF interval with a human reason
ui-test: fixture 53 PASS - DEF remains outside fuel acquisitions and leaves exact 9.000 mpg unchanged
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: fixture 108 PASS - add-charge offers all four cost states with repeatable itemized component rows and a receipt total field
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: fixture 20 PASS - live Obelisk kept one %app row across INSERT/UPDATE and rejected a second INSERT
ui-test: fixture 21 PASS - live HTTP refused archiving the app-default vehicle until redesignation
ui-test: browser measurements: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Temporary Vehicle 1786659465515859397 subtypes=91/100|85|87|88|89|90|91|92|93|95|98 modes=Tow / Haul/0 history=Temporary Vehicle 1786659465515859397/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: fixture 19 PASS - Chromium measured every source subtype selectable with only the default preselected: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Temporary Vehicle 1786659465515859397 subtypes=91/100|85|87|88|89|90|91|92|93|95|98 modes=Tow / Haul/0 history=Temporary Vehicle 1786659465515859397/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 26 PASS - Chromium measured Tow / Haul for an assigned vehicle and zero modes for a non-member vehicle: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Temporary Vehicle 1786659465515859397 subtypes=91/100|85|87|88|89|90|91|92|93|95|98 modes=Tow / Haul/0 history=Temporary Vehicle 1786659465515859397/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 28 PASS - Chromium measured single-source as a vehicle property; live PHEV HTTP already exposed fill and charge: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Temporary Vehicle 1786659465515859397 subtypes=91/100|85|87|88|89|90|91|92|93|95|98 modes=Tow / Haul/0 history=Temporary Vehicle 1786659465515859397/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 31 PASS - Chromium measured 390px overflow, stacking, and touch targets: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Temporary Vehicle 1786659465515859397 subtypes=91/100|85|87|88|89|90|91|92|93|95|98 modes=Tow / Haul/0 history=Temporary Vehicle 1786659465515859397/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: app default inserts once, changes via UPDATE, refuses archive, and Vehicles add/archive round-trips
ui-test: fixture 18 PASS - live Obelisk report ties the selected subtype to rating 93
ui-test: fixture 23 PASS - live Obelisk counts stayed equal for unset balance and report stored asserted 73
ui-test: fixture 27 PASS - live Obelisk counts stayed equal for zero tags and linked existing plus inline tags
ui-test: subtypes, missed-fill break, scoped mode, exact speed, unset/asserted balance, and zero/many tags persist through real Obelisk
ui-test: fixture 22 PASS - live Obelisk break and served HTML retain the missed-fill reason in human text
ui-test: fixture 30 PASS - live History default/detail measurement and Obelisk edit round-trip rendered 3.333 / $12.00
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: fixture 24 PASS - live hub says tank size is not recorded instead of storing or rendering a sentinel
ui-test: fixture 29 PASS - live hub combines human odometer units with concrete unavailable reasons
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: fixture 25 PASS - live HTTP and Obelisk report prove typed values, mandatory validation, and immutable used type
ui-test: tile and both JetBrains Mono faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
ui-test: fixture 88 PASS - new PNG serves exact bytes as image/png and the docket charges its same-origin tile path
ui-test: fixture 81 PASS - add controls persist new source/mode types and expose them as checkbox choices
ui-test: fixture 80 PASS - literal-Y archive hides selectors, preserves history, and refuses the app default until redesignation
ui-test: fixture 84 PASS - rendered header contains the running ship and current default vehicle, with no decorative placeholders
ui-test: fixture 85 PASS - rendered header states NO DEFAULT VEHICLE when the singleton row is absent
ui-test: fixture 86 PASS - changing the app default refreshes the rendered header vehicle label
ui-test: fixture 87 PASS - bounded glow slider disables with the toggle, persists across reload, and drives a materially stronger CSS shadow
ui-test: fixture 109 PASS - a real browser fills repeatable itemized component rows, previews the exact derived total, and saves it through Eyre
ui-test: fixture 89 PASS - Enable DEF and DEF tank size are separate labelled controls and DEFDEF is absent
ui-test: fixture 90 PASS - default energy is inside its source group and Rover rejects a forged disallowed default before writing
ui-test: fixture 91 PASS - Fuel System contains subtype, tank size, units, and refill reserve and precedes Energy Sources, Driving Modes, and DEF
ui-test: fixture 92 PASS - at 390px the reorganised settings has no horizontal overflow and every enabled touch target is at least 44px
ui-test: fixture 110 PASS - Settings opens a hidden import entry screen carrying a .json file input, a batch size, a validate step, and a submit control
ui-test: fixture 111 PASS - the browser batch split equals the one tools/rover-import/upload.py builds for the same document and batch size
ui-test: fixture 112 PASS - a real browser split a two-vehicle six-fill document into three batches, posted them one at a time, and every record landed although both vehicles span batches
ui-test: fixture 113 PASS - the aggregate the browser renders equals the sum of its per-batch reports, line for line with the one upload.py prints
ui-test: fixture 114 PASS - re-uploading the same document reported already-imported 6 and wrote nothing
ui-test: fixture 115 PASS - the browser refuses a bad version, a non-list vehicles key, and a vehicle without fills, and posts nothing
ui-test: fixture 116 PASS - a batch the desk refuses stops the browser where it stands, names the batch and the desk verdict, and holds back every batch behind it
ui-test: fixture 117 PASS - the real import endpoint added a 30-fill vehicle and a 3-fill vehicle
ui-test: statscope few-fill census - history=3 statistics=16 vehicles=['Statscope Few Diesel']
ui-test: fixture 118 PASS - the selected 3-fill diesel vehicle keeps its honest interval refusal
ui-test: statscope many-fill page 1 census - history=25 statistics=126 vehicles=['Statscope Many Gasoline']
ui-test: fixture 119 PASS - History and Statistics page inside the selected 30-fill vehicle
ui-test: statscope many-fill page 2 census - history=5 statistics=26 vehicles=['Statscope Many Gasoline']
ui-test: fixture 120 PASS - page 2 stays inside the selected vehicle and serves its last 5 fills
ui-test: statscope GET status=200 census for Statscope Many Gasoline - history=25 statistics=126 vehicles=['Statscope Many Gasoline']
ui-test: statscope bare-page POST status=200 census - history=25 statistics=126 vehicles=['Statscope Many Gasoline']
ui-test: statscope GET status=200 census for Statscope Few Diesel - history=3 statistics=16 vehicles=['Statscope Few Diesel']
ui-test: fixture 121 PASS - GET serves both defaults and the old bare-page POST stays compatible
ui-test: bootstrap idempotence counts - before fills=56 starter-energy-definitions=8 after fills=56 starter-energy-definitions=8
ui-test: fixture 123 PASS - a populated view does not re-pour, re-seed, or change fill and starter counts
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - ran 77 of 105 defined fixtures
ui-test: COVERAGE - SKIPPED, not executed this run: 57 58 59 60 61 62 63 64 65 66 67 69 76 77 78 79 82 83 94 95 96 97 98 99 100 101 102 104
ui-test: COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
```

## Schema battery

Command:

```text
bash bin/schema-test.sh /home/michael/piers/rover-statscope-bel
```

The command exited with status 0. Full output:

```text
schema-test: PASS - SQL/Hoon parity is 68/68 relations; DDL has 75 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

## Fence checks

The shipping action union still has exactly these five arms:
`init-db`, `ensure-ui-schema`, `ensure-def-schema`, `verify-schema`, and
`seed-starters`.

The task diff does not include `docs/schema-m0.sql`, `desk/sur/rover.hoon`,
or `desk/sur/obelisk-ast.hoon`. The copied and upstream Obelisk AST files both
have this SHA-256:

```text
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2
```

The Hoon source contains only ASCII. The full UI battery kept fixtures 117
through 124 green. Fixture 123 retained all 56 test fills and all eight starter
energy definitions across the populated view request. Fixture 75 restored and
served the owner database after the disposable battery.
