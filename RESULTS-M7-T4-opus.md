# RESULTS — M7 T4, vehicle acquisition and disposal (branch `ab-m7t4-opus`)

Date: 2026-08-17. Every result below comes from a run on a real pier against the
pinned Obelisk agent. No result comes from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t4-opus`, branch `ab-m7t4-opus` |
| Pier | `~/piers/rover-m7t4-opus-bel`, ship `~bel`, tmux session `m7t4opus` |
| Ames port | 32004 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` @ `9de6332` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |
| Rover commit under test | `35a90fa` |

The pier is a fake `~bel`, so it cannot reach `~dister-nomryg-nilref` over Ames.
Obelisk came from the pinned local checkout at `/tmp/obelisk-fresh`, which is
`master` @ `9de6332`. Its `sur/obelisk-ast.hoon` carries the SHA-256 the standing
orders pin, and it matches the copy in the Rover desk byte for byte. The desk went
in with `|merge %obelisk our %base`, `|mount %obelisk`, a file copy,
`|commit %obelisk`, `|install our %obelisk`, and `|start %obelisk %obelisk`. Rover
went in the same way.

**Mount before copy.** The first attempt copied the desk files before the mount and
`|commit` answered `%no-sync-duct`. The failed commit left an old `desk.bill` in
place, `|install` then met base's app list and printed
`clay: cannot run app from two desks: %acme`, and the failed kiln install crashed
on every later keystroke. The pier was rebuilt from the pill. The order is merge,
mount, copy, commit, install.

## What T4 adds

Three new relations. No column reaches a populated relation.

```text
disposal-kind-definitions
  (disposal-kind-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (disposal-kind-id)

vehicle-acquisitions
  (event-id @ux)
  PRIMARY KEY (event-id)
  FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id)

vehicle-disposals
  (event-id @ux, disposal-kind-id @ux)
  PRIMARY KEY (event-id)
  FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id)
  (disposal-kind-id) REFERENCES disposal-kind-definitions (disposal-kind-id)
```

All foreign keys are `RESTRICT` on delete and on update. T4 adds **no association
relation**: the odometer, station, cost, tag, payment-method, and note links are the
shipped parent-keyed relations, reused unchanged.

`event-kind` gains `%acquisition` and `%disposal`, and the route match in
`desk/app/rover.hoon` gains `/apps/rover/add-acquisition-event` and
`/apps/rover/add-disposal-event`. There is still one handler and one decoder.

The starter pack holds six labels: Sold, Traded In, Totaled, Scrapped, Gifted,
Stolen. It reaches the database through `seed-starters` and its new child
`seed-disposal-kinds`. The shipping `$action` union still holds five arms.

## Done-check results

| # | Check | Result |
|---|---|---|
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | PASS |
| 2 | A fresh database gets the disposal-kind starter pack without a page load | PASS, probe |
| 3 | An acquisition saves with an entered total and a linked odometer, and reads back | PASS, fixture 27 |
| 4 | A disposal saves with an entered total, a kind, and a linked odometer, and reads back | PASS, fixture 28 |
| 5 | One vehicle carries an acquisition, a disposal, and a second acquisition | PASS, fixture 29 |
| 6 | A trade-in is two independent events, and no join exists | PASS, fixture 30 |
| 7 | Purchase and sale readings land in the one `odometer-observations` list | PASS, fixture 31 |
| 8 | Selling does not set `archived`, and archiving writes no disposal | PASS, fixture 32 |
| 9 | A body naming a kind cannot override the route | PASS, fixtures 15 and 33 |
| 10 | Everything above survives a ship restart | PASS, fixture 34 |
| 11 | The shipping action union still has five arms | PASS, fixture 13 |
| 12 | The battery runs twice with the same verdict, and no fixture is skipped | PASS |

### Done-check 1 — the install

The Rover desk compiled on the first `|install our %rover` after the pier rebuild:

```text
gall: installing %rover
> |install our %rover
>=
gall: booted %rover
```

A search of the whole boot and install transcript for `nest-fail` returned 0 lines.

