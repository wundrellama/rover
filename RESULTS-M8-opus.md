# RESULTS — M8 attachments, opus leg

Rover stores photos now. A person who records a fill, a repair, or an odometer
reading keeps the receipt beside it. The bytes never enter Obelisk. The database
holds a reference, and the bytes live in Clay or in an S3 bucket.

This file records the evidence. Every number here was measured on the pier named
below, not assumed.

The fix leg, on 2026-08-31, repaired the one path that did not answer: an import
that carried a photograph and named S3. That work is in **The defect the fix leg
repaired** and in **Which of the two fix shapes, and why**. Everything else in
this file is the earlier legs' evidence, re-measured on the new pier.

## The pier

| item | value |
|---|---|
| Pier | `/home/michael/piers/rover-m8e-opus-bel` |
| Ship | `~bel` |
| tmux session | `m8eopus` |
| Ames port | `32910` |
| Eyre port | `8083`, before and after both restart fixtures |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk source | `/home/michael/workspace/urbit/pins/obelisk-fresh/desk` |
| Obelisk install | `/home/michael/piers/rover-m8e-opus-bel/obelisk` |
| Obelisk commit | `9de633299b373a1047490b48281a40b457fb2043` |
| Obelisk start | `\|start %obelisk %obelisk` |
| S3 endpoint | RustFS at `http://localhost:9200`, bucket `rover-attachments` |

The copied `sur/obelisk-ast.hoon` SHA-256 was checked before the install:

```text
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2  \
  /home/michael/workspace/urbit/pins/obelisk-fresh/desk/sur/obelisk-ast.hoon
```

Obelisk went in as its own unmodified desk: `|merge %obelisk our %base`,
`|mount %obelisk`, a file copy, `|commit %obelisk`, `|install our %obelisk`,
`|start %obelisk %obelisk`. The pier printed `gall: booted %obelisk` and
`gall: booted %obelisk-web`. Rover went in the same way, without the start, and
printed `gall: booted %rover`. No `nest-fail` appeared in either install.

The brass pill carries a `%landscape` desk, so `%storage` needed no source of
its own. `|install our %landscape` and `|start %landscape %storage` were
enough. `%storage` was then pointed at RustFS with six pokes of
`%storage-action`: `%set-endpoint`, `%set-access-key-id`,
`%set-secret-access-key`, `%add-bucket`, `%set-current-bucket`, and
`%set-region`. The `/json` scry then answered every key
`++storage-configuration` reads.

### Why this pier is the fifth

The fix leg was told to build a new one, and it did. Nothing was read from
`~/piers/rover-m8d-opus-bel` or from any earlier `rover-m8*` pier. The defect
this leg repairs is a state defect, so a pier that had already met it would
prove nothing.

The fourth pier was itself a replacement. `~/piers/rover-m8c-opus-bel` is
poisoned: fixture 84 failed on it because `GET /apps/rover/export.tar` answered
409 and the words "An export is already running". The run flag `export-run.sat`
was set when a previous process was killed in the middle of an export, and
nothing cleared it. The guard did its job over state that is no longer true.

The stale flag is a design question, not a defect this leg fixes. It is filed
as item 7 in `QUESTIONS.md`, and the fix leg made it sharper. See item 8.

## The defect the fix leg repaired

An import archive that carried a photograph and named `backend=s3` never
answered. The browser tab waited until Eyre gave up, and the battery reported:

```text
event-test: FAIL - fixture 111 the S3 import was refused: gateway timeout
504
```

The fault was reproduced on this pier before anything was changed.

### What the trace showed

The brief located the fault in `on-arvo` and offered two shapes for the fix. It
also asked for the reason the S3 branch never reaches the completion path a
Clay import reaches. The reason was measured, not deduced. `|verb` was turned
on, the pane was piped to a file, and one S3 import was posted by hand.

Three facts came out of that trace, and they are the whole story.

1. **The PUT goes out.** The trace carries
   `%pass [%gall %i] [%request /use/rover/.../rover-import-photo-s3-put/211]`.
