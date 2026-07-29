# Rover UI milestone results

## 2026-07-29 dev re-pin — Part 1 gate

The Obelisk compatibility unit is now pinned to upstream `dev`
`2b72856e9fc0ca50391eb653540edf6574bffd04`. The first source check was
intentionally red against the old master mold:

```console
$ bash bin/dev-pin-test.sh
dev-pin-test: FAIL - Rover AST SHA is c2507e65d513747a161c3f351ddb4d8582bfc98b3dccb3221519764b9e8ebddb (want c74bf1c911b61b7abb4de8c98b28b30d684e5e3c0b10a0c65f759f64ee9f93dd)
```

After copying the dev mold and porting Rover's exhaustive result variants:

```console
$ bash bin/dev-pin-test.sh
dev-pin-test: PASS - fixture 55 source gate - dev commit and compatibility mold SHA match

$ sha256sum desk/sur/obelisk-ast.hoon \
> /tmp/rover-obelisk-2b72856e/desk/sur/obelisk-ast.hoon
c74bf1c911b61b7abb4de8c98b28b30d684e5e3c0b10a0c65f759f64ee9f93dd  desk/sur/obelisk-ast.hoon
c74bf1c911b61b7abb4de8c98b28b30d684e5e3c0b10a0c65f759f64ee9f93dd  /tmp/rover-obelisk-2b72856e/desk/sur/obelisk-ast.hoon
```

The dev reference-doc audit found no DDL grammar drift from master.
`dml-insert.md` adds query-backed `INSERT`/`INSERT FORCE`; `scry.md` is new;
`security-permissions.md` adds design notes. The 64-relation pour itself
empirically exercises the multi-FK comma continuation grammar.

The disposable gate ship is `~wanbel`, pier
`~/piers/rover-wanbel`, Ames port `31361`, Eyre public port `8084`.
The dojo proves the dev desk is live on zuse 408:

```console
> =ob -build-file /=obelisk=/app/obelisk/hoon
> ?=(^ ob)
%.y
> +vats %obelisk
%obelisk
  /sys/kelvin:            [%zuse 408] [%zuse 409] [%zuse 410] [%zuse 411]
  %cz hash ends in:       hujs5
  essential desk:         no
  app status:             running
  source ship:            ~
  pending updates:        ~
  /desk/bill:             ~[%obelisk]
> .^(@uv %cz /=obelisk=)
0v4.g40be.9nhgs.tcmcf.7005e.knv1v.p931t.dl45l.1gham.s38hq.hujs5
```

The one atomic mutation-only script created all 64 relations on dev. The
post-pour live metadata gate passed:

```console
$ bash bin/schema-test.sh "$HOME/piers/rover-wanbel"
schema-test: PASS - DDL has 64 unique tables, 71 explicit RESTRICT FKs, zero forward references
schema-test: PASS - fixture 17 - live Obelisk has 64 relations; all 71 FK constraints (74 column rows) are RESTRICT; zero cascade/set-default
```

Fixtures 55–56: **PASS**. Part 1's hard gate is closed.

## 2026-07-29 fresh ship — Part 2 gate

Starter-pack coverage was added test-first. The pre-change real Eyre response
failed on the first genuinely absent category:

```console
$ ROVER_FRESH_ONLY=1 bash bin/ui-test.sh "$HOME/piers/rover-wanbel"
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: FAIL - fixture 57 starter additive set mismatch; actual: <none>
```

The final served ship is the newly booted child `~binbel`, at
`~/piers/rover-binbel`. It was booted in tmux from
`brass-408k-1.pill`; Ames is fixed at `31362`. After installation its
Urbit process PID `1557158` owns Eyre public port `8085` and loopback
port `12326`:

```console
$ ss -lntp | grep 'pid=1557158'
LISTEN 0 16 127.0.0.1:12326 0.0.0.0:* users:(("urbit",pid=1557158,fd=85))
LISTEN 0 16 0.0.0.0:8085    0.0.0.0:* users:(("urbit",pid=1557158,fd=84))
```

On that fresh ship, dev Obelisk is running and the live schema metadata
proves the same 64-table, all-RESTRICT pour:

```console
> +vats %obelisk
%obelisk
  /sys/kelvin:            [%zuse 408] [%zuse 409] [%zuse 410] [%zuse 411]
  %cz hash ends in:       hujs5
  app status:             running

$ bash bin/schema-test.sh "$HOME/piers/rover-binbel"
schema-test: PASS - DDL has 64 unique tables, 71 explicit RESTRICT FKs, zero forward references
schema-test: PASS - fixture 17 - live Obelisk has 64 relations; all 71 FK constraints (74 column rows) are RESTRICT; zero cascade/set-default
```

Only the starter action was run after the pour. The authenticated served HTML
contains the exact 8 energy definitions, exact 32 market subtypes, 2 additive
definitions, 5 driving modes, and 4 consumables. Its scenario-debris assertion
also searches for the fixture label families and found none:

```console
$ ROVER_FRESH_ONLY=1 bash bin/ui-test.sh "$HOME/piers/rover-binbel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 57 PASS - fresh ship serves exact energy, subtype, additive, driving-mode, and consumable starter packs with zero scenario data
```

Fixture 57: **PASS**. The old `~/piers/rover-bel` pier was left in place;
the disposable dev gate `~wanbel` was also left in place. Neither is the
served final database.

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

### Slice 7 - Add Charge and Add Odometer

These write paths were carried forward from the previous UI milestone and
remained green after the 53-relation re-pour. This slice separated their
purpose-built navigation from Vehicles and corrected the remaining owner
wording: Add Charge now says `Energy Source`, never `Definition`, and its
technical evidence selector says `Measurement source`. The Energy Source
control stays hidden for a single-source vehicle and is exposed only for a
multi-source configuration.

