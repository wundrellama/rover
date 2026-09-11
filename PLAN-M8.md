# PLAN-M8.md — Attachments

Status: ratified 2026-08-22. **Complete 2026-08-31 at `c006bac`.**

Rover stores receipt and odometer photographs now. The bytes never enter
Obelisk. The database holds a reference, and the file lives in the ship's own
Clay or in an S3-compatible bucket. The owner picks, and both are real.

M8 ran as one campaign rather than a task list. Two legs began it, one on each
model, from a byte-identical frozen brief. Three further legs carried it to
green. The work is grouped below by what it delivered.

| | Delivered | Landed |
|---|---|---|
| 1 | Attachment reference relations, Clay backend, outbound transport proved | `4de9814` |
| 2 | S3 backend, AWS4 signed on the ship and proxied through it | `8df5158` |
| 3 | The export carries the bytes, and the store is content-addressed | `9bc3dda` |
| 4 | Clay answers the attachment desk's two wires | `14c3f8d` |
| 5 | The import takes the archive back, and a file name is never lost | `1a42cb6` |
| 6 | The real corpus loads, and the query string survives the owner's data | `e369355` |
| 7 | `%storage` reads by key, and each export manifest tells its own truth | `a71d19c` |
| 8 | The entry surface: a file input on both forms, the photo on the card | `016b1a7` |
| 9 | The import asks which backend, once, for the whole batch | `000e4bd` |
| 10 | An S3 import answers the browser, because the run survives Obelisk's kick | `02ab642` |
| 11 | Fixtures 114 and 115, the second restart and the batch refusal | `d837675` |

Every claim was verified by the owner running `bin/event-test.sh` rather than by
reading a leg's report. The final state is 115 fixtures, twice back to back on
one pier, exit 0 both times, every fixture executed and none skipped. The
battery was run once more from the merged master checkout, with the same result.

The rulings the milestone produced are 17's amendment and 23 through 27 in
`app-structure.md`.

## What shipped

**Two backends, both real.** Clay writes to a `%rover-files` desk, never to the
published `%rover` desk. S3 signs AWS Signature Version 4 in Hoon, verified
against a real RustFS endpoint, and the ship proxies every byte. No presigned
URL reaches the browser, because those expire and carry a credential into any
file the owner saves.

**The owner's corpus loads.** 121 photographs against 114 records, every stored
file hashing equal to its source. EXIF survives byte for byte, per ruling 17:
the stripping rule governs publication, not a person's own storage.

**The export carries the bytes.** `/apps/rover/export.tar` is one uncompressed
tar holding the import document and every photograph, and Rover's own import
reads it back. `/apps/rover/export` still serves the document alone, and each
manifest now says which one the reader is holding.

**The entry surface.** A file input on Add Fill and on Add Event, the photograph
on the record's card in History, and the import's backend control. All at 390px.

## Why tar

Measured on 121 JPEG-incompressible files at real corpus size:

| Format | Bytes | Versus raw |
|---|---|---|
| tar | 49,633,280 | 100.1% |
| tar.gz | 49,588,932 | 100.1% |
| zip store | 49,586,101 | 100.0% |
| zip deflate | 49,593,966 | 100.1% |
| 7z lzma | 49,565,913 | 100.0% |

Compression buys nothing on photographs, so the container is chosen for how
simply Rover can write and read it. The pinned zuse has no zip, gzip, deflate,
or tar arm, so any container is written by hand. Tar is the smallest one to
write: one 512-byte header per file, every numeric field ASCII octal, an
integrity field that is a sum of the header bytes, and no central directory to
parse backward.

Hoon has no octal renderer. `scot` handles `%ud`, `%ux`, and `%uv` only. The
render is a div-and-mod loop.

## The rulings that changed the work

Four questions were filed by the first leg and ruled by the owner on 2026-08-30.
**Three of the four overturned what had been built**, which is the campaign's
argument for filing questions rather than deciding them.

1. **`%storage` is read by key through a `/json` scry**, not by position and not
   by copying the mold. `current-bucket` and `region` sit side by side in
   Landscape's configuration and both are `@t`, so a reordering upstream would
   have kept the arity and the shape the old guard tested, and Rover would have
   signed every request against a bucket named `us-east-1`.
2. **A file name is a fact.** Identical bytes under a new name get their own
   reference row pointing at the same stored file. The corpus holds 121 names
   against 120 digests, so the first design lost one.
3. **The import asks which backend**, once, for the whole batch. A Clay default
   on an S3 ship would have cost 121 re-attachments and a three-step
   reclamation to undo.
4. **Both export endpoints stay, and both tell the truth.** The document's
   manifest says the photographs are not included and names the archive that
   carries them.

## The defect fixture 111 caught

An S3 import hung until Eyre gave up. A Clay import of the same archive answered
in about nine seconds.

**Obelisk closes a `/server` subscription as soon as it has answered**, so a
kick arrives after every query and carries no news. Two import arms read that
routine kick as the death of the run and cleared `import-run`, discarding the
`eyre-id` of the person waiting along with the remaining photographs and the
report. A Clay import finishes inside the same move cascade the kicks unwind
behind and never noticed. An S3 import parks on the bucket, the kick lands
first, and the answer had nowhere to go.

Three theories were tested and killed before this one: the `%storage` scry
blocking, the S3 credentials, and a missing `http-pending` registration. The
diagnosis came from `|verb` with `tmux pipe-pane`.

The finding is recorded in the `obelisk-substrate` skill, at
`references/server-kick-is-not-a-failure.md`. It will bite any agent that parks
on an async step between an Obelisk answer and an external response.

## Open, and deliberately not built

`QUESTIONS.md` carries eight entries. Two came out of this milestone's end and
are now ruled but unbuilt:

- **Ruling 26** — `on-load` clears every in-flight run flag. A killed process
  currently wedges the export and import endpoints until the agent is
  reinstalled.
- **Ruling 27** — a Behn stall timer beside each outbound S3 request, re-armed
  on every `%progress`, failing one photograph if it fires. Iris has no timeout
  of its own.

Both are small and neither blocks M8. They are the first candidates for M9.

Also still fenced: sharing and the second pour, the remote protocol, trip
records, the community corpus, EVSE inventory, leases, and vehicle parts.
