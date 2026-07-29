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
++  rows-by-text
  |=  [key=@tas value=@t rows=(list vector:ast)]
  ^-  (list vector:ast)
  %+  skim  rows
  |=  row=vector:ast
  =(value (cell-text key row))
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
++  subtype-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  archived  =(0 (cell-atom %archived i.rows))
  =/  rest  (subtype-options t.rows)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  =/  definition  (escape (cell-text %energy i.rows))
  ;:  weld
    "<option value=\""
    label
    "\" data-definition=\""
    definition
    "\">"
    label
    "</option>"
    rest
  ==
::
++  default-subtype-data
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  ;:  weld
    "<span hidden data-default-subtype-vehicle=\""
    (escape (cell-text %vehicle i.rows))
    "\" data-default-subtype=\""
    (escape (cell-text %subtype i.rows))
    "\"></span>"
    (default-subtype-data t.rows)
  ==
::
++  driving-mode-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  archived  ?|  =(0 (cell-atom %mode-archived i.rows))
                         =(0 (cell-atom %link-archived i.rows))
                     ==
  =/  rest  (driving-mode-options t.rows)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<option value=\""
    label
    "\" data-vehicle=\""
    (escape (cell-text %vehicle i.rows))
    "\">"
    label
    "</option>"
    rest
  ==
::
++  tag-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  archived  =(0 (cell-atom %archived i.rows))
  =/  rest  (tag-options t.rows)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<label class=\"check-option\"><input type=\"checkbox\" name=\"tags\" value=\""
    label
    "\"><span>"
    label
    "</span></label>"
    rest
  ==
::
++  has-term
  |=  [key=@tas value=@tas rows=(list vector:ast)]
  ^-  ?
  ?~  rows
    %.n
  ?:  =(value (cell-term key i.rows))
    %.y
  $(rows t.rows)
