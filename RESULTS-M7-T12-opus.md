# M7 T12 — Correcting an event — opus

## Outcome

A person can correct a service event, an expense, a note, a purchase, and a
sale. Before this task only a fill could be corrected, and the other five
families were write-once because no endpoint corrected them.

`/apps/rover/edit-event` mirrors what `edit-fill` proves. It takes the owner's
authenticated Eyre session, a JSON body, and refuses a bad shape with a named
reason. Every event card in History carries an Edit control that opens the Add
Event form with the person's own entry in it and saves as a correction.

The correction is an `UPDATE` in place at `NOW`. The event keeps its id, so
every association still targets it. Obelisk retains the prior content state and
a read `AS OF` recovers it. Rover writes no revision row, no reversing entry,
and no second ledger, and it issues no mutation `AS OF`.

No new relation, no new column. The shipping `$action` union is still five arms.

## Real substrate

- Branch: `ab-m7t12-opus`
- Base: `master` at `fd8e00a`
- Pier: `/home/michael/piers/rover-m7t12-opus-bel`
- Ship: `~bel`
- tmux session: `m7t12opus`
- Ames port: `32810`
- Eyre port: `8120`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk source: `/tmp/obelisk-fresh/desk`
- Obelisk install: `/home/michael/piers/rover-m7t12-opus-bel/obelisk`
- Obelisk commit: `9de633299b373a1047490b48281a40b457fb2043`
- Obelisk start command: `|start %obelisk %obelisk`
- Copied `sur/obelisk-ast.hoon` SHA-256:
  `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`

Obelisk went in as its own unmodified desk. The desk went in with
`|merge %obelisk our %base`, `|mount %obelisk`, a file copy, `|commit %obelisk`,
`|install our %obelisk`, and `|start %obelisk %obelisk`. The pier printed:

```text
gall: installing %obelisk
gall: installing %obelisk-web
> |install our %obelisk
>=
gall: booted %obelisk
gall: booted %obelisk-web
> |start %obelisk %obelisk
```

The Rover desk compiled on the first `|install our %rover`:

```text
gall: installing %rover
> |install our %rover
>=
gall: booted %rover
```

Every later source commit printed `gall: bumped %rover`. No transcript held
`nest-fail` after the first compile error, which is recorded under TDD below.

## What the correction does

### The endpoint

`/apps/rover/edit-event` is one route for all five kinds. The add path puts the
kind in the route so a client cannot name a kind that disagrees with the typed
child it gets. A correction cannot do that: the event already has a typed
child, and the correction has to hold to it. The requested kind therefore
arrives in the body, and the database decides whether it agrees.

The record is named the way a person sees it. The body carries the vehicle
label and `originalObserved`, the local moment the record currently holds. No
machine id crosses the HTTP boundary in either direction. This is exactly what
`edit-fill` does.

### Three phases

A mutation cannot follow a result-returning query in one Obelisk script, so the
write is the third of three.

1. `+edit-event-lookup` turns the vehicle label and the recorded moment into an
   event id. Two rows at one moment on one vehicle cannot be told apart by the
   only handle a person has, so Rover corrects neither and answers `409`.
2. `+edit-event-state` reads which typed child the event has, which odometer
   observation it links to, and every catalog the corrected form may name.
3. `+update-event` is one atomic mutation-only script.

Phase two is separate from phase one because its child probes have to key on
the resolved id. Each probe names one relation with a predicate and no join. A
join would reach through a child relation that is legitimately empty — a
database with no note event holds an empty `note-events` — and T11 measured the
pinned engine failing that shape.

### The script

```text
UPDATE vehicle-events SET observed-start, observed-end, source-zone, recorded-at
  WHERE event-id = <the id the lookup resolved>
UPDATE vehicle-disposals SET disposal-kind-id          (a disposal only)
DELETE the seven optional association relations for that event
INSERT whatever the corrected form carries
```

The event id is never regenerated. It is the identity the correction preserves.

