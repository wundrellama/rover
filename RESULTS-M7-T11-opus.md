# RESULTS — M7 T11, statistics for the event families (branch `ab-m7t11-opus`)

Date: 2026-08-18. Every number below comes from a run on a real pier against
the pinned Obelisk agent through real Eyre. No number comes from a mock.

## Outcome

Statistics knew about fuel fills and DEF purchases. The six M7 event families
carried real money that the screen never showed. T11 adds the read path.

Four tables join the seven that were there:

1. Total cost of ownership
2. Cost per distance
3. Spend by family
4. Service history summary

Every figure is derived on the read. T11 adds no relation, no column, and no
cached total. The shipping `$action` union still holds five arms.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t11-opus`, branch `ab-m7t11-opus`, off `master` at `4759008` |
| Pier | `/var/home/michael/piers/rover-m7t11-opus-bel`, ship `~bel` |
| tmux session | `m7t11opus` |
| Ames port | 32710 |
| Eyre port | 8118 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk source | `/tmp/obelisk-fresh`, `master` @ `9de633299b373a1047490b48281a40b457fb2043` |
| Obelisk install path | own unmodified desk: `|merge %obelisk our %base`, `|mount %obelisk`, file copy, `|commit %obelisk`, `|install our %obelisk`, `|start %obelisk %obelisk` |
| Copied `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |

The fake `~bel` has no network route to `~dister-nomryg-nilref`, so both desks
went in locally. Rover went in the same way as Obelisk, without the start
command. The first install printed:

```text
gall: installing %rover
> |install our %rover
>=
gall: booted %rover
```

The pane held no `nest-fail` at any point. Every later source commit printed
`gall: bumped %rover`.

**Boot the pier as the pane command.** The battery finds the pier through the
tmux pane pid. A pier started by typing into a shell inside the pane leaves the
shell as the pane process, and `restart_test_pier` cannot find it. The pier was
rebooted as `urbit -p 32710 <pier>`, which is the form the battery reconstructs.

## What the four tables do

**Total cost of ownership.** Fuel, charging, service, expense, consumables, and
the purchase, less what a sale returned. One row per ownership interval.

**Cost per distance.** Total spend over the distance the odometer shows for the
period. The existing tables divide fuel alone, so a diesel's maintenance bill
was invisible next to its fuel bill.

**Spend by family.** One row per family per period, with the record count and
the total. Fuel, Service, Expense, Consumables, Purchase, and Sale always
render. Charging and Note render only where they hold a record.

**Service history summary.** Visits and cost by service subtype, so a person
sees what the vehicle needs repeatedly. A visit counts under every subtype it
names. The last row of each period counts each visit once, so the table carries
an unduplicated figure as well as the per-subtype one.

## The rules, and where each one lives

**Derived, not stored (ruling 12).** `++cost-ledger` in `desk/lib/rover-view.hoon`
reduces every family to mills, a date, and a name, on the read. The four render
arms read that list. Nothing writes a row.

**Ruling 11 pays for the whole task.** Cost attaches to the family parent, so
one walk reads seven families. The diff adds one query and no relation.

**Ownership bounds every aggregate (T5).** `++cost-scopes` turns a vehicle's
ownership intervals into the periods the tables report. A vehicle with no
purchase and no sale gets one period named `Lifetime`, which is what every
database installed before M7 T4 holds. A vehicle with two or more intervals
gets one row group per interval plus a `Whole history` row that refuses. The
refusal carries the sentence T5 already wrote:

```text
The vehicle was not owned for part of this interval, so it is unavailable.
```

**Exact integer arithmetic.** Fuel and consumable totals come from
`derive-fill-total:act`. Charging totals come from the receipt row, or from
`derive-charging-total:act` over the itemized components. Event totals are the
entered figures ruling 13 allows. Every sum is in mills.

**The boundary speaks human (ruling 8).** `++format-money-mills` prints a sum as
money when the sum is exactly money, and prints thousandths when a charging
tariff makes it finer. It never rounds. Distances print through
`format-distance-milli`. No database ID reaches the screen.

**Honest absence.** A family with no record prints `Not recorded`. A vehicle
with no service record prints `No service record falls in this period.` Neither
prints `$0.00`.

**urQL, server side.** T11 adds one query, `++consumable-cost-query` in
`desk/lib/rover-act.hoon`. It is last in the script, so no earlier index moves.
It is wide and names the acquisition key, so Obelisk cannot collapse two
purchases that cost the same. Every other list the four tables read was already
read for History.

**Tables only.** No `<canvas>`, no `<svg>`, no `chart`. Fixture 85 still passes.

## Where the brief and the build differ

