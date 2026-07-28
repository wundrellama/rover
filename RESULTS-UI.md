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
