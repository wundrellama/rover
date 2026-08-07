# PLAN-GATE7.md — Fixture fence

Status: frozen 2026-08-07. Blocks publish per AGENTS.md Gate 7 (ratified 2026-08-06).

## Why

`sur/rover.hoon` ships a 43-arm `$action` union. None of it is reachable over
HTTP — the UI's entire surface is 17 Eyre endpoints. The union is a poke-only
test harness that a published desk must not carry.

The boundary already exists and does not need inventing: `probes/` sits at repo
root, outside `desk/`, run from the host via `click -k -i`. Seven probes
(`address-q9`, `cetane-pour`, `import-provenance`, `live-database-list`,
`live-demo-fill-rows`, `live-owner-vehicles`, `profile-view-query`) already poke
`%obelisk` directly with inline urQL and never touch `%rover-action`. That is the
target pattern.

**One desk, not two.** A dev/published split would mean the artifact under test is
not the artifact shipped, and every fixture PASS would carry an asterisk. The
fence removes code; it does not gate it.

## Triage

### KEEP — 7

`init-db` · `ensure-ui-schema` · `ensure-def-schema` · `verify-schema` ·
`seed-starters` · `rename-energy-source` · `rename-consumable`

The four ratified schema/admin surfaces plus the market-aware starter pack.

The two renames are **conditional**: they are real user actions with no Eyre
endpoint, so today they ship unreachable. Either add endpoints in this task or
drop them. Do not ship a user action a user cannot invoke. Decide explicitly.

### DROP THE POKE, KEEP THE ARM — 4

`derive-fill-total` · `preview-us` · `preview-eur` · `derive-charging-total`

These are calculators. The action wrappers are test-only exposure of internal
functions and must go; the arms in `lib/rover-act.hoon` stay.

- `derive-fill-total:act` is genuine product — called from `rover-view.hoon`
  (3×) and `rover-import.hoon` (1×). Arm untouched, wrapper deleted.
- `preview-us:act`, `preview-eur:act`, `derive-charging-total:act` are called
  **only** from `app/rover.hoon`, i.e. only from the poke handler itself. If no
  product path calls them after the wrappers go, they are dead — confirm and
  delete arm and all.

Their probe consumers (`pricing-preview.hoon`, `charging-total.hoon`) assert pure
arithmetic. Rewrite as `+$` unit tests or arm-level probes; do not keep a poke
alive to test a function.

### MOVE TO PROBE — 21

Readbacks (16): `app-structure-report` · `display-preference-report` ·
`charging-cost-report` · `charging-evidence-report` · `consumption-report` ·
`fuel-evidence-report` · `location-report` · `pricing-report` ·
`fill-edit-report` · `station-report` · `consumable-report` ·
`charge-subtype-report` · `vehicle-settings-report` · `demo-starter-report` ·
`starter-report` · `consumable-starter-report`

Diagnostics (5): `run-integrity` (8 consumers, heaviest) ·
`try-second-app-default` (negative assertion) · `content-report` (20+ FROM/SELECT
across every table, no WHERE — a full DB dump) · `vehicle-history` ·
`current-odometer`

`vehicle-history` and `current-odometer` are unambiguous despite product-sounding
names: both hardcode `WHERE V.label = 'Phase A Vehicle'`. They can only query a
fixture.

urQL bodies move out of `lib/rover-act.hoon` into `probes/*.hoon`.

### RE-DRIVE THROUGH EYRE — 11

`seed-fuel-evidence` · `seed-charging-evidence` · `seed-charging-cost` ·
`seed-consumption` · `seed-location` · `seed-pricing` · `seed-app-structure` ·
`seed-fill-edit-support` · `seed-demo-fuel` · `seed-demo-def` · `seed-spike`

These create state by privileged poke. They must create it the way a user does,
via the 17 endpoints: `add-fill` · `add-charge` · `add-odometer` · `add-vehicle` ·
`edit-fill` · `edit-vehicle` · `remove-vehicle` · `add-consumable` ·
`add-custom-field` · `archive-custom-field` · `change-custom-field-type` ·
`add-energy-source-type` · `add-driving-mode-type` · `set-default-vehicle` ·
`set-preference` · `import` · `view`

`bin/ui-test.sh` already makes 150 curl calls against these endpoints, so the
harness exists — this is extension, not new machinery.

`seed-spike` is a spike artifact; expected outcome is deletion.

**If a seed cannot be expressed through an endpoint, that is a finding, not a
workaround.** Stop and report the gap. Do not reintroduce a poke.

### ALSO IN SCOPE

The ratified fence text names the action union only. These also sit inside
`desk/` and are scaffolding:

- `desk/gen/test-entry.hoon`, `test-import.hoon`, `test-pricing.hoon`,
  `test-render.hoon` (246 lines total)
- `desk/tests/lib/rover-enums.hoon` — referenced by neither `desk.bill` nor
  `app/rover.hoon`

Move to host-side or delete. Nothing named `test-*` ships.

### CORRECTION

AGENTS.md says 42 actions. The union holds 43. Fix the ratified text.

## Split

The freeze-split rule applies. This plan is wider than one dispatch can finish.
It runs as two tasks.

**T1 — build the replacements. Additive only.** Write the 21 probes. Re-drive
the 11 seeds through Eyre in the batteries. Delete nothing from the action
union. Existing tests stay green without modification. After T1 the union is
still 43 arms, but no battery and no probe pokes the 32 doomed ones.

**T2 — delete the sweep.** Remove the 32 actions, the four calculator wrappers,
`desk/gen/test-*.hoon`, and `desk/tests/`. The batteries already run through the
new paths, so the deletion is provable by the batteries staying green. T2 cuts
its base from the merged trunk of T1.

The firewall keeps the T1 diff purely additive, which keeps the divergence
analysis clean.

## Result

`sur/rover.hoon`: 43 actions → 7 (or 5 if the renames are dropped).
`lib/rover-act.hoon`: sheds most of 3,237 lines.
`desk/gen/`, `desk/tests/`: empty or gone.

## Verify contract

One fresh disposable pier. Not `rover-v09-bel` — its state was seeded through
the back doors this task removes, so it cannot prove the fence.

Not `~/piers/fakezod` or `~/piers/fakenec` (erpit, live).

1. Boot fresh fake pier, install pinned Obelisk v0.9.0-beta
   (`9de633299b373a1047490b48281a40b457fb2043`).
2. Install the shipped `%rover` desk. No dev variant exists.
3. `on-init` binds Eyre; nothing auto-seeds.
4. `seed-starters` and the schema surfaces work on first run.
5. Full battery: `bin/ui-test.sh`, `bin/schema-test.sh`, `bin/import-test.sh`,
   `bin/view-performance-test.sh`, `bin/dev-pin-test.sh` — all fixtures PASS with
   every seed driven through Eyre.
6. Restart persistence holds.
7. `grep -c` on the shipped desk: zero fixture actions, zero `test-*` files.

Mocked evidence does not count. Fixtures run against real Obelisk on a real fake
pier.

## Fences

- Do not remove product seeding: `seed-starters`, `seed-energy-starters`,
  `seed-consumables`, `seed-additives`, `seed-driving-modes`.
- Do not add actions to the shipping union.
- Do not create a dev desk, build flag, or conditional include.
- Design questions go to `QUESTIONS.md` and end the run. Do not absorb them.
- Branch is `master`.
- TDD: failing test first.
- Read `.claude/skills/ste-writing/SKILL.md` before you write a commit message
  or any other prose. The file is a real copy and survives a fresh clone.