2. **The bucket takes the bytes and Iris answers.** RustFS holds the object.
   Six seconds after the import was posted the trace carries
   `["" %unix %receive /i/http-client/0v6.tg04s ~2026.08.31..01.44.09..3807]`
   and then
   `%give %iris %http-response i=/gall/use/rover/.../rover-import-photo-s3-put/211`.
   The browser waited 90 more seconds and got nothing.
3. **Between the two, Obelisk kicks.** Immediately after the PUT card, the
   trace carries
   `%give %gall [%unto %kick] i=.../rover-import-photo-lookup/211`.

Rover gave no cards at all for the Iris response. The bytes were in the bucket,
the answer was in hand, and nothing was sent.

### The cause

Obelisk closes a `/server` subscription as soon as it has answered the query on
it. Rover subscribes once per command and never leaves, so a kick arrives for
every query the import makes. The kick is the ordinary end of one query and
carries no news.

The two photo arms of `on-agent` read it as the death of the run:

```hoon
    %kick
  `this(import-run ~)
```

`import-run` is the one place that holds the eyre-id of the person waiting, the
photographs that are left, and the report. The kick threw all three away.

**A Clay import never showed the fault.** It finishes inside one move cascade,
and the kicks unwind behind it. By the time a kick lands, the browser already
has its 200 and `import-run` is empty on purpose. **An S3 import stops on the
bucket.** The cascade unwinds, the kick lands first, and when Iris answers,
`on-arvo` finds no run:

```hoon
    =/  run-unit  import-run
    ?~  run-unit
      `this(state bare)
```

That is the silent drop. It is one line, and it is the whole 504.

Every other import arm — `rover-import-lookup`, `rover-import-comparison`,
`rover-import-comparison-tail`, `rover-import-support`, `rover-import-write` —
already ignores the kick. Only the two photo arms did not. The attach path
survives for a different reason: it moves its `http-pending` and
`attachment-pending` entries onto the put-wire before the PUT goes out, and its
kick handler deletes by the lookup wire, which is a key that is already gone.

### The fix

The two photo arms now ignore the kick, as the other five do. `import-run`
stays the one place the answer lives, and `continue-import` reads `eyre-id.run`
at the end of the batch, the way the Clay path already did.

One thing was added beside it. `on-arvo` used to wait for `%finished` and
answer nothing for any other response shape, so a request the runtime gave up
on left the run parked forever. A response that is not `%progress` and not
`%finished` now reads as status zero, which `s3-refusal` already says in words.
That fails one photograph, names it in the report, and answers the request.

The Clay import path is untouched. `desk/app/rover.hoon` is the only file the
fix changes, and the change is 20 lines added and 4 removed.

## The two battery runs

Both runs ran against this pier, back to back. The database was not dropped and
not rebuilt between them, so the second run met everything the first one wrote.

Run 1, verbatim, from the fixture that used to time out to the end:

```text
event-test: fixture 111 backends - IMPORT_BACKENDS=clay,s3, bucket 5eaf2c2650d2440f065d4b5491ece2f28c7896ed87ff432ccff606db8c4e35f8 138
event-test: fixture 111 PASS - the import asks once which backend to use, refuses an archive of photos that names none, and both choices land the photo in the store the owner named
event-test: fixture 112 reason - This ship has no S3 storage set up yet. Open the Landscape storage settings to point it at a bucket. Until then Rover stores photos on the ship itself.
event-test: fixture 112 PASS - a ship with no %storage configuration offers Clay only on the import screen, says why in human words, and the endpoint refuses the S3 choice the same way
event-test: fixture 115 batch - three imported and read back out of the bucket, two refused and named
event-test: fixture 115 PASS - a three-photograph S3 import answers once, after the last one, a bucket that refuses fails every photograph it refuses and still answers the request, and the run that follows a refusal still works
event-test: fixture 114 restart - 33 references, MEMBERS=34 PHOTOS=33
event-test: fixture 114 PASS - every imported photograph, both backends, the archive and its manifest survived a second ship restart, and an S3 import still answers after it
event-test: fixture 104 corpus - 121 photos, 116 fill, 3 event, 2 vehicle, 120 distinct digests, 114 records
event-test: fixture 104 pier - 1626720193 bytes before the photo load, 1675642817 after, growth 48922624
event-test: fixture 104 PASS - the real corpus loads through the product endpoint: 121 photos against 114 records, every stored photo hashing equal to its source, and a second load adding nothing
event-test: COVERAGE - all 115 defined fixtures executed
EXIT=0
```

