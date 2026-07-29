#!/usr/bin/env bash
# Rover browser-half fixtures over real Eyre. No loopback auto-auth and no mocks.
set -uo pipefail

PIER="${1:-$HOME/piers/rover-bel}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "ui-test: FAIL - $*" >&2; exit 1; }
note() { echo "ui-test: $*"; }

[ -S "$PIER/.urb/conn.sock" ] || { echo "no conn.sock under $PIER" >&2; exit 2; }
command -v click >/dev/null 2>&1 || PATH="$HOME/workspace/urbit/bin:$PATH"
command -v click >/dev/null 2>&1 || { echo "click not on PATH" >&2; exit 2; }

PORT="$(awk '/insecure public/{print $1}' "$PIER/.http.ports")"
[ -n "$PORT" ] || { echo "no public http port in $PIER/.http.ports" >&2; exit 2; }
URL="http://localhost:$PORT"

click_file() {
  local body="$1" target="${2:-$PIER}" file out
  file="$(mktemp /tmp/rover-ui-test.XXXXXX.hoon)"
  printf '%s\n' "$body" > "$file"
  out="$(click -k -i "$file" "$target" 2>/dev/null | tail -1)"
  rm -f "$file"
  printf '%s\n' "$out"
}

derive_code() {
  local target="$1" raw decimal dotted
  raw="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
(pure:m !>(.^(@p %j /(scot %p our.bowl)/code/(scot %da now.bowl)/(scot %p our.bowl))))' "$target" \
    | sed 's/^\[0 %avow 0 %noun //; s/\]$//')"
  decimal="$(python3 -c "print(int('$raw', 0))" 2>/dev/null)" || return 1
  case "$decimal" in (''|*[!0-9]*) return 1;; esac
  dotted="$(printf '%s' "$decimal" | rev | sed 's/[0-9]\{3\}/&./g' | rev | sed 's/^\.//')"
  printf '`@p`%s\n' "$dotted" | urbit eval 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
    | grep -oE '[a-z]{6}(-[a-z]{6}){3}' | head -1
}

CODE="$(derive_code "$PIER")"
[ -n "$CODE" ] || fail "could not derive +code"
JAR="$(mktemp /tmp/rover-ui-cookie.XXXXXX)"
HDRS="$(mktemp /tmp/rover-ui-headers.XXXXXX)"
ASSET="$(mktemp /tmp/rover-ui-asset.XXXXXX)"
cleanup() { rm -f "$JAR" "$HDRS" "$ASSET"; }
trap cleanup EXIT

response="$(curl -s -o /dev/null -w '%{http_code} %{size_download} %{redirect_url}' "$URL/apps/rover")"
case "$response" in
  "303 0 $URL/~/login?redirect="*) ;;
  *) fail "logged-out GET /apps/rover -> '$response' (want 303, empty login redirect)" ;;
esac
note "logged-out browser receives login redirect with no Rover body"

curl -s -c "$JAR" -o /dev/null "$URL/~/login" --data-raw "password=$CODE"
grep -q urbauth "$JAR" || fail "login with +code did not yield urbauth cookie"

body="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "authenticated GET /apps/rover not 200"
grep -qi '^content-type: text/html' "$HDRS" || fail "shell content-type is not text/html"
grep -q 'ROVER' <<<"$body" || fail "served shell has no Rover designation"
note "authenticated Rover shell served over real Eyre"

grep -q -- '--rv-bg: #0b0a08' <<<"$body" || fail "UA 571-C background token missing"
grep -q -- '--rv-amber: #d8b843' <<<"$body" || fail "UA 571-C amber token missing"
[ "$(grep -c '@font-face' <<<"$body")" -eq 4 ] || fail "shell does not declare four Berkeley Mono faces"
grep -q 'font-variant-numeric: tabular-nums' <<<"$body" || fail "tabular numerals are not active"
grep -q 'id="glow-toggle"' <<<"$body" || fail "glow control is missing"
grep -q 'min-height: 44px' <<<"$body" || fail "44px touch target rule is missing"
grep -q '@media (min-width: 48rem)' <<<"$body" || fail "mobile-first wide breakpoint is missing"
grep -q 'overflow-x: hidden' <<<"$body" || fail "narrow viewport overflow guard is missing"
note "UA 571-C palette, fonts, glow control, and mobile rules served"