::
++  main-hub
  |=  $:  app-default=(list vector:ast)
          definition-rows=(list vector:ast)
          odometers=(list vector:ast)
          tank-sizes=(list vector:ast)
      ==
  ^-  tape
  =/  default-id=(unit @)
    ?~  app-default
      ~
    `(cell-atom %vehicle-id i.app-default)
  =/  default-marker=tape
    ?~  app-default
      "<span id=\"app-default-data\" hidden></span>"
    ;:  weld
      "<span id=\"app-default-data\" hidden data-vehicle=\""
      (escape (cell-text %label i.app-default))
      "\"></span>"
    ==
  =/  default-label=tape
    ?~  app-default
      "DEFAULT VEHICLE NOT SET"
    (escape (cell-text %label i.app-default))
  =/  sources=(list vector:ast)
    ?~  default-id
      ~
    (rows-for u.default-id definition-rows)
  =/  has-fill  (has-term %physical-kind %reservoir sources)
  =/  has-charge  (has-term %physical-kind %electricity sources)
  =/  odometer=tape
    ?~  default-id
      "Unavailable"
    (current-odometer (rows-for u.default-id odometers) ~)
  =/  tank-reason=tape
    ?~  default-id
      "No default vehicle is set."
    ?:  ?=(~ (rows-for u.default-id tank-sizes))
      "Tank size is not recorded for this vehicle."
    "An eligible economy interval is required."
  ;:  weld
    default-marker
    "<section id=\"main-hub\" class=\"app-screen\">"
    "<header class=\"hub-header\"><p class=\"eyebrow\">ROVER VEHICLE LOG</p><h1>MAIN</h1><p>"
    default-label
    "</p></header><section class=\"hub-primary\">"
    ?:(has-fill "<button type=\"button\" data-open-screen=\"add-fill\">Add Fill</button>" "")
    ?:(has-charge "<button type=\"button\" data-open-screen=\"add-charge\">Add Charge</button>" "")
    ?:  ?|(has-fill has-charge)
      ""
    "<button type=\"button\" data-open-screen=\"vehicles-screen\">Configure a vehicle</button>"
    "</section>"
    "<nav class=\"hub-actions\" aria-label=\"Main actions\">"
    "<button type=\"button\" data-open-screen=\"add-odometer\">Add Odometer Entry</button>"
    "<button type=\"button\" data-open-screen=\"vehicles-screen\">Vehicles</button>"
    "<button type=\"button\" data-open-screen=\"history-screen\">History</button>"
    "<button type=\"button\" data-open-screen=\"statistics-screen\">Statistics</button>"
    "<button type=\"button\" data-open-screen=\"settings-screen\">Settings</button>"
    "</nav>"
    "<section class=\"hub-readouts\" aria-label=\"Default vehicle readouts\">"
    "<article><span>MOST RECENT ODOMETER</span><strong>"
    odometer
    "</strong><small>"
    ?:(?=(~ default-id) "No default vehicle is set." "Latest non-overlapping observation.")
    "</small></article>"
    "<article><span>ECONOMY - LAST FILL</span><strong>Unavailable</strong><small>An eligible full-fill interval is required.</small></article>"
    "<article><span>ECONOMY - LIFETIME</span><strong>Unavailable</strong><small>No eligible lifetime interval is recorded.</small></article>"
    "<article><span>ESTIMATED DISTANCE TO NEXT FILL</span><strong>Unavailable</strong><small>"
    tank-reason
    "</small></article>"
    "<article><span>BEST ECONOMY</span><strong>Unavailable</strong><small>No eligible economy intervals are recorded.</small></article>"
    "<article><span>WORST ECONOMY</span><strong>Unavailable</strong><small>No eligible economy intervals are recorded.</small></article>"
    "</section></section>"
  ==
::
++  entry-screens
  |=  $:  vehicles=(list vector:ast)
          definitions=(list vector:ast)
          stations=(list vector:ast)
          additives=(list vector:ast)
          subtypes=(list vector:ast)
          default-subtypes=(list vector:ast)
          driving-modes=(list vector:ast)
          tags=(list vector:ast)
      ==
  ^-  tape
  =/  vehicle-html  (vehicle-options vehicles)
  =/  definition-html  (definition-options definitions vehicles)
  =/  station-html  (station-options stations)
  =/  additive-html  (additive-options additives)
  =/  subtype-html  (subtype-options subtypes)
  =/  default-subtype-html  (default-subtype-data default-subtypes)
  =/  driving-mode-html  (driving-mode-options driving-modes)
  =/  tag-html  (tag-options tags)
  ;:  weld
    "<section id=\"add-fill\" class=\"entry-screen app-screen\" hidden>"
    "<button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button>"
    "<header><p class=\"eyebrow\">NEW ACQUISITION</p><h2>Add fill</h2></header>"
    "<form id=\"fill-form\">"
    "<label data-fill-field=\"vehicle\">Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label>"
    "<label class=\"energy-source-control\" hidden>Energy Source<select name=\"definition\" required>"
    definition-html
    "</select></label>"
    "<label data-fill-field=\"odometer\">Odometer <span class=\"optional\">optional</span><input name=\"mileage\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"10012.5\"></label>"
    "<div class=\"read-only-row\" data-fill-field=\"previous-odometer\"><span>Previous odometer reading</span><output id=\"fill-previous-odometer\">Unavailable - no prior reading selected</output></div>"
    "<div data-fill-field=\"price\"><label>Fuel price<input name=\"price\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"$3.49\" required></label><div class=\"preview-row\"><span>Completed price</span><output id=\"fill-price-completed\">&mdash;</output></div></div>"
    "<label data-fill-field=\"quantity\">Quantity<div class=\"input-unit\"><input name=\"quantity\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"12.345\" required><output id=\"fill-unit\">unit</output></div></label>"
    "<div class=\"preview-row derived-preview\" data-fill-field=\"calculated-total\"><span>Calculated Total</span><output id=\"fill-derived-total\" aria-live=\"polite\">&mdash;</output><small>Calculated from quantity and completed unit price</small></div>"
    "<label class=\"check-option\" data-fill-field=\"partial-fill\"><input name=\"partialFill\" type=\"checkbox\"><span>Partial Fill</span></label>"
    "<label class=\"check-option\" data-fill-field=\"missed-fill\"><input name=\"missedFill\" type=\"checkbox\"><span>Missed Fill</span></label>"
    "<label data-fill-field=\"fuel-subtype\">Fuel Subtype<select name=\"subtype\"><option value=\"\">Not recorded</option>"
    subtype-html
    "</select></label>"
    default-subtype-html
    "<fieldset id=\"fill-additives\" data-fill-field=\"additive\"><legend>Additive <span class=\"optional\">optional</span></legend><div class=\"check-grid\">"
    additive-html
    "</div></fieldset>"
    "<fieldset class=\"station-field\" data-fill-field=\"station\"><legend>Station <span class=\"optional\">optional</span></legend>"
    "<label>Search / select<input id=\"fill-station-search\" type=\"search\" autocomplete=\"off\" placeholder=\"Search recent or saved\"></label>"
    "<select id=\"fill-station\" name=\"station\"><option value=\"none\">No station recorded</option>"
    station-html
    "<option value=\"new\">Add new station&hellip;</option></select>"
    "<div id=\"fill-new-station\" hidden><label>Station label<input name=\"newStationLabel\" autocomplete=\"off\" placeholder=\"Home pump\"></label><label>Place label<input name=\"newPlaceLabel\" autocomplete=\"off\" placeholder=\"Home\"></label><label>Station kind<select name=\"newStationKind\"><option value=\"private\">Private</option><option value=\"fuel\">Fuel</option><option value=\"charging\">Charging</option><option value=\"mixed\">Mixed</option></select></label></div>"
    "</fieldset>"
    "<label data-fill-field=\"driving-mode\">Driving Mode <span class=\"optional\">optional</span><select name=\"drivingMode\"><option value=\"\">Not recorded</option>"
    driving-mode-html
    "</select></label>"
    "<label data-fill-field=\"average-speed\">Average Speed <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"averageSpeed\" inputmode=\"decimal\" autocomplete=\"off\"><select name=\"speedUnit\"><option value=\"mph\">mph</option><option value=\"kph\">km/h</option></select></div></label>"
    "<fieldset class=\"drive-balance\" data-fill-field=\"drive-balance\"><legend>City &larr;&rarr; Highway <span class=\"optional\">optional</span></legend><output id=\"fill-drive-balance-state\">UNSET</output><input id=\"fill-drive-balance\" name=\"driveBalance\" type=\"range\" min=\"0\" max=\"100\" value=\"50\" data-state=\"unset\"><div class=\"balance-ends\"><span>City</span><span>Highway</span></div></fieldset>"
    "<fieldset id=\"fill-tags\" data-fill-field=\"tags\"><legend>Tags <span class=\"optional\">optional</span></legend><button type=\"button\" id=\"fill-tags-toggle\" aria-expanded=\"false\">Choose or add tags</button><div id=\"fill-tags-picker\" hidden><div class=\"check-grid\">"
    tag-html
    "</div><label>Add new tag<input name=\"newTag\" autocomplete=\"off\"></label></div></fieldset>"
    "<fieldset id=\"fill-custom-fields\" data-fill-field=\"custom-fields\"><legend>Custom fields</legend><p class=\"empty\">No custom fields target Add Fill.</p></fieldset>"
    "<input name=\"profile\" type=\"hidden\" value=\"us-usd-gal\">"
    "<input name=\"tank\" type=\"hidden\" value=\"full\">"
    "<input name=\"settlement\" type=\"hidden\" value=\"standard\">"
    "<input name=\"observed\" type=\"hidden\">"
    "<input name=\"zone\" type=\"hidden\">"
    "<input name=\"mileageUnit\" type=\"hidden\" value=\"mi\">"
    "<div class=\"form-actions\"><button type=\"submit\">Save fill</button><button type=\"button\" data-close-screen>Cancel</button></div>"
    "<output id=\"fill-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output>"
    "</form></section>"
    "<section id=\"add-charge\" class=\"entry-screen app-screen\" hidden>"
    "<button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button>"
    "<header><p class=\"eyebrow\">NEW ACQUISITION</p><h2>Add charge</h2></header>"
    "<form id=\"charge-form\">"
    "<label>Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label>"
    "<label class=\"charge-energy-source-control\" hidden>Energy Source<select name=\"definition\" required>"
    definition-html
    "</select></label>"
    "<div class=\"form-grid\"><label>Started<input name=\"start\" type=\"datetime-local\" required></label><label>Ended<input name=\"end\" type=\"datetime-local\" required></label></div>"
    "<input name=\"zone\" type=\"hidden\">"
    "<label>Energy delivered <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"energyDelivered\" inputmode=\"decimal\" placeholder=\"42.75\"><output>kWh</output></div></label>"
    "<label>Measurement source<select name=\"energySource\"><option value=\"charger-reported\">Charger reported</option><option value=\"wall-measured\">Wall measured</option><option value=\"vehicle-reported\">Vehicle reported</option><option value=\"estimate\">Estimate</option></select></label>"
    "<div class=\"form-grid\"><label>Start battery <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"startBattery\" inputmode=\"decimal\" placeholder=\"20\"><output>%</output></div></label><label>End battery <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"endBattery\" inputmode=\"decimal\" placeholder=\"80\"><output>%</output></div></label></div>"
    "<label>Mileage <span class=\"optional\">optional</span><input name=\"mileage\" inputmode=\"decimal\" placeholder=\"10020.0\"></label>"
    "<label>Mileage unit<select name=\"mileageUnit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label>"
    "<label>Cost state<select name=\"costState\"><option value=\"unknown\">Unknown</option><option value=\"free\">Free</option></select></label>"
    "<label>Currency<select name=\"currency\"><option value=\"usd\">USD</option><option value=\"eur\">EUR</option></select></label>"
    "<div class=\"form-actions\"><button type=\"submit\">Save charge</button><button type=\"button\" data-close-screen>Cancel</button></div>"
    "<output id=\"charge-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output>"
    "</form></section>"
    "<section id=\"add-odometer\" class=\"entry-screen app-screen\" hidden>"
    "<button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button>"
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
  |=  [rows=(list vector:ast) preference=(unit @tas)]
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
  =/  source  (cell-term %unit latest)
  =/  target  ?~(preference source u.preference)
  =/  converted
    (convert-distance:render (cell-atom %value-digits latest) (cell-atom %decimal-places latest) source target)
  %-  trip
  %:  format-distance:render
      converted-digits.converted
      converted-places.converted
      converted-unit.converted
      converted.converted
  ==
::
++  preference-form
  |=  [vehicle-label=@t preference-rows=(list vector:ast)]
  ^-  tape
  =/  distance=@tas
    ?~  preference-rows
      %native
    (cell-term %distance-unit i.preference-rows)
  =/  currency=@tas
    ?~  preference-rows
      %usd
    (cell-term %currency i.preference-rows)
  ;:  weld
    "<form class=\"preference-form\"><input type=\"hidden\" name=\"vehicle\" value=\""
    (escape vehicle-label)
    "\"><label>Distance display<select name=\"distanceUnit\"><option value=\"native\""
    ?:(=(%native distance) " selected" "")
    ">Source-native</option><option value=\"mi\""
    ?:(=(%mi distance) " selected" "")
    ">mi</option><option value=\"km\""
    ?:(=(%km distance) " selected" "")
    ">km</option></select></label><label>Currency display<select name=\"currency\"><option value=\"usd\""
    ?:(=(%usd currency) " selected" "")
    ">USD</option><option value=\"eur\""
    ?:(=(%eur currency) " selected" "")
    ">EUR</option></select></label><button type=\"submit\">Save display preference</button><output class=\"preference-verdict\" aria-live=\"polite\"></output></form>"
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
  |=  $:  row=vector:ast
          station-links=(list vector:ast)
          additive-links=(list vector:ast)
          subtype-links=(list vector:ast)
          economy-breaks=(list vector:ast)
      ==
  ^-  tape
  =/  acquisition-id  (cell-atom %acquisition-id row)
  =/  stations  (rows-by %acquisition-id acquisition-id station-links)
  =/  additives  (rows-by %acquisition-id acquisition-id additive-links)
  =/  subtypes   (rows-by %acquisition-id acquisition-id subtype-links)
  =/  breaks     (rows-by %acquisition-id acquisition-id economy-breaks)
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
    "</dd></div><div><dt>FUEL SUBTYPE</dt><dd>"
    ?:(?=(~ subtypes) "Not recorded" (escape (cell-text %subtype i.subtypes)))
    "</dd></div><div><dt>QUANTITY</dt><dd>"
    (escape quantity)
    "</dd></div><div><dt>UNIT PRICE</dt><dd>"
    (escape unit-price)
    "</dd></div><div><dt>TANK</dt><dd>"
    (escape (scot %tas (cell-term %tank-state row)))
    "</dd></div><div class=\"derived\"><dt>CALCULATED TOTAL</dt><dd>"
    (escape total)
    "</dd></div><div><dt>ECONOMY</dt><dd>"
    ?:  ?=(~ breaks)
      "Unavailable - another eligible full fill is required"
    ;:  weld
      "Unavailable - "
      (escape (scot %tas (cell-term %reason i.breaks)))
    ==
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
  =/  card=tape  (fill-card i.rows ~ ~ ~ ~)
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
          subtype-links=(list vector:ast)
          economy-breaks=(list vector:ast)
      ==
  ^-  tape
  ?~  rows
    ~
  =/  is-fill  (vector-key:act %quantity-milli i.rows)
  =/  card=tape
    ?^  is-fill
      (fill-card i.rows station-links additive-links subtype-links economy-breaks)
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
          subtype-links=(list vector:ast)
          economy-breaks=(list vector:ast)
      ==
  ^-  tape
  =/  ordered  (order-vectors:act %observed-start %.n (weld fills charges))
  ?:  ?=(~ ordered)
    "<p class=\"empty\">No acquisition history.</p>"
  (history-cards ordered measurements batteries station-links additive-links subtype-links economy-breaks)
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
          preferences=(list vector:ast)
          subtype-links=(list vector:ast)
          economy-breaks=(list vector:ast)
          default-subtypes=(list vector:ast)
          driving-modes=(list vector:ast)
          tank-sizes=(list vector:ast)
          is-default=?
      ==
  ^-  tape
  =/  id  (cell-atom %vehicle-id row)
  =/  archived  =(0 (cell-atom %archived row))
  =/  preference-rows  (rows-for id preferences)
  =/  preference=(unit @tas)
    ?~  preference-rows
      ~
    `(cell-term %distance-unit i.preference-rows)
  =/  odometer  (current-odometer (rows-for id odometers) preference)
  =/  defs  (definitions (rows-for id definition-rows) (rows-for id default-rows))
  =/  preference-control  (preference-form (cell-text %label row) preference-rows)
  =/  label  (cell-text %label row)
  =/  default-subtype  (row-by-text %vehicle label default-subtypes)
  =/  modes  (rows-by-text %vehicle label driving-modes)
  =/  tank  (rows-for id tank-sizes)
  =/  tank-text=tape
    ?~  tank
      "Unavailable - no tank size recorded"
    ;:  weld
      (trip (format-scaled:render (cell-atom %digits i.tank) (cell-atom %decimals i.tank) %.n))
      " "
      (escape (scot %tas (cell-term %size-unit i.tank)))
    ==
  =/  mode-text=tape
    ?~  modes
      "No driving modes configured"
    (escape (cell-text %label i.modes))
  =/  history
    %:  ordered-history
        (rows-for id fills)
        (rows-for id charges)
        measurements
        batteries
        station-links
        additive-links
        subtype-links
        economy-breaks
    ==
  ;:  weld
    "<article class=\"vehicle-card\"><header><div><p class=\"eyebrow\">VEHICLE</p><h2>"
    (escape (cell-text %label row))
    "</h2></div><span class=\"status\">"
    ?:(is-default "DEFAULT" ?:(archived "ARCHIVED" "ACTIVE"))
    "</span></header><div class=\"vehicle-actions\">"
    "<button type=\"button\" data-set-default-vehicle data-vehicle=\""
    (escape (cell-text %label row))
    "\">Set Default</button><button type=\"button\" data-remove-vehicle data-vehicle=\""
    (escape (cell-text %label row))
    "\">Remove</button></div><div class=\"vehicle-entry-actions\">"
    "<button type=\"button\" data-vehicle-action=\"fill\" data-vehicle=\""
    (escape (cell-text %label row))
    "\">Add Fill</button><button type=\"button\" data-vehicle-action=\"charge\" data-vehicle=\""
    (escape (cell-text %label row))
    "\">Add Charge</button><button type=\"button\" data-vehicle-action=\"odometer\" data-vehicle=\""
    (escape (cell-text %label row))
    "\">Add Odometer</button></div><details class=\"vehicle-settings\"><summary>Vehicle settings</summary>"
    "<dl><div><dt>ENERGY SOURCE</dt><dd>Configured below</dd></div>"
    "<div><dt>FUEL SUBTYPES</dt><dd>"
    ?~(default-subtype "No default subtype; all source subtypes remain selectable" (escape (cell-text %subtype u.default-subtype)))
    " default; all source subtypes remain selectable</dd></div>"
    "<div><dt>TANK SIZE</dt><dd>"
    tank-text
    "</dd></div><div><dt>DRIVING MODES</dt><dd>"
    mode-text
    "</dd></div><div><dt>DISPLAY PREFERENCE</dt><dd>Source-native unless selected</dd></div></dl></details><section class=\"odometer\"><span class=\"key\">CURRENT ODOMETER - DERIVED</span><strong>"
    odometer
    "</strong></section>"
    preference-control
    defs
    "<section class=\"history\"><h3>ORDERED HISTORY</h3>"
    history
    "</section></article>"
  ==