### Done-check 2 — the starter pack with no page load

`probes/disposal-kind-report.hoon` ran through `click` right after the install and
before any HTTP request reached `/apps/rover`. The database was poured by the
install path, which welds `def-relations` into `schema-m0`, and seeded by the same
path. Six rows came back, none archived (`%archived 102 1` is not archived):

```text
[%vector [%disposal-kind-id 30837 0xf6285575f43f451a1c64841468185d8c]
         [%label 116 'Traded In'] [%archived 102 1] 0]
[%vector [%disposal-kind-id 30837 0xf6285575f43f451a1c64841468185d8d]
         [%label 116 'Totaled'] [%archived 102 1] 0]
[%vector [%disposal-kind-id 30837 0xf6285575f43f451a1c64841468185d8f]
         [%label 116 'Sold'] [%archived 102 1] 0]
[%vector [%disposal-kind-id 30837 0xf6285575f43f451a1c64841468185db0]
         [%label 116 'Stolen'] [%archived 102 1] 0]
[%vector [%disposal-kind-id 30837 0xf6285575f43f451a1c64841468185db2]
         [%label 116 'Scrapped'] [%archived 102 1] 0]
[%vector [%disposal-kind-id 30837 0xf6285575f43f451a1c64841468185db3]
         [%label 116 'Gifted'] [%archived 102 1] 0]
[%vector-count 6]
```

The same probe read the keying of both new children:

```text
child-table %vehicle-disposals
  parent-table %disposal-kind-definitions  on-delete %restrict  on-update %restrict
  parent-table %vehicle-events             on-delete %restrict  on-update %restrict
child-table %vehicle-acquisitions
  parent-table %vehicle-events             on-delete %restrict  on-update %restrict
```

**A probe file must carry no comments.** The first version of this probe opened with
three comment lines and `click` answered `syntax error {1 895}`. The trap is recorded
in the `obelisk-substrate` skill. The explanation now lives here instead.

### Done-check 5 — the buy-sell-rebuy case

Fixture 29 writes a purchase, a sale, and a second purchase on one vehicle. Nothing
rejects the second purchase, the vehicle carries two `vehicle-acquisitions` rows, and
the served history holds all three cards. History runs newest first, so the fixture
asserts that the repurchase card precedes the sale card and the sale card precedes
the purchase card in the document.

### Done-check 6 — no join between the trade-in pair

Fixture 30 writes a `Traded In` disposal on one vehicle and a purchase on another,
then proves the absence four ways:

1. No foreign key names `vehicle-disposals` as a parent.
2. No foreign key names `vehicle-acquisitions` as a parent.
3. Neither child keys to the other.
4. Every column of both children is named and compared. `vehicle-disposals` holds
   `event-id` and `disposal-kind-id`. `vehicle-acquisitions` holds `event-id`.

The fixture also asserts that the out-of-pocket figure is stored nowhere. The pair is
`$31,750.00` and `$9,500.00`, so the figure is `$22,250.00`. That value appears in no
`vehicle-event-cost-totals` row, in decimal or in hex, and in no served card.

### Done-check 12 — two runs, same verdict

Both runs ran on the rebuilt pier, back to back, in the foreground. The verdict lines
are identical once the run stamp is removed. The final lines of run 1:

```text
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: COVERAGE - all 35 defined fixtures executed
```

The final lines of run 2:

```text
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: COVERAGE - all 35 defined fixtures executed
```

Both runs exited 0. The coverage gate reports every defined fixture executed, with no
skips.

## New fixtures

| # | What it proves |
|---|---|
| 25 | The three relations exist, both children key to `vehicle-events`, and nothing keys to either child |
| 26 | Six disposal kinds, one row each, none archived, and a second seed adds none |
| 27 | A purchase saves with an entered total and a linked odometer, and reads back |
| 28 | A sale saves with a total, a kind, and an odometer, and an unknown kind is refused |
| 29 | Buy, sell, and buy back on one vehicle, read back in order |
| 30 | A trade-in is two independent events, with no join and no stored net figure |
| 31 | Purchase and sale readings share the one odometer list with the fill and the charge |
| 32 | Selling sets no flag, and archiving writes no disposal and no event |
| 33 | The route decides the kind for both new kinds |
| 34 | Every T4 fact survives a ship restart |
| 35 | A person records a purchase and a sale in a browser and sees both in history |

