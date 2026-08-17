# M7 T4 — vehicle acquisition and disposal (`sol`)

Date: 2026-08-17. Every runtime result below came from a real fake ship and
the pinned Obelisk agent. No database result came from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t4-sol`, branch `ab-m7t4-sol` |
| Pier | `~/piers/rover-m7t4-sol-bel`, ship `~bel` |
| tmux / Ames | `m7t4sol` / `32140` |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` at `9de633299b373a1047490b48281a40b457fb2043` |
| Obelisk AST SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |

The required `|install ~dister-nomryg-nilref %obelisk` began a sync, but this
fake `~bel` could not reach the distributor and the desk remained unavailable.
I installed the unmodified desk from `/tmp/obelisk-fresh` instead. That checkout
has the exact pinned commit above, and its AST matches Rover's copy byte for
byte. `%obelisk` then started with `|start %obelisk %obelisk`.

## What changed

T4 adds three relations through the post-publish definition pour:

```text
vehicle-acquisitions (event-id @ux)
  PK event-id
  FK event-id -> vehicle-events.event-id RESTRICT

disposal-kind-definitions
  (disposal-kind-id @ux, label @t, archived @f, recorded-at @da)
  PK disposal-kind-id

vehicle-disposals (event-id @ux, disposal-kind-id @ux)
  PK event-id
  FK event-id -> vehicle-events.event-id RESTRICT
  FK disposal-kind-id -> disposal-kind-definitions.disposal-kind-id RESTRICT
```

The shared event decoder and route handler now accept `%acquisition` and
`%disposal`. Both reuse the parent-keyed cost, odometer, station, tag, payment,
and note relations. A disposal resolves its mandatory definition label to the
intrinsic child column. The six starter definitions are Sold, Traded in,
Totaled, Scrapped, Gifted, and Stolen, each inserted with literal `N`.

The existing Add Event form and history cards now expose both ownership kinds.
No ownership interval, break row, economy change, depreciation, or other T5
derivation was added.

## Inherited work

The branch had no prior commits or tracked changes. It did contain an ignored
`QUESTIONS.md` asking where disposal kind belongs. This brief resolved that
question: `disposal-kind-id` is mandatory and intrinsic to
`vehicle-disposals`. I removed the resolved question.

## TDD evidence

The first schema fixture failed against the pre-T4 desk:

```text
event-test: FAIL - fixture 25 the pour is missing vehicle-acquisitions
```

After the relation and starter slice passed, the first ownership write failed
against the still-unextended HTTP surface:

```text
event-test: FAIL - fixture 26 acquisition event:
405
```

The implementation followed those failures. The finished battery contains 33
plain-integer fixtures; its coverage gate observed every one.

## Fresh-install evidence

I suspended and nuked only this disposable pier's `%rover` agent, dropped only
its populated `%rover` database with `DROP DATABASE FORCE rover`, and installed
the final desk again. The install trace contained:

```text
gall: booted %rover
```

The trace contained zero `nest-fail` lines. Before making an HTTP page request,
`click -k -i probes/disposal-kind-report.hoon` returned six rows from
`disposal-kind-definitions` (`%vector-count 6`) and both
`vehicle-disposals` foreign keys with `%on-delete %restrict` and
`%on-update %restrict`.

## Done-check

| # | Check | Evidence |
|---|---|---|
| 1 | Desk boots without a nest failure | PASS — fresh install trace above |
| 2 | Fresh database seeds disposal kinds without a page load | PASS — direct six-row probe above |
| 3 | Acquisition total and odometer save and read through Eyre | PASS — fixture 26 |
| 4 | Disposal total, kind, and odometer save and read through Eyre | PASS — fixture 27 |
| 5 | Buy, sell, and buy again on one vehicle | PASS — fixture 28 |
| 6 | Trade-in ledgers are independent and have no joining relation | PASS — fixture 29 |
| 7 | Ownership, fill, and charge readings share one odometer stream | PASS — fixture 30 |
| 8 | Disposal and archive state are independent | PASS — fixtures 27 and 31 |
| 9 | Body kind cannot override the route | PASS — fixture 15 |
| 10 | Ownership facts survive a ship restart | PASS — fixture 32 |
| 11 | Shipping action union remains five arms | PASS — fixture 13 |
| 12 | Two consecutive complete runs agree, with no skips | PASS — final runs below |
| 13 | A person can enter purchase and disposal in a browser | PASS — fixture 33, real Chromium |

## Final battery runs

Command for both runs:

```text
bin/event-test.sh /var/home/michael/piers/rover-m7t4-sol-bel
```

Run 1 ended with these verbatim lines:

```text
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 33 PASS - a person records an acquisition and a disposal with kind in the shared browser form
event-test: COVERAGE - all 33 defined fixtures executed
```

Run 2 ended with these verbatim lines:

```text
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 33 PASS - a person records an acquisition and a disposal with kind in the shared browser form
event-test: COVERAGE - all 33 defined fixtures executed
```

Each run performed its own real ship restart. Both returned the same coverage
verdict and reported no skipped fixture.

## Design latitude used

- Acquisition has no kind family. The acquisition event already records the
  ownership opening; adding bought, gifted, and inherited now would create a
  vocabulary T4 does not need, while leased remains explicitly out of scope.
- The owner-editable catalog is named `disposal-kind-definitions`. It follows
  the shipped definition-family names and makes the child's foreign key clear.
- Both kinds share the existing Add Event screen. This preserves the
  route-derived decoder and keeps service, expense, note, acquisition, and
  disposal on one entry path.
- The reused station field is labeled “Location / counterparty.” It gives a
  purchase or sale owner-facing language without adding an association.
- History uses `ACQUISITION` and `DISPOSAL` cards, with a dedicated disposal
  kind line. The view resolves the label server-side and never renders its id.
- Total and odometer retain the event family's absent-row behavior. T4's
  completed purchase and sale fixtures supply both; a missing association is
  incomplete evidence, not a sentinel value.