view="$(curl -s -b "$JAR" -D "$HDRS" "$URL/apps/rover/view")"
grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "vehicle view not 200"
grep -q 'Phase A Vehicle' <<<"$view" || fail "vehicle view has no seeded vehicle"
grep -Eq '[0-9]{1,3}(,[0-9]{3})+\.[0-9]+ (mi|km)' <<<"$view" \
  || fail "current odometer is not human-formatted"
grep -q '12.345 gal' <<<"$view" || fail "fill quantity is not human-formatted"
grep -q '\$3\.499' <<<"$view" || fail "unit price is not human-formatted"
grep -q '\$43\.20' <<<"$view" || fail "derived fill total is not rendered"
grep -q 'DERIVED' <<<"$view" || fail "fill total is not labelled derived"
grep -q 'FUEL SUBTYPE' <<<"$view" || fail "fill detail has no Fuel Subtype field"
grep -q 'Regular 87 E10' <<<"$view" ||
  fail "fill detail does not render the subtype label"
if grep -Eq '(^|[^0-9,.])(12345|3499)([^0-9,.]|$)|0x[0-9a-fA-F]+' <<<"$view"; then
  fail "vehicle view leaked a raw machine value or ID"
fi
note "vehicle list/detail render real rows in human units with no raw IDs"

grep -q 'id="fill-form"' <<<"$view" || fail "add-fill form is missing"
grep -q 'id="fill-price-completed"' <<<"$view" || fail "completed-price preview is missing"
grep -q '<output id="fill-derived-total"' <<<"$view" \
  || fail "derived total is not a non-input output"
if grep -Eq '<input[^>]+name="(total|unitPriceMills|quantityMilli)"' <<<"$view"; then
  fail "add-fill form asks for a derived total or machine representation"
fi
grep -q 'Energy delivered' <<<"$view" || fail "add-charge surface lacks Energy delivered wording"
grep -q 'id="charge-form"' <<<"$view" || fail "add-charge form is missing"
grep -q 'name="energyDelivered"' <<<"$view" \
  || fail "add-charge form lacks optional delivered energy"
grep -q 'name="energySource"' <<<"$view" \
  || fail "add-charge form lacks delivered-energy source"
grep -q 'name="costState"' <<<"$view" || fail "add-charge form lacks cost state"
charge_html="${view#*id=\"add-charge\"}"
charge_html="${charge_html%%</section>*}"
if grep -Eqi 'full|partial|battery filled' <<<"$charge_html"; then
  fail "add-charge screen contains a fuel tank-state concept"
fi
grep -q 'id="odometer-form"' <<<"$view" || fail "standalone odometer form is missing"
grep -q 'name="reading"' <<<"$view" || fail "odometer form lacks source-native reading"
grep -q 'id="fill-station"' <<<"$view" || fail "fill station selector is missing"
grep -q '>No station recorded<' <<<"$view" \
  || fail "station selector lacks explicit no-station choice"
grep -q '>Add new station&hellip;<' <<<"$view" \
  || fail "station selector lacks add-new choice"
grep -q 'id="fill-additives"' <<<"$view" || fail "fill additives multi-select is missing"
if grep -Eqi '<[^>]+class="[^"]*chip[^"]*"[^>]*>None<' <<<"$view"; then
  fail "zero additives render as a synthetic None chip"
fi
grep -q 'class="preference-form"' <<<"$view" \
  || fail "per-vehicle display preference control is missing"

bad_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"wat","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T19:22","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[]}' \
  "$URL/apps/rover/add-fill")"
[ "$bad_fill" = $'%bad-shape: fill.quantity\n400' ] \
  || fail "malformed fill did not name its field: $bad_fill"
note "malformed fill refuses as %bad-shape: fill.quantity"

PLAYWRIGHT_ROOT="${PLAYWRIGHT_ROOT:-$HOME/git/hermes-workspace/node_modules/.pnpm/playwright@1.58.2/node_modules}"
CHROMIUM_BIN="${CHROMIUM_BIN:-$HOME/.cache/ms-playwright/chromium-1217/chrome-linux64/chrome}"
[ -d "$PLAYWRIGHT_ROOT/playwright" ] || fail "Playwright package not found at $PLAYWRIGHT_ROOT"
[ -x "$CHROMIUM_BIN" ] || fail "Chromium not found at $CHROMIUM_BIN"
preview="$(
  URL="$URL" JAR="$JAR" CHROMIUM_BIN="$CHROMIUM_BIN" \
    NODE_PATH="$PLAYWRIGHT_ROOT" node <<'NODE'
