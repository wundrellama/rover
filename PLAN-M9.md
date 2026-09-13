# M9 — in progress

Opened 2026-09-12 from a completed M8 at `1674f25`.

## Scope

M9 was scoped as debt (rulings 26 and 27), a bounded JSON read API, and one
converted page. The first real-corpus import displaced that order: reading the
owner's own 420 fills through the app found three defects the battery could not
see, and those were repaired first. The read API has not started.

## What landed

| | Delivered | Commit |
|---|---|---|
| 1 | The import is one file, and the browser unpacks it | `5357b88` |
| 2 | A history fill card shows its mileage and derives its economy | `0095917` |
| 3 | A photograph can reach a record that already exists | `cc57001` |
| 4 | Fixture 116 asserts all three | `ccd0b03`, `ed48b5c` |

`bin/event-test.sh` holds **116 fixtures**, green twice back to back on one
pier, exit 0 both times, coverage gate reporting every fixture executed and none
skipped.

## Ratified this milestone

Ruling 28 and two findings, recorded in `~/brain/projects/rover/app-structure.md`.

- **A bridge is a moon of the owner's own planet**, reaching Rover over Ames.
  Rover stores no key and no token.
- **Bridge authorization is the second pour.** Ruling 25 warned that the answer
  must not become the sharing protocol by accident. That framing is wrong: a
  list of ships permitted to touch an owner's data *is* a grant list, and read
  or write is a column on it. There was never an answer outside sharing.
- **Ruling 26's premise about restarts is false.** `on-load` does not run when a
  pier stops and starts. Measured with a marker that printed on commit, printed
  again after the marker text changed, and printed zero times across a full cold
  start while the agent answered 200.

## The finding that cost the most to learn

Three defects shipped on one screen and 115 fixtures were green over all of
them. A fixture that asserts on rendered output cannot see a field that was
never written; the inverted economy branch is briefly true on a small corpus,
because a fresh database really has no earlier eligible fill; and a second
renderer for the same record showed the mileage correctly, so the obvious check
passed.

Fixture 116 is written against that: it states the arithmetic — 300 miles on
15.000 gallons is 20 mpg — and requires the card to match, rather than accepting
whatever the renderer prints.

## Published

`%rover` is installed and published on `~hilpem-hocryt-dinnyt-divsud` at
`ccd0b03`, whose desk is byte-identical to `ed48b5c`. Obelisk on that ship was
verified file by file against the pin. The database auto-provisioned on install
with 105 relations, so a fresh remote install needs no dojo command.

**`%noun [%add %desk]` is not enough to publish.** It sets `sovereign` and
returns success while leaving the alliance untouched, so nothing advertises the
desk. `%alliance-update-0` with `[%add our %desk]` sets both. The alliance scry
is what proves it; the poke's own answer does not.

## Not done

- The bounded JSON read routes, which were M9's stated body.
- Rulings 26 and 27 remain unbuilt. Ruling 26 is one term on
  `desk/app/rover.hoon:2052` plus a fixture that must reinstall rather than
  restart.
- Removing a photograph from a record. Adding works; removal needs a delete path
  that does not exist, and Clay reclamation is three steps.
- The rendered page on the publish moon has never been fetched. The agent is
  live, the docket is charged, the schema poured, and the auth fence refuses
  anonymous requests, but the HTML itself is unverified.

## M9 T-PRESIGN record — 2026-09-13

Ruling 29 and its locator amendment are complete. The ship issues a presigned
PUT URL, the browser uploads to S3, and the browser records the reference only
after HTTP 200. The URL expires after 300 seconds, signs `host` alone, and uses
`UNSIGNED-PAYLOAD`. Both signing paths use the existing SigV4 chain. The S3
secret stays on the ship.

S3 keys now use `attachments/<SHA-256>`. The stored locator contains no signed
query. Deduplication rejects an old locator shape and creates a new reference.
The guard applies to browser records, legacy uploads, and archive imports.

`/apps/rover/attachment-url` and `/apps/rover/record-attachment` accept metadata
and reject bodies. Both require owner
authentication, validate the metadata, resolve the record, and return 409 when
S3 is unconfigured. `/record-attachment` makes no S3 request.

Forms and archive imports use one browser upload helper. S3 record photos
render from the public object URL. Clay uploads and reads still use the ship.
Every backend control discloses public reads before selection and names Clay
as the choice for private photos. An unfamiliar bucket status now appears in
the refusal text.

Both complete foreground runs used clean commit `764e4de` on the disposable
`~bel` pier under this worktree's `.scratch/`. The pier uses
`brass-408k-1.pill`, standalone Obelisk `9de6332`, and the real RustFS bucket at
`http://localhost:9200`. Checksums confirmed that both mounted desks matched
their source trees. The Obelisk AST still matches the pinned SHA-256.

| Run | Exit | Distinct fixtures | Failures | Skips |
| --- | --- | --- | --- | --- |
| 1 | 0 | 121 | 0 | 0 |
| 2 | 0 | 121 | 0 | 0 |

Each run executed all 116 original fixtures and all five additions. Both
coverage lines state: `all 121 defined fixtures executed, no skips`.

- Fixture 100 uploaded 16,422 bytes with the presigned URL. Public GET and the
  ship proxy returned the same bytes. An independent client read the bucket.
- Fixture 117 found no signature in the stored locator. Metadata routes
  rejected bodies, invalid hashes, absent owners, and unauthenticated requests.
- Fixture 118 received HTTP 504 through Iris and named 504 in the refusal.
  No reference followed the refused upload.
- Fixture 119 assigned an old S3 locator to a stored row on real Obelisk.
  Recording the same photo again created a new reference with the content-hash
  locator.
- Fixtures 120 and 121 proved browser uploads from forms and archives.
  Metadata requests carried no bytes. A refused browser PUT recorded no
  reference. S3 and Clay photos rendered at 24 by 24 pixels within 390 pixels.

Fixtures 111 and 114 passed in both runs. Imports honored the chosen backend,
and photos in both stores survived the second restart. Each real-corpus pass
verified 121 photos on 114 records, with 120 distinct digests. Repeating that
load added nothing. Neither complete log contains a real VIN or plate.

The battery now preserves spaces in manifest names and scopes browser photo
checks to their vehicle. Converter output may use the ignored `.scratch/`
directory, while other repository paths remain blocked. All 23 converter tests
pass there. The coverage gate exits 1 when a defined fixture is absent.

Logs, hashes, and result JSON remain in `.scratch/battery-run1.log`,
`.scratch/battery-run2.log`, `.scratch/battery-manifest.json`, and
`.scratch/battery-results.json`.

This change adds no migration, rekey on read, compatibility branch, or delete
path. Export still reads bytes through the ship. Rulings 26 and 27 remain
unbuilt. The shipping action union still has five arms. The schema has no new
relation or column. The sharing fence remains closed.
