# RESULTS — M7 T7, vehicle identity and specification (branch `ab-m7t7-opus`)

Date: 2026-08-18. Every result below comes from a run on a real pier against the
pinned Obelisk agent. No result comes from a mock.

## Every VIN and plate in this tree is synthetic

This is stated first because it is the part of T7 that can do lasting harm.

The battery writes four VINs: `ROVERFAKEVIN00001`, `ROVERFAKEVIN00002`,
`ROVERFAKEVIN00003`, and `ROVERFAKEVIN00009`. Each is seventeen characters and
each contains the letters `I` and `O`. **The real VIN alphabet excludes I, O and
Q**, so none of these can ever be a real vehicle identification number. The three
plates are `ROVER-FAKE-01`, `ROVER-FAKE-02` and `ROVER-FAKE-03`.

Fixture 63 asserts this mechanically. It scans every tracked file except the font
and image assets for a seventeen-character token drawn from the real VIN
alphabet, and fails if it finds one. It then checks that each VIN this run writes
is seventeen characters and carries a letter that alphabet excludes, and that
each plate carries the word `FAKE`.

**The owner's aCar export was not read.** Nothing in `bin/`, `probes/` or `desk/`
names its directory as a path, `.gitignore` still holds `aCar export/`, and
fixture 63 asserts both. No value from that export appears in this tree, in any
fixture, in any probe, or in any commit message.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t7-opus`, branch `ab-m7t7-opus` |
| Pier | `/var/home/michael/piers/rover-m7t7-opus-bel`, ship `~bel`, tmux session `m7t7opus` |
| Ames port | 32310 |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `master` @ `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta) |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |
| Rover commit at the baseline run | `cd367d4` |
| Rover commit under test | `41b2164` |

The pier is a fake `~bel`, so it cannot reach `~dister-nomryg-nilref` over Ames.
Obelisk came from the pinned local checkout at `/tmp/obelisk-fresh`. Its
`sur/obelisk-ast.hoon` matches the Rover copy byte for byte. Both desks went in
with `|merge ... our %base`, `|mount`, a file copy, `|commit`, `|install`, and for
Obelisk `|start %obelisk %obelisk`.

A baseline run of the unchanged battery on this pier, before any T7 code, gave
`COVERAGE - all 54 defined fixtures executed` with zero failures.

## What T7 adds

Thirteen relations. No column reaches a populated relation.

```text
vehicle-vin            (vehicle-id @ux, vin @t, recorded-at @da)
vehicle-license-plate  (vehicle-id @ux, plate @t, recorded-at @da)
vehicle-model-year     (vehicle-id @ux, model-year @ud)
vehicle-make           (vehicle-id @ux, make @t)
vehicle-model          (vehicle-id @ux, model @t)
vehicle-sub-model      (vehicle-id @ux, sub-model @t)
vehicle-body-type      (vehicle-id @ux, body-type @t)
vehicle-color          (vehicle-id @ux, color @t)
vehicle-engine         (vehicle-id @ux, engine @t)
vehicle-transmission   (vehicle-id @ux, transmission @t)
vehicle-drive-type     (vehicle-id @ux, drive-type @t)
vehicle-bed-type       (vehicle-id @ux, bed-type @t)
vehicle-notes          (vehicle-id @ux, note @t)
```

Every one takes `PRIMARY KEY (vehicle-id)` and a `RESTRICT` foreign key to
`vehicles (vehicle-id)`. `vehicles` still holds the four columns it shipped with,
and fixture 55 counts them.

Insurance is not built, and no relation, column, or field anywhere in the desk
names it. See the ruling section below.

### Where the code lives

- `desk/lib/rover-act.hoon` — `spec-view-order` is the one list of thirteen
  `[relation column]` pairs. `spec-relations` builds the DDL from it,
  `spec-queries` builds the read from it, `spec-write` writes one field at a
  time, and `update-vehicle-settings` calls that last one.
- `desk/lib/rover-entry.hoon` — `decode-vehicle-edit` reads each specification
  key on its own.
- `desk/lib/rover-view.hoon` — `vehicle-description` renders what a person
  recorded, `vehicle-spec-form` is where they type it, and `spec-index` carries
  the thirteen row lists by relation name instead of as thirteen arguments.
