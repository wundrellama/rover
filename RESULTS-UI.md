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
