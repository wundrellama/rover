# RESULTS — M7 T9, import widening (branch `ab-m7t9-sol`)

Date: 2026-08-18. All database results came from the pinned Obelisk agent on a real fake pier. No database result came from a mock.

## Outcome

The widened import carried the full private corpus. It imported 420 fills, 35 service events, 4 note events, and 8 reminders.

The converter processed 65 source subtype definitions. It emitted 62 shared labels because three service and expense labels were duplicates.

Both vehicles received their source specification. Empty source fields stayed absent. VIN and plate used their own T7 relations.

The same private import ran again after multiple ship restarts. Rover found every row and made no duplicate.

## Where it ran

| Item | Value |
|---|---|
| Worktree | `/tmp/m7t9-sol`, branch `ab-m7t9-sol` |
| Code commit | `678da5d88bc6fe8c816065b3c16f5f66a74f830a` |
| Pier | `/var/home/michael/piers/rover-m7t9-sol-bel`, ship `~bel` |
| tmux session | `m7t9sol` |
| Ames port | `32520` |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Obelisk | `9de633299b373a1047490b48281a40b457fb2043` |
| Obelisk install path | Local unmodified desk from `/tmp/obelisk-fresh` |
| `sur/obelisk-ast.hoon` SHA-256 | `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2` |

The fake ship could not resolve a remote install. I installed the pinned local checkout and ran `|start %obelisk %obelisk`.

The Rover desk compiled without a `nest-fail`. The first install reported `gall: booted %rover`.

## The one schema addition

T9 added `service-subtype-reminder-defaults`. T6 explicitly deferred subtype defaults to T9, and no existing relation can store definition-level intervals.

The post-publish rule requires a child relation. The relation uses `service-subtype-id` as its primary key and a `RESTRICT` foreign key.

The source supplies time and distance defaults together. The child row stores both intervals, and absence means the subtype has no default.

No populated relation gained a column. No other relation was added.

## Full corpus database evidence

The first import returned these count-only results:

```text
Rover import complete
Fills: imported 420, already-imported 0, conflicts 0, failures 0
Definitions: created 44, reused 33
Places: created 67, reused 0
Vehicles: created 2, reused 0
Station-none fills: 11
Total cross-check: exact 420, off-by-one 0, beyond 0
Unit mismatches: 0
Events: imported 39, already-imported 0, conflicts 0
Reminders: imported 8, already-imported 0
Subtype defaults: created 52, reused 0
sourceEfficiency: ignored by the Hoon import path
```

Primary-key projections gave these counts before battery data entered the pier:

| Relation or group | Rows |
|---|---:|
| `vehicles` | 2 |
| `fuel-fills` | 420 |
| `vehicle-events` | 39 |
| `service-events` | 35 |
| `note-events` | 4 |
| `service-subtype-reminder-defaults` | 52 |
| `vehicle-event-service-subtypes` | 107 |
| `service-reminders` | 8 |
| `service-reminder-time` | 8 |
| `service-reminder-distance` | 8 |
| `vehicle-event-costs` | 27 |
| `vehicle-event-odometers` | 39 |
| `vehicle-event-stations` | 31 |
| `vehicle-event-tags` | 25 |
| `vehicle-event-payment-method` | 24 |
| `vehicle-event-notes` | 26 |
| `vehicle-acquisitions` | 0 |
| `vehicle-disposals` | 0 |

The specification read checked all 13 T7 relations. Eleven relations held two rows each.

`vehicle-color` and `vehicle-notes` held zero rows. Both source vehicles left those two optional values empty.

The VIN and plate relations each held two rows. The evidence check exposed no source value.

After the battery restarted the ship multiple times, the private import returned this report:

```text
Rover import complete
Fills: imported 0, already-imported 420, conflicts 0, failures 0
Definitions: created 0, reused 77
Places: created 0, reused 67
Vehicles: created 0, reused 2
Station-none fills: 11
Total cross-check: exact 420, off-by-one 0, beyond 0
Unit mismatches: 0
Events: imported 0, already-imported 39, conflicts 0
Reminders: imported 0, already-imported 8
Subtype defaults: created 0, reused 52
sourceEfficiency: ignored by the Hoon import path
```

## Import report

This is the converter report from the final write. It contains counts only and no private values.

