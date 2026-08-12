# Rover M1-IMPORT-GUI results

Date: 2026-08-12. Branch: `ab-importgui-opus`.

Pier: `~/piers/rover-igui-bel`. Fresh disposable fake `~bel`, Ames port 31450,
pill `brass-408k-1.pill`, booted this run under tmux session `roverigui`.
Obelisk `master` at `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta),
installed from `/tmp/obelisk-fresh` and started with `|start %obelisk %obelisk`.
HTTP port 8081, read from `.http.ports`. The owner baseline is `%init-db` plus
`%seed-starters`.

## The gap this closes

`POST /apps/rover/import` worked and had seven green fixtures. No user could
reach it. `grep -n import desk/app/rover/shell.html` and
`grep -n import desk/lib/rover-view.hoon` both returned nothing. The owner's
main ship has no practical command line, so the Python client was not an import
path for the ship that matters.

## The surface

Settings opens an import screen. The screen is static HTML with no
server-rendered data.

- `desk/lib/rover-view.hoon` `+import-screen` renders the screen. The Settings
  placeholder `IMPORT / EXPORT - COMING LATER` becomes a real section with a
  `data-open-screen="import-screen"` button. `EXPORT - COMING LATER` stays.
- `desk/app/rover/shell.html` reads the file, checks it, splits it, posts the
  batches one at a time, and renders the reports.

Controls: a file input that accepts `.json`, a batch size that defaults to 50,
a Validate button, and a Start import submit button.

Readouts: the plan, the progress line, the outcome, one list item per batch
report, and the aggregate.

### Validation before any POST

`+importPrepare` refuses four shapes and returns the Rover verdict vocabulary.

| Refusal | Verdict |
|---|---|
| Not JSON | `%bad-shape: import` |
| `rover-import` is not 1 | `%bad-shape: import.rover-import` |
| `vehicles` is absent | `%missing-key: import.vehicles` |
| `vehicles` is not a list | `%bad-shape: import.vehicles` |
| A vehicle has no `fills` list | `%bad-shape: import.vehicle.fills` |
| The batch size is not a positive integer | `%bad-shape: import.batch-size` |

It also refuses a floating-point JSON number token, which is what
`+reject_float` in `tools/rover-import/upload.py` does with `parse_float`. A
float token would pass through a double on the way back out and could rewrite
the owner's own numbers. Decimals stay strings end to end. An integer token that
does not survive `String(Number(token))` is refused for the same reason.

This is not a second validator. The desk still validates every record with
`+decode-import`. The browser refuses only the document shapes that would make
the batch split meaningless, and shows the desk's own verdict for everything
else.

### The batch split

`+importBatchDocuments` is a direct port of `+batch_documents` in
`tools/rover-import/upload.py`. It flattens the `(vehicle index, fill)` pairs,
copies the whole document per batch including the definitions preamble, empties
every vehicle, and refills one slice. The fill-count assertion `upload.py` makes
is kept: a split that changes the count refuses instead of sending.

### Sequential posts, progress, and the outcome

The submit handler awaits each response before it sends the next batch. It never
posts two at once. The progress line names the batch and carries the running
tally. Each report lands in the batch list as the endpoint returns it.

The run settles into one of five outcomes, recorded on
`#import-outcome[data-import-outcome]`.

| Outcome | Meaning |
|---|---|
| `refused` | The browser refused the document. Nothing was sent. |
| `blocked` | The endpoint answered 409. The run stopped and did not retry. |
| `stopped` | A batch failed or the endpoint refused it. Later batches were held back. |
| `incomplete` | Every batch was sent and the reports name conflicts or failures. |
| `success` | Every batch was sent and every record was accounted for. |

Only `success` turns the verdict green. A run with conflicts or failures keeps
the warning color, so it reads as a non-success.

## Blocking finding - the run stopped here

**A vehicle keeps only the energy sources and driving modes named by the batch
that created it.** A document whose vehicles span more than one batch loses
records. The unchanged `tools/rover-import/upload.py` reproduces it exactly, so
this is not the browser port, and it hits the ratified 420-record corpus at the
ratified default batch size of 50.

`QUESTIONS.md` holds the finding, the evidence, the four candidate repairs, and
why each is a ruling rather than a fix. The run stopped there instead of
choosing one.

