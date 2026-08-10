# Rover M0-CC charging cost entry results

Date: 2026-08-10

Target: `~/piers/rover-m0cc-bel` (`~bel`, tmux `rover-m0cc`, HTTP 8081)

Obelisk: `master` at `9de633299b373a1047490b48281a40b457fb2043`
(v0.9.0-beta)

The pier is a fresh disposable fake ship. It booted from the unchanged
`brass-408k-1.pill`. Stock `%obelisk` and `%rover` stay separate desks.

## The gap

`sur/rover.hoon` declares four cost states. `docs/schema-m0.sql` holds
`charging-costs`, `charging-cost-components`, and
`charging-cost-source-totals`. The add-charge form offered two states, and
the decoder refused the other two. A user could not record an itemized
charging cost or a receipt total.

## The surface

`/apps/rover/add-charge` now accepts all four cost states.

- The form reveals a repeatable component group for `%itemized`. Each line
  carries kind, quantity, quantity unit, rate, and amount.
- The form reveals one total field for `%receipt-total-only`.
- The decoder validates the component rows and the receipt total. It keeps
  the existing refusal vocabulary.
- The write path inserts the parent `charging-costs` row and its child rows
  in one mutation-only atomic script.
- The view renders the cost state, the component lines, the derived itemized
  total, and the source-reported receipt total.

`derive-charging-total` in `lib/rover-act.hoon` remains the only charging
arithmetic. The decoder, the HTTP verdict, and the view all call it. No
second calculator exists.

The decoder reports the calculator's own refusal. A discount larger than the
charged components makes `derive-charging-total` assert. The decoder catches
that assertion and answers `%bad-range: charge.components`.

Obelisk does not execute `ORDER BY`, so the view sorts the component lines
itself. The order is the ratified component order: energy, time, session,
idle, tax, discount.

## Fixture 105 - itemized components and the derived total

The fixture posts the six component kinds through `/apps/rover/add-charge`,
then reads the charge back through `/apps/rover/view`.

```text
Saved charge - Energy delivered 45.678 kWh - itemized total $17.420
201
```

The same six amounts through the `%derive-charging-total` action produce the
same proof. Positive components, discounts, and total in mills:

```text
[0 %avow 0 %noun 0 0 19420 2000 17420]
```

The rendered card holds every source-native component value:

```html
<div><dt>COST STATE</dt><dd data-cost-state="itemized">itemized / usd</dd></div>
<div><dt>COST COMPONENTS</dt><dd><ul class="cost-components">
<li><span data-cost-component="energy">energy</span><span>45.678 kwh</span><span>$0.250</span><span>$11.420</span></li>
<li><span data-cost-component="time">time</span><span>30 minute</span><span>$0.100</span><span>$3.000</span></li>
<li><span data-cost-component="session">session</span><span>1 session</span><span>$1.500</span><span>$1.500</span></li>
<li><span data-cost-component="idle">idle</span><span>5 minute</span><span>$0.500</span><span>$2.500</span></li>
<li><span data-cost-component="tax">tax</span><span>1 session</span><span>$1.000</span><span>$1.000</span></li>
<li><span data-cost-component="discount">discount</span><span>1 session</span><span>$2.000</span><span>-$2.000</span></li>
</ul></dd></div>
<div><dt>ITEMIZED TOTAL</dt><dd data-itemized-total="$17.420">$17.420</dd></div>
```

The energy amount is `11420` mills while quantity times rate is `11419.5`.
The amount is source-reported evidence. Rover does not recompute it.

## Fixture 106 - the receipt total stays as reported

```text
Saved charge - Energy delivered 40.0 kWh - receipt total $22.340
201
```

```html
<div><dt>COST STATE</dt><dd data-cost-state="receipt-total-only">receipt-total-only / usd</dd></div>
<div><dt>RECEIPT TOTAL</dt><dd data-receipt-total="$22.340">$22.340 <small>source reported</small></dd></div>
```

The card carries no component row and no derived total.

## Fixture 107 - the refusals