const {chromium} = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_BIN
  });
  const page = await browser.newPage({viewport: {width: 390, height: 844}});
  const raw = fs.readFileSync(process.env.JAR, 'utf8');
  const cookie = raw.match(/urbauth-~bel\s+([^\s]+)/);
  if (!cookie) throw new Error('urbauth cookie missing');
  await page.context().addCookies([{
    name: 'urbauth-~bel',
    value: cookie[1],
    domain: 'localhost',
    path: '/'
  }]);
  await page.goto(`${process.env.URL}/apps/rover`);
  const fillForm = page.locator('#fill-form');
  await fillForm.waitFor({state: 'attached'});
  await page.locator('[data-open-screen="add-fill"]').click();
  await fillForm.locator('[name="vehicle"]').selectOption({label: 'Phase A Vehicle'});
  await fillForm.locator('[name="definition"]').selectOption({label: 'Regular 87'});
  await fillForm.locator('[name="quantity"]').fill('12.344');
  await fillForm.locator('[name="price"]').fill('$3.49');
  const read = selector => page.locator(selector).evaluate(element => element.value);
  const price = await read('#fill-price-completed');
  const standard = await read('#fill-derived-total');
  await fillForm.locator('[name="quantity"]').fill('12.345');
  const afterQuantity = await read('#fill-derived-total');
  await fillForm.locator('[name="quantity"]').fill('12.344');
  await fillForm.locator('[name="price"]').fill('$3.50');
  const afterPrice = await read('#fill-derived-total');
  await fillForm.locator('[name="price"]').fill('$3.49');
  await fillForm.locator('[name="tank"]').selectOption('partial');
  const afterTank = await read('#fill-derived-total');
  await fillForm.locator('[name="station"]').selectOption('Home Charger');
  const firstAdditive = fillForm.locator('[name="additives"]').first();
  if (await firstAdditive.count()) await firstAdditive.check();
  const afterEvidence = await read('#fill-derived-total');
  await fillForm.locator('[name="settlement"]').selectOption('cash');
  const cash = await read('#fill-derived-total');
  const shape = await page.locator('#fill-derived-total').evaluate(element => ({
    tag: element.tagName,
    editable: element.isContentEditable
  }));
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > innerWidth
  );
  const mobile = await page.evaluate(async () => {
    const visible = [...document.querySelectorAll(
      'button, select, input:not([type="checkbox"]):not([type="hidden"])'
    )]
      .filter(element => element.offsetParent !== null);
    const minTouch = Math.min(...visible.map(
      element => element.getBoundingClientRect().height
    ));
    const project = html => {
      const documentCopy = new DOMParser().parseFromString(html, 'text/html');
      const vehicle = [...documentCopy.querySelectorAll('.vehicle-card')]
        .find(card => card.querySelector('h2')?.textContent === 'Phase A Vehicle');
      return [...vehicle.querySelectorAll('.history-card')].map(card => ({
        time: card.querySelector('time').textContent.slice(0, 19),
        text: card.textContent.replace(/\s+/g, ' ').trim()
      }));
    };
    const first = project(await (await fetch('/apps/rover/view')).text());
    const second = project(await (await fetch('/apps/rover/view')).text());
    const ordered = first.every(
      (event, index) => index === 0 || first[index - 1].time <= event.time
    );
    return {
      touch: minTouch >= 44,
      stacked: getComputedStyle(document.querySelector('#vehicle-view'))
        .gridTemplateColumns === 'none',
      font: document.fonts.check('12px "Berkeley Mono"'),
      ordered,
      stable: JSON.stringify(first) === JSON.stringify(second)
    };
  });
  console.log(
    `${price} standard=${standard} quantity=${afterQuantity} price=${afterPrice} ` +
    `after-tank=${afterTank} ` +
    `after-evidence=${afterEvidence} cash=${cash} ` +
    `total=${shape.tag}/${shape.editable ? 'editable' : 'readonly'} ` +
    `overflow=${overflow} touch=${mobile.touch} stacked=${mobile.stacked} ` +
    `font=${mobile.font} ordered=${mobile.ordered} stable=${mobile.stable}`
  );
  await browser.close();
})().catch(error => {
  console.error(error);
  process.exit(1);
});
NODE
)"
[ "$preview" = '$3.499 standard=$43.19 quantity=$43.20 price=$43.32 after-tank=$43.19 after-evidence=$43.19 cash=$43.20 total=OUTPUT/readonly overflow=false touch=true stacked=true font=true ordered=true stable=true' ] \
  || fail "browser fill preview mismatch: $preview"