The brief says total cost of ownership is "fuel plus every event family
carrying a cost". A disposal carries a cost, and it is money received. Adding
it to a cost would state that selling a car for $15,000 made the car cost
$15,000 more.

**Total cost of ownership is spend less amounts received.** Fixture 136 shows
the first ownership interval of the gap vehicle: a $20,000 purchase and a $300
service, less a $15,000 sale, is $5,300.00. Spend by family shows the sale on
its own row as `-$15,000.00`, so the arithmetic is visible and the rows add to
the total.

**Cost per distance uses gross spend.** A sale is not deducted there, because a
sale is not a distance-related cost. The Basis column says so.

Nothing else in the brief was substituted.

## Design latitude used

- **One period column on all four tables.** T5 refuses cross-gap figures with a
  reason, and the brief asks the same of aggregates. One uniform scope list
  gives all four tables the same posture and one code path.
- **A `Charging` family row, rendered only when it holds a record.** The brief
  names six families. A plug-in hybrid's electricity spend would otherwise
  vanish from the total, which is the defect this task exists to fix.
- **A `Note` family row, on the same condition.** A note event may carry a cost.
  Dropping it would lose money from the total, and folding it into Expense
  would state something the owner did not record.
- **`Purchase` and `Sale` as the family names.** The event card already prints
  `PURCHASE PRICE` and `AMOUNT RECEIVED`. `Acquisition` and `disposal` are
  relation names.
- **A refused whole-history row rather than a hidden one.** A missing row reads
  as "nothing to report". A row that says `Unavailable` and gives the reason
  reads as a refusal.
- **Mixed currency refuses.** A period holding more than one currency prints
  `Unavailable` and the reason. The lifetime average-price table already takes
  this posture.
- **Service cost by subtype counts the whole visit under each subtype it
  names.** The column header says `Cost of those visits`, and the last row of
  each period gives the unduplicated figure. Attributing a share of one invoice
  to each of ten subtypes would invent a number the owner never recorded.
- **A distance in a period needs two readings in that period.** A period with
  one reading, mixed units, or an odometer that did not advance prints
  `Unavailable` with the specific reason.
- **No fifth table.** The four cover the question. A fifth would repeat them.

## Stale assertions, and which side was wrong

| Assertion | Which side was wrong | What changed |
|---|---|---|
| `bin/ui-test.sh` looked for `EXPORT.*COMING LATER` | the battery | T10 shipped a real download control at `rover-view.hoon:1298`. The assertion now names the export section, the download control, and the `/apps/rover/export` address, and refuses the placeholder. `GRANTS - COMING LATER` stays. |
| `bin/ui-test.sh` refused `name="total"` anywhere in the served view | the battery | Ruling 13 makes an event total an entered field, and Add Event carries `name="total"`. A fill total has operands, so Rover calculates it. The assertion is now scoped to the Add Fill form. |
| Fixtures 58, 59, and 61 read the diesel demo figures from a gasoline-scoped view | the battery | Statistics has served one vehicle at a time since the 2026-08-12 scope repair. Each fixture now sets the diesel vehicle as the default through the real endpoint, reads that view, and restores gasoline. |
| Fixture 65 expected seven tables to change on a scope switch | the battery | The screen now has eleven tables. The row signature also carries each row's vehicle, so a table that is empty for both demo vehicles still proves its scope changed. |
| Fixtures 118 to 121 counted 16, 126, and 26 statistics rows | the battery | The four new tables add nine rows per vehicle: one total, one rate, six families, and one service line. The counts are now 25, 135, and 35. |
| `bin/view-performance-test.sh` measured a view with no default vehicle | the battery | History and Statistics serve the selected vehicle. The guard poured a fresh database and never named one, so it timed a page with zero history rows. The guard now sets the imported vehicle as the default through the real endpoint. |

`bin/schema-test.sh` is red, and T11 did not cause it and did not repair it. It
holds a hardcoded expectation of 81 relations and was last touched at M7 T2.
M7 T4 through T7 added relations after that. The DDL holds 89 unique
`CREATE TABLE rover..` statements at `master` `4759008` and 89 at this branch
head, so T11 adds no table. The brief scopes this task to `bin/ui-test.sh` and
`bin/event-test.sh`.

## The failing runs, before the passing ones

Each mutation below changed the product, ran the full battery on the same real
pier, and was then reverted. These are the unedited failure lines.

**Consumables dropped from the ledger.** `:(weld fuel electric recorded)`:

```text
ui-test: FAIL - fixture 134 spend by family is not the exact parts: PARTS=expense:$45.50|fuel:$60.18|service:$900.00
```

