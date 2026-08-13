# Rover vehicle scope results

Date: 2026-08-12. Branch: `fix/vehicle-scoped-history-statistics`.

Pier: `/home/michael/piers/rover-statscope-bel`. This run created the
disposable fake `~bel` with Ames port 31470 and the `brass-408k-1.pill`.
The pier runs in tmux session `statscope`. Obelisk is the unmodified
`9de633299b373a1047490b48281a40b457fb2043` pin. It runs as its own desk
after `|start %obelisk %obelisk`.

## Repair

`POST /apps/rover/view` accepts a JSON object with string fields `page`
and `vehicle`. The old bare page number still works. A GET has no explicit
scope, so the server uses the app default vehicle. If no default exists,
the scoped screens are empty.

The page renderer resolves the label to a full vehicle row. History and
Statistics both use the existing `rows-for` arm before ordering and before
the 25-row window. Pagination uses the length of that scoped list. All
Statistics helpers get the scoped vehicle and fills. This includes the
lifetime average-price helper. DEF-only statistics stay available because
the no-data decision also checks scoped DEF purchases.

The browser sends the selected vehicle when either selector changes. It
also sends that vehicle for later pages. Client-side row hiding stays as a
progressive display step, but it is not the data-scope mechanism.

`ordered-history` and its vehicle-settings caller did not change.

## RED mutation run

I temporarily replaced both `rows-for` calls with the unfiltered `fills`
list. I committed that temporary desk to the same real pier and ran the
full UI command. The import through Eyre succeeded, and the first scoped
census failed. This is the real output:

```text
$ bash bin/ui-test.sh /home/michael/piers/rover-statscope-bel
...
ui-test: fixture 116 PASS - a batch the desk refuses stops the browser where it stands, names the batch and the desk verdict, and holds back every batch behind it
ui-test: fixture 117 PASS - the real import endpoint added a 30-fill vehicle and a 3-fill vehicle
history rows 25, want 3: ['Structure Vehicle', 'History Vehicle 1786593714924178982', 'Fill Edit Vehicle 1786593694869984782', 'Fixture 46 PHEV 1786593704473761198', 'Phase A Vehicle', 'Phase A Vehicle', 'Structure Vehicle', 'Structure Vehicle', 'Phase A Vehicle', 'Fill Edit Vehicle 1786593694869984782', 'Fill Edit Vehicle 1786593694869984782', 'Fill Edit Vehicle 1786593694869984782', 'Phase A Vehicle', 'Fill Edit Vehicle 1786593694869984782', 'Preference Vehicle', 'Fill Edit Vehicle 1786593694869984782', 'Fill Edit Vehicle 1786593694869984782', 'Statscope Many Gasoline', 'Statscope Many Gasoline', 'Statscope Many Gasoline', 'Statscope Many Gasoline', 'Statscope Many Gasoline', 'Statscope Many Gasoline', 'Statscope Many Gasoline', 'Statscope Many Gasoline']
ui-test: FAIL - fixture 118 few-fill scope is not isolated:
EXIT=1
```

The temporary mutation was then removed. The final desk contains both
`rows-for` calls.

## GREEN UI run

The command ran the complete default UI battery. These are the final,
unedited scope and coverage lines from the real run:

```text
$ bash bin/ui-test.sh /home/michael/piers/rover-statscope-bel
...
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
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - ran 71 of 99 defined fixtures
ui-test: COVERAGE - SKIPPED, not executed this run: 57 58 59 60 61 62 63 64 65 66 67 69 76 77 78 79 82 83 94 95 96 97 98 99 100 101 102 104
ui-test: COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
EXIT=0
```

The census reads the served HTML. It counts
`data-history-vehicle` articles and `data-statistics-vehicle` table rows.
It fails if any row names a vehicle other than the requested scope. It
also checks the exact dates, subtype, row count, and page text. The
few-fill check requires both `Unavailable` and the eligible-interval
refusal text.

The two GET lines are separate requests. Before each request, the battery
sets that vehicle as the app default through the real product endpoint.
Each GET returned 200 and contained only that default vehicle.

## Schema run

```text
$ bash bin/schema-test.sh /home/michael/piers/rover-statscope-bel
schema-test: PASS - SQL/Hoon parity is 68/68 relations; DDL has 75 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
EXIT=0
```

## Fence checks

The action union still contains exactly five arms: `init-db`,
`ensure-ui-schema`, `ensure-def-schema`, `verify-schema`, and
`seed-starters`. No schema file changed. The Obelisk API mold hash is:

```text
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2  desk/sur/obelisk-ast.hoon
```