Seven association relations are cleared and rewritten: `vehicle-event-costs`,
`vehicle-event-cost-totals`, `vehicle-event-stations`, `vehicle-event-tags`,
`vehicle-event-service-subtypes`, `vehicle-event-payment-method`, and
`vehicle-event-notes`. Obelisk has no nullable column, so a missing row is the
only way an association goes from present to absent. The cost total keys to the
cost row, so the total leaves first and returns second.

The odometer is handled apart from the other six. A corrected reading `UPDATE`s
the observation the event already links to, so the reading keeps its identity
too and the link never moves. A correction that clears the reading drops the
link and then the observation it named. Leaving the observation would put a
reading in the vehicle's odometer stream that no event claims, and every
derived distance would count it.

### The kind is fixed at creation

A service event that should have been an expense is a different family with a
different typed child. Moving the row between relations would break every link
into it. Rover refuses and says why:

```text
%wrong-kind: edit-event.kind - an event keeps the kind it was recorded under.
Record the event again under the kind you want.
```

The refusal names the failure class and the offending field, per R8 Refinement
A, and then gives the reason in a sentence a person can act on. **I agree with
the ruling.** The alternative is a `DELETE` and an `INSERT` under a new id,
which is a new event wearing the old one's date, and every link that pointed at
the original would have to be found and moved. Rover does not build deletion,
and this is one of the reasons why.

### Arithmetic

An event total is entered, not derived. Ruling 13 settles this: a purchase
price and a shop invoice have no quantity and no unit price, so there is
nothing to multiply. A corrected total is parsed by `+parse-money:render`, the
same arm that parsed the original, into exact mills. No floating point is
involved on either path. The half-up-after-multiply rule the brief names
applies to the fill path, where operands exist, and `edit-fill` still owns it
unchanged.

### The vehicle cannot move

The lookup finds the event by the vehicle label the body carries, so a body
naming a different vehicle finds no event and gets a `404`. The parent's
`vehicle-id` is never written. `edit-fill` behaves the same way, so the two
correction paths agree.

## The UI

Each event card carries an Edit button under the facts. Pressing it fills the
Add Event form and switches it to correction mode: the heading reads "Correct
event", the button reads "Save correction", and the hidden `originalObserved`
names the record. Opening the Add Event screen any other way puts the form back
in add mode, so a correction target never outlives the screen.

One form serves both jobs. A second form would drift from the first, and a
selector missing from one of them would silently drop the association it
offers. For the same reason `+event-lookup` and `+edit-event-state` now share
one `+event-catalogs` arm.

The button carries every value in the exact text its form field takes, so
filling the form is a copy. Nothing is read back out of the rendered card: the
odometer there is converted to the display preference and formatted with
separators, and it would round-trip into the wrong unit. Tags and subtypes are
read from the card's own `data-event-tag` and `data-event-subtype` lists.

The kind selector stays live during a correction. A greyed-out control with no
explanation tells a person less than a refusal that names the reason, and the
refusal is only reachable if the attempt is.

The control is one short word, right-aligned, on its own row under the card's
facts. It fits 390px and does not grow with the content beside it. Colors come
from the existing UA 571-C variables.

## TDD evidence

The fixtures went red before the code. With the T12 desk stashed and the
pre-T12 desk committed to the same pier, `bin/event-test.sh` reached fixture 87
and stopped:

```text
event-test: fixture 75 PASS - an unknown family, an absent definition, and a missing or empty new label are each refused, and none of them writes
event-test: FAIL - fixture 87 the correction: 
405
exit=1
```

`405` is Eyre answering that no such route exists.

Three real defects the runs found, each fixed before the green pair:

- **`snag` on a `?~`-narrowed list.** The first `|commit %rover` failed with
  `nest-fail` at `app/rover.hoon` line 1901, `-have.%~`, under `mull-grow`.
  Reading the resolved row as `i.rows` instead of `(snag 0 rows)` compiles and
  says the same thing.
- **`N` is the urQL literal for false.** A relation aliased `N` fails to parse
  when the query projects `N.event-id`. The T9 fixtures already use `Z` for
  `vehicle-event-notes`, for this reason. The new loop now does too.