## Two harness repairs

Both are in `bin/event-test.sh` and neither changes what a fixture asserts.

1. **Fixture 12 read the urbit binary from `PATH`.** A pier booted with a full path
   runs under a tmux server whose `PATH` may hold no `urbit`, and the restart then
   reported a dead pier. The fixture now takes the binary from the running command
   line. The first argument is not the binary, because the pane runs
   `script -c <binary> ...`, so the match is on the argument that names urbit.
2. **Fixture 34 first counted acquisitions.** Fixture 33 leaves a third acquisition
   behind on purpose, so the count moved between the write and the restart check.
   The fixture now names the two purchases by their observed start.

## Design latitude used

The specs fix the typed-child shape, the route-derived kind, the entered total, the
parent keying, the `archived` rule, and the trade-in rule. These choices were mine.

- **Acquisitions carry no kind, and T4 ships one definition family.** Ruling 13 names
  one family and enumerates only disposal kinds. A disposal kind changes what the
  amount means: a sale is a price, a totaled payout is an insurance settlement, and a
  scrapped or stolen vehicle may bring nothing. A purchase amount is always money out,
  so a kind adds no distinction any derivation can use, and T5 opens an ownership
  interval on the presence of a purchase rather than on its flavor. Leases are out of
  scope, which removes one of the four candidate labels anyway. A second family is a
  new relation, which the post-publish rule permits at any time, so nothing is lost by
  waiting for a real consumer. Adding it now would also owe T8 a second rename and
  archive surface for a vocabulary no screen reads.
- **The disposal kind is a column on `vehicle-disposals`, not a link row.** Every
  disposal has exactly one kind, and mandatory data uses a column. The relation is
  new, so the post-publish rule does not apply. A link row keyed to the event parent
  would let a purchase name how it was sold.
- **The disposal kind is mandatory.** A sale, a write-off, and a theft are different
  facts, and the amount alone cannot tell them apart. The form marks the control
  required where it shows, and the decoder refuses a disposal with no kind.
- **Relation names.** `vehicle-acquisitions` and `vehicle-disposals` are the names the
  plan uses. `disposal-kind-definitions` follows `service-subtype-definitions` and
  `consumable-definitions`.
- **`Traded In` is an ordinary starter label.** It joins nothing and carries no
  special handling, which is what makes ruling 14 hold by construction.
- **Both kinds share the existing event form.** They are a Kind selection beside
  Service, Expense, and Note, labelled Purchase and Disposal. A separate screen would
  duplicate the vehicle, total, odometer, station, tag, payment, note, and date
  controls, and every one of those means the same thing on a purchase as on a service
  visit.
- **The disposal-kind control hides for every other kind, and clears itself.** This
  copies the T2 subtype picker. It is a display affordance, not a schema constraint.
- **The card labels the money by kind.** A purchase shows PURCHASE PRICE and a
  disposal shows AMOUNT RECEIVED. The `data-event-total` attribute does not change, so
  one machine name still serves every kind.
- **The counterparty is the existing station link.** A private seller and a dealer are
  both places where a transaction happened, and `stations` with `places` already holds
  that. Ruling 11 forbids a new association relation here, and inventing a
  counterparty relation would give one event family a second name for the same thing.
- **Fixture 35 is a second browser script**, `bin/ownership-browser-fixture.cjs`,
  rather than more arguments on the T1 script. The T1 script keeps sending exactly the
  form it sent before.

## Scope

T4 stores the facts. It does not build the ownership interval derivation. No break
row, no economy change, no cost per mile, and no depreciation. The T1 event shape, the
T2 subtype catalog, and the T3 odometer relation are unchanged.
