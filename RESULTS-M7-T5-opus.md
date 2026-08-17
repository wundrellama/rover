# RESULTS — M7 T5, ownership intervals bound every derivation (branch `ab-m7t5-opus`)

Date: 2026-08-17. Every result below comes from a run on a real pier against the
pinned Obelisk agent. No result comes from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t5-opus`, branch `ab-m7t5-opus` |
| Pier | `~/piers/rover-m7t5-opus-bel`, ship `~bel`, tmux session `m7t5opus` |
| Ames port | 32150 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` @ `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |
| Rover commit at the baseline run | `e8c1519` |
| Rover commit under test | `4cf0494` |

Obelisk came from the pinned local checkout at `/tmp/obelisk-fresh`. Its
`sur/obelisk-ast.hoon` matches the Rover copy byte for byte. Both desks went in
with `|merge ... our %base`, `|mount`, a file copy, `|commit`, `|install`, and for
Obelisk `|start %obelisk %obelisk`.

## What T5 adds

T5 adds no relation, no column, and no stored row. It reads the T4 rows that
already exist and derives from them.

```text
+$  ownership-interval  [start=(unit @da) end=(unit @da)]

++  ownership-index     one map of ownership intervals per vehicle
++  ownership-walk      purchases open, disposals close
++  ownership-segment   which interval holds a date, or none
++  ownership-gap       do the two ends of a window sit in one interval
```

`ownership-index` reads the `vehicle-events` rows plus the `vehicle-acquisitions`
and `vehicle-disposals` child rows. The page already queries all three, so T5 adds
no query either.

Two derivations consult the map:

- `derive-fill-series` — fuel economy, distance between fills, elapsed time
  between fills, and distance per tank. All four hang off one `break-reason`.
- `def-economy` — consumable economy.

A window whose two ends sit in different ownership intervals, or in none, gets the
break reason `%ownership-gap`. `economy-break-text` renders it as
`The vehicle was not owned for part of this interval, so it is unavailable.`

The reason is derived and is never stored. `economy-breaks` keeps its three
owner-supplied reasons and its key to `fuel-fills`. `economy-break-reason` in
`sur/rover.hoon` still holds `%missed-fill`, `%excluded`, and `%owner-marked`, so
an owner cannot write `%ownership-gap` through the entry path.

## The fixture that decides the task, seen red first

Fixtures 36 to 43 run three vehicles that carry the **same four fills, the same
odometer readings, and the same quantities**. Only the ownership events differ, so
any figure that differs between them differs because of ownership and nothing
else.

| fill | date | odometer | quantity | interval | economy |
|---|---|---|---|---|---|
| F1 | 2026-05-05 | 40,000 | 12.000 gal | — | baseline |
| F2 | 2026-05-15 | 40,300 | 10.000 gal | 300 mi | 30.000 mpg |
| F3 | 2026-07-05 | 41,100 | 10.000 gal | 800 mi | 80.000 mpg |
| F4 | 2026-07-15 | 41,400 | 12.000 gal | 300 mi | 25.000 mpg |

The gap vehicle buys on 2026-05-01, sells on 2026-06-01 at 40,400 miles, and buys
back on 2026-07-01 at 40,800 miles. The F2-to-F3 interval spans the sale and the
repurchase. 500 of its 800 miles belong to whoever held the vehicle in between.

**80.000 mpg is the maximum of the three.** That is the point: if the gap is not
honoured it is what BEST ECONOMY reports.

### The red run

The T5 code was stashed, the pre-T5 desk was committed to the pier, and the
battery ran. Fixtures 1 to 35 passed and fixture 36 failed. Verbatim:

```text
event-test: fixture 33 PASS - the route decides the kind for acquisition and disposal, and the body cannot override it
event-test: FAIL - fixture 36 the cross-gap interval is reported as the best economy: BEST ECONOMY = 80.000 mpg
```

A probe against the same pier, with the same pre-T5 desk installed, read the whole
served hub and the whole economy table of the gap vehicle:

```text
ECONOMY - LAST FILL    25.000 mpg
ECONOMY - LIFETIME     45.000 mpg
BEST ECONOMY           80.000 mpg
WORST ECONOMY          25.000 mpg
--- economy table rows, newest first
25.000 mpg   break=-                Eligible full-fill interval.
80.000 mpg   break=-                Eligible full-fill interval.
30.000 mpg   break=-                Eligible full-fill interval.
Unavailable  break=-                An eligible adjacent full-fill interval is required.
```

That is the defect in full. The cross-gap interval rendered a figure, carried no
warning, was **labelled eligible**, and entered both the best and the mean.

### The green run

The same probe after the fix, same pier, same data:

```text
ECONOMY - LAST FILL    25.000 mpg
ECONOMY - LIFETIME     27.500 mpg
BEST ECONOMY           30.000 mpg
WORST ECONOMY          25.000 mpg
--- economy table rows, newest first
25.000 mpg   break=-                Eligible full-fill interval.
Unavailable  break=%ownership-gap   The vehicle was not owned for part of this interval, so it is unavailable.
30.000 mpg   break=-                Eligible full-fill interval.
Unavailable  break=-                An eligible adjacent full-fill interval is required.
```

The other three interval tables of the same vehicle, read the same way:

```text
--- distance-between-fills
    2026-07-15 12:00:00 | 300.000 mi  | Eligible full-fill interval.
    2026-07-05 12:00:00 | Unavailable | The vehicle was not owned for part of this interval, so it is unavailable.
    2026-05-15 12:00:00 | 300.000 mi  | Eligible full-fill interval.
    2026-05-05 12:00:00 | Unavailable | Adjacent odometer-linked full fills are required.