```text
Rover aCar conversion report
Mode: write

Records
Vehicles in/out: 2/2
Fills in/out/dropped: 420/420/0
Service events imported: 35
Note events imported: 4
Expense events not imported: 0 (Rover T9 carries service and note history; every expense remains named here)
Note events with a nonzero total kept as notes: 1 (the source kind is authoritative; the entered total was retained)
Trip records not imported: 0 (Rover has no trip-record model)
Reminders imported: 8
Trip types not imported: 6 (aCar defaults carry tax-deduction rates Rover does not model)
Source subtype definitions processed: 65
Rover service subtype definitions emitted: 62
Duplicate service/expense labels reused: 3 (T2 uses one shared service catalog entry for the same label)
Subtype default intervals imported: 52
Vehicle specifications imported: 2
Specification values imported by field: VIN=2, licence plate=2, model year=2, make=2, model=2, sub-model=2, body type=2, colour=0, engine=2, transmission=2, drive type=2, bed type=2, notes=0
Source fuel definitions processed: 45
Referenced fuel definitions emitted: 2
Unused source fuel definitions not imported: 43 (unused aCar catalog entries would add definitions the owner never selected)
Preferences not imported: 72 (application settings do not describe vehicle history)
Sync metadata records not imported: 585 (account and synchronization bookkeeping is not vehicle history)

Definitions and places
Energy definitions: 2
Additive definitions: 1
Driving-mode definitions: 1
Tag definitions: 6
Payment-method definitions: 5
Places: 67
Fill notes imported verbatim: 188
Suppressed literal 'deleted' tags: 123
Parts-only addresses imported: 105
Station-none fills with unmapped address text: 3 (the text has no source label that can identify a station)
Corrections applied: 1
Unit mismatches: 0

total-cost cross-check
Compared: 420
Exact: 420
Within one cent: 0
Beyond one cent: 0

fuel-efficiency cross-check
Chronological interval pairs: 418
Compared to source: 416
Source value absent: 2
Beyond 0.01 mpg: 0

Coordinates
Source coordinate values: 1418
Values exceeding scale 7: 643
Place coordinate pairs imported: 391
Imported place values rounded to scale 7: 59
Device coordinate pairs skipped: 318
Skipped device values exceeding scale 7: 584

Attachments (no database rows)
Photos extracted to disk, not the database: 121
Records carrying photos: 114
Fill/event/vehicle photo split: 116/3/2
Raw/written bytes: 48567745/48567745
Distinct raw hashes: 120
Duplicate raw photos: 1
Distinct filenames: 121
Owner JPEG metadata preserved: yes (EXIF is stripped only from a later published artifact)
PDF tags/nonempty PDFs: 69/0 (empty PDFs contain nothing to carry; nonempty PDFs remain attachment-task scope)

Other nonempty unmapped fields
External place-directory identifiers on events: 14 not imported (the external directory identifier has no ratified Rover target)
Device coordinate pairs on fills: 318 not imported (device location is not evidence of the station location)
External place-directory identifiers on fills: 275 not imported (the external directory identifier has no ratified Rover target)
Source field vehicle.active: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.bed-type-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.body-type-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.city-name: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.country-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.country-name: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.drive-type-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.engine-id: 2 not imported (no ratified Rover target; no mapping was invented)
Insurance policy strings: 2 not imported (insurance is fenced; a policy string is not an insurance feature)
Source field vehicle.make-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.model-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.region-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.region-name: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.transmission-id: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.type: 2 not imported (no ratified Rover target; no mapping was invented)
Source field vehicle.vehicle-id: 2 not imported (no ratified Rover target; no mapping was invented)
```

The attachment output held 121 JPEG files plus the JSON manifest and report. The converter wrote 48,567,745 source bytes without changes.

No PDF had content. The converter did not create a database attachment row.

## Product-path and compatibility evidence

Fixture 80 compared one imported service event with one service event from `add-service-event`. Both events used the same ten relations.

The shared shape included the event parent, typed child, cost, total, odometer, station, tag, payment, note, and subtype link.

Fixture 79 created the vehicle through the product endpoint before import. The import then added the old importer's missing specification data.

Fixture 81 ran the exact import again. It found the vehicle, four fills, two events, one reminder, and one subtype without duplicates.

Fixture 83 imported the T5 compatibility fill corpus without ownership events. The expected best, mean, worst, and last figures stayed unchanged.

The shipping `$action` union still has five arms.

## Test results

The converter suite passed 21 tests:

```text
.....................
----------------------------------------------------------------------
Ran 21 tests in 0.015s

OK
```

Both final battery runs used the same pier and database. The battery restarted the ship during each run.

Run 1, verbatim final four lines:

```text
event-test: fixture 81 PASS - re-import creates no second vehicle, fill, event, reminder, or subtype definition
event-test: fixture 82 PASS - source defaults, both reminder intervals, and all thirteen specification children land
event-test: fixture 83 PASS - imported history creates no ownership events and keeps the pre-T5 whole-history derivation
event-test: COVERAGE - all 83 defined fixtures executed
```

Run 2, verbatim final four lines:

```text
event-test: fixture 81 PASS - re-import creates no second vehicle, fill, event, reminder, or subtype definition
event-test: fixture 82 PASS - source defaults, both reminder intervals, and all thirteen specification children land
event-test: fixture 83 PASS - imported history creates no ownership events and keeps the pre-T5 whole-history derivation
event-test: COVERAGE - all 83 defined fixtures executed
```

Both runs exited 0 and contained no `FAIL` line.

## Private-data fence

A count-only scan loaded both private VINs and plates from the source. It found zero exact matches in the repository.

Fixture 63 also scanned the tree. Every fixture VIN contains a forbidden real-VIN letter, and every fixture plate contains `FAKE`.

The private JSON, photos, manifest, and report stayed under `/tmp`. Git does not track them.

## Design latitude used

1. **Payload sections.** Definitions use `service-subtypes`. Vehicles use `serviceEvents`, `noteEvents`, `reminders`, and `specification`.
2. **Route authority.** Separate event sections select the kind. Event objects do not carry a `kind` field.
3. **Subtype defaults.** One child row stores both source intervals because every populated source default supplies both.
4. **Event repeat key.** Vehicle, event kind, and observed minute identify a repeated event without a new provenance relation.
5. **Reminder repeat key.** Vehicle and subtype identify a repeated reminder because Rover permits one active reminder for that pair.
6. **Existing vehicles.** Import fields replace only supplied specification fields. Missing keys do not clear owner data.
7. **Malformed input.** The decoder rejects a malformed document before writes. A later database refusal reports its item and keeps completed items.
8. **Report order.** The report uses fixed sections for records, definitions, checks, coordinates, attachments, and unmapped fields.
9. **Station kind.** Fill-only places use `fuel`, event-only places use `private`, and shared places use `mixed`.
10. **Attachment bytes.** The owner extraction keeps the source JPEG bytes. A later publication task can strip metadata from a copy.