Real output, unchanged CLI, fresh disposable database, batch size 2 over
`tests/fixtures/rover-import-synthetic.json`:

```text
Batch 2/3
Fills: imported 1, already-imported 0, conflicts 0, failures 1
Detail: Failure: Diesel Truck / ~2026.01.01..09.00.00 - driving mode was not linked to the vehicle
Aggregate
Fills: imported 5, already-imported 0, conflicts 0, failures 1
```

The same six records import whole in one POST.

Consequence for this task: the brief asks the fixtures to prove "a multi-batch
document imports every record". Fixture 112 proves it with a single-vehicle
document, which is the case the desk supports today. It cannot be proved for a
document whose vehicles span batches until the ruling lands.

## Second finding - one import run is one Arvo event

During a 200-record import the ship answered nothing else. An unrelated
`GET /apps/rover/view` issued 500 ms into the run was answered only when the run
finished, 13.4 seconds later.

```text
unrelated GET /apps/rover/view answered at 13366ms -> 503
import answered at 13366ms -> 200
```

Two consequences.

1. `409 An import is already running` cannot be observed by a second HTTP client
   on the same ship. A second request is queued, not refused, and by the time it
   runs the state is clear. The browser handles 409 as the brief requires and no
   fixture can produce one. The planned fixture was removed rather than mocked.
2. Batching in the browser is what keeps the ship responsive. The 420-record
   corpus in one POST would hold the ship for about half a minute.

## Fixtures

New fixtures 110 to 116 in `bin/ui-test.sh`, driven through a real browser by
`bin/ui-browser-fixtures.cjs` modes `import-upload` and `import-prepare`.

| Fixture | Proves |
|---|---|
| 110 | Settings opens a hidden import entry screen with the file input, batch size, validate, and submit controls |
| 111 | The browser batch split equals `+batch_documents` for the same document and batch size |
| 112 | A real browser splits a three-fill document into three batches, posts them one at a time, and every record lands |
| 113 | The rendered aggregate equals the sum of the per-batch reports, line for line with `+render_aggregate` |
| 114 | Re-uploading the same document reports already-imported and writes nothing |
| 115 | Three malformed documents are refused client-side with no POST |
| 116 | A batch the desk refuses stops the run, names the batch and the verdict, and holds back the batches behind it |

Fixtures 111, 113, and 115 count every POST the page makes to
`/apps/rover/import` through the Playwright request hook, so "sent nothing" is
measured, not assumed.

One existing assertion changed. The Settings check for the
`IMPORT / EXPORT - COMING LATER` placeholder became a check for
`data-settings-section="import"` plus the surviving export placeholder. One
existing browser fixture gained `.first()` on its Settings locator, because the
import screen adds a second control that opens Settings.

## Verification

### The failing test first

Before any surface existed, the browser fixture could not find the screen.

```text
$ node bin/ui-browser-fixtures.cjs import-upload http://localhost:8081 ...
ui-browser-fixtures: FAIL - locator.click: Timeout 30000ms exceeded.
Call log:
  - waiting for locator('[data-open-screen="import-screen"]').first()
```

### Rover compiles

```text
$ click -k -i probes/compile-rover.hoon ~/piers/rover-igui-bel
[0 %avow 0 %noun 0]
```

### The batteries

All against `~/piers/rover-igui-bel`. Zero FAIL lines in every run.