**Cost per distance divides fuel spend.** `(scope-totals scope (family-entries %fuel ledger))`:

```text
ui-test: FAIL - fixture 135 cost per distance did not follow total spend: {"attributes": {"statistics-vehicle": "T11 Rate Vehicle 1787108191032700975", "cost-scope": "Lifetime", "cost-per-distance": "$0.030 per mi"}, "cells": ["Lifetime", "1,000 mi", "$0.030 per mi", "Total spend over distance travelled; a sale is not deducted."]}
```

**Ownership ignored.** `++cost-scopes` returns one unbounded `Lifetime` scope:

```text
ui-test: FAIL - fixture 136 total-cost-of-ownership has no whole-history row: {"attributes": {"statistics-vehicle": "T11 Gap Vehicle 1787108356985392251", "cost-scope": "Lifetime", "total-cost": "$14,450.00"}, "cells": ["Lifetime", "5", "$14,450.00", "Every priced record, less amounts received."]}
```

That is the defect ruling 12 exists to prevent. The figure is arithmetically
clean, carries no warning, and divides by 36,000 miles. The owner drove 8,000
of them.

**Absence rendered as a zero.** `Not recorded` and the empty-state sentence
replaced by `$0.00`:

```text
ui-test: FAIL - fixture 137 the empty service summary states no reason: {"attributes": {"statistics-vehicle": "T11 No Service Vehicle 1787108527099921356", "cost-scope": "Lifetime", "service-summary-empty": "Lifetime"}, "cells": ["Lifetime", "$0.00"]}
```

## The six fixtures that decide the task

```text
ui-test: fixture 134 cost census - PARTS=consumable:$40.05|expense:$45.50|fuel:$60.18|service:$900.00 ABSENT=acquisition|disposal TOTAL=$1,045.73 SUM=yes
ui-test: fixture 134 PASS - fuel, service, expense, and consumable records add to an exact $1,045.73 total cost of ownership
ui-test: fixture 135 rate census - before="cost-per-distance": "$0.030 per mi" after="cost-per-distance": "$0.530 per mi" fuel unchanged at $30.09 over 1,000 mi
ui-test: fixture 135 PASS - cost per distance divides total spend: one $500 service moved it from $0.030 to $0.530 per mi while the fill stood still
ui-test: fixture 136 gap census - 2024-01-10 to 2024-12-01=$5,300.00 2026-02-01 to now=$9,150.00 Whole history=Unavailable
ui-test: fixture 136 PASS - each ownership interval computes on its own and the combined figure is refused with the ownership sentence
ui-test: fixture 137 PASS - a vehicle with no service record states the absence and never renders $0.00
ui-test: fixture 138 PASS - at 390px every new statistics table fits with no horizontal overflow, for one ownership interval and for a gap
ui-test: fixture 139 PASS - the four cost tables, their exact figures, and the ownership-gap refusal survive a ship restart
```

Fixture 138 is a real Chromium at a 390 by 844 viewport. Its measurement:

```text
ui-test: fixture 138 statistics layout - {"single":{"viewport":390,"documentOverflow":0,"tables":[{"name":"total-cost-of-ownership","present":true,"rows":1,"overflow":-24,"right":365},{"name":"cost-per-distance","present":true,"rows":1,"overflow":-24,"right":365},{"name":"spend-by-family","present":true,"rows":6,"overflow":-24,"right":365},{"name":"service-summary","present":true,"rows":2,"overflow":-24,"right":365}]},"gapped":{"viewport":390,"documentOverflow":0,"tables":[{"name":"total-cost-of-ownership","present":true,"rows":3,"overflow":-24,"right":365},{"name":"cost-per-distance","present":true,"rows":3,"overflow":-24,"right":365},{"name":"spend-by-family","present":true,"rows":13,"overflow":-24,"right":365},{"name":"service-summary","present":true,"rows":5,"overflow":-24,"right":365}]}}
```

Every table ends 25 pixels inside the viewport, and the document has no
horizontal overflow. The gap vehicle is measured too, because its refusal rows
carry a whole sentence.

## The two back-to-back battery runs

Both commands ran on the same live pier, one after the other, with no rebuild
and no restart between them. Both exited 0.

Run 1, verbatim final lines:

```text
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - all 116 defined fixtures executed
```

Run 2, verbatim final lines:

```text
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - all 116 defined fixtures executed
```

The coverage line reports every defined fixture and names no skip. The
`ROVER_DEMO_ONLY=1` flag is what runs the demo-gated fixtures. A plain run
exits 0 and reports `ran 88 of 116 defined fixtures`, and it names the 28 it
did not reach. The six T11 fixtures are behind no flag and run in both modes.

