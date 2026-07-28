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
++  fill-card
  |=  row=vector:ast
  ^-  tape
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
    "</dd></div></dl></article>"
  ==
::
++  fill-cards
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  card=tape  (fill-card i.rows)
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
++  vehicle-card
  |=  $:  row=vector:ast
          odometers=(list vector:ast)
          definition-rows=(list vector:ast)
          default-rows=(list vector:ast)
          fills=(list vector:ast)
      ==
  ^-  tape
  =/  id  (cell-atom %vehicle-id row)
  =/  archived  =(0 (cell-atom %archived row))
  =/  odometer  (current-odometer (rows-for id odometers))
  =/  defs  (definitions (rows-for id definition-rows) (rows-for id default-rows))
  =/  history  (fill-history (rows-for id fills))
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
  =/  cards=tape
    |-
    ?~  vehicles
      ~
    =/  card
      (vehicle-card i.vehicles odometers definition-rows default-rows fills)
    =/  rest=tape  $(vehicles t.vehicles)
    (weld card rest)
  =/  html=tape
    ;:  weld
      "<section id=\"vehicle-view\"><header class=\"view-header\"><p class=\"eyebrow\">ROVER FLEET</p><h1>VEHICLES</h1></header>"
      ?:(?=(~ vehicles) "<p class=\"empty\">No vehicles recorded.</p>" cards)
      "</section>"
    ==
  (crip html)
--
