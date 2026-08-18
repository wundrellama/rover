# M7 T10 — Export — results (opus)

## The pier

| Item | Value |
| --- | --- |
| Pier | `~/piers/rover-m7t10-opus-bel` |
| Ship | `~bel`, fake |
| Pill | `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill` |
| Ames port | 32610 |
| tmux session | `m7t10opus` |
| HTTP port | 8116 (insecure public) |
| Branch | `ab-m7t10-opus` |

## The Obelisk install

The fake ship has no network, so the remote install cannot resolve. I used the
second path the brief gives: the standalone unmodified desk from the clean
checkout at `/tmp/obelisk-fresh`, at the pinned commit
`9de633299b373a1047490b48281a40b457fb2043`. The desk is its own desk beside
`%rover`, started with `|start %obelisk %obelisk`. Rover reaches it only through
Gall cards.

Checks on the running pier:

```
$ sha256sum ~/piers/rover-m7t10-opus-bel/rover/sur/obelisk-ast.hoon
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2

$ sha256sum ~/piers/rover-m7t10-opus-bel/obelisk/sur/obelisk-ast.hoon
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2
```

The engine files on the pier are byte-identical to the pinned checkout:

```
app/obelisk.hoon    fresh=2e885d83a01de062  pier=2e885d83a01de062
lib/main.hoon       fresh=32b86349a6850d1e  pier=32b86349a6850d1e
lib/ddl.hoon        fresh=36fd4bc5d9b3e796  pier=36fd4bc5d9b3e796
lib/parse.hoon      fresh=61208a7ad4e5a004  pier=61208a7ad4e5a004
sur/obelisk-ast.hoon fresh=e7fd9775da24a34e pier=e7fd9775da24a34e
```

Rover installs with `gall: booted %rover` and no `nest-fail`. Every desk commit
in this task reported `gall: bumped %rover`.

## What T10 built

- `desk/lib/rover-export.hoon` — reads the stored facts and renders the payload.
- `GET /apps/rover/export` in `desk/app/rover.hoon` — serves the payload as a
  file download, behind the owner's Eyre session.
- A download control on the Settings screen, in place of the placeholder that
  promised the export for later.
- The import widening the round trip needs, in `desk/lib/rover-import.hoon` and
  `desk/app/rover.hoon`.
- Nine fixtures in `bin/event-test.sh`, numbered 84 to 92.

**No new relation. No new column.** The export is a read path, and the import
widening writes into relations that M0 through T9 already poured. The shipping
`$action` union still holds five arms:

```
+$  action
  $%  [%init-db ~]
      [%ensure-ui-schema ~]
      [%ensure-def-schema ~]
      [%verify-schema ~]
      [%seed-starters ~]
  ==
```

## The round trip

The fixture populates one vehicle with every kind of record M7 knows, through
the endpoints a browser calls: a full specification with a synthetic VIN and a
plate marked FAKE, an acquisition, an odometer reading, two fills with a new
station in a new place, tags, an additive, a payment method, a driving mode and
a custom field value, a charge with mileage and battery readings, a DEF
purchase, a service event with ten subtypes, an expense, a note, two reminders,
a disposal with its kind, and an archived driving mode.

It then exports the whole database, drops it with
`DROP DATABASE FORCE rover;`, pours it again through `%init-db`,
`%ensure-def-schema` and `%ensure-ui-schema`, seeds the starters, and imports
the export.

### Counts on both sides

Read by primary key, which is unique by construction, so no projection can
collapse two rows. Every relation that holds a row is listed. Ten reads per
call, because all ninety in one script make a result noun larger than the
`click` transport can return.

