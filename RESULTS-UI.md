# Rover UI milestone results

All browser fixtures use the real `~bel` pier at
`~/piers/rover-bel`, real Eyre cookies, and the pinned stock
`%obelisk`. No browser response is mocked.

## Eyre port diagnosis

The redispatch named port `12323`, but the live pier identifies that as
Eyre's loopback (auto-authenticated) listener, not its public session
listener:

```console
$ cat ~/piers/rover-bel/.http.ports
12323 insecure loopback
8082 insecure public
```

The loopback listener does not expose the logged-out browser boundary.
At this pill it sends even Eyre-owned routes through `%lens` and returns
500:

```console
$ for path in / /~/login /apps/rover; do
>   curl -s -o /dev/null -w "$path HTTP %{http_code} redirect:%{redirect_url}\n" \
>     "http://localhost:12323$path"
> done
/ HTTP 500 redirect:
/~/login HTTP 500 redirect:
/apps/rover HTTP 500 redirect:
```

That rules out Rover's request handler as the cause: `/` and `/~/login`
are Eyre-owned, while the same running Rover agent passes the complete
session and asset fixture on the pier's public listener below.

## Slices 1 and 2 — page, session, assets, docket

Exact command:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS**.

This one live-pier command proves:

- logged-out `GET /apps/rover` returns an empty `303` login redirect;
- posting the live `+code` yields an `urbauth` session cookie;
- authenticated `GET /apps/rover` returns the embedded HTML shell;
- `tile.png` returns `image/png` and bytes identical to the desk file;
- all four public `.woff2` URLs return `font/woff2` and bytes identical
  to the committed font files;
- the docket installs with `site+/apps/rover`, the same-origin tile URL,
  and no glob.

The `.woff2x` files are the deliberate Clay-import representation. The
browser URLs and committed source assets remain `.woff2`; the fixture
compares every served face byte-for-byte with its corresponding
`.woff2` source.

## Slice 3 — formatter and entry parser

RED was captured after committing the expanded fixture into the live
desk but before adding `lib/rover-render.hoon`:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-render.hoon "$HOME/piers/rover-bel"
[0 %avow 1 %thread-fail ...]
```

The real pier log identified the expected missing implementation:

```text
clay: %a build failed [...] /gen/test-render/hoon
clay: no files match /lib/rover-render/hoon
```

GREEN, exact command and output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-render.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %render-tests-pass]
```

Result: **PASS**.

The Hoon fixture asserts exact results for:

- `12345` at scale 3 → `12.345`;
- grouped `100125` at scale 1 → `10,012.5`;
- `12345` quantity → `12.345 gal`;
- `3499` unit-price mills → `$3.499`;
- `43190` total mills with two USD minor decimals → `$43.19`;
- source-native and converted distance labels;
- positive and negative coordinates at scale 7;
- parsing `12.345` and `10,012.5` back to exact digits/precision;
- excess-precision refusal;
- `$3.49` visible completion to `$3.499`;
- exact `$3.499` override;
- malformed `$3.x9` refusal as `%bad-shape`.

Regression commands and real outputs:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/compile-rover.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun 0]

$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-pricing.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %pricing-tests-pass]
```

In Urbit loobean encoding, the compile probe's final `0` is `%.y`
(the build returned a vase).

## Slice 4 — vehicle list and detail reads

The browser fixture was extended before the read route existed. RED,
exact command and output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: FAIL - vehicle view has no seeded vehicle
```

The implementation polls `/apps/rover/view`, submits one urQL read
script to the real `%obelisk`, joins rows internally by machine ID, and
emits only owner-facing labels and formatted values. Rover sorts fill
history by `observed-start`; it does not rely on Obelisk row order.

GREEN, exact formatter command and output:

```console
$ "$HOME/workspace/urbit/bin/click" -k \
>   -i probes/run-test-render.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %render-tests-pass]
```

GREEN, exact browser command and output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS**.

The served response proves the Phase A vehicle renders with a derived
current odometer of `10,012.5 mi`, the fill renders as `12.345 gal` at
`$3.499`, and its non-editable display total is labelled `DERIVED TOTAL`
and renders `$43.20`. The harness rejects bare `12345`, bare `3499`, and
any `0x` identifier in the served vehicle HTML. Vehicles without
odometer observations render `Unavailable - no odometer readings`
instead of zero or an estimate.