::
++  input-da
  |=  value=@da
  ^-  tape
  =/  text  (trip (format-da:render value))
  ;:(weld (scag 10 text) "T" (scag 5 (slag 11 text)))
::
++  history-row
  |=  $:  row=vector:ast
          vehicles=(list vector:ast)
          odometer-links=(list vector:ast)
      ==
  ^-  tape
  =/  vehicle  (vehicle-label (cell-atom %vehicle-id row) vehicles)
  =/  acquisition  (cell-atom %acquisition-id row)
  =/  odometer  (rows-by %acquisition-id acquisition odometer-links)
  =/  quantity
    (format-quantity:render (cell-atom %quantity-milli row) (cell-term %quantity-unit row))
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
  =/  date  (trip (format-da:render `@da`(cell-atom %observed-start row)))
  =/  observed-input  (input-da `@da`(cell-atom %observed-start row))
  =/  odometer-text=@t
    ?~  odometer
      'Not recorded'
    %:  format-distance:render
        (cell-atom %value-digits i.odometer)
        (cell-atom %decimal-places i.odometer)
        (cell-term %unit i.odometer)
        %.n
    ==
  ;:  weld
    "<article class=\"history-table-row\" data-history-vehicle=\""
    (escape vehicle)
    "\"><button type=\"button\" class=\"history-record-toggle\" aria-expanded=\"false\">"
    "<span data-history-column=\"DATE\">"
    date
    "</span><span data-history-column=\"ODOMETER\">"
    (escape odometer-text)
    "</span><span data-history-column=\"GALLONS\">"
    (escape quantity)
    "</span><span data-history-column=\"TOTAL COST\">"
    (escape total)
    "</span></button><div class=\"history-record-detail\" hidden><dl>"
    "<div><dt>Vehicle</dt><dd>"
    (escape vehicle)
    "</dd></div><div><dt>Energy Source</dt><dd>"
    (escape (cell-text %energy row))
    "</dd></div><div><dt>Tank state</dt><dd>"
    (escape (scot %tas (cell-term %tank-state row)))
    "</dd></div></dl><form class=\"history-edit-form\">"
    "<input type=\"hidden\" name=\"vehicle\" value=\""
    (escape vehicle)
    "\"><input type=\"hidden\" name=\"observed\" value=\""
    observed-input
    "\"><input type=\"hidden\" name=\"definition\" value=\""
    (escape (cell-text %energy row))
    "\"><input type=\"hidden\" name=\"zone\" value=\""
    (escape (cell-text %source-zone row))
    "\"><input type=\"hidden\" name=\"mileage\" value=\"\"><input type=\"hidden\" name=\"mileageUnit\" value=\"mi\"><input type=\"hidden\" name=\"station\" value=\"none\"><input type=\"hidden\" name=\"newStationLabel\" value=\"\"><input type=\"hidden\" name=\"newPlaceLabel\" value=\"\"><input type=\"hidden\" name=\"newStationKind\" value=\"private\"><input type=\"hidden\" name=\"subtype\" value=\"\"><input type=\"hidden\" name=\"missedFill\" value=\"no\"><input type=\"hidden\" name=\"drivingMode\" value=\"\"><input type=\"hidden\" name=\"averageSpeed\" value=\"\"><input type=\"hidden\" name=\"speedUnit\" value=\"mph\"><input type=\"hidden\" name=\"driveBalance\" value=\"\"><input type=\"hidden\" name=\"newTag\" value=\"\"><label>Quantity<input name=\"quantity\" inputmode=\"decimal\" value=\""
    (escape (format-scaled:render (cell-atom %quantity-milli row) 3 %.n))
    "\"></label><label>Unit price<input name=\"price\" inputmode=\"decimal\" value=\""
    (escape (format-unit-price:render (cell-atom %unit-price-mills row) (cell-term %currency row)))
    "\"></label><input type=\"hidden\" name=\"profile\" value=\""
    (escape (scot %tas (cell-term %price-profile row)))
    "\"><input type=\"hidden\" name=\"tank\" value=\""
    (escape (scot %tas (cell-term %tank-state row)))
    "\"><input type=\"hidden\" name=\"settlement\" value=\""
    (escape (scot %tas (cell-term %settlement-mode row)))
    "\"><button type=\"submit\">Save changes</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form></div></article>"
  ==