- `desk/sur/rover.hoon` — `spec-text`, `spec-number`, `vehicle-spec-entry`.
- `docs/schema-m0.sql` — the thirteen relations, with the reasoning.

## The division: one relation per field

The specification page offers two shapes and recommends the second, "typed child
relations per concern: identifiers, make and model, drivetrain, appearance." The
brief fixes shape 2 and leaves the exact division open.

**The division is finer than four, and the rules force it.** Every field is
individually optional, and a row must use every column it defines. Put those two
together and take the page's own `vehicle-drivetrain` sketch: engine,
transmission, drive type and bed type in one row. **A sedan has no bed at all.**
That row therefore bunts a column for every vehicle that is not a pickup, which
is the conditionally-meaningless-column defect shape 2 exists to avoid.

The same test kills every other grouping. Make and model look inseparable until a
person records a 1981 truck whose model they never learned. Sub-model without
model is nonsense, but model without sub-model is the ordinary case. No pair
among these twelve fields is always-together, so no pair earns a shared row.

The corpus agrees. Both of the owner's vehicles carry make, model, sub-model,
year, body type, engine, transmission, drive type and bed type, and **both leave
colour and the note empty**. A single wide row would bunt two columns on the only
two real records available.

The cost is thirteen relations, and it is paid once. `spec-view-order` is a
single list of thirteen pairs, and the pour, the queries, the write and the
render all read it. A fourteenth field is one entry in that list.

## VIN and plate: the gating argument

**Ruled 2026-08-18: VIN and plate must be shareable independently of other
vehicle data, and independently of each other.** This is a schema requirement,
not a sharing-milestone requirement, because a grant can only be as fine-grained
as the rows it gates.

T7 builds two relations, `vehicle-vin` and `vehicle-license-plate`. Read back
from `sys.columns` on the pier:

```text
vehicle-vin            vehicle-id   vin     recorded-at
vehicle-license-plate  vehicle-id   plate   recorded-at
```

**Neither holds a descriptive column, and neither holds the other's value.**
Fixture 61 asserts both, and asserts them over every relation in the database
rather than over these two: it reads the whole `sys.columns` list, groups the
columns by relation, and fails if any relation holds `vin` or `plate` beside a
descriptive column, or holds both `vin` and `plate`.

Two relations rather than one relation with two columns, for two reasons that
point the same way.

**The gating reason.** A grant is a rule about rows. Rover's future sharing pour
is `vehicle-grants` and `vehicle-grant-fields`, and whatever those turn out to
be, the finest thing the engine returns is a row. A single
`vehicle-identifiers (vehicle-id, vin, plate)` row forces a grant that reaches
the plate to reach the VIN in the same read, and the only way out is
column-level permission the substrate does not have. Two relations make the
grant that a person actually wants — a plate for the parking service, a VIN for
the mechanic, never both — expressible with the row-shaped machinery Rover
already uses everywhere. Nothing has to be migrated later to get there.

**The optionality reason, which reaches the same shape on its own.** A vehicle
may carry a VIN and no plate, or a plate and no VIN. Under one relation both
columns are mandatory whenever the row exists, so one of the two states is
unrepresentable without a bunt. That is the same defect the drivetrain grouping
has. The gating requirement and the individually-optional rule agree, which is
the strongest evidence the shape is right.

Fixture 61 proves the independence on data as well as on columns. `Spec Plate
Only Vehicle` carries a plate, a make and a model, and has **no row** in
`vehicle-vin`. `Spec Late VIN Vehicle` carries a VIN and has **no row** in
`vehicle-license-plate`. Each identifier is present or absent without the other.

The served vehicle screen shows the same thing:

```text
=== Spec Plate Only Vehicle
  headline  Honda Civic
  plate     PLATE ROVER-FAKE-02
=== Spec Late VIN Vehicle
  vin       VIN ROVERFAKEVIN00002
```

**VIN is evidence, not a key.** No foreign key anywhere targets `vin` or
`plate`, and fixture 55 reads `sys.foreign-keys` to assert it. `vehicle-id`
remains the only identity.

## The insurance ruling, as built

