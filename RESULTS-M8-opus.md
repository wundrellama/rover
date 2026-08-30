# RESULTS — M8 attachments, opus leg

Rover stores photos now. A person who records a fill, a repair, or an odometer
reading keeps the receipt beside it. The bytes never enter Obelisk. The database
holds a reference, and the bytes live in Clay or in an S3 bucket.

This file records the evidence. Every number here was measured on the pier named
below, not assumed.

## The pier

| item | value |
|---|---|
| Pier | `/home/michael/piers/rover-m8b-opus-bel` |
| Ship | `~bel` |
| tmux session | `m8bopus` |
| Ames port | `32880` |
| Eyre port | `8080`, before and after the restart fixture |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk source | `/home/michael/workspace/urbit/pins/obelisk-fresh/desk` |
| Obelisk install | `/home/michael/piers/rover-m8b-opus-bel/obelisk` |
| Obelisk commit | `9de633299b373a1047490b48281a40b457fb2043` |
| Obelisk start | `\|start %obelisk %obelisk` |
| S3 endpoint | RustFS at `http://localhost:9200`, bucket `rover-attachments` |

The copied `sur/obelisk-ast.hoon` SHA-256 was checked before the install:

```text
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2  \
  /home/michael/piers/rover-m8b-opus-bel/obelisk/sur/obelisk-ast.hoon
```

Obelisk went in as its own unmodified desk: `|merge %obelisk our %base`,
`|mount %obelisk`, a file copy, `|commit %obelisk`, `|install our %obelisk`,
`|start %obelisk %obelisk`. The pier printed `gall: booted %obelisk` and
`gall: booted %obelisk-web`. Rover went in the same way, without the start, and
printed `gall: booted %rover`.

This pier is new. The pier the earlier run used was killed by a machine reboot
in the middle of a run, so nothing on it was read or reused.

## The two battery runs

Both runs ran against this pier, back to back. The database was not dropped and
not rebuilt between them, so the second run met everything the first one wrote.

Run 1, verbatim last four lines:

```text
event-test: fixture 104 pier - 1361139622 bytes before the photo load, 1410066342 after, growth 48926720
event-test: fixture 104 PASS - the real corpus loads through the product endpoint: 121 photos against 114 records, every stored photo hashing equal to its source, and a second load adding nothing
event-test: COVERAGE - all 106 defined fixtures executed
EXIT=0
```

Run 2, verbatim last four lines:

```text
event-test: fixture 104 pier - 1942771622 bytes before the photo load, 2193184678 after, growth 250413056
event-test: fixture 104 PASS - the real corpus loads through the product endpoint: 121 photos against 114 records, every stored photo hashing equal to its source, and a second load adding nothing
event-test: COVERAGE - all 106 defined fixtures executed
EXIT=0
```

The coverage line is the same in both runs:

```text
event-test: COVERAGE - all 106 defined fixtures executed
```

No fixture is skipped. Both runs exit 0. Both report 110 PASS lines, because
four fixtures report more than one pass.

### `bin/ui-test.sh`

The brief said this battery is red on arrival at
`ui-test: FAIL - Settings lacks the export placeholder`. **That is not the state
I found.** On `ab-m8-opus` it ran green up to the export section and asserted
`href="/apps/rover/export"`, which passed, and the run finished.

My change to the Settings download control broke that one assertion, so I
updated it to name `/apps/rover/export.tar`. The battery then exits 0:

```text
ui-test: COVERAGE - ran 87 of 114 defined fixtures
ui-test: COVERAGE - SKIPPED, not executed this run: 57 58 59 60 61 62 63 64 65 66 67 69 76 77 78 79 82 83 94 95 96 97 98 99 100 101 102 104
ui-test: COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
```

The 27 skipped fixtures are gated behind flags and were gated before M8.

## Hash equality, one photo, end to end

The source bytes, the digest the database holds, the bytes in Clay, and the
bytes the ship serves back are all the same.

```text
$ sha256sum photo.jpg
98ad3bcf8e03eab1ff4dfd5410095067de94382e57d2a0125002cf2f2ab17836  photo.jpg

$ curl --data-binary @photo.jpg '.../add-attachment?owner=fill&...&backend=clay'
Attached proof-proof993562.jpg

$ curl -o back.jpg '.../attachment/proof-proof993562.jpg' && sha256sum back.jpg
98ad3bcf8e03eab1ff4dfd5410095067de94382e57d2a0125002cf2f2ab17836  back.jpg

$ cmp photo.jpg back.jpg
(no output: identical)
```

