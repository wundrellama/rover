# PLAN-GATE7.md — Fixture fence

Status: frozen 2026-08-07. Blocks publish per AGENTS.md Gate 7 (ratified 2026-08-06).

Amended 2026-08-07: T2 also fixes the silent-drop bail-out and asserts the 15→16
state migration. Both came out of the M0-CC migration review. See "ALSO IN T2".

Amended 2026-08-11: five seeds are exempt from the re-drive — `seed-fuel-evidence`,
`seed-charging-evidence`, `seed-consumption`, `seed-location`, `seed-pricing`.
The evidence they write has no product entry surface, so those areas leave M0 for
M1 and T2 deletes all five. Six seeds re-drive, not eleven. An earlier amendment
today exempted only `seed-consumption` on an incomplete scoping; this supersedes
it. See "RE-DRIVE THROUGH EYRE".

Open finding, not yet ruled: no endpoint archives or renames a definition, so a
mistyped owner-created definition is permanent. Needs a ruling before publish.

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

**FIVE SEEDS ARE EXEMPT — ruled 2026-08-11.** `seed-fuel-evidence`,
`seed-charging-evidence`, `seed-consumption`, `seed-location`, and
`seed-pricing` cannot be re-driven, because the evidence they write has no
product entry surface. Verified zero writers in both the product `insert-*`
arms and `lib/rover-import.hoon`: `energy-subtype-blend`,
`station-brand-operator`, `station-identifiers`, `acquisition-station-equipment`,
`place-coordinate-accuracy`, `energy-subtype-grade-code`,
`battery-observation-segments`, `charging-efficiency-breaks`,
`consumption-observations`. `seed-pricing` additionally needs a drifted profile
snapshot that no user can enter by design until a profile revision ships.

All five are schema capacity built ahead of the product and become M1 scope. Do
not build endpoints for them in T1. Do not re-drive them. **T2 deletes all five
seeds, their reports, and their fixtures.** The relations stay in the pour —
removing them is a schema change.

That leaves **six** seeds to re-drive: `seed-spike`, `seed-app-structure`,
`seed-charging-cost`, `seed-demo-fuel`, `seed-demo-def`, `seed-fill-edit-support`.

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

*Done on master in `41089c6`. AGENTS.md and the GBrain entry both read 43.*

### ALSO IN T2 — the silent-drop bail-out

Found reviewing the M0-CC v16 state migration, 2026-08-07. Pre-existing, not
introduced by that commit. Folded here because T2 already rewrites these
handlers when the 21 read-back actions move to probes, and fixing it separately
means touching the same code twice.

Every `on-agent` fact handler that answers an HTTP request opens the same way:

```hoon
=/  eyre-id  (~(get by http-pending) wire)
=/  input    (~(get by charge-pending) wire)
?:  ?|(?=(~ eyre-id) ?=(~ input))
  `this
```

When either lookup misses, the handler returns bare `this` — **no HTTP
response, no cleanup**. The browser hangs until Eyre times out and the orphaned
`http-pending` entry leaks for the life of the agent. 24 of the 25 handlers
that read `http-pending` share this shape.

The state migration makes it reachable rather than theoretical. `on-load`
preserves `http-pending` but drops `charge-pending` to `~` (see `%15`, and `%13`
before it for fills). That is the right call — the two new `charge-entry` fields
have no honest value for an in-flight request, and bunting them would fabricate
an empty component list that reads as "user entered no components" instead of
"this request predates components." But it means an upgrade landing between poke
and fact leaves a live `eyre-id` with no input, which is exactly the silent-drop
path.

Fix: the bail-out answers with a 503 and a human reason, and deletes the
orphaned `http-pending` key. Per Ruling 8 the boundary speaks; it does not hang.
A caller who resubmits gets a working request.

Blast radius is small — it needs an upgrade or a lost pending entry inside a
narrow window, and the worst case is one dropped form submission on a
single-user app. It is not a publish blocker on its own. It rides with T2
because the code is already open.

**Also in T2:** add a fixture that asserts the migration itself. The M0-CC
batteries cover the charging-cost feature and restart persistence at v16, but
nothing boots a v15 agent, puts a charge in flight, upgrades, and asserts the
outcome. The 15→16 transition is the only untested edge in that commit.

## Split

The freeze-split rule applies. This plan is wider than one dispatch can finish.
It runs as two tasks.

**T1 — build the replacements. Additive only.** Write the 21 probes. Re-drive
the 11 seeds through Eyre in the batteries. Delete nothing from the action
union. Existing tests stay green without modification. After T1 the union is
still 43 arms, but no battery and no probe pokes the 32 doomed ones.

**T2 — delete the sweep.** Remove the 32 actions, the four calculator wrappers,
`desk/gen/test-*.hoon`, and `desk/tests/`. Fix the silent-drop bail-out and add
the migration fixture. The batteries already run through the new paths, so the
deletion is provable by the batteries staying green. T2 cuts its base from the
merged trunk of T1.

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

**"Fresh" means pill-booted plus the two-poke owner baseline, not literally
empty.** The batteries rename the owner `rover` database aside for fixture
isolation and restore it afterward, so a pier with no `rover` database fails at
`owner-facing rover database is absent` before any fixture runs. Establish the
baseline first with `%init-db` then `%seed-starters` — both KEEP arms, both real
product surfaces, so this does not weaken the fence.

**Boot the pier under tmux, not as a bare process.** Desk setup needs `|merge`,
`|mount`, `|commit`, and `|install` from a dojo. Driving kiln through
`click`/conn.sock works but the argument molds are unforgiving: `%kiln-merge`
takes a bare `[syd ali sud cas gim]` tuple, not a unit, and a wrong shape returns
a `nest-fail` tang whose `%leaf` byte arrays decode to ASCII and name the exact
mold expected. Decode the tang rather than guessing.

**Check the Ames port is free before booting.** A collision kills the pier
*after* it rolls a new epoch, which can corrupt the snapshot and leave a pier
that crashes in `_disk_epoc_load` on every subsequent boot, at any loom size.
That pier is unrecoverable.

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
8. No handler silently drops an HTTP request. Every bail-out that finds a live
   `eyre-id` with a missing input answers 503 with a human reason and clears its
   `http-pending` key. Prove it: put a request in flight, drop its pending
   input, and assert the caller gets 503 rather than a hang.
9. The 15→16 state migration is asserted by a fixture, not by inspection.

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