- **The correction fixtures moved a figure fixture 24 derives.** Their odometer
  readings were later than the charge on the shared event vehicle, so the
  derived current odometer changed and fixture 24 failed with no defect behind
  it. The correction fixtures now record on a vehicle of their own.

## The battery

Nine new fixtures, 87 through 95. Eight are the brief's list. The ninth
drives the whole correction with a pointer.

| Fixture | What it decides |
|---|---|
| 87 | A corrected cost keeps the event id, every association still names it, and the prior total reads back `AS OF` |
| 88 | A second correction makes no second event, no second typed child, and one card |
| 89 | A tag and a payment method go from present to absent, with no orphan row and no lost definition |
| 90 | A total, an odometer, a station, a tag, and a payment method are added to an event that had none |
| 91 | A corrected cost moves the exact T11 ownership total and the spend-by-family row |
| 92 | A sibling event on the same vehicle is untouched |
| 93 | A kind change is refused with a human reason and writes nothing |
| 94 | All of it survives a ship restart, and correcting still works after it |
| 95 | A person corrects an event from the card in a real browser at 390px |

Fixture 91 asserts on real T11 statistics, which has merged on this branch. A
vehicle with a $10,000.00 purchase and a $200.00 service reports
`data-total-cost-mills="10200000"`. After the service is corrected to $450.00
it reports `10450000`, the spend-by-family service row reads `450000`, and the
old figure appears nowhere.

Fixture 87 also proves the audit trail the correction posture relies on. The
pre-correction total is read `AS OF` a moment between the two writes. The read
returns the same event id and the old total. A read `AS OF` is allowed. Rover
issues no mutation `AS OF` anywhere.

### Both runs, verbatim final lines

Run one:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 95 defined fixtures executed
exit=0
```

Run two, back to back on the same database, with no rebuild and no drop:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 95 defined fixtures executed
exit=0
```

The coverage line is `COVERAGE - all 95 defined fixtures executed` in both. No
fixture was skipped.

The second run saw the first run's data. Fixture 86 reports every relation
count, and the correction relations grew between the runs, which is what proves
the database was not dropped:

```text
run one: round-trip relation vehicle-notes: 31 -> 31
run two: round-trip relation vehicle-notes: 34 -> 34
```

This pier had ten battery runs behind it when the pair ran, not two.

### The identity proof

Fixture 87 prints the parent id before the correction, after it, and as read
`AS OF` the moment between the two writes.

Run one:

```text
event-test: fixture 87 identity - before: %event-id 30837 0x9cb1161103deda13668617933a00e92a
event-test: fixture 87 identity - after:  %event-id 30837 0x9cb1161103deda13668617933a00e92a
event-test: fixture 87 identity - AS OF ~2026.08.19..06.14.24: %event-id 30837 0x9cb1161103deda13668617933a00e92a at 300,000 mills
```

Run two:

```text
event-test: fixture 87 identity - before: %event-id 30837 0x5d31c8a1f9b115906ed6762c330f656a
event-test: fixture 87 identity - after:  %event-id 30837 0x5d31c8a1f9b115906ed6762c330f656a
event-test: fixture 87 identity - AS OF ~2026.08.19..06.25.46: %event-id 30837 0x5d31c8a1f9b115906ed6762c330f656a at 300,000 mills
```

One id. The cost moved from 300,000 to 355,250 mills under it, and the prior
value is still readable.

### Two harness limits the two-run rule found

Both arrive with data volume. Neither is a Rover defect, and neither shows on a
fresh pour. Both are repaired.

**The fixture 86 count probe could not read a large relation.** It reads one
whole relation per query, and `click` cannot carry back an arbitrarily large
result. At 656 rows this came back as `cue failed`:

```text
FROM odometer-observations X SELECT X.odometer-id;
```

The probe then reported a missing count, not a wrong one:

```text
event-test: FAIL - fixture 86 the source count probe did not return all 101 relations
```

A relation that will not read in one piece is now counted in key ranges and the
parts are added. The split is on the first projected column, which is the
leading column of the primary key. Rover ids are random 128-bit, so the halves
are even: `odometer-observations` split 329 and 327. Six splits and the fixture
fails. A count this probe cannot take is never reported as zero.

