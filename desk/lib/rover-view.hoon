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
++  starter-definition-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  archived  =(0 (cell-atom %archived i.rows))
  =/  rest  (starter-definition-options t.rows)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<option value=\""
    label
    "\" data-starter-source>"
    label
    "</option>"
    rest
  ==
::
++  vehicle-list-items
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  rest  (vehicle-list-items t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<li><button type=\"button\" data-open-vehicle-settings data-vehicle=\""
    label
    "\">"
    label
    "</button></li>"
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
++  vehicle-subtype-options
  |=  $:  rows=(list vector:ast)
          definitions=(list vector:ast)
          selected=(unit @t)
      ==
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  energy  (cell-text %energy i.rows)
  ?~  (row-by-text %energy energy definitions)
    rest
  =/  label  (cell-text %label i.rows)
  ;:  weld
    "<option value=\""
    (escape label)
    "\""
    ?:  ?&  ?=(^ selected)
            =(label u.selected)
        ==
      " selected"
    ""
    ">"
    (escape label)
    "</option>"
    rest
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
++  payment-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  rest  (payment-options t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<option value=\""
    label
    "\">"
    label
    "</option>"
    rest
  ==
::
++  custom-field-controls
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  active  !=(0 (cell-atom %archived i.rows))
  =/  rest  (custom-field-controls t.rows)
  ?.  active
    rest
  =/  label  (escape (cell-text %label i.rows))
  =/  content  (cell-term %content-type i.rows)
  =/  mandatory  =(0 (cell-atom %mandatory i.rows))
  =/  control=tape
    ?+  content
      ;:  weld
        "<input name=\"custom-"
        label
        "\" data-custom-field data-custom-label=\""
        label
        "\" data-custom-type=\"text\">"
      ==
      %number
        ;:  weld
          "<input name=\"custom-"
          label
          "\" inputmode=\"decimal\" data-custom-field data-custom-label=\""
          label
          "\" data-custom-type=\"number\">"
        ==
      %boolean
        ;:  weld
          "<input type=\"checkbox\" name=\"custom-"
          label
          "\" value=\"yes\" data-custom-field data-custom-label=\""
          label
          "\" data-custom-type=\"boolean\">"
        ==
    ==
  ;:  weld
    "<label class=\"custom-field-control\">"
    label
    ?:(mandatory " <span class=\"required\">required</span>" " <span class=\"optional\">optional</span>")
    control
    "</label>"
    rest
  ==
::
++  custom-definition-list
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  label  (escape (cell-text %label i.rows))
  =/  archived  =(0 (cell-atom %archived i.rows))
  ;:  weld
    "<li data-custom-definition=\""
    label
    "\"><span>"
    label
    " - "
    (escape (scot %tas (cell-term %content-type i.rows)))
    ?:(=(0 (cell-atom %mandatory i.rows)) " - mandatory" "")
    ?:(archived " - archived" "")
    "</span><button type=\"button\" data-archive-custom-field data-label=\""
    label
    "\">Archive</button><select data-change-custom-type><option value=\"number\">Number</option><option value=\"text\">Text</option><option value=\"boolean\">Boolean</option></select><button type=\"button\" data-change-custom-field data-label=\""
    label
    "\">Change type</button></li>"
    (custom-definition-list t.rows)
  ==
::
++  settings-screen
  |=  custom-definitions=(list vector:ast)
  ^-  tape
  ;:  weld
    "<section id=\"settings-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER CONFIGURATION</p><h1>SETTINGS</h1></header>"
    "<section data-settings-section=\"theme\"><h2>Theme</h2><p>Colors use the UA 571-C palette. Glow can be toggled from the header.</p><div class=\"theme-swatches\"><span>Background</span><span>Amber</span><span>Warning</span></div></section>"
    "<section data-settings-section=\"custom-fields\"><h2>Custom fields</h2><form id=\"custom-field-definition-form\"><label>Label<input name=\"label\" required></label><label>Content type<select name=\"contentType\"><option value=\"number\">Number</option><option value=\"text\">Text</option><option value=\"boolean\">Boolean</option></select></label><label class=\"check-option\"><input type=\"checkbox\" name=\"mandatory\"><span>Mandatory on Add Fill</span></label><button type=\"submit\">Create custom field</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form><ul id=\"custom-field-definitions\">"
    (custom-definition-list custom-definitions)
    "</ul></section><section class=\"settings-placeholder\"><h2>IMPORT / EXPORT - COMING LATER</h2></section><section class=\"settings-placeholder\"><h2>GRANTS - COMING LATER</h2></section></section>"
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
          custom-definitions=(list vector:ast)
          payment-methods=(list vector:ast)
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
  =/  custom-field-html  (custom-field-controls custom-definitions)
  =/  payment-html  (payment-options payment-methods)
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
    "<div id=\"fill-new-station\" hidden><label>Station label<input name=\"newStationLabel\" autocomplete=\"off\" placeholder=\"Home pump\"></label><label>Place label<input name=\"newPlaceLabel\" autocomplete=\"off\" placeholder=\"Home\"></label><label>Station kind<select name=\"newStationKind\"><option value=\"private\">Private</option><option value=\"fuel\">Fuel</option><option value=\"charging\">Charging</option><option value=\"mixed\">Mixed</option></select></label><label>Formatted address <span class=\"optional\">optional</span><input name=\"newAddressFormatted\" autocomplete=\"street-address\"></label><label>Address line 1 <span class=\"optional\">optional</span><input name=\"newAddressLine1\" autocomplete=\"address-line1\"></label><label>Address line 2 <span class=\"optional\">optional</span><input name=\"newAddressLine2\" autocomplete=\"address-line2\"></label><label>City/locality <span class=\"optional\">optional</span><input name=\"newLocality\" autocomplete=\"address-level2\"></label><label>Region <span class=\"optional\">optional</span><input name=\"newRegion\" autocomplete=\"address-level1\"></label><label>Postal code <span class=\"optional\">optional</span><input name=\"newPostalCode\" autocomplete=\"postal-code\"></label><label>Country <span class=\"optional\">optional</span><input name=\"newCountry\" autocomplete=\"country\"></label><label>Latitude <span class=\"optional\">optional</span><input name=\"newLatitude\" inputmode=\"decimal\" placeholder=\"41.8781136\"></label><label>Longitude <span class=\"optional\">optional</span><input name=\"newLongitude\" inputmode=\"decimal\" placeholder=\"-87.6297982\"></label></div>"
    "</fieldset>"
    "<label data-fill-field=\"driving-mode\">Driving Mode <span class=\"optional\">optional</span><select name=\"drivingMode\"><option value=\"\">Not recorded</option>"
    driving-mode-html
    "</select></label>"
    "<label data-fill-field=\"average-speed\">Average Speed <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"averageSpeed\" inputmode=\"decimal\" autocomplete=\"off\"><select name=\"speedUnit\"><option value=\"mph\">mph</option><option value=\"kph\">km/h</option></select></div></label>"
    "<fieldset class=\"drive-balance\" data-fill-field=\"drive-balance\"><legend>City &larr;&rarr; Highway <span class=\"optional\">optional</span></legend><output id=\"fill-drive-balance-state\">UNSET</output><input id=\"fill-drive-balance\" name=\"driveBalance\" type=\"range\" min=\"0\" max=\"100\" value=\"50\" data-state=\"unset\"><div class=\"balance-ends\"><span>City</span><span>Highway</span></div></fieldset>"
    "<fieldset id=\"fill-tags\" data-fill-field=\"tags\"><legend>Tags <span class=\"optional\">optional</span></legend><button type=\"button\" id=\"fill-tags-toggle\" aria-expanded=\"false\">Choose or add tags</button><div id=\"fill-tags-picker\" hidden><div class=\"check-grid\">"
    tag-html
    "</div><label>Add new tag<input name=\"newTag\" autocomplete=\"off\"></label></div></fieldset>"
    "<fieldset id=\"fill-custom-fields\" data-fill-field=\"custom-fields\"><legend>Custom fields</legend>"
    ?:(?=(~ custom-field-html) "<p class=\"empty\">No custom fields target Add Fill.</p>" custom-field-html)
    "</fieldset>"
    "<label data-fill-field=\"notes\">Notes <span class=\"optional\">optional</span><textarea name=\"notes\"></textarea></label>"
    "<label data-fill-field=\"payment-method\">Payment Method <span class=\"optional\">optional</span><select name=\"paymentMethod\"><option value=\"\">Not recorded</option>"
    payment-html
    "</select></label>"
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
          subtypes=(list vector:ast)
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
  =/  tank-value=tape
    ?~  tank
      ~
    (trip (format-scaled:render (cell-atom %digits i.tank) (cell-atom %decimals i.tank) %.n))
  =/  tank-unit=@tas
    ?~  tank
      %gal
    (cell-term %size-unit i.tank)
  =/  selected-subtype=(unit @t)
    ?~  default-subtype
      ~
    `(cell-text %subtype u.default-subtype)
  =/  subtype-controls
    (vehicle-subtype-options subtypes (rows-for id definition-rows) selected-subtype)
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
    "<article class=\"vehicle-card\" data-vehicle-settings-panel data-vehicle=\""
    (escape (cell-text %label row))
    "\" hidden><header><div><p class=\"eyebrow\">VEHICLE SETTINGS</p><h2>"
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
    "\">Add Odometer</button></div><form class=\"vehicle-settings-form\"><input type=\"hidden\" name=\"vehicle\" value=\""
    (escape label)
    "\"><label>Vehicle name<input name=\"label\" value=\""
    (escape label)
    "\" required></label><label>Default Subtype<select name=\"defaultSubtype\"><option value=\"\">Not set</option>"
    subtype-controls
    "</select></label><label>Tank Size<input name=\"tankSize\" inputmode=\"decimal\" value=\""
    tank-value
    "\"></label><label>Tank Unit<select name=\"tankUnit\"><option value=\"gal\""
    ?:(=(%gal tank-unit) " selected" "")
    ">gal</option><option value=\"litre\""
    ?:(=(%litre tank-unit) " selected" "")
    ">litre</option></select></label><button type=\"submit\">Save Vehicle Settings</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form><details class=\"vehicle-settings\"><summary>Configuration summary</summary>"
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
          payment-methods=(list vector:ast)
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
    "\"><input type=\"hidden\" name=\"originalObserved\" value=\""
    observed-input
    "\"><input type=\"hidden\" name=\"observed\" value=\""
    observed-input
    "\"><input type=\"hidden\" name=\"definition\" value=\""
    (escape (cell-text %energy row))
    "\"><input type=\"hidden\" name=\"zone\" value=\""
    (escape (cell-text %source-zone row))
    "\"><input type=\"hidden\" name=\"mileage\" value=\"\"><input type=\"hidden\" name=\"mileageUnit\" value=\"mi\"><input type=\"hidden\" name=\"station\" value=\"none\"><input type=\"hidden\" name=\"newStationLabel\" value=\"\"><input type=\"hidden\" name=\"newPlaceLabel\" value=\"\"><input type=\"hidden\" name=\"newStationKind\" value=\"private\"><input type=\"hidden\" name=\"subtype\" value=\"\"><input type=\"hidden\" name=\"missedFill\" value=\"no\"><input type=\"hidden\" name=\"drivingMode\" value=\"\"><input type=\"hidden\" name=\"averageSpeed\" value=\"\"><input type=\"hidden\" name=\"speedUnit\" value=\"mph\"><input type=\"hidden\" name=\"driveBalance\" value=\"\"><input type=\"hidden\" name=\"newTag\" value=\"\"><label>Notes<textarea name=\"notes\"></textarea></label><label>Payment Method<select name=\"paymentMethod\"><option value=\"\">Not recorded</option>"
    (payment-options payment-methods)
    "</select></label><label>Quantity<input name=\"quantity\" inputmode=\"decimal\" value=\""
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
          stations=(list vector:ast)
          subtypes=(list vector:ast)
          driving-modes=(list vector:ast)
          fill-driving-modes=(list vector:ast)
          fill-average-speeds=(list vector:ast)
          fill-drive-balances=(list vector:ast)
          fill-notes=(list vector:ast)
          fill-payment-links=(list vector:ast)
          payment-methods=(list vector:ast)
      ==
  ^-  tape
  =/  ordered  (order-vectors:act %observed-start %.n fills)
  =/  render-rows
    |=  rows=(list vector:ast)
    ^-  tape
    ?~  rows
      ~
    (weld (history-row i.rows vehicles odometer-links payment-methods) $(rows t.rows))
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
++  interval-quantity
  |=  $:  fills=(list vector:ast)
          vehicle-id=@
          after=@da
          through=@da
          quantity-unit=@tas
      ==
  ^-  (unit @ud)
  ?~  fills
    `0
  =/  row  i.fills
  =/  date=@da  `@da`(cell-atom %observed-start row)
  =/  included
    ?&  =(vehicle-id (cell-atom %vehicle-id row))
        (gth date after)
        (lte date through)
    ==
  =/  rest
    $(fills t.fills)
  ?~  rest
    ~
  ?.  included
    rest
  ?.  =(quantity-unit (cell-term %quantity-unit row))
    ~
  `(add (cell-atom %quantity-milli row) u.rest)
::
++  interval-has-break
  |=  $:  fills=(list vector:ast)
          breaks=(list vector:ast)
          vehicle-id=@
          after=@da
          through=@da
      ==
  ^-  ?
  ?~  fills
    %.n
  =/  row  i.fills
  =/  date=@da  `@da`(cell-atom %observed-start row)
  ?:  ?&  =(vehicle-id (cell-atom %vehicle-id row))
          (gth date after)
          (lte date through)
          ?=(^ (rows-by %acquisition-id (cell-atom %acquisition-id row) breaks))
      ==
    %.y
  $(fills t.fills)
::
++  economy-for-fill
  |=  $:  close=vector:ast
          fills=(list vector:ast)
          odometers=(list vector:ast)
          breaks=(list vector:ast)
      ==
  ^-  (unit [milli=@ud unit=@t])
  ?.  =(%full (cell-term %tank-state close))
    ~
  =/  close-odo
    (rows-by %acquisition-id (cell-atom %acquisition-id close) odometers)
  ?.  =(1 (lent close-odo))
    ~
  =/  vehicle-id  (cell-atom %vehicle-id close)
  =/  close-date=@da  `@da`(cell-atom %observed-start close)
  =/  prior-fulls=(list vector:ast)
    %+  skim  fills
    |=  row=vector:ast
    ?&  =(vehicle-id (cell-atom %vehicle-id row))
        (lth (cell-atom %observed-start row) close-date)
        =(%full (cell-term %tank-state row))
        =(1 (lent (rows-by %acquisition-id (cell-atom %acquisition-id row) odometers)))
    ==
  ?~  prior-fulls
    ~
  =/  prior  (snag 0 (order-vectors:act %observed-start %.n prior-fulls))
  =/  prior-date=@da  `@da`(cell-atom %observed-start prior)
  ?:  (interval-has-break fills breaks vehicle-id prior-date close-date)
    ~
  =/  quantity-unit  (cell-term %quantity-unit close)
  =/  quantity
    (interval-quantity fills vehicle-id prior-date close-date quantity-unit)
  ?~  quantity
    ~
  ?:  =(0 u.quantity)
    ~
  =/  prior-odo
    (snag 0 (rows-by %acquisition-id (cell-atom %acquisition-id prior) odometers))
  =/  close-odo-row  (snag 0 close-odo)
  =/  distance-unit  (cell-term %unit close-odo-row)
  ?.  =(distance-unit (cell-term %unit prior-odo))
    ~
  =/  prior-places  (cell-atom %decimal-places prior-odo)
  =/  close-places  (cell-atom %decimal-places close-odo-row)
  ?:  ?|((gth prior-places 3) (gth close-places 3))
    ~
  =/  prior-milli
    (mul (cell-atom %value-digits prior-odo) (pow-ten:render (sub 3 prior-places)))
  =/  close-milli
    (mul (cell-atom %value-digits close-odo-row) (pow-ten:render (sub 3 close-places)))
  ?.  (gth close-milli prior-milli)
    ~
  =/  unit=@t
    ?:  ?&  =(%mi distance-unit)
            =(%gal quantity-unit)
        ==
      'mpg'
    ?:  ?&  =(%km distance-unit)
            =(%litre quantity-unit)
        ==
      'km/L'
    ''
  ?:  =('' unit)
    ~
  =/  distance-milli  (sub close-milli prior-milli)
  =/  economy-milli
    (div (add (mul distance-milli 1.000) (div u.quantity 2)) u.quantity)
  `[economy-milli unit]
::
++  statistic-fill-rows
  |=  $:  fills=(list vector:ast)
          all-fills=(list vector:ast)
          vehicles=(list vector:ast)
          subtype-links=(list vector:ast)
          odometers=(list vector:ast)
          breaks=(list vector:ast)
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
  =/  economy
    (economy-for-fill row all-fills odometers breaks)
  =/  rendered=tape
    ?+  mode  ~
      %economy
        ;:  weld
          "<tr data-economy-vehicle=\""
          (escape vehicle)
          "\" data-economy=\""
          ?~(economy "Unavailable" (weld (trip (format-scaled:render milli.u.economy 3 %.n)) (weld " " (trip unit.u.economy))))
          "\"><td>"
          date
          "</td><td>"
          ?:(?=(~ subtype) "Not recorded" (escape (cell-text %subtype i.subtype)))
          "</td><td>"
          ?~(economy "Unavailable" (weld (trip (format-scaled:render milli.u.economy 3 %.n)) (weld " " (trip unit.u.economy))))
          "</td><td>"
          ?:(?=(~ economy) "An eligible adjacent full-fill interval is required." "Eligible full-fill interval.")
          "</td></tr>"
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
          odometers=(list vector:ast)
          breaks=(list vector:ast)
      ==
  ^-  tape
  =/  recent  (order-vectors:act %observed-start %.n fills)
  ;:  weld
    "<section id=\"statistics-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER ANALYSIS</p><h1>STATISTICS</h1></header>"
    "<section class=\"stat-table\" data-statistic=\"economy-by-subtype\"><h2>Economy per fill by fuel subtype</h2><table><thead><tr><th>Date</th><th>Fuel subtype</th><th>Economy</th><th>Eligibility</th></tr></thead><tbody>"
    (statistic-fill-rows recent fills vehicles subtype-links odometers breaks %economy)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"fuel-costs\"><h2>Fuel costs</h2><table><thead><tr><th>Date</th><th>Vehicle</th><th>Total cost</th></tr></thead><tbody>"
    (statistic-fill-rows recent fills vehicles subtype-links odometers breaks %cost)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"distance-between-fills\"><h2>Distance between fills</h2><table><tbody><tr><td>Unavailable</td><td>Adjacent odometer-linked full fills are required.</td></tr></tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"time-between-fills\"><h2>Time between fills</h2><table><tbody><tr><td>Unavailable</td><td>Two eligible ordered fills are required for the selected vehicle.</td></tr></tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"average-price-per-unit\"><h2>Average price per unit</h2><table><thead><tr><th>Date</th><th>Vehicle</th><th>Observed unit price</th></tr></thead><tbody>"
    (statistic-fill-rows recent fills vehicles subtype-links odometers breaks %price)
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
  =/  starter-definitions  (rows-at commands 23)
  =/  fill-driving-modes  (rows-at commands 24)
  =/  fill-average-speeds  (rows-at commands 25)
  =/  fill-drive-balances  (rows-at commands 26)
  =/  fill-notes  (rows-at commands 27)
  =/  fill-payment-links  (rows-at commands 28)
  =/  payment-methods  (rows-at commands 29)
  =/  custom-definitions  (rows-at commands 18)
  =/  definition-html  (definition-options definition-rows vehicles)
  =/  starter-html  (starter-definition-options starter-definitions)
  =/  starter-subtype-html  (subtype-options subtypes)
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
          subtypes
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
      (entry-screens vehicles definition-rows stations additives subtypes default-subtypes driving-modes tags custom-definitions payment-methods)
      "<section id=\"vehicles-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER FLEET</p><h1>VEHICLES</h1></header><button type=\"button\" data-open-screen=\"vehicle-create-screen\">Add Vehicle</button>"
      ?:(?=(~ vehicles) "<p class=\"empty\">No vehicles recorded.</p>" (weld "<ul class=\"vehicle-list\">" (weld (vehicle-list-items vehicles) "</ul>")))
      "</section>"
      "<section id=\"vehicle-create-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"vehicles-screen\">&lsaquo; VEHICLES</button><header class=\"view-header\"><p class=\"eyebrow\">NEW VEHICLE</p><h1>ADD VEHICLE</h1></header><form id=\"vehicle-add-form\"><label>Vehicle name<input name=\"label\" required></label><label>Primary Energy Source<select name=\"energy\">"
      starter-html
      "</select></label><label>Additional Energy Sources<select name=\"additionalEnergy\" multiple>"
      starter-html
      "</select></label><label>Allowed Subtypes<select name=\"allowedSubtypes\" multiple>"
      starter-subtype-html
      "</select></label><label>Default Subtype<select name=\"defaultSubtype\"><option value=\"\">Not set</option>"
      starter-subtype-html
      "</select></label><label>Tank Size<input name=\"tankSize\" inputmode=\"decimal\"></label><label>Tank Unit<select name=\"tankUnit\"><option value=\"gal\">gal</option><option value=\"litre\">litre</option></select></label><label>Driving Modes<input name=\"drivingModes\" placeholder=\"Normal, Economy, Sport\"></label><label>Distance Display<select name=\"distanceUnit\"><option value=\"native\">Source-native</option><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label><label>Currency Display<select name=\"currency\"><option value=\"usd\">USD</option><option value=\"eur\">EUR</option></select></label><button type=\"submit\">Save Vehicle</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form></section>"
      "<section id=\"vehicle-settings-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"vehicles-screen\">&lsaquo; VEHICLES</button>"
      ?:(?=(~ vehicles) "<p class=\"empty\">No vehicle selected.</p>" cards)
      "</section>"
      (history-screen vehicles fills fill-odometers stations subtypes driving-modes fill-driving-modes fill-average-speeds fill-drive-balances fill-notes fill-payment-links payment-methods)
      (statistics-screen fills vehicles subtype-links fill-odometers economy-breaks)
      (settings-screen custom-definitions)
    ==
  (crip html)
--