Run 2, the same span, verbatim:

```text
event-test: fixture 111 backends - IMPORT_BACKENDS=clay,s3, bucket 5eaf2c2650d2440f065d4b5491ece2f28c7896ed87ff432ccff606db8c4e35f8 138
event-test: fixture 111 PASS - the import asks once which backend to use, refuses an archive of photos that names none, and both choices land the photo in the store the owner named
event-test: fixture 112 reason - This ship has no S3 storage set up yet. Open the Landscape storage settings to point it at a bucket. Until then Rover stores photos on the ship itself.
event-test: fixture 112 PASS - a ship with no %storage configuration offers Clay only on the import screen, says why in human words, and the endpoint refuses the S3 choice the same way
event-test: fixture 115 batch - three imported and read back out of the bucket, two refused and named
event-test: fixture 115 PASS - a three-photograph S3 import answers once, after the last one, a bucket that refuses fails every photograph it refuses and still answers the request, and the run that follows a refusal still works
event-test: fixture 114 restart - 42 references, MEMBERS=43 PHOTOS=42
event-test: fixture 114 PASS - every imported photograph, both backends, the archive and its manifest survived a second ship restart, and an S3 import still answers after it
event-test: fixture 104 corpus - 121 photos, 116 fill, 3 event, 2 vehicle, 120 distinct digests, 114 records
event-test: fixture 104 pier - 2412873665 bytes before the photo load, 2461796289 after, growth 48922624
event-test: fixture 104 PASS - the real corpus loads through the product endpoint: 121 photos against 114 records, every stored photo hashing equal to its source, and a second load adding nothing
event-test: COVERAGE - all 115 defined fixtures executed
EXIT=0
```

The coverage line is the same in both runs:

```text
event-test: COVERAGE - all 115 defined fixtures executed
```

No fixture is skipped. Both runs exit 0. Both report 119 PASS lines, because
four fixtures report more than one pass.

The reference count in fixture 114 moves between the runs, from 33 to 42,
because the second run met everything the first one wrote. The count is read
from the relation on both sides of the restart, and it is equal on both sides
within each run. That is what the fixture asserts.

The full logs are `.scratch/final-run1.log` and `.scratch/final-run2.log` on the
machine that ran them. `.scratch/` is not in the repository.

### The failing run, before the fix

The same battery, on the same pier, with the same fixtures, before
`desk/app/rover.hoon` changed:

```text
event-test: fixture 103 PASS - the archive imports into the database fixture 86 filled, every photo arrives with the digest and byte count the source recorded, the four attachment relation counts are equal, and re-reading the same archive writes no second record
event-test: FAIL - fixture 111 the S3 import was refused: gateway timeout
504
EXIT=1
```

### What each import costs

Measured on this pier with one archive of 92 KB carrying one photograph, timed
end to end, including the login the measuring script does first.

| import | wall time |
|---|---|
| Clay | 8.1 s |
| S3 | 8.4 s |

Both report `Photos: imported 1, already-imported 0, failures 0` and answer
200. The Clay import is where it was. The S3 import costs one bucket round trip
more, and that round trip is 0.3 seconds against a bucket on this machine.

### `bin/ui-test.sh`

Run on this pier after both event-battery runs. It exits 0:

```text
ui-test: COVERAGE - ran 87 of 114 defined fixtures
ui-test: COVERAGE - SKIPPED, not executed this run: 57 58 59 60 61 62 63 64 65 66 67 69 76 77 78 79 82 83 94 95 96 97 98 99 100 101 102 104
ui-test: COVERAGE - gated fixtures need their flag, e.g. ROVER_DEMO_ONLY=1 bin/ui-test.sh <pier>
```

The 27 skipped fixtures are gated behind flags and were gated before M8.