**The fixture 12 restart raced the king.** It waited only for the serf to exit.
The king outlives the serf and holds the pier lock on its way out, so the next
pier exited at once and the fixture reported a pier that never came back:

```text
event-test: FAIL - fixture 12 the pier did not restart
```

The wait now covers every urbit process on this pier, scoped to `pgrep -x
urbit` because a bare path match also matches the battery's own command line.
This is the same race `app-structure.md` records from the T3 migration battery,
in a second place. The failure now prints the pane text, which the old one
threw away with the session.

## `bin/ui-test.sh`

Green, exit 0, with the T12 change in place:

```text
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - ran 87 of 114 defined fixtures
ui-test: COVERAGE - SKIPPED, not executed this run: 57 58 59 60 61 62 63 64 65 66 67 69 76 77 78 79 82 83 94 95 96 97 98 99 100 101 102 104
ui-test: COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
exit=0
```

T11 has merged on this branch, and the brief says that means this battery is
green. It is. The skipped fixtures are the flag-gated ones the battery reports
by design.

I did not capture a pre-change baseline of this battery on this pier, so I
cannot show a before and after pair. The state after the change is green, which
is the best state it has, so no change of mine made it worse.

## Design latitude used

- **Three phases, not two.** Phase one resolves the id and phase two probes the
  typed children with single-relation predicates. Folding the probes into phase
  one needs a join through a child relation that is legitimately empty, which
  T11 measured the pinned engine failing.
- **The requested kind rides in the body.** The add path takes it from the
  route. A correction has one route for five kinds, so the route cannot carry
  it, and the stored kind is what the request is checked against.
- **`200`, not `201`.** A correction mints nothing. The record a person is
  looking at is the record they already had.
- **The refusal carries a sentence.** R8 Refinement A asks for a named class and
  field. The brief asks for a human reason. The text gives both.
- **A cleared reading deletes its observation.** An observation no event claims
  would still sit in the vehicle's odometer stream and every derived distance
  would count it. This is the one place the correction path deletes a row that
  is not an association link, and it deletes it because the link went.
- **`+event-catalogs` is shared.** `+event-lookup` and `+edit-event-state` read
  one list, so the create form and the edit form cannot come to offer different
  selectors.
- **The kind selector stays live during a correction.** A refusal that explains
  itself beats a disabled control that does not.
- **The correction fixtures use their own vehicle.** Writing them onto the
  shared event vehicle moved a figure fixture 24 derives.
- **`cell_number` in the battery.** The report printer writes a small atom in
  decimal and a large one in hex, so no numeric assertion may compare the
  printed token.
- **The count probe splits on the key range.** Every other way to count a
  relation the transport cannot carry either changes what fixture 86 asserts or
  needs a server-side aggregate the pinned engine does not execute.
- **A browser fixture of its own.** `bin/correction-browser-fixture.cjs` is a
  second file rather than a flag on `bin/event-browser-fixture.cjs`, so the T1
  fixture keeps driving exactly the form it drove before.

## Scope

Built: event correction only.

Not built: deletion. The scope fence forbids it and it has not been ruled on.
Correction is coherent without it — a person fixes a wrong figure, a wrong date,
a wrong association, or a wrong note, and every one of those is a correction of
a thing that happened. Only "this never happened at all" needs deletion, and
that is the different question the fence names.

Not built: a revision table, a correction log, a `corrected at` column, or any
second ledger. The doctrine forbids each one and Obelisk already keeps the
history.

Not changed: `edit-fill`, and nothing T1 through T11 built.

## One question relayed

`QUESTIONS.md` carries it. The brief says the correction path handles the
odometer by delete and reinsert, and also says a correction that drops the
odometer link must be refused "the way creation does". Creation does not refuse:
fixture 7 of this battery asserts that a blank mileage writes no odometer row.

T12 built the correction path to match the create path exactly, so a blank
mileage removes the link the same way it never writes one. That keeps the two
paths in agreement and makes a create-then-correct round trip through one form
lossless. Nothing else in T12 depends on the answer.
