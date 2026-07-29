# Rover

Vehicle lifecycle tracking as a native Urbit application. Rover records fuel fills,
charging sessions, odometer readings, stations, and consumables for one or more
vehicles, and derives fuel economy and cost figures from that history.

Comparable in purpose to [LubeLog](https://github.com/hargata/lubelog) and
[Fuelly](https://www.fuelly.com/), with the data held on the owner's own ship.

**Status: pre-release.** Rover runs on disposable fake ships only. The schema has not
been published, and it is still repoured as the design changes.

## Design

Rover is a Gall agent that keeps its canonical state in
[Obelisk](https://github.com/jackfoxy/obelisk), a relational database for Urbit.
Obelisk is installed as its own unmodified desk; Rover reaches it through standard Gall
cards and copies only `sur/obelisk-ast.hoon`, the developer API mold. The database
engine is never vendored into the Rover desk.

Four commitments shape the data model:

**Optional data is an absent row, never a sentinel.** Obelisk has no nullable columns,
so an unused column would hold its aura bunt — and a bunt is indistinguishable from a
real value. A `0` in an accuracy column reads as perfect precision; an `@f` bunt reads
as `true`. Optional facts therefore live in child relations whose absence is the
answer.

**Derived values are not stored.** A fill's total is computed from quantity and unit
price at read time. A vehicle's current odometer is derived from its observation
series. Storing either would let it drift from its inputs with nothing to surface the
drift.

**Arithmetic is exact.** Quantities and prices are integers with an explicit decimal
scale — a fill records `12345` thousandths of a gallon and `3499` mills per gallon, not
floating-point approximations. Rounding rules are snapshotted onto each record, so a
later change to a pricing profile cannot re-render past history.

**Values are rendered for humans at every boundary.** Stored integers never reach a
screen. `12345` is presented as `12.345 gal`; a derivation that cannot be computed
renders as unavailable *with a reason*, never as zero or an estimate.

## Repository layout

| Path | Contents |
|---|---|
| `desk/` | The `%rover` Gall desk — agent, libraries, marks, types |
| `desk/app/rover.hoon` | Agent: Eyre binding, HTTP routing, Obelisk dispatch |
| `desk/lib/rover-act.hoon` | Schema and urQL construction |
| `desk/lib/rover-entry.hoon` | Entry decoding and validation |
| `desk/lib/rover-render.hoon` | The human-units boundary |
| `desk/lib/rover-view.hoon` | Projections and screen assembly |
| `docs/schema-m0.sql` | The 62-relation schema, in Obelisk's DDL grammar |
| `bin/schema-test.sh` | Static DDL validation and live schema verification |
| `bin/ui-test.sh` | Browser-half fixture battery against a live pier |
| `probes/` | Click threads for driving and inspecting a running pier |
| `AGENTS.md` | Standing orders for contributors and coding agents |

## Substrate

| | |
|---|---|
| Pill | `brass-408k-1` (zuse 408) |
| Obelisk | `master` @ `eecab1b` |
| Development ships | `~bel` and children, disposable |

Obelisk's `dev` branch is the upstream-recommended source, but at commit `2b72856e` it
requires `strandio`, which the 408 pill does not ship. `master` @ `eecab1b` compiles and
runs on this pill. `AGENTS.md` records the checklist for returning to `dev` once the
runtime allows it.

Because Rover embeds none of Obelisk's engine, changing that pin is a desk swap plus a
mold re-copy plus a fixture run — no application logic changes.

## Browser surface

Rover serves a single-page application over Eyre at `/apps/rover`, authenticated with
the ship's standard `+code` session. The Landscape tile is a docket `site+` binding
rather than a globbed bundle, so the application remains reachable on a ship without
Landscape installed.

The interface is themed after the UA 571-C remote sentry terminal from *Aliens* (1986),
whose props were GRiD Compass laptops with orange electroluminescent panels. It is
mobile-first: a phone is the primary surface.

## Testing

```bash
bin/schema-test.sh    # static DDL validation, then live relation and FK verification
bin/ui-test.sh        # browser fixtures against a running pier
```

Fixtures run against a live fake ship with real Eyre sessions and real Obelisk writes.
Mocked database responses are not accepted as evidence. A fixture that cannot fail is
treated as a defect; a check that cannot be made genuinely failable is recorded as
unverified rather than reported as passing.

## Licence

Not yet licensed. All rights reserved pending a licence decision.

## Documentation

Design records — data model, schema rulings, application structure, import format —
are kept outside this repository. `AGENTS.md` is the standing-order source for anyone,
human or agent, working in the tree.