Exact authenticated requests and responses exercised by `bin/ui-test.sh`:

```console
POST /apps/rover/add-charge
bad range -> %bad-range: charge.end
valid -> Saved charge - Energy delivered 41.25 kWh

POST /apps/rover/add-odometer
bad shape -> %bad-shape: odometer.reading
valid -> Saved odometer - 10,023.125 mi
overlapping time -> Saved odometer - 10,024.125 mi
```

The subsequent real readback renders `41.25 kWh`, `21%`, `79.5%`,
`charger / reported`, and the overlapping-odometer reason
`Unavailable - latest observation times overlap`. The full green command is
the exact Slice 6 output above, including:

```console
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS** - Add Charge and Add Odometer are dedicated, named-back
screens with default-vehicle initialization and real Obelisk write/readback.

### Slice 8 - Statistics tables

The six-table assertion ran against the placeholder first. RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: FAIL - Statistics screen lacks table: economy-by-subtype
```

Statistics now contains exactly the milestone's tabular families:

- economy per fill by fuel subtype;
- fuel costs;
- distance between fills;
- time between fills;
- average price per unit; and
- distance per tank.

Recent real fills contribute human dates, vehicle labels, subtype labels,
calculated totals, and unit prices. Ineligible distance/economy figures remain
`Unavailable` beside their concrete requirements. Tank-dependent output says
that Rover never guesses a tank size. No canvas, SVG, chart library, or chart
markup is served.

GREEN used the exact full command/output recorded in Slice 6, with all six
`data-statistic` table assertions and the no-chart assertion passing before
the write fixtures:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
...
ui-test: History defaults to the app vehicle; row detail opens and edit round-trips through Obelisk
...
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS** - Statistics is tables-only, uses real human-unit figures
where available, and explains every unavailable derivation.

### Slice 9 - Settings and custom-field definitions

The Settings assertion was installed before the placeholder was replaced.
RED:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: FAIL - Settings lacks custom-field definition management
```

Settings now groups the theme controls, custom-field definition management,
default-vehicle control, and the intentionally deferred Import / Export and
Grants placeholders. Active `%fill` definitions render in Add Fill in their
declared order and type.

The browser fixture creates one number, text, and boolean definition. It
proves an empty mandatory number rejects the whole fill with HTTP 422, then
writes `12.345`, `hello`, and true in the same mutation-only script as the
fill. Direct urQL readback from the real database is:

```console
[%custom-field 116 'Number-1785288670414533630']
[%digits 25717 12345] [%decimals 25717 3]
[%value-unit %tas %unitless]

[%custom-field 116 'Text-1785288670414533630']
[%value 116 %hello]

[%custom-field 116 'Boolean-1785288670414533630']
[%value 102 0]
```

The fixture then attempts to change the valued text definition to number and
receives:

```console
%immutable: custom-field.content-type - archive and recreate
409
```

All three temporary definitions are archived afterward, leaving repeat runs
free of an accidental mandatory field.

The live pier crashed once in the runtime allocator while processing an
accumulated-data browser request. Its event log and state were not altered.
It was restarted using its established zuse-408 command, replayed through
event 2569, and its post-restart listener was matched by PID before the green
run:

```console
$ tmux new-session -d -s rover-bel \
>   "cd '$HOME/workspace/urbit/bin' && exec ./urbit -p 31350 '$HOME/piers/rover-bel'"
...
play (2569): done
http: web interface live on http://localhost:8082
http: loopback live on http://localhost:12323
pier (2582): live

$ pid="$(pgrep -f "urbit -p 31350 $HOME/piers/rover-bel" | head -1)"
$ echo "$pid"; ss -lntp | grep "pid=$pid,"
750256
LISTEN 0 16 127.0.0.1:12323 0.0.0.0:* users:(("urbit",pid=750256,fd=85))
LISTEN 0 16 0.0.0.0:8082 0.0.0.0:* users:(("urbit",pid=750256,fd=84))
```

GREEN, exact real-Eyre command and output after persistence replay:

```console
$ timeout 360 bin/ui-test.sh
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
ui-test: custom number/text/boolean values use typed relations; mandatory and immutable-type rules hold
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: **PASS** - Settings manages fill-targeted typed definitions over real
Eyre and Obelisk, mandatory values fail closed, and valued definitions require
archive-and-recreate for a content-type change.

## Final milestone fixture battery

Fixtures 1-16 remain represented by the carried real-Eyre checks above.
Fixtures 17-31 were rerun after the persistence restart and report
individually below.

Fixture 17 exact command and real output:

```console
$ bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 53 unique tables, 56 explicit RESTRICT FKs, zero forward references
schema-test: PASS - fixture 17 - live Obelisk has 53 relations; all 56 FK constraints (58 column rows) are RESTRICT; zero cascade/set-default
```

Result: **PASS**.

### Priority 0 fixture-harness repair

All **14** previously decorative fixture labels (18-31) are now attached to
live Eyre, Obelisk, or Chromium assertions in the block that produces each
label. The 14 bare `note "fixture NN PASS ..."` lines at the end of the script
were deleted. **Zero fixtures are UNVERIFIED.**

RED was proven by temporarily making the new fixture 18 assertion demand
octane rating `94`. Exact command and failure:

```console
$ bash bin/ui-test.sh "$HOME/piers/rover-bel"
...
ui-test: FAIL - fixture 18 subtype-level octane mismatch; actual Obelisk report: ... [%subtype 116 'Structure 93 AKI'] [%rating 25717 93] [%method %tas %aki] ...
```

The expectation was restored to `93`. GREEN exact command and complete real
output:

```console
$ bash bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: fixture 20 PASS - live Obelisk kept one %app row across INSERT/UPDATE and rejected a second INSERT
ui-test: fixture 21 PASS - live HTTP delete returned %restricted / 409 for the app-default vehicle
ui-test: app default inserts once, changes via UPDATE, RESTRICTs deletion, and Vehicles add/remove round-trips
ui-test: browser measurements: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 history=Mode Scope Vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: fixture 19 PASS - Chromium measured every source subtype selectable with only the default preselected: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 history=Mode Scope Vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 26 PASS - Chromium measured Tow / Haul for Structure Vehicle and zero modes for Mode Scope Vehicle: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 history=Mode Scope Vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 28 PASS - Chromium measured single-source as a vehicle property; live PHEV HTTP already exposed fill and charge: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 history=Mode Scope Vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 31 PASS - Chromium measured 390px overflow, stacking, and touch targets: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 history=Mode Scope Vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 18 PASS - live Obelisk report ties the selected subtype to rating 93
ui-test: fixture 23 PASS - live Obelisk counts stayed equal for unset balance and report stored asserted 73
ui-test: fixture 27 PASS - live Obelisk counts stayed equal for zero tags and linked existing plus inline tags
ui-test: subtypes, missed-fill break, scoped mode, exact speed, unset/asserted balance, and zero/many tags persist through real Obelisk
ui-test: fixture 22 PASS - live Obelisk break and served HTML both contain missed-fill
ui-test: fixture 30 PASS - live History default/detail measurement and Obelisk edit round-trip rendered 3.333 / $12.00
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: fixture 24 PASS - live hub says tank size is not recorded instead of storing or rendering a sentinel
ui-test: fixture 29 PASS - live hub combines human odometer units with concrete unavailable reasons
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: fixture 25 PASS - live HTTP and Obelisk report prove typed values, mandatory validation, and immutable used type
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Results: fixtures 18-31 **PASS** with live assertions. No decorative PASS
lines remain.

## 62-relation M0 re-pour

The schema fixture was changed first. RED, against the previous live pour:

```console
$ bash bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 62 unique tables, 68 explicit RESTRICT FKs, zero forward references
schema-test: FAIL - live Obelisk has 53 relations (want 62)
```

The previous disposable pier was preserved, recoverably, as:

```text
/home/michael/piers/rover-bel-pre62-20260728-221956
```

A fresh `~bel` was booted with the unchanged
`brass-408k-1.pill`, zuse 408, and Ames port 31350. Stock `%obelisk`
`master` at `eecab1b8` and `%rover` remain separate desks. The Hoon schema
arm was compared to `docs/schema-m0.sql` after stripping SQL comments and
normalizing whitespace:

```console
hoon tables 62 refs 68
docs tables 62 refs 68
match True
```

`probes/init-db.hoon` returned one successful database creation followed by
62 successful `CREATE TABLE` results in the DDL's declared order, ending:

```console
[%action 'CREATE TABLE %payment-method-definitions']
[%action 'CREATE TABLE %fuel-fill-payment-method']
[%action 'CREATE TABLE %fill-notes']
[%action 'CREATE TABLE %charging-session-subtype']
[%action 'CREATE TABLE %consumable-definitions']
[%action 'CREATE TABLE %consumable-acquisitions']
[%action 'CREATE TABLE %consumable-purchases']
[%action 'CREATE TABLE %consumable-acquisition-stations']
[%action 'CREATE TABLE %consumable-acquisition-odometers']
```

GREEN, exact live-metadata command and output:

```console
$ bash bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 62 unique tables, 68 explicit RESTRICT FKs, zero forward references
schema-test: PASS - fixture 17 - live Obelisk has 62 relations; all 68 FK constraints (70 column rows) are RESTRICT; zero cascade/set-default
```

The two two-column composite foreign keys account for the two additional
metadata rows. Compile gates:

```console
$ click -k -i probes/compile-obelisk.hoon "$HOME/piers/rover-bel" | tail -1
[0 %avow 0 %noun 0]
$ click -k -i probes/compile-rover.hoon "$HOME/piers/rover-bel" | tail -1
[0 %avow 0 %noun 0]
```

Post-restart PID and Eyre listener match:

```console
$ pgrep -a urbit | grep rover-bel
824227 ./urbit -F bel -p 31350 -B /home/michael/workspace/urbit/pills/brass-408k-1.pill -c /home/michael/piers/rover-bel
$ ss -lntp | grep 'pid=824227,'
LISTEN 0 16 127.0.0.1:12323 0.0.0.0:* users:(("urbit",pid=824227,fd=78))
LISTEN 0 16 0.0.0.0:8082 0.0.0.0:* users:(("urbit",pid=824227,fd=77))
```

Result: **PASS** - fresh 62-relation pour, 68 all-RESTRICT constraints,
zero forward references, exact DDL/arm parity, and both agents compile.

## Fixtures 32-35 - starter taxonomy and copy safety

Fixture 32 was installed before the production seed. RED on the fresh live
62-table pier:

```console
$ ROVER_FIXTURE_STOP=32 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: FAIL - fixture 32 starter sources mismatch; actual served source labels: <none>
```

The seed then copied eight source definitions and 32 market-aware subtypes
into owner-controlled Obelisk rows. The write used one mutation-only atomic
script; its real result ended at 8 energy definitions, 32 subtypes, 11
octane rows, and 9 blend rows. Rover first reads `energy-definitions`; when
any owner definitions exist, repeating the installation seed is a no-op.
It never issues `UPSERT` or rewrites a copy.

Fixture 35's owner rename action was deliberately absent for the first
combined run. Fixtures 33 and 34 passed, then the live poke failed at the
missing action:

```console
$ ROVER_FIXTURE_STOP=35 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: FAIL - fixture 35 owner rename failed: [0 %avow 1 %thread-fail ... %rename-energy-source ...]
```

GREEN, after adding the Rover-authorized lookup/update path:

```console
$ ROVER_FIXTURE_STOP=35 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
```

Fixture 33 creates one live Gasoline vehicle and one live Diesel vehicle,
loads Rover in headless Chromium, dispatches each vehicle selector change,
and reads only non-hidden subtype options. Fixture 34 checks the served
labels and separately reads `%aki`/`%ron` from
`energy-subtype-octane`. Fixture 35 renames the owner row, repeats the seed,
asserts exactly eight definitions and no duplicate `Gasoline`, then restores
the label and deletes its temporary vehicles through Rover.

```console
$ click -k -i probes/compile-rover.hoon "$HOME/piers/rover-bel" | tail -1
[0 %avow 0 %noun 0]
```

Result: fixtures 32-35 **PASS** against real Eyre, Chromium, Rover Gall,
and stock Obelisk.

## Fixtures 36-37 - vehicle screens and persisted settings

Fixture 36 was added against the old all-in-one screen. RED:

```console
$ ROVER_FIXTURE_STOP=36 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: FAIL - fixture 36 Vehicles screen is not a plain vehicle list; actual HTML: class="app-screen" ... <form id="vehicle-add-form"> ... <article class="vehicle-card"> ...
```

The fleet surface now has three distinct screens: a plain vehicle list, a
dedicated Add Vehicle form, and a selected vehicle's settings. Vehicle list
buttons carry human labels only; no raw IDs cross the HTML boundary.

Fixture 37 was then added before the edit route. RED:

```console
$ ROVER_FIXTURE_STOP=37 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: FAIL - fixture 37 vehicle edit failed:
405
```

GREEN after adding the Rover lookup/validation and one atomic
mutation-only settings script:

```console
$ ROVER_FIXTURE_STOP=37 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
```

Fixture 37 creates a real vehicle, posts the edit over authenticated Eyre,
reads separate live Obelisk result sets for `vehicles`,
`vehicle-tank-size`, and `vehicle-default-energy-subtype`, checks exact
`18.5 gal` evidence and subtype `95`, checks the values in served HTML, and
removes the temporary vehicle through Rover.

## Fixtures 38-39 - full fill correction and historical odometer

Fixture 38 first exposed the old partial edit contract. RED from authenticated
Eyre HTML:

```console
$ ROVER_FIXTURE_STOP=38 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: FAIL - fixture 38 fill-edit screen lacks editable notes; actual form HTML: ...
```

After expanding the decoder, lookup validation, and atomic correction script,
the live Obelisk report contained the corrected parent and child facts:

```console
[%quantity-milli 25717 11111]
[%tank-state %tas %partial]
[%unit-price-mills 25717 3599]
[%minor-unit-decimals 25717 2]
[%cash-increment-mills 25717 50]
[%subtype 116 13625]
[%station 116 'Edit Station']
[%driving-mode 116 'Mixed Driving']
[%digits 25717 555] [%decimals 25717 1] [%speed-unit %tas %mph]
[%highway-percent 25717 64]
[%note 116 'Owner corrected every field']
[%payment-method 116 'Personal Visa']
```

Fixture 39 was installed before the economy projection. The odometer
observation and `fuel-fill-odometers` join existed after the edit, but the
new failable statistics assertion produced this RED:

```console
$ ROVER_FIXTURE_STOP=39 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: FAIL - fixture 39 economy interval did not update to exact 9.000 mpg; actual statistics HTML: ...
```

Rover now derives eligible liquid-fuel intervals with integer arithmetic. It
finds the prior linked full fill, includes all compatible intervening
quantities, rejects break rows and incompatible units, and rounds half-up
only at the final thousandth.

GREEN, exact command and terminal output:

```console
$ ROVER_FIXTURE_STOP=39 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: fixture 38 field gate PASS - fill-edit screen exposes every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
```

The fixture proves the target fill had zero odometer links beforehand. After
the historical edit, the live joined row contained `value-digits 0x30d40`
(200000), one decimal place, and `%mi`; the served Statistics row then
contained the human-only attributes
`data-economy="9.000 mpg"` and the temporary vehicle label. Result:
fixtures 38-39 **PASS** with real Eyre, Gall, Obelisk, and served HTML.

## Fixtures 40-41 - manual station evidence

Fixture 40 began as a served-form assertion and failed before any write:

```console
$ ROVER_FIXTURE_STOP=40 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: FAIL - fixture 40 manual-station form lacks newAddressFormatted; actual HTML: hidden><label>Station label...
```

The Add Fill station editor now accepts a human name, formatted address,
individual address parts, and optional signed coordinates. The entry boundary
normalizes coordinates to exactly seven decimal places and rejects half-pairs
or out-of-range latitude/longitude. The mutation script inserts optional
address and coordinate child rows only when their evidence is present.

GREEN, exact command and output:

```console
$ ROVER_FIXTURE_STOP=41 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: fixture 38 field gate PASS - fill-edit screen exposes every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: fixture 40 PASS - manual station persists owner address parts and scale-7 coordinates while omitted parts create no rows
ui-test: fixture 41 PASS - name-only manual station writes no empty address rows and no zero-coordinate row
```

Fixture 40's four-result live report contained the station/place row, owner
formatted address, exactly five present part rows, and one coordinate row:

```console
[%latitude-scaled 25715 0x31ec2fa0]
[%longitude-scaled 25715 0x68767dfb]
[%coord-scale 25717 7]
[%source %tas %owner]
```

Those signed atoms are the exact `@sd` encodings of `41.8781136` and
`-87.6297982`; the absent `line2` produced no part row. Fixture 41's same
report had one station/place vector followed by three separate
`[%vector-count 0]` results for address, parts, and coordinates. Result:
fixtures 40-41 **PASS** on live Obelisk with no empty/sentinel child evidence.

## Fixtures 42-44 - consumables, charge subtype, payment method

Fixture 42 seeds an independent owner-controlled consumable pack (`DEF`,
`Washer Fluid`, `Motor Oil`, `Coolant`), records a real DEF purchase through
Eyre, and reads `consumable-acquisitions` joined to
`consumable-purchases`. Its live row retained `quantity-milli 2500`,
`unit-price-mills 4499`, `%standard`, `%us-usd-gal`, two minor-unit
decimals, and a 50-mill cash increment. The HTTP result was the exact
post-multiply total `$11.25`. The same vehicle's served economy attribute
was `9.000 mpg` both before and after the purchase, proving the consumable
did not enter the fuel denominator.

Fixture 43 creates an Electricity vehicle, records a `DC Fast` charge, and
then joins `charging-sessions` through `charging-session-subtype` to the
human subtype label. Fixture 44 writes two otherwise-identical fills; only
the second has a `Personal Visa` link. Both HTTP responses derive `$3.50`,
and both live parent rows retain `%standard`; only the linked fill returns
the payment label.

GREEN, exact command and output:

```console
$ ROVER_FIXTURE_STOP=44 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: fixture 38 field gate PASS - fill-edit screen exposes every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: fixture 40 PASS - manual station persists owner address parts and scale-7 coordinates while omitted parts create no rows
ui-test: fixture 41 PASS - name-only manual station writes no empty address rows and no zero-coordinate row
ui-test: fixture 42 PASS - DEF purchase uses snapshotted exact pricing and remains outside fuel-economy derivation
ui-test: fixture 43 PASS - charge persists its electricity subtype through charging-session-subtype
ui-test: fixture 44 PASS - payment method is descriptive; settlement mode and derived total are identical with or without its link
```

Result: fixtures 42-44 **PASS** against real Rover, stock Obelisk, Eyre, and
served projections. Payment method remains descriptive; charge subtype is a
charge-only link; consumables remain structurally outside energy acquisition
and fuel-economy relations.

## Complete legacy battery after 62-relation re-pour

The fresh re-pour invalidated an old harness assumption: fixtures 18-31
expected real support records but did not create them. The harness now pokes
each required dataset through Rover, checks the returned live noun, and
re-fetches the view from Eyre. No in-memory or HTTP mock was introduced.

The complete legacy-only diagnostic command finished GREEN:

```console
$ ROVER_LEGACY_ONLY=1 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 19 PASS - Chromium measured every source subtype selectable with only the default preselected: $3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly energy-source=vehicle-property balance=unset default=Mode Scope Vehicle subtypes=Structure 91 AKI/Structure 87 AKI|Structure 91 AKI|Structure 93 AKI modes=Tow / Haul/0 history=Mode Scope Vehicle/true/true overflow=false touch=true stacked=true font=true ordered=true stable=true
ui-test: fixture 26 PASS - Chromium measured Tow / Haul for Structure Vehicle and zero modes for Mode Scope Vehicle: ...
ui-test: fixture 28 PASS - Chromium measured single-source as a vehicle property; live PHEV HTTP already exposed fill and charge: ...
ui-test: fixture 31 PASS - Chromium measured 390px overflow, stacking, and touch targets: ...
ui-test: fixture 18 PASS - live Obelisk report ties the selected subtype to rating 93
ui-test: fixture 23 PASS - live Obelisk counts stayed equal for unset balance and report stored asserted 73
ui-test: fixture 27 PASS - live Obelisk counts stayed equal for zero tags and linked existing plus inline tags
ui-test: fixture 22 PASS - live Obelisk break and served HTML both contain missed-fill
ui-test: fixture 30 PASS - live History default/detail measurement and Obelisk edit round-trip rendered 3.333 / $12.00
ui-test: fixture 24 PASS - live hub says tank size is not recorded instead of storing or rendering a sentinel
ui-test: fixture 29 PASS - live hub combines human odometer units with concrete unavailable reasons
ui-test: fixture 25 PASS - live HTTP and Obelisk report prove typed values, mandatory validation, and immutable used type
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Fixtures 20 and 21 also report their live singleton and RESTRICT checks
immediately before the Chromium measurement. Thus all **14 previously fake
fixtures (18-31) now contain real assertions that can fail**. None is left
UNVERIFIED.