**It was red on arrival, and the fix leg repaired it.** Fixture 112 failed with
`IMPORT_POSTS=0`. The import itself worked, and the page reported all six
fills, but the counter saw none of the three posts. The import screen names the
backend in the query string now, so the browser posts to
`/apps/rover/import?backend=clay`, and both counters in
`bin/ui-browser-fixtures.cjs` matched with `endsWith('/apps/rover/import')`.

The match is on the URL path now. This mattered in both directions. A counter
that always reads zero fails the fixtures that want three, and it also passes
the fixtures that want zero for the wrong reason, so a client-side refusal that
did send something would have looked clean.

The Settings download control assertion is unchanged from the earlier leg. It
names `/apps/rover/export.tar` and it passes.

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

The two runs on this pier report the same figure for the same load:

| run | before the photo load | after | growth |
|---|---|---|---|
| 1 | 1,626,720,193 | 1,675,642,817 | 48,922,624 |
| 2 | 2,412,873,665 | 2,461,796,289 | 48,922,624 |

The corpus is 48,567,745 raw bytes. Both runs measure 1.007 times that.

**Neither figure is the whole cost.** `du` measures a live pier. The event log
takes the inbound bytes as they arrive, so it grows inside the measured window
every time. The snapshot is written on the runtime's own schedule, so whether
it lands inside the window is a matter of timing. On the earlier pier one run
caught a snapshot and read 250,413,056 for the same load. On this pier neither
run caught one, which is why the two figures agree to the byte.

The durable figure is the pier itself. Four battery runs met this pier. Two of
them stopped at fixture 111 and 115, before the corpus. The two that finished
loaded the corpus twice each, and every one of the four sent a 50 MB transport
blob through Eyre. After all four:

```text
2510858177  /home/michael/piers/rover-m8e-opus-bel
1533997060  /home/michael/piers/rover-m8e-opus-bel/.urb/log
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
| 111 | the import asks which backend once for the whole batch, refuses an archive of photographs that names none, and both choices land the photograph in the store the owner named |
| 115 | a three-photograph S3 import answers once, after the last one, and a bucket that refuses fails every photograph it refuses and still answers the request |
| 114 | every imported photograph, both backends, the archive and its manifest survive a SECOND ship restart, and an S3 import still answers after it |

Outbound transport, measured twice at the size the archive really reached:

```text
event-test: fixture 102 archive - 157745152 bytes, 22 members, 21 photos     (run 1)
event-test: fixture 102 archive - 210317824 bytes, 29 members, 28 photos     (run 2)
```

Fixture 86 then posts that same archive back in. So 210 MB left the ship through
Eyre and 210 MB came back in, in one piece each way. Chunked download is not
needed.

## Design latitude used

### Which of the two fix shapes, and why

The brief offered two.

1. Register `http-pending` for the put-wire, mirroring the attach path.
2. Read `eyre-id.run` at completion, and route the handler into the completion
   arm the Clay path uses.

**Shape 2 was taken.** Two reasons, and the second is the deciding one.

The first is the rule the brief names: one fact in one place. `import-run`
already carries the eyre-id, and `continue-import` already reads it at line
1203. A second copy of the same identifier in `http-pending` is a second thing
to keep true.

The second reason is that **shape 1 does not fix this defect.** The kick
destroys the whole run, not the eyre-id alone. An `http-pending` entry survives
the kick, so `on-arvo` could answer the browser — but with what? The remaining
photographs, the report, and the reference the run was about to write all went
with `import-run`. The answer would be a 200 carrying a report that never
counted the photograph, or a 500 for a photograph the bucket accepted. A ship
that says the wrong thing quickly is worse than one that says nothing slowly.

Shape 2 keeps the run alive, so the completion arm has something true to say.

The brief said shape 2 "looks right" and told me not to take that as settled. I
read both paths, traced the failure on a live pier, and the trace is what
decided it. The mechanism the brief inferred — that nothing maps the wire back
to an eyre-id — is right about the effect and not about the cause. Nothing maps
the wire back because the map was thrown away, not because it was never made.

### What the fix does not change

- The Clay import path. Not one line, and fixture 111 proves it still answers.
- The attach path. Not one line, and fixtures 100 and 106 prove it.
- The `$action` union. Still five arms, and fixture 13 proves it.
- The schema. No relation, no column.

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
8. **Obelisk kicks every `/server` subscription as soon as it answers.** Rover
   subscribes once per command and never leaves, so a kick arrives for each one.
   A handler that reads the kick as a failure destroys work that is still alive.
   A synchronous run never shows it, because the kicks unwind behind the answer.
   A run that parks on a round trip shows it every time. This cost the fix leg
   the whole 504.
9. **A pane that is 41 lines long hides the evidence.** The battery restarts the
   pier, and a new tmux session starts with empty scrollback. Use
   `tmux pipe-pane -o -t <session> 'cat >> <file>'` before turning `|verb` on,
   or the trace is gone by the time you look for it.
10. **`ls` on this machine is `eza`.** `ls -t` fails with
    `invalid value '...' for '--time <FIELD>'`. Use `command ls -t`.
11. **The brass pill already carries a `%landscape` desk**, so a new pier needs
    no source for `%storage`. `|install our %landscape` and
    `|start %landscape %storage` are enough.
12. **`%.y` prints as `0`.** A `%gu` liveness scry that answers `0` means the
    agent IS running. Reading it the other way costs an hour.

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
9. The entry surface fits 390px. **Yes**, fixtures 107 through 110.
10. `bin/event-test.sh` runs twice back to back, same verdict, exit 0, coverage
    naming every fixture with no skips. **Yes.**
11. Everything survives a ship restart. **Yes**, fixtures 106 and 114. Fixture
    114 is a second restart, taken after the imports and the archive endpoints
    have run, so it reads the state they left.
12. An S3 import answers the browser. **Yes**, fixtures 111, 115, and 114.
13. A multi-photograph S3 import answers once, after the last one. **Yes**,
    fixture 115.
14. A bucket refusal fails the photograph and still answers the request.
    **Yes**, fixture 115.
15. The Clay import still answers in about nine seconds. **Yes**, fixture 111
    passes its Clay half on both runs, and the fix touches no Clay line.

## The gap is closed

The earlier run of this leg reported the entry surface as missing. The second
leg built it, and four fixtures now hold it:

| fixture | what it proves |
|---|---|
| 107 | a person attaches a photo to a fill from the browser, through the file input on the existing Add Fill form, and the stored bytes hash equal to the source |
| 108 | the same on the Add Event form |
| 109 | the photo appears on the record's card in History and opens full size, and a record with no photo shows no empty frame |
| 110 | the entry surface and the full-size photo view fit 390px, with no horizontal overflow |

**One thing is still open, and it is a design question rather than a gap.** A
photograph OF THE VEHICLE reaches `/apps/rover/attachments.json` and no renderer
reads it. The obvious home is the vehicle card, and fixture 58 holds that card
to the shape it had before M7 T7. That is item 5 in `QUESTIONS.md`.

The endpoints the surface uses are all in place and all proved:

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

## What is not proven

Named so nobody reads more into the green runs than they carry.

1. **An import that the runtime never answers.** Every status a bucket can give
   is handled and fixture 115 proves the refusal. A response that never arrives
   at all has no fixture, because there is no way to make a real bucket go
   silent without a stub, and a stub is not a test on this project's rules. The
   run would stay set and wedge `/apps/rover/import`. This is item 8 in
   `QUESTIONS.md`.
2. **A bucket that is not RustFS.** The S3 path is proved end to end against a
   real RustFS container at `http://localhost:9200`, read back by `boto3`. It
   has not been run against AWS S3 itself, or against any bucket that is not on
   this machine.
3. **A photograph of the vehicle on the vehicle card.** Item 5 in
   `QUESTIONS.md`. The data reaches the JSON route and no renderer reads it.
4. **A stale run flag after a killed process.** Item 7 in `QUESTIONS.md`. This
   pier carries no stale flag, and no fixture makes one on purpose.
5. **Timing on a slow bucket.** The S3 import costs 0.3 seconds more than the
   Clay import against a bucket on this machine. A bucket across a network
   costs more, and no figure here says how much.
