# M7 T1 results — sol

## Environment

- Branch: `ab-m7t1-sol`
- Implementation commit: `0263af1`
- Pier: `/home/michael/piers/rover-m7t1-sol-bel`
- Ship: `~bel`
- tmux session: `m7t1sol`
- Ames port: `31641`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk: `9de633299b373a1047490b48281a40b457fb2043`
- Obelisk AST SHA-256: `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`

I inspected `pgrep -a -x urbit` before boot and selected unused port 31641.
The pier was created from the pinned pill and was the only pier used for this
work. Obelisk ran as the unmodified `%obelisk` desk and was started with
`|start %obelisk %obelisk`.

## TDD evidence

The first event battery ran before the endpoints existed and failed at the
service endpoint:

```text
m7t1-test: FAIL - service event:
405
```

After the write path compiled, the battery reached the read path and exposed a
503 from the combined view query. An isolated real-Obelisk query showed that
`N`, the loobean literal, could not be used as the notes relation alias. The
alias was changed to `H`, and all nine event view queries then executed.

The passing test was sabotaged by setting the expected event count to four.
The fyrd still returned the actual count of three, and the battery failed:

```text
[0 %avow 0 %noun %m7t1-pass 3 4 1 1 1 2 0 0 1 1 1]
m7t1-test: FAIL - the final typed verdict is not a pass: [0 %avow 0 %noun %m7t1-pass 3 4 1 1 1 2 0 0 1 1 1]
```

Restoring the expected count made the same battery pass.

## Schema evidence

`ensure-def-schema` created the 11 new relations on the live Rover database.
The final isolated schema battery returned:

```text
schema-test: PASS - SQL/Hoon parity is 79/79 relations; DDL has 90 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 79 relations; all 90 FK constraints (93 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

The substrate pin battery returned:

```text
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match
```

Clay compiled the changed desk and Gall reloaded `%rover` without changing the
persisted state version:

```text
gall: reloading %rover
eyre: replacing existing binding at /apps/rover
gall: bumped %rover
```

The shipping action union still has exactly five arms: `init-db`,
`ensure-ui-schema`, `ensure-def-schema`, `verify-schema`, and `seed-starters`.

## Real fixture evidence

`bin/m7t1-test.sh /home/michael/piers/rover-m7t1-sol-bel` drove the real Eyre
endpoints and the pinned Obelisk agent. It asserted the rendered notes and the
entered totals `$123.450` and `$12.500`. It also asserted that a zero entered
total and an empty note were refused without writes.

The final fyrd verdict was:

```text
[0 %avow 0 %noun %m7t1-pass 3 4 1 1 1 2 0 0 1 1 1]
m7t1-test: PASS - typed fixture counts match
```

The tuple records, in order:

1. Three vehicle events.
2. Four vehicle odometer observations: one fuel fill and three events.
3. One service child.
4. One expense child.
5. One note child.
6. Two entered-cost rows.
7. No station row for the expense.
8. No cost row for the note.
9. One matching place definition.
10. One matching station definition.
11. One direct station-ID match between the fuel fill and service event.

These counts prove that absent optional values did not create sentinel rows and
that the service event reused the fill's existing place and station.

## Restart persistence

I stopped the exact `m7t1sol` session with `|exit`, confirmed that its process
was gone, and restarted only this pier with:

```text
/home/michael/workspace/urbit/bin/urbit -p 31641 /home/michael/piers/rover-m7t1-sol-bel
```

The restarted ship reported `mesa: live on 31641 (localhost only)` and returned
to the `~bel:dojo>` prompt. The event battery then ran twice without inserting
new fixture rows. Both runs returned the same typed pass verdict shown above.

## Design latitude used

- The three endpoints are `/apps/rover/add-service-event`,
  `/apps/rover/add-expense-event`, and `/apps/rover/add-note-event`. Separate
  names keep HTTP refusal context and typed-child selection explicit.
- All endpoints decode one common JSON entry shape and inject the event kind
  from the route. This prevents a client-supplied kind from disagreeing with
  the selected typed child.
- The existing `fill-body-pending` text map carries an event body across the
  lookup and write facts. Reusing that general text storage preserved state
  version 17 and avoided a needless Gall migration.
- Service, expense, and note rows are merged in Gall, tagged from their typed
  query, sorted newest-first by `observed-start`, and shown in a separate
  25-row vehicle-event history after energy history. This preserves the typed
  child as the source of kind and avoids unsupported database ordering.
- Mileage remains optional at entry. A missing link renders as incomplete,
  matching the common-header ruling without inventing a sentinel reading.
- A note event requires nonempty note text. An identity-only note child with no
  note association would not record the event the endpoint names.
- Station, tag, and payment lookups use active human labels. This keeps machine
  IDs internal and reuses the owner's existing definitions.

## Questions and final status

No design question was filed in `QUESTIONS.md`.

After committing this results file, `git status --short` produced no output and
`git status --short --branch` reported:

```text
## ab-m7t1-sol
```

Nothing was pushed, merged, or committed to `master`.