## Slice 5 — UA 571-C theme and mobile layout

RED, exact browser output before the theme existed:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: FAIL - UA 571-C background token missing
```

GREEN, exact command and output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS**.

A headless Chromium render used the authenticated real-pier page at a
390-by-844 viewport. Exact measured output:

```json
{"viewport":390,"scrollWidth":390,"horizontalOverflow":false,"minTouchHeight":45.96875,"fontLoaded":true,"vehicleColumns":"none"}
```

This proves the rendered page has no horizontal overflow at phone
width, its interactive control exceeds 44 px, Berkeley Mono is loaded,
and the wide two-column vehicle grid is not active. The served shell
defines the ratified amber palette, all four local font faces, tabular
numerals, a persisted glow toggle (off by default), stacked history
cards, the compact phone designation, and the `48rem` wide breakpoint.

## Slice 6a — add-fill entry

The first real POST was the RED check for the mutation serializer. It
failed closed with HTTP 422, and the real Obelisk trace identified
grouped decimal output and missing term sigils:

```console
$ curl ... --data-raw '{"quantity":"7.654",...}' \
>   http://localhost:8082/apps/rover/add-fill
valid HTTP 422
body: %database-refused: fill

[ %rover-fill-write-refused
  ~[
    [%leaf p="syntax error"]
    [%leaf p="\"error on numeric parser <|p a r t i a l|> \""]
    [%leaf p="\"insert parse phase:  \\\" fuel-fills VALUES (..., 7.654, gal, partial, 3.499, usd, ...\\\" ...\""]
  ]
]
```

Rover now serializes application integers as flat base-10 digits and
enum values as `%term` literals. The pure human-entry decoder test is
green:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-entry.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %entry-tests-pass]
```

The first successful real write, exact response:

```console
$ curl --max-time 20 -sS -b /tmp/rover-debug-jar \
>   -H 'content-type: application/json' \
>   --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"7.654","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-28T19:20","zone":"America/Chicago","mileage":"","mileageUnit":"mi"}' \
>   http://localhost:8082/apps/rover/add-fill
Saved fill - $3.499 - derived $26.78
```

The browser-half harness then exercised the parser, live BigInt
preview, cash rounding, atomic Obelisk write, stored integer values,
and read-back:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS**.

The raw admin probe returned the newly inserted row as
`[%quantity-milli 25717 6543]` and
`[%unit-price-mills 25717 3499]`; those representations are asserted
only behind the admin test boundary. The served page renders
`6.543 gal`, `$3.499`, and derived `$22.89`, and its raw-value sweep
still passes.

Screenshot-equivalent: authenticated HTML served for the add-fill
screen (options abbreviated here only to keep this evidence readable):

```html
<section id="add-fill" class="entry-screen" hidden>
  <header>
    <p class="eyebrow">NEW ACQUISITION</p>
    <h2>Add fill</h2>
  </header>
  <form id="fill-form">
    <label>Vehicle
      <select name="vehicle" required>
        <option value="Phase A Vehicle">Phase A Vehicle</option>
      </select>
    </label>
    <label>Definition
      <select name="definition" required>
        <option value="Regular 87" data-vehicle="Phase A Vehicle"
          data-unit="gal" data-kind="reservoir">Regular 87</option>
      </select>
    </label>
    <label>Quantity
      <div class="input-unit">
        <input name="quantity" inputmode="decimal" placeholder="12.345" required>
        <output id="fill-unit">unit</output>
      </div>
    </label>
    <label>Price per unit
      <input name="price" inputmode="decimal" placeholder="$3.49" required>
    </label>
    <div class="preview-row">
      <span>Completed price</span>
      <output id="fill-price-completed">&mdash;</output>
    </div>
    <label>Tank state
      <select name="tank">
        <option value="full">Full</option>
        <option value="partial">Partial</option>
      </select>
    </label>
    <label>Optional mileage
      <input name="mileage" inputmode="decimal" placeholder="10012.5">
    </label>
    <div class="preview-row derived-preview">
      <span>Derived total</span>
      <output id="fill-derived-total" aria-live="polite">&mdash;</output>
      <small>Calculated from quantity and completed unit price</small>
    </div>
    <button type="submit">Save fill</button>
  </form>
</section>
```