Five bad inputs, five named refusals, and no new row:

```text
%bad-shape: charge.components    (itemized with no components)
%bad-shape: charge.components    (receipt-total-only with components)
%bad-shape: charge.component     (component kind "parking")
%bad-shape: charge.source-total  (free charge with a source total)
%bad-shape: charge.source-total  (receipt-total-only with no total)
%bad-range: charge.components    (discount larger than the charges)
```

Every refusal returns 400. The charge-card count is the same before and
after, so no refused charge reached the database.

## Fixture 108 - the form shape

The served Add Charge section offers all four cost states, a repeatable
component group with the five component fields, the six component kinds, the
three quantity units, and one receipt total field.

## Fixture 109 - a real browser fills the form

Chromium loads the served shell, opens Add Charge, and selects each cost
state. The itemized group appears only for `%itemized`. The receipt group
appears only for `%receipt-total-only`. The browser adds six component rows,
fills them, reads the preview, and submits.

```text
CHARGE_PREVIEW=$17.420
CHARGE_VERDICT=Saved charge - Energy delivered not recorded - itemized total $17.420
```

The saved charge carries six component rows and the same derived total.

## Restart persistence

An itemized charge and a receipt-only charge were written to the owner
database. The pier was stopped and started again. Both survived with their
component rows, their derived total, and their reported total:

```text
charge cards after restart: 2
  receipt-total-only | data-receipt-total="$22.340" | components: []
  itemized | data-itemized-total="$17.420" | components: ['energy', 'time', 'session', 'idle', 'tax', 'discount']
```

The agent state moved from `%15` to `%16` because `charge-entry` gained the
component list and the source total. The upgrade drops the in-flight
`charge-pending` map, which holds only unanswered HTTP requests.

## Full battery

```console
$ ROVER_DEMO_ONLY=1 bin/ui-test.sh ~/piers/rover-m0cc-bel
ui-test: fixture 105 PASS - the add-charge surface records six itemized components and the view derives the same total derive-charging-total proves
ui-test: fixture 106 PASS - a receipt-only total survives as reported evidence with no components and no derived total
ui-test: fixture 107 PASS - Rover refuses an empty itemized set, a receipt total with components, an unknown component kind, a cost total on a free charge, and a discount larger than its charges, and writes none of them
ui-test: fixture 108 PASS - add-charge offers all four cost states with repeatable itemized component rows and a receipt total field
ui-test: fixture 109 PASS - a real browser fills repeatable itemized component rows, previews the exact derived total, and saves it through Eyre
ui-test: COVERAGE - all 90 defined fixtures executed
```

```console
$ bin/schema-test.sh ~/piers/rover-m0cc-bel
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed

$ bin/import-test.sh ~/piers/rover-m0cc-bel
import-test: COVERAGE - all 7 defined import fixtures executed

$ bin/view-performance-test.sh ~/piers/rover-m0cc-bel
view-performance-test: run 2 - 0.576169s, 277461 bytes, 25 of 420 fills
view-performance-test: COVERAGE - synthetic 420-fill view stayed within 2.0s

$ bin/dev-pin-test.sh
dev-pin-test: PASS - fixture 55 source gate - v0.9.0-beta commit and compatibility mold SHA match

$ tests/view-linear-test.sh
view-linear-test: PASS - one-pass derivation feeds a bounded newest-first view
```

The two added `ui-view` queries did not move the view past its budget. The
420-fill synthetic page still renders in about 0.58 seconds.

Unit generators:

```text
[0 %avow 0 %noun %entry-tests-pass]
[0 %avow 0 %noun %render-tests-pass]
[0 %avow 0 %noun %pricing-tests-pass]
[0 %avow 0 %noun %import-tests-pass]
```

## Scope

`docs/schema-m0.sql` is unchanged. The tables already existed and are
correct. No action joined the `$action` union. No fixture action or fixture
arm changed, so Gate 7 T1 and T2 keep their fence. `derive-charging-total`
is unchanged. Liquid-fill cash rounding does not touch charging costs.