::
++  history-screen
  |=  $:  vehicles=(list vector:ast)
          fills=(list vector:ast)
          odometer-links=(list vector:ast)
      ==
  ^-  tape
  =/  ordered  (order-vectors:act %observed-start %.n fills)
  =/  render-rows
    |=  rows=(list vector:ast)
    ^-  tape
    ?~  rows
      ~
    (weld (history-row i.rows vehicles odometer-links) $(rows t.rows))
  =/  rows=tape  (render-rows ordered)
  ;:  weld
    "<section id=\"history-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER LOG</p><h1>HISTORY</h1></header>"
    "<label>Vehicle<select id=\"history-vehicle-filter\">"
    (vehicle-options vehicles)
    "</select></label><div class=\"history-table-head\"><span>DATE</span><span>ODOMETER</span><span>GALLONS</span><span>TOTAL COST</span></div><div id=\"history-table\">"
    rows
    "</div><p id=\"history-empty\" class=\"empty\" hidden>No fill history for this vehicle.</p></section>"
  ==
::
++  statistic-fill-rows
  |=  $:  fills=(list vector:ast)
          vehicles=(list vector:ast)
          subtype-links=(list vector:ast)
          mode=@tas
      ==
  ^-  tape
  ?~  fills
    ~
  =/  row  i.fills
  =/  acquisition  (cell-atom %acquisition-id row)
  =/  subtype  (rows-by %acquisition-id acquisition subtype-links)
  =/  date  (trip (format-da:render `@da`(cell-atom %observed-start row)))
  =/  vehicle  (vehicle-label (cell-atom %vehicle-id row) vehicles)
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
  =/  price
    (format-unit-price:render (cell-atom %unit-price-mills row) (cell-term %currency row))
  =/  rendered=tape
    ?+  mode  ~
      %economy
        ;:  weld
          "<tr><td>"
          date
          "</td><td>"
          ?:(?=(~ subtype) "Not recorded" (escape (cell-text %subtype i.subtype)))
          "</td><td>Unavailable</td><td>An eligible adjacent full-fill interval is required.</td></tr>"
        ==
      %cost
        ;:  weld
          "<tr><td>"
          date
          "</td><td>"
          (escape vehicle)
          "</td><td>"
          (escape total)
          "</td></tr>"
        ==
      %price
        ;:  weld
          "<tr><td>"
          date
          "</td><td>"
          (escape vehicle)
          "</td><td>"
          (escape price)
          "</td></tr>"
        ==
    ==
  (weld rendered $(fills t.fills))
