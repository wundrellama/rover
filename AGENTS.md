# Rover — agent standing orders

Vehicle-lifecycle tracking as an Urbit Gall app. Canonical relational state lives
in **stock `%obelisk`** (pinned commit); `%rover` owns identity, authorization,
validation, projections, and subscriptions. `%hawk` is the owner/admin root hatch.

This file is the single source of standing orders for Claude Code, Codex, and
OpenCode. `CLAUDE.md` and (if your tool reads it) `OPENCODE.md` point here.

## Read these FIRST, in order

The ratified contract lives in the Brain (separate spec repo), not here. Read in
this order before writing or changing any code:

1. `~/brain/projects/rover/schema-v1.md` — the RATIFIED contract. All five gates
   closed 2026-07-27. **Do not re-open design questions it settles.**
2. `~/brain/projects/rover/integration-plan.md` — the 22 real-substrate fixtures
   and the First Real Integration Spike path.
3. `~/brain/projects/rover/data-model.md` — semantics (odometer representation,
   backfill/temporal rules, exact integer arithmetic, no floating point).
4. `~/brain/projects/rover/architecture-and-access.md` — Rover/Obelisk/Hawk split
   and fail-closed reconciliation.

Then the substrate docs (audit the exact checked-out commit, never "the dev
branch"): master is the working pin on zuse 408. The dev commit `2b72856e`
needs 409+ stdlib and does not compile on the brass-408k pill — see "Substrate
pin" below. Docs: `/tmp/rover-obelisk-master/desk/doc/usr/reference/*` and
`/tmp/rover-obelisk-master/desk/sur/obelisk-ast.hoon`.

## Substrate pin

- **Working pin: Obelisk `master` @ `eecab1b8`** — the highest commit that
  compiles on the brass-408k pill (zuse 408). Verified live on `~bel`.
- The originally-targeted dev pin `2b72856e` imports `strandio` (409+) and
  fails to compile on 408. Do **not** move to 409+ to chase it (user ruling).
- Re-pin to a newer Obelisk only when the dev runtime itself moves past 408.
- Piers run `%base`'s bundled-claim conflict away by starting the agent with an
  explicit desk: `|start %obelisk %obelisk`.

## Non-negotiables

- Eleven v1 relations **exactly** as specified in schema-v1.md. No more, no less.
- IDs: nonzero random 128-bit `@ux`, Rover-generated. Never bunt/zero.
- Write literal `N` for `archived @f` on insert — never `DEFAULT` (the `@f` bunt
  is `%.y` = archived).
- Subtype rows (`fuel-fills`, `charging-sessions`) inherit `acquisition-id` as
  PK+FK. Exactly one subtype per acquisition (Rover's atomic script + reconciliation;
  Obelisk cannot express cross-table XOR).
- All FKs `RESTRICT`. No `CASCADE`, no `SET DEFAULT`.
- Rover **never** issues mutation `AS OF` and **never** issues `UPSERT`.
  Backfills insert at current `recorded-at` with past *observed* bounds.
- **urQL pokes** for all application reads (predicates/joins server-side).
  Scries only for admin/diagnostics — never scry a whole table to filter in Gall.
- Optional data = **absent child/link rows**, never NULL/sentinel (no nullable
  columns in Obelisk).
- Raw machine IDs **never** appear at human/agent/remote boundaries — labels and
  context only.
- Exact integer arithmetic (mills, thousandths). **No floating point.** Total paid
  is *calculated* (quantity × unit price, half-up after multiply), never entered.

## Substrate limits that shape the code (pinned beta)

- Inner joins + predicates execute. **Outer joins, `ORDER BY`, `GROUP BY`, `TOP`
  are parser-only** — Rover does stable sorting and optional-child assembly itself.
- No CHECK constraints → enums, ranges, nonempty labels, subtype XOR are Rover
  invariants + reconciliation.
- Multi-command scripts are atomic; mutations cannot follow a result-returning
  query in one script → validate first, submit one mutation-only script, query after.
- Secondary/unique indexes parsed, not executed → don't claim alternate uniqueness.

## Development rules

- **Disposable fake piers only.** The Rover dev pier is `~/piers/rover-zod`
  (tmux session `rover-zod`). Do **not** touch `~/piers/fakezod` or
  `~/piers/fakenec` — those belong to a different project (erpit) and are live.
- Mocked database evidence **does not count** as a test. Fixtures run against the
  real pinned Obelisk agent on a real fake pier, including restart persistence.
- Git branch is always `master`, never `main`.
- TDD: failing test first, watch it fail, minimal code to pass. See the
  `test-driven-development` skill in `.claude/skills/`.

## Do-NOT-build fence (v1 scope)

Do not build: v2 evidence/arithmetic relations (pricing components, battery,
consumption, coordinates, additives links), v3 sharing (`vehicle-grants*`),
Landscape UI, remote/poke sharing protocol, CSV import, attachments, derived
economy arithmetic beyond current-odometer derivation. v1 is the backbone only.

## When a design question isn't answered by the specs

STOP. Write it to `QUESTIONS.md` (gitignored) and end the run. Do **not** absorb
or silently decide a *design* question — relay it. Ratified decisions come back
through the Brain pages before code changes.

## Skills

Relevant Hermes/Urbit skills are symlinked under `.claude/skills/`. Load
`obelisk-substrate` and `gall-agents` first. If the symlinks dangle (fresh clone
on another machine), fall back to the Brain pages + pinned substrate docs above.