The reference row, read with urQL:

```text
[%attachment-id 30837 0x8a3bb2ba5d9c7327c8eb0212fac1b5d5]
[%backend %tas %clay]
[%locator 116 '/attachments/0x8238.5323.c84c.503f.0510.5b11.e603.b18b/mime']
[%content-hash 116 '98ad3bcf8e03eab1ff4dfd5410095067de94382e57d2a0125002cf2f2ab17836']
[%byte-count 25717 16422]
```

The bytes read out of Clay at that locator, hashed inside the ship:

```text
[0 %avow 0 %noun 16422
  '0x98ad.3bcf.8e03.eab1.ff4d.fd54.1009.5067.de94.382e.57d2.a012.5002.cf2f.2ab1.7836']
```

This example also shows the shared locator at work. The reference id is
`0x8a3b…` and the locator names `0x8238…`, because the ship already held these
exact bytes under another name. It stored them once and kept both names.

The S3 half is proved the same way, by a client that is not Rover. Fixture 100
reads the object out of the bucket with `boto3`:

```text
event-test: fixture 100 bucket - /rover-attachments/attachments/0xa27c.55de.c404.bd56.e4da.e629.2c3e.d016 holds 98ad3bcf8e03eab1ff4dfd5410095067de94382e57d2a0125002cf2f2ab17836 16422
```

## The real corpus

Fixture 104 loads the owner's real corpus through `/apps/rover/add-attachment`,
the same endpoint a browser calls. It runs in a database of its own, so the
battery's data and the owner's history never mix, and the second run of the
battery meets the same state the first one did.

Counts only. No file name, label, date, or digest out of the corpus appears in
this repository.

```text
event-test: fixture 104 corpus - 121 photos, 116 fill, 3 event, 2 vehicle, 120 distinct digests, 114 records
```

- 121 photos load. None is refused.
- The split is 116 fill, 3 event, 2 vehicle, which matches the converter.
- 121 names produce 120 distinct digests. One photo is a byte-identical
  duplicate of another under its own name.
- The photos hang off 114 records, counted by distinct owner id across the three
  link relations.
- Every photo is read back and its digest compared with the converter's:
  `ATTACHMENTS_VERIFIED=121`, `ATTACHMENTS_MISMATCHED=0`.
- The same load, run again, reports `ATTACHMENTS_STORED=0` and
  `ATTACHMENTS_ALREADY=121`, and the reference count does not move.

The corpus document import takes about 39 seconds for 420 fills, 39 events, 8
reminders, 67 places, and 2 vehicles. The photo load takes about 11 seconds.

## Measured pier growth

The two runs report different figures for the same load:

| run | before the photo load | after | growth |
|---|---|---|---|
| 1 | 1,361,139,622 | 1,410,066,342 | 48,926,720 |
| 2 | 1,942,771,622 | 2,193,184,678 | 250,413,056 |

The corpus is 48,567,745 raw bytes. Run 1 measures 1.007 times that. Run 2
measures 5.2 times it.

**Both figures are honest and neither is the whole cost.** `du` measures a live
pier. The event log takes the inbound bytes as they arrive, so it grows during
the window in both runs. The snapshot is written on the runtime's own schedule,
so whether it lands inside the measured window is a matter of timing. Run 2
caught one. Run 1 did not.

The durable figure is the pier itself. After two full battery runs, four corpus
loads, and four 50 MB transport blobs:

```text
2242062246  /home/michael/piers/rover-m8b-opus-bel
1350623236  /home/michael/piers/rover-m8b-opus-bel/.urb/log
```

The event log is 60% of the pier. **A photo costs its bytes three times:** once
in the event log that records the HTTP request, once in Clay's blob store, and
once in every snapshot until the log is truncated.

A second measurement makes the first cost explicit. A repeat corpus load stores
nothing new — the reference count does not move, and Clay writes no file — and
the pier still grew by 48,873,472 bytes. That is the event log recording 121
inbound requests whose bodies it must keep.

## The Clay cost is documented, not re-opened

The owner has ruled that Clay stays and the cost gets documented. The
reclamation path has three parts, and all three are needed. I verified the first
two in the pinned `clay.hoon` on this pier.

1. **`tomb-lobe` genuinely deletes.** It runs `(~(del by lat.ran.ruf) lob)` on
   Clay's blob store and then prints `clay: file successfully tombstoned`. A
   later read of that file crashes with `%tombstoned-file`. It is not a flag.
