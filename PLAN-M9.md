# M9 — in progress

Opened 2026-09-12 from a completed M8 at `1674f25`.

## Scope

M9 was scoped as debt (rulings 26 and 27), a bounded JSON read API, and one
converted page. The first real-corpus import displaced that order: reading the
owner's own 420 fills through the app found three defects the battery could not
see, and those were repaired first. The read API has not started.

## What landed

| | Delivered | Commit |
|---|---|---|
| 1 | The import is one file, and the browser unpacks it | `5357b88` |
| 2 | A history fill card shows its mileage and derives its economy | `0095917` |
| 3 | A photograph can reach a record that already exists | `cc57001` |
| 4 | Fixture 116 asserts all three | `ccd0b03`, `ed48b5c` |

`bin/event-test.sh` holds **116 fixtures**, green twice back to back on one
pier, exit 0 both times, coverage gate reporting every fixture executed and none
skipped.

## Ratified this milestone

Ruling 28 and two findings, recorded in `~/brain/projects/rover/app-structure.md`.

- **A bridge is a moon of the owner's own planet**, reaching Rover over Ames.
  Rover stores no key and no token.
- **Bridge authorization is the second pour.** Ruling 25 warned that the answer
  must not become the sharing protocol by accident. That framing is wrong: a
  list of ships permitted to touch an owner's data *is* a grant list, and read
  or write is a column on it. There was never an answer outside sharing.
- **Ruling 26's premise about restarts is false.** `on-load` does not run when a
  pier stops and starts. Measured with a marker that printed on commit, printed
  again after the marker text changed, and printed zero times across a full cold
  start while the agent answered 200.

## The finding that cost the most to learn

Three defects shipped on one screen and 115 fixtures were green over all of
them. A fixture that asserts on rendered output cannot see a field that was
never written; the inverted economy branch is briefly true on a small corpus,
because a fresh database really has no earlier eligible fill; and a second
renderer for the same record showed the mileage correctly, so the obvious check
passed.

Fixture 116 is written against that: it states the arithmetic — 300 miles on
15.000 gallons is 20 mpg — and requires the card to match, rather than accepting
whatever the renderer prints.

## Published

`%rover` is installed and published on `~hilpem-hocryt-dinnyt-divsud` at
`ccd0b03`, whose desk is byte-identical to `ed48b5c`. Obelisk on that ship was
verified file by file against the pin. The database auto-provisioned on install
with 105 relations, so a fresh remote install needs no dojo command.

**`%noun [%add %desk]` is not enough to publish.** It sets `sovereign` and
returns success while leaving the alliance untouched, so nothing advertises the
desk. `%alliance-update-0` with `[%add our %desk]` sets both. The alliance scry
is what proves it; the poke's own answer does not.

## Not done

- The bounded JSON read routes, which were M9's stated body.
- Rulings 26 and 27 remain unbuilt. Ruling 26 is one term on
  `desk/app/rover.hoon:2052` plus a fixture that must reinstall rather than
  restart.
- Removing a photograph from a record. Adding works; removal needs a delete path
  that does not exist, and Clay reclamation is three steps.
- The rendered page on the publish moon has never been fetched. The agent is
  live, the docket is charged, the schema poured, and the auth fence refuses
  anonymous requests, but the HTML itself is unverified.
