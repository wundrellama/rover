# M7 T2 results — sol

## Environment

- Branch: `ab-m7t2-sol`
- Pier: `/var/home/michael/piers/rover-m7t2-sol-bel`
- Ship: `~bel`
- tmux session: `m7t2sol`
- Ames port: `31820`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk commit: `9de633299b373a1047490b48281a40b457fb2043`
- Copied `sur/obelisk-ast.hoon` SHA-256: `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`

The distributor command `|install ~dister-nomryg-nilref %obelisk` claimed the
desk but remained at `beginning install`. I replaced that incomplete desk with
the clean pinned checkout, verified the hash above, committed it, and ran
`|start %obelisk %obelisk`. The pier then reported `gall: booted %obelisk` and
`gall: booted %obelisk-web`.

The Rover desk compiled without `nest-fail` and reported `gall: booted %rover`.
The superseded disposable pier snapshots were moved to the recoverable Trash
location. The named pier above is the only M7 T2 sol pier that remains active.

## TDD evidence

The first real-pier run preceded production changes. Fixture 16 failed because
Obelisk reported that `rover.dbo.service-subtype-definitions` did not exist.
That was the expected red result.

After implementation, I rebuilt the same pier path from the pinned pill. The
first battery query ran before any Rover page request and produced this line:

```text
event-test: fixture 16 PASS - the fresh database has 62 unique service subtype starters before a Rover page load
```

The static schema audit reported:

```text
tables: 81  unique: 81
FK constraints: 92  with explicit actions: 92

clean: no duplicates, no forward references, all FKs RESTRICT
```

## Real fixture results

I ran both batteries with:

```text
bin/event-test.sh /var/home/michael/piers/rover-m7t2-sol-bel
```

Each run executed real Eyre writes, direct urQL readback against the pinned
Obelisk agent, a ship restart, and a Playwright browser save. The fixtures
proved the 62 starter definitions, 10 simultaneous selections, one selection,
zero selections, owner definition creation, shared definitions, parent-keyed
foreign keys, persistence, browser rendering, and the five-arm action union.

Run 1 final lines, verbatim:

```text
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: COVERAGE - all 20 defined fixtures executed
```

Run 2 final lines, verbatim:

```text
event-test: fixture 14 PASS - a person saves a service event from the Add Event form and sees it come back
event-test: COVERAGE - all 20 defined fixtures executed
```

Both runs exited 0. No fixture was skipped.

## Design choices

- Relations: `service-subtype-definitions` and
  `vehicle-event-service-subtypes`. The names distinguish this owner catalog
  from energy subtypes and state the parent association.
- Catalog shape: no category column. One owner catalog avoids duplicate labels
  and leaves classification to the event context.
- Source collisions: `Car Wash`, `Insurance`, and `Registration` each seed one
  definition. A shared definition preserves the vocabulary without presenting
  duplicate selector labels before T8 can archive them.
- Starter scope: all 62 distinct labels from the 65-row aCar catalog seed once.
  AAA maintenance guidance supplied the general-market cross-check; MOT
  guidance supplied the UK-specific inspection check.
- Entry control: service-only checkbox multi-select plus one new-definition
  field. Checkboxes make a 10-item visit practical, while the field preserves
  owner vocabulary.
- Schema affordance: the browser shows subtypes only for service events, but
  the link remains parent-keyed and carries no typed-child constraint. This
  follows the recorded-fact doctrine in ruling 11.
- Rendering: cards show a stable alphabetical `SERVICE WORK` list. A list stays
  readable for the observed 10-subtype event.
- Reminder path: each definition has a stable random `subtype-id` primary key.
  T6 can reference that key without changing a populated relation; T2 adds no
  reminder relation or interval column.

Research references:

- AAA, “Time-Stamped Car Maintenance Checklist”:
  <https://www.aaa.com/autorepair/articles/car-maintenance/time-stamped-car-maintenance-checklist>
- GOV.UK, “Getting an MOT: The MOT test”:
  <https://www.gov.uk/getting-an-mot/the-mot-test>

## Questions and status

No design question required a `QUESTIONS.md` entry.

Final `git status --short`: clean; it produced no output after the commit.
