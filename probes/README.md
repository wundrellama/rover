# Rover probes

Standalone `click -k -i` threads run against a live fake pier. Each returns a
vase; read the tail line of the output.

    export PATH="$HOME/workspace/urbit/bin:$PATH"
    click -k -i probes/<name>.hoon ~/piers/rover-binbel

The dev pier is `~/piers/rover-binbel` (pid → port via `ss -lntp | grep urbit`;
the HTTP port moves on restart). Never touch `~/piers/fakezod` or
`~/piers/fakenec` — another project owns those and they are live.

## PITFALL: no `::` comments in probe files

**A single `::` comment anywhere in a `click -k -i` file is a syntax error.**
Verified 2026-07-30 by bisection: the identical thread parses without the
comment and fails with it, and the reported error column tracks the comment's
length — click flattens the file before evaluation.

    =/  m  (strand ,vase)      =/  m  (strand ,vase)
    ::  a comment              ;<  our=@p  bind:m  get-our
    ;<  our=@p  bind:m  get-our    (pure:m !>(our))
    (pure:m !>(our))
    → syntax error             → [0 %avow 0 %noun 619]

Position does not help — before or after the strand line both fail. Document
probe intent **here**, not in the file. No pre-existing probe has a leading
comment, which is why this went unnoticed.

## PITFALL: no date literals inside urQL tapes

`~2026.7.30` written into a tape is a parse error. Interpolate instead:

    =/  stamp=tape  (scow %da now)
    "INSERT INTO t VALUES (0x1, 'x', N, "  stamp  "); "

## Gate 7 T1 — readbacks and diagnostics poke %obelisk directly

Every readback report and diagnostic probe now sends its urQL straight to
`%obelisk` with `[%script %rover %vector "<urql>"]` on a per-probe wire. No
probe in this directory pokes a `%rover-action` readback, diagnostic, or
calculator arm. The urQL text is lifted verbatim from the matching arm in
`desk/lib/rover-act.hoon`, which stays in place until T2 deletes it.

Probe defaults for the parametrized reports name demo fixture rows:
`vehicle-settings-report` and `fill-edit-report` read `Rover Demo Gasoline`,
`consumable-report` reads the `Rover Demo Diesel` DEF purchase, and
`station-report` reads `Market Mixed Station`. Run `bin/ui-test.sh` with
`ROVER_DEMO_ONLY=1` and `ROVER_NO_FIXTURE_ISOLATION=1` first, or the reports
return empty result sets. `charge-subtype-report` reads the
`Charging Evidence Vehicle` session and returns an empty set until a
charging subtype entry surface exists (see QUESTIONS.md).

The six `integrity-*` mutation probes carry fixed fixture ids. Each script
ends in a statement the substrate must refuse, the whole script is atomic,
so nothing persists and reruns never collide. The expected result is an
error fact: `[0 %avow 0 %noun 1 ...]`. `integrity-zero-subtype` and
`integrity-two-subtypes` exercise the Rover-side XOR check, so they build
`lib/rover-act.hoon` and call `validate-acquisition-subtypes` directly.

The calculator probes (`pricing-preview*`, `pricing-total*`,
`charging-total`) also build the lib and call the arm. They no longer keep
a poke alive to test a function.

The probe files for `seed-spike`, `seed-app-structure`, `seed-charging-cost`,
and `seed-demo-fuel` are gone: `bin/ui-test.sh` now creates that state
through the product endpoints. The five remaining `seed-*` probes
(`seed-fuel-evidence`, `seed-charging-evidence`, `seed-consumption`,
`seed-location`, `seed-pricing`) still poke their `%rover-action` arms
because no endpoint can express their evidence rows. QUESTIONS.md carries
one finding per gap.

Note on the date-literal pitfall below: the generated Gate 7 probes embed
dates in the padded `scow %da` form (`~2026.07.01..12.00.00`) inside their
urQL tapes, and those parse and execute (verified 2026-08-11 on the live
pier). Keep the interpolation habit for hand-written probes.

## Probe index — import/export work

### `profile-view-query.hoon`

Times the current 37-clause `+ui-view` `%script` with `%vector` output against a live profiling pier
without invoking Rover's Gall-side assembly or HTML renderer. It receives and
discards the Obelisk fact, then returns only `~`, so terminal printing of the
result vectors is excluded. Measure it from the host with `/usr/bin/time`.

This probe contains query structure only. It emits no row contents and writes
nothing to Obelisk.

### `profile-control.hoon`

Measures the fixed `click -k -i` startup/evaluation overhead for the query
profile above. Subtract its median wall time from `profile-view-query.hoon` to
isolate the `%script` request and fact delivery.

### `cetane-pour.hoon`
Import Q1. Pours `energy-subtype-cetane` into a **throwaway `cetprobe`
database**, inserts the real cetane-45 ULSD shape plus a 93-AKI gasoline row,
then reads both back joined.