### What "the second run sees the first run's data" means for this battery

`bin/ui-test.sh` isolates itself. It renames the owner database, pours a
disposable one, runs, and restores the owner database at the end. Fixture 75 is
the assertion that it does exactly this. So the second run cannot read the
first run's rows out of the disposable database, by ratified design.

The grown-database evidence therefore comes from two places.

**`bin/event-test.sh` writes into the owner database and never drops it.** Both
runs below ran back to back on the same pier, and the second read the first
run's rows:

```text
event-test: round-trip relation vehicle-events: 31 -> 31       (run 1)
event-test: round-trip relation vehicle-events: 62 -> 62       (run 2)
event-test: round-trip relation odometer-observations: 51 -> 51   (run 1)
event-test: round-trip relation odometer-observations: 102 -> 102 (run 2)
```

**The six T11 fixtures also ran once against the grown owner database.** With
`ROVER_NO_FIXTURE_ISOLATION=1` the battery works directly on the owner
database, which then held 26 vehicles and 72 fills from earlier runs. All six
passed there:

```text
ui-test: fixture 134 cost census - PARTS=consumable:$40.05|expense:$45.50|fuel:$60.18|service:$900.00 ABSENT=acquisition|disposal TOTAL=$1,045.73 SUM=yes
ui-test: fixture 139 PASS - the four cost tables, their exact figures, and the ownership-gap refusal survive a ship restart
```

That run stopped at fixture 75, which is correct: fixture 75 asserts the owner
database is unchanged, and a run without isolation changes it. Its scenario
rows were then cleared by dropping the owner database once, before both runs
above. Rover's bootstrap re-poured and re-seeded it, which fixture 127 already
covers.

Every T11 vehicle carries `$(date +%s%N)` in its label, so a second run on the
same database writes and reads its own rows. No T11 write is guarded behind an
existence check.

## `bin/event-test.sh`

Green at 86 in both runs.

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 86 defined fixtures executed
```

## Restart

Two independent restarts prove persistence.

`ui-test` fixture 139 stops the whole pier in tmux, starts it again, logs in
again with `+code`, and re-reads the four tables. It compares the rendered rows
of total cost of ownership, of the service summary, and of the gap vehicle's
refusal against the pre-restart rows, character for character.

`event-test` fixture 12 restarts the pier in both runs:

```text
event-test: fixture 12 PASS - every event, total, odometer link, station link, and reading survived a ship restart
```

## Performance

`bin/view-performance-test.sh` pours a fresh database, imports a synthetic
420-fill vehicle, and times the served view twice.

| Run | Time 1 | Time 2 | Bytes |
|---|---|---|---|
| Before T11, `master` desk | 0.679336s | 0.654774s | 337,551 |
| After T11 | 0.662723s | 0.659342s | 340,874 |

The four tables cost no measurable time and 3,323 bytes on this vehicle.

The read is not quadratic. Doubling the history multiplies the time by 1.71,
not by 4:

```text
view-performance-test: run 1 - 0.662723s, 340874 bytes, 25 of 420 fills
view-performance-test: run 1 - 1.132366s, 404294 bytes, 25 of 840 fills
```

The shape of the code says the same thing. `++cost-ledger` builds its five
event-kind sets and its four lookup maps once, in one pass over each list, and
then walks each list once. Asking "which kind is this event" against five lists
per event is quadratic in history length, so the sets exist. Each render arm
walks the finished ledger a fixed number of times, and the number of ownership
intervals is the number of times a vehicle changed hands.

No derived value is cached into a relation.

## Fence checks

- No new relation and no new column. The DDL holds 89 unique
  `CREATE TABLE rover..` statements at `master` `4759008` and 89 at this branch
  head. The diff adds zero `CREATE TABLE`, `ALTER TABLE`, and `ADD COLUMN`
  lines.
- The `$action` union in `desk/sur/rover.hoon` holds five arms: `init-db`,
  `ensure-ui-schema`, `ensure-def-schema`, `verify-schema`, `seed-starters`.
- No test scaffolding entered the shipped desk.
- The Obelisk API mold is unchanged:
  `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2  desk/sur/obelisk-ast.hoon`
- `find <pier>/rover -type d -empty -delete` ran before every desk commit.

## Files changed

```text
desk/lib/rover-act.hoon      one query, ++consumable-cost-query
desk/lib/rover-view.hoon     the cost molds, the ledger, the four render arms
bin/ui-test.sh               six new fixtures, six stale assertions repaired
bin/ui-browser-fixtures.cjs  the statistics-layout browser mode
bin/view-performance-test.sh names a default vehicle before it measures
```