## Slice 6b — charge and standalone odometer

The browser fixture was extended before replacing the placeholder
charge text. RED, exact output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: FAIL - add-charge form is missing
```

The completed charge write uses one atomic mutation-only script for the
acquisition, charging subtype, cost state, optional delivered-energy
measurement, optional endpoint battery observations, and optional
charge-time odometer observation. The standalone odometer action keeps
the entered digits, precision, unit, local time, and zone.

First rich live writes, exact responses:

```console
$ curl ... --data-raw '{"vehicle":"Phase A Vehicle","definition":"Electricity","start":"2026-07-28T20:00","end":"2026-07-28T21:00","zone":"America/Chicago","energyDelivered":"42.75","energySource":"charger-reported","startBattery":"20.5","endBattery":"80","mileage":"10020.0","mileageUnit":"mi","costState":"free","currency":"usd"}' \
>   http://localhost:8082/apps/rover/add-charge
charge HTTP 201
body: Saved charge - Energy delivered 42.75 kWh

$ curl ... --data-raw '{"vehicle":"Phase A Vehicle","reading":"10021.125","unit":"mi","observed":"2026-07-28T21:05","zone":"America/Chicago"}' \
>   http://localhost:8082/apps/rover/add-odometer
odometer HTTP 201
body: Saved odometer - 10,021.125 mi
```

The read projection then returned human values only:

```console
$ curl -sS -b /tmp/rover-debug-jar \
>   http://localhost:8082/apps/rover/view > /tmp/rover-charge-view.html
$ rg -o '42\\.75 kWh|charger / reported|20\\.5%|80%|10,021\\.125 mi' \
>   /tmp/rover-charge-view.html
10,021.125 mi
42.75 kWh
charger / reported
20.5%
80%
```

Final GREEN, exact browser output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS**.

The charge screen contains no `full`, `partial`, or `Battery filled`
concept. Malformed bounds refuse as `%bad-range: charge.end`, malformed
odometer text refuses as `%bad-shape: odometer.reading`, and the served
read projection rejects raw identifiers and the submitted
`4125`/`10023125` machine integers.

## Slice 7 — stations and additives

RED was captured before the selectors existed:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: FAIL - fill station selector is missing
```

The form now offers a searchable saved-station selector, an explicit
`No station recorded`, and `Add new station…`. Creating a new station
atomically inserts the place, station, acquisition, fill, optional
station link, and additive links. A private station requires only its
place/station labels and kind; no address or coordinate placeholder is
created.

First live saved/new writes, exact responses:

```console
$ curl ... --data-raw '{"quantity":"5.111",...,"station":"Home Charger","additives":["Injector cleaner"]}' \
>   http://localhost:8082/apps/rover/add-fill
saved-station HTTP 201
body: Saved fill - $3.499 - derived $17.88

$ curl ... --data-raw '{"quantity":"5.222",...,"station":"new","newStationLabel":"UI Home Pump","newPlaceLabel":"UI Home","newStationKind":"private","additives":["Injector cleaner","Fuel stabilizer"]}' \
>   http://localhost:8082/apps/rover/add-fill
new-station HTTP 201
body: Saved fill - $3.499 - derived $18.27
```

GREEN, exact full browser output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS**.

Changing station or additive selections leaves the exact derived total
unchanged in Chromium. History renders `No station recorded` and
`No additives recorded` for absent link rows; one or several additives
render only their real labels as chips. The harness rejects a synthetic
`None` chip and any `0x` identifier.

## Slice 8 — per-vehicle display preference

RED before the control existed:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: FAIL - per-vehicle display preference control is missing
```

The live substrate predated the ratified 36th relation even though the
fresh-pour DDL already contained it. The targeted, real migration
result was:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/ensure-ui-schema.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun 0 0 0 [%results [%action 'CREATE TABLE %vehicle-display-preferences'] [%server-time 0x8000000d3907372d3429000000000000] [%schema-time 0x8000000d3907372d3429000000000000] 0] 0]
```

