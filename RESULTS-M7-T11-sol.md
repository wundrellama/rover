# M7 T11 Statistics results — sol

## Outcome

Statistics now reads the selected vehicle's event-family costs from Obelisk and
renders four new table sections:

- Total cost of ownership.
- Cost per distance, all-in.
- Spend by family.
- Service history by subtype.

The total combines fuel, consumables, service, expense, note, and acquisition
costs, then treats disposal proceeds as a credit. Fuel and consumable totals use
the existing exact half-up derivations. Event totals use the recorded mill
facts. Cost per distance divides the all-in signed mill total by the difference
between the first and last compatible odometer readings inside one ownership
interval.

A lifetime result that would cross an ownership gap is unavailable with the T5
human reason. Rover still renders exact rows for each ownership interval. Event
counts and money obey the same bounds; fixture 134 records a $777 service after
disposal and proves that neither the total nor the service count includes it.

Every required spend family keeps one row. An absent family says `No costs
recorded` and carries no zero-total attribute. A vehicle without service events
gets a separate human empty state. Mixed currencies and missing distance
evidence render unavailable rather than zero.

The change adds no relation, column, or cached result. The shipping `$action`
union remains at five arms. Statistics remains tables-only.

## Real substrate

- Branch: `ab-m7t11-sol`
- Base: `master` at `4759008`
- Pier: `/var/home/michael/piers/rover-m7t11-sol-bel`
- Ship: `~bel`
- tmux session: `m7t11sol`
- Ames port: `32720`
- Eyre port: `8119`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk source: `/tmp/obelisk-fresh/desk`
- Obelisk install: `/var/home/michael/piers/rover-m7t11-sol-bel/obelisk`
- Obelisk commit: `9de633299b373a1047490b48281a40b457fb2043`
- Obelisk start command: `|start %obelisk %obelisk`
- Copied `sur/obelisk-ast.hoon` SHA-256: `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`

Obelisk was installed as its own unmodified desk from the local pinned checkout.
The initial Rover install printed `gall: booted %rover`. The final source commit
printed `gall: bumped %rover`; neither transcript contained `nest-fail`.

## Read path

The application resolves the selected vehicle before issuing the Statistics
read. Thirteen selected-vehicle urQL commands read the cost-bearing fuel,
consumable, and event relations with predicates and joins on the server. Their
projections retain relation keys so identical-looking facts do not collapse.
Gall receives only the selected vehicle's rows and folds each family without a
whole-table scry.

The event-to-odometer link and odometer facts use two keyed reads. A wider join
made pinned Obelisk fail when the link relation was empty while odometer facts
were present. Splitting those reads preserves the same bounded result and keeps
the pinned database engine healthy.

All rendered attributes and values are human-facing labels, money, dates, and
distance units. No database ID reaches the screen.

## TDD evidence

The new fixtures failed before their implementation:

- Fixture 134 first failed because Statistics had no ownership-cost sections.
  Its exact expected total is 6,038,010 mills.
- Fixture 135 first failed because no all-in distance rate existed. Adding only
  a $100 service moves the rate from 6,038 to 6,138 mills per mile while fuel
  remains 29,990 mills.
- Fixture 136 first failed because lifetime results crossed a buy-sell-rebuy
  gap. The two valid intervals retain totals/rates of 5,100,000/25,500 and
  8,200,000/82,000 mills.
- Fixture 137 proved the service empty state and every required spend-family
  row without a `$0.00` claim.
- Fixture 138 initially found real 390px screen overflow. The narrow selector
  rule now keeps the screen and every table inside the viewport.
- A later fixture 134 extension first counted a post-disposal service. The
  service count now uses the same ownership filter as its cost.

The product also regressed the existing fixture 51 while the first event
odometer query used the unsafe wide join. The HTTP assertion stayed in place;
the product read was split and fixture 51 returned HTTP 200 again.

## Back-to-back retained-data runs

Both runs used this command against the same live database:

```text
ROVER_NO_FIXTURE_ISOLATION=1 ROVER_T11_ONLY=1 bin/ui-test.sh /var/home/michael/piers/rover-m7t11-sol-bel
```

There was no database rename, drop, rebuild, or desk commit between them. The
whole ship stopped and restarted in `m7t11sol` between the runs. The census is
the persistence proof: the second run starts at the first run's ending count.

The first run exited 0 with these verbatim final lines:

```text
ui-test: fixture 134 PASS - total cost and service subtype count are exact within ownership despite a later service outside it
ui-test: fixture 135 PASS - a service-only $100 change raises all-in cost from 6038 to 6138 mills per mile while fuel stays at 29990 mills
ui-test: fixture 136 PASS - lifetime aggregates refuse the buy-sell-rebuy gap and the two intervals retain exact totals and all-in rates
ui-test: fixture 137 PASS - a vehicle with no service events keeps the Service family row, says so, and renders no zero-dollar claim
ui-test: fixture 138 PASS - all four new Statistics tables fit a real 390px browser with no chart, SVG, canvas, or horizontal overflow: {"allPresent":true,"screenOverflow":false,"tableOverflow":false,"viewportOverflow":false,"forbiddenVisual":false}
ui-test: T11 retained-data census - Statistics Cost Vehicle count 10 -> 11
ui-test: COVERAGE - all 5 T11 fixtures executed
```

The restarted second run exited 0 with these verbatim final lines:

```text
ui-test: fixture 134 PASS - total cost and service subtype count are exact within ownership despite a later service outside it
ui-test: fixture 135 PASS - a service-only $100 change raises all-in cost from 6038 to 6138 mills per mile while fuel stays at 29990 mills
ui-test: fixture 136 PASS - lifetime aggregates refuse the buy-sell-rebuy gap and the two intervals retain exact totals and all-in rates
ui-test: fixture 137 PASS - a vehicle with no service events keeps the Service family row, says so, and renders no zero-dollar claim
ui-test: fixture 138 PASS - all four new Statistics tables fit a real 390px browser with no chart, SVG, canvas, or horizontal overflow: {"allPresent":true,"screenOverflow":false,"tableOverflow":false,"viewportOverflow":false,"forbiddenVisual":false}
ui-test: T11 retained-data census - Statistics Cost Vehicle count 11 -> 12
ui-test: COVERAGE - all 5 T11 fixtures executed
```

## Full battery evidence

The complete UI battery ran against real Eyre and the pinned Obelisk agent. It
exited 0 with these final lines:

```text
ui-test: fixture 134 PASS - total cost and service subtype count are exact within ownership despite a later service outside it
ui-test: fixture 135 PASS - a service-only $100 change raises all-in cost from 6038 to 6138 mills per mile while fuel stays at 29990 mills
ui-test: fixture 136 PASS - lifetime aggregates refuse the buy-sell-rebuy gap and the two intervals retain exact totals and all-in rates
ui-test: fixture 137 PASS - a vehicle with no service events keeps the Service family row, says so, and renders no zero-dollar claim
ui-test: fixture 138 PASS - all four new Statistics tables fit a real 390px browser with no chart, SVG, canvas, or horizontal overflow: {"allPresent":true,"screenOverflow":false,"tableOverflow":false,"viewportOverflow":false,"forbiddenVisual":false}
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - all 114 defined fixtures executed
```

The final event battery ran after the last product change. It exited 0 with:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 86 defined fixtures executed
```

That run also printed fixture 13's five-arm action-union result and fixture 12's
event-family restart result.

## Performance

The baseline, taken before the Statistics event-family read path, was:

```text
view-performance-test: run 1 - 0.645631s, 337551 bytes, 25 of 420 fills
view-performance-test: run 2 - 0.657809s, 337551 bytes, 25 of 420 fills
view-performance-test: COVERAGE - synthetic 420-fill view stayed within 2.0s
```

The final code produced:

```text
view-performance-test: run 1 - 0.808841s, 339578 bytes, 25 of 420 fills
view-performance-test: run 2 - 0.799036s, 339578 bytes, 25 of 420 fills
view-performance-test: COVERAGE - synthetic 420-fill view stayed within 2.0s
```

The query is bounded to the selected vehicle. The final runs remain below half
the two-second budget without storing a derived cache.

## Stale assertions and newly exposed defects

- Export fixture 53: the test was wrong. T10 replaced the placeholder, so the
  assertion now requires the export section, download anchor, and
  `/apps/rover/export`, and rejects an export placeholder. The grants
  placeholder remains.
- Performance vehicle selection: the harness was wrong. Its isolated import had
  no app default, so it now selects `Synthetic Performance Vehicle` before the
  timed read.
- Add Fill derived total: the test was wrong. Its document-wide input search saw
  the event form's total field after M7; the assertion now scopes itself to the
  Add Fill screen.
- Consumable total in fixture 134: the test was wrong. The canonical half-up
  result is 8,020 mills, not the unrounded 8,018-mill product.
- Demo fixtures 58 and 61: the tests were wrong. Each used a default-vehicle GET
  to inspect both gasoline and diesel. They now request the intended vehicle.
- Fixture 65: the old seven-table expectation was wrong after T11. It now checks
  all ten data-dependent tables plus row/section scope; the unchanged empty
  service table remains scoped too.
- Fixture 137 section extraction: the test was wrong after the product added
  section-level scope metadata. The extractor now permits attributes on the
  opening tag.
- Existing fixture 51: the product was wrong. The first new four-way event
  odometer join crashed the pinned engine for an empty link relation; the read
  was split without weakening the HTTP assertion.
- Fixture 138: the product was wrong. A long selected vehicle label overflowed
  Statistics at 390px; the mobile selector now fits.
- Spend-family absence: the product was wrong. It omitted a required family row;
  the row now remains and states the absence without inventing zero.
- Post-disposal service count: the product was wrong. The money was bounded but
  the subtype count was not; both now use the ownership interval.

## Design latitude used

- Disposal proceeds are signed credits. A sale lowers ownership cost because
  its entered total is money received, not spend.
- Notes get a spend-family row. Note events may carry a cost, so omitting the row
  would make the family table fail to reconcile with total ownership cost.
- A service with several subtypes contributes one event to each named subtype
  and shows the event's full cost under each. Rover stores no allocation among
  subtype links, so an invented split would be false precision.
- Distance uses the first and last increasing, source-native odometer readings
  inside one ownership interval. The rate is rounded half-up to mills per
  distance unit.
- Mixed currency is unavailable. Rover does not invent an exchange rate.
- No fifth Statistics view was added. The interval breakdown belongs inside the
  four required views and directly explains each refused lifetime result.
- Event odometer facts use two urQL reads because the pinned engine rejects the
  equivalent empty-side wide join. Gall joins the two selected-vehicle result
  sets by their retained keys.
