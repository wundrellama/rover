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
branch"): `/tmp/rover-obelisk-2b72856e/desk/doc/usr/reference/*` and
`/tmp/rover-obelisk-2b72856e/desk/sur/obelisk-ast.hoon`.

## Substrate pin

- **Working pin: Obelisk `dev` @ `2b72856e`** — verified to compile and run on
  the brass-408k pill (zuse 408). The matching copied
  `sur/obelisk-ast.hoon` SHA-256 is
  `c74bf1c911b61b7abb4de8c98b28b30d684e5e3c0b10a0c65f759f64ee9f93dd`.
- The 2026-07-28 downgrade to `master` @ `eecab1b8` was based on a false
  diagnosis. `strandio` is present on brass-408k; the actual `gall: failed`
  came from an empty directory under `app/`.
- Piers run `%base`'s bundled-claim conflict away by starting the agent with an
  explicit desk: `|start %obelisk %obelisk`.
- Before every desk commit, remove empty directories:
  `find <pier>/<desk> -type d -empty -delete`. In particular, a stale empty
  `app/debug/` makes Gall try to compile `/app//hoon`.

## Obelisk stays standalone

`%obelisk` is installed as its **own unmodified desk** alongside `%rover`; it is never
embedded, forked, or renamed. Rover reaches it only through Gall cards
(`%pass ... %agent [our %obelisk] %watch /server` + `%poke %obelisk-action`).

The **only** file Rover copies from Obelisk is `sur/obelisk-ast.hoon` — the developer
API mold, exactly as the upstream developer docs prescribe. Rover must **not** vendor
engine libraries (`main`, `parse`, `ddl`, `crud`, `predicate`, `scalars`, `selections`,
`sys-views`, `migration`); those belong to the `%obelisk` desk. Vendoring one would
fork the database engine and silently break the pin.

## Non-negotiables

- **Schema scope (Gate 6, ratified 2026-07-28):** M0 is a **single schema pour** —
  the vehicle/observation/energy/place/station backbone **plus** the evidence,
  arithmetic, and provenance relations. Sharing (`vehicle-grants`,
  `vehicle-grant-fields`) is a **separate second pour** and is the populated-data
  migration rehearsal. The earlier eleven-relation v1 / v2 / v3 progression is
  superseded — do not treat "eleven relations exactly" as current.
- Because the M0 pour is fresh (pre-publish), relations take their **honest shape**:
  mandatory fill facts — price per unit, currency, settlement mode — are **columns on
  `fuel-fills`**, not a child table. The child/link shape was only ever a way to dodge
  a migration constraint that does not apply to a fresh pour.
- **Optional** data still uses **absent child/link rows**, never NULL/sentinel
  (Obelisk has no nullable columns). Mileage on a fill is optional → stays a link row.
  Mandatory data uses columns. Do not confuse the two.
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

## Do-NOT-build fence (M0 scope)

Do not build: sharing (`vehicle-grants`, `vehicle-grant-fields` — that is the second
pour), Landscape UI, remote/poke sharing protocol, CSV import, attachments, permanent
EVSE/connector inventory, or maintenance/service/insurance/modification records (M7).

Everything else in the adopted M0 relation family — including fill pricing, fill↔odometer
links, economy breaks, additives, charging measurements, battery and consumption
observations, charging cost components, address/coordinate evidence, and station
identifiers — is **in scope for the single M0 pour** per Gate 6.

## When a design question isn't answered by the specs

STOP. Write it to `QUESTIONS.md` (gitignored) and end the run. Do **not** absorb
or silently decide a *design* question — relay it. Ratified decisions come back
through the Brain pages before code changes.

## Skills

Relevant Hermes/Urbit skills are symlinked under `.claude/skills/`. Load
`obelisk-substrate` and `gall-agents` first. If the symlinks dangle (fresh clone
on another machine), fall back to the Brain pages + pinned substrate docs above.