Distance conversion uses the exact rational identity
`1 mi = 1.609344 km`, performs integer half-up rounding only at final
display precision, and appends `(converted)`. The preference mutation
updates only `vehicle-display-preferences`; selecting source-native
deletes that vehicle's optional preference row.

Pure formatter and parser results:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-render.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %render-tests-pass]

$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-entry.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %entry-tests-pass]
```

GREEN browser output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS**.

`Fuel Evidence Vehicle` renders `32,186.9 km (converted)`. The admin
probe still returns its original odometer cells as value
`0x30d40` (`200000`), precision `1`, and unit atom `26989` (`%mi`),
while the separate preference row holds unit atom `28011` (`%km`).
`Phase A Vehicle` is reset to source-native and is unaffected.

## Final 16-fixture battery

Fixtures 1-14 and 16 run through one real-cookie browser-half command.
The command performs the writes and reads itself; a line is printed only
after every assertion represented by that line has passed.

Exact command and final post-restart output:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: browser measurements: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Per-fixture mapping of that real output:

| # | Fixture and real output | Result |
|---:|---|:---:|
| 1 | Logged-out request: `303`, empty Rover body, login redirect; live `+code` produced `urbauth`; authenticated shell returned `200`. | PASS |
| 2 | Bare public URL authenticated and served the Rover shell without Landscape. | PASS |
| 3 | Tile and four fonts returned `200`, exact bytes, `image/png` / `font/woff2`; docket charge was `site /apps/rover`, same-origin tile, no glob. | PASS |
| 4 | Vehicle/detail sweeps found `12.345 gal`, `$3.499`, `$43.20`, and no bare `12345`, `3499`, or `0x` ID. Charge/odometer sweeps likewise found no `4125`, `10023125`, or ID. | PASS |
| 5 | Chromium measured completed price `$3.499`; saved admin cells were exactly `quantity-milli 6543` and `unit-price-mills 3499`. | PASS |
| 6 | Total was an `OUTPUT/readonly`; standard `$43.19`, quantity change `$43.20`, price change `$43.32`, tank/evidence unchanged at `$43.19`. | PASS |
| 7 | Standard was `$43.19`; changing only settlement to cash produced `$43.20`. | PASS |
| 8 | Zero, one, and several additives round-tripped as honest absence or real labels; no synthetic `None` chip. | PASS |
| 9 | `No station recorded` round-tripped honestly. Saved/new private stations rendered; the new home station needed no address or coordinate placeholder. | PASS |
| 10 | Chromium returned `ordered=true stable=true` from two independently fetched real Obelisk projections. | PASS |
| 11 | Current odometer rendered as a grouped human value derived from observation rows; no vehicle odometer column or raw evidence value was emitted. | PASS |
| 12 | Two real latest observations with identical bounds rendered `Unavailable - latest observation times overlap`, never zero or an estimate. | PASS |
| 13 | Real malformed requests returned `%bad-shape: fill.quantity`, `%bad-range: charge.end`, and `%bad-shape: odometer.reading`, each with HTTP `400`. | PASS |
| 14 | One vehicle rendered `32,186.9 km (converted)` while the other stayed native; admin output retained source `200000`, precision `1`, unit `%mi`. | PASS |
| 16 | At 390x844 Chromium returned `overflow=false touch=true stacked=true font=true`; the minimum visible control height was at least 44px. | PASS |

Fixture 15 was run around a real shutdown and restart of only the
owned `rover-bel` pier. Before restart:

```console
before UI Home Pump => 20
before Fuel stabilizer => 8
before 41.25 kWh => 5
before 32,186.9 km (converted) => 1
before Unavailable - latest observation times overlap => 1
```

Exact restart command:

```console
$ tmux send-keys -t rover-bel C-d
$ tmux new-session -d -s rover-bel \
>   -c "$HOME/workspace/urbit/bin" \
>   './urbit -p 31350 /home/michael/piers/rover-bel'
```

After the restarted pier became live, the existing real Eyre session
fetched the same projection:

```console
after-restart HTTP 200 bytes:38450
after  UI Home Pump => 20
after  Fuel stabilizer => 8
after  41.25 kWh => 5
after  32,186.9 km (converted) => 1
after  Unavailable - latest observation times overlap => 1
restart markers: PASS
```

Fixture 15 result: **PASS**. The full browser-half command shown above
was then run again against the restarted pier and passed.

Final substrate and compilation checks:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/verify-schema.hoon "$HOME/piers/rover-bel"
... [%relation 'rover.sys.tables'] ... [%vector-count 36] ...

$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-render.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %render-tests-pass]

$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/run-test-entry.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun %entry-tests-pass]

$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/compile-rover.hoon "$HOME/piers/rover-bel"
[0 %avow 0 %noun 0]
```

