::  lib/rover-view - render Obelisk query results as owner-facing HTML.
::
::  Internal IDs are used only to assemble rows. They never enter output.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, render=rover-render
::
|%
++  result-rows
  |=  command=cmd-result:ast
  ^-  (list vector:ast)
  =/  results=(list result:ast)  +.command
  |-
  ?~  results
    ~
  ?:  ?=(%result-set -.i.results)
    +.i.results
  $(results t.results)
::
++  rows-at
  |=  [commands=(list cmd-result:ast) index=@ud]
  ^-  (list vector:ast)
  (result-rows (snag index commands))
::
++  cell-atom
  |=  [key=@tas row=vector:ast]
  ^-  @
  (need (vector-key:act key row))
::
++  cell-text
  |=  [key=@tas row=vector:ast]
  ^-  @t
  `@t`(cell-atom key row)
::
++  cell-term
  |=  [key=@tas row=vector:ast]
  ^-  @tas
  `@tas`(cell-atom key row)
::
++  escape
  |=  value=@t
  ^-  tape
  =/  chars=tape  (trip value)
  |-
  ?~  chars
    ~
  =/  char  i.chars
  =/  escaped=tape
    ?:  =('&' char)  "&amp;"
    ?:  =('<' char)  "&lt;"
    ?:  =('>' char)  "&gt;"
    ?:  =('"' char)  "&quot;"
    [char ~]
  =/  rest=tape  $(chars t.chars)
  (weld escaped rest)
::
++  rows-for
  |=  [vehicle-id=@ rows=(list vector:ast)]
  ^-  (list vector:ast)
  %+  skim  rows
  |=  row=vector:ast
  =(vehicle-id (cell-atom %vehicle-id row))
::
++  rows-by
  |=  [key=@tas value=@ rows=(list vector:ast)]
  ^-  (list vector:ast)
  %+  skim  rows
  |=  row=vector:ast
  =/  found  (vector-key:act key row)
  ?^  found
    =(value u.found)
  %.n