```text
$ ROVER_DEMO_ONLY=1 bash bin/ui-test.sh ~/piers/rover-igui-bel
...
ui-test: fixture 110 PASS - Settings opens a hidden import entry screen carrying a .json file input, a batch size, a validate step, and a submit control
ui-test: fixture 111 PASS - the browser batch split equals the one tools/rover-import/upload.py builds for the same document and batch size
ui-test: fixture 112 PASS - a real browser split a three-fill document into three batches, posted them one at a time, and every record landed
ui-test: fixture 113 PASS - the aggregate the browser renders equals the sum of its per-batch reports, line for line with the one upload.py prints
ui-test: fixture 114 PASS - re-uploading the same document reported already-imported 3 and wrote nothing
ui-test: fixture 115 PASS - the browser refuses a bad version, a non-list vehicles key, and a vehicle without fills, and posts nothing
ui-test: fixture 116 PASS - a batch the desk refuses stops the browser where it stands, names the batch and the desk verdict, and holds back every batch behind it
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - all 94 defined fixtures executed
EXIT=0        (99 PASS notes, grep -c FAIL = 0)

$ bash bin/schema-test.sh ~/piers/rover-igui-bel
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed

$ bash bin/import-test.sh ~/piers/rover-igui-bel
import-test: fixture 7 PASS - suspend/revive preserved imported rows and provenance
import-test: COVERAGE - all 7 defined import fixtures executed

$ bash bin/view-performance-test.sh ~/piers/rover-igui-bel
view-performance-test: run 1 - 0.575811s, 279380 bytes, 25 of 420 fills
view-performance-test: run 2 - 0.578160s, 279380 bytes, 25 of 420 fills
view-performance-test: COVERAGE - synthetic 420-fill view stayed within 2.0s

$ bash bin/dev-pin-test.sh ~/piers/rover-igui-bel
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match

$ bash tests/view-linear-test.sh
view-linear-test: PASS - one-pass derivation feeds a bounded newest-first view

$ python3 tools/rover-import/test_upload.py     -> Ran 6 tests, OK
$ python3 tools/acar-import/test_convert.py     -> Ran 18 tests, OK
```

The coverage gate needed a fix of its own. It fed `comm` two numerically sorted
lists, and `comm` compares lexically. Once fixture numbers reached three digits
the gate reported every fixture above 99 as skipped in the same run that passed
them. `bin/coverage-gate.sh` now sorts the `comm` inputs lexically and sorts
only the report numerically.

### Restart persistence

`|suspend %rover` then `|revive %rover`. The served view still carries the
import screen and the Settings control that opens it, and a real browser
imported a three-batch document afterward.

```text
$ curl -s -b <jar> $URL/apps/rover/view | grep -c 'id="import-screen"'
1
$ curl -s -b <jar> $URL/apps/rover/view | grep -c 'data-open-screen="import-screen"'
1
IMPORT_POSTS=3
OUTCOME success
MESSAGE Import complete - imported 3, already-imported 0.
```

## Fences held

- The wire format is unchanged. The browser reads what `convert.py` writes.
- No second validator. `+decode-import` still validates every record, and the
  browser shows the desk's verdict when the desk refuses.
- No action was added to the `$action` union. It stays at five arms.
- No relation was added for import state.
- `docs/schema-m0.sql` is unchanged.
- `tools/` is unchanged. `test_upload.py` and `test_convert.py` still pass.
- No conversion entered the desk. No Hoon learns a source app's name.
- No floating point. The browser refuses a floating-point JSON token before it
  parses the document.

---

# Rover M1-IMPORT-WIDEN results

Date: 2026-08-12. Branch: `ab-widen-opus`, cut from `ab-importgui-opus`.

Pier: `~/piers/rover-widen-bel`. Fresh disposable fake `~bel`, Ames port 31460,
pill `brass-408k-1.pill`, booted this run under tmux session `roverwiden`.
Obelisk `master` at `9de633299b373a1047490b48281a40b457fb2043` (v0.9.0-beta),
installed from `/tmp/obelisk-fresh` and started with `|start %obelisk %obelisk`.
HTTP port 8089, read from `.http.ports`. The owner baseline is `%init-db` plus
`%seed-starters`.

This task closes the blocking finding the M1-IMPORT-GUI run raised.

## What was wrong

A vehicle got its energy-definition and driving-mode links once, when import
created it, from the fills in that document. `+vehicle-energy-labels` and
`+vehicle-mode-labels` read `fills.vehicle`, which holds only the current
batch's slice. A batch that created a vehicle but carried none of its fills
created a vehicle with no usable energy source and no usable driving mode. Every
later batch that held a fill for that vehicle failed.

## The ruling

`~/brain/projects/rover/import-gui.md`, section "Import batching defect - ruled
2026-08-12", candidate A: **import widens the vehicle on every batch.**

When import meets a vehicle that already exists, it adds the energy-definition
and driving-mode links that batch's fills need. Three constraints came with the
ruling, and all three are in the code and in a fixture.

1. Import never archives a link. It adds a row, or it clears `archived` on a row
   it links again.
2. Import never changes the default energy.
   `vehicle-default-energy-definitions` is untouched.
3. Import does not tell a vehicle it created from a vehicle the owner created.
   It widens either one.

## The change