**Ruled 2026-08-18: insurance is not built in T7.** A bare policy string cannot
say when the policy renews, what it covers, or what it cost. It is a stub of a
feature rather than a feature, and shipping the stub makes the real feature
harder, because the stub's shape becomes a migration obligation.

There is no `vehicle-insurance-reference` relation, no insurance column on any
relation, and no insurance field in any entry mold or form. Fixture 62 asserts
this against `sys.tables`, against `sys.columns`, and against the shipped desk
source.

Fixture 62 also asserts what must **not** change. `Insurance` stays a T2 service
subtype starter label. It records what a person paid the insurer, which is an
expense and a different thing from the policy machinery the fence covers.
Removing it would have been a second defect.

The T9 import reports `insurance-policy` as unmapped.

## The compatibility guard, and how it is proved

Every installed database holds vehicles with no specification data. The brief is
plain: if T7 changes anything a person sees for such a vehicle, T7 is wrong.

`bin/spec-free-vehicle-card.html` is the settings panel of a vehicle created by
`add-vehicle` and never edited, **captured from the pre-T7 desk on this pier
before any T7 code existed**. Fixture 58 creates the same kind of vehicle and
compares the served panel against that file character for character.

Two normalizations apply to both sides and to neither side alone: the vehicle
label, which carries the run stamp, and the two membership check grids, whose
contents follow the energy-source and driving-mode catalogs rather than anything
T7 does.

The specification fieldset is removed from the served panel before the
comparison. **Everything else must match, including the rest of the settings
form.** That is what makes the guard strict: it proves T7 added nothing anywhere
else in the panel, not merely that the read surface is unchanged.

Excluding the new fieldset is the tank-size precedent, not an exemption. An
optional field has always taken a blank control in the settings form and said
nothing at all on the read surface until the owner fills it in. The pre-T7
capture already shows an empty `Tank size` input on a vehicle with no tank size.
A feature with no browser control is the defect Gate 7 was closed over, so the
control has to exist somewhere, and this is where every other optional vehicle
field already lives.

Fixture 58 also asserts that the panel of a specification-free vehicle carries no
`data-vehicle-spec` element at all, and fixture 64 asserts the same after a real
ship restart.

### The guard seen red

The check was broken on purpose to prove it has teeth. `vehicle-description` was
changed to render `Not recorded` when it had nothing to say — the placeholder a
careless implementation writes. The desk was committed to the pier and the
battery ran. Verbatim:

```text
event-test: fixture 57 PASS - each specification field is independently absent, and a cleared field removes its row rather than storing an empty string
event-test: FAIL - fixture 58 a vehicle with no specification data renders a specification line
```

The line was reverted and fixture 58 went green again.

### The individually-optional rule seen red

`spec-text-write` was changed so a field the owner cleared inserts an empty
string instead of removing its row. Verbatim:

```text
event-test: fixture 56 PASS - twelve specification fields and the vehicle note save, reach thirteen relations, and read back as a description
event-test: FAIL - fixture 57 a cleared make left a row behind: ... [%result-set [%vector [%make 116 0] 0] 0] ...
```

`[%make 116 0]` is the empty-string row the rule forbids. The change was
reverted.

### The whole T7 block went red first

Before any T7 code existed, the eleven new fixtures ran against the pre-T7 desk
and stopped at the first assertion:

```text
event-test: fixture 52 PASS - recording the service the reminder names resets it, and the stored due point is never rewritten
event-test: FAIL - fixture 55 the pour is missing vehicle-vin
```

## What the vehicle screen says

Read back from the pier after the final runs. A vehicle renders only the lines it
has data for.

```text
=== Spec Vehicle
  headline  2019 Ford F-150 Lariat
  detail    Oxford White crew cab pickup, 3.5L V6 EcoBoost, 10-speed automatic, four-wheel drive, 5.5 ft bed.
  vin       VIN ROVERFAKEVIN00001
  plate     PLATE ROVER-FAKE-01
  note      Bought used with a full service history 1787022908
=== Spec Browser Vehicle
  headline  1981 Chevrolet C10 Scottsdale
  detail    Carmine Red regular cab pickup, 5.7L V8, 4-speed manual, rear-wheel drive, 8 ft bed.
  vin       VIN ROVERFAKEVIN00003
  plate     PLATE ROVER-FAKE-03
  note      Second owner 1787025447
=== Spec Partial Vehicle
  headline  Corolla
=== Spec Plate Only Vehicle
  headline  Honda Civic
  plate     PLATE ROVER-FAKE-02
=== Spec Late VIN Vehicle
  vin       VIN ROVERFAKEVIN00002
```

