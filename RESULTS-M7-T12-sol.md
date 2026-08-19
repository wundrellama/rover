# M7 T12 results — sol

## Outcome

Rover now corrects service, expense, note, acquisition, and disposal events through authenticated Eyre. A correction updates the common parent and its fixed typed child at the current database time. The event ID stays stable. Parent-keyed optional associations are deleted and rebuilt from the corrected form, so an association can be added or removed without a sentinel or orphan.

Each event card in the vehicle's ordered History has an Edit event control. It opens the existing Add Event form with the vehicle, kind, total, source odometer value and unit, station, service subtypes, tags, payment method, note, observed time, zone, and disposal kind prefilled. Kind is disabled and is also checked by the server. The card sends only human labels and the original observed time; it does not expose an event ID.

## Real substrate

- Branch: `ab-m7t12-sol`
- Ship: `~bel`
- Pier: `/home/michael/piers/rover-m7t12-sol-bel`
- tmux session: `m7t12sol`
- Ames port: `32820`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk source and install path: `/tmp/obelisk-fresh` to `/home/michael/piers/rover-m7t12-sol-bel/obelisk`
- Obelisk commit: `9de633299b373a1047490b48281a40b457fb2043`
- Rover install path: `/home/michael/piers/rover-m7t12-sol-bel/rover`
- `sur/obelisk-ast.hoon` SHA-256 in both the worktree and installed Rover desk: `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`

Obelisk remained an unmodified, separate desk and was started with `|start %obelisk %obelisk`. The Rover install trace reported `gall: booted %rover`; each later desk commit reported `gall: reloading %rover` and `gall: bumped %rover`, with no `nest-fail`.

## TDD evidence

The first endpoint fixture failed with HTTP 405 because `/apps/rover/edit-event` did not exist. After the endpoint and atomic update script landed, the real Obelisk fixture passed with one stable parent ID. The first 390px browser fixture then failed waiting for `[data-edit-event]`. After the History control and form-reuse path landed, the same browser fixture reported a prefilled, fixed-kind form, a fitting control and form, a successful correction, and one resulting card.

## Back-to-back event batteries

Both completed runs used this command and the same restored database:

```text
bin/event-test.sh /home/michael/piers/rover-m7t12-sol-bel
```

Before the evidence pair, I cleared developer-only rows produced while watching the red browser fixture and invoked the shipping starter seed. That removed a same-vehicle, same-minute collision deliberately created during diagnosis. There was no rebuild, database drop, reseed, or desk change between the two completed runs. Run 1's round trip held 31 `vehicle-events`; run 2 held 62, proving the second run operated on the first run's retained data.

Run 1 stable service parent:

```text
event-test: fixture 87 identity - 0x3537de5bb78ca36cc6bae551c3f8e9 -> 0x3537de5bb78ca36cc6bae551c3f8e9
```

Run 1 restart proof:

```text
event-test: fixture 93 identity - service 0x3537de5bb78ca36cc6bae551c3f8e9; expense 0xc4249b090c06680c6ad88910268ae40f
event-test: fixture 93 PASS - corrected identities and association additions and removals survive a ship restart with one History card
```

Run 1 final lines, verbatim:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 94 defined fixtures executed
```

Run 2 stable service parent:

```text
event-test: fixture 87 identity - 0xae799101b3c7dec8fbf3c6f92109572e -> 0xae799101b3c7dec8fbf3c6f92109572e
```

Run 2 restart proof:

```text
event-test: fixture 93 identity - service 0xae799101b3c7dec8fbf3c6f92109572e; expense 0x277cd3fd84f9dd886176065c4da81678
event-test: fixture 93 PASS - corrected identities and association additions and removals survive a ship restart with one History card
```

Run 2 final lines, verbatim:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 94 defined fixtures executed
```

The deciding fixtures also proved:

- the corrected cost reached T11's service-family total;
- History rendered one card and the family row count stayed one;
- removing tag and payment links left no association row;
- adding tag, payment, and odometer links kept the expense parent ID;
- the expense sibling's ID, cost, and note did not change during a service correction;
- a kind change returned `%kind-fixed: event.kind - an event kind cannot be changed` without a machine ID;
- the 390px browser reused the Add Event form, kept kind fixed, saved the correction, and rendered one card;
- all corrected state survived the real ship restart.

## UI regression state

`bin/ui-test.sh /home/michael/piers/rover-m7t12-sol-bel` exited 0. The branch includes T11, and its cost fixtures 134 through 138 passed. The final coverage lines were:

```text
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - ran 87 of 114 defined fixtures
ui-test: COVERAGE - SKIPPED, not executed this run: 57 58 59 60 61 62 63 64 65 66 67 69 76 77 78 79 82 83 94 95 96 97 98 99 100 101 102 104
ui-test: COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
```

## Fence audit

- `docs/schema-m0.sql` and `desk/sur/rover.hoon` have no diff from `origin/master`.
- The shipping `$action` union still has five arms.
- No mutation statement contains `AS OF`.
- No `UPSERT` statement exists.
- No relation or column was added.
- The changed paths are limited to the event Eyre handler, event action library, event view and shell, and the event batteries.
- The branch was not pushed, merged, or rebased onto master.

## Design latitude used

- **Ambiguous human locator:** refuse two events on one vehicle at the same original observed time instead of choosing one; a raw ID cannot cross the boundary.
- **Identity-only typed children:** issue a same-key `UPDATE` for service, expense, note, and acquisition children; disposal also updates its editable kind reference. This follows the required parent-plus-child correction shape without changing identity.
- **Existing odometer evidence:** update the linked odometer observation in place and reinsert its parent link; create a new observation only for an incomplete legacy event that had no link. This keeps stable evidence identity when one exists.
- **Required correction mileage:** mark mileage required in edit mode and refuse a blank correction. A correction cannot turn a complete common-header event into an incomplete one.
- **Archived referenced definitions:** add a temporary “current” human option to the reused form when a historical card names an archived station, tag, payment method, subtype, vehicle, or disposal kind. Saving an unrelated correction therefore does not silently drop a still-referenced value.
- **Parent `recorded-at`:** preserve the event parent's original provenance value while Obelisk records the `UPDATE` at its current server time. Replacement rows that carry their own provenance receive the correction time.
- **Round-trip diagnostics:** print the first rendered-History diff when fixture 86 fails. This made a same-minute manual test collision visible without weakening the equality assertion.
