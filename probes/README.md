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

## Probe index — import/export work

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

## PITFALL: `;<` bindings need explicit types

`;<  [pour-mark pour-vase]  bind:m  (take-fact wire)` fails with `find pour-mark`. Bare
names are not a valid binding pattern. Use `[mark =vase]` or annotate:
`[pour-mark=@tas pour-vase=vase]`.

