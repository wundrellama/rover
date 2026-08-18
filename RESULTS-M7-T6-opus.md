# RESULTS — M7 T6, reminders (branch `ab-m7t6-opus`)

Date: 2026-08-17. Every result below comes from a run on a real pier against the
pinned Obelisk agent. No result comes from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t6-opus`, branch `ab-m7t6-opus` |
| Pier | `~/piers/rover-m7t6-opus-bel`, ship `~bel`, tmux session `m7t6opus` |
| Ames port | 32210 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` @ `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |
| Rover commit at the baseline run | `ca82bdc` |
| Rover commit under test | `60e26ac` |

The pier is a fake `~bel`, so it cannot reach `~dister-nomryg-nilref` over Ames.
Obelisk came from the pinned local checkout at `/tmp/obelisk-fresh`. Its
`sur/obelisk-ast.hoon` matches the Rover copy byte for byte. Both desks went in
with `|merge ... our %base`, `|mount`, a file copy, `|commit`, `|install`, and for
Obelisk `|start %obelisk %obelisk`.

A baseline run of the unchanged battery on this pier, before any T6 code, gave
`COVERAGE - all 43 defined fixtures executed` with zero failures.

## The decision this task turned on: no timer

**Rover schedules no wakeup for a reminder. Every reminder answer is derived on
the read.** The full argument is in the design-latitude section below. The rest of
this report describes a read-time derivation.

## What T6 adds

Three relations. No column reaches a populated relation.

```text
service-reminders
  (reminder-id @ux, vehicle-id @ux, service-subtype-id @ux,
   archived @f, recorded-at @da)
  PRIMARY KEY (reminder-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
             (service-subtype-id) REFERENCES service-subtype-definitions

service-reminder-time
  (reminder-id @ux, interval-count @ud, interval-unit @tas, due-at @da)
  PRIMARY KEY (reminder-id)
  FOREIGN KEY (reminder-id) REFERENCES service-reminders (reminder-id)

service-reminder-distance
  (reminder-id @ux, interval-digits @ud, interval-decimals @ud,
   due-digits @ud, due-decimals @ud, distance-unit @tas)
  PRIMARY KEY (reminder-id)
  FOREIGN KEY (reminder-id) REFERENCES service-reminders (reminder-id)
```

All foreign keys are `RESTRICT` on delete and on update. The parent holds no
interval and no due point, because a reminder may carry an interval in time, an
interval in distance, or both. An interval the owner did not set writes **no
row**. A column on the parent would make a zero interval representable, and a
service due every zero miles is not a real state.

The subtype key is the point of the family. A reminder is about a kind of service
work, and T2 gave `service-subtype-definitions` a single-column primary key so a
later child could reference it. That is the door this task walks through.

### What T2 actually left open

T2 built the single-column primary key and nothing else. It poured no default
interval relation, and no code in the desk mentions one. The comment at
`desk/lib/rover-act.hoon:1051` names T6 as the caller it was left open for. T6
uses the key and does not add a default-interval relation. See design latitude 3.

### The read path

`desk/lib/rover-act.hoon` adds four queries to `ui-view`, each over one relation
and with no join at all. The subtype label comes from the catalog query that was
already there, matched by ID in Hoon. A three-way join whose leftmost relation is
empty crashes the pinned engine, and a fresh database has no reminder and no
vehicle, so the join is not written in the first place.

`desk/lib/rover-view.hoon` derives the answer:

```text
++  current-odometer-reading   the one derivation of the current reading
++  reminder-completions       services already recorded that name this subtype
++  reminder-time-verdict      the time half
++  reminder-distance-verdict  the distance half, bounded by ownership
++  countdown-start-date       when the countdown started, in time
++  reminder-verdict-of        due when either interval fires
++  reminder-cards             one card per reminder of the vehicle
++  add-months, month-days     calendar arithmetic for a calendar interval
```

`current-odometer` now prints what `current-odometer-reading` derives. The readout
and the reminders read the same number, so the two cannot disagree. The two
existing refusal strings are unchanged.

`page` gains `now`. That is the only new input the derivation needs.

## The three states, as the served hub renders them

Read back from the pier with `set-default-vehicle` and `/apps/rover/view`, after
run 1 of the final battery:

```text
=== Reminder Vehicle 1787018380
  Engine Oil       due          Due now                Due at 13,000 mi. The odometer reads 13,050 mi.
  Brake Fluid      due          Due now                Due on 2026-08-01.
  Inspection       not-due      Due 2027-06-01         Every 12 months. Next due on 2027-06-01.
  Air Filter       due          Due now                Due at 12,000 mi. The odometer reads 13,050 mi.
  Spark Plugs      due          Due now                Due on 2026-07-01.
=== Ownership Gap Vehicle 1787018380
  Engine Oil       unavailable  Unavailable            The vehicle was not owned for part of this interval, so it is unavailable.
  Tire Rotation    not-due      Due in 100 mi          Every 500 mi. Next due at 41,500 mi.
=== Reminder Empty Vehicle 1787018380
  Engine Oil       unavailable  Unavailable            This vehicle has no odometer reading, so Rover cannot tell whether this is due.
=== Reminder Reset Vehicle 1787018380
  Oil Filter       not-due      Due in 3,000 mi        Every 3,000 mi. Next due at 23,150 mi.
  Coolant System   not-due      Due 2026-11-05         Every 3 months. Next due on 2026-11-05.
```

`Air Filter` carries both intervals. Its date is 2027-01-01 and it is due anyway,
because its distance point fired. `Spark Plugs` carries both intervals and is due
on time alone, with its reading 77,000 miles away.

## The fixture that decides the task, seen red first

Ruling 12 applied to a new figure. Progress toward a distance due point is
distance driven, and distance driven across a gap in ownership includes miles the
owner did not drive.

The gap vehicle from T5 carries the same buy-sell-rebuy history: bought
2026-05-01, sold 2026-06-01 at 40,400 miles, bought back 2026-07-01 at 40,800
miles. Its odometer rises the whole way and nothing in the readings looks wrong.

| reminder | due at | interval | countdown starts at | last reading at or below | window |
|---|---|---|---|---|---|
| Engine Oil | 41,300 mi | 1,200 mi | 40,100 mi | 40,000 mi on 2026-05-05 | crosses the gap |
| Tire Rotation | 41,500 mi | 500 mi | 41,000 mi | 40,800 mi on 2026-07-01 | inside one interval |

The current reading is 41,400 miles on 2026-07-15. The owner drove 40,000 to
40,400 and 40,800 to 41,400, which is 1,000 of the 1,300 miles between the
countdown point and now. **Counting the gap's 400 miles as progress makes the
Engine Oil reminder due.** That is the defect.

### The red run

The ownership check in `reminder-distance-verdict` was replaced with `%.n`, the
desk was committed to the pier, and the battery ran. Verbatim:

```text
event-test: fixture 49 PASS - a reminder with both intervals is due when either one fires
event-test: FAIL - fixture 50 the reminder counted the gap's miles as progress and reported due
```

The served hub of the same vehicle, with the same desk:

```text
=== Ownership Gap Vehicle 1787018380
  Engine Oil       due          Due now                Due at 41,300 mi. The odometer reads 41,400 mi.
  Tire Rotation    not-due      Due in 100 mi          Every 500 mi. Next due at 41,500 mi.
```

### The green run

The bound restored, same pier, same data:

```text
=== Ownership Gap Vehicle 1787018380
  Engine Oil       unavailable  Unavailable            The vehicle was not owned for part of this interval, so it is unavailable.
  Tire Rotation    not-due      Due in 100 mi          Every 500 mi. Next due at 41,500 mi.
```

The second reminder is the control. It sits on the same vehicle with the same
gap, and it still answers, because its countdown starts at the repurchase. The
bound covers the gap and not the vehicle.

The whole T6 block also went red before it went green. The first run of the new
fixtures, before any T6 code, stopped at the first assertion:

```text
event-test: fixture 42 PASS - consumable economy respects ownership gaps the same way fuel economy does
event-test: FAIL - fixture 44 the pour is missing service-reminders
```

## The browser fixture found a defect the JSON fixtures could not

Fixture 54 drives the Add Reminder form in a real browser. Its first run failed:

```text
event-test: FAIL - fixture 54 the browser could not save a reminder: REMINDER_VERDICT=%bad-shape: reminder.time-interval
```

A drop-down always sends a value. The JSON fixtures sent `"timeUnit":""` for a
distance-only reminder, but the browser sent `"timeUnit":"month"`, so the entry
path read a half-filled time interval and refused the whole reminder. The unit
control alone no longer means the owner asked for a time interval. The count and
the due date are what a person types, and either one asks.

## The desk installs

The agent was nuked and installed again, so the install path is on the record:

```text
> |nuke %rover
gall: nuking %rover
> |install our %rover
gall: unnuking %rover
eyre: replacing existing binding at /apps/rover
> |rein %rover [%.y %rover]
gall: booted %rover
```

No `nest-fail`. The served view worked immediately after, and the gap vehicle
still read `unavailable` with the ownership sentence.

### One upgrade step this task needs on a populated database

`ui-view` names the three new relations, so a database poured before T6 refuses
the view query until the definition-layer catch-up runs. On this pier the first
attempt answered:

```text
event-test: FAIL - fixture 1 the served view has no hub: Rover could not load the vehicle log. Obelisk refused the view query.
```

One poke of the shipping `%ensure-def-schema` action poured the three relations,
and every run after that was green from fixture 1. This is the published-ship
upgrade path Rover already has, and fixture 2 is its standing proof. A fresh
database is not affected, because `schema-m0` welds the whole relation list.
The behavior is not new to T6 — every task from T1 on that adds a relation to
`ui-view` has it — so this report names it rather than changing the bootstrap
path, which is outside T6.

## Done-check results

| # | Check | Result |
|---|---|---|
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | PASS, output above |
| 2 | A reminder saves with a time interval, a distance interval, or both, keyed to a service subtype, and reads back through Eyre | PASS, fixture 45 |
| 3 | A distance reminder is not due below its threshold and is due after a real odometer reading crosses it | PASS, fixture 47 |
| 4 | A time reminder is due on or after its date | PASS, fixture 48 |
| 5 | A reminder with both intervals behaves as the recorded rule says | PASS, fixture 49 |
| 6 | A distance reminder on a vehicle with an ownership gap does not count the gap's miles as progress | PASS, fixture 50, red output above |
| 7 | A vehicle with no odometer readings renders unavailable with a human reason, not due and not not-due | PASS, fixture 51 |
| 8 | A time-only reminder writes no distance rows and no zero | PASS, fixture 46 |
| 9 | Recording the service the reminder names advances or resets it | PASS, fixture 52 |
| 10 | Everything survives a ship restart, with no duplicate wakeup and no orphaned wire | PASS, fixture 53 |
| 11 | The shipping action union still has five arms | PASS, fixture 13 |
| 12 | The full battery runs twice back to back with the same verdict and no skips | PASS, output below |

Check 10 has no timer to prove clean, which is the whole design. Fixture 53
asserts it on the shipping source: every Behn card the agent sends is a
one-second sequencing delay, `on-arvo` answers the four wires it answered before
T6, and no wire names a reminder. It then reads every reminder answer back after
a real ship restart.

## Battery evidence

Both runs used the pier and the desk above, back to back, with no change between
them. Verbatim final two lines of each run:

Run 1, `/tmp/t6-final-1.log`:

```text
event-test: fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub
event-test: COVERAGE - all 54 defined fixtures executed
```

Run 2, `/tmp/t6-final-2.log`:

```text
event-test: fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub
event-test: COVERAGE - all 54 defined fixtures executed
```

Both runs report zero `FAIL` lines. The coverage gate names all 54 defined
fixtures as executed, with no skips.

The eleven new fixtures, from run 1:

```text
event-test: fixture 44 PASS - the reminder parent keys to a vehicle and a service subtype, and each interval is its own child relation
event-test: fixture 45 PASS - a reminder saves with a time interval, a distance interval, or both, keyed to a service subtype, and reads back through Eyre
event-test: fixture 46 PASS - a time-only reminder writes no distance row and no zero, and a distance-only reminder writes no time row
event-test: fixture 47 PASS - a distance reminder is not due below its threshold and is due after a real odometer reading crosses it
event-test: fixture 48 PASS - a time reminder is due on and after its date, and is not due before it
event-test: fixture 49 PASS - a reminder with both intervals is due when either one fires
event-test: fixture 50 PASS - a distance reminder whose countdown crosses an ownership gap does not count the gap's miles as progress, and a reminder inside one ownership interval on the same vehicle still answers
event-test: fixture 51 PASS - a vehicle with no odometer readings renders the distance reminder unavailable with a human reason, not due and not not-due
event-test: fixture 52 PASS - recording the service the reminder names resets it, and the stored due point is never rewritten
event-test: fixture 53 PASS - every reminder answer survived a ship restart, and the agent holds no reminder timer, no duplicate wakeup, and no orphaned wire
event-test: fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub
```

T6 added eleven fixtures and broke none of the forty-three that were there.

The clock was not faked. Fixture 48 reads a due date of 2026-08-01 against the
real date of the run, and a second reminder dated 2027-06-01 that has not
arrived. No stored due date was edited mid-assertion.

## Design latitude used

The specs fix the keying rules, the ownership bound, the derived-not-stored
posture, and the never-render-two-states rule. These are the choices they left
open.

### 1. A reminder uses no Behn timer. It is evaluated on every read.

This is the most consequential choice in T6, so here is the whole argument.

**A timer buys one thing: notification while the app is closed. Rover has
nowhere to send such a notification.** Rover is a served page. It has no push
channel, no `%hark` integration, no subscriber, and no remote protocol — the
remote protocol is explicitly out of scope until after M7. A timer that woke the
agent at midnight could set a flag in agent state and nothing else. The owner
would still learn that the oil change is due when they next open the app, which
is exactly when the read-time derivation tells them. The timer would buy
latency the product cannot spend.

**The distance half cannot be timed at all.** A distance reminder falls due when
the odometer crosses a threshold, and the odometer moves when the owner writes a
reading. No wakeup can predict that. A timer would therefore cover the time half
only, and the two halves of one reminder would answer through two different
mechanisms with two different freshness stories. One derivation for both is
simpler and cannot disagree with itself.

**The cost of a timer is a lifecycle the brief lists in full**: state migration,
restart survival, no duplicate wakeups, no orphaned wires, and no unbounded
growth. Every one of those is a way to be wrong. A scheduled wakeup per reminder
on a fifty-vehicle database with eight reminders each is four hundred live
timers, every one of which must be rescheduled on `on-load`, cancelled when a
reminder is archived, and re-armed after the service is recorded. A wakeup that
survives a desk upgrade but points at a reminder row that no longer exists is an
orphan. A wakeup armed twice because `on-load` ran after a partial migration is a
duplicate. None of these failure modes exists in code that does not exist.

**The posture of the whole app already answers this question.** Rover computes
derived values at read time from stored facts and never stores them. T5 proved
the shape again three days ago: the ownership break has no relation and no write
path, because it is computed when the page is served, and a stored derivation
can drift from its inputs. A reminder is the same shape. Its four inputs — the
stored interval, the stored due point, the clock, and the derived current
odometer — are all available when the owner opens the app, and three of the four
can change without the timer knowing.

**What Rover gives up.** If the owner never opens the app, Rover never tells them
anything. That is true of every other figure Rover derives, and it is honest: an
app with no notification surface should not pretend to have one. When Rover gains
a notification surface, a timer becomes a question worth reopening, and it will
be reopened against a real destination rather than against a flag in agent state.

`on-arvo` therefore still answers the four wires it answered before T6, and all
six Behn cards the agent sends are still `%wait (add now.bowl ~s1)` — one-shot
sequencing delays. Fixture 53 asserts both on the shipping source.

### 2. The relation names and the shape of the family.

`service-reminders` is the parent, and `service-reminder-time` and
`service-reminder-distance` are the two optional interval children. The interval
and its due point live in one row because neither is meaningful alone: a due
point with no interval cannot advance, and an interval with no due point has
nowhere to start. Both columns of a child are mandatory when that row exists,
which is the shape `vehicle-tank-size` uses. One `distance-unit` covers both the
interval and the due reading, because an interval in miles and a due reading in
kilometres could never be compared against one odometer.

### 3. A service subtype carries no default interval in T6.

The corpus holds a default interval on 52 of its 65 subtypes, and T2 left the
door open with a single-column primary key. T6 does not walk through that door
with a second relation.

The reason is that a relation with no writer and no reader is dead code, and T5
removed six arms for being exactly that. The 52 defaults are corpus data, and
the corpus arrives in T9. Adding `service-subtype-reminder-defaults` now would
pour an empty table with no way to fill it and no reader to use it. The door
stays open: the primary key T2 chose is unchanged, so T9 or T8 can add the
relation without touching a populated one.

### 4. A reminder with both intervals is due when either one fires.

The specs are silent, so this is a recorded choice rather than a filed question.
It is how a maintenance schedule is written and how a person reads one: every six
months or five thousand miles, whichever comes first.

The corollary needed a choice too. **When neither interval has fired and one of
the two cannot answer, the reminder is unavailable rather than not due.** Half an
answer is not an answer, and reporting `not due` on the strength of the half that
worked is the same defect as reporting a figure across an ownership gap.

### 5. Recording the service resets the reminder, and the reset is derived.

The next due point is the recorded service plus one interval, and never earlier
than the point the owner entered. In one line: `effective = max(anchor, last
completion + interval)`.

Nothing rewrites the stored row. Fixture 52 asserts that the stored due point is
still 20,100 miles after the reminder reads `Due in 3,000 mi`. A write path that
advanced the stored point would need `UPDATE` on a row Rover has just derived
from, and it could desync from the events it was derived from. The derived form
cannot.

A completion is a **service** event that names the reminder's subtype. The
subtype link keys to the event parent, so an expense could carry one, but paying
for a part is not the same as having the work done.

The two halves look for different evidence. The time half takes the newest
completion. The distance half takes the newest completion **that carries an
odometer reading**, because a service visit recorded without a reading says
nothing about the odometer and must not move a distance due point.

### 6. The countdown, and what the ownership bound is applied to.

The ownership window needs a start date, and the reminder row holds none. The
start is derived: the countdown starts at the effective due point less one
interval, and the window opens at the date of the **last odometer observation at
or below that reading**. If the record starts after that point, the earliest
observation is as far back as Rover can honestly go.

This is derived entirely from stored facts and needs no completion event. It also
falls out correctly when a completion exists: the effective due point is the
completion reading plus the interval, so the countdown point is the completion
reading and the window opens on the day of the service.

**The bound is applied to the distance half only.** Ruling 12 bounds interval
derivations, and a distance figure across a gap counts miles the owner did not
drive. A calendar date is not such a figure. Three months passed whether or not
the owner held the vehicle, so a time reminder answers across a gap.

### 7. Three states, and the sentences for the third.

A reminder answers `due`, `not-due`, or `unavailable`. Three things make the
distance half unavailable, and each says why:

```text
This vehicle has no odometer reading, so Rover cannot tell whether this is due.
The latest odometer observations of this vehicle overlap, so Rover cannot tell whether this is due.
The vehicle was not owned for part of this interval, so it is unavailable.
```

The third is `economy-break-text %ownership-gap` reused unchanged. One fact has
one sentence, and T5 already wrote it.

### 8. A due reminder renders on the hub, for the default vehicle.

The hub is where the owner looks first and where every other at-a-glance readout
already lives. What is due is the most actionable thing Rover knows, so it goes
there rather than behind the Statistics screen. The section holds one card per
reminder, and a vehicle with no reminder says so rather than rendering nothing.

The card names the service subtype and never the reminder ID. The headline is a
sentence a person acts on — `Due now`, `Due in 3,000 mi`, `Due 2027-06-01` — and
the line under it gives the interval and the point it counts to.

### 9. Distance figures render with the precision they have.

`format-distance-milli` renders exact thousandths and then drops trailing zeros,
so 3,000,000 thousandths reads `3,000 mi` and 2,500 reads `2.5 mi`. Nothing is
rounded and no decimal point appears where the figure has no fraction.

### 10. Time intervals use calendar arithmetic.

`time-unit` is a term. Three months is a calendar step, not 7,776,000 seconds,
and a column of seconds would drift by three days a year. `add-months` carries
into years and clamps the day to the length of the target month, so the 31st plus
one month is the 28th of February. Rolling over into March would move a service
due at the end of January into the month after the one the owner meant.

### 11. `service-reminders` carries `archived`, and T6 ships no endpoint for it.

Every definition family in Rover carries `archived @f`, written literal `N` on
insert. The post-publish rule means a column left out now can never be added, and
a reminder the owner has finished with needs somewhere to go. The rename and
archive endpoints are T8 work, and the scope fence keeps them out of T6. The
view query already reads `WHERE R.archived = N`, so the column is live rather
than decorative.

### 12. One reminder ID is generated per write, and the write is one script.

`insert-reminder` writes the parent and up to two children in one atomic script,
the way `insert-event` does. The lookup phase resolves the vehicle and the
subtype by label first and refuses an unknown one. A reminder never invents a
subtype definition.

## What T6 did not touch

The T1 event shape, the T2 subtype catalog, the T3 odometer relation, the T4
ownership relations, and the T5 derivation are unchanged. `+$ action` in
`desk/sur/rover.hoon` still holds five arms. The eight source reminders import in
T9, not here.

## Commits

```text
06d2ff0  m7t6 opus: add the reminder family and evaluate what is due at read time, with no timer
60e26ac  m7t6 opus: add eleven reminder fixtures, including the countdown across an ownership gap
```

Nothing was pushed. No pull request was opened. Nothing was committed to `master`.
