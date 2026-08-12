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
