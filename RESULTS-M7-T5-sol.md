# M7 T5 — Ownership intervals bound every derivation — sol

Date: 2026-08-17

## Result

T5 is complete on `ab-m7t5-sol`. Fuel, DEF, and odometer-linked charging
intervals now consult acquisition and disposal events. An interval that crosses
an ownership boundary is unavailable with `%ownership-gap`; it contributes no
fuel economy value to last, mean, best, worst, or distance-per-tank.

No relation, column, migration, or shipping action was added. The ownership
break exists only in Rover's read-side derivation.

## Test environment

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t5-sol` |
| Branch | `ab-m7t5-sol` |
| Code commit | `e6808c89412eae38979bee67e13c28daf8262156` |
| Pier | `/var/home/michael/piers/rover-m7t5-sol-bel` |
| Ship | `~bel` |
| tmux session | `m7t5sol` |
| Ames port | `32160` |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `9de633299b373a1047490b48281a40b457fb2043` (`v0.9.0-beta`) |
| Obelisk AST SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |

The fake `~bel` did not complete `|install ~dister-nomryg-nilref %obelisk`.
The desk came from the pinned `/tmp/obelisk-fresh` checkout after the incomplete
bootstrap was discarded and the same specified pier path was rebuilt. Obelisk
started with `|start %obelisk %obelisk`.

The initial Rover desk installation printed:

```text
gall: installing %rover
> |install our %rover
>=
gall: booted %rover
```

The final desk commit recompiled `lib/rover-view.hoon`, reloaded `%rover`, and
printed `gall: bumped %rover`. No install, reload, battery, or restart transcript
contained `nest-fail`.

## Red before green

Fixture 36 ran first on the unmodified derivation. It proved the published
no-ownership-event behavior before the T5 change. Fixture 37 then built a
buy-sell-rebuy record with a 400.000 mpg cross-gap interval. The run ended with:

```text
event-test: fixture 33 PASS - the route decides the kind for acquisition and disposal, and the body cannot override it
event-test: fixture 36 PASS - a vehicle with no ownership events still derives last 30.000 mpg, best 30.000 mpg, and mean 25.000 mpg
event-test: FAIL - fixture 37 cross-gap 400.000 mpg became BEST ECONOMY: 400.000 mpg
```

After the fix, fixture 37 reported best 30.000 mpg and mean 25.000 mpg from the
two within-ownership intervals. The 400.000 mpg interval rendered `Unavailable`
with `%ownership-gap` and this sentence:

```text
The vehicle was not owned for part of this interval, so the derived value is unavailable.
```

An intermediate repeat exposed a battery defect:

```text
event-test: FAIL - fixture 40 rendered 2 charging ownership breaks, want exactly the one cross-gap interval
```

The assertion had counted the persisted marker from the preceding stamped run.
The fixture now slices this run's vehicle card before counting. The two final
runs below began after that correction.

## Done-check

| # | Check | Evidence |
|---|---|---|
| 1 | Desk boots without `nest-fail` | Initial install printed `gall: booted %rover`; the final desk reloaded and served all fixtures. |
| 2 | Cross-gap interval is not best | Fixture 37: 400.000 mpg unavailable; best 30.000 mpg. |
| 3 | Cross-gap interval is absent from mean | Fixture 37: mean 25.000 mpg, the half-up mean of 20.000 and 30.000. |
| 4 | Cross-gap rendering is human and nonzero | Fixture 37 checks `Unavailable`, `%ownership-gap`, and the human sentence above. |
| 5 | Within-ownership fuel intervals still derive | Fixture 37 checks 20.000 mpg before the gap and 30.000 mpg after it. |
| 6 | No-event compatibility is exact | Fixture 36 checks last 30.000, best 30.000, mean 25.000 before and after T5; fixture 41 repeats it after restart. |
| 7 | One open purchase derives to now | Fixture 38 derives 20.000 mpg after one acquisition and no disposal; fixture 41 repeats it after restart. |
| 8 | Charging and consumable economy honor gaps | Fixture 39 makes cross-gap DEF unavailable, then derives 100.000 mi/gal DEF inside ownership. Fixture 40 marks exactly one cross-gap charge interval unavailable. |
| 9 | Results survive restart | Fixtures 12 and 41 pass in both final battery runs. |
| 10 | Shipping action union stays at five arms | Fixture 13 passes in both final runs. |
| 11 | Full battery is repeatable with coverage | Both final runs report all 41 fixtures executed. |

## Final battery runs

The two runs were back to back against the same real pier. These are the
verbatim final lines of run 1:

```text
event-test: fixture 34 PASS - both purchases, the sale and its kind, the trade-in pair, the odometer links, and the disposal-kind pack survived a ship restart
event-test: fixture 41 PASS - fuel, charging, DEF, open ownership, and no-event compatibility keep the same verdict after restart
event-test: fixture 13 PASS - the shipping action union still has five arms
event-test: fixture 15 PASS - the route decides the kind, and the body cannot override it
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: COVERAGE - all 41 defined fixtures executed
```

These are the verbatim final lines of run 2:

```text
event-test: fixture 34 PASS - both purchases, the sale and its kind, the trade-in pair, the odometer links, and the disposal-kind pack survived a ship restart
event-test: fixture 41 PASS - fuel, charging, DEF, open ownership, and no-event compatibility keep the same verdict after restart
event-test: fixture 13 PASS - the shipping action union still has five arms
event-test: fixture 15 PASS - the route decides the kind, and the body cannot override it
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: COVERAGE - all 41 defined fixtures executed
```

## Design latitude used

- **Derived representation:** `%ownership-gap` uses the existing in-memory
  `@tas` break-reason path. Rover writes no `economy-breaks` row because that
  relation records owner-supplied fuel-fill facts.
- **Legacy initial state:** no ownership events means an unbounded interval,
  preserving every published database. If acquisitions exist, ownership begins
  closed and a purchase opens it. A disposal-only history is owned until its
  disposal, which preserves a legacy vehicle's earlier interval.
- **Boundary inclusion:** Rover evaluates ownership at the interval's first
  endpoint and treats every ownership event in `(after, through]` as a break. A
  purchase exactly at the first endpoint therefore opens the interval without
  breaking it.
- **Reason precedence:** a derived ownership gap takes precedence over an
  owner-supplied break in the same interval because the observable ownership
  boundary must never be hidden.
- **Charging rendering:** Rover adds an unavailable charging-efficiency line to
  the later charge card only when two odometer-linked charges cross ownership.
  It does not invent an available efficiency figure; the complete charging
  efficiency calculation remains outside the shipped surface.