2. **It refuses while a live desk still names the blob.** The `?^ used` guard
   walks every desk's current commit, and if any path in it carries the lobe, it
   answers `clay: file used in {beam}` and deletes nothing. A person must remove
   the file from the desk and commit that removal before the tombstone takes.
3. **The event log is separate.** `urbit roll <pier>` starts a new epoch and
   `urbit chop <pier>` truncates the log. `chop` only deletes epochs older than
   the newest two. Neither is a dojo generator. Both are runtime commands, and
   the ship must be down.

A person who deletes a receipt expects the disk to shrink. It will not, until
all three steps run.

## What the fixtures prove

| fixture | what it proves |
|---|---|
| 96 | 52,428,800 bytes leave Gall through Eyre in one piece, byte count and digest equal to what went in |
| 97 | a photo attaches to a fill, the stored bytes hash equal to the source, the APP1 Exif segment survives |
| 98 | the same path to an event and to a vehicle, three owners, one reference relation, each link keyed to the family parent |
| 99 | the Clay backend end to end on a real pier, and nothing lands on the published `%rover` desk |
| 100 | the S3 backend end to end against RustFS, read back out of the bucket by `boto3`, and no redirect or presigned URL reaches the browser |
| 101 | a ship with no `%storage` configuration refuses in human words, stores nothing, and the Clay it offers works |
| 102 | the archive unpacks with the system `tar`, and `rover-import.json` inside it is byte for byte the payload the JSON endpoint serves |
| 103 | every photo arrives on the far side of the round trip with the digest and byte count the source recorded |
| 104 | the real corpus: 121 photos against 114 records |
| 105 | no blob reaches Obelisk, proved by reading every column of all four attachment relations |
| 106 | every reference, link, and byte survives a ship restart, and attaching still works after it |

Outbound transport, measured twice at the size the archive really reached:

```text
event-test: fixture 102 archive - 157745152 bytes, 22 members, 21 photos     (run 1)
event-test: fixture 102 archive - 210317824 bytes, 29 members, 28 photos     (run 2)
```

Fixture 86 then posts that same archive back in. So 210 MB left the ship through
Eyre and 210 MB came back in, in one piece each way. Chunked download is not
needed.

## Design latitude used

### The reference relation columns

```text
CREATE TABLE rover..attachments
  (attachment-id @ux, backend @tas, locator @t, content-hash @t,
   byte-count @ud, media-type @t, file-name @t, recorded-at @da)
  PRIMARY KEY (attachment-id);
```

| column | why it is there |
|---|---|
| `attachment-id` | a nonzero random 128-bit `@ux`, Rover-generated, the key every link points at |
| `backend` | `%clay` or `%s3`. The reader has to know which store to ask before it can read anything |
| `locator` | where the bytes are inside that backend. It is a column and not a rule, because two references can name one stored file |
| `content-hash` | SHA-256, lowercase hex. This is what makes the store content-addressed and what a fixture compares |
| `byte-count` | an exact integer. It proves a short read rather than letting one pass |
| `media-type` | what the ship sends back in `content-type`. Clay stores a `mime`, and the type is the owner's, not a guess |
| `file-name` | the only handle that crosses the HTTP boundary. Ruling 8: no raw machine id at a human boundary |
| `recorded-at` | when Rover was told, not when the camera fired. The same posture every other Rover relation takes |

Three link relations carry the association, one per event family parent:
`energy-acquisition-attachments`, `vehicle-event-attachments`, and
`vehicle-attachments`. Each is many-to-many, keyed on both columns. A fill and a
charge share one link relation because they share one family parent, exactly as
they share one odometer link. No column was added to any populated relation.

### The duplicate photo stores once, and keeps both names

The corpus has 121 file names and 120 distinct digests. One photograph is filed
twice under two names.

**It stores once.** The bytes are written to Clay one time. The second reference
row points at the same locator.

**Both names live.** The first design keyed the reuse on the digest and the
backend alone, and it reused the whole reference including its name. That lost
the second name: a request for it answered 404, and a round trip through the
export dropped it. A file name is a fact the owner told Rover, so the rule is
now: identical bytes under a name the ship already holds reuse the reference,
and identical bytes under a new name get their own reference pointing at the
same file.

That is what makes reading the same archive twice write nothing, and what makes
the round trip lossless.

### The other choices