```
vehicles                                 source     88   rebuilt     88
energy-definitions                       source     26   rebuilt     26
energy-definition-subtypes               source     32   rebuilt     32
energy-subtype-octane                    source     11   rebuilt     11
vehicle-energy-definitions               source    121   rebuilt    121
vehicle-default-energy-definitions       source     88   rebuilt     88
driving-mode-definitions                 source     37   rebuilt     37
vehicle-driving-modes                    source     18   rebuilt     18
additive-definitions                     source     20   rebuilt     20
tag-definitions                          source     29   rebuilt     29
payment-method-definitions               source     22   rebuilt     22
consumable-definitions                   source      4   rebuilt      4
vehicle-consumables                      source     26   rebuilt     26
vehicle-consumable-tank-size             source     26   rebuilt     26
service-subtype-definitions              source     69   rebuilt     69
service-subtype-reminder-defaults        source      3   rebuilt      3
disposal-kind-definitions                source      6   rebuilt      6
custom-field-definitions                 source     18   rebuilt     18
places                                   source     17   rebuilt     17
stations                                 source     17   rebuilt     17
odometer-observations                    source    278   rebuilt    267
energy-acquisitions                      source    107   rebuilt    107
fuel-fills                               source     93   rebuilt     93
charging-sessions                        source     14   rebuilt     14
energy-acquisition-odometers             source    107   rebuilt    107
energy-acquisition-stations              source     29   rebuilt     29
fuel-fill-additives                      source     17   rebuilt     17
fuel-fill-driving-mode                   source     17   rebuilt     17
fuel-fill-average-speed                  source     13   rebuilt     13
fuel-fill-drive-balance                  source     13   rebuilt     13
fuel-fill-tags                           source     17   rebuilt     17
fill-notes                               source     13   rebuilt     13
fuel-fill-payment-method                 source     17   rebuilt     17
acquisition-imports                      source     12   rebuilt     12
charging-energy-measurements             source     14   rebuilt     14
charging-session-batteries               source     28   rebuilt     28
battery-observation-percent              source     28   rebuilt     28
charging-costs                           source     14   rebuilt     14
consumable-acquisitions                  source     31   rebuilt     31
consumable-purchases                     source     31   rebuilt     31
consumable-acquisition-odometers         source     31   rebuilt     31
vehicle-events                           source    175   rebuilt    175
service-events                           source     48   rebuilt     48
expense-events                           source     15   rebuilt     15
note-events                              source     25   rebuilt     25
vehicle-acquisitions                     source     53   rebuilt     53
vehicle-disposals                        source     34   rebuilt     34
vehicle-event-costs                      source    150   rebuilt    150
vehicle-event-cost-totals                source    150   rebuilt    150
vehicle-event-odometers                  source    129   rebuilt    129
vehicle-event-stations                   source     24   rebuilt     24
vehicle-event-tags                       source     24   rebuilt     24
vehicle-event-payment-method             source     35   rebuilt     35
vehicle-event-notes                      source    175   rebuilt    175
vehicle-event-service-subtypes           source    181   rebuilt    181
service-reminders                        source     68   rebuilt     68
service-reminder-time                    source     34   rebuilt     34
service-reminder-distance                source     56   rebuilt     56
app-default-vehicle                      source      1   rebuilt      1
custom-field-values-text                 source     17   rebuilt     17
vehicle-vin                              source     28   rebuilt     28
vehicle-license-plate                    source     28   rebuilt     28
vehicle-model-year                       source     24   rebuilt     24
vehicle-make                             source     28   rebuilt     28
vehicle-model                            source     32   rebuilt     32
vehicle-sub-model                        source     24   rebuilt     24
vehicle-body-type                        source     24   rebuilt     24
vehicle-color                            source     24   rebuilt     24
vehicle-engine                           source     24   rebuilt     24
vehicle-transmission                     source     24   rebuilt     24
vehicle-drive-type                       source     24   rebuilt     24
vehicle-bed-type                         source     24   rebuilt     24
vehicle-notes                            source     24   rebuilt     24
```

Every relation matches except `odometer-observations`, which reads 278 on the
source side and 267 on the rebuilt side. `odometer-observations` is the one
relation the export carries in part. A reading that a fill, a purchase or an
event carries travels inside that record. A reading entered on its own has no
place in the format, so the export counts it by name under `not-carried`. The
entry has this shape, read from the export of the rebuilt database, which holds
none:

```
{"rows": 0, "kind": "standalone-odometer-readings",
 "reason": "a reading that no fill, purchase or event carries has no place in the format"}
```

On the source side of run 1 that count read 11. The fixture subtracts the
number the export names from the source count and then demands equality, so a
pass proves the count was 11, that eleven readings are the whole difference,
and that no other row is missing anywhere.

The `source` block and the attachment entry, from the same export:

```
{"exported": "2026-08-18T20:02", "ship": "~bel", "app": "Rover"}

{"photos": 0,
 "manifest": "attachments.json beside the converted export; Rover stores no photo row",
 "reason": "photos live outside the database by ruling 17, and the attachment task is not built"}
```

## The verdicts

Both runs used the same pier and the same database. Each run restarts the ship
twice: once in fixture 12 and once in fixture 91.

### Run 1, verbatim final lines

