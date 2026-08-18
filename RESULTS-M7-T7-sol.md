# M7 T7 results — vehicle identity and specification

Branch: `ab-m7t7-sol`

Pier: `~/piers/rover-m7t7-sol-bel` on `~bel`

Session and ports: `m7t7sol`, Ames `32320`, Eyre `8111`

Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`

## Substrate

The pier ran stock Obelisk `master` at
`9de633299b373a1047490b48281a40b457fb2043` (`v0.9.0-beta`). The copied
`sur/obelisk-ast.hoon` SHA-256 was
`e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`.

The disposable fake ship could not reach `~dister-nomryg-nilref`. I used the
project's established local fallback: the exact pinned, unmodified Obelisk
checkout at `/tmp/obelisk-fresh`. Obelisk remained a separate desk and started
with `|start %obelisk %obelisk`.

The final Rover reinstall and rein trace ended with:

```text
gall: unnuking %rover
eyre: replacing existing binding at /apps/rover
> |rein %rover [%.y %rover]
>=
gall: booted %rover
```

No `nest-fail` appeared. An authenticated POST to `/apps/rover/view` returned
HTTP 200 after that boot.

## Implementation

T7 adds seven per-vehicle child relations:

- `vehicle-vins`
- `vehicle-license-plates`
- `vehicle-make-model`
- `vehicle-model-years`
- `vehicle-drivetrains`
- `vehicle-appearances`
- `vehicle-notes`

`vehicles` did not gain a column. Every new relation keys to `vehicle-id`, and
every foreign key uses `ON DELETE RESTRICT ON UPDATE RESTRICT`. VIN remains
correctable evidence. It is neither a primary key nor a foreign-key target.

The settings endpoint accepts the 13 requested values, including notes. It
inserts an absent optional row when a value first appears, updates the same row
when a value changes, and deletes the row when the value is cleared. It never
writes an empty string, a zero, `UPSERT`, or a mutation `AS OF`. Year is stored
as `@ud` and rendered as an ordinary four-digit year.

The owner view adds a description only when at least one specification row
exists. A vehicle without specification data gets the pre-T7 rendering, with no
empty description or placeholder terms.

No insurance column, field, endpoint value, or relation was added.

## Design latitude used

I divided the values into seven concern relations. VIN and licence plate each
have a dedicated one-row-per-vehicle relation. A future row-gated grant can
therefore expose only `vehicle-vins` or only `vehicle-license-plates`; neither
grant also exposes the other identifier or any descriptive value. Make, model,
and sub-model use field-keyed rows in `vehicle-make-model`; engine,
transmission, and drive type use the same pattern in `vehicle-drivetrains`;
color, body type, and bed type use it in `vehicle-appearances`. This keeps every
descriptive value independently absent without creating sparsely meaningful
columns. Model year remains a numeric row because it has a different type, and
notes remain their own text concern.

- Relation names use the vehicle prefix and the language shown to the owner.
- The form labels read `VIN`, `Licence plate`, `Sub-model`, `Body type`, and
  `Drive type`; they avoid database terminology.
- Partial specifications render as a compact vehicle description with only the
  recorded values.
- Updates correct evidence in place so vehicle identity and historical links do
  not change.

## TDD and fixtures

I added fixture 55 before the schema or endpoint existed. Its focused first run
failed at the intended boundary: Obelisk reported that `vehicle-vins` did not
exist. The implementation then made that fixture pass before the remaining T7
coverage was added.

Fixtures 55 through 64 prove:

- a VIN can be added after a vehicle already has a fill and odometer history;
- VIN correction preserves the same vehicle, fill, event, and observation IDs;
- all seven relations exist with the required keys and `RESTRICT` foreign keys;
- VIN and plate occupy separate gateable relations;
- a rowless vehicle renders without a specification section;
- all 13 values save and read through Eyre;
- partial input writes no rows for absent values and no empty or zero value;
- model year zero is rejected;
- all rows and absences survive a ship restart;
- a real Playwright browser saves the form and reads the human description;
- no insurance surface exists and the shipping action union remains at five
  arms.

Every VIN and plate in the tree is synthetic and visibly a fixture value. I did
not read the owner's aCar export.

## Final batteries

I ran the full real-substrate battery twice back to back. Both runs restarted
the ship, exercised the browser fixture, and reported every defined fixture
with no skip.

Run 1 final lines:

```text
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub
event-test: fixture 63 PASS - all thirteen fields save from the browser and return in the human vehicle description
event-test: fixture 64 PASS - no insurance stub exists, and every VIN and plate fixture is visibly synthetic
event-test: COVERAGE - all 64 defined fixtures executed
```

Run 2 final lines:

```text
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub
event-test: fixture 63 PASS - all thirteen fields save from the browser and return in the human vehicle description
event-test: fixture 64 PASS - no insurance stub exists, and every VIN and plate fixture is visibly synthetic
event-test: COVERAGE - all 64 defined fixtures executed
```

The isolated live schema battery also passed:

```text
schema-test: PASS - SQL/Hoon parity is 94/94 relations; DDL has 106 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 94 relations; all 106 FK constraints (109 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

Static checks passed:

```text
view-linear-test: PASS
dev-pin-test: PASS
```

## Done-check

All T7 checks passed on the assigned pier: install and boot, all requested
values through Eyre, blank-vehicle compatibility, independent absence, VIN add
and correction without re-keying, identity and foreign-key shape, separate VIN
and plate gating, the insurance exclusion, synthetic fixture identities,
restart persistence, the five-arm action union, two matching battery verdicts,
and complete coverage.
