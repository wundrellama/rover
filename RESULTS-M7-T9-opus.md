# RESULTS — M7 T9, import widening (branch `ab-m7t9-opus`)

Date: 2026-08-18. Every result below comes from a run on a real pier against the
pinned Obelisk agent. No result comes from a mock.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t9-opus`, branch `ab-m7t9-opus` |
| Pier | `/var/home/michael/piers/rover-m7t9-opus-bel`, ship `~bel`, tmux session `m7t9opus` |
| Ames port | 32510 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | local checkout `/tmp/obelisk-fresh` @ `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`, byte for byte with the Rover copy |
| Install path | Local standalone desk. The fake `~bel` cannot reach `~dister-nomryg-nilref` over Ames, so `%obelisk` came from the pinned checkout and started with `\|start %obelisk %obelisk` |
| Rover commit at the baseline run | `afb7ca1` |
| Rover commit under test | see the commit list at the end |

**The pier was rebuilt once, mid-task.** T9 changes the shape of
`import-report`, which lives inside the agent's state. Two development
iterations both saved a `state-18`, so the second shape could not nest into the
noun the first one wrote, and `on-load` refused. `|nuke`, `|revive`,
`|uninstall` and a hard nuke all restored the archived state, so the pier kept
running the older build. The pier is disposable; it was deleted and booted again
at the same path from the same pill, and both desks were installed again. **A
real ship never meets this**: it goes from `state-17` to `state-18` once, and
`state-17` freezes the pre-T9 `import-run` shape so an import running across the
upgrade is dropped rather than misread.

## The baseline

`bin/event-test.sh` ran green on the pinned code before any T9 change:

```text
event-test: COVERAGE - all 77 defined fixtures executed
```

## What T9 adds

### The converter: four new payload sections plus the notices

`tools/acar-import/convert.py` read the fuel side of an aCar export and counted
the rest. It now converts it.

| Section | Holds |
|---|---|
| `definitions.service-subtypes` | One entry per LABEL, from the 65 source subtype records |
| `vehicles[].serviceEvents`, `.noteEvents` | The event records. Sections also exist for expense, acquisition and disposal |
| `vehicles[].reminders` | The time and distance interval each reminder carries |
| `vehicles[].specification` | The thirteen T7 fields, and only the ones the source filled |
| `notices` | One entry per source record kind that did not become a row, each with a count and a reason |

**The SECTION is the kind.** A record never names its own kind, so it cannot
disagree with the typed child row it becomes. That is the same rule the five Add
Event routes enforce, moved from the route to the section.

Places now cover event records as well as fills. A place only a service visit
names takes station kind `private`, which is what the Add Event station control
offers first.

### The desk: three new work kinds, and one new relation

| Work kind | Lookup | Write |
|---|---|---|
| `%spec` | `spec-lookup`, the vehicle plus the thirteen relations | one INSERT per field the vehicle does not hold |
| `%event` | `event-existing-lookup`, then `event-lookup:act` | `insert-event:act` plus one provenance row |
| `%reminder` | `reminder-existing-lookup` | `insert-reminder:act` |

Service subtypes reach the shipped create-if-absent path as a fifth simple
definition family, so no new code decides whether a subtype exists.

**`decode-event` and `decode-reminder` split into object-level arms.** One
decoder now serves the browser and the import, so an imported record cannot be
validated more loosely than a typed one.

## The one new relation, and why

```text
event-imports (event-id @ux, source-app @tas, source-record-id @t)
  PRIMARY KEY (event-id)
  FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT
```

The brief expected T9 to need no new relation and asked for the reason if it
did. The reason is that **re-import safety has one ratified mechanism and it is
per-record provenance** (import Q5), and the shipped `acquisition-imports`
cannot hold an event because its foreign key names `energy-acquisitions`.

Import Q5 rejected the natural key — vehicle plus observed-start — for a reason
that does not change with the record family: it conflates "have I already
imported this record?" with "are these the same real-world event?", and two
legitimate records inside one source minute would be **refused in silence**.
Silent refusal of real data is the failure mode this project rules against
repeatedly.

The post-publish rule forbids a new **column** on a populated relation. A new
child relation is how capability is meant to arrive, and this one is the shipped
`acquisition-imports` with one word changed. It reaches an installed database
through the same `ensure-def-schema` catch-up pour every earlier relation used.

Everything else T9 carries needed no relation: events, associations, subtypes,
reminders and the thirteen specification relations were all built by T1 through
T7.

## The real corpus

Measured from the owner's export at `~/workspace/rover/aCar export/`. The export
is personal data, it is gitignored, and nothing in the repository opens it —
fixture 63 fails the run if anything does.

### What the source holds

| Source | Count |
|---|---|
| Vehicles | 2 |
| Fill records | 420 |
| Event records | 39 — 35 service, 4 note, 0 expense |
| Event to subtype references | 107 across 29 distinct subtypes |
| Event subtype definitions | 65 — 55 service, 10 expense |
| Subtypes carrying a default reminder interval | 52 |
| Reminders | 8, every one carrying both a time and a distance interval |
| Specification field slots | 26 (thirteen fields on each of two vehicles), 22 of them filled |
| Duplicate subtype labels | 3 — `Car Wash`, `Insurance`, `Registration` |

`color` and the vehicle note are empty on both vehicles, which is why 22 of 26
slots carry a value. An empty source field writes no row.

### The import report

PLACEHOLDER-IMPORT-REPORT

### The second import of the same document

PLACEHOLDER-SECOND-IMPORT

### The converter report

PLACEHOLDER-CONVERTER-REPORT

## Two defects the real corpus found

Both were found by re-importing, and neither would have shown on a first import.

**1. `N` cannot qualify a column in a SELECT list.** `N` is urQL's own literal
for false — the one `archived = N` writes. `JOIN vehicle-event-notes N ON …` and
`WHERE N.note = '…'` both parse, and the shipped fixture 35 uses them, but
`SELECT N.note` is refused. The event note comparison selected that way, and
every re-import answered `database comparison lookup refused` for all 39 events.
The shipped fill path had already used `Q` for the same relation; the event path
now does too. The battery repeated the same mistake in its own readback query,
which is how the second half of the finding was measured.

**2. An event note holding a newline was stored with the newline turned into a
space.** Seven of the owner's 26 event notes hold newlines. urQL treats a
newline inside a literal as whitespace, so the stored note had the same length
and different content — a silent change to the owner's own words. The fill path
already solved this: Rover parses its own script to an AST and puts the note in
as a typed value. `replace-fill-note` generalizes to `replace-note`, keyed by
the relation, and an event note now takes the same path.

A third defect was found the same way and is smaller: the specification
comparison read the model year with `scow`, which prints Hoon's dot separators,
so `2.019` never equalled the `2019` the column holds. Both sides now use
`sql-ud`, which is what writes the column.

## A substrate limit found, and not worked around

**A four-relation join is refused when the joined set is empty for the whole
relation, whatever the predicate selects.** The engine builds the joined-row
address map before it applies the predicate, and it reads that map from the
first joined row:

```text
lib/utils.hoon:175       calc-joined-addr, ~(dig by data) on a table not in the map
lib/selections.hoon:822  reached while building the joined column metadata
```

Measured on the pier, all three against the same populated database:

| Query | Result |
|---|---|
| `energy-acquisitions ⋈ fuel-fill-additives ⋈ additive-definitions`, no predicate | 3 rows |
| the same plus `⋈ acquisition-imports`, where no additive link belongs to an imported acquisition | **refused** |
| the same shape over `fuel-fill-subtype`, where the links do belong to imported acquisitions | 3 rows |

This is the shipped fill re-import comparison, which T9 does not change. Three of
its four-relation joins are affected, and each one is affected only when the
document being re-imported never uses that association at all:

| Query | Link relation | Affected when |
|---|---|---|
| `fill-comparison-lookup` | `fuel-fill-additives` | no imported fill carries an additive |
| `fill-comparison-tail-lookup` | `fuel-fill-tags` | no imported fill carries a tag |
| `fill-comparison-tail-lookup` | `fuel-fill-payment-method` | no imported fill records a payment method |

The three-relation joins in the same scripts — average speed, drive balance,
fill notes, economy breaks — return an empty result set correctly. Only the
four-relation ones fail.

The owner's own corpus uses all three associations, so the owner never meets
this, and the 420-record re-import below is clean.

**T9 does not work around it.** Reshaping an M0 query on the strength of a newly
found engine limit is a design decision that deserves a ruling, not a quiet edit
inside an import task. The finding is recorded here with its reproduction. The
battery's own document carries an additive, a tag and a payment method on its
fills for the same reason the corpus does, so the fill re-import path is
exercised rather than skipped. A person re-importing a document that uses none of
the three sees the record reported as a failure and nothing is written, so no
data is at risk and the loss is visible rather than silent.

The same shape appears nowhere in the T9 code: `event-comparison-lookup` reaches
`tag-definitions`, `service-subtype-definitions` and
`payment-method-definitions` through the same four-relation shape, so an event
document that uses none of those would meet the same limit. The event fixtures
use all three.

## What stays unmapped, and why

Every line below is in the import report the owner reads, with its count and its
reason. Nothing in the source ends anywhere else.

| Source | Count | Reason |
|---|---|---|
| `insurance-policy` | 2 | Insurance is fenced, ruled 2026-08-18 |
| Photos | 119 in `<photos>` plus 2 in the vehicle `<photo>` | Attachments are their own task. Extracted to disk with a manifest; no database row |
| PDF slots with content | 0 of 69 | Nothing to carry |
| Trip types | 6 | aCar defaults carrying IRS mileage deduction rates |
| Trip records | 0 | Nothing to carry |
| `device-*` coordinates | 318 fills | Where the phone was, not where the station is (Q6) |
| `place-google-places-id` | 275 fills, 14 events | A machine value that never reaches a person |
| Subtype default reminder intervals | 52 | Rover stores an interval on a reminder, not a suggestion on a catalog entry |
| Event records with a source total of zero | 12 | aCar writes 0 for an unentered amount |
| Reminder due points losing a time of day | 7 | A reminder falls due on a calendar day |
| Suppressed `deleted` tags | 125 | An aCar internal marker (Q8) |
| Station-none fills with orphaned address text | 3 | The text names no station (Q10) |
| aCar catalog row numbers, `active`, `type`, registration place | 2 each | No Rover relation holds them |

The one source record the plan named explicitly is reported by name: a record
aCar typed `note` carries a total of 811.88. It imports as a note with that
total. Reclassifying it would decide, on the owner's behalf, that aCar's own
type was wrong.

## Design latitude used

The specs fix the report obligation, the unmapped list, the no-privileged-path
rule and the no-new-relation expectation. They do not fix the following, and
each choice is mine.

1. **One document section per event kind, rather than a `kind` member.** The
   section plays the part the route plays for a browser, so a record cannot name
   a kind that disagrees with the child row it becomes.
2. **The importer carries the converter's unmapped notices inside the
   document.** Only the converter reads the source, so only the converter knows
   what was left. Carrying the notices means the report a person sees after the
   import says the same thing as the report the converter printed.
3. **A source total of 0.00 writes no cost row.** aCar makes the field mandatory
   and writes 0 when nothing was entered, so a stored 0.00 could not be told
   apart from a genuine free service. Absence is visibly unknown; a stored zero
   is invisibly wrong. The 12 records are named in the report.
4. **The 52 subtype default reminder intervals stay out.** Rover stores an
   interval on a reminder, and 4 of the owner's 8 reminders already carry
   exactly the suggestion for their subtype. Creating 52 reminders nobody set
   would invent schedules; emitting a payload key no relation reads would be a
   stub. The count and the reason are in the report.
5. **A place only an event names takes station kind `private`.** Rover's four
   kinds are `fuel`, `charging`, `mixed` and `private`, and none says "repair
   shop". `private` is the kind the Add Event station control offers first, so
   an imported shop matches a hand-entered one, and no forecourt that sells
   nothing appears in the Add Fill selector.
6. **Import writes a specification field the vehicle lacks and never overwrites
   one it holds.** A field whose stored value differs is reported as a conflict.
   `spec-write` on the product path deletes and re-inserts, which is right for a
   person correcting a value and wrong for a stale foreign export.
7. **A reminder is addressed by its vehicle and its subtype.** That is what a
   person means by "the oil reminder on the truck", and it needs no provenance
   relation of its own.
8. **The report orders itself by record kind, then by definition family, then by
   what was left out.** What came in first, what was already there beside it,
   and the disclosure last.
9. **A malformed record fails alone.** The run reports it by name and continues,
   which is the atomicity the fill path already had: one script per record, and
   a failure mid-batch leaves earlier records intact.
10. **Conflicts are counted per record kind.** A specification conflict on the
    fill line would say something that never happened.
11. **The browser and `upload.py` split every record kind across batches, and
    the specification rides the first batch alone.** A batch is a bounded,
    resumable slice of the work, and a record is the unit of work. Carrying the
    specification on every batch would report the same fields already-held once
    per batch.

## Done-check

PLACEHOLDER-DONE-CHECK

## The battery

PLACEHOLDER-BATTERY

## Commits

PLACEHOLDER-COMMITS