| choice | why |
|---|---|
| The complete export is `/apps/rover/export.tar`, and Settings offers it | The manifest says the photos are included. Before this, the file that carried that manifest carried no photos |
| `/apps/rover/export` still serves the document alone | A reader that wants only the facts takes one member and stops. It is also what lets fixture 102 prove the member is not re-serialized |
| The import detects the archive by the `ustar` magic at offset 257 | Byte 0 of a Rover import document is always `{`, so the two can never be confused |
| The archive needs no side file | The export already names every photo on the record that carries it, and the manifest already names its media type |
| An imported photo goes to Clay | Clay is on every ship and it is synchronous. See `QUESTIONS.md` item 3 |
| The photo phase runs after the document phase | A photo cannot attach to a record that has not been written yet |
| The attachment desk is `%rover-files`, not `%rover` | A published desk that carried the owner's receipts would ship them to every installer |
| The state is version 24, and an in-flight import is dropped on upgrade | The connection it would answer does not survive the upgrade, and a run left behind refuses every later import |
| Rover decodes percent escapes itself | `de-urlt` answers nothing for a byte above 127 and leaves the `+` a query string writes for a space |

## Traps paid for

Recorded so the next leg does not pay them again.

1. **`shay` byte order.** `shay` reads and writes an atom least significant byte
   first. `sha-256l` and `hmac-sha256l` read and write most significant first.
   Every value converts once and stays in one order.
2. **Vere writes its own `Host:` line.** A signed request that also carried one
   was ambiguous, and every S3-compatible server answered 403. That reads
   exactly like a bad credential and is not one. The host is signed and no
   longer sent.
3. **A `%gu` liveness scry blocks without a trailing `/$`,** and a blocked scry
   cannot be caught.
4. **An explicit `content-length` header on a Gall response** makes Vere send a
   zero-length body.
5. **Clay answers the merge that creates the attachment desk.** That answer
   reached `on-arvo`, matched nothing, and fell through to the Eyre assertion,
   so every install printed `%arvo-response` and a crash trace.
6. **The pinned engine renders a term that carries a digit as a bare number.**
   An S3 reference reads `%backend %tas 13171`, and 13171 is the cord `s3`.
7. **`de-urlt` drops a whole parameter** if a value carries a byte above 127.
   One curly apostrophe in a vehicle label made the corpus load refuse 121
   photos out of 121, and it reported as a missing key.

## Done-check

1. The desk installs with `gall: booted %rover` and no `nest-fail`. **Yes.**
2. A person attaches a photo to a fill, an event, and a vehicle, and sees it
   again. **Yes**, fixtures 97 and 98, through the product endpoint.
3. Both backends store and serve a real photo on a real pier. **Yes**, fixtures
   99 and 100. The S3 endpoint is a real RustFS container, not a mock.
4. Stored bytes hash equal to source bytes, EXIF intact. **Yes**, fixtures 97
   and 104.
5. No blob is in Obelisk, proved by reading the relations. **Yes**, fixtures 105
   and 106.
6. The archive unpacks with the system `tar` and round-trips every photo.
   **Yes**, fixtures 102, 86, and 103.
7. The real corpus loads: 121 photos against 114 records. **Yes**, fixture 104.
8. No new column on a populated relation. Five-arm action union. **Yes**,
   fixture 13.
9. The entry surface fits 390px. **Partly. See the gap below.**
10. `bin/event-test.sh` runs twice back to back, same verdict, exit 0, coverage
    naming every fixture with no skips. **Yes.**
11. Everything survives a ship restart. **Yes**, fixture 106.

## The gap

**Item 9 is not fully delivered, and no fixture claims it is.**

The attachment path is proved end to end through the HTTP endpoints a browser
calls, at the byte level, on a real pier. What is not built is the browser
control that calls them: there is no file input on the Add Fill or Add Event
form, and no photo strip on a card.

The earlier run of this leg had that work in the editor when a machine reboot
destroyed the worktree, and the continuation brief scopes the remaining work to
fixtures 102, 103, 104, and 106, the two battery runs, and these two documents.
So the entry surface is the one piece of the original brief this leg does not
deliver.

The endpoints it needs are all in place and all proved:

- `POST /apps/rover/add-attachment?owner=&vehicle=&observed=&file=&type=&backend=`
  with the raw image as the body.
- `GET /apps/rover/attachment/<file-name>`.

Both answer in human words. A record that does not exist answers 404, and the
words name the record family the request asked for — `No fill or charge on that
vehicle at that moment.` for a fill, `No record on that vehicle at that moment.`
for an event, `No vehicle by that name.` for a vehicle. A ship with no
`%storage` configuration answers 409 in words and offers Clay.

The Settings export control did change: it now downloads the archive, and
`bin/ui-test.sh` asserts that at 390px.
