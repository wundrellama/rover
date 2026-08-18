# M7 T8 definition lifecycle — sol

## Result

PASS on the exact pinned substrate. Rover now gives all nine owner-editable
definition families rename, archive, and restore controls. The full 72-fixture
battery passed twice back to back with no skips.

T8 changed no schema. It added no relation and no column. The shipping action
union remains at five arms.

## Environment

- Branch: `ab-m7t8-sol`
- Implementation commit: `52162f89d03743a6f35e2d61d86c052c4be37922`
- Pier: `/var/home/michael/piers/rover-m7t8-sol-bel`
- Ship: `~bel`
- tmux session: `m7t8sol`
- Ames port: `32420`
- Pill: `/var/home/michael/workspace/urbit/pills/brass-408k-1.pill`
- Obelisk commit: `9de633299b373a1047490b48281a40b457fb2043`
- Copied `sur/obelisk-ast.hoon` SHA-256:
  `e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`

The requested `|install ~dister-nomryg-nilref %obelisk` began but could not
resolve on a fake ship because `-F` disables networking. I installed the
standalone, unmodified desk from the clean `/tmp/obelisk-fresh` checkout at the
exact commit above. The source and copied API mold match the required pin. I
then ran `|start %obelisk %obelisk` successfully.

The final Rover install check used fresh Gall state on this disposable pier.
`|start %rover %rover` emitted this line, with no `nest-fail` in that install:

```text
gall: booted %rover
```

The owner view then returned HTTP 200 and rendered the existing Obelisk data.

## Definition-family audit

Before T8, no family had both rename and reversible archive. Only custom fields
had any lifecycle endpoint. Its endpoint archived one way. It also had a
separate type-change endpoint.

| Family | Before T8 | T8 result |
| --- | --- | --- |
| Energy sources | Owner create endpoint only | Rename and archive or restore |
| Driving modes | Owner create endpoint only | Rename and archive or restore |
| Consumables | Seed and acquisition paths, no definition lifecycle | Rename and archive or restore |
| Service subtypes | Seeded catalog, no definition lifecycle | Rename and archive or restore |
| Disposal kinds | Seeded catalog, no definition lifecycle | Rename and archive or restore |
| Additives | Seed and import paths, no definition lifecycle | Rename and archive or restore |
| Tags | Inline and import creation, no definition lifecycle | Rename and archive or restore |
| Payment methods | Import creation, no definition lifecycle | Rename and archive or restore |
| Custom fields | Create, type change, and one-way archive | Rename and reversible archive or restore |

T8 added `rename-definition` and `set-definition-archived` as shared endpoints
for the closed nine-family set. The older custom-field archive and type-change
routes remain for compatibility.

## Design latitude used

- Shared endpoints: one rename endpoint and one archive-state endpoint keep the
  nine families on one validated path.
- Human boundary keys: requests carry the closed family name and current label.
  Raw definition IDs remain inside Rover and Obelisk.
- Same-family collision rule: rename returns HTTP 409 when the target label
  already exists in that family. The same label in another family remains
  legal.
- Archived visibility: archived rows remain in Settings with a Restore button.
  They leave every record-entry selector.
- Rename guidance: Settings says that rename changes historical display. Rover
  does not guess at intent or block a material-looking rename.
- Backward compatibility: the existing custom-field type-change and archive
  route remain in place while the browser uses the complete shared lifecycle.

## TDD evidence

The first referenced-energy rename fixture failed against the unchanged desk:

```text
event-test: FAIL - fixture 66 rename the referenced energy source:
405
```

After the first energy path passed, the next-family fixture failed before the
path was generalized:

```text
event-test: FAIL - fixture 67 rename driving-mode: %bad-shape: definition
400
```

The archive fixture failed before the archive route existed:

```text
event-test: FAIL - fixture 68 archive the referenced energy definition:
405
```

The real-browser fixture then failed while waiting for the first missing
Settings row. After the controls landed, it reported nine families, nine
renames, nine archives, and nine restores.

## Lifecycle evidence

- Fixture 66 renamed a referenced energy definition. History used the new
  label, the old label disappeared, and the definition kept its row identity.
- Fixture 67 renamed all nine families and refused a same-family collision.
- Fixture 68 archived a referenced energy definition. Fill and charge selectors
  hid it while the historical fill kept rendering it. Restore returned it.
- Fixture 69 archived and restored every family and checked every selector that
  offers those definitions.
- Fixture 70 archived an unreferenced starter, reran `seed-starters`, and proved
  the one row stayed archived until restore.
- Fixture 71 clicked rename, archive, and restore in a real Chromium session for
  all nine families.
- Fixture 72 left a referenced tag renamed and a starter additive archived over
  a real ship restart. History, selector filtering, and restore all survived.
- Fixture 13 counted five shipping action arms.

## Final battery run 1

Command:

```text
bin/event-test.sh /var/home/michael/piers/rover-m7t8-sol-bel
```

Exit status: 0

Verbatim final lines:

```text
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub
event-test: fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description
event-test: COVERAGE - all 72 defined fixtures executed
```

Coverage line:

```text
event-test: COVERAGE - all 72 defined fixtures executed
```

## Final battery run 2

Command:

```text
bin/event-test.sh /var/home/michael/piers/rover-m7t8-sol-bel
```

Exit status: 0

Verbatim final lines:

```text
event-test: fixture 22 PASS - a person selects three subtypes in the browser and sees all three on the saved card
event-test: fixture 35 PASS - a person records a purchase and a sale from the form and sees both in history
event-test: fixture 54 PASS - a person records a reminder in the browser and sees the derived countdown come back on the hub
event-test: fixture 65 PASS - a person records the whole specification in the browser and the vehicle screen reads it back as a description
event-test: COVERAGE - all 72 defined fixtures executed
```

Coverage line:

```text
event-test: COVERAGE - all 72 defined fixtures executed
```