::
++  statistics-screen
  |=  $:  fills=(list vector:ast)
          vehicles=(list vector:ast)
          subtype-links=(list vector:ast)
      ==
  ^-  tape
  =/  recent  (scag 12 (order-vectors:act %observed-start %.n fills))
  ;:  weld
    "<section id=\"statistics-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER ANALYSIS</p><h1>STATISTICS</h1></header>"
    "<section class=\"stat-table\" data-statistic=\"economy-by-subtype\"><h2>Economy per fill by fuel subtype</h2><table><thead><tr><th>Date</th><th>Fuel subtype</th><th>Economy</th><th>Eligibility</th></tr></thead><tbody>"
    (statistic-fill-rows recent vehicles subtype-links %economy)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"fuel-costs\"><h2>Fuel costs</h2><table><thead><tr><th>Date</th><th>Vehicle</th><th>Total cost</th></tr></thead><tbody>"
    (statistic-fill-rows recent vehicles subtype-links %cost)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"distance-between-fills\"><h2>Distance between fills</h2><table><tbody><tr><td>Unavailable</td><td>Adjacent odometer-linked full fills are required.</td></tr></tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"time-between-fills\"><h2>Time between fills</h2><table><tbody><tr><td>Unavailable</td><td>Two eligible ordered fills are required for the selected vehicle.</td></tr></tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"average-price-per-unit\"><h2>Average price per unit</h2><table><thead><tr><th>Date</th><th>Vehicle</th><th>Observed unit price</th></tr></thead><tbody>"
    (statistic-fill-rows recent vehicles subtype-links %price)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"distance-per-tank\"><h2>Distance per tank</h2><table><tbody><tr><td>Unavailable</td><td>Tank size and an eligible economy interval are required; Rover never guesses tank size.</td></tr></tbody></table></section></section>"
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
  =/  preferences  (rows-at commands 12)
  =/  subtype-links  (rows-at commands 13)
  =/  subtypes  (rows-at commands 14)
  =/  default-subtypes  (rows-at commands 15)
  =/  driving-modes  (rows-at commands 16)
  =/  tags  (rows-at commands 17)
  =/  economy-breaks  (rows-at commands 19)
  =/  app-default  (rows-at commands 20)
  =/  tank-sizes  (rows-at commands 21)
  =/  fill-odometers  (rows-at commands 22)
  =/  definition-html  (definition-options definition-rows vehicles)
  =/  default-id=(unit @)
    ?~  app-default
      ~
    `(cell-atom %vehicle-id i.app-default)
  =/  cards=tape
    |-
    ?~  vehicles
      ~
    =/  card
      %:  vehicle-card
          i.vehicles
          odometers
          definition-rows
          default-rows
          fills
          charges
          measurements
          batteries
          station-links
          additive-links
          preferences
          subtype-links
          economy-breaks
          default-subtypes
          driving-modes
          tank-sizes
          ?~(default-id %.n =((cell-atom %vehicle-id i.vehicles) u.default-id))
      ==
    =/  rest=tape  $(vehicles t.vehicles)
    (weld card rest)
  =/  html=tape
    ;:  weld
      (main-hub app-default definition-rows odometers tank-sizes)
      (entry-screens vehicles definition-rows stations additives subtypes default-subtypes driving-modes tags)
      "<section id=\"vehicles-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><div id=\"vehicle-view\"><header class=\"view-header\"><p class=\"eyebrow\">ROVER FLEET</p><h1>VEHICLES</h1></header><form id=\"vehicle-add-form\"><label>Vehicle name<input name=\"label\" required></label><label>Energy Source<select name=\"energy\">"
      definition-html
      "</select></label><button type=\"submit\">Add Vehicle</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form>"
      ?:(?=(~ vehicles) "<p class=\"empty\">No vehicles recorded.</p>" cards)
      "</div></section>"
      (history-screen vehicles fills fill-odometers)
      (statistics-screen fills vehicles subtype-links)
      "<section id=\"settings-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER CONFIGURATION</p><h1>SETTINGS</h1></header><p class=\"empty\">Theme, default vehicle, and custom fields.</p></section>"
    ==
  (crip html)
--
