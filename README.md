# Rover

Rover is a self-hosted vehicle log for Urbit. It records vehicle activity and keeps the data on the owner's ship.

Rover supports fuel fills, charging sessions, odometer readings, consumable purchases, stations, and vehicle settings. It calculates economy, costs, and distance estimates from that history.

Rover has a working mobile-first owner interface. It is similar in purpose to [LubeLog](https://github.com/hargata/lubelog) and [Fuelly](https://www.fuelly.com/).

> **Status: pre-release 0.1.0.** Rover operates only on disposable fake ships. The checked-in schema can change before release.

## Current features

### Vehicles

- Create and rename vehicles.
- Select a default vehicle for the application.
- Configure liquid fuel, electricity, and other energy sources.
- Configure a default energy source and fuel subtype.
- Configure tank size, DEF use, DEF tank size, and driving modes.
- Select distance and currency display preferences for each vehicle.
- Archive a vehicle without deleting its history.

### Entries

- Record liquid fuel fills with exact quantity and unit-price values.
- Record charging sessions with energy, battery, cost state, and measurement source.
- Record odometer observations as independent facts.
- Record purchases for DEF, coolant, motor oil, and washer fluid.
- Link entries to stations, odometer observations, additives, tags, driving modes, and payment methods.
- Add notes and typed custom fields to fuel fills.
- Correct every fuel-fill field through one atomic database change.

### History and statistics

- Filter history by vehicle.
- Edit historical fuel fills without replacing their identity.
- Paginate large history and statistics views.
- Calculate eligible full-to-full fuel economy intervals.
- Show missed-fill and exclusion breaks with a human reason.
- Calculate fuel costs, distance between fills, time between fills, and lifetime mean unit price.
- Calculate estimated distance per tank and distance to the next fill.
- Calculate DEF economy separately from fuel economy.
- Refuse incompatible or incomplete calculations instead of showing zero or an estimate.

### Owner controls

- Use starter packs for energy sources, fuel subtypes, additives, driving modes, and consumables.
- Add owner-defined energy sources and driving modes.
- Add number, text, and yes-or-no custom fields.
- Change the interface glow and glow intensity.

## Architecture

`%rover` is a Gall agent. It serves the owner interface through Eyre at `/apps/rover`.

The interface uses the ship's standard login session. It uses an amber UA 571-C color scheme and a mobile-first layout.

Rover stores canonical data in [Obelisk](https://github.com/jackfoxy/obelisk). Obelisk remains an unmodified desk on the same ship.

Rover sends standard Gall cards to Obelisk. The Rover desk copies only `sur/obelisk-ast.hoon`, which defines the developer API types.

The current schema has 68 relations. It covers vehicles, energy, observations, locations, consumables, custom fields, and import provenance.

## Data rules

**Optional data uses an absent row.** Obelisk has no nullable columns. Rover does not use zero, empty text, or an aura bunt as a missing value.

**Derived values are not stored.** Rover calculates totals, current odometer values, and economy figures from their source records.

**Arithmetic is exact.** Rover stores quantities, prices, coordinates, and other decimal values as scaled integers.

**Historical meaning does not change.** Each fuel fill stores the rounding rules that applied when the owner recorded it.

**Corrections use normal database history.** Rover updates the current row. Obelisk keeps prior database states for temporal queries.

**Archive replaces deletion.** Rover retires referenced definitions and vehicles without removing their history.

**Human boundaries use human values.** The interface shows labels, units, completed prices, and refusal reasons instead of raw identifiers.

## Import tools

Rover includes a versioned JSON import path for operators. The browser Settings screen does not expose import controls yet.

The import format covers definitions, places, vehicles, and fuel fills. It does not cover charges, consumables, standalone odometers, or service history.

`tools/acar-import/convert.py` converts an aCar XML export into Rover import JSON. It validates units, reports unsupported data, and refuses guesses.

The converter writes output outside this repository. It removes JPEG application metadata before it writes extracted photos.

Rover does not attach those photos to database records. The converter records them in a separate attachment manifest for later work.

`tools/rover-import/upload.py` sends bounded batches to the authenticated import endpoint. Import provenance makes identical retries safe and reports changed source records as conflicts.

```bash
python3 tools/acar-import/convert.py /path/to/acar-export \
  --zone America/Chicago \
  --dry-run

python3 tools/acar-import/convert.py /path/to/acar-export \
  --zone America/Chicago \
  --out /path/to/rover-output

python3 tools/rover-import/upload.py /path/to/rover-output/rover-import.json \
  --dry-run
```

A real upload also needs the full `/apps/rover/import` URL and an authenticated cookie file.

## Testing

The main batteries use a live fake ship, real Eyre authentication, and the pinned Obelisk agent. Mock database responses do not count as integration evidence.

```bash
bin/dev-pin-test.sh
tests/view-linear-test.sh
bin/schema-test.sh <pier>
ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
bin/import-test.sh <pier>
bin/view-performance-test.sh <pier>
python3 tools/acar-import/test_convert.py
python3 tools/rover-import/test_upload.py
```

Every pier command requires an explicit pier path. Use only a disposable Rover pier.

The live batteries replace the active `rover` database with a temporary test database. They restore the owner database after the run.

The UI battery also applies a final demo-data guard. Use a pristine demo-only owner database for the complete UI battery.

The fixture coverage gate lists every skipped fixture. A partial run does not become a complete pass because its executed checks are green.

`ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>` runs all 90 defined UI fixtures and is the complete UI battery.

`ROVER_LEGACY_ONLY=1 bin/ui-test.sh <pier>` is a Phase-A diagnostic, not a battery. It asserts against `Phase A Vehicle`, which only exists on a pier where someone poked `%seed-spike`, so it fails on a clean pier with `per-vehicle action missing: Add Charge`. Seeding alone does not fix it: the hub renders `Add Fill` and `Add Charge` from the energy sources of the **app default vehicle**, and `seed-spike` never writes the `app-default-vehicle` singleton, so both buttons stay hidden. Running the leg needs `click -k -i probes/seed-spike.hoon <pier>` plus a default-vehicle designation. Skip it otherwise. The Gate 7 fixture fence retires this dependency.

## Substrate

| Component | Current pin |
|---|---|
| Urbit pill | `brass-408k-1` with zuse 408 |
| Obelisk | `master` @ `9de6332` (v0.9.0-beta) |
| Development ships | Disposable `~bel` lineage ships |

The copied Obelisk API mold and the pinned upstream mold must have the same SHA-256 value. `bin/dev-pin-test.sh` checks the commit and both files.

## Repository layout

| Path | Purpose |
|---|---|
| `desk/app/rover.hoon` | Gall agent, Eyre routes, and Obelisk request handling |
| `desk/app/rover/` | Browser shell, fonts, and tile art |
| `desk/lib/rover-act.hoon` | Schema and urQL changes |
| `desk/lib/rover-entry.hoon` | HTTP input decoding and validation |
| `desk/lib/rover-import.hoon` | Import planning, comparison, and reports |
| `desk/lib/rover-render.hoon` | Human units and exact value formatting |
| `desk/lib/rover-view.hoon` | Owner views, history, statistics, and pagination |
| `docs/schema-m0.sql` | Current 68-relation Obelisk schema |
| `bin/` | Live schema, browser, import, pin, and performance batteries |
| `tools/` | aCar conversion and Rover import upload tools |
| `probes/` | Click threads for live inspection and fixture control |
| `tests/view-linear-test.sh` | Static regression guard for linear, paginated views |
| `RESULTS.md` | Schema and data fixture evidence |
| `RESULTS-UI.md` | Browser and owner-interface fixture evidence |
| `RESULTS-M0CC.md` | Charging cost entry fixture evidence |

## Not implemented

- Cross-ship sharing and per-field grants.
- Remote mutation.
- Browser controls for import or export.
- Maintenance, service, insurance, tax, and modification records.
- Database attachment storage.
- Permanent charger and connector inventory.
- A supported release installation or migration path.

## License

Rover is licensed under the **GNU Affero General Public License, version 3 or
later**. The full text is in [`LICENSE`](LICENSE).

If you run a modified Rover as a network service, the AGPL requires you to offer
that service's users the corresponding modified source.

Third-party components carry their own terms and are listed in
[`NOTICE.md`](NOTICE.md):

- `desk/sur/obelisk-ast.hoon` is the `%obelisk` developer API mold, copied
  unmodified from upstream under its MIT+n license.
- The `%base` system files under `desk/lib/`, `desk/sur/docket.hoon`, and
  `desk/mar/` are MIT, copyright Tlon Corporation.
- The JetBrains Mono faces under `desk/app/rover/assets/fonts/` are under the SIL
  Open Font License 1.1, copyright The JetBrains Mono Project Authors.
