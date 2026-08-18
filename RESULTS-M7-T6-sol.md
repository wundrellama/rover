# RESULTS - M7 T6 reminders (branch `ab-m7t6-sol`)

Date: 2026-08-17. All final results came from a real fake ship and the pinned
Obelisk agent. No result came from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t6-sol`, branch `ab-m7t6-sol` |
| Rover commit under test | `5ea8d64` |
| Pier | `~/piers/rover-m7t6-sol-bel`, ship `~bel` |
| tmux session | `m7t6sol` |
| Ames port | 32220 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` at `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |

The fake ship could not resolve `~dister-nomryg-nilref`. I installed the same
unmodified pin from `/tmp/obelisk-fresh/desk` and used its copied AST. I started
the agent with `|start %obelisk %obelisk`.

The first install reported these lines and no `nest-fail`:

```text
gall: booted %obelisk
gall: booted %rover
```

The final shell change also compiled on the same desk:

```text
gall: reloading %rover
eyre: replacing existing binding at /apps/rover
: /~bel/rover/8/app/rover/shell/html
gall: bumped %rover
```

## What T6 adds

T6 adds six relations through the definition-schema catch-up:

- `service-reminders` is the family parent. It keys the vehicle and service
  subtype.
- `reminder-time-intervals` stores a time interval, unit, and due date.
- `reminder-distance-intervals` stores exact interval and due readings.
- `reminder-service-events` records the service event that last reset a
  reminder.
- `service-subtype-time-defaults` leaves a child-row path for catalog defaults.
- `service-subtype-distance-defaults` leaves the matching distance path.

All foreign keys use `RESTRICT`. Each parent writes `N` for `archived`. Optional
time or distance data uses an absent child row. The code uses `INSERT` and never
uses mutation `AS OF` or `UPSERT`.

The `/apps/rover/add-reminder` endpoint accepts time, distance, or both. The hub
derives the current state each time it serves the page. Rover does not store a
current odometer or a due state.

The distance code follows the ordering and overlap checks in
`++current-odometer`. It keeps the numeric observation instead of parsing the
rendered tape. Cross-unit comparisons use integer factors and integer scaling.

A matching service event resets the reminder in the event's atomic script. A
time interval advances from the observed service date. A distance interval
advances from the linked service odometer. The reset link supplies ownership
provenance for later due evaluation.

## The test was red first

Fixture 2 required the reminder relations before any T6 product code existed.
The unchanged desk failed with this line:

```text
event-test: FAIL - fixture 2 the pour is missing service-reminders
```

The implementation followed that failure. The final battery passed the same
schema check twice in each run.

## Reminder fixture evidence

| Fixture | Evidence |
|---|---|
| 44 | Time, distance, and combined reminders save through Eyre. A time-only reminder has no distance row. |
| 45 | A real odometer write changes a distance reminder from pending to due. |
| 46 | The real ship time fires a past date. Distance makes a combined reminder due while its time remains future. |
| 47 | A vehicle with no readings renders unavailable and gives a human reason. |
| 48 | A buy-sell-rebuy interval renders unavailable and does not count gap miles. |
| 49 | The named service advances time and distance due points and records reset provenance. |
| 50 | Reminder facts and all three derived states survive a full ship restart. |
| 51 | A real browser saves a time-only reminder and sees its pending state after reload. |

Fixture 45 wrote 900 miles through `/apps/rover/add-odometer`. The hub rendered
`Due in 100 mi`. A second product write recorded 1,001 miles, and the same card
rendered due.

Fixture 46 used the stored date `2025-10-01` against the real ship clock. The
test did not change the date between assertions and did not fake the clock.

Fixture 48 bought the vehicle at 1,000 miles and reset the reminder by service.
It then sold the vehicle, bought it again at 2,000 miles, and recorded 2,100
miles. The result stayed unavailable because the interval crossed the ownership
gap.

## Done-check results

| # | Check | Result |
|---|---|---|
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | PASS |
| 2 | Time, distance, and combined reminders save and read through Eyre | PASS, fixtures 44 and 51 |
| 3 | A real odometer crossing changes pending to due | PASS, fixture 45 |
| 4 | A reminder is time-due on or after its date | PASS, fixture 46 |
| 5 | Either supplied interval can make a combined reminder due | PASS, fixture 46 |
| 6 | An ownership gap does not count toward distance due | PASS, fixture 48 |
| 7 | Missing odometer evidence renders unavailable with a reason | PASS, fixture 47 |
| 8 | A time-only reminder writes no distance row or zero | PASS, fixture 44 |
| 9 | Recording the named service advances the reminder | PASS, fixture 49 |
| 10 | All reminder facts and states survive restart | PASS, fixture 50 |
| 11 | The shipping action union still has five arms | PASS, fixture 13 |
| 12 | Two back-to-back batteries have the same verdict and no skips | PASS |

T6 has no recurring timer. Therefore, restart has no reminder wakeup to
duplicate and no reminder wire to orphan.

## Battery evidence

Both runs used the code recorded in commit `5ea8d64` on the pier above. No code
or desk change occurred between them. These are the verbatim final lines.

Run 1:

```text
event-test: fixture 51 PASS - a person saves a reminder from the form and sees its pending state after reload
event-test: COVERAGE - all 51 defined fixtures executed
```

Run 2:

```text
event-test: fixture 51 PASS - a person saves a reminder from the form and sees its pending state after reload
event-test: COVERAGE - all 51 defined fixtures executed
```

Both runs reported zero `FAIL` lines. The coverage gate reported all 51 defined
fixtures executed, with no skips.

## Failures found during development

The required first red run failed on the missing `service-reminders` relation.
That failure appears above.

One restart attempt failed with this line:

```text
event-test: FAIL - fixture 12 the pier did not restart
```

The tmux launcher failed to attach the same pier on that attempt. I restored the
launcher and changed no database fact. Both final runs restarted the ship and
passed all restart fixtures.

Two candidate final runs sent the select's default distance unit with empty
distance fields. The endpoint rejected that partial child:

```text
event-test: FAIL - fixture 51 the browser could not save a reminder: REMINDER_VERDICT=%bad-shape: reminder.distance
reminder-browser-fixture: FAIL - page.waitForFunction: Timeout 30000ms exceeded.
```

The form now omits the complete optional group when its value fields are empty.
Both final browser fixtures then passed.

## Design latitude used

**Timer:** Rover evaluates reminders when it serves the owner view. It does not
schedule a Behn wakeup. Rover has no notification destination when the app is
closed, so a wakeup would not deliver a person-visible result. A recurring
schedule would also add durable lifecycle state, restart recovery, duplicate
suppression, and wire cleanup. Read-time evaluation uses the same derived-value
posture as T5. The stored due points, current date, derived odometer, and
ownership intervals already supply every input. This choice also keeps due
state derived and makes restart behavior independent of timer recovery.

- **Relation shape:** `service-reminders` is the parent. Time, distance, and
  reset provenance use child relations because each can be absent.
- **Subtype defaults:** Two child relations leave the post-publish path open.
  T6 seeds no defaults because T9 imports the 52 source values.
- **Combined rule:** Either interval makes a reminder due. Due wins over an
  unavailable sibling. Otherwise, unavailable wins over pending.
- **Service reset:** A service with a matching subtype resets the reminder.
  The event date advances time, and its linked odometer advances distance.
- **Missing reset mileage:** Time still advances. Distance becomes unavailable
  because Rover has no honest distance baseline.
- **Ownership baseline:** A distance reminder with ownership boundaries needs
  reset provenance. Rover renders it unavailable instead of guessing a start.
- **Time units:** Days and weeks use exact durations. Months and years use
  calendar arithmetic instead of fixed second counts.
- **Hub rendering:** The selected vehicle shows each active reminder with human
  component text and an overall due, not-due, or unavailable state.