Three files. No relation, no action, no wire-format change, no change under
`tools/`.

- `desk/lib/rover-import.hoon:524` `+vehicle-lookup` gains two result sets: the
  energy links and the driving-mode links the vehicle already carries, each with
  its `archived` flag. A vehicle that does not exist yet returns both empty.
- `desk/lib/rover-import.hoon:781` `+widen-energy-links`,
  `desk/lib/rover-import.hoon:807` `+widen-mode-links`, and
  `desk/lib/rover-import.hoon:835` `+widen-import-vehicle` build the additive
  script. For each definition or mode the batch needs: clear `archived` on an
  archived link, insert a missing link, or write nothing. The script is empty in
  the common case, and the caller then makes no database write.
- `desk/app/rover.hoon:2331` the `%vehicle` work arm. The existing-vehicle path
  still counts `vehicles-reused`. It now also submits the widening script when
  that script is not empty. The create path is unchanged.
- `desk/lib/rover-view.hoon:109` `+row-ids` and
  `desk/lib/rover-view.hoon:117` `+archived-link-rows` read the ids and the
  archived subset out of the result rows. `+row-ids` also replaces the two
  hand-written `turn` loops the create path used.

`+sync-energy-current` and `+sync-mode-current` in `desk/lib/rover-act.hoon` are
neither called nor imitated. Those reconcile a whole set for an owner edit and
do set `archived = Y`. The widening arms have no branch that writes `Y`.

## The failing test first

The defect reproduced on the fresh pier before any change, through the unchanged
CLI, exactly as `QUESTIONS.md` recorded it.

```text
$ python3 tools/rover-import/upload.py tests/fixtures/rover-import-synthetic.json \
    --url http://localhost:8089/apps/rover/import \
    --cookie-file <jar> --batch-size 2
Batch 2/3
Fills: imported 1, already-imported 0, conflicts 0, failures 1
Detail: Failure: Diesel Truck / ~2026.01.01..09.00.00 - driving mode was not linked to the vehicle
Aggregate
Fills: imported 5, already-imported 0, conflicts 0, failures 1
EXIT=1
```

Fixtures 8 to 13 went into `bin/import-test.sh` before the desk change. Fixtures
1 to 7 passed and fixture 8 failed on the defect.

```text
import-test: fixture 7 PASS - suspend/revive preserved imported rows and provenance
import-test: FAIL - batch size 2 upload exited 1: Batch 1/3
```

## The same CLI run after the change

```text
Aggregate
Fills: imported 6, already-imported 0, conflicts 0, failures 0
Definitions: created 13, reused 32
Places: created 2, reused 4
Vehicles: created 2, reused 4
Station-none fills: 3
Total cross-check: exact 6, off-by-one 0, beyond 0
Unit mismatches: 0
EXIT=0
```

`Diesel Truck` is the vehicle batch 1 created with no fills. It now carries the
link batch 2 needed.

```text
[%energy 116 'Diesel'] [%link-archived 102 1]
[%mode 116 'Synthetic Normal'] [%link-archived 102 1]
[%default-energy 116 'Diesel']
```

## New fixtures

Six new fixtures in `bin/import-test.sh`, 8 to 13. Each builds its own vehicle
labels and its own provenance keys, because the fixtures share one disposable
database. Fixtures 8, 9, 11, 12, and 13 drive `tools/rover-import/upload.py`
unchanged, so they prove the CLI path as well as the desk.

| Fixture | Proves |
|---|---|
| 8 | The two-vehicle document at batch size 2 imports 6 of 6, and the vehicle a batch created without fills gains its driving mode |
| 9 | The same document at batch size 1 imports 6 of 6 across six batches |
| 10 | The same document in a single POST still imports 6 of 6 |
| 11 | Re-uploading the whole document reports already-imported for every record and changes no link |
| 12 | A vehicle the owner made by hand through `/apps/rover/add-vehicle` gains the links its imported fills need and keeps its original default energy |
| 13 | Import revives the two links the owner had archived, archives none of the rest, keeps the default energy, and the widened links survive a restart |

Fixture 12 is the sharp case for constraint 2. The owner creates the vehicle
with default energy `Diesel`. The document declares `defaultEnergy` `Gasoline`
and its fills use `Gasoline`. After the import the vehicle carries both links
and the default is still `Diesel`.

