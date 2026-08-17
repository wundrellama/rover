# M7 T3 — Charging odometer repair — sol

## Result

T3 is complete on `ab-m7t3-sol`. Rover now uses one parent-keyed odometer
link for fuel fills and charging sessions.

The migration copies populated data before it drops the old relation. It
compares the source and destination row count and content before the drop.

## Inherited work

The worktree contained an uncommitted partial T3 implementation. It had the
new relation, caller changes, charge rendering, and a migration battery.

The inherited copy used `INSERT` from a query. The pinned runtime refuses that
form. I kept the correct work and replaced the copy with one multi-row
`VALUES` statement.

`QUESTIONS.md` recorded this substrate question. The task brief answered it,
so I removed the entry.

## Test environment

- Branch: `ab-m7t3-sol`
- Ship: `~bel`
- Pier: `/var/home/michael/piers/rover-m7t3-sol-bel`
- tmux session: `m7t3sol`
- Ames port: `31903`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk commit: `9de633299b373a1047490b48281a40b457fb2043`
- Obelisk version: `v0.9.0-beta`
- Copied AST SHA-256: `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`
- Pre-migration backup: `/home/michael/piers/rover-m7t3-sol-bel-before-energy-odometer-migration-1786989972.tar.zst`

The desk installed without a `nest-fail`. The pier reported
`gall: booted %rover`.

I did not access the owner moon or any other project pier.

## TDD evidence

The first migration run used the inherited query-based copy. It created three
old-schema fills through Eyre and recorded all three source rows.

The pinned runtime refused the copy. The battery then failed with this line:

```text
odometer-migration-test: FAIL - the old relation still exists
```

The failed copy did not reach the drop. This result proved the test could
detect the substrate defect without losing source data.

The final code serializes the two projected `@ux` columns into one atomic
multi-row `VALUES` insert. Obelisk requires whitespace between row groups.

## Migration evidence

The migration battery started from commit `9a4003e`. It created a database on
that old schema and saved three fills through the product endpoint.

The two-column projection prevents identical projected rows from collapsing.
Each row includes the unique `acquisition-id` primary key.

```text
odometer-migration-test: source row count before copy: 3
odometer-migration-test: source content fingerprint before copy: 4325c3cd5abd1c7d91ec828db5cee744dfba0b57935de58589a24708e9c6f760
odometer-migration-test: destination row count after copy: 3
odometer-migration-test: destination content fingerprint after copy: 4325c3cd5abd1c7d91ec828db5cee744dfba0b57935de58589a24708e9c6f760
odometer-migration-test: step 4 PASS - count and content match, and the old relation is gone
odometer-migration-test: step 5 PASS - all three migrated fill mileages render
odometer-migration-test: step 6 PASS - the second migration path changes nothing
odometer-migration-test: step 7 PASS - the migration and every migrated fill survive restart
odometer-migration-test: PASS - populated migration preserved 3 rows by count and content; backup /home/michael/piers/rover-m7t3-sol-bel-before-energy-odometer-migration-1786989972.tar.zst
```

The battery created the destination first. Rover then recorded the source
count, copied the rows, and queried both relations again.

Rover compared the count and every two-column row. It submitted
`DROP TABLE FORCE fuel-fill-odometers` only after that comparison passed.

The drop removes the old relation's foreign keys. The destination owns new
`RESTRICT` foreign keys to `energy-acquisitions` and
`odometer-observations`.

The battery ran `ensure-def-schema` again after the drop. The destination
fingerprint did not change, and Rover did not recreate the old relation.

## Fresh schema and product evidence

A separate fresh database received `energy-acquisition-odometers`. It never
received `fuel-fill-odometers`.

Event fixture 23 saved a charging session with mileage through Eyre. The
charge and a fill used the same parent-keyed relation and odometer list.

The charge was the latest observation. Rover derived the current odometer
from that charge.

Event fixture 24 restarted the ship. The charge link, rendered mileage, and
derived current odometer survived.

Event fixture 13 counted five shipping action arms. No fixture or migration
action was added to the union.

## Two full event battery runs

Both runs used the same pier and ran back to back. Both runs had the same
verdict.

Run 1 final lines:

```text
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: COVERAGE - all 24 defined fixtures executed
```

Run 2 final lines:

```text
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: COVERAGE - all 24 defined fixtures executed
```

The T3 fixture lines were also identical in both runs:

```text
event-test: fixture 23 PASS - fill and charge mileage share the parent-keyed link and one odometer stream
event-test: fixture 24 PASS - charge mileage and the derived current odometer survive restart
```

## Schema evidence

The isolated live schema battery passed after the two event runs.

```text
schema-test: PASS - SQL/Hoon parity is 81/81 relations; DDL has 92 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 81 relations; all 92 FK constraints (95 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

Shell syntax checks passed for the event, migration, UI, and schema batteries.
`git diff --check` also passed.

The wider UI battery passed its migrated fill-edit odometer fixture. It later
stopped at this pre-existing form-scope assertion:

```text
ui-test: FAIL - add-fill form asks for a derived total or machine representation
```

That assertion scans the complete view for `input name="total"`. The settled
Add Event form contains that input on the base commit. T3 does not change that
form or assertion.

## Design latitude used.

- The migration lives in `ensure-def-schema`. This action already owns
  incremental definition relations and also feeds the fresh schema pour.
- The migration uses explicit Gall phases. This structure records the source
  state and verifies the copy before the drop.
- The charge uses the existing mileage control. Its history card renders the
  reading with the vehicle distance preference.
- A separate migration battery owns the destructive old-schema rehearsal. The
  event battery covers fresh-schema behavior and the repaired product path.