Expect one cetane vector `[%energy 'Diesel'] [%subtype 'ULSD'] [%rating 45]`
with **no method**, and one octane vector `[%energy 'Gasoline'] [%rating 93]
[%method %aki]` — exactly one rating row per subtype, each from the correct
relation.

Writes only to `cetprobe`, never to `%rover`: fixture data must not reach
owner-facing state. Drop it from the dojo when finished
(`DROP DATABASE cetprobe`) — the agent tooling blocks that as destructive.

### `rating-scale-report.hoon`
Import Q2. Reads the ignition-mode lookup — Rover stores **nothing** about
ignition mode, so this builds `tests/lib/rover-enums` and reads
`+rating-scales`.

Expect exactly:

    ['Gasoline' ~ %octane] ['Ethanol' ~ %octane] ['Propane' ~ %octane]
    ['Diesel' ~ %cetane]
    ['Electricity' ~] ['Hydrogen' ~] ['CNG' ~] ['LNG' ~]

The four `~` entries are **assertions, not gaps**: Electricity and Hydrogen
have no anti-knock rating at all, and CNG/LNG are rated on **methane number**,
a third scale Rover deliberately does not model. A future edit that
"helpfully" classifies CNG as `%octane` must fail this fixture.

**Falsifiability verified 2026-07-30**: flipping Diesel to `` `%octane `` in
`tests/lib/rover-enums.hoon`, committing, and re-running showed the change in
the output — the probe reads live built state, not a cached constant. Restored
afterward.

### `import-provenance.hoon`
Import Q5. Pours `acquisition-imports` into a **throwaway `impprobe` database** with the
minimal vehicle/definition/acquisition backbone it needs, then proves the re-import
contract.

Expect three result sets:

1. **2 provenance rows** — aCar `78432901` and Fuelly `78432901` coexisting. This is the
   namespacing proof; an unnamespaced key would collide.
2. **Exactly 1 row** for `WHERE source-app = %acar` — predicate executes server-side.
3. **3 acquisitions**, of which `0xbeef0101` and `0xbeef0102` share an **identical
   `observed-start`** (two legitimate same-minute fills), and `0xbeef0103` has **no**
   provenance row (owner-entered).

Result set 3 is the point: the same-minute pair is exactly what a natural-key dedup
(`vehicle` + `observed-start`) would silently refuse. Provenance keeps both and still
tells them apart. If a future change makes those two rows indistinguishable, that
regression is the one this probe exists to catch.

Writes only to `impprobe`, never `%rover`. One-shot: re-running fails on
`CREATE DATABASE` because the database already exists — drop it from the dojo
(`DROP DATABASE impprobe`) to re-run, since the agent tooling blocks that as
destructive.

### `address-q9.hoon`
Import Q9. Pours the amended address family into a **throwaway `addrq9probe`
database** and inserts four synthetic places: formatted text plus parts,
parts-only, formatted-only, and no address evidence.

Expect four result sets:

1. All four places exist.
2. Exactly three have `place-addresses` parents; `No Address Place` does not.
3. Exactly two have `place-address-formatted` children: `Both Evidence Place`
   and `Formatted Only Place`.
4. Parts read back for `Both Evidence Place` and `Parts Only Place`; the
   parts-only place has both `%line1` and `%locality`.

The parts-only row is the rejected-alternative hazard: the pre-Q9 schema could
not store it because `formatted` was mandatory on the parent. The probe uses
two separate pokes because `CREATE DATABASE` and a query against it cannot
share one request. It writes only to `addrq9probe`, never `%rover`, and is
one-shot unless that throwaway database is dropped from the dojo.

### `run-test-import.hoon`

Compiles and executes `desk/gen/test-import.hoon` from the live `%rover` desk.
It checks the import decoder, mandatory `defaultEnergy`, Q14 unit validation,
source-total classification, the atomic fill-plus-provenance mutation script,
and the split provenance/support lookup shapes. Expect:

    [0 %avow 0 %noun %import-tests-pass]

For the real-substrate import battery, run:

    bin/import-test.sh ~/piers/rover-binbel

That script swaps the owner database out, pours a disposable current schema,
imports only synthetic data, proves happy path, a 51-place/2-vehicle
same-import ID stress case, apostrophe escaping, lossless multiline notes,
re-import, conflict, per-record atomicity, provenance boundary, and restart
persistence, then restores the owner database and compares the rendered view
hash. A green run ends with:

    import-test: COVERAGE - all 7 defined import fixtures executed

## PITFALL: `;<` bindings need explicit types

`;<  [pour-mark pour-vase]  bind:m  (take-fact wire)` fails with `find pour-mark`. Bare
names are not a valid binding pattern. Use `[mark =vase]` or annotate:
`[pour-mark=@tas pour-vase=vase]`.