Result: **PASS** — 36 relations, formatter/parser tests green, and the
Rover agent compiles on the pinned zuse 408 pier.

## 53-relation hub milestone

### Slice 1 - fresh re-pour

The schema fixture was added before the Hoon schema tape changed. Its first
real-pier run proved the expected RED state:

```console
$ bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 53 unique tables, 56 explicit RESTRICT FKs, zero forward references
schema-test: FAIL - live Obelisk has 36 relations (want 53)
```

The old disposable pier was preserved as
`~/piers/rover-bel-pre53-20260728-191712`. A fresh `~bel` was booted on the
unchanged brass-408k pill and Ames port 31350. The pinned, unmodified Obelisk
`master` desk at `eecab1b8` and the Rover desk were installed separately.
Rover then submitted the complete 53-table schema as one atomic `%tape`
action.

The Hoon schema arm was independently compared with `docs/schema-m0.sql`
after whitespace normalization:

```console
hoon tables 53 refs 56
docs tables 53 refs 56
schema arm matches docs exactly after whitespace normalization
```

GREEN, exact command and real output:

```console
$ bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 53 unique tables, 56 explicit RESTRICT FKs, zero forward references
schema-test: PASS - live Obelisk has 53 relations; all 56 FK constraints (58 column rows) are RESTRICT
```

Obelisk emits one metadata row per participating FK column, so the two
two-column composite foreign keys make 58 live metadata rows for 56 FK
constraints. Every live row reported `%restrict` for both update and delete;
none reported `%cascade` or `%set-default`.

The fresh pier's HTTP listener was re-resolved after boot and matched back to
the owned process:

```console
$ cat "$HOME/piers/rover-bel/.http.ports"
12323 insecure loopback
8082 insecure public

$ ss -lntp | grep 'pid=660917'
LISTEN 0 16 127.0.0.1:12323 0.0.0.0:* users:(("urbit",pid=660917,fd=88))
LISTEN 0 16 0.0.0.0:8082 0.0.0.0:* users:(("urbit",pid=660917,fd=87))
```

Pinned-agent and Rover compile gates:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/compile-obelisk.hoon "$HOME/piers/rover-bel" | tail -1
[0 %avow 0 %noun 0]

$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/compile-rover.hoon "$HOME/piers/rover-bel" | tail -1
[0 %avow 0 %noun 0]
```

Result: **PASS** - fresh 53-relation pour, 56 all-RESTRICT foreign-key
constraints, zero forward references, and both agents compile on zuse 408.

### Slice 2 - existing surface and subtype re-key

The carried-forward fuel-evidence fixture was run unchanged first. It failed
for the expected reason after the schema re-key:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/seed-fuel-evidence.hoon "$HOME/piers/rover-bel"
...
"INSERT: table [%dbo %energy-definition-octane] does not exist"
...
```

The fixture now creates an energy source `Gasoline`, a subtype
`Regular 87 E10`, and attaches the octane and blend evidence to that subtype.
It also records the vehicle's default subtype and the actual subtype selected
on each fill. The fuel, location, content-report, and browser read paths were
changed to join through `energy-definition-subtypes`.