The ratified app-structure ruling says there is deliberately **no
vehicle-level subtype narrowing**: every subtype of an allowed energy source
must remain selectable, with only the per-vehicle default configurable.
Accordingly Rover does not implement or claim an “allowed subtype” filter
that would contradict the 62-relation contract.

## Served HTML review artifacts

The authenticated response fragments are included verbatim as:

- [Vehicles screen](artifacts/served-vehicles.html)
- [Fill-edit form](artifacts/served-fill-edit.html)

They were captured from the persisted real-pier state used by the final
44-fixture battery. The fill-edit artifact is the actual Eyre response, not a
template or mock. Exact artifact verification:

```console
$ sha256sum artifacts/served-vehicles.html artifacts/served-fill-edit.html
872c6c466bb55f50019f6f9763432b7a1d4b5b2b134f5d6575106a4e32a41266  artifacts/served-vehicles.html
63c68f05315e1f2ab7065aa835a3092c87e5a47c0d64fce5af9c98d2f258f255  artifacts/served-fill-edit.html

$ wc -c artifacts/served-vehicles.html artifacts/served-fill-edit.html
1971 artifacts/served-vehicles.html
4496 artifacts/served-fill-edit.html
6467 total
```

The first implementation represented most fill fields as hidden inputs. The
strengthened fixture correctly failed that served HTML. It now rejects hidden
placeholders and requires owner-visible controls:

```console
ui-test: fixture 38 field gate PASS - fill-edit screen exposes owner controls (not hidden inputs) for every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
```

The same fixture links `Octane Booster` and `Road Trip`, reads both child
rows back from Obelisk, and requires both to re-render as checked editable
controls. The follow-up odometer-only edit submits and preserves both lists.

## Final complete battery and clean handoff pier

The final full run began from a snapshot containing only the 62-relation pour
and starter packs. Fixture 36 initially failed because the assertion expected
a list item without first creating a vehicle. Its setup now creates a live
vehicle through Eyre before asserting list/settings navigation. The complete
run then passed:

```console
$ bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: fixture 38 field gate PASS - fill-edit screen exposes owner controls (not hidden inputs) for every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: fixture 40 PASS - manual station persists owner address parts and scale-7 coordinates while omitted parts create no rows
ui-test: fixture 41 PASS - name-only manual station writes no empty address rows and no zero-coordinate row
ui-test: fixture 42 PASS - DEF purchase uses snapshotted exact pricing and remains outside fuel-economy derivation
ui-test: fixture 43 PASS - charge persists its electricity subtype through charging-session-subtype
ui-test: fixture 44 PASS - payment method is descriptive; settlement mode and derived total are identical with or without its link
ui-test: fixture 19 PASS - Chromium measured every source subtype selectable with only the default preselected: ...
ui-test: fixture 26 PASS - Chromium measured Tow / Haul for Structure Vehicle and zero modes for Mode Scope Vehicle: ...
ui-test: fixture 28 PASS - Chromium measured single-source as a vehicle property; live PHEV HTTP already exposed fill and charge: ...
ui-test: fixture 31 PASS - Chromium measured 390px overflow, stacking, and touch targets: ...
ui-test: fixture 18 PASS - live Obelisk report ties the selected subtype to rating 93
ui-test: fixture 23 PASS - live Obelisk counts stayed equal for unset balance and report stored asserted 73
ui-test: fixture 27 PASS - live Obelisk counts stayed equal for zero tags and linked existing plus inline tags
ui-test: fixture 22 PASS - live Obelisk break and served HTML both contain missed-fill
ui-test: fixture 30 PASS - live History default/detail measurement and Obelisk edit round-trip rendered 3.333 / $12.00
ui-test: fixture 24 PASS - live hub says tank size is not recorded instead of storing or rendering a sentinel
ui-test: fixture 29 PASS - live hub combines human odometer units with concrete unavailable reasons
ui-test: fixture 25 PASS - live HTTP and Obelisk report prove typed values, mandatory validation, and immutable used type
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

The final exercised pier was preserved as
`/home/michael/piers/rover-bel-ui44-final-2`. The final served pier was restored
from the pre-fixture snapshot, restarted, and re-audited:

```console
$ bash bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 62 unique tables, 68 explicit RESTRICT FKs, zero forward references
schema-test: PASS - fixture 17 - live Obelisk has 62 relations; all 68 FK constraints (70 column rows) are RESTRICT; zero cascade/set-default