--- time-between-fills
    2026-07-15 12:00:00 | 240.000 h   | Eligible full-fill interval.
    2026-07-05 12:00:00 | Unavailable | The vehicle was not owned for part of this interval, so it is unavailable.
    2026-05-15 12:00:00 | 240.000 h   | Eligible full-fill interval.
    2026-05-05 12:00:00 | Unavailable | Two eligible ordered fills are required for the selected vehicle.
--- distance-per-tank
    2026-07-15 12:00:00 | Unavailable | Tank size and an eligible economy interval are required; Rover never guesses tank size.
    2026-07-05 12:00:00 | Unavailable | The vehicle was not owned for part of this interval, so it is unavailable.
    2026-05-15 12:00:00 | Unavailable | Tank size and an eligible economy interval are required; Rover never guesses tank size.
    2026-05-05 12:00:00 | Unavailable | Tank size and an eligible economy interval are required; Rover never guesses tank size.
```

The control vehicle, which carries the same four fills and no ownership events,
read the same before the fix and after it:

```text
ECONOMY - LAST FILL    25.000 mpg
ECONOMY - LIFETIME     45.000 mpg
BEST ECONOMY           80.000 mpg
WORST ECONOMY          25.000 mpg
25.000 mpg   break=-                Eligible full-fill interval.
80.000 mpg   break=-                Eligible full-fill interval.
30.000 mpg   break=-                Eligible full-fill interval.
Unavailable  break=-                An eligible adjacent full-fill interval is required.
```

## The desk installs

The T5 desk reached the pier through `|commit %rover`, which reported
`gall: bumped %rover` and no `nest-fail`. The agent was then nuked and installed
again, so the install path itself is on the record:

```text
> |nuke %rover
gall: nuking %rover
> |install our %rover
gall: unnuking %rover
eyre: replacing existing binding at /apps/rover
> |rein %rover [%.y %rover]
gall: booted %rover
```

The served view worked again immediately after, and the gap vehicle still read
`BEST ECONOMY 30.000 mpg` with the cross-gap row unavailable. Rover re-bootstrapped
against the populated Obelisk database with no manual step.

## Done-check results

| # | Check | Result |
|---|---|---|
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | PASS |
| 2 | The cross-gap interval is not reported as best economy, red before green | PASS, fixture 36, red output above |
| 3 | The cross-gap interval does not enter the mean | PASS, fixture 37 |
| 4 | The cross-gap interval renders unavailable with a human ownership reason, not zero | PASS, fixture 38 |
| 5 | A within-ownership interval on the same vehicle still computes | PASS, fixture 39 |
| 6 | A vehicle with no acquisition and no disposal derives exactly what it derived before T5 | PASS, fixture 40 |
| 7 | A vehicle owned from one purchase to now derives across its whole history with no break | PASS, fixture 41 |
| 8 | Charging efficiency and consumable economy respect ownership gaps | PARTIAL — consumable economy PASS, fixture 42. Charging efficiency does not exist. See below |
| 9 | Everything above survives a ship restart | PASS, fixture 43 |
| 10 | The shipping action union still has five arms | PASS, fixture 13 |
| 11 | The full battery runs twice back to back with the same verdict and no skips | PASS |

### Check 8 — charging efficiency has no derivation to bound

Rover derives no charging efficiency figure today, so T5 has nothing to bound
there. This is measured, not assumed:

- `charging-efficiency-breaks` appears **once** in the whole desk, in its own
  `CREATE TABLE` statement in `desk/lib/rover-act.hoon`. No query reads it, and it
  is not in the 57-statement view query list.
- The charge card renders `ODOMETER`, `ENERGY`, `ENERGY DELIVERED`,
  `START BATTERY`, `END BATTERY`, and `COST STATE`. No distance-per-energy figure.
- `derive-fill-series` walks `fuel-fills`. Charging sessions are a sibling child
  and never enter it.

Building the charging efficiency statistic is new capability, not an ownership
bound, so T5 leaves it out. The bound it would need is `ownership-gap`, which is
already written and already called from two places.

Two other interval figures the ruling names, `cost per mile` and `cost of
ownership`, also have no derivation in the shipped desk. The same applies to them.

## Battery evidence

Both runs used the pier and the desk above, back to back, with no change between
them. Verbatim final two lines of each run:

Run 1, `/tmp/t5-final-1.log`:

```text
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: COVERAGE - all 43 defined fixtures executed
```

Run 2, `/tmp/t5-final-2.log`:

```text
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: COVERAGE - all 43 defined fixtures executed
```

Both runs report zero `FAIL` lines. The coverage gate names all 43 defined
fixtures as executed, with no skips.

The eight new fixtures, from run 1:

```text
event-test: fixture 36 PASS - the cross-gap interval is not reported as best economy, and the reported best is the within-ownership figure
event-test: fixture 37 PASS - the cross-gap interval does not enter the mean
event-test: fixture 38 PASS - the cross-gap economy, distance, and elapsed-time figures all render unavailable with a human reason naming the ownership gap, and none renders as zero
event-test: fixture 39 PASS - a within-ownership interval on the same vehicle still computes
event-test: fixture 40 PASS - a vehicle with no acquisition and no disposal derives exactly what it derived before T5
event-test: fixture 41 PASS - a vehicle owned from one purchase to now derives across its whole history with no break
event-test: fixture 42 PASS - consumable economy respects ownership gaps the same way fuel economy does
event-test: fixture 43 PASS - the derived ownership break, the bounded aggregates, and the untouched control vehicle all survived a ship restart
```

A baseline run of the unchanged battery on the same pier, before any T5 code, gave
`COVERAGE - all 35 defined fixtures executed` with zero failures. The T5 work
therefore added eight fixtures and broke none.

## A pre-existing failure in `bin/ui-test.sh`

`bin/ui-test.sh` was run for extra compatibility evidence. Its economy fixtures
passed:

```text
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: fixture 42 PASS - DEF purchase uses snapshotted exact pricing and remains outside fuel-economy derivation
ui-test: fixture 53 PASS - DEF remains outside fuel acquisitions and leaves exact 9.000 mpg unchanged
```

The run then stopped on one assertion that **T5 did not cause**:

```text
ui-test: FAIL - add-fill form asks for a derived total or machine representation
```

The assertion greps the **whole served page** for `<input name="total">`. The Add
Event form has carried exactly that input since M7 T1:

```text
git log -S 'name=\"total\"' -- desk/lib/rover-view.hoon
3a3625f m7t1 opus: add the vehicle event backbone
```

The check means to guard the Add Fill form and now catches the Add Event form
three tasks later. Repairing it is not T5 work, so it is reported rather than
fixed. The battery stops there and never reaches its coverage gate, so the
fixtures after that line did not run in this session.

## Design latitude used

The specs fix the interval rule, the derived-not-owner-marked rule, the
never-render-zero rule, and the compatibility requirement. These are the choices
they left open.

1. **The derived break gets its own term, `%ownership-gap`, in the same term space
   the three owner reasons use.** One rendering path, one `economy-break-text`
   arm, one `data-economy-break` attribute. The term space is a `(unit @tas)` in
   the in-memory `derived-fill`, not a stored union.

2. **`economy-break-reason` in `sur/rover.hoon` stays at three arms.** That union
   validates what an owner writes. Adding the derived term there would let an
   owner write a fact Rover is supposed to see for itself.

3. **The derived break is stored nowhere at all.** No relation, no row, no column.
   It is recomputed on every read from the acquisition and disposal rows. A stored
   derivation can drift from its inputs, and the post-publish rule would need a new
   relation for it. Both point the same way.

4. **The ownership window is computed from the event rows in one pass per vehicle,
   built once per page render.** `ownership-index` groups the boundary events by
   vehicle and hands each group to `ownership-walk`. The cost is one pass over the
   event rows, which are far fewer than the fills.

5. **A second purchase inside an open ownership interval opens nothing.** The
   vehicle never left the owner's hands, so there is no gap. The alternative would
   close and reopen at the same instant and invent a zero-width gap.

6. **A disposal with no purchase before it closes an interval that reaches back to
   the first record.** An owner who records only the sale still held the vehicle
   before it. Refusing to close on that evidence would ignore a disposal Rover can
   plainly see, which is the defect T5 exists to prevent.

7. **A vehicle with no acquisition and no disposal has no ownership boundary.**
   `ownership-gap` answers no on an empty interval list before it looks at
   anything. This is the compatibility rule made structural rather than checked.

8. **An owner-supplied break reason wins when both apply.** It is the more specific
   fact, and it is the sentence the owner was already shown.

9. **The unavailable interval renders on the statistics screen, in the economy,
   distance, and elapsed-time tables, through the machinery that already renders
   the three owner reasons.** The history fill card is unchanged: its break note
   comes from the `economy-breaks` rows, and the derived break has no row. The
   statistics screen is where the historical defect lived, so that is where the
   proof belongs.

10. **The hub names no gap.** BEST ECONOMY, WORST ECONOMY, and ECONOMY - LIFETIME
    report the bounded figures and say `Best eligible full-fill interval.` as
    before. A broken interval never reaches `best-economy` or `worst-economy`, so
    the zero those arms return for an empty list keeps one meaning.

11. **Six unreachable arms were removed** — `interval-quantity`,
    `interval-has-break`, `interval-break-reason`, `economy-for-fill`,
    `fill-interval-break-reason`, and `interval-for-fill`. The T5 brief names five
    of them as the seam to change, which is how a reader finds them. They have no
    caller: the per-fill query walk they belong to was replaced by the single
    ordered pass in `derive-fill-series`, and only their calls to each other
    remained. A second derivation path that no longer runs, and that does not
    honour the ownership bound, is the exact shape of the defect T5 prevents. The
    removal is its own commit, `e4c4e70`, so it can be reverted on its own.

## Commits

```text
b803f22  m7t5 opus: bound every interval derivation by the ownership intervals of the vehicle
e4c4e70  m7t5 opus: remove the six unreachable interval arms that the ownership bound could not reach
4cf0494  m7t5 opus: assert the distance and elapsed-time figures across the gap in fixtures 38 and 40
```

Nothing was pushed. No pull request was opened. Nothing was committed to `master`.