note "browser measurements: $preview"
note "browser completes \$3.49 to \$3.499 and derives an exact non-editable total"

saved_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"6.543","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-28T19:21","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[]}' \
  "$URL/apps/rover/add-fill")"
[ "$saved_fill" = $'Saved fill - $3.499 - derived $22.89\n201' ] \
  || fail "valid fill was not saved: $saved_fill"
history="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%vehicle-history ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))')"
grep -q '\[%quantity-milli 25717 6543\].*\[%unit-price-mills 25717 3499\]' <<<"$history" \
  || fail "saved fill did not retain exact 6543/3499 machine integers"
view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q '6.543 gal' <<<"$view" || fail "saved fill quantity did not render back to a human"
grep -q '\$22\.89' <<<"$view" || fail "saved fill derived total did not render"
note "valid human fill saves exact 6543/3499 integers and renders 6.543 gal at derived \$22.89"

saved_station_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"5.111","price":"$3.49","profile":"us-usd-gal","tank":"partial","settlement":"standard","observed":"2026-07-29T00:10","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"Home Charger","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":["Injector cleaner"]}' \
  "$URL/apps/rover/add-fill")"
[ "$saved_station_fill" = $'Saved fill - $3.499 - derived $17.88\n201' ] \
  || fail "saved-station fill failed: $saved_station_fill"

new_station_fill="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"5.222","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-29T00:20","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"UI Home Pump","newPlaceLabel":"UI Home","newStationKind":"private","additives":["Injector cleaner","Fuel stabilizer"]}' \
  "$URL/apps/rover/add-fill")"
[ "$new_station_fill" = $'Saved fill - $3.499 - derived $18.27\n201' ] \
  || fail "new-station fill failed: $new_station_fill"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q 'Home Charger' <<<"$view" || fail "saved private station did not render"
grep -q 'UI Home Pump' <<<"$view" || fail "new private station did not render"
grep -q 'Injector cleaner' <<<"$view" || fail "one-additive fill did not render"
grep -q 'Fuel stabilizer' <<<"$view" || fail "several-additive fill did not render"
grep -q 'No station recorded' <<<"$view" || fail "zero-station fill is not honest"
grep -q 'No additives recorded' <<<"$view" || fail "zero-additive fill is not honest"
if grep -Eq '<span class="chip">None</span>|0x[0-9a-fA-F]+' <<<"$view"; then
  fail "station/additive history leaked a synthetic None chip or raw ID"
fi
note "station none/saved/new and additive zero/one/several render honestly"

native_preference="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","distanceUnit":"native","currency":"usd"}' \
  "$URL/apps/rover/set-preference")"
[ "$native_preference" = $'Saved display preference - source-native\n201' ] \
  || fail "source-native preference failed: $native_preference"

km_preference="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Fuel Evidence Vehicle","distanceUnit":"km","currency":"usd"}' \
  "$URL/apps/rover/set-preference")"
[ "$km_preference" = $'Saved display preference - km\n201' ] \
  || fail "per-vehicle km preference failed: $km_preference"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -Fq '32,186.9 km (converted)' <<<"$view" \
  || fail "Fuel Evidence Vehicle did not render converted and labelled"
phase_card="${view#*<h2>Phase A Vehicle</h2>}"
phase_card="${phase_card%%<h2>*}"
grep -q 'value="native" selected' <<<"$phase_card" \
  || fail "Phase A Vehicle preference was affected by the other vehicle"
preference_report="$(click_file '=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%display-preference-report ~]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))')"
grep -q '\[%value-digits 25717 0x30d40\].*\[%decimal-places 25717 1\].*\[%unit %tas 26989\]' <<<"$preference_report" \
  || fail "display preference changed stored odometer evidence"
grep -q '\[%distance-unit %tas 28011\]' <<<"$preference_report" \
  || fail "per-vehicle km preference was not stored"
note "per-vehicle km preference converts and labels one vehicle without rewriting evidence"

bad_charge="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Electricity","start":"2026-07-28T22:00","end":"2026-07-28T21:00","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"unknown","currency":"usd"}' \
  "$URL/apps/rover/add-charge")"
[ "$bad_charge" = $'%bad-range: charge.end\n400' ] \
  || fail "malformed charge did not name its end field: $bad_charge"

