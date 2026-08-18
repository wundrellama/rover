# M7 T10 export results — sol

## Outcome

T10 adds one complete Rover export. The owner can download a `rover-import` JSON file from Settings. Rover accepts that file unchanged through `/apps/rover/import`.

The implementation adds no relation or column. The shipping `$action` union still has five arms. The export reads current facts through one wide, 101-query urQL script. It does not export derived values.

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

The second and final run produced the same semantic hash on both sides:

```text
SEMANTIC_SHA_BEFORE=4d1c4223d961c17dd4ed5138e1e5815d3cfc143a8114cd8896c1a9c8606084bc
SEMANTIC_SHA_AFTER=4d1c4223d961c17dd4ed5138e1e5815d3cfc143a8114cd8896c1a9c8606084bc
SEMANTIC_EQUAL=yes
```

The order-independent payload summaries also matched:

```json
{"acquisitionEvents":50,"chargingSessions":5,"consumableAcquisitions":25,"definitions":148,"disposalEvents":30,"expenseEvents":5,"fills":90,"noteEvents":20,"odometerReadings":25,"places":6,"reminders":60,"serviceEvents":50,"stations":7,"vehicles":95}
```

The selected vehicle rendered the same history before and after import. The archived tag remained archived. The payload scan rejected keys for current odometer, economy, fuel efficiency, cost per mile, fill intervals, and derived totals.

The final relation counts were:

```text
vehicles: 95 -> 95
vehicle-display-preferences: 0 -> 0
odometer-observations: 255 -> 255
energy-definitions: 13 -> 13
vehicle-energy-definitions: 105 -> 105
vehicle-default-energy-definitions: 95 -> 95
energy-acquisitions: 95 -> 95
fuel-fills: 90 -> 90
charging-sessions: 5 -> 5
places: 6 -> 6
stations: 7 -> 7
energy-acquisition-stations: 5 -> 5
energy-definition-subtypes: 32 -> 32
energy-subtype-octane: 11 -> 11
energy-subtype-cetane: 0 -> 0
energy-subtype-blend: 9 -> 9
energy-subtype-grade-code: 0 -> 0
vehicle-default-energy-subtype: 0 -> 0
additive-definitions: 7 -> 7
fuel-fill-additives: 5 -> 5
economy-breaks: 0 -> 0
charging-energy-measurements: 5 -> 5
battery-observations: 10 -> 10
battery-observation-percent: 10 -> 10
battery-observation-segments: 0 -> 0
charging-session-batteries: 10 -> 10
charging-efficiency-breaks: 0 -> 0
charging-costs: 5 -> 5
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
driving-mode-definitions: 10 -> 10
vehicle-driving-modes: 5 -> 5
fuel-fill-driving-mode: 5 -> 5
fuel-fill-average-speed: 0 -> 0
fuel-fill-drive-balance: 0 -> 0
tag-definitions: 21 -> 21
fuel-fill-tags: 5 -> 5
custom-field-definitions: 5 -> 5
custom-field-options: 0 -> 0
custom-field-values-number: 0 -> 0
custom-field-values-text: 5 -> 5
custom-field-values-boolean: 0 -> 0
payment-method-definitions: 11 -> 11
fuel-fill-payment-method: 5 -> 5
fill-notes: 0 -> 0
acquisition-imports: 20 -> 20
charging-session-subtype: 0 -> 0
consumable-definitions: 4 -> 4
consumable-acquisitions: 25 -> 25
consumable-purchases: 25 -> 25
consumable-acquisition-stations: 0 -> 0
consumable-acquisition-odometers: 25 -> 25
energy-acquisition-odometers: 95 -> 95
vehicle-consumables: 15 -> 15
vehicle-consumable-tank-size: 15 -> 15
vehicle-events: 155 -> 155
service-events: 50 -> 50
expense-events: 5 -> 5
note-events: 20 -> 20
vehicle-acquisitions: 50 -> 50
vehicle-disposals: 30 -> 30
vehicle-event-costs: 135 -> 135
vehicle-event-cost-totals: 135 -> 135
vehicle-event-odometers: 110 -> 110
vehicle-event-stations: 20 -> 20
vehicle-event-tags: 20 -> 20
vehicle-event-payment-method: 20 -> 20
vehicle-event-notes: 155 -> 155
vehicle-event-service-subtypes: 95 -> 95
service-subtype-definitions: 71 -> 71
service-subtype-reminder-defaults: 5 -> 5
disposal-kind-definitions: 6 -> 6
service-reminders: 60 -> 60
service-reminder-time: 30 -> 30
service-reminder-distance: 45 -> 45
vehicle-vin: 20 -> 20
vehicle-license-plate: 20 -> 20
vehicle-model-year: 15 -> 15
vehicle-make: 20 -> 20
vehicle-model: 25 -> 25
vehicle-sub-model: 15 -> 15
vehicle-body-type: 15 -> 15
vehicle-color: 15 -> 15
vehicle-engine: 15 -> 15
vehicle-transmission: 15 -> 15
vehicle-drive-type: 15 -> 15
vehicle-bed-type: 15 -> 15
vehicle-notes: 15 -> 15
```

Each count came from the same wide query used by the export, including each relation's identifying columns. The battery compared the count files as content, not set order.

## Battery evidence

The first complete run ended with these verbatim lines:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 wide relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 86 defined fixtures executed
```

The second back-to-back run ended with the same verbatim lines:

```text
event-test: fixture 86 PASS - an unchanged export imports into a fresh real database with all 101 wide relation counts, rendered history, archive state, and semantic re-export equal
event-test: COVERAGE - all 86 defined fixtures executed
```

The first run's semantic hashes both equaled `3d0f33cf4a93e21afff55784fd2f7fa0321e88c53218101ac6c86de67d9332e1`. Its before and after summaries both held 76 vehicles, 72 fills, 4 charging sessions, 20 consumable acquisitions, 40 service events, 4 expense events, 16 note events, 40 acquisitions, 24 disposals, and 48 reminders.

## Restart evidence

After both batteries, the whole pier stopped and restarted in `m7t10sol`. Vere reported the web interface live on port 8117 and the pier live. Authenticated exports before and after restart were both 172,929 bytes. Their semantic hashes both equaled `4d1c4223d961c17dd4ed5138e1e5815d3cfc143a8114cd8896c1a9c8606084bc`, and their summaries matched the final round-trip summary above.

## Design latitude used

- Endpoint: `/apps/rover/export` keeps the complete download beside Rover's existing owner-only app endpoints.
- Filename: `rover-export-complete.json` states both the producer and the file's unfiltered scope.
- Assembly: Gall builds one JSON document after one current-state, wide urQL script so the related facts share one read response.
- Attachment notice: `source.attachments` and `source.omissions` name photos, their zero current reference count, and `attachments-manifest.json` without inventing attachment storage.
- Download control: Settings uses a direct download link because T10 has one complete format and needs no preview choice.
- Round-trip isolation: the battery temporarily renames the populated database and creates a fresh one on the same pier, which proves an empty-database import while holding Vere, Zuse, and the pinned Obelisk substrate constant.
- Equality: the comparator recursively canonicalizes JSON arrays before hashing because Obelisk set order is not stable and byte equality would be false precision.