`Spec Partial Vehicle` reads `Corolla` because fixture 57 cleared its make and
the row went away. It has no description sentence, because it has nothing to
describe. `Spec Late VIN Vehicle` shows a VIN and nothing else.

## The desk installs

The agent was nuked and installed again, so the install path is on the record:

```text
> |nuke %rover
gall: nuking %rover
> |install our %rover
gall: unnuking %rover
eyre: replacing existing binding at /apps/rover
> |rein %rover [%.y %rover]
gall: booted %rover
```

No `nest-fail`. The served view worked immediately after.

### The upgrade step a populated database needs

`ui-view` names the thirteen new relations, so a database poured before T7
refuses the view query until the definition-layer catch-up runs. On this pier the
first attempt answered:

```text
event-test: FAIL - fixture 1 the served view has no hub: Rover could not load the vehicle log. Obelisk refused the view query.
```

One poke of the shipping `%ensure-def-schema` action poured the thirteen
relations, and every run after that was green from fixture 1. This is the
published-ship upgrade path Rover already has, and fixture 2 is its standing
proof. A fresh database is not affected, because `schema-m0` welds the whole
relation list. The behavior is not new to T7 — every task from T1 on that adds a
relation to `ui-view` has it.

## Done-check results

| # | Check | Result |
|---|---|---|
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | PASS, output above |
| 2 | All thirteen fields plus notes save and read back through Eyre | PASS, fixtures 56 and 65 |
| 3 | A vehicle with no specification data renders exactly as it did before T7 | PASS, fixture 58, red output above |
| 4 | Each field is independently optional, with no empty strings or zeros | PASS, fixture 57, red output above |
| 5 | A vehicle created without a VIN gains one later with no re-keying, and its history still reads | PASS, fixture 59 |
| 6 | A mistyped VIN is corrected and every existing link still targets the same vehicle | PASS, fixture 60 |
| 7 | `vehicle-id` is still the only identity, and no relation keys to VIN or plate | PASS, fixture 55 |
| 8 | VIN and plate share no relation with a descriptive field and are independently gateable | PASS, fixture 61, argued above |
| 9 | No insurance field or relation exists anywhere in the tree | PASS, fixture 62 |
| 10 | No real VIN or plate appears in any fixture, probe, seed, results file, or commit | PASS, fixture 63 |
| 11 | Everything above survives a ship restart | PASS, fixture 64 |
| 12 | The shipping action union still has five arms | PASS, fixture 13 |
| 13 | The full battery runs twice back to back with the same verdict, and no skips | PASS, output below |

Check 2 counts twelve stored fields plus the vehicle note, which is thirteen
stored values in thirteen relations. `insurance-policy` is the fourteenth name on
the specification page and it is ruled out, so it is neither built nor counted.

## Battery evidence

Both runs used the pier and the desk above, back to back, with no change between
them. Verbatim final two lines of each run:

Run 1, `/tmp/t7-final-1.log`:

```text
event-test: fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description
event-test: COVERAGE - all 65 defined fixtures executed
```

Run 2, `/tmp/t7-final-2.log`:

```text
event-test: fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description
event-test: COVERAGE - all 65 defined fixtures executed
```

Both runs report zero `FAIL` lines and 69 `PASS` lines. The coverage gate names
all 65 defined fixtures as executed, with no skips.

The eleven new fixtures, from run 1:

```text
event-test: fixture 55 PASS - thirteen specification relations exist, one per field, vehicles gained no column, and no foreign key targets a VIN or a plate
event-test: fixture 56 PASS - twelve specification fields and the vehicle note save, reach thirteen relations, and read back as a description
event-test: fixture 57 PASS - each specification field is independently absent, and a cleared field removes its row rather than storing an empty string
event-test: fixture 58 PASS - a vehicle with no specification data renders exactly as it did before T7, character for character
event-test: fixture 59 PASS - a vehicle created without a VIN gains one later, keeps its vehicle-id, and its history still reads
event-test: fixture 60 PASS - a mistyped VIN is corrected in place, and every link still targets the same vehicle
event-test: fixture 61 PASS - VIN and plate each hold a relation of their own, share none with a descriptive field, and are present or absent independently of each other
event-test: fixture 62 PASS - no insurance relation, column, or field exists anywhere in the shipped desk, and the T2 expense subtype label is untouched
event-test: fixture 63 PASS - every VIN in the tree contains a letter the real VIN alphabet excludes, every plate is marked FAKE, and the owner's export is never read
event-test: fixture 64 PASS - every specification row, absence, correction, and rendered description survived a ship restart
event-test: fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description
```

T7 added eleven fixtures and broke none of the fifty-four that were there.

### One environment failure, and what it was

An earlier attempt at the two final runs failed at fixture 12 with `the pier did
not restart`. The cause is in the harness, not in T7.

Fixture 12 waits for the old pier to stop with `pgrep -f "snap-dir $PIER"`. The
serf reports its `--snap-dir` as `/var/home/michael/piers/...`, and `~` expands
to `/home/michael/piers/...`. On this machine `/home` is a symlink to
`/var/home`, so the two name one directory and the pattern never matches. The
wait therefore returned at once, the fixture killed the tmux session while the
old pier still held the pier lock, and the new pier died on startup.

This is the same class as the teardown race the T3 report recorded. The fix used
here changes no fixture: the pier was booted under the canonical
`/var/home/...` path and the battery was invoked with the same path, so the king
and the serf agree and the wait matches. Both final runs then passed. The two
runs recorded above are the runs made this way.

## A substrate trap the recorded pitfall predicted

`probes/README.md` already records that `N` and `Y` are boolean literals and
cannot be relation aliases. Three of the new fixture queries used them anyway,
and each failed with a `lib/parse` stack that names no clause:

```text
FROM vehicles V JOIN vehicle-model-year Y ON ... SELECT Y.model-year;   REFUSED
FROM vehicles V JOIN vehicle-model-year S ON ... SELECT S.model-year;   OK
FROM ... JOIN vehicle-event-notes N ON ... SELECT N.note;               REFUSED
```

The queries were rewritten with other letters. One detail the README does not
say, measured here: the refusal comes from **projecting** `N.<column>` or
`Y.<column>`, not from the alias alone. Shipped fixture 35 joins
`vehicle-event-notes N` and filters on `N.note` in a `WHERE` clause without
projecting it, and it parses. That is why the trap can hide.

The README is accurate as written and needs no change. It is recorded here
because the first symptom looked like a keyword collision on `year`, and it was
not.

## Design latitude used

The specs fix shape 2, the individually-optional rule, the VIN-is-evidence rule,
the insurance ruling, the identifier separation, and the compatibility
requirement. These are the choices they left open.

### 1. The division of the twelve fields into relations — one relation per field

This gets the full paragraph the brief asks for, and it must argue the
identifier gating explicitly.

The specification page sketches four relations: identifiers, make and model,
drivetrain, appearance. **That sketch fails the page's own rule, and the
drivetrain proves it.** A row holding engine, transmission, drive type and bed
type must have all four whenever it exists, and a sedan has no bed at all — so
the row bunts a column for every vehicle that is not a pickup, which is exactly
the conditionally-meaningless-column defect shape 2 was chosen to avoid. The same
test applied to every other candidate grouping gives the same answer: make
without model is how a person records a vehicle whose model they never learned,
model without sub-model is the ordinary case, and colour without body type is
what the owner's own corpus holds, since both of his vehicles leave colour empty
while carrying nine other fields. Because no pair is always-together, no pair
earns a shared row, and the division lands on one relation per field. The
identifiers then fall out of the same rule rather than needing a separate
argument: a single `vehicle-identifiers (vehicle-id, vin, plate)` makes both
columns mandatory together, so a vehicle with a plate and no VIN is
unrepresentable without a bunt. Splitting them satisfies the ruling as a
consequence, and the gating story is the stronger half of why the split must
survive: a grant is a rule about rows, the pinned substrate has no column-level
permission, and Rover gates on the presence of rows everywhere else. With
`vehicle-vin` and `vehicle-license-plate` as separate relations, the grant a
person actually wants — hand the plate to the parking service, hand the VIN to
the mechanic, never both, and never the make and model with either — is
expressible with the machinery the sharing pour will already have, and no
relation has to be split later on a populated database. Fixture 61 checks the
claim over every relation in the schema rather than over these two, so a future
task that adds `vin` beside a descriptive column fails the battery.