::
++  row-by-text
  |=  [key=@tas value=@t rows=(list vector:ast)]
  ^-  (unit vector:ast)
  ?~  rows
    ~
  ?:  =(value (cell-text key i.rows))
    `i.rows
  $(rows t.rows)
::
++  ids-for-labels
  |=  $:  labels=(list @t)
          rows=(list vector:ast)
          label-key=@tas
          id-key=@tas
      ==
  ^-  (each (list @ux) @t)
  ?~  labels
    [%& ~]
  =/  found  (row-by-text label-key i.labels rows)
  ?~  found
    [%| i.labels]
  =/  rest  $(labels t.labels)
  ?:  ?=(%| -.rest)
    rest
  [%& [`@ux`(cell-atom id-key u.found) p.rest]]
::
++  vehicle-label
  |=  [vehicle-id=@ rows=(list vector:ast)]
  ^-  @t
  ?~  rows
    'Unavailable'
  ?:  =(vehicle-id (cell-atom %vehicle-id i.rows))
    (cell-text %label i.rows)
  $(rows t.rows)
::
++  vehicle-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  label  (escape (cell-text %label i.rows))
  =/  option
    ;:  weld
      "<option value=\""
      label
      "\">"
      label
      "</option>"
    ==
  (weld option $(rows t.rows))
::
++  definition-options
  |=  [rows=(list vector:ast) vehicles=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  row  i.rows
  =/  owner
    (escape (vehicle-label (cell-atom %vehicle-id row) vehicles))
  =/  label  (escape (cell-text %energy row))
  =/  unit  (escape (scot %tas (cell-term %quantity-unit row)))
  =/  kind  (escape (scot %tas (cell-term %physical-kind row)))
  =/  option
    ;:  weld
      "<option value=\""
      label
      "\" data-vehicle=\""
      owner
      "\" data-unit=\""
      unit
      "\" data-kind=\""
      kind
      "\">"
      label
      "</option>"
    ==
  (weld option $(rows t.rows))
::
++  station-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  archived  =(0 (cell-atom %archived i.rows))
  =/  rest  (station-options t.rows)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  =/  place  (escape (cell-text %place i.rows))
  ;:  weld
    "<option value=\""
    label
    "\" data-search=\""
    label
    " "
    place
    "\">"
    label
    " - "
    place
    "</option>"
    rest
  ==
::
++  additive-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  archived  =(0 (cell-atom %archived i.rows))
  =/  rest  (additive-options t.rows)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<label class=\"check-option\"><input type=\"checkbox\" name=\"additives\" value=\""
    label
    "\"><span>"
    label
    "</span></label>"
    rest
  ==
::
++  entry-screens
  |=  $:  vehicles=(list vector:ast)
          definitions=(list vector:ast)
          stations=(list vector:ast)
          additives=(list vector:ast)
      ==
  ^-  tape
  =/  vehicle-html  (vehicle-options vehicles)
  =/  definition-html  (definition-options definitions vehicles)
  =/  station-html  (station-options stations)
  =/  additive-html  (additive-options additives)
  ;:  weld
    "<nav class=\"action-bar\" aria-label=\"Record actions\">"
    "<button type=\"button\" data-open-screen=\"add-fill\">Add fill</button>"
    "<button type=\"button\" data-open-screen=\"add-charge\">Add charge</button>"
    "<button type=\"button\" data-open-screen=\"add-odometer\">Add odometer</button>"
    "</nav>"
    "<section id=\"add-fill\" class=\"entry-screen\" hidden>"
    "<header><p class=\"eyebrow\">NEW ACQUISITION</p><h2>Add fill</h2></header>"
    "<form id=\"fill-form\">"
    "<label>Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label>"
    "<label>Definition<select name=\"definition\" required>"
    definition-html
    "</select></label>"
    "<label>Quantity<div class=\"input-unit\"><input name=\"quantity\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"12.345\" required><output id=\"fill-unit\">unit</output></div></label>"
    "<label>Price profile<select name=\"profile\"><option value=\"us-usd-gal\">US &middot; USD per gallon</option><option value=\"eu-eur-litre\">EU &middot; EUR per litre</option></select></label>"
    "<label>Price per unit<input name=\"price\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"$3.49\" required></label>"
    "<div class=\"preview-row\"><span>Completed price</span><output id=\"fill-price-completed\">&mdash;</output></div>"
    "<label>Tank state<select name=\"tank\"><option value=\"full\">Full</option><option value=\"partial\">Partial</option></select></label>"
    "<label>Settlement<select name=\"settlement\"><option value=\"standard\">Standard</option><option value=\"cash\">Cash</option></select></label>"
    "<label>Observed at<input name=\"observed\" type=\"datetime-local\" required></label>"
    "<input name=\"zone\" type=\"hidden\">"
    "<label>Optional mileage<input name=\"mileage\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"10012.5\"></label>"
    "<label>Mileage unit<select name=\"mileageUnit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label>"
    "<fieldset class=\"station-field\"><legend>Station <span class=\"optional\">optional</span></legend>"
    "<label>Search saved stations<input id=\"fill-station-search\" type=\"search\" autocomplete=\"off\" placeholder=\"Search recent or saved\"></label>"
    "<select id=\"fill-station\" name=\"station\"><option value=\"none\">No station recorded</option>"
    station-html
    "<option value=\"new\">Add new station&hellip;</option></select>"
    "<div id=\"fill-new-station\" hidden><label>Station label<input name=\"newStationLabel\" autocomplete=\"off\" placeholder=\"Home charger\"></label><label>Place label<input name=\"newPlaceLabel\" autocomplete=\"off\" placeholder=\"Home\"></label><label>Station kind<select name=\"newStationKind\"><option value=\"private\">Private</option><option value=\"fuel\">Fuel</option><option value=\"charging\">Charging</option><option value=\"mixed\">Mixed</option></select></label></div>"
    "</fieldset>"
    "<fieldset id=\"fill-additives\"><legend>Additives <span class=\"optional\">optional</span></legend><div class=\"check-grid\">"
    additive-html
    "</div></fieldset>"
    "<div class=\"preview-row derived-preview\"><span>Derived total</span><output id=\"fill-derived-total\" aria-live=\"polite\">&mdash;</output><small>Calculated from quantity and completed unit price</small></div>"
    "<div class=\"form-actions\"><button type=\"submit\">Save fill</button><button type=\"button\" data-close-screen>Cancel</button></div>"
    "<output id=\"fill-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output>"
    "</form></section>"
    "<section id=\"add-charge\" class=\"entry-screen\" hidden>"
    "<header><p class=\"eyebrow\">NEW ACQUISITION</p><h2>Add charge</h2></header>"
    "<form id=\"charge-form\">"
    "<label>Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label>"
    "<label>Electricity definition<select name=\"definition\" required>"
    definition-html
    "</select></label>"
    "<div class=\"form-grid\"><label>Started<input name=\"start\" type=\"datetime-local\" required></label><label>Ended<input name=\"end\" type=\"datetime-local\" required></label></div>"
    "<input name=\"zone\" type=\"hidden\">"
    "<label>Energy delivered <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"energyDelivered\" inputmode=\"decimal\" placeholder=\"42.75\"><output>kWh</output></div></label>"
    "<label>Energy source<select name=\"energySource\"><option value=\"charger-reported\">Charger reported</option><option value=\"wall-measured\">Wall measured</option><option value=\"vehicle-reported\">Vehicle reported</option><option value=\"estimate\">Estimate</option></select></label>"
    "<div class=\"form-grid\"><label>Start battery <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"startBattery\" inputmode=\"decimal\" placeholder=\"20\"><output>%</output></div></label><label>End battery <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"endBattery\" inputmode=\"decimal\" placeholder=\"80\"><output>%</output></div></label></div>"
    "<label>Mileage <span class=\"optional\">optional</span><input name=\"mileage\" inputmode=\"decimal\" placeholder=\"10020.0\"></label>"
    "<label>Mileage unit<select name=\"mileageUnit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label>"
    "<label>Cost state<select name=\"costState\"><option value=\"unknown\">Unknown</option><option value=\"free\">Free</option></select></label>"
    "<label>Currency<select name=\"currency\"><option value=\"usd\">USD</option><option value=\"eur\">EUR</option></select></label>"
    "<div class=\"form-actions\"><button type=\"submit\">Save charge</button><button type=\"button\" data-close-screen>Cancel</button></div>"
    "<output id=\"charge-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output>"
    "</form></section>"
    "<section id=\"add-odometer\" class=\"entry-screen\" hidden>"
    "<header><p class=\"eyebrow\">NEW OBSERVATION</p><h2>Add odometer reading</h2></header>"
    "<form id=\"odometer-form\">"
    "<label>Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label>"
    "<label>Reading<input name=\"reading\" inputmode=\"decimal\" placeholder=\"10020.125\" required></label>"
    "<label>Source unit<select name=\"unit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label>"
    "<label>Observed at<input name=\"observed\" type=\"datetime-local\" required></label>"
    "<input name=\"zone\" type=\"hidden\">"
    "<p class=\"field-note\">Source-native digits and precision are retained exactly.</p>"
    "<div class=\"form-actions\"><button type=\"submit\">Save odometer</button><button type=\"button\" data-close-screen>Cancel</button></div>"
    "<output id=\"odometer-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output>"
    "</form></section>"
  ==
::
++  current-odometer
  |=  rows=(list vector:ast)
  ^-  tape
  =/  ordered  (order-vectors:act %observed-start %.y rows)
  ?~  ordered
    "Unavailable - no odometer readings"
  =/  latest  i.ordered
  =/  ambiguous
    ?~  t.ordered
      %.n
    =/  prior-end  (cell-atom %observed-end i.t.ordered)
    =/  latest-start  (cell-atom %observed-start latest)
    (gth prior-end latest-start)
  ?:  ambiguous
    "Unavailable - latest observation times overlap"
  %-  trip
  %:  format-distance:render
      (cell-atom %value-digits latest)
      (cell-atom %decimal-places latest)
      (cell-term %unit latest)
      %.n
  ==
::
++  definitions
  |=  [rows=(list vector:ast) default-rows=(list vector:ast)]
  ^-  tape
  =/  default=@t
    ?~  default-rows
      'Unavailable'
    (cell-text %default-energy i.default-rows)
  =/  items=tape
    |-
    ?~  rows
      ~
    =/  row  i.rows
    =/  label  (escape (cell-text %energy row))
    =/  archived  =(0 (cell-atom %link-archived row))
    =/  rest=tape  $(rows t.rows)
    ;:  weld
      "<li><span>"
      label
      "</span>"
      ?:(archived " <small>ARCHIVED</small>" "")
      "</li>"
      rest
    ==
  ;:  weld
    "<div class=\"definitions\"><p><span class=\"key\">DEFAULT</span> "
    (escape default)
    "</p><ul>"
    items
    "</ul></div>"
  ==
::
++  additive-chips
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  ;:  weld
    "<span class=\"chip\">"
    (escape (cell-text %additive i.rows))
    "</span>"
    $(rows t.rows)
  ==
::
++  fill-card
  |=  [row=vector:ast station-links=(list vector:ast) additive-links=(list vector:ast)]
  ^-  tape
  =/  acquisition-id  (cell-atom %acquisition-id row)
  =/  stations  (rows-by %acquisition-id acquisition-id station-links)
  =/  additives  (rows-by %acquisition-id acquisition-id additive-links)
  =/  quantity
    %+  format-quantity:render
      (cell-atom %quantity-milli row)
    (cell-term %quantity-unit row)
  =/  unit-price
    %+  format-unit-price:render
      (cell-atom %unit-price-mills row)
    (cell-term %currency row)
  =/  proof
    %:  derive-fill-total:act
        (cell-atom %quantity-milli row)
        (cell-atom %unit-price-mills row)
        (cell-atom %minor-unit-decimals row)
        (cell-atom %cash-increment-mills row)
        ;;(settlement-mode:rover (cell-term %settlement-mode row))
    ==
  =/  total
    %:  format-total:render
        total-mills.proof
        (cell-term %currency row)
        (cell-atom %minor-unit-decimals row)
    ==
  =/  observed
    ;:  weld
      (trip (format-da:render `@da`(cell-atom %observed-start row)))
      " ("
      (escape (cell-text %source-zone row))
      ")"
    ==
  ;:  weld
    "<article class=\"history-card fill\"><header><span>FILL</span><time>"
    observed
    "</time></header><dl>"
    "<div><dt>ENERGY</dt><dd>"
    (escape (cell-text %energy row))
    "</dd></div><div><dt>QUANTITY</dt><dd>"
    (escape quantity)
    "</dd></div><div><dt>UNIT PRICE</dt><dd>"
    (escape unit-price)
    "</dd></div><div><dt>TANK</dt><dd>"
    (escape (scot %tas (cell-term %tank-state row)))
    "</dd></div><div class=\"derived\"><dt>DERIVED TOTAL</dt><dd>"
    (escape total)
    "</dd></div><div><dt>STATION</dt><dd>"
    ?:(?=(~ stations) "No station recorded" (escape (cell-text %station i.stations)))
    "</dd></div><div><dt>ADDITIVES</dt><dd class=\"chips\">"
    ?:(?=(~ additives) "No additives recorded" (additive-chips additives))
    "</dd></div></dl></article>"
  ==
::
++  fill-cards
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  card=tape  (fill-card i.rows ~ ~)
  =/  rest=tape  (fill-cards t.rows)
  (weld card rest)
::
++  fill-history
  |=  rows=(list vector:ast)
  ^-  tape
  =/  ordered  (order-vectors:act %observed-start %.n rows)
  ?:  ?=(~ ordered)
    "<p class=\"empty\">No fill history.</p>"
  (fill-cards ordered)
::
++  battery-at
  |=  [endpoint=@tas rows=(list vector:ast)]
  ^-  tape
  ?~  rows
    "Not recorded"
  ?:  =(endpoint (cell-term %endpoint i.rows))
    ;:  weld
      (trip (format-scaled:render (cell-atom %value-digits i.rows) (cell-atom %value-decimals i.rows) %.n))
      "%"
    ==
  $(rows t.rows)
::
++  charge-card
  |=  [row=vector:ast measurements=(list vector:ast) batteries=(list vector:ast)]
  ^-  tape
  =/  acquisition-id  (cell-atom %acquisition-id row)
  =/  energy-rows  (rows-by %acquisition-id acquisition-id measurements)
  =/  battery-rows  (rows-by %acquisition-id acquisition-id batteries)
  =/  delivered=tape
    ?~  energy-rows
      "Not recorded"
    ;:  weld
      (trip (format-scaled:render (cell-atom %quantity i.energy-rows) (cell-atom %decimals i.energy-rows) %.n))
      " kWh - "
      (escape (scot %tas (cell-term %point i.energy-rows)))
      " / "
      (escape (scot %tas (cell-term %evidence i.energy-rows)))
    ==
  =/  observed=tape
    ;:  weld
      (trip (format-da:render `@da`(cell-atom %observed-start row)))
      " - "
      (trip (format-da:render `@da`(cell-atom %observed-end row)))
      " ("
      (escape (cell-text %source-zone row))
      ")"
    ==
  ;:  weld
    "<article class=\"history-card charge\"><header><span>CHARGE</span><time>"
    observed
    "</time></header><dl>"
    "<div><dt>ENERGY</dt><dd>"
    (escape (cell-text %energy row))
    "</dd></div><div><dt>ENERGY DELIVERED</dt><dd>"
    delivered
    "</dd></div><div><dt>START BATTERY</dt><dd>"
    (battery-at %start battery-rows)
    "</dd></div><div><dt>END BATTERY</dt><dd>"
    (battery-at %end battery-rows)
    "</dd></div><div><dt>COST STATE</dt><dd>"
    (escape (scot %tas (cell-term %cost-state row)))
    " / "
    (escape (scot %tas (cell-term %currency row)))
    "</dd></div></dl></article>"
  ==
::
++  history-cards
  |=  $:  rows=(list vector:ast)
          measurements=(list vector:ast)
          batteries=(list vector:ast)
          station-links=(list vector:ast)
          additive-links=(list vector:ast)
      ==
  ^-  tape
  ?~  rows
    ~
  =/  is-fill  (vector-key:act %quantity-milli i.rows)
  =/  card=tape
    ?^  is-fill
      (fill-card i.rows station-links additive-links)
    (charge-card i.rows measurements batteries)
  (weld card $(rows t.rows))
::
++  ordered-history
  |=  $:  fills=(list vector:ast)
          charges=(list vector:ast)
          measurements=(list vector:ast)
          batteries=(list vector:ast)
          station-links=(list vector:ast)
          additive-links=(list vector:ast)
      ==
  ^-  tape
  =/  ordered  (order-vectors:act %observed-start %.n (weld fills charges))
  ?:  ?=(~ ordered)
    "<p class=\"empty\">No acquisition history.</p>"
  (history-cards ordered measurements batteries station-links additive-links)
::
++  vehicle-card
  |=  $:  row=vector:ast
          odometers=(list vector:ast)
          definition-rows=(list vector:ast)
          default-rows=(list vector:ast)
          fills=(list vector:ast)
          charges=(list vector:ast)
          measurements=(list vector:ast)
          batteries=(list vector:ast)
          station-links=(list vector:ast)
          additive-links=(list vector:ast)
      ==
  ^-  tape
  =/  id  (cell-atom %vehicle-id row)
  =/  archived  =(0 (cell-atom %archived row))
  =/  odometer  (current-odometer (rows-for id odometers))
  =/  defs  (definitions (rows-for id definition-rows) (rows-for id default-rows))
  =/  history
    %:  ordered-history
        (rows-for id fills)
        (rows-for id charges)
        measurements
        batteries
        station-links
        additive-links
    ==
  ;:  weld
    "<article class=\"vehicle-card\"><header><div><p class=\"eyebrow\">VEHICLE</p><h2>"
    (escape (cell-text %label row))
    "</h2></div><span class=\"status\">"
    ?:(archived "ARCHIVED" "ACTIVE")
    "</span></header><section class=\"odometer\"><span class=\"key\">CURRENT ODOMETER - DERIVED</span><strong>"
    odometer
    "</strong></section>"
    defs
    "<section class=\"history\"><h3>ORDERED HISTORY</h3>"
    history
    "</section></article>"
  ==
::
++  page
  |=  commands=(list cmd-result:ast)
  ^-  @t
  =/  vehicles  (rows-at commands 0)
  =/  odometers  (rows-at commands 1)
  =/  definition-rows  (rows-at commands 2)
  =/  default-rows  (rows-at commands 3)
  =/  fills  (rows-at commands 4)
  =/  charges  (rows-at commands 5)
  =/  measurements  (rows-at commands 6)
  =/  batteries  (rows-at commands 7)
  =/  stations  (rows-at commands 8)
  =/  additives  (rows-at commands 9)
  =/  station-links  (rows-at commands 10)
  =/  additive-links  (rows-at commands 11)
  =/  cards=tape
    |-
    ?~  vehicles
      ~
    =/  card
      (vehicle-card i.vehicles odometers definition-rows default-rows fills charges measurements batteries station-links additive-links)
    =/  rest=tape  $(vehicles t.vehicles)
    (weld card rest)
  =/  html=tape
    ;:  weld
      (entry-screens vehicles definition-rows stations additives)
      "<section id=\"vehicle-view\"><header class=\"view-header\"><p class=\"eyebrow\">ROVER FLEET</p><h1>VEHICLES</h1></header>"
      ?:(?=(~ vehicles) "<p class=\"empty\">No vehicles recorded.</p>" cards)
      "</section>"
    ==
  (crip html)
--