```
event-test:   vehicle-notes                            source     24   rebuilt     24
event-test: fixture 87 PASS - a dropped and rebuilt database holds the same row count in all 90 relations the export carries, short only by the standalone readings the export counts by name
event-test: fixture 88 PASS - the rebuilt database renders the same vehicle history, derivations included
event-test: fixture 89 PASS - an archived definition stays archived across the round trip, and an active one stays active
event-test: fixture 90 PASS - re-exporting the rebuilt database gives a payload semantically equal to the first export, and the readings the first export named as left behind are the only thing missing
event-test: fixture 91 PASS - the export, the rebuilt row counts, and the archived flag all survive a ship restart
event-test: COVERAGE - all 92 defined fixtures executed
EXIT=0
```

### Run 2, verbatim final lines

```
event-test:   vehicle-notes                            source     28   rebuilt     28
event-test: fixture 87 PASS - a dropped and rebuilt database holds the same row count in all 90 relations the export carries, short only by the standalone readings the export counts by name
event-test: fixture 88 PASS - the rebuilt database renders the same vehicle history, derivations included
event-test: fixture 89 PASS - an archived definition stays archived across the round trip, and an active one stays active
event-test: fixture 90 PASS - re-exporting the rebuilt database gives a payload semantically equal to the first export, and the readings the first export named as left behind are the only thing missing
event-test: fixture 91 PASS - the export, the rebuilt row counts, and the archived flag all survive a ship restart
event-test: COVERAGE - all 92 defined fixtures executed
EXIT=0
```

### Coverage line

Both runs end with the same line:

```
event-test: COVERAGE - all 92 defined fixtures executed
```

Ninety-two fixtures are defined and ninety-two ran. No fixture was skipped in
either run. Both runs exit 0.

## Done-check

| # | Item | Evidence |
| --- | --- | --- |
| 1 | The desk installs with `gall: booted %rover` and no `nest-fail` | the pier log, and fixture 1 in both runs |
| 2 | A person presses a download control and receives the file | fixture 92 |
| 3 | The export is a payload Rover's own import accepts unchanged | fixtures 85 and 87 |
| 4 | The round trip passes | fixtures 87, 88, 89 |
| 5 | A re-export is semantically equal to the first export | fixture 90 |
| 6 | The export names what it does not carry, photos included | fixture 85 |
| 7 | The endpoint requires the owner's session | fixture 84 |
| 8 | No real VIN, plate or personal value in the repository | fixture 63, which the T10 corpus passes |
| 9 | Everything survives a ship restart | fixture 91 |
| 10 | The action union still has five arms | quoted above |
| 11 | Two runs, same verdict, every fixture executed | the two runs above |

## What the export leaves behind, and why

The payload carries a `not-carried` block. It names twelve things:

| Kind | Reason |
| --- | --- |
| attachments | photos live outside the database by ruling 17, and the attachment task is not built |
| custom-field-options | a custom field with a fixed option list has no entry path yet |
| station-brand-operator | brand and operator have no entry path yet |
| station-identifiers | a provider identifier must never cross a boundary |
| place-coordinate-accuracy | coordinate accuracy has no entry path yet |
| acquisition-station-equipment | the pump or charger used has no entry path yet |
| energy-subtype-blend | a blend percentage has no entry path yet |
| energy-subtype-grade-code | a grade code has no entry path yet |
| battery-observation-segments | a battery reading in segments rather than percent has no entry path yet |
| consumption-observations | a dashboard consumption reading has no entry path yet |
| charging-efficiency-breaks | a charging break has no entry path yet |
| standalone-odometer-readings | a reading that no fill, purchase or event carries has no place in the format |

Each entry carries the row count as well as the reason. The attachments entry
carries the photo count and names where a manifest would live.

Nothing derived is in the payload. Fixture 86 walks every key of the document
and refuses an economy figure, a cost per mile, a derived total paid, a current
odometer, a lifetime figure or an average. Fixture 88 proves the second
database reaches the same figures from the same facts: the rendered history for
the vehicle is identical on both sides, including the `CALCULATED TOTAL` and
`ECONOMY` lines that only a derivation can produce.

## Two defects the round trip found

The round trip is the first thing in this repository to run the product against
a database that holds only what an export carried. It found two real defects,
both in code that shipped before T10.

**1. A comparison read crashed on an absent child.** The pinned engine runs a
join over whole relations and applies the `WHERE` at the end. When a join step
matches nothing and another join follows, the script crashes instead of
returning no rows. Every child of a fill is optional, so `fuel-fill-subtype`
and `economy-breaks` are empty on a database whose fills never used them, and
the import's comparison lookup — which reached each child through the vehicle
or the provenance — crashed and reported every repeated fill as a failure.
Fixture 81 met this on the rebuilt database.