$ ROVER_FIXTURE_STOP=32 bin/ui-test.sh "$HOME/piers/rover-bel"
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels

$ ss -lntp | grep 'pid=960982,'
LISTEN 0 16 127.0.0.1:12322 0.0.0.0:* users:(("urbit",pid=960982,fd=120))
LISTEN 0 16 0.0.0.0:8081 0.0.0.0:* users:(("urbit",pid=960982,fd=119))
```

All **14 previously fake fixtures were converted to real, failable
assertions**. All numbered fixtures 18-44 are verified; none is left
UNVERIFIED.

## Prior hand-off disclosure - resolved by this follow-up

At the 44-fixture hand-off, two vehicle-configuration requirements were not
covered and were not complete:

- changing a vehicle's linked energy-source set after creation;
- creating or changing that vehicle's driving-mode membership.

That disclosure was accurate for the hand-off commit. Both paths are now
implemented and verified by fixtures 46-48 below.

Vehicle-level subtype narrowing is different: it is intentionally absent
under ratified app-structure ruling 8. Every subtype belonging to an allowed
energy source remains selectable; only the default subtype is configurable.

## Follow-up slice 1 - clean fixture seeding

The hand-off database contained two active duplicate source rows created by
older fixture code. They were retired in place with literal `Y` before this
run. Fixture seed actions now create all of their private energy definitions
archived, and selectable subtype queries require both the subtype and its
parent definition to be active. Historical fixture acquisitions still render;
test scaffolding no longer enters owner configuration controls.

Real run against `~/piers/rover-bel`, PID 1009190, Eyre port 8081:

```console
$ ROVER_FIXTURE_STOP=44 ./bin/ui-test.sh
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: fixture 38 field gate PASS - fill-edit screen exposes owner controls (not hidden inputs) for every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: fixture 40 PASS - manual station persists owner address parts and scale-7 coordinates while omitted parts create no rows
ui-test: fixture 41 PASS - name-only manual station writes no empty address rows and no zero-coordinate row
ui-test: fixture 42 PASS - DEF purchase uses snapshotted exact pricing and remains outside fuel-economy derivation
ui-test: fixture 43 PASS - charge persists its electricity subtype through charging-session-subtype
ui-test: fixture 44 PASS - payment method is descriptive; settlement mode and derived total are identical with or without its link
```

Fixtures 32-44 are all verified in this run; none is UNVERIFIED.

## Follow-up slice 2 - vehicle energy and mode membership

The create decoder now accepts the primary source plus an additional-source
list and a driving-mode list. The edit decoder accepts the complete selected
sets. Labels are resolved by server-side urQL reads; only IDs internal to Rover
enter the atomic mutation script. Removed memberships are updated to literal
`Y`, retained memberships to literal `N`, and only previously unseen
memberships are inserted. No membership row is deleted.

Real continuation of the Eyre/cookie run:

```console
ui-test: fixture 45 PASS - the run reached fixture 44 and the served source selector still has exactly eight owner sources
ui-test: fixture 46 PASS - create persisted active Gasoline and Electricity links and the vehicle hub offers fill and charge
ui-test: fixture 47 PASS - edit retired Gasoline with literal Y, retained Electricity, and preserved the historical fill
ui-test: fixture 48 PASS - create and edit mode memberships persist; the non-member mode is absent for the vehicle
```

Fixtures 45-48 are verified; none is UNVERIFIED.

## Follow-up slice 3 - 64-relation DEF configuration schema

The two relations were added in dependency order. `vehicle-consumables`
represents enablement by row presence and carries the retire-in-place flag.
`vehicle-consumable-tank-size` is keyed by the vehicle/consumable pair and is
not DEF-specific.

Pre-pour checks:

```console
$ python3 ~/.hermes/profiles/urbot/skills/urbit/obelisk-substrate/scripts/validate-ddl.py docs/schema-m0.sql --expect 64
tables: 64  unique: 64
FK constraints: 71  with explicit actions: 71