### 2. `recorded-at` on the two identifier relations and on no other

An identifier is the specification field a person **corrects**. The VIN is
mistyped, the plate changes with the state. Knowing when the value now held was
recorded is what makes a correction traceable, and it costs one column on a row
that has to exist for the value anyway. The descriptive fields do not get it:
make and body type are facts about what the vehicle is, they are not corrected in
the same sense, and Rover has no reader for when a person typed one.
`vehicle-tank-size` and `vehicle-refill-reserve` are the precedent for the plain
shape, and `vehicle-default-energy-subtype` for the stamped one.

### 3. `model-year` rather than `year`, and four digits enforced

`year` is a urQL keyword. Naming the column `model-year` sidesteps the question
entirely and is the more precise word for what the number is: a model year, not a
date. A year a person reads is four digits, so the entry path refuses anything
below 1000 or above 9999. That rejects a zero, a two-digit shorthand and a
mistyped seven-digit number. It is a Rover invariant with no spec behind it, so
it is recorded here rather than assumed.

The parse also had to change. `slaw %ud` wants Hoon's own `2.019` syntax and
refuses the `2019` a person types, so the entry path reads a plain decimal with
`parse-decimal` and the render prints with `format-scaled`, ungrouped. Fixture 56
asserts the stored value is the number `2019`.

### 4. Three states per field, not two: untouched, cleared, set

`spec-text` is `(unit (unit @t))`. The outer unit says whether the request body
named the field at all. The inner one says whether the person put anything in it.

Two states would have been wrong. `update-vehicle-settings` deletes and re-writes
every optional child it manages, so a single unit would make **any** vehicle
settings save from a client that knows nothing about the specification erase all
thirteen rows. Fifty-four fixtures that predate T7 post exactly such a body. With
three states, a body that names no specification key leaves the specification
alone, a key sent empty removes its row, and a key with a value writes one.
Fixture 57 drives all three.

### 5. A description on the vehicle screen, entry in the settings form

The brief asks the vehicle screen to read like a description of a vehicle rather
than a table of terms. The render puts the year, make, model and sub-model into
one name, and the colour, body, engine, transmission, drive and bed into one
sentence. VIN and plate get labelled lines of their own, because a
seventeen-character identifier inside a sentence is unreadable, and because
labelling them is what a person needs when they are about to read one aloud. The
note is its own paragraph. Every line is absent when its data is.

Entry goes in the existing vehicle settings form, beside tank size and the DEF
configuration, because that is where every other optional vehicle field already
is. The create form is unchanged: a vehicle is created and then described, which
is also what done-check 5 describes.

### 6. `spec-view-order` as the single list

The pour, the thirteen queries, and the render all read one list of thirteen
`[relation column]` pairs. Thirteen relations is a real cost, and this is what
keeps it from being thirteen places to edit. The render maps query results to
relation names through the same list rather than counting `rows-at` indices by
hand, so a new field is one entry and cannot desync the four consumers.

### 7. The specification queries go last in `ui-view`

Every index before 61 is unchanged, so no reader that predates T7 has to move.
Each of the thirteen is a single-relation query with no join, which is the shape
T6 established after a three-way join over an empty leftmost relation crashed the
pinned engine — and on a fresh database every one of these relations is empty.

## Scope

T7 built the specification and nothing else. No insurance. No definition rename
or archive, no import widening, no export. No change to the T1 event shape, the
T2 subtype catalog, the T3 odometer relation, the T4 ownership relations, the T5
derivation, or the T6 reminders. The shipping `$action` union still holds five
arms, and fixture 13 asserts it.

The aCar specification values import in T9.