The caller already knows which acquisition it found. `import-run` now carries
it, and every comparison read filters on that one identifier. Each read is a
single join, or no join at all.

This was latent, not new. It bites on any database in which no fill has a
subtype and none has an economy break. The batteries never met it because the
piers they ran on carried other data.

**2. An archived vehicle came back active.** The export carries the flag on a
vehicle, and the import wrote it on a vehicle it created, but a vehicle it
found kept the state the receiving ship already held. The settings pass now
corrects the flag, the same way it corrects a definition. Fixture 90 caught it:
the re-export differed from the export on `archived` for two vehicles.

## Design latitude used

| Choice | Rationale |
| --- | --- |
| `GET /apps/rover/export` for the endpoint | An export is a read. A GET is what a download control is, and nothing about an export mutates. |
| `rover-export-YYYY-MM-DD.json` for the filename, in `content-disposition` | The date is the one thing that tells two exports apart in a downloads folder. The extension says what the file is. |
| One urQL script, assembled in Gall, served as one body | The whole payload is one read of current state, so it is one script and one answer. Streaming would need a cursor the engine does not offer, and a partial file is worse than a slow one. |
| `not-carried` at the top level of the payload, beside `source` | It describes the whole document, not one vehicle. A reader who wants to know what is missing reads the top of the file. |
| No summary screen before the download | One button, one complete file. A summary is a second thing to keep true. |
| The control lives on the Settings screen | It replaces the `EXPORT - COMING LATER` placeholder that was already there, next to Import. |
| The fresh empty database is this pier's own `rover` database, dropped and poured again | A second desk needs a second copy of the agent with a second database name, and the copy — not the export — becomes the thing under test. Dropping proves the stronger claim: the export alone rebuilds the database it came from, with no leftover row to flatter the comparison. The battery bootstraps a fresh database in fixture 1, so the run that follows starts from the rebuilt database and needs no repair. |
| Standalone odometer readings are named in `not-carried` rather than carried | The format has no section for a reading that no record holds. The brief lists what the round trip preserves, and it is what the import carries; a standalone reading is not in it. Inventing a section would be inventing format, which is a ratified decision, not mine. The export counts them instead, so nothing is silently absent. |
| The import is widened to accept everything the export writes | The rule is that Rover's own import must accept Rover's export unchanged. Charges, consumable purchases, disposal kinds, consumable and custom-field definitions, custom field values, vehicle settings links, the default vehicle, and the archived flag on a definition or a vehicle the receiving ship already holds all had to be readable. This is additive: no document that imported before imports differently now. |
| The count comparison reads each relation by its primary key | A primary key is unique, so the projection cannot collapse two rows. Reading wide would be equally correct and much larger. |
| The count comparison runs ten relations per call | All ninety in one script make a result noun the `click` transport fails to cue, and it returns nothing at all. The fixture refuses a short count vector rather than comparing fewer relations. |
| The semantic comparison ignores the row counts under `not-carried` | Those counts are a report about the database that was read, not content the payload carries, and one of them counts the readings the round trip legitimately drops. Their names and reasons are compared. The standalone count is asserted on its own, where it says what it should say. |
| Fixture numbers 84 to 92, appended after fixture 83 | The round trip drops the database, so it has to run after everything that reads the accumulated one. |

## Fixtures added

| # | What it proves |
| --- | --- |
| 84 | The export endpoint refuses a request that carries no owner session. |
| 85 | The export is a `rover-import` payload that names its producer, its photo count, and every fact kind it leaves behind. |
| 86 | The export carries entered totals and no derived figure. |
| 87 | A dropped and rebuilt database holds the same row count in all 90 relations the export carries, short only by the standalone readings the export counts by name. |
| 88 | The rebuilt database renders the same vehicle history, derivations included. |
| 89 | An archived definition stays archived across the round trip, and an active one stays active. |
| 90 | Re-exporting the rebuilt database gives a payload semantically equal to the first export, and the readings the first export named as left behind are the only thing missing. |
| 91 | The export, the rebuilt row counts, and the archived flag all survive a ship restart. |
| 92 | The Settings screen carries a download control, and the address it names serves the export file. |

## Privacy

Every VIN written by this task contains `Q`, which the real VIN alphabet
excludes. Every plate is marked FAKE. Fixture 63 checks the whole tree and
passes in both runs. The export endpoint is behind the owner's authenticated
Eyre session, the same as every write endpoint, and fixture 84 proves a request
without that session receives the login redirect and no payload.
