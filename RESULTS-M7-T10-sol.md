# M7 T10 export results — sol

## Outcome

T10 adds one complete Rover export. The owner can download a `rover-import` JSON file from Settings. Rover accepts that file unchanged through `/apps/rover/import`.

The implementation adds no relation or column. The shipping `$action` union still has five arms. The export reads current facts through one wide, 101-query urQL script. It does not export derived values.

The export, import, and file format are unchanged. Fixture 86 now selects the complete primary key of each relation for counting. This preserves row identity and keeps the `click` result below the transport limit.

## Real substrate

- Branch: `ab-m7t10-sol`
- Pier: `/var/home/michael/piers/rover-m7t10-sol-bel`
- Ship: `~bel`
- tmux session: `m7t10sol`
- Ames port: `32620`
- Eyre port: `8117`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk commit: `9de633299b373a1047490b48281a40b457fb2043`
- Obelisk install path: the standalone, unmodified desk copied from `/tmp/obelisk-fresh`
- Obelisk start command: `|start %obelisk %obelisk`
- Copied `sur/obelisk-ast.hoon` SHA-256: `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`

The local install path was necessary because the fake ship had no network route for a remote install. The initial desk install printed `gall: booted %rover` with no `nest-fail`. The final source commit printed `gall: bumped %rover` with no `nest-fail`.

## Browser and boundary evidence

Fixture 84 made an unauthenticated request and received Eyre's login redirect. The same fixture used the authenticated owner session, opened Settings in Chromium, pressed the download control, and received `rover-export-complete.json` as valid JSON. Its `source.app` is `Rover`. Its attachment notice says photos are not included, gives a photo count of zero, and names `attachments-manifest.json`.

All fixture values are synthetic. The VIN assertion requires the `ROVERFAKEVIN` prefix. Plates remain marked fake.

## Round-trip comparison

Fixture 86 renamed the populated `rover` database to `roverexportowner`, created a fresh empty `rover` database on the same real Obelisk agent, and submitted the downloaded file unchanged. It then restored the original database.

The earlier evidence came from a fresh database that had only a few battery runs. These replacement runs used the existing grown database without a rebuild or drop. The first run counted 449 odometer rows on both sides. The second run counted 500 on both sides.

The second replacement run produced the same semantic hash on both sides:

```text
SEMANTIC_SHA_BEFORE=bc065b068b66e216d9335ab25fd536b07c87b266d007a7cb0a8034c3eef4704e
SEMANTIC_SHA_AFTER=bc065b068b66e216d9335ab25fd536b07c87b266d007a7cb0a8034c3eef4704e
SEMANTIC_EQUAL=yes
```

The order-independent payload summaries also matched:

```json
{"acquisitionEvents":99,"chargingSessions":10,"consumableAcquisitions":50,"definitions":199,"disposalEvents":59,"expenseEvents":10,"fills":176,"noteEvents":38,"odometerReadings":50,"places":10,"reminders":118,"serviceEvents":97,"stations":11,"vehicles":188}
```

The selected vehicle rendered the same history before and after import. The archived tag remained archived. The payload scan rejected keys for current odometer, economy, fuel efficiency, cost per mile, fill intervals, and derived totals.

The final relation counts were:

```text
vehicles: 188 -> 188
vehicle-display-preferences: 0 -> 0
odometer-observations: 500 -> 500
energy-definitions: 18 -> 18
vehicle-energy-definitions: 208 -> 208
vehicle-default-energy-definitions: 188 -> 188
energy-acquisitions: 186 -> 186
fuel-fills: 176 -> 176
charging-sessions: 10 -> 10
places: 10 -> 10
stations: 11 -> 11
energy-acquisition-stations: 10 -> 10
energy-definition-subtypes: 32 -> 32
energy-subtype-octane: 11 -> 11
energy-subtype-cetane: 0 -> 0
energy-subtype-blend: 9 -> 9
energy-subtype-grade-code: 0 -> 0
vehicle-default-energy-subtype: 0 -> 0
additive-definitions: 12 -> 12
fuel-fill-additives: 10 -> 10
economy-breaks: 0 -> 0
charging-energy-measurements: 10 -> 10
battery-observations: 20 -> 20
battery-observation-percent: 20 -> 20
battery-observation-segments: 0 -> 0
charging-session-batteries: 20 -> 20
charging-efficiency-breaks: 0 -> 0
charging-costs: 10 -> 10
charging-cost-components: 0 -> 0
charging-cost-source-totals: 0 -> 0
consumption-observations: 0 -> 0
place-addresses: 0 -> 0
place-address-formatted: 0 -> 0
place-address-parts: 0 -> 0
place-coordinates: 0 -> 0
place-coordinate-accuracy: 0 -> 0
station-brand-operator: 0 -> 0
station-identifiers: 0 -> 0
acquisition-station-equipment: 0 -> 0
app-default-vehicle: 1 -> 1
vehicle-tank-size: 0 -> 0
vehicle-refill-reserve: 0 -> 0
fuel-fill-subtype: 0 -> 0
driving-mode-definitions: 15 -> 15
vehicle-driving-modes: 10 -> 10
fuel-fill-driving-mode: 10 -> 10
fuel-fill-average-speed: 0 -> 0
fuel-fill-drive-balance: 0 -> 0
tag-definitions: 39 -> 39
fuel-fill-tags: 10 -> 10
custom-field-definitions: 10 -> 10
custom-field-options: 0 -> 0
custom-field-values-number: 0 -> 0
custom-field-values-text: 10 -> 10
custom-field-values-boolean: 0 -> 0
payment-method-definitions: 20 -> 20
fuel-fill-payment-method: 10 -> 10
fill-notes: 0 -> 0
acquisition-imports: 36 -> 36
charging-session-subtype: 0 -> 0
consumable-definitions: 4 -> 4
consumable-acquisitions: 50 -> 50
consumable-purchases: 50 -> 50
consumable-acquisition-stations: 0 -> 0
consumable-acquisition-odometers: 50 -> 50
energy-acquisition-odometers: 186 -> 186
vehicle-consumables: 30 -> 30
vehicle-consumable-tank-size: 30 -> 30
vehicle-events: 303 -> 303
service-events: 97 -> 97
expense-events: 10 -> 10
note-events: 38 -> 38
vehicle-acquisitions: 99 -> 99
vehicle-disposals: 59 -> 59
vehicle-event-costs: 265 -> 265
vehicle-event-cost-totals: 265 -> 265
vehicle-event-odometers: 214 -> 214
vehicle-event-stations: 37 -> 37
vehicle-event-tags: 37 -> 37
vehicle-event-payment-method: 37 -> 37
vehicle-event-notes: 303 -> 303
vehicle-event-service-subtypes: 185 -> 185
service-subtype-definitions: 75 -> 75
service-subtype-reminder-defaults: 9 -> 9
disposal-kind-definitions: 6 -> 6
service-reminders: 118 -> 118
service-reminder-time: 59 -> 59
service-reminder-distance: 88 -> 88
vehicle-vin: 38 -> 38
vehicle-license-plate: 38 -> 38
vehicle-model-year: 28 -> 28
vehicle-make: 38 -> 38
vehicle-model: 48 -> 48
vehicle-sub-model: 28 -> 28
vehicle-body-type: 28 -> 28
vehicle-color: 28 -> 28
vehicle-engine: 28 -> 28
vehicle-transmission: 28 -> 28
vehicle-drive-type: 28 -> 28
vehicle-bed-type: 28 -> 28
vehicle-notes: 28 -> 28
```

Each count selected the complete primary key of its relation. Composite keys selected all key columns. The battery kept one relation per call and retained the 101-count short-vector guard. It compared the count files as content, not set order.

## Battery evidence

Both commands exited 0.

The first grown-database run ended with these verbatim lines:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 86 defined fixtures executed
```

The second back-to-back grown-database run ended with the same verbatim lines:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 primary-key relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 86 defined fixtures executed
```

The first run's semantic hashes both equaled `fd2a19cd09350e862719e2ed10f46cad06d6d829deb0d5096ced8d3c022dec57`. Its source and destination both counted all 101 relations. The repaired odometer count was `449 -> 449`.

The first run's matching summaries held 169 vehicles, 158 fills, 9 charging sessions, and 45 consumable acquisitions. They also held 87 service events, 9 expense events, 34 note events, 89 acquisitions, 53 disposals, and 106 reminders.

## Restart evidence

Each replacement battery stopped and restarted the whole pier in `m7t10sol`. Both runs then reported this verbatim line before the round trip:

```text
event-test: fixture 12 PASS - every event, total, odometer link, station link, and reading survived a ship restart
```

Both runs served the web interface on port 8117 after the restart. Each run then completed fixture 86 and the coverage gate.

## Design latitude used

- Endpoint: `/apps/rover/export` keeps the complete download beside Rover's existing owner-only app endpoints.
- Filename: `rover-export-complete.json` states both the producer and the file's unfiltered scope.
- Assembly: Gall builds one JSON document after one current-state, wide urQL script so the related facts share one read response.
- Attachment notice: `source.attachments` and `source.omissions` name photos, their zero current reference count, and `attachments-manifest.json` without inventing attachment storage.
- Download control: Settings uses a direct download link because T10 has one complete format and needs no preview choice.
- Round-trip isolation: the battery temporarily renames the populated database and creates a fresh one on the same pier, which proves an empty-database import while holding Vere, Zuse, and the pinned Obelisk substrate constant.
- Equality: the comparator recursively canonicalizes JSON arrays before hashing because Obelisk set order is not stable and byte equality would be false precision.
- Counting: fixture 86 selects the complete primary key of each relation. Composite keys use all key columns, and the 101-call short-vector guard remains.
