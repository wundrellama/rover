# RESULTS — M7 T8, definition lifecycle (branch `ab-m7t8-opus`)

Date: 2026-08-18. Every result below comes from a run on a real pier against the
pinned Obelisk agent. No result comes from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t8-opus`, branch `ab-m7t8-opus` |
| Pier | `/var/home/michael/piers/rover-m7t8-opus-bel`, ship `~bel`, tmux session `m7t8opus` |
| Ames port | 32410 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` @ `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |
| Rover commit at the baseline run | `28e03a5` |
| Rover commit under test | `29ba321` |

The pier is a fake `~bel`, so it cannot reach `~dister-nomryg-nilref` over Ames.
Obelisk came from the pinned local checkout at `/tmp/obelisk-fresh`. Its
`sur/obelisk-ast.hoon` matches the Rover copy byte for byte. Both desks went in
with `|merge ... our %base`, `|mount`, a file copy, `|commit`, `|install`, and for
Obelisk `|start %obelisk %obelisk`.

## The per-family audit

The brief named nine families and asked for the list to be checked against the
worktree. The check found ten relations that hold both a `label` and an
`archived @f`. Nine are the brief's list. The tenth is
`energy-definition-subtypes`, and it is discussed below.

**Before T8, one family of the nine had any lifecycle endpoint at all.**

| Family | Relation | Create endpoint before T8 | Rename before T8 | Archive before T8 | Restore before T8 | T8 adds |
|---|---|---|---|---|---|---|
| energy | `energy-definitions` | `add-energy-source-type` | no | no | no | rename, archive, restore |
| driving-mode | `driving-mode-definitions` | `add-driving-mode-type` | no | no | no | rename, archive, restore |
| consumable | `consumable-definitions` | starter pack only | no | no | no | rename, archive, restore |
| service-subtype | `service-subtype-definitions` | starter pack only | no | no | no | rename, archive, restore |
| disposal-kind | `disposal-kind-definitions` | starter pack only | no | no | no | rename, archive, restore |
| additive | `additive-definitions` | `import` | no | no | no | rename, archive, restore |
| tag | `tag-definitions` | `import`, and `newTag` on a fill or event | no | no | no | rename, archive, restore |
| payment-method | `payment-method-definitions` | `import` | no | no | no | rename, archive, restore |
| custom-field | `custom-field-definitions` | `add-custom-field` | no | **yes**, `archive-custom-field` | no | rename, restore |

So the gap was wider than "three families without rename and archive". Custom
fields had archive and a content-type change, and **no family had a rename and
no family had a restore.** T8 adds 26 of the 27 controls the table asks for.

`archive-custom-field` and `change-custom-field-type` are unchanged and still
work. `archive-custom-field` is now a second way to do what
`archive-definition` does for the `custom-field` family. It is a published
endpoint, so T8 leaves it in place. The browser controls all call the new
endpoints.

### The tenth relation, and why it is not in scope

`energy-definition-subtypes` holds a `label` and an `archived @f` and is read by
a selector, so it looks like a definition family. It is not owner-editable:
there is no endpoint that creates one, the rows arrive only from the starter
pack or from an import, and the M0 catalog read already filters them with
`WHERE S.archived = N` inside the query rather than in the render.

The brief names nine families and fences off adding a definition family, so T8
builds the nine. Adding a rename and an archive to a family a person cannot
create is the mirror image of the half-fix the 2026-08-12 ruling refused. The
gap is recorded here rather than closed.

## What T8 adds

No relation. No column. No query. Every one of the nine families was poured
with `archived @f`, every selector already read it, and the view already read
every one of these catalogs. The whole task is three endpoints, one settings
panel, and a repair to four selectors on the fill edit form.

### Three endpoints, one handler, nine families

```text
POST /apps/rover/rename-definition    {family, label, newLabel}
POST /apps/rover/archive-definition   {family, label}
POST /apps/rover/restore-definition   {family, label}
```

The route selects the operation and the body names the family. This is the
split the five event routes use: a client cannot ask for an operation the
endpoint it called does not perform.

`definition-families` in `desk/lib/rover-act.hoon` is the one list that maps a
family term to its relation and its key column. A tenth family costs one entry
there and one line in the settings render.

The write is two phases, like every other label-addressed write in Rover. Phase
one finds the definition by label, and for a rename also finds whatever else
already carries the new label. Phase two writes one `UPDATE`.

### Refusals

| Condition | Code | Body |
|---|---|---|
| family term Rover does not manage | 400 | `%unknown-family: definition.family` |
| no `family` key | 400 | `%missing-key: definition.family` |
| no `newLabel` on a rename | 400 | `%missing-key: definition.new-label` |
| empty `newLabel` on a rename | 400 | `%bad-shape: definition.new-label` |
| no definition with that label in that family | 404 | `%not-found: definition` |
| the new label is already used in the same family | 409 | `%duplicate-label: definition` |
| Obelisk refuses the script | 422 | `%database-refused: definition` |

## Design latitude used

The specs fix archive-not-delete, rename-does-not-police-intent, reachability,
and no-schema-change. They leave the rest open. Each choice below is mine.

1. **Three routes, not twenty-seven.** One route per operation, with the family
   in the body, rather than one route per family per operation. The route still
   carries the operation, so the guarantee the event routes give is kept, and
   nine families cost one handler instead of nine.
2. **Rename, archive and restore share one handler and one lookup.** All three
   address a definition the same way — family, then label — and all three write
   one `UPDATE`. A second decoder could drift from the first.
3. **Restore is a route of its own, not `archive` with a flag.** A request that
   carries the intended state can be sent with the wrong state by a stale page.
   A request that carries no state cannot.
4. **A rename may not collide inside its own family, and the refusal is 409.**
   The label is the only handle Rover has on a definition at every boundary,
   because a raw machine ID never crosses one. Two rows of one family under one
   label make both unreachable, including the row just renamed. The rule is
   enforced in the write path, because the substrate parses alternate
   uniqueness and does not execute it.
5. **A collision with an archived row is still a collision.** An archived
   definition is still addressed by its label, and a restore later has to find
   it.
6. **The rule is per family and nothing else.** `Car Wash`, `Insurance` and
   `Registration` exist in more than one family in the T2 catalog on purpose.
   Fixture 74 renames a tag to `Car Wash` while the service subtype `Car Wash`
   exists, and asserts both rows afterwards.
7. **Rover does not judge a rename.** No heuristic, no warning, no block. The
   settings panel says what rename does — "corrects a label everywhere it
   renders, including on records already saved" — and stops there. A person who
   reads that and repurposes a definition has been told the truth.
8. **Archived definitions are visible in exactly one place:** the new
   Definitions panel in Settings. They are gone from every selector, so without
   one list that keeps showing them there is no way back. Every other surface
   hides them.
9. **An archived definition offers Rename and Restore. An active one offers
   Rename and Archive.** A mistyped label is worth correcting whether or not
   the definition is still offered anywhere.
10. **The archive control asks for confirmation and the confirmation says what
    archive does.** "It leaves every selector. Records that already name it keep
    it, and you can restore it later." Restore asks nothing, because it is the
    undo.
11. **Custom fields keep their own settings panel** and gain Rename and Restore
    there. They carry a content type and a mandatory flag no other family has,
    so folding them into the generic panel would have dropped controls or made
    the generic panel carry a special case.
12. **The fill edit form keeps an archived definition that the record already
    names, and drops every other archived one.** This is a rendering rule the
    specs do not fix. The alternative — hiding it — makes a save of an
    unrelated edit delete an association nobody touched.
13. **Stations are left alone.** `stations` also carries a `label` and an
    `archived`, and the fill edit form still offers an archived station. A
    station is not a definition family in the nine, so this is recorded, not
    fixed.
14. **`seed-starters` was not changed.** The shipped seeding reads each family
    first and seeds only a family that is completely empty, so an archived
    starter is never rewritten and never duplicated. Fixture 72 runs the seeding
    twice against three archived starters and proves it.

## What the fixtures prove

Twelve new fixtures, 66 through 77. The battery is 77 fixtures.

- **66** All nine families rename. The new label is on the same row, the old
  label is gone from the relation, and the row count stays at one.
- **67** All nine families archive. The flag moves and no row leaves any
  relation.
- **68** The archived definition of each of the nine families is gone from the
  selector its entry screen offers, read from the served document. Energy
  sources and driving modes are also gone from the membership grids of the
  vehicle settings form.
- **69** Every historical record still names what it named. The fill card keeps
  its energy source and its additive. The fill edit form keeps its tag, its
  payment method, its driving mode and its additive, all still selected. The
  service card keeps its subtype and the disposal card keeps its kind. The DEF
  purchase still joins to its archived definition and the custom field value
  still joins to its archived field. An archived tag the record does NOT name is
  gone from that same form, so the rule is what the record says, not show
  everything.
- **70** Every archived definition restores and returns to the selectors it
  left.
- **71** A rename reaches the records. Three labels are corrected — a tag, a
  service subtype and an energy source. The old text appears nowhere in the
  served document, and the corrected text appears on the record and in the
  selector. None of the three corrected labels contains the label it replaces,
  so a stale copy cannot pass by being a prefix.
- **72** Two runs of `seed-starters` leave three archived starter definitions
  archived, and write no second row.
- **73** A tag no record references archives, leaves the selector, and restores.
  Both halves of "no record references it" are proved on the link relations
  first.
- **74** A rename onto a label the same family already holds is refused, and the
  refused request writes nothing. A rename onto an archived label is refused
  too. A rename onto a label another FAMILY holds succeeds, and the T2 catalog
  row is undisturbed.
- **75** Five refusals, and nothing is written by any of them.
- **76** Every rename, archive flag and restore survives a real ship restart,
  and archive and restore still work after it.
- **77** A person renames, archives and restores a definition in a real browser
  through the Settings screen, answers the prompt and the confirmation, and sees
  the archived definition leave the Add Fill tag list and come back. The three
  writes are then read out of the database, not off the screen.

## The two final runs

Both runs used the pier and the desk above, back to back, with no change
between them. The agent was nuked and started fresh before run 1, which is the
`gall: booted %rover` recorded under the done-check below.

Run 1, verbatim final three lines:

```text
event-test: fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description
event-test: fixture 77 PASS - a person renames, archives and restores a definition in the browser, and the archived one leaves the Add Fill tag list and comes back
event-test: COVERAGE - all 77 defined fixtures executed
```

Run 2, verbatim final three lines:

```text
event-test: fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description
event-test: fixture 77 PASS - a person renames, archives and restores a definition in the browser, and the archived one leaves the Add Fill tag list and comes back
event-test: COVERAGE - all 77 defined fixtures executed
```

Both runs exited 0 and reported zero `FAIL` lines.

The twelve T8 fixtures, verbatim from run 2:

```text
event-test: fixture 66 PASS - all nine definition families rename in place, one row keeps one identity, and the old label leaves the relation
event-test: fixture 67 PASS - all nine families archive by flipping a flag, and no row leaves any relation
event-test: fixture 68 PASS - an archived definition in each of the nine families is gone from every selector that offered it
event-test: fixture 69 PASS - every historical record still renders the definition it names after that definition is archived
event-test: fixture 70 PASS - every archived definition restores, and each one returns to the selectors it left
event-test: fixture 71 PASS - a rename reaches every record that names the definition, the old label renders nowhere, and the corrected one is offered again
event-test: fixture 72 PASS - two runs of seed-starters leave an archived starter definition archived, and add no second row
event-test: fixture 73 PASS - a definition no record references archives and restores, and no usage count is consulted
event-test: fixture 74 PASS - a label collides only inside its own family, an archived row still holds its label, and the shared T2 catalog labels are undisturbed
event-test: fixture 75 PASS - an unknown family, an absent definition, and a missing or empty new label are each refused, and none of them writes
event-test: fixture 76 PASS - every rename, archive flag and restore survived a ship restart, and archive and restore still work after it
event-test: fixture 77 PASS - a person renames, archives and restores a definition in the browser, and the archived one leaves the Add Fill tag list and comes back
```

## The install

```text
gall: nuking %rover
gall: unnuking %rover
eyre: replacing existing binding at /apps/rover
> |start %rover %rover
>=
gall: booted %rover
```

A search of the pier log for `nest-fail` returns nothing.

## One red baseline, before any T8 code

The unchanged battery was run on this pier before any T8 change. **It failed at
fixture 58**, the T7 compatibility guard:

```text
event-test: FAIL - fixture 58 a vehicle with no specification data no longer renders as it did before T7: DIFFERS at 950
pre-T7 : ...pe<select name="defaultSubtype"><option value="">Not set</option><option value="88">88</option><option value="87">87</option><option value="85">85</option><option value="92">92</option><option value="
served : ...pe<select name="defaultSubtype"><option value="">Not set</option><option value="95">95</option><option value="93">93</option><option value="100">100</option><option value="98">98</option><option value
```

The same eleven options in a different order. Fixture 58 compares a served
vehicle card, character for character, against `bin/spec-free-vehicle-card.html`
— a capture made on the T7 pier. The default-subtype selector reads the
`energy-definition-subtypes` catalog, the engine returns a set, and the order
that set comes back in follows the random 128-bit subtype IDs the seeding
assigned. Those IDs differ on every pier, so the fixture could only ever pass on
the pier its capture was made on.

The fix sorts the options of that one selector on both sides of the comparison,
alongside the two normalizations the fixture already applied for the same class
of reason. The guard still checks WHICH options are offered. It no longer checks
an order no code decides. Every other character of the card is still compared
exactly.

After the fix the unchanged battery ran green: `COVERAGE - all 65 defined
fixtures executed`, zero failures. That is the baseline the T8 work started from.

## The done-check

| # | Check | Verdict |
|---|---|---|
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | PASS, output above |
| 2 | Every owner-editable definition family has both rename and archive | PASS, nine families, fixtures 66 and 67 |
| 3 | An archived definition disappears from every selector that offered it | PASS, fixture 68 |
| 4 | An archived definition still renders on every historical record referencing it | PASS, fixture 69 |
| 5 | Archiving is reversible, and a restored definition returns to its selectors | PASS, fixture 70 |
| 6 | A rename reaches historical records: the old label is gone, the new one is present | PASS, fixture 71 |
| 7 | `seed-starters` does not resurrect an archived starter definition | PASS, fixture 72 |
| 8 | Every rename and archive control is reachable in a real browser session | PASS, fixture 77 |
| 9 | A definition that no record references can still be archived and restored | PASS, fixture 73 |
| 10 | Everything above survives a ship restart | PASS, fixture 76 |
| 11 | The shipping action union still has five arms | PASS, fixture 13 |
| 12 | The full battery runs twice back to back with the same verdict, and the coverage line reports every defined fixture executed with no skips | PASS, both runs `all 77 defined fixtures executed`, exit 0, zero FAIL |

## Constraints

- **No schema change.** `git diff` touches no `CREATE TABLE` and no `ALTER`. The
  brief expected none and none was needed.
- **Every association keys to the family parent.** T8 writes no association.
- **`INSERT`, never `UPSERT`.** T8 writes only `UPDATE`.
- **No mutation `AS OF`.** T8 issues none.
- **The `$action` union stays at five arms.** Fixture 13 asserts it. T8 added no
  arm and no probe under `probes/`.
- **No outer join, `ORDER BY`, `GROUP BY` or `TOP`.** The two lookup commands
  are single-relation reads with an equality predicate.
- **No single-column projection is counted.** `t8_row_count` projects the key
  column, which is unique, so no row can collapse into another.

## What was NOT built

- Import widening and export. T9 and T10 own them.
- A tenth definition family, a field on a definition, merge-two-definitions,
  bulk edit, and usage counts.
- A lifecycle for `energy-definition-subtypes`, `stations` or `places`.
- Any change to the T1 event shape, the T2 catalog, the T3 odometer relation,
  the T4 ownership relations, the T5 derivation, the T6 reminders, or the T7
  specification relations.

## What a reader should check next

`bin/event-test.sh` restores every starter definition it touches, but a run that
stops inside fixtures 66 to 77 leaves one archived or renamed. The next run then
fails at fixture 26 or at the T8 setup, which is how the leftover was found
during development each time. A run that finishes leaves the database as it
found it. This is the same class of coupling every other stateful fixture in the
battery has, and it is recorded rather than fixed.