saved_charge="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","definition":"Electricity","start":"2026-07-28T22:00","end":"2026-07-28T23:00","zone":"America/Chicago","energyDelivered":"41.25","energySource":"charger-reported","startBattery":"21","endBattery":"79.5","mileage":"10022.0","mileageUnit":"mi","costState":"free","currency":"usd"}' \
  "$URL/apps/rover/add-charge")"
[ "$saved_charge" = $'Saved charge - Energy delivered 41.25 kWh\n201' ] \
  || fail "valid charge was not saved: $saved_charge"

bad_odometer="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","reading":"ten thousand","unit":"mi","observed":"2026-07-28T23:05","zone":"America/Chicago"}' \
  "$URL/apps/rover/add-odometer")"
[ "$bad_odometer" = $'%bad-shape: odometer.reading\n400' ] \
  || fail "malformed odometer did not name its reading field: $bad_odometer"

saved_odometer="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","reading":"10023.125","unit":"mi","observed":"2026-07-28T23:05","zone":"America/Chicago"}' \
  "$URL/apps/rover/add-odometer")"
[ "$saved_odometer" = $'Saved odometer - 10,023.125 mi\n201' ] \
  || fail "valid odometer was not saved: $saved_odometer"

overlap_odometer="$(curl -s -b "$JAR" -w $'\n%{http_code}' \
  -H 'content-type: application/json' \
  --data-raw '{"vehicle":"Phase A Vehicle","reading":"10024.125","unit":"mi","observed":"2026-07-28T23:05","zone":"America/Chicago"}' \
  "$URL/apps/rover/add-odometer")"
[ "$overlap_odometer" = $'Saved odometer - 10,024.125 mi\n201' ] \
  || fail "overlapping odometer fixture was not saved: $overlap_odometer"

view="$(curl -s -b "$JAR" "$URL/apps/rover/view")"
grep -q '41.25 kWh' <<<"$view" || fail "saved delivered energy did not render"
grep -q '21%' <<<"$view" || fail "saved start battery did not render"
grep -q '79.5%' <<<"$view" || fail "saved end battery did not render"
grep -q 'charger / reported' <<<"$view" || fail "charging measurement source did not render"
grep -q 'Unavailable - latest observation times overlap' <<<"$view" \
  || fail "overlapping latest observations did not render unavailable with a reason"
if grep -Eq '(^|[^0-9,.])(4125|10023125)([^0-9,.]|$)|0x[0-9a-fA-F]+' <<<"$view"; then
  fail "charge/odometer view leaked a raw machine value or ID"
fi
note "charge and standalone odometer save through Obelisk and render source-native evidence"

asset_check() {
  local path="$1" content_type="$2" source="$3"
  : > "$HDRS"
  curl -s -b "$JAR" -D "$HDRS" -o "$ASSET" "$URL$path"
  grep -q '^HTTP/[0-9.]* 200' "$HDRS" || fail "asset $path not 200"
  grep -qi "^content-type: $content_type" "$HDRS" \
    || fail "asset $path content-type is not $content_type"
  if ! cmp -s "$ASSET" "$source"; then
    echo "served: $(wc -c < "$ASSET") bytes $(sha256sum "$ASSET" | awk '{print $1}')" >&2
    echo "source: $(wc -c < "$source") bytes $(sha256sum "$source" | awk '{print $1}')" >&2
    fail "asset $path differs from desk source"
  fi
}

asset_check /apps/rover/assets/tile.png image/png \
  "$REPO/desk/app/rover/assets/tile.png"
for face in Regular Bold Oblique Bold-Oblique; do
  asset_check "/apps/rover/assets/fonts/BerkeleyMono-$face.woff2" font/woff2 \
    "$REPO/desk/app/rover/assets/fonts/BerkeleyMono-$face.woff2"
done
note "tile and four font faces have exact bytes and content-types"

install_result="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-install !>([%rover our.bowl %rover]))
(pure:m !>(%installed))')"
case "$install_result" in
  *%installed*) ;;
  *) fail "docket install did not acknowledge: $install_result" ;;
esac
sleep 1
charge="$(click_file '=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
=/  charges  .^(* %gx /(scot %p our.bowl)/docket/(scot %da now.bowl)/charges/noun)
(pure:m !>(charges))')"
case "$charge" in
  *"%rover"*"[%site %apps %rover 0]"*"'/apps/rover/assets/tile.png'"*)
    note "PASS - docket charge is site /apps/rover with same-origin tile and no glob"
    ;;
  *) fail "Rover site/tile docket charge not found: $charge" ;;
esac