The served fill-detail assertion was also added before the renderer change.
RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: FAIL - fill detail has no Fuel Subtype field
```

GREEN, exact real-Eyre command and output:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: browser measurements: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

The same response contains `FUEL SUBTYPE` and `Regular 87 E10`; octane is
read through the subtype join rather than from the energy source.

Hoon and real-query regression commands:

```console
$ for probe in run-test-render run-test-entry run-test-pricing compile-rover; do
>   PATH="$HOME/workspace/urbit/bin:$PATH" \
>     click -k -i "probes/$probe.hoon" "$HOME/piers/rover-bel" 2>/dev/null |
>     tail -1
> done
[0 %avow 0 %noun %render-tests-pass]
[0 %avow 0 %noun %entry-tests-pass]
[0 %avow 0 %noun %pricing-tests-pass]
[0 %avow 0 %noun 0]

$ for probe in fuel-evidence-report location-report content-report; do
>   PATH="$HOME/workspace/urbit/bin:$PATH" \
>     click -k -i "probes/$probe.hoon" "$HOME/piers/rover-bel" 2>/dev/null |
>     tail -1
> done
[0 %avow 0 %noun ...]
[0 %avow 0 %noun ...]
[0 %avow 0 %noun ...]
```

Result: **PASS** - all 16 carried-forward browser fixtures remain green after
the re-pour, and every existing subtype evidence/read path uses the new
subtype layer.

### Slice 3 - main hub

The navigation/readout assertions were added before the hub renderer. RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: FAIL - main hub is missing
```

The served fragment now opens on `MAIN`; Vehicles, History, Statistics,
Settings, Add Fill, Add Charge, and Add Odometer are separate hidden screens.
Every screen that returns to the hub has an `&lsaquo; MAIN` control. On this
fresh-install fixture, where `app-default-vehicle` is intentionally absent,
all six readouts say `Unavailable` with `No default vehicle is set`, and the
primary area explains how to choose or set one instead of guessing.

GREEN is the full real-Eyre command recorded in Slice 2 above, with these
additional assertions passing before the carried-forward checks:

```console
main hub: present
secondary destinations: add-odometer, vehicles-screen, history-screen,
                        statistics-screen, settings-screen
readouts: MOST RECENT ODOMETER, ECONOMY - LAST FILL, ECONOMY - LIFETIME,
          ESTIMATED DISTANCE TO NEXT FILL, BEST ECONOMY, WORST ECONOMY
back destination label: &lsaquo; MAIN
```

Result: **PASS** - the hub is the initial screen, purpose-built destinations
are one tap away, all back controls name `MAIN`, and unavailable fresh-state
derivations carry human reasons.

### Slice 4 - Add Fill

The exact-order assertion was added before rebuilding the form. RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: FAIL - Add Fill field order is wrong:
```

The real-substrate subtype fixture was also asserted before it was poured.
RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: FAIL - Add Fill is missing allowed subtype: Structure 87 AKI
```

`%seed-app-structure` then poured a single reservoir energy source with three
subtypes (87, 91, and 93 AKI), defaulted the vehicle to 91, linked Tow / Haul
only to Structure Vehicle, and created two real tag definitions. The form
offers all three subtypes and merely preselects 91. Switching to Mode Scope
Vehicle removes Tow / Haul from the selector. A single-source vehicle keeps
Energy Source as a vehicle property; the browser reports
`energy-source=vehicle-property`.

The Add Fill POST now writes the optional evidence as child/link rows in the
same mutation-only atomic script. Two POST fixtures prove both sides of the
unset rules: the first writes subtype 93, `%missed-fill`, Tow / Haul, and
55.5 mph while adding neither a drive-balance row nor a tag row; the second
writes an asserted 73% highway balance, two existing tags, and one
inline-created tag. The read path renders the affected economy interval as
unavailable with the missed-fill reason.

GREEN, exact real-Eyre command and output:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: browser measurements: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: subtypes, missed-fill break, scoped mode, exact speed, unset/asserted balance, and zero/many tags persist through real Obelisk
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Compile and pure-Hoon regression gates:

```console
$ for probe in run-test-render run-test-entry run-test-pricing compile-rover; do
>   PATH="$HOME/workspace/urbit/bin:$PATH" \
>     click -k -i "probes/$probe.hoon" "$HOME/piers/rover-bel" 2>/dev/null |
>     tail -1
> done
[0 %avow 0 %noun %render-tests-pass]
[0 %avow 0 %noun %entry-tests-pass]
[0 %avow 0 %noun %pricing-tests-pass]
[0 %avow 0 %noun 0]
```

Result: **PASS** - the Add Fill screen follows the ratified 16-field order,
uses `Calculated Total`, keeps Energy Source conditional, preserves the
visibly unset slider, and persists all newly supported evidence through the
real pinned Obelisk agent.

### Slice 5 - Vehicles and app default

The Vehicles assertions landed before the dedicated controls. RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: FAIL - Vehicles screen lacks Add Vehicle
```

The singleton check was also run before the app-default report query was
added. RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: FAIL - app-default-vehicle is not a one-row singleton after insert
```

The Vehicles screen now has Add Vehicle, Set Default, Remove, per-vehicle
Add Fill / Add Charge / Add Odometer actions, and an expandable settings
summary for Energy Source, Fuel Subtypes, Tank Size, Driving Modes, and
Display Preference. Removal first deletes removable configuration children
in the same atomic script; history and the `%app` default still fail closed
through RESTRICT.

The browser fixture inserts `%app`, changes it to another vehicle through
`UPDATE`, confirms exactly one row throughout, and verifies that deleting the
current default returns HTTP 409. It also adds and removes a new unreferenced
vehicle. The direct second-INSERT probe is rejected by Obelisk's singleton
primary key:

```console
$ PATH="$HOME/workspace/urbit/bin:$PATH" \
>   click -k -i probes/try-second-app-default.hoon \
>   "$HOME/piers/rover-bel" 2>/dev/null |
>   tail -1 | grep -o '^\[0 %avow 0 %noun 0 0 1'
[0 %avow 0 %noun 0 0 1
```

That leading result shape is the captured refusal (`%.n`); the underlying
real error is `INSERT: cannot add duplicate key` on the `%app` row.

GREEN, exact real-Eyre command and output:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: app default inserts once, changes via UPDATE, RESTRICTs deletion, and Vehicles add/remove round-trips
ui-test: browser measurements: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: subtypes, missed-fill break, scoped mode, exact speed, unset/asserted balance, and zero/many tags persist through real Obelisk
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

The same run proves:

- all entry forms initialize to the `%app` vehicle;
- a vehicle without `vehicle-tank-size` reports the distance estimate
  unavailable because tank size is not recorded;
- setting the known multi-source vehicle as default makes the hub offer both
  Add Fill and Add Charge; and
- Tow / Haul remains absent from Mode Scope Vehicle.

Result: **PASS** - vehicle add/remove, default selection, per-vehicle entry
actions and configuration summaries are live, while singleton and FK
restrictions remain enforced by the real database.

### Slice 6 - History filter, detail, and edit

The History structure assertions ran before the placeholder was replaced.
RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: FAIL - History screen lacks vehicle filter
```

History is now a separate screen. Each row presents Date, Odometer, Gallons,
and Total Cost; selecting a row opens its full record and edit form. The
filter initializes from the `%app` default, and the browser asserts that every
initially visible row belongs to that vehicle before switching to Structure
Vehicle and opening a detail.

The edit fixture creates a uniquely labelled vehicle through the real Vehicles
endpoint, writes a fill for it, edits that record from 3.000 gallons at
`$3.499` to 3.333 gallons at `$3.599`, and reads back both the edited source
quantity and the recalculated `$12.00` total. The boundary identifies the
record with owner-visible vehicle/date context; no acquisition ID enters the
HTML or POST.

GREEN, exact command and real output:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: app default inserts once, changes via UPDATE, RESTRICTs deletion, and Vehicles add/remove round-trips
ui-test: browser measurements: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 history=Mode Scope Vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: subtypes, missed-fill break, scoped mode, exact speed, unset/asserted balance, and zero/many tags persist through real Obelisk
ui-test: History defaults to the app vehicle; row detail opens and edit round-trips through Obelisk
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS** - default filtering, four-column rows, detail expansion, and
edit/readback all execute over authenticated Eyre and real Obelisk state.