Fixture 13 is the sharp case for constraint 1. The owner adds `Diesel` and
`Sport`, then narrows the vehicle through `/apps/rover/edit-vehicle`, which
archives both links. The import needs both again. It clears `archived` on both,
leaves `Gasoline` and `Normal` alone, and archives nothing. The fixture then
counts archived link rows and requires zero.

## Fixture 112 now spans batches

`bin/ui-test.sh` fixture 112 used a single-vehicle document, because that was
the only case the desk supported. It now uses the whole two-vehicle synthetic
document at batch size 2: six fills, three batches, both vehicles created by
batch 1 and both carrying fills in a batch that did not create them. The comment
pointing at `QUESTIONS.md` is gone, and so is the temporary single-vehicle
document the fixture used to build.

Fixtures 114, 115, and 116 follow it onto the same document. Their counts move
from three records to six. Fixture 116 still stops the browser at batch 1 of 3.

```text
ui-test: fixture 112 PASS - a real browser split a two-vehicle six-fill document into three batches, posted them one at a time, and every record landed although both vehicles span batches
ui-test: fixture 114 PASS - re-uploading the same document reported already-imported 6 and wrote nothing
```

## Rover compiles

```text
$ click -k -i probes/compile-rover.hoon ~/piers/rover-widen-bel
[0 %avow 0 %noun 0]
```

## The batteries

All against `~/piers/rover-widen-bel`. Zero FAIL lines in every run.

```text
$ ROVER_DEMO_ONLY=1 bash bin/ui-test.sh ~/piers/rover-widen-bel
ui-test: COVERAGE - all 94 defined fixtures executed
EXIT=0        (99 PASS notes, grep -c FAIL = 0)

$ bash bin/ui-test.sh ~/piers/rover-widen-bel
ui-test: COVERAGE - ran 66 of 94 defined fixtures
EXIT=0        (68 PASS notes, grep -c FAIL = 0; the rest need ROVER_DEMO_ONLY)

$ bash bin/schema-test.sh ~/piers/rover-widen-bel
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed

$ bash bin/import-test.sh ~/piers/rover-widen-bel
import-test: fixture 13 PASS - import revived the two links the owner had archived, archived none of the rest, kept the default energy, and the widened links survived a restart
import-test: COVERAGE - all 13 defined import fixtures executed

$ bash bin/view-performance-test.sh ~/piers/rover-widen-bel
view-performance-test: run 1 - 0.586189s, 279380 bytes, 25 of 420 fills
view-performance-test: run 2 - 0.583054s, 279380 bytes, 25 of 420 fills
view-performance-test: COVERAGE - synthetic 420-fill view stayed within 2.0s

$ bash bin/dev-pin-test.sh ~/piers/rover-widen-bel
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match

$ bash tests/view-linear-test.sh
view-linear-test: PASS - one-pass derivation feeds a bounded newest-first view

$ python3 tools/rover-import/test_upload.py     -> Ran 6 tests, OK
$ python3 tools/acar-import/test_convert.py     -> Ran 18 tests, OK
```

## Restart persistence

Fixture 13 suspends and revives `%rover` after the widening import and compares
the link set before and against after. They are equal.

A separate end-to-end check ran on a fresh disposable database. `|suspend %rover`
then `|revive %rover`, then the same batch size 2 upload.

```text
[0 %avow 0 %noun %restarted]
Aggregate
Fills: imported 6, already-imported 0, conflicts 0, failures 0
EXIT=0
```

## Fences held

- No relation was added. There is no vehicle-level import provenance.
- The wire format is unchanged. `convert.py` still emits what the desk reads.
- `tools/` is unchanged. The CLI was repaired by the desk change alone.
  `test_upload.py` and `test_convert.py` still pass.
- No action was added to the `$action` union. It stays at five arms.
- `docs/schema-m0.sql` is unchanged, and `bin/schema-test.sh` still reports
  68 relations and 75 RESTRICT foreign keys.
- No fixture was weakened or deleted. Fixture 112 got a harder document, not an
  easier one.
- Q5 conflict detection is untouched. Fixture 4 still reports a field-level
  conflict and preserves the original, and fixtures 3, 11, and 114 still report
  already-imported.

## Left open

The second `QUESTIONS.md` finding stays open. One import run still occupies one
Arvo event, and whether the import loop should yield between records is a
separate question.
