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
`consumable-report` reads the `Rover Demo Diesel` DEF purchase,
`station-report` reads `Edit Station`, and `charge-subtype-report` reads
the `DC Fast` session at `~2026.07.31..12.00.00` (its vehicle label carries
a run timestamp, so the probe keys on the observed start). Run
`bin/ui-test.sh` with `ROVER_DEMO_ONLY=1` and
`ROVER_NO_FIXTURE_ISOLATION=1` first, or the reports return empty result
sets.

The six `integrity-*` mutation probes carry fixed fixture ids. Each script
ends in a statement the substrate must refuse, the whole script is atomic,
so nothing persists and reruns never collide. The expected result is an
error fact: `[0 %avow 0 %noun 1 ...]`. `integrity-zero-subtype` and
`integrity-two-subtypes` exercise the Rover-side XOR check, so they build
`lib/rover-act.hoon` and call `validate-acquisition-subtypes` directly.

The calculator probes (`pricing-total*`, `charging-total`) also build
the lib and call the arm. They no longer keep a poke alive to test a
function. The `pricing-preview` pair died with the `preview-us` and
`preview-eur` arms in T2. No product path called those two arms after
the poke wrappers went.

`bin/ui-test.sh` creates the `seed-spike`, `seed-app-structure`,
`seed-charging-cost`, `seed-demo-fuel`, `seed-demo-def`, and
`seed-fill-edit-support` state through the product endpoints. T2 deleted
the superseded seed probe files with the seed actions.

Five seeds were exempt from the re-drive per the 2026-08-11 ruling in
`PLAN-GATE7.md`: `seed-fuel-evidence`, `seed-charging-evidence`,
`seed-consumption`, `seed-location`, `seed-pricing`. The evidence they
wrote has no product entry surface, so those areas leave M0 for M1. T2
deleted the five seeds, their five report probes, and their fixtures.

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
ignition mode, so this builds `lib/rover-act` and maps the eight energy
labels through the live `+rating-scale-for` product arm. It read a mirror
in `tests/lib/rover-enums` before T2 deleted that file.

Expect exactly:

    ['Gasoline' ~ %octane] ['Ethanol' ~ %octane] ['Propane' ~ %octane]
    ['Diesel' ~ %cetane]
    ['Electricity' ~] ['Hydrogen' ~] ['CNG' ~] ['LNG' ~]

The four `~` entries are **assertions, not gaps**: Electricity and Hydrogen
have no anti-knock rating at all, and CNG/LNG are rated on **methane number**,
a third scale Rover deliberately does not model. A future edit that
"helpfully" classifies CNG as `%octane` must fail this fixture.

**Falsifiability verified 2026-07-30** against the retired mirror: flipping
Diesel to `` `%octane ``, committing, and re-running showed the change in
the output — the probe reads live built state, not a cached constant. The
probe now reads `+rating-scale-for` in `lib/rover-act.hoon`, so the same
flip there fails it the same way.

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

The in-desk `gen/test-*` generators and `desk/tests/` are gone with T2.
For the real-substrate import battery, run `bin/import-test.sh <pier>`.
A green run ends with:

    import-test: COVERAGE - all 7 defined import fixtures executed

### `event-report.hoon`

M7 T1. Reads the whole vehicle-event family off a live pier: the common header,
the three typed children, the cost evidence with its entered total, and the
odometer, station, tag, payment-method, and note links.

Every link query keys on `event-id`, which is the point of the family: no
association keys to a typed child, so one query shape covers service, expense,
and note alike. Which child row appears in result sets 2, 3, and 4 is the only
record of what kind an event is.

Reads only. It writes nothing and takes no argument, so it reports whatever the
pier holds. `bin/event-test.sh` is the battery; this is for looking.

## PITFALL: `N` and `Y` are literals, not available as relation aliases

`FROM note-events N SELECT N.event-id;` is a **parse error**. `N` is the
boolean false literal that every `archived @f` insert writes, so the parser
reads the alias as that literal. `Y` has the same problem. Found 2026-08-16
while adding the M7 T1 event queries; the clause parsed nowhere, and because a
`%script` is atomic the whole 52-clause `+ui-view` failed with it. The symptom
is a `lib/parse` stack, not a message naming the clause.

Use any other letter. `+ui-view` reads `note-events` as `Z`.

## PITFALL: a three-way join crashes when the leftmost relation is empty

    FROM vehicle-event-stations L
      JOIN stations S ON L.station-id = S.station-id
      JOIN places  P ON S.place-id = P.place-id     <- keys off the SECOND

With zero rows in `vehicle-event-stations` this crashes inside `lib/utils`
rather than returning an empty result set. The same shape over a populated
leftmost relation is fine, which is why the shipped
`energy-acquisition-stations` clause has never shown it — every pier that runs
the view has fills.

Name a populated relation first and join the link last:

    FROM places P
      JOIN stations S ON P.place-id = S.place-id
      JOIN vehicle-event-stations L ON S.station-id = L.station-id

Verified 2026-08-16 on the pinned `9de6332` engine. `energy-acquisition-stations`
and `consumable-acquisition-stations` still carry the fragile order, so a fresh
install with no fill is expected to reproduce it.

## PITFALL: `;<` bindings need explicit types

`;<  [pour-mark pour-vase]  bind:m  (take-fact wire)` fails with `find pour-mark`. Bare
names are not a valid binding pattern. Use `[mark =vase]` or annotate:
`[pour-mark=@tas pour-vase=vase]`.