clean: no duplicates, no forward references, all FKs RESTRICT

$ bash bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 64 unique tables, 71 explicit RESTRICT FKs, zero forward references
schema-test: FAIL - live Obelisk has 62 relations (want 64)
```

Real populated-data pour and post-pour metadata check:

```console
$ click -k -i probes/ensure-def-schema.hoon "$HOME/piers/rover-bel"
[%action 'CREATE TABLE %vehicle-consumables']
[%action 'CREATE TABLE %vehicle-consumable-tank-size']

$ bash bin/schema-test.sh "$HOME/piers/rover-bel"
schema-test: PASS - DDL has 64 unique tables, 71 explicit RESTRICT FKs, zero forward references
schema-test: PASS - fixture 17 - live Obelisk has 64 relations; all 71 FK constraints (74 column rows) are RESTRICT; zero cascade/set-default
```

## Follow-up slice 4 - DEF enablement and tank capacity

Create and edit decode DEF configuration without adding any boolean column.
An enabled vehicle gets an active `vehicle-consumables` link; an omitted or
never-enabled vehicle gets no link row. Capacity is exact
digits/decimals/unit in the composite child relation. The Diesel check only
controls whether the settings fieldset is offered; storage remains capable of
representing an unusual real-world vehicle.

```console
ui-test: fixture 49 PASS - enabled Diesel has an active DEF link; disabled Diesel has no link row
ui-test: fixture 50 PASS - composite DEF tank size stores exact 55/1/gal, absence creates no row, and settings re-render 5.5 gal
```

Fixtures 49-50 are verified; none is UNVERIFIED.

## Follow-up slice 5 - DEF economy and fuel isolation

Rover does not transfer the full-to-full fuel algorithm to DEF. The implemented
rule uses the two latest consecutive DEF purchases, the closing purchase
quantity, and one exact odometer observation on each endpoint. Units must be
the same supported distance/volume pair. A purchase without odometer evidence
breaks the current interval and produces a reason; Rover does not bridge across
it or estimate the missed distance.

The first red fixture used August 1. Pinned Obelisk's date-literal parser
rejected the formatted `~2026.08.01` before any mutation. The fixture moved to
August 10 without changing its interval semantics. This was a test-data/parser
edge, not a relaxed assertion.

```console
ui-test: fixture 51 PASS - two odometer-linked DEF purchases derive and render exact 500.000 mi/gal DEF
ui-test: fixture 52 PASS - missing odometer evidence explicitly breaks the latest DEF interval with a human reason
ui-test: fixture 53 PASS - DEF remains outside fuel acquisitions and leaves exact 9.000 mpg unchanged
```

The DEF readout is available on the default-vehicle hub and in Statistics.
Fixtures 51-53 are verified; none is UNVERIFIED.

## Follow-up slice 6 - consumables starter pack

The same copy-on-selection rule used by energy starters now has a direct,
failable consumables proof. Fixture 54 renames the active owner `DEF` row,
repeats `%seed-starters`, queries active consumables through Rover, and requires
exactly four rows: the renamed DEF copy, Washer Fluid, Motor Oil, and Coolant.
It rejects a newly inserted `DEF` row, then restores the owner label.

The red run failed at the action mold before implementation:

```console
ui-test: FAIL - fixture 54 owner consumable rename failed: [0 %avow 1 %thread-fail ... %poke-fail ... %rename-consumable ...]
```

The real green result:

```console
ui-test: fixture 54 PASS - DEF, washer fluid, motor oil, and coolant seed once; an owner rename survives re-seeding
```

## Final complete battery

This is one unshortened invocation against real Eyre, Rover, and stock
Obelisk. `ROVER_CAPTURE_DIR` only writes the authenticated served-HTML
artifact; it does not skip or alter a fixture.

```console
$ ROVER_CAPTURE_DIR="$PWD/artifacts" ./bin/ui-test.sh
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: authenticated Rover shell served over real Eyre
ui-test: UA 571-C palette, fonts, glow control, and mobile rules served
ui-test: fixture 32 PASS - live view contains exactly eight starter sources including Diesel and zero fixture-debris labels
ui-test: fixture 33 PASS - Chromium selection exposes only source-owned subtypes: gasoline=100|85|87|88|89|90|91|92|93|95|98 diesel=#1|#2|Arctic|B20|B7|HVO100|Off-road (dyed)|Premium|R99|Winter
ui-test: fixture 34 PASS - labels are human 87/95 while Obelisk retains AKI/RON metadata
ui-test: fixture 35 PASS - owner rename survived re-seeding with eight rows and no duplicate/overwrite
ui-test: fixture 36 PASS - Vehicles is a plain list; Add Vehicle and vehicle taps open distinct screens
ui-test: fixture 37 PASS - label, exact tank size, and default subtype persist in Obelisk and re-render
ui-test: fixture 38 field gate PASS - fill-edit screen exposes owner controls (not hidden inputs) for every editable field
ui-test: fixture 38 PASS - every fill field round-trips through one atomic edit; untouched rounding integers remain exact
ui-test: fixture 39 PASS - historical fill edit creates and links odometer evidence and updates exact interval economy to 9.000 mpg
ui-test: fixture 40 PASS - manual station persists owner address parts and scale-7 coordinates while omitted parts create no rows
ui-test: fixture 41 PASS - name-only manual station writes no empty address rows and no zero-coordinate row
ui-test: fixture 42 PASS - DEF purchase uses snapshotted exact pricing and remains outside fuel-economy derivation
ui-test: fixture 43 PASS - charge persists its electricity subtype through charging-session-subtype
ui-test: fixture 44 PASS - payment method is descriptive; settlement mode and derived total are identical with or without its link
ui-test: fixture 45 PASS - the run reached fixture 44 and the served source selector still has exactly eight owner sources
ui-test: fixture 46 PASS - create persisted active Gasoline and Electricity links and the vehicle hub offers fill and charge
ui-test: fixture 47 PASS - edit retired Gasoline with literal Y, retained Electricity, and preserved the historical fill
ui-test: fixture 48 PASS - create and edit mode memberships persist; the non-member mode is absent for the vehicle
ui-test: fixture 49 PASS - enabled Diesel has an active DEF link; disabled Diesel has no link row
ui-test: fixture 50 PASS - composite DEF tank size stores exact 55/1/gal, absence creates no row, and settings re-render 5.5 gal
ui-test: fixture 51 PASS - two odometer-linked DEF purchases derive and render exact 500.000 mi/gal DEF
ui-test: fixture 52 PASS - missing odometer evidence explicitly breaks the latest DEF interval with a human reason
ui-test: fixture 53 PASS - DEF remains outside fuel acquisitions and leaves exact 9.000 mpg unchanged
ui-test: fixture 54 PASS - DEF, washer fluid, motor oil, and coolant seed once; an owner rename survives re-seeding
ui-test: vehicle list/detail render real rows in human units with no raw IDs
ui-test: malformed fill refuses as %bad-shape: fill.quantity
ui-test: fixture 20 PASS - live Obelisk kept one %app row across INSERT/UPDATE and rejected a second INSERT
ui-test: fixture 21 PASS - live HTTP delete returned %restricted / 409 for the app-default vehicle
ui-test: browser completes $3.49 to $3.499 and derives an exact non-editable total
ui-test: fixture 19 PASS - Chromium measured every source subtype selectable with only the default preselected
ui-test: fixture 26 PASS - Chromium measured Tow / Haul for an assigned vehicle and zero modes for a non-member vehicle
ui-test: fixture 28 PASS - Chromium measured single-source as a vehicle property; live PHEV HTTP already exposed fill and charge
ui-test: fixture 31 PASS - Chromium measured 390px overflow, stacking, and touch targets
ui-test: app default inserts once, changes via UPDATE, RESTRICTs deletion, and Vehicles add/remove round-trips
ui-test: fixture 18 PASS - live Obelisk report ties the selected subtype to rating 93
ui-test: fixture 23 PASS - live Obelisk counts stayed equal for unset balance and report stored asserted 73
ui-test: fixture 27 PASS - live Obelisk counts stayed equal for zero tags and linked existing plus inline tags
ui-test: subtypes, missed-fill break, scoped mode, exact speed, unset/asserted balance, and zero/many tags persist through real Obelisk
ui-test: fixture 22 PASS - live Obelisk break and served HTML both contain missed-fill
ui-test: fixture 30 PASS - live History default/detail measurement and Obelisk edit round-trip rendered 3.333 / $12.00
ui-test: valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived $22.89
ui-test: station none/saved/new and additive zero/one/several render honestly
ui-test: per-vehicle km preference converts and labels one vehicle without rewriting evidence
ui-test: fixture 24 PASS - live hub says tank size is not recorded instead of storing or rendering a sentinel
ui-test: fixture 29 PASS - live hub combines human odometer units with concrete unavailable reasons
ui-test: charge and standalone odometer save through Obelisk and render source-native evidence
ui-test: fixture 25 PASS - live HTTP and Obelisk report prove typed values, mandatory validation, and immutable used type
ui-test: tile and four font faces have exact bytes and content-types
ui-test: PASS - docket charge is site /apps/rover with same-origin tile and no glob
```

Result: the clean battery invocation reaches fixture 54 and its complete
legacy regression tail exits zero. Fixtures 32-54 are all genuinely verified.
Nothing is left UNVERIFIED.

## Served DEF vehicle-settings HTML

The exact authenticated Eyre response fragment is committed as
[served-vehicle-settings-def.html](artifacts/served-vehicle-settings-def.html).
It is the full vehicle-settings `<article>`, not a template. Its live DEF
configuration fieldset is:

```html
<fieldset data-def-configuration><legend>DEF configuration</legend><label><input type="checkbox" name="defEnabled" value="yes" checked> Enable DEF</label><label>DEF tank size<input name="defTankSize" inputmode="decimal" value="5.5"></label><label>DEF tank unit<select name="defTankUnit"><option value="gal" selected>gal</option><option value="litre">litre</option></select></label></fieldset>
```

Artifact verification:

```console
$ sha256sum artifacts/served-vehicle-settings-def.html
cc43a3437cdb822a4da68caaa0f17968173f083734ac60a756aa561127f5fbc5  artifacts/served-vehicle-settings-def.html
$ wc -c artifacts/served-vehicle-settings-def.html
4886 artifacts/served-vehicle-settings-def.html
```
