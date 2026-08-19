::  lib/rover-view - render Obelisk query results as owner-facing HTML.
::
::  Internal IDs are used only to assemble rows. They never enter output.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, render=rover-render
::
|%
+$  interval-proof
  [distance-milli=@ud distance-unit=@tas elapsed-seconds=@ud]
+$  economy-proof
  [milli=@ud unit=@t]
+$  distance-proof
  [milli=@ud unit=@tas]
+$  derived-fill
  [economy=(unit economy-proof) interval=(unit interval-proof) break-reason=(unit @tas)]
+$  interval-baseline
  [date=@da odometer=vector:ast]
::  The two charging-cost child relations travel together through the history
::  render, so one name carries both instead of two positional arguments.
+$  charging-cost-rows
  [components=(list vector:ast) source-totals=(list vector:ast)]
::  The vehicle-event family travels through the history render as one name.
::  Every member after `events` is keyed by `event-id` - by the family PARENT,
::  never by a typed child - so one lookup shape serves all three kinds.
+$  event-rows
  $:  events=(list vector:ast)
      services=(list vector:ast)
      expenses=(list vector:ast)
      notes=(list vector:ast)
      costs=(list vector:ast)
      cost-totals=(list vector:ast)
      odometers=(list vector:ast)
      stations=(list vector:ast)
      tags=(list vector:ast)
      payments=(list vector:ast)
      note-texts=(list vector:ast)
      service-subtypes=(list vector:ast)
      ::  M7 T4. Two more typed children. `disposals` carries the kind label
      ::  the child references, so the card needs no second lookup.
      acquisitions=(list vector:ast)
      disposals=(list vector:ast)
  ==
::  The dedicated Statistics queries are selected-vehicle reads. Their wide
::  rows retain every relation key while Gall assembles the common cost shape.
+$  statistics-cost-rows
  $:  fuels=(list vector:ast)
      consumables=(list vector:ast)
      events=(list vector:ast)
      services=(list vector:ast)
      expenses=(list vector:ast)
      notes=(list vector:ast)
      acquisitions=(list vector:ast)
      disposals=(list vector:ast)
      costs=(list vector:ast)
      totals=(list vector:ast)
      event-odometers=(list vector:ast)
      service-subtypes=(list vector:ast)
      vehicle-odometers=(list vector:ast)
  ==
::  Signed mills keep disposal proceeds as credits. `entries` counts only
::  records that carry a total; an absent cost never turns into zero.
+$  cost-tally
  $:  entries=@ud
      total=@sd
      currency=(unit @tas)
      minor-decimals=(unit @ud)
      compatible=?
  ==
+$  interval-walk
  $:  prior=(unit interval-baseline)
      quantity=@ud
      quantity-unit=(unit @tas)
      quantity-valid=?
      break-reason=(unit @tas)
  ==
::  M7 T5, ruling 12. Ownership is an interval. A purchase opens one and a
::  disposal closes one, so a vehicle carries one or more of them. An absent
::  bound is not a sentinel: an absent start reaches back to the first record,
::  and an absent end reaches the present.
+$  ownership-interval
  [start=(unit @da) end=(unit @da)]
::  M7 T6. The derived current odometer, as a number rather than as the tape
::  the readout prints. One derivation serves both.
+$  current-reading
  [digits=@ud places=@ud reading-unit=@tas date=@da]
::  M7 T6. The reminder family travels through the render as one name, the way
::  the event family does. `event-subtypes` is keyed by event and holds the
::  subtype ID, because a reminder matches on the ID its own row carries.
+$  reminder-rows
  $:  reminders=(list vector:ast)
      times=(list vector:ast)
      distances=(list vector:ast)
      event-subtypes=(list vector:ast)
  ==
::  What one reminder says, in three states and never in two. `%due` and
::  `%not-due` are answers; `%unavailable` is the refusal, and it carries the
::  human reason for it.
+$  reminder-verdict
  [state=@tas headline=@t detail=@t]
::  A service the reminder names, already recorded. The odometer is a unit
::  because a service visit may be recorded without a reading.
+$  reminder-completion
  [date=@da odometer=(unit vector:ast)]
::  M7 T7. The thirteen specification relations, keyed by relation name rather
::  than carried as thirteen positional arguments. `spec-view-order:act` is the
::  one list that decides which query answers which name.
+$  spec-index  (map @tas (list vector:ast))
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
++  row-ids
  |=  [key=@tas rows=(list vector:ast)]
  ^-  (list @ux)
  %+  turn  rows
  |=  row=vector:ast
  `@ux`(cell-atom key row)
::
++  last-vector
  |=  rows=(list vector:ast)
  ^-  (unit vector:ast)
  ?~  rows
    ~
  ?~  t.rows
    `i.rows
  $(rows t.rows)
::
::  The @f bunt is %.y, so an archived link reads 0 and an active link reads 1.
++  archived-link-rows
  |=  rows=(list vector:ast)
  ^-  (list vector:ast)
  %+  skim  rows
  |=  row=vector:ast
  =(0 (cell-atom %link-archived row))
::
++  index-rows
  |=  $:  key=@tas
          rows=(list vector:ast)
          index=(map @ (list vector:ast))
      ==
  ^-  (map @ (list vector:ast))
  ?~  rows
    index
  =/  value  (cell-atom key i.rows)
  =/  existing  (~(get by index) value)
  =/  indexed
    ?~  existing
      [i.rows ~]
    [i.rows u.existing]
  $(rows t.rows, index (~(put by index) value indexed))
::
++  one-indexed-row
  |=  [key=@ index=(map @ (list vector:ast))]
  ^-  (unit vector:ast)
  =/  found  (~(get by index) key)
  ?~  found
    ~
  ?.  =(1 (lent u.found))
    ~
  `(snag 0 u.found)
::
++  indexed-break
  |=  [key=@ index=(map @ (list vector:ast))]
  ^-  (unit @tas)
  =/  found  (~(get by index) key)
  ?~  found
    ~
  `(cell-term %reason (snag 0 u.found))
::
::  M7 T5. One ownership map for the whole render, keyed by vehicle. The two
::  typed children carry identity only, so which child a boundary event belongs
::  to is what makes it a purchase or a sale.
++  ownership-index
  |=  $:  events=(list vector:ast)
          acquisitions=(list vector:ast)
          disposals=(list vector:ast)
      ==
  ^-  (map @ (list ownership-interval))
  =/  bought=(set @)
    (~(gas in *(set @)) `(list @)`(row-ids %event-id acquisitions))
  =/  sold=(set @)
    (~(gas in *(set @)) `(list @)`(row-ids %event-id disposals))
  =/  boundaries=(list vector:ast)
    %+  skim  events
    |=  row=vector:ast
    =/  event  (cell-atom %event-id row)
    ?|((~(has in bought) event) (~(has in sold) event))
  =/  by-vehicle
    (index-rows %vehicle-id boundaries *(map @ (list vector:ast)))
  %-  ~(gas by *(map @ (list ownership-interval)))
  %+  turn  ~(tap by by-vehicle)
  |=  [vehicle=@ rows=(list vector:ast)]
  ^-  [@ (list ownership-interval)]
  [vehicle (ownership-walk (order-vectors:act %observed-start %.n rows) sold)]
::
::  A purchase opens an interval and a disposal closes one. Two rules the event
::  rows can force and the ruling does not name:
::
::  A second purchase inside an open interval opens nothing. The vehicle never
::  left the owner's hands, so there is no gap to honour.
::
::  A sale with no purchase before it closes an interval that reaches back to
::  the first record. An owner who records only the sale still held the vehicle
::  before it, and refusing to close on that evidence would ignore a disposal
::  Rover can plainly see.
++  ownership-walk
  |=  [rows=(list vector:ast) sold=(set @)]
  ^-  (list ownership-interval)
  =|  spans=(list ownership-interval)
  =/  open=?  %.n
  =/  start=(unit @da)  ~
  |-
  ^-  (list ownership-interval)
  ?~  rows
    ?.  open
      (flop spans)
    =/  reaching-now=ownership-interval  [start ~]
    (flop [reaching-now spans])
  =/  date=@da  `@da`(cell-atom %observed-start i.rows)
  ?:  (~(has in sold) (cell-atom %event-id i.rows))
    $(rows t.rows, spans [[start `date] spans], open %.n, start ~)
  ?:  open
    $(rows t.rows)
  $(rows t.rows, open %.y, start `date)
::
::  Which ownership interval holds this date. A date inside a gap is in none of
::  them, and the empty product says so.
++  ownership-segment
  |=  [spans=(list ownership-interval) date=@da]
  ^-  (unit @ud)
  =/  index=@ud  0
  |-
  ^-  (unit @ud)
  ?~  spans
    ~
  ?:  ?&  ?~(start.i.spans %.y (gte date u.start.i.spans))
          ?~(end.i.spans %.y (lte date u.end.i.spans))
      ==
    `index
  $(spans t.spans, index +(index))
::
::  Ruling 12: every interval derivation runs inside ONE ownership interval and
::  never crosses a gap between two. A break here is DERIVED. Nothing writes a
::  row for it, and the owner is never asked to mark it.
::
::  A vehicle with no purchase and no sale has no ownership boundary. The empty
::  span list answers no, so its derivations are exactly what they were before
::  T5. Every database installed today is in that state.
++  ownership-gap
  |=  [spans=(list ownership-interval) after=@da through=@da]
  ^-  ?
  ?~  spans
    %.n
  =/  opening  (ownership-segment spans after)
  =/  closing  (ownership-segment spans through)
  ?|  ?=(~ opening)
      ?=(~ closing)
      !=(u.opening u.closing)
  ==
::
++  derive-fill-series
  |=  $:  fills=(list vector:ast)
          odometers=(list vector:ast)
          breaks=(list vector:ast)
          ownership=(map @ (list ownership-interval))
      ==
  ^-  (map @ derived-fill)
  =/  ordered  (order-vectors:act %observed-start %.n fills)
  =/  odometer-index
(index-rows %acquisition-id odometers *(map @ (list vector:ast)))
  =/  break-index
(index-rows %acquisition-id breaks *(map @ (list vector:ast)))
  =/  rows  ordered
  =/  states  *(map @ interval-walk)
  =/  derived  *(map @ derived-fill)
  |-
  ^-  (map @ derived-fill)
  ?~  rows
    derived
  =/  row  i.rows
  =/  acquisition  (cell-atom %acquisition-id row)
  =/  vehicle  (cell-atom %vehicle-id row)
  =/  date=@da  `@da`(cell-atom %observed-start row)
  =/  found-state  (~(get by states) vehicle)
  =/  state=interval-walk
    ?~  found-state
      [~ 0 ~ %.y ~]
    u.found-state
  =/  row-break  (indexed-break acquisition break-index)
  =/  state
    ?~  prior.state
      state
    %_  state
      quantity  (add quantity.state (cell-atom %quantity-milli row))
      quantity-unit
        ?~  quantity-unit.state
          `(cell-term %quantity-unit row)
        quantity-unit.state
      quantity-valid
        ?~  quantity-unit.state
          quantity-valid.state
        ?&  quantity-valid.state
            =(u.quantity-unit.state (cell-term %quantity-unit row))
        ==
      break-reason
        ?~  row-break
          break-reason.state
        row-break
    ==
  =/  close-odometer
    (one-indexed-row acquisition odometer-index)
  ?.  =(%full (cell-term %tank-state row))
    $(rows t.rows, states (~(put by states) vehicle state))
  ?~  close-odometer
    $(rows t.rows, states (~(put by states) vehicle state))
  ::  M7 T5. The derived break. An owner-supplied reason still wins when both
  ::  apply: it is the more specific fact, and it is what the owner was told.
  =/  spans=(list ownership-interval)  (~(gut by ownership) vehicle ~)
  =/  break-reason=(unit @tas)
    ?^  break-reason.state
      break-reason.state
    ?~  prior.state
      ~
    ?.  (ownership-gap spans date.u.prior.state date)
      ~
    `%ownership-gap
  =/  interval=(unit interval-proof)
    ?:  ?|  ?=(~ prior.state)
            ?=(^ break-reason)
        ==
      ~
    =/  prior-odometer  odometer.u.prior.state
    =/  close-places  (cell-atom %decimal-places u.close-odometer)
    =/  prior-places  (cell-atom %decimal-places prior-odometer)
    ?:  ?|  (gth close-places 3)
            (gth prior-places 3)
            !=((cell-term %unit u.close-odometer) (cell-term %unit prior-odometer))
            (lte date date.u.prior.state)
        ==
      ~
    =/  close-milli
      (mul (cell-atom %value-digits u.close-odometer) (pow-ten:render (sub 3 close-places)))
    =/  prior-milli
      (mul (cell-atom %value-digits prior-odometer) (pow-ten:render (sub 3 prior-places)))
    ?.  (gth close-milli prior-milli)
      ~
    `[(sub close-milli prior-milli) (cell-term %unit u.close-odometer) (div (sub date date.u.prior.state) (bex 64))]
  =/  economy=(unit economy-proof)
    ?:  ?|  ?=(~ interval)
            =(%.n quantity-valid.state)
            ?=(~ quantity-unit.state)
            =(0 quantity.state)
        ==
      ~
    =/  unit=@t
      ?:  ?&  =(%mi distance-unit.u.interval)
              =(%gal u.quantity-unit.state)
          ==
        'mpg'
      ?:  ?&  =(%km distance-unit.u.interval)
              =(%litre u.quantity-unit.state)
          ==
        'km/L'
      ''
    ?:  =('' unit)
      ~
    =/  economy-milli
      (div (add (mul distance-milli.u.interval 1.000) (div quantity.state 2)) quantity.state)
    `[economy-milli unit]
  =/  result=derived-fill
    [economy interval break-reason]
  =/  next-state=interval-walk
    [`[date u.close-odometer] 0 ~ %.y ~]
  $(rows t.rows, states (~(put by states) vehicle next-state), derived (~(put by derived) acquisition result))
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
  =/  rest  $(rows t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (escape (cell-text %label i.rows))
  =/  option
    ;:  weld
      "<option value=\""
      label
      "\">"
      label
      "</option>"
    ==
  (weld option rest)
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
  |=  [rows=(list vector:ast) localities=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  archived  =(0 (cell-atom %archived i.rows))
  =/  rest  (station-options t.rows localities)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  =/  place  (escape (cell-text %place i.rows))
  =/  locality-row
    (rows-by %place-id (cell-atom %place-id i.rows) localities)
  =/  locality=tape
    ?~  locality-row
      ~
    (escape (cell-text %locality i.locality-row))
  ;:  weld
    "<option value=\""
    label
    "\" data-search=\""
    label
    " "
    place
    ?~(locality ~ (weld " " locality))
    "\">"
    label
    " - "
    place
    ?~(locality ~ (weld " - " locality))
    "</option>"
    rest
  ==
::
++  address-locality-data
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  ;:  weld
    "<span hidden data-place-locality data-place=\""
    (escape (cell-text %place i.rows))
    "\" data-locality=\""
    (escape (cell-text %locality i.rows))
    "\"></span>"
    $(rows t.rows)
  ==
::
++  consumable-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<option value=\""
    label
    "\" data-unit=\""
    (trip (scot %tas (cell-term %quantity-unit i.rows)))
    "\">"
    label
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
++  archived-vehicle-list-items
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  !=(0 (cell-atom %archived i.rows))
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
++  odometer-series-data
  |=  [rows=(list vector:ast) vehicles=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  vehicle  (vehicle-label (cell-atom %vehicle-id i.rows) vehicles)
  =/  display
    %:  format-distance:render
        (cell-atom %value-digits i.rows)
        (cell-atom %decimal-places i.rows)
        (cell-term %unit i.rows)
        %.n
    ==
  ;:  weld
    "<span hidden data-odometer-observation data-vehicle=\""
    (escape vehicle)
    "\" data-observed=\""
    (input-da `@da`(cell-atom %observed-start i.rows))
    "\" data-reading=\""
    (escape display)
    "\"></span>"
    $(rows t.rows)
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
++  vehicle-energy-source-options
  |=  [rows=(list vector:ast) linked=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (cell-text %label i.rows)
  =/  selected-row  (row-by-text %energy label linked)
  =/  selected
    ?~  selected-row
      %.n
    !=(0 (cell-atom %link-archived u.selected-row))
  ;:  weld
    "<option value=\""
    (escape label)
    "\""
    ?:(selected " selected" "")
    ">"
    (escape label)
    "</option>"
    rest
  ==
::
++  vehicle-energy-source-checks
  |=  [rows=(list vector:ast) linked=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (cell-text %label i.rows)
  =/  selected-row  (row-by-text %energy label linked)
  =/  selected
    ?~  selected-row
      %.n
    !=(0 (cell-atom %link-archived u.selected-row))
  ;:  weld
    "<label class=\"check-option\"><input type=\"checkbox\" name=\"energySources\" value=\""
    (escape label)
    "\""
    ?:(selected " checked" "")
    "><span>"
    (escape label)
    "</span></label>"
    rest
  ==
::
++  vehicle-mode-membership-options
  |=  [rows=(list vector:ast) linked=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (cell-text %label i.rows)
  =/  selected-row  (row-by-text %label label linked)
  =/  selected
    ?~  selected-row
      %.n
    !=(0 (cell-atom %link-archived u.selected-row))
  ;:  weld
    "<option value=\""
    (escape label)
    "\""
    ?:(selected " selected" "")
    ">"
    (escape label)
    "</option>"
    rest
  ==
::
++  vehicle-mode-membership-checks
  |=  [rows=(list vector:ast) linked=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  =(0 (cell-atom %archived i.rows))
    rest
  =/  label  (cell-text %label i.rows)
  =/  selected-row  (row-by-text %label label linked)
  =/  selected
    ?~  selected-row
      %.n
    !=(0 (cell-atom %link-archived u.selected-row))
  ;:  weld
    "<label class=\"check-option\"><input type=\"checkbox\" name=\"drivingModes\" value=\""
    (escape label)
    "\""
    ?:(selected " checked" "")
    "><span>"
    (escape label)
    "</span></label>"
    rest
  ==
::
++  default-energy-options
  |=  [rows=(list vector:ast) selected=(unit @t)]
  ^-  tape
  ?~  rows
    ~
  =/  rest  $(rows t.rows)
  ?:  ?|  =(0 (cell-atom %energy-archived i.rows))
          =(0 (cell-atom %link-archived i.rows))
      ==
    rest
  =/  label  (cell-text %energy i.rows)
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
++  active-energy-kind
  |=  [kind=@tas rows=(list vector:ast)]
  ^-  ?
  ?~  rows
    %.n
  ?:  ?&  =(kind (cell-term %physical-kind i.rows))
          !=(0 (cell-atom %energy-archived i.rows))
          !=(0 (cell-atom %link-archived i.rows))
      ==
    %.y
  $(rows t.rows)
::
++  active-energy-label
  |=  [label=@t rows=(list vector:ast)]
  ^-  ?
  ?~  rows
    %.n
  ?:  ?&  =(label (cell-text %energy i.rows))
          !=(0 (cell-atom %energy-archived i.rows))
          !=(0 (cell-atom %link-archived i.rows))
      ==
    %.y
  $(rows t.rows)
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
::  M7 T2. One checkbox per service subtype, because the corpus proves the
::  selection is many-to-many. An archived definition leaves the selector and
::  the historical records that name it still render.
++  service-subtype-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  archived  =(0 (cell-atom %archived i.rows))
  =/  rest  (service-subtype-options t.rows)
  ?:  archived
    rest
  =/  label  (escape (cell-text %label i.rows))
  ;:  weld
    "<label class=\"check-option\"><input type=\"checkbox\" name=\"subtypes\" value=\""
    label
    "\"><span>"
    label
    "</span></label>"
    rest
  ==
::
::  M7 T6. The same catalog as a drop-down. A reminder names exactly one kind
::  of service work, so it picks one rather than checking several.
++  service-subtype-select-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  rest  (service-subtype-select-options t.rows)
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
::  M7 T4. The disposal-kind selector. An archived definition leaves the
::  selector but the historical record that names it still renders, which is
::  the same rule every other definition family follows.
++  disposal-kind-options
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  rest  (disposal-kind-options t.rows)
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
++  selected-options
  |=  $:  rows=(list vector:ast)
          key=@tas
          selected=(unit @t)
      ==
  ^-  tape
  ?~  rows
    ~
  =/  label  (cell-text key i.rows)
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
    $(rows t.rows)
  ==
::
::  M7 T8. The edit form of a record that already exists. An archived
::  definition leaves the selector here the same way it leaves the entry form,
::  with one difference the entry form cannot have: a record this old may
::  already name the archived definition. That row stays on the list and stays
::  selected, because dropping it would make saving an unrelated edit quietly
::  delete an association the person never touched.
++  selected-active-options
  |=  $:  rows=(list vector:ast)
          key=@tas
          selected=(unit @t)
      ==
  ^-  tape
  ?~  rows
    ~
  =/  label  (cell-text key i.rows)
  =/  chosen  ?&(?=(^ selected) =(label u.selected))
  ?:  ?&  =(0 (cell-atom %archived i.rows))
          !chosen
      ==
    $(rows t.rows)
  ;:  weld
    "<option value=\""
    (escape label)
    "\""
    ?:(chosen " selected" "")
    ">"
    (escape label)
    "</option>"
    $(rows t.rows)
  ==
::
::  The same rule for the driving-mode select, which reads two flags rather
::  than one: the definition can be archived, and this vehicle's membership in
::  it can be archived independently.
++  selected-active-mode-options
  |=  $:  rows=(list vector:ast)
          selected=(unit @t)
      ==
  ^-  tape
  ?~  rows
    ~
  =/  label  (cell-text %label i.rows)
  =/  chosen  ?&(?=(^ selected) =(label u.selected))
  ?:  ?&  ?|  =(0 (cell-atom %mode-archived i.rows))
              =(0 (cell-atom %link-archived i.rows))
          ==
          !chosen
      ==
    $(rows t.rows)
  ;:  weld
    "<option value=\""
    (escape label)
    "\""
    ?:(chosen " selected" "")
    ">"
    (escape label)
    "</option>"
    $(rows t.rows)
  ==
::
++  selected-active-check-options
  |=  $:  rows=(list vector:ast)
          key=@tas
          selected=(list vector:ast)
          selected-key=@tas
          name=@t
      ==
  ^-  tape
  ?~  rows
    ~
  =/  label  (cell-text key i.rows)
  =/  chosen  ?=(^ (row-by-text selected-key label selected))
  ?:  ?&  =(0 (cell-atom %archived i.rows))
          !chosen
      ==
    $(rows t.rows)
  ;:  weld
    "<label class=\"check-option\"><input type=\"checkbox\" name=\""
    (escape name)
    "\" value=\""
    (escape label)
    "\""
    ?:(chosen " checked" "")
    "><span>"
    (escape label)
    "</span></label>"
    $(rows t.rows)
  ==
::
++  selected-check-options
  |=  $:  rows=(list vector:ast)
          key=@tas
          selected=(list vector:ast)
          selected-key=@tas
          name=@t
      ==
  ^-  tape
  ?~  rows
    ~
  =/  label  (cell-text key i.rows)
  ;:  weld
    "<label class=\"check-option\"><input type=\"checkbox\" name=\""
    (escape name)
    "\" value=\""
    (escape label)
    "\""
    ?:  ?=(^ (row-by-text selected-key label selected))
      " checked"
    ""
    "><span>"
    (escape label)
    "</span></label>"
    $(rows t.rows)
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
::  M7 T8. The three lifecycle controls one definition carries. An active
::  definition offers Rename and Archive; an archived one offers Rename and
::  Restore, because a person who archived by mistake needs the way back and a
::  mistyped label is worth correcting whether or not the definition is still
::  offered anywhere.
::
::  The family term rides the button, so the browser never has to know which
::  relation a definition lives in.
++  definition-lifecycle-controls
  |=  [family=@t label=tape archived=?]
  ^-  tape
  ;:  weld
    "<button type=\"button\" data-rename-definition data-family=\""
    (escape family)
    "\" data-label=\""
    label
    "\">Rename</button>"
    ?:  archived
      ;:  weld
        "<button type=\"button\" data-restore-definition data-family=\""
        (escape family)
        "\" data-label=\""
        label
        "\">Restore</button>"
      ==
    ;:  weld
      "<button type=\"button\" data-archive-definition data-family=\""
      (escape family)
      "\" data-label=\""
      label
      "\">Archive</button>"
    ==
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
    "\""
    ?:(archived " data-definition-archived" "")
    "><span>"
    label
    " - "
    (escape (scot %tas (cell-term %content-type i.rows)))
    ?:(=(0 (cell-atom %mandatory i.rows)) " - mandatory" "")
    ?:(archived " - archived" "")
    "</span>"
    (definition-lifecycle-controls 'custom-field' label archived)
    "<select data-change-custom-type><option value=\"number\">Number</option><option value=\"text\">Text</option><option value=\"boolean\">Boolean</option></select><button type=\"button\" data-change-custom-field data-label=\""
    label
    "\">Change type</button></li>"
    (custom-definition-list t.rows)
  ==
::
::  Every definition of one family, active and archived alike. This list is the
::  ONE place an archived definition is shown to a person: it has left every
::  selector, so without a list that keeps showing it there is no way back.
++  definition-list
  |=  [family=@t rows=(list vector:ast)]
  ^-  tape
  ?~  rows
    ~
  =/  label  (escape (cell-text %label i.rows))
  =/  archived  =(0 (cell-atom %archived i.rows))
  ;:  weld
    "<li data-definition-entry data-definition-family=\""
    (escape family)
    "\" data-definition-label=\""
    label
    "\""
    ?:(archived " data-definition-archived" "")
    "><span>"
    label
    ?:(archived " - archived" "")
    "</span>"
    (definition-lifecycle-controls family label archived)
    "</li>"
    $(rows t.rows)
  ==
::
++  definition-panels
  |=  panels=(list [family=@t title=@t rows=(list vector:ast)])
  ^-  tape
  ?~  panels
    ~
  ;:  weld
    "<section class=\"definition-family\" data-definition-panel=\""
    (escape family.i.panels)
    "\"><h3>"
    (escape title.i.panels)
    "</h3><ul class=\"definition-list\">"
    ?:  ?=(~ rows.i.panels)
      "<li class=\"empty\">None yet.</li>"
    (definition-list family.i.panels rows.i.panels)
    "</ul></section>"
    $(panels t.panels)
  ==
::
++  settings-screen
  |=  $:  custom-definitions=(list vector:ast)
          panels=(list [family=@t title=@t rows=(list vector:ast)])
      ==
  ^-  tape
  ;:  weld
    "<section id=\"settings-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER CONFIGURATION</p><h1>SETTINGS</h1></header>"
    "<section data-settings-section=\"theme\"><h2>Theme</h2><p>Colors use the UA 571-C palette. Use the header toggle to switch glow on or off.</p><div class=\"theme-swatches\"><span>Background</span><span>Amber</span><span>Warning</span></div><div class=\"theme-glow-control\"><label for=\"glow-intensity\">Glow intensity<input id=\"glow-intensity\" data-glow-intensity type=\"range\" min=\"0\" max=\"100\" step=\"1\" value=\"32\"></label><output data-glow-intensity-output for=\"glow-intensity\">32%</output></div></section>"
    "<section data-settings-section=\"custom-fields\"><h2>Custom fields</h2><form id=\"custom-field-definition-form\"><label>Label<input name=\"label\" required></label><label>Content type<select name=\"contentType\"><option value=\"number\">Number</option><option value=\"text\">Text</option><option value=\"boolean\">Boolean</option></select></label><label class=\"check-option\"><input type=\"checkbox\" name=\"mandatory\"><span>Mandatory on Add Fill</span></label><button type=\"submit\">Create custom field</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form><ul id=\"custom-field-definitions\">"
    (custom-definition-list custom-definitions)
    "</ul></section>"
    "<section data-settings-section=\"definitions\"><h2>Definitions</h2><p>Rename corrects a label everywhere it renders, including on records already saved. Archive removes a definition from every selector and keeps every record that names it. Nothing is deleted, and an archived definition can be restored.</p>"
    (definition-panels panels)
    "<output id=\"definition-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output></section>"
    "<section data-settings-section=\"import\"><h2>Import</h2><p>Rover reads a Rover import JSON document. Run the converter first. Rover never learns the name of the app the records came from.</p><button type=\"button\" data-open-screen=\"import-screen\">Import records</button></section><section data-settings-section=\"export\"><h2>Export</h2><p>Download one Rover import file that contains your complete vehicle history.</p><a href=\"/apps/rover/export\" download data-rover-export-download>Download complete export</a></section><section class=\"settings-placeholder\"><h2>GRANTS - COMING LATER</h2></section></section>"
  ==
::
::  The import screen carries no server-rendered data. The browser reads the
::  document, checks it, splits it into batches, and posts one batch at a time,
::  because /apps/rover/import takes one document per POST and answers 409 while
::  a run is live. The split is the one tools/rover-import/upload.py makes.
++  import-screen
  ^-  tape
  ;:  weld
    "<section id=\"import-screen\" class=\"entry-screen app-screen\" hidden>"
    "<button type=\"button\" class=\"back-control\" data-open-screen=\"settings-screen\">&lsaquo; SETTINGS</button>"
    "<header><p class=\"eyebrow\">ROVER IMPORT</p><h2>Import records</h2></header>"
    "<form id=\"import-form\">"
    "<p class=\"field-note\">Rover checks the document in this browser and sends it in batches. A record that is already imported reports already-imported and writes nothing, so a stopped run recovers by uploading the same file again.</p>"
    "<label>Import document<input id=\"import-file\" name=\"document\" type=\"file\" accept=\".json,application/json\" required></label>"
    "<label>Records per batch<input id=\"import-batch-size\" name=\"batchSize\" inputmode=\"numeric\" autocomplete=\"off\" value=\"50\"></label>"
    "<div class=\"form-actions\"><button type=\"button\" id=\"import-validate\">Validate</button><button type=\"submit\" id=\"import-submit\">Start import</button></div>"
    "<div class=\"preview-row\"><span>Plan</span><output id=\"import-plan\">&mdash;</output><small>Validate reads the document and counts the batches. It sends nothing.</small></div>"
    "<div class=\"preview-row\"><span>Progress</span><output id=\"import-progress\" aria-live=\"polite\">&mdash;</output></div>"
    "<output id=\"import-outcome\" class=\"form-verdict\" data-import-outcome=\"\" aria-live=\"polite\"></output>"
    "<fieldset id=\"import-batch-reports\"><legend>Batch reports</legend><ol id=\"import-batch-list\"></ol></fieldset>"
    "<div class=\"preview-row\"><span>Aggregate</span><output id=\"import-aggregate\">&mdash;</output><small>The sum of every batch report in this run.</small></div>"
    "<button type=\"button\" id=\"import-refresh\" hidden>Refresh the log</button>"
    "</form></section>"
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
++  def-economy
  |=  $:  vehicle-id=@
          purchases=(list vector:ast)
          odometers=(list vector:ast)
          ownership=(map @ (list ownership-interval))
      ==
  ^-  [available=? display=@t reason=@t]
  =/  vehicle-purchases=(list vector:ast)
    (order-vectors:act %observed-start %.y (rows-for vehicle-id purchases))
  ?:  (lth (lent vehicle-purchases) 2)
    [%.n 'Unavailable' 'Two consecutive DEF purchases are required']
  =/  close=vector:ast  (snag 0 vehicle-purchases)
  =/  prior=vector:ast  (snag 1 vehicle-purchases)
  ::  M7 T5, ruling 12. Consumable economy is an interval derivation, so it is
  ::  bounded the same way fuel economy is.
  =/  spans=(list ownership-interval)  (~(gut by ownership) vehicle-id ~)
  ?:  %:  ownership-gap
          spans
          `@da`(cell-atom %observed-start prior)
          `@da`(cell-atom %observed-start close)
      ==
    [%.n 'Unavailable' (economy-break-text %ownership-gap)]
  =/  close-odos=(list vector:ast)
    (rows-by %consumable-acquisition-id (cell-atom %consumable-acquisition-id close) odometers)
  ?~  close-odos
    [%.n 'Unavailable' 'Latest DEF purchase has no odometer reading']
  =/  prior-odos=(list vector:ast)
    (rows-by %consumable-acquisition-id (cell-atom %consumable-acquisition-id prior) odometers)
  ?~  prior-odos
    [%.n 'Unavailable' 'Previous DEF purchase has no odometer reading']
  =/  close-odo  i.close-odos
  =/  prior-odo  i.prior-odos
  =/  distance-unit  (cell-term %unit close-odo)
  ?.  =(distance-unit (cell-term %unit prior-odo))
    [%.n 'Unavailable' 'DEF interval odometer units do not match']
  =/  prior-places  (cell-atom %decimal-places prior-odo)
  =/  close-places  (cell-atom %decimal-places close-odo)
  ?:  ?|  (gth prior-places 3)
          (gth close-places 3)
      ==
    [%.n 'Unavailable' 'DEF interval odometer precision is unsupported']
  =/  prior-milli
    (mul (cell-atom %value-digits prior-odo) (pow-ten:render (sub 3 prior-places)))
  =/  close-milli
    (mul (cell-atom %value-digits close-odo) (pow-ten:render (sub 3 close-places)))
  ?.  (gth close-milli prior-milli)
    [%.n 'Unavailable' 'DEF interval odometer did not advance']
  =/  quantity  (cell-atom %quantity-milli close)
  ?:  =(0 quantity)
    [%.n 'Unavailable' 'Latest DEF purchase quantity is zero']
  =/  quantity-unit  (cell-term %quantity-unit close)
  =/  unit=@t
    ?:  ?&  =(%mi distance-unit)
            =(%gal quantity-unit)
        ==
      'mi/gal DEF'
    ?:  ?&  =(%km distance-unit)
            =(%litre quantity-unit)
        ==
      'km/L DEF'
    ''
  ?:  =('' unit)
    [%.n 'Unavailable' 'DEF interval units are not a supported pair']
  =/  distance-milli  (sub close-milli prior-milli)
  =/  economy-milli
    (div (add (mul distance-milli 1.000) (div quantity 2)) quantity)
  =/  display=@t
    %-  crip
    ;:  weld
      (trip (format-scaled:render economy-milli 3 %.n))
      " "
      (trip unit)
    ==
  [%.y display '']
::
++  def-economy-stat-rows
  |=  $:  vehicles=(list vector:ast)
          purchases=(list vector:ast)
          odometers=(list vector:ast)
          ownership=(map @ (list ownership-interval))
      ==
  ^-  tape
  ?~  vehicles
    ~
  =/  rest  $(vehicles t.vehicles)
  =/  id  (cell-atom %vehicle-id i.vehicles)
  ?:  ?=(~ (rows-for id purchases))
    rest
  =/  label  (escape (cell-text %label i.vehicles))
  =/  status=[available=? display=@t reason=@t]
    (def-economy id purchases odometers ownership)
  ;:  weld
    "<tr "
    "data-statistics-vehicle=\""
    label
    "\" "
    ?:  available.status
      ;:  weld
        "data-def-economy-vehicle=\""
        label
        "\" data-def-economy=\""
        (escape display.status)
        "\""
      ==
    ;:  weld
      "data-def-economy-unavailable=\""
      label
      "\""
    ==
    "><td>"
    (escape display.status)
    "</td><td>"
    ?:(available.status "Consecutive odometer-linked DEF purchases." (escape reason.status))
    "</td></tr>"
    rest
  ==
::
++  economy-values
  |=  $:  vehicle-id=@
          fills=(list vector:ast)
          derivations=(map @ derived-fill)
      ==
  ^-  (list [milli=@ud unit=@t])
  ?~  fills
    ~
  =/  rest  $(fills t.fills)
  ?.  =(vehicle-id (cell-atom %vehicle-id i.fills))
    rest
  =/  derived  (~(get by derivations) (cell-atom %acquisition-id i.fills))
  =/  value=(unit economy-proof)
    ?~  derived
      ~
    economy.u.derived
  ?~  value
    rest
  [u.value rest]
::
++  sum-economies
  |=  rows=(list [milli=@ud unit=@t])
  ^-  @ud
  ?~(rows 0 (add milli.i.rows $(rows t.rows)))
::
++  best-economy
  |=  rows=(list [milli=@ud unit=@t])
  ^-  @ud
  ?~  rows
    0
  ?~  t.rows
    milli.i.rows
  (max milli.i.rows $(rows t.rows))
::
++  worst-economy
  |=  rows=(list [milli=@ud unit=@t])
  ^-  @ud
  ?~  rows
    0
  ?~  t.rows
    milli.i.rows
  (min milli.i.rows $(rows t.rows))
::
++  economy-display
  |=  [milli=@ud unit=@t]
  ^-  tape
  ;:  weld
    (trip (format-scaled:render milli 3 %.n))
    " "
    (trip unit)
  ==
::
++  economy-break-text
  |=  reason=@tas
  ^-  @t
  ?+  reason
    'An economy-chain break makes this interval unavailable.'
    %missed-fill  'A missed fill was recorded, so this economy interval is unavailable.'
    %excluded     'The owner excluded this fill from economy calculations.'
    %owner-marked  'The owner marked this fill as an economy-chain break.'
    ::  M7 T5. The one derived reason. Rover reads the sale and the later
    ::  purchase from the database and honours them without being told.
    %ownership-gap
  'The vehicle was not owned for part of this interval, so it is unavailable.'
  ==
::
::  M7 T6. Calendar arithmetic, because a reminder interval is a calendar step.
::  Three months is not a fixed count of seconds, and a column holding one
::  would drift by three days every year.
++  month-days
  |=  [year=@ud month=@ud]
  ^-  @ud
  ?:  =(2 month)
    ?:  =(0 (mod year 400))
      29
    ?:  =(0 (mod year 100))
      28
    ?:(=(0 (mod year 4)) 29 28)
  ?:  ?|  =(4 month)
          =(6 month)
          =(9 month)
          =(11 month)
      ==
    30
  31
::
::  The last day of a short month absorbs a longer one. The 31st plus one month
::  is the 28th of February, not the 3rd of March: a service due at the end of
::  January is due at the end of February, and rolling over would move it into
::  the month after the one the owner meant.
++  add-months
  |=  [when=@da count=@ud]
  ^-  @da
  =/  parts  (yore when)
  =/  ordinal  (add (dec m.parts) count)
  =/  years  (add y.parts (div ordinal 12))
  =/  month  +((mod ordinal 12))
  =/  day  (min d.t.parts (month-days years month))
  %-  year
  [[a.parts years] month [day h.t.parts m.t.parts s.t.parts f.t.parts]]
::
++  add-time-interval
  |=  [when=@da count=@ud interval-unit=@tas]
  ^-  @da
  ?:  =(%day interval-unit)
    (add when (mul count ~d1))
  ?:  =(%week interval-unit)
    (add when (mul count ~d7))
  ?:  =(%year interval-unit)
    (add-months when (mul count 12))
  (add-months when count)
::
::  The plural a person expects. "Every 1 month", "every 3 months".
++  interval-unit-text
  |=  [count=@ud interval-unit=@tas]
  ^-  tape
  =/  singular=tape  (trip (scot %tas interval-unit))
  ?:(=(1 count) singular (weld singular "s"))
::
++  format-day
  |=  when=@da
  ^-  tape
  (scag 10 (trip (format-da:render when)))
::
::  Exact thousandths in, a figure a person reads out. A whole number of miles
::  keeps no decimal point, and a fractional one keeps only the digits it has.
++  format-distance-milli
  |=  [milli=@ud distance-unit=@tas]
  ^-  tape
  =/  scaled=tape  (trip (format-scaled:render milli 3 %.y))
  =/  trimmed=tape
    %-  flop
    |-  ^-  tape
    =/  reversed  (flop scaled)
    ?~  reversed
      ~
    ?:  =('0' i.reversed)
      $(scaled (flop t.reversed))
    ?:  =('.' i.reversed)
      t.reversed
    reversed
  ;:  weld
    ?~(trimmed "0" trimmed)
    " "
    (trip (scot %tas distance-unit))
  ==
::
::  One odometer figure in exact thousandths of the unit the reminder uses. A
::  reading Rover cannot convert or cannot hold exactly answers with nothing,
::  and the caller renders that as unavailable rather than as a guess.
++  reading-in-milli
  |=  [digits=@ud places=@ud source=@tas target=@tas]
  ^-  (unit @ud)
  ?:  (gth places 3)
    ~
  ?.  ?|  =(%mi source)
          =(%km source)
      ==
    ~
  ?.  ?|  =(%mi target)
          =(%km target)
      ==
    ~
  =/  converted  (convert-distance:render digits places source target)
  `(mul converted-digits.converted (pow-ten:render (sub 3 converted-places.converted)))
::
::  Every service already recorded that names this reminder's subtype, newest
::  first. A service event and nothing else: the subtype link keys to the event
::  parent, so an expense could carry one, but paying for a part is not the
::  same as having the work done.
++  reminder-completions
  |=  $:  vehicle-id=@
          subtype-id=@
          events=(list vector:ast)
          services=(list vector:ast)
          links=(list vector:ast)
          odometers=(list vector:ast)
      ==
  ^-  (list reminder-completion)
  =/  service-events=(set @)
    (~(gas in *(set @)) `(list @)`(row-ids %event-id services))
  =/  named=(set @)
    %-  ~(gas in *(set @))
    ^-  (list @)
    %+  turn  (rows-by %service-subtype-id subtype-id links)
    |=(row=vector:ast (cell-atom %event-id row))
  =/  matched=(list vector:ast)
    %+  skim  (rows-for vehicle-id events)
    |=  row=vector:ast
    =/  event  (cell-atom %event-id row)
    ?&  (~(has in service-events) event)
        (~(has in named) event)
    ==
  %+  turn  (order-vectors:act %observed-start %.y matched)
  |=  row=vector:ast
  ^-  reminder-completion
  =/  found  (rows-by %event-id (cell-atom %event-id row) odometers)
  :-  `@da`(cell-atom %observed-start row)
  ?~(found ~ `i.found)
::
::  The time half. The stored due point is what the owner entered; recording
::  the service the reminder names moves it forward by one interval. It never
::  moves backwards, so a service recorded before the point the owner entered
::  leaves that point standing.
++  reminder-time-verdict
  |=  $:  row=vector:ast
          completions=(list reminder-completion)
          now=@da
      ==
  ^-  reminder-verdict
  =/  count  (cell-atom %interval-count row)
  =/  interval-unit  (cell-term %interval-unit row)
  =/  anchor=@da  `@da`(cell-atom %due-at row)
  =/  effective=@da
    ?~  completions
      anchor
    =/  advanced  (add-time-interval date.i.completions count interval-unit)
    ?:((gth advanced anchor) advanced anchor)
  =/  every=tape
    ;:  weld
      "Every "
      (scow %ud count)
      " "
      (interval-unit-text count interval-unit)
      ". "
    ==
  ?:  (gte now effective)
    :+  %due
      'Due now'
    (crip ;:(weld "Due on " (format-day effective) "."))
  :+  %not-due
    (crip (weld "Due " (format-day effective)))
  (crip ;:(weld every "Next due on " (format-day effective) "."))
::
::  The distance half. Three things can make it unanswerable, and each says so
::  in a sentence: the vehicle has no reading, the readings overlap, or the
::  countdown crosses a gap in ownership.
::
::  Ruling 12 is the last of the three. Progress toward a distance due point is
::  distance driven, and distance driven across a gap includes miles the owner
::  did not drive. The countdown starts at the due point less one interval, and
::  the window runs from the reading at or below that point to the reading now.
::  A window that leaves one ownership interval and returns is unavailable, the
::  way a fuel economy interval across the same gap is.
++  reminder-distance-verdict
  |=  $:  row=vector:ast
          completions=(list reminder-completion)
          odometers=(list vector:ast)
          spans=(list ownership-interval)
      ==
  ^-  reminder-verdict
  =/  distance-unit  (cell-term %distance-unit row)
  =/  interval=(unit @ud)
    %:  reading-in-milli
        (cell-atom %interval-digits row)
        (cell-atom %interval-decimals row)
        distance-unit
        distance-unit
    ==
  =/  anchor=(unit @ud)
    %:  reading-in-milli
        (cell-atom %due-digits row)
        (cell-atom %due-decimals row)
        distance-unit
        distance-unit
    ==
  ?:  ?|(?=(~ interval) ?=(~ anchor))
    :+  %unavailable
      'Unavailable'
    'This reminder holds a distance Rover cannot hold exactly, so it is unavailable.'
  =/  found  (current-odometer-reading odometers)
  ?:  ?=(%| -.found)
    :+  %unavailable
      'Unavailable'
    ?:  =(%no-readings p.found)
      'This vehicle has no odometer reading, so Rover cannot tell whether this is due.'
    'The latest odometer observations of this vehicle overlap, so Rover cannot tell whether this is due.'
  =/  current=(unit @ud)
    (reading-in-milli digits.p.found places.p.found reading-unit.p.found distance-unit)
  ?~  current
    :+  %unavailable
      'Unavailable'
    'The odometer of this vehicle is not in a unit Rover can compare against this reminder.'
  ::  The newest recorded service that carries a reading. One without a reading
  ::  moves no distance due point, because it says nothing about the odometer.
  =/  completion=(unit @ud)
    |-  ^-  (unit @ud)
    ?~  completions
      ~
    ?~  odometer.i.completions
      $(completions t.completions)
    =/  measured
      %:  reading-in-milli
          (cell-atom %value-digits u.odometer.i.completions)
          (cell-atom %decimal-places u.odometer.i.completions)
          (cell-term %unit u.odometer.i.completions)
          distance-unit
      ==
    ?~  measured
      $(completions t.completions)
    measured
  =/  effective=@ud
    ?~  completion
      u.anchor
    =/  advanced  (add u.completion u.interval)
    ?:((gth advanced u.anchor) advanced u.anchor)
  =/  countdown-start=@ud
    ?:((gth effective u.interval) (sub effective u.interval) 0)
  =/  started=@da
    (countdown-start-date odometers distance-unit countdown-start date.p.found)
  ?:  (ownership-gap spans started date.p.found)
    [%unavailable 'Unavailable' (economy-break-text %ownership-gap)]
  =/  every=tape
    ;:  weld
      "Every "
      (format-distance-milli u.interval distance-unit)
      ". "
    ==
  ?:  (gte u.current effective)
    :+  %due
      'Due now'
    %-  crip
    ;:  weld
      "Due at "
      (format-distance-milli effective distance-unit)
      ". The odometer reads "
      (format-distance-milli u.current distance-unit)
      "."
    ==
  :+  %not-due
    (crip (weld "Due in " (format-distance-milli (sub effective u.current) distance-unit)))
  %-  crip
  ;:  weld
    every
    "Next due at "
    (format-distance-milli effective distance-unit)
    "."
  ==
::
::  When the countdown started, in time. The reading at or below the countdown
::  point is where the clock of this reminder began; if the record starts after
::  that point, the earliest reading is as far back as Rover can honestly go.
++  countdown-start-date
  |=  $:  odometers=(list vector:ast)
          distance-unit=@tas
          countdown-start=@ud
          fallback=@da
      ==
  ^-  @da
  =/  ordered  (order-vectors:act %observed-start %.n odometers)
  ?~  ordered
    fallback
  =/  earliest=@da  `@da`(cell-atom %observed-start i.ordered)
  =/  rows=(list vector:ast)  ordered
  =/  found=(unit @da)
    |-  ^-  (unit @da)
    ?~  rows
      ~
    =/  rest  $(rows t.rows)
    =/  measured
      %:  reading-in-milli
          (cell-atom %value-digits i.rows)
          (cell-atom %decimal-places i.rows)
          (cell-term %unit i.rows)
          distance-unit
      ==
    ?~  measured
      rest
    ?.  (lte u.measured countdown-start)
      rest
    =/  when=@da  `@da`(cell-atom %observed-start i.rows)
    ?~  rest
      `when
    ?:((gth when u.rest) `when rest)
  ?~(found earliest u.found)
::
::  Both intervals set means due when EITHER fires. That is how a maintenance
::  schedule is written and how a person reads one: every six months or five
::  thousand miles, whichever comes first.
::
::  When neither has fired and one of them cannot answer, the reminder is
::  unavailable rather than not due. Half an answer is not an answer.
++  reminder-verdict-of
  |=  [time=(unit reminder-verdict) distance=(unit reminder-verdict)]
  ^-  reminder-verdict
  ?~  time
    ?~  distance
      [%unavailable 'Unavailable' 'This reminder carries no interval.']
    u.distance
  ?~  distance
    u.time
  =/  both=(list reminder-verdict)  ~[u.time u.distance]
  =/  due=(list reminder-verdict)
    (skim both |=(one=reminder-verdict =(%due state.one)))
  ?^  due
    :+  %due
      'Due now'
    (crip (join-details due))
  =/  refused=(list reminder-verdict)
    (skim both |=(one=reminder-verdict =(%unavailable state.one)))
  ?^  refused
    [%unavailable 'Unavailable' (crip (join-details refused))]
  :+  %not-due
    (crip ;:(weld (trip headline.u.distance) " or " (slag 4 (trip headline.u.time))))
  (crip (join-details ~[u.distance u.time]))
::
++  join-details
  |=  parts=(list reminder-verdict)
  ^-  tape
  ?~  parts
    ~
  =/  rest  $(parts t.parts)
  ?~  rest
    (trip detail.i.parts)
  ;:(weld (trip detail.i.parts) " " rest)
::
::  One reminder card per reminder of this vehicle. The subtype label is the
::  name of the thing that is due; the reminder ID never leaves the server.
++  reminder-cards
  |=  $:  vehicle-id=@
          family=reminder-rows
          subtypes=(list vector:ast)
          odometers=(list vector:ast)
          events=(list vector:ast)
          services=(list vector:ast)
          event-odometers=(list vector:ast)
          spans=(list ownership-interval)
          now=@da
      ==
  ^-  tape
  =/  vehicle-odometers  (rows-for vehicle-id odometers)
  =/  mine
    %:  order-vectors:act
        %recorded-at
        %.n
        (rows-by %vehicle-id vehicle-id reminders.family)
    ==
  |-  ^-  tape
  ?~  mine
    ~
  =/  rest=tape  $(mine t.mine)
  =/  row  i.mine
  =/  reminder-id  (cell-atom %reminder-id row)
  =/  subtype-id  (cell-atom %service-subtype-id row)
  =/  named  (rows-by %service-subtype-id subtype-id subtypes)
  ?~  named
    rest
  =/  label=@t  (cell-text %label i.named)
  =/  completions
    %:  reminder-completions
        vehicle-id
        subtype-id
        events
        services
        event-subtypes.family
        event-odometers
    ==
  =/  time-rows  (rows-by %reminder-id reminder-id times.family)
  =/  distance-rows  (rows-by %reminder-id reminder-id distances.family)
  =/  time=(unit reminder-verdict)
    ?~  time-rows
      ~
    `(reminder-time-verdict i.time-rows completions now)
  =/  distance=(unit reminder-verdict)
    ?~  distance-rows
      ~
    :-  ~
    %:  reminder-distance-verdict
        i.distance-rows
        completions
        vehicle-odometers
        spans
    ==
  =/  verdict  (reminder-verdict-of time distance)
  ;:  weld
    "<article class=\"reminder\" data-reminder=\""
    (escape label)
    "\" data-reminder-state=\""
    (trip (scot %tas state.verdict))
    "\" data-reminder-due=\""
    (escape headline.verdict)
    "\" data-reminder-detail=\""
    (escape detail.verdict)
    "\"><span>"
    (escape label)
    "</span><strong>"
    (escape headline.verdict)
    "</strong><small>"
    (escape detail.verdict)
    "</small></article>"
    rest
  ==
::
++  reminder-section
  |=  cards=tape
  ^-  tape
  ;:  weld
    "<section class=\"hub-reminders\" aria-label=\"Reminders\"><h2>REMINDERS</h2>"
    ?~  cards
      "<p class=\"empty\">No reminder is recorded for this vehicle.</p>"
    cards
    "</section>"
  ==
::
++  main-hub
  |=  $:  app-default=(list vector:ast)
          definition-rows=(list vector:ast)
          odometers=(list vector:ast)
          tank-sizes=(list vector:ast)
          refill-reserves=(list vector:ast)
          fills=(list vector:ast)
          fill-odometers=(list vector:ast)
          economy-breaks=(list vector:ast)
          def-purchases=(list vector:ast)
          def-odometers=(list vector:ast)
          derivations=(map @ derived-fill)
          ownership=(map @ (list ownership-interval))
          ::  M7 T6. The reminder cards arrive already rendered. What is due is
          ::  derived from the same rows this page already reads, so the hub
          ::  takes a tape rather than eight more row lists.
          reminder-html=tape
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
  =/  hub-stat-scope=tape
    ?~  app-default
      " data-hub-statistics-no-default"
    ;:  weld
      " data-hub-statistics-vehicle=\""
      (escape (cell-text %label i.app-default))
      "\""
    ==
  =/  sources=(list vector:ast)
    ?~  default-id
      ~
    (rows-for u.default-id definition-rows)
  =/  has-fill  (has-term %physical-kind %reservoir sources)
  =/  has-charge  (has-term %physical-kind %electricity sources)
  =/  ordered-fills  (order-vectors:act %observed-start %.y fills)
  =/  economies=(list [milli=@ud unit=@t])
    ?~  default-id
      ~
    (economy-values u.default-id ordered-fills derivations)
  =/  rolling-economies  (scag 5 economies)
  =/  rolling-count  (lent rolling-economies)
  =/  rolling-mean
    ?~  rolling-economies
      0
    (div (add (sum-economies rolling-economies) (div rolling-count 2)) rolling-count)
  =/  reserve=(unit @ud)
    ?~  default-id
      ~
    =/  rows  (rows-for u.default-id refill-reserves)
    ?.  =(1 (lent rows))
      ~
    `(cell-atom %reserve-percent (snag 0 rows))
  =/  reserve-valid
    ?~(reserve %.y (lth u.reserve 100))
  =/  last-economy=tape
    ?~  economies
      "Unavailable"
    (economy-display milli.i.economies unit.i.economies)
  =/  lifetime-economy=tape
    ?~  economies
      "Unavailable"
    =/  mean  (div (add (sum-economies economies) (div (lent economies) 2)) (lent economies))
    (economy-display mean unit.i.economies)
  =/  best=tape
    ?~  economies
      "Unavailable"
    (economy-display (best-economy economies) unit.i.economies)
  =/  worst=tape
    ?~  economies
      "Unavailable"
    (economy-display (worst-economy economies) unit.i.economies)
  =/  odometer=tape
    ?~  default-id
      "Unavailable"
    (current-odometer (rows-for u.default-id odometers) ~)
  =/  tank-reason=tape
    ?~  default-id
      "No default vehicle is set."
    ?:  ?=(~ (rows-for u.default-id tank-sizes))
      "Tank size is not recorded for this vehicle."
    ?.  reserve-valid
      "Refill reserve must be between 0 and 99%."
    ?~  rolling-economies
      "An eligible economy interval is required."
    ;:  weld
      "Mean of the last "
      (scow %ud rolling-count)
      " eligible interval"
      ?:(=(1 rolling-count) "" "s")
      ?~  reserve
        ", full tank."
      ;:  weld
        ", "
        (scow %ud u.reserve)
        "% reserve."
      ==
    ==
  =/  next-distance=tape
    ?:  ?|  ?=(~ default-id)
            ?=(~ economies)
            =(%.n reserve-valid)
        ==
      "Unavailable"
    =/  tanks  (rows-for u.default-id tank-sizes)
    ?.  =(1 (lent tanks))
      "Unavailable"
    =/  tank-row  (snag 0 tanks)
    =/  places  (cell-atom %decimals tank-row)
    ?:  (gth places 3)
      "Unavailable"
    =/  tank-milli
      (mul (cell-atom %digits tank-row) (pow-ten:render (sub 3 places)))
    =/  usable-milli
      ?~  reserve
        tank-milli
      (div (add (mul tank-milli (sub 100 u.reserve)) 50) 100)
    =/  distance-milli
      (div (add (mul rolling-mean usable-milli) 500) 1.000)
    =/  distance-whole
      (div (add distance-milli 500) 1.000)
    ;:  weld
      (scow %ud distance-whole)
      ?:(=('mpg' unit.i.economies) " mi" " km")
    ==
  =/  def-status=[available=? display=@t reason=@t]
    ?~  default-id
      [%.n 'Unavailable' 'No default vehicle is set']
    (def-economy u.default-id def-purchases def-odometers ownership)
  ;:  weld
    default-marker
    "<section id=\"main-hub\" class=\"app-screen\">"
    "<header class=\"hub-header\"><p class=\"eyebrow\">ROVER VEHICLE LOG</p><h1>MAIN</h1><p>"
    default-label
    "</p></header><section class=\"hub-primary\">"
    ?:(has-fill "<button type=\"button\" data-open-screen=\"add-fill\">Add Fill</button>" "")
    ?:(has-charge "<button type=\"button\" data-open-screen=\"add-charge\">Add Charge</button>" "")
    "<button type=\"button\" data-open-screen=\"add-consumable\">Add Consumable</button>"
    "<button type=\"button\" data-open-screen=\"add-event\">Add Event</button>"
    ?:  ?|(has-fill has-charge)
      ""
    "<button type=\"button\" data-open-screen=\"vehicles-screen\">Configure a vehicle</button>"
    "</section>"
    "<nav class=\"hub-actions\" aria-label=\"Main actions\">"
    "<button type=\"button\" data-open-screen=\"add-odometer\">Add Odometer Entry</button>"
    "<button type=\"button\" data-open-screen=\"add-reminder\">Add Reminder</button>"
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
    "<article"
    hub-stat-scope
    "><span>ECONOMY - LAST FILL</span><strong>"
    last-economy
    "</strong><small>"
    ?:(?=(~ economies) "An eligible odometer-linked full-fill interval is required." "Latest eligible full-fill interval.")
    "</small></article>"
    "<article"
    hub-stat-scope
    "><span>ECONOMY - LIFETIME</span><strong>"
    lifetime-economy
    "</strong><small>"
    ?:(?=(~ economies) "No eligible lifetime interval is recorded." "Mean of eligible full-fill intervals.")
    "</small></article>"
    "<article"
    hub-stat-scope
    "><span>ESTIMATED DISTANCE TO NEXT FILL FROM LAST FILL</span><strong>"
    next-distance
    "</strong><small>"
    tank-reason
    "</small></article>"
    "<article"
    hub-stat-scope
    "><span>BEST ECONOMY</span><strong>"
    best
    "</strong><small>"
    ?:(?=(~ economies) "No eligible economy intervals are recorded." "Best eligible full-fill interval.")
    "</small></article>"
    "<article"
    hub-stat-scope
    "><span>WORST ECONOMY</span><strong>"
    worst
    "</strong><small>"
    ?:(?=(~ economies) "No eligible economy intervals are recorded." "Worst eligible full-fill interval.")
    "</small></article>"
    "<article><span>DEF ECONOMY - LAST INTERVAL</span><strong>"
    (escape display.def-status)
    "</strong><small>"
    ?:(available.def-status "Consecutive odometer-linked DEF purchases." (escape reason.def-status))
    "</small></article>"
    "</section>"
    (reminder-section reminder-html)
    "</section>"
  ==
::
++  entry-screens
  |=  $:  vehicles=(list vector:ast)
          odometers=(list vector:ast)
          definitions=(list vector:ast)
          stations=(list vector:ast)
          additives=(list vector:ast)
          subtypes=(list vector:ast)
          default-subtypes=(list vector:ast)
          driving-modes=(list vector:ast)
          tags=(list vector:ast)
          custom-definitions=(list vector:ast)
          payment-methods=(list vector:ast)
          consumables=(list vector:ast)
          localities=(list vector:ast)
          service-subtypes=(list vector:ast)
          disposal-kinds=(list vector:ast)
      ==
  ^-  tape
  =/  vehicle-html  (vehicle-options vehicles)
  =/  service-subtype-html  (service-subtype-options service-subtypes)
  =/  reminder-subtype-html  (service-subtype-select-options service-subtypes)
  =/  disposal-kind-html  (disposal-kind-options disposal-kinds)
  =/  definition-html  (definition-options definitions vehicles)
  =/  station-html  (station-options stations localities)
  =/  additive-html  (additive-options additives)
  =/  subtype-html  (subtype-options subtypes)
  =/  default-subtype-html  (default-subtype-data default-subtypes)
  =/  driving-mode-html  (driving-mode-options driving-modes)
  =/  tag-html  (tag-options tags)
  =/  custom-field-html  (custom-field-controls custom-definitions)
  =/  payment-html  (payment-options payment-methods)
  =/  consumable-html  (consumable-options consumables)
  ;:  weld
    (odometer-series-data odometers vehicles)
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
    "<div class=\"read-only-row\" data-fill-field=\"previous-odometer\"><span>Previous odometer reading</span><output id=\"fill-previous-odometer\">Unavailable - this vehicle has no earlier odometer observation</output></div>"
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
    "<label>Charging subtype<select name=\"subtype\" required>"
    subtype-html
    "</select></label>"
    "<div class=\"form-grid\"><label>Started<input name=\"start\" type=\"datetime-local\" required></label><label>Ended<input name=\"end\" type=\"datetime-local\" required></label></div>"
    "<input name=\"zone\" type=\"hidden\">"
    "<label>Energy delivered <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"energyDelivered\" inputmode=\"decimal\" placeholder=\"42.75\"><output>kWh</output></div></label>"
    "<label>Measurement source<select name=\"energySource\"><option value=\"charger-reported\">Charger reported</option><option value=\"wall-measured\">Wall measured</option><option value=\"vehicle-reported\">Vehicle reported</option><option value=\"estimate\">Estimate</option></select></label>"
    "<div class=\"form-grid\"><label>Start battery <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"startBattery\" inputmode=\"decimal\" placeholder=\"20\"><output>%</output></div></label><label>End battery <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"endBattery\" inputmode=\"decimal\" placeholder=\"80\"><output>%</output></div></label></div>"
    "<label>Mileage <span class=\"optional\">optional</span><input name=\"mileage\" inputmode=\"decimal\" placeholder=\"10020.0\"></label>"
    "<label>Mileage unit<select name=\"mileageUnit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label>"
    "<label>Cost state<select name=\"costState\"><option value=\"unknown\">Unknown</option><option value=\"free\">Free</option><option value=\"itemized\">Itemized</option><option value=\"receipt-total-only\">Receipt total only</option></select></label>"
    "<label>Currency<select name=\"currency\"><option value=\"usd\">USD</option><option value=\"eur\">EUR</option></select></label>"
    "<fieldset id=\"charge-itemized\" hidden><legend>Cost components</legend>"
    "<p class=\"field-note\">Each line keeps its own quantity, rate, and source-reported amount. Rover derives the total.</p>"
    "<div id=\"charge-component-rows\"></div>"
    "<template id=\"charge-component-template\"><div class=\"cost-component-row\" data-cost-component-row>"
    "<label>Kind<select name=\"componentKind\">"
    "<option value=\"energy\">Energy</option>"
    "<option value=\"time\">Charging time</option>"
    "<option value=\"session\">Session</option>"
    "<option value=\"idle\">Idle</option>"
    "<option value=\"tax\">Tax</option>"
    "<option value=\"discount\">Discount</option>"
    "</select></label>"
    "<label>Quantity<input name=\"componentQuantity\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"45.678\"></label>"
    "<label>Unit<select name=\"componentUnit\">"
    "<option value=\"kwh\">kWh</option>"
    "<option value=\"minute\">minute</option>"
    "<option value=\"session\">session</option>"
    "</select></label>"
    "<label>Rate<input name=\"componentRate\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"0.250\"></label>"
    "<label>Amount<input name=\"componentAmount\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"11.420\"></label>"
    "<button type=\"button\" data-remove-cost-component>Remove</button>"
    "</div></template>"
    "<button type=\"button\" data-add-cost-component>Add component</button>"
    "<div class=\"preview-row derived-preview\"><span>Derived total</span><output id=\"charge-itemized-total\" aria-live=\"polite\">&mdash;</output><small>Charges less discounts, in exact thousandths</small></div>"
    "</fieldset>"
    "<fieldset id=\"charge-receipt-total\" hidden><legend>Receipt total</legend>"
    "<label>Source-reported total<input name=\"sourceTotal\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"22.34\"></label>"
    "<p class=\"field-note\">Rover keeps this total as the source reported it and derives nothing from it.</p>"
    "</fieldset>"
    "<div class=\"form-actions\"><button type=\"submit\">Save charge</button><button type=\"button\" data-close-screen>Cancel</button></div>"
    "<output id=\"charge-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output>"
    "</form></section>"
    "<section id=\"add-consumable\" class=\"entry-screen app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header><p class=\"eyebrow\">NEW PURCHASE</p><h2>Add consumable</h2></header><form id=\"consumable-form\"><label>Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label><label>Consumable<select name=\"consumable\" required>"
    consumable-html
    "</select></label><label>Quantity<input name=\"quantity\" inputmode=\"decimal\" required></label><label>Unit price<input name=\"price\" inputmode=\"decimal\" required></label><input name=\"profile\" type=\"hidden\" value=\"us-usd-gal\"><label>Settlement<select name=\"settlement\"><option value=\"standard\">Standard</option><option value=\"cash\">Cash</option></select></label><label>Odometer <span class=\"optional\">optional</span><input name=\"mileage\" inputmode=\"decimal\"></label><label>Odometer unit<select name=\"mileageUnit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label><label>Observed<input name=\"observed\" type=\"datetime-local\" required></label><input name=\"zone\" type=\"hidden\"><div class=\"form-actions\"><button type=\"submit\">Save purchase</button><button type=\"button\" data-close-screen>Cancel</button></div><output id=\"consumable-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output></form></section>"
    ::  M7 T1. One form for all three kinds. Total, odometer, station, tags,
    ::  payment method, and note are every one optional: a blank field writes
    ::  no row, which is how a parking fee with no station and a note with no
    ::  cost stay distinct from a zero.
    "<section id=\"add-event\" class=\"entry-screen app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header><p class=\"eyebrow\">NEW EVENT</p><h2>Add event</h2></header><form id=\"event-form\"><label>Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label><label>Kind<select name=\"kind\" required><option value=\"service\">Service</option><option value=\"expense\">Expense</option><option value=\"note\">Note</option><option value=\"acquisition\">Purchase</option><option value=\"disposal\">Disposal</option></select></label><label>Total <span class=\"optional\">optional</span><input name=\"total\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"$412.75\"></label><input name=\"currency\" type=\"hidden\" value=\"usd\"><label>Odometer <span class=\"optional\">optional</span><input name=\"mileage\" inputmode=\"decimal\" autocomplete=\"off\"></label><label>Odometer unit<select name=\"mileageUnit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label><fieldset class=\"station-field\"><legend>Station <span class=\"optional\">optional</span></legend><select id=\"event-station\" name=\"station\"><option value=\"none\">No station recorded</option>"
    station-html
    "<option value=\"new\">Add new station&hellip;</option></select><div id=\"event-new-station\" hidden><label>Station label<input name=\"newStationLabel\" autocomplete=\"off\"></label><label>Place label<input name=\"newPlaceLabel\" autocomplete=\"off\"></label><label>Station kind<select name=\"newStationKind\"><option value=\"private\">Private</option><option value=\"fuel\">Fuel</option><option value=\"charging\">Charging</option><option value=\"mixed\">Mixed</option></select></label></div></fieldset>"
    ::  M7 T2. The subtype picker. The catalog is long, so it opens behind a
    ::  toggle the way the fill tag picker does. It shows for a service event
    ::  and hides for the other two kinds - a UI affordance, not a schema
    ::  constraint, because the link keys to the event parent.
    "<fieldset id=\"event-subtypes\" hidden><legend>Service subtypes <span class=\"optional\">optional</span></legend><button type=\"button\" id=\"event-subtypes-toggle\" aria-expanded=\"false\">Choose subtypes</button><div id=\"event-subtypes-picker\" hidden><div class=\"check-grid\">"
    service-subtype-html
    "</div></div></fieldset>"
    ::  M7 T4. How the vehicle left. It shows for a disposal and hides for
    ::  every other kind, the way the subtype picker does. Unlike a subtype it
    ::  is mandatory where it shows: a sale, a write-off, and a theft are
    ::  different facts, and the amount alone cannot tell them apart.
    "<label id=\"event-disposal-kind\" hidden>Disposal kind<select name=\"disposalKind\"><option value=\"\">Choose one</option>"
    disposal-kind-html
    "</select></label>"
    "<fieldset id=\"event-tags\"><legend>Tags <span class=\"optional\">optional</span></legend><div class=\"check-grid\">"
    tag-html
    "</div><label>New tag<input name=\"newTag\" autocomplete=\"off\"></label></fieldset><label>Payment method <span class=\"optional\">optional</span><select name=\"paymentMethod\"><option value=\"\">Not recorded</option>"
    payment-html
    ::  M7 T12. The moment the record currently holds. It is empty while the
    ::  form is adding, and it names the record while the form is correcting -
    ::  a correction may move the date, so the record cannot be found by the
    ::  date the person just typed.
    "</select></label><label>Note <span class=\"optional\">optional</span><input name=\"notes\" autocomplete=\"off\"></label><label>Observed<input name=\"observed\" type=\"datetime-local\" required></label><input name=\"zone\" type=\"hidden\"><input name=\"originalObserved\" type=\"hidden\" value=\"\"><div class=\"form-actions\"><button type=\"submit\">Save event</button><button type=\"button\" data-close-screen>Cancel</button></div><output id=\"event-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output></form></section>"
    ::  M7 T6. A reminder names one kind of service work and carries an
    ::  interval in time, an interval in distance, or both. A blank interval
    ::  writes NO row, so the form asks for nothing it will not store.
    "<section id=\"add-reminder\" class=\"entry-screen app-screen\" hidden>"
    "<button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button>"
    "<header><p class=\"eyebrow\">NEW REMINDER</p><h2>Add reminder</h2></header>"
    "<form id=\"reminder-form\">"
    "<label>Vehicle<select name=\"vehicle\" required>"
    vehicle-html
    "</select></label>"
    "<label>Service<select name=\"subtype\" required><option value=\"\">Choose one</option>"
    reminder-subtype-html
    "</select></label>"
    "<fieldset id=\"reminder-time\"><legend>Time interval <span class=\"optional\">optional</span></legend>"
    "<label>Every<input name=\"timeInterval\" inputmode=\"numeric\" autocomplete=\"off\" placeholder=\"3\"></label>"
    "<label>Unit<select name=\"timeUnit\"><option value=\"month\">months</option><option value=\"day\">days</option><option value=\"week\">weeks</option><option value=\"year\">years</option></select></label>"
    "<label>Next due on<input name=\"timeDue\" type=\"date\"></label>"
    "</fieldset>"
    "<fieldset id=\"reminder-distance\"><legend>Distance interval <span class=\"optional\">optional</span></legend>"
    "<label>Every<input name=\"distanceInterval\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"3000\"></label>"
    "<label>Next due at<input name=\"distanceDue\" inputmode=\"decimal\" autocomplete=\"off\" placeholder=\"83169\"></label>"
    "<label>Unit<select name=\"distanceUnit\"><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label>"
    "</fieldset>"
    "<p class=\"field-note\">Fill in one interval or both. A reminder with both is due when either one fires. Rover reads the odometer it already holds; it never asks for the current reading here.</p>"
    "<div class=\"form-actions\"><button type=\"submit\">Save reminder</button><button type=\"button\" data-close-screen>Cancel</button></div>"
    "<output id=\"reminder-verdict\" class=\"form-verdict\" aria-live=\"polite\"></output>"
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
::  M7 T6. The one derivation of "how far has this vehicle been driven". The
::  reading is never stored: it is the latest non-overlapping observation of
::  the vehicle, recomputed on every read. `current-odometer` prints it and
::  the reminders compare against it, so the two can never disagree.
++  current-odometer-reading
  |=  rows=(list vector:ast)
  ^-  (each current-reading @tas)
  =/  ordered  (order-vectors:act %observed-start %.y rows)
  ?~  ordered
    [%| %no-readings]
  =/  latest  i.ordered
  =/  ambiguous
    ?~  t.ordered
      %.n
    =/  prior-end  (cell-atom %observed-end i.t.ordered)
    =/  latest-start  (cell-atom %observed-start latest)
    (gth prior-end latest-start)
  ?:  ambiguous
    [%| %overlapping]
  :-  %&
  :*  (cell-atom %value-digits latest)
      (cell-atom %decimal-places latest)
      (cell-term %unit latest)
      `@da`(cell-atom %observed-start latest)
  ==
::
++  current-odometer
  |=  [rows=(list vector:ast) preference=(unit @tas)]
  ^-  tape
  =/  found  (current-odometer-reading rows)
  ?:  ?=(%| -.found)
    ?:  =(%no-readings p.found)
      "Unavailable - no odometer readings"
    "Unavailable - latest observation times overlap"
  =/  source  reading-unit.p.found
  =/  target  ?~(preference source u.preference)
  =/  converted
    (convert-distance:render digits.p.found places.p.found source target)
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
    "</dd></div><div><dt>PARTIAL FILL</dt><dd><label class=\"check-option read-only-check\"><input type=\"checkbox\" disabled"
    ?:(=(%partial (cell-term %tank-state row)) " checked" "")
    "><span>Partial fill</span></label></dd></div><div class=\"derived\"><dt>CALCULATED TOTAL</dt><dd>"
    (escape total)
    "</dd></div><div><dt>ECONOMY</dt><dd>"
    ?:  ?=(~ breaks)
      "Unavailable - another eligible full fill is required"
    ;:  weld
      "Unavailable - "
      (escape (economy-break-text (cell-term %reason i.breaks)))
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
::  Obelisk does not execute ORDER BY, so Rover orders the itemized lines
::  itself. The rank is the ratified component order, charges before discounts.
++  cost-component-rank
  |=  component=@tas
  ^-  @ud
  ?+  component  6
    %energy    0
    %time      1
    %session   2
    %idle      3
    %tax       4
    %discount  5
  ==
::
++  order-cost-components
  |=  rows=(list vector:ast)
  ^-  (list vector:ast)
  %+  sort  rows
  |=  [a=vector:ast b=vector:ast]
  ^-  ?
  %+  lth
    (cost-component-rank (cell-term %component a))
  (cost-component-rank (cell-term %component b))
::
::  One itemized line: kind, source-native quantity with its unit, the rate,
::  and the source-reported amount. A discount subtracts, so it renders signed.
++  cost-component-row
  |=  [row=vector:ast currency=@tas]
  ^-  tape
  =/  component  (cell-term %component row)
  =/  amount  (format-mills:render (cell-atom %amount-mills row) currency)
  ;:  weld
    "<li><span data-cost-component=\""
    (escape (scot %tas component))
    "\">"
    (escape (scot %tas component))
    "</span><span>"
    (trip (format-scaled:render (cell-atom %quantity row) (cell-atom %quantity-decimals row) %.n))
    " "
    (escape (scot %tas (cell-term %quantity-unit row)))
    "</span><span>"
    (trip (format-mills:render (cell-atom %rate-mills row) currency))
    "</span><span>"
    ?:(=(%discount component) "-" "")
    (trip amount)
    "</span></li>"
  ==
::
++  cost-evidence
  |=  [row=vector:ast costs=charging-cost-rows]
  ^-  tape
  =/  acquisition-id  (cell-atom %acquisition-id row)
  =/  currency  (cell-term %currency row)
  =/  component-rows
    %-  order-cost-components
    (rows-by %acquisition-id acquisition-id components.costs)
  =/  total-rows
    (rows-by %acquisition-id acquisition-id source-totals.costs)
  =/  itemized=tape
    ?~  component-rows
      ~
    =/  amounts=(list charging-component-amount:rover)
      %+  turn  component-rows
      |=  component=vector:ast
      ^-  charging-component-amount:rover
      :-  ;;(cost-component:rover (cell-term %component component))
      (cell-atom %amount-mills component)
    =/  proof  (derive-charging-total:act amounts)
    =/  lines=tape
      =/  remaining=(list vector:ast)  component-rows
      |-  ^-  tape
      ?~  remaining
        ~
      %+  weld  (cost-component-row i.remaining currency)
      $(remaining t.remaining)
    ;:  weld
      "<div><dt>COST COMPONENTS</dt><dd><ul class=\"cost-components\">"
      lines
      "</ul></dd></div><div><dt>ITEMIZED TOTAL</dt><dd data-itemized-total=\""
      (escape (format-mills:render total-mills.proof currency))
      "\">"
      (escape (format-mills:render total-mills.proof currency))
      "</dd></div>"
    ==
  =/  receipt=tape
    ?~  total-rows
      ~
    =/  total  (format-mills:render (cell-atom %total-mills i.total-rows) currency)
    ;:  weld
      "<div><dt>RECEIPT TOTAL</dt><dd data-receipt-total=\""
      (escape total)
      "\">"
      (escape total)
      " <small>source reported</small></dd></div>"
    ==
  (weld itemized receipt)
::
++  charge-card
  |=  $:  row=vector:ast
          measurements=(list vector:ast)
          batteries=(list vector:ast)
          costs=charging-cost-rows
          odometers=(list vector:ast)
          preference=(unit @tas)
      ==
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
  =/  odometer-line=tape
    =/  odometer-rows  (rows-by %acquisition-id acquisition-id odometers)
    ?~  odometer-rows
      ~
    =/  source-unit  (cell-term %unit i.odometer-rows)
    =/  target  ?~(preference source-unit u.preference)
    =/  shown
      %:  convert-distance:render
          (cell-atom %value-digits i.odometer-rows)
          (cell-atom %decimal-places i.odometer-rows)
          source-unit
          target
      ==
    =/  reading
      (format-distance:render converted-digits.shown converted-places.shown converted-unit.shown converted.shown)
    ;:  weld
      "<div><dt>ODOMETER</dt><dd data-charge-odometer=\""
      (escape reading)
      "\">"
      (escape reading)
      "</dd></div>"
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
    "</dd></div>"
    odometer-line
    "<div><dt>COST STATE</dt><dd data-cost-state=\""
    (escape (scot %tas (cell-term %cost-state row)))
    "\">"
    (escape (scot %tas (cell-term %cost-state row)))
    " / "
    (escape (scot %tas (cell-term %currency row)))
    "</dd></div>"
    (cost-evidence row costs)
    "</dl></article>"
  ==
::
::  Which kind an event is, read the only way there is to read it: by which
::  typed child row exists. There is no kind column, and adding one would let
::  the column and the child disagree.
++  event-kind-of
  |=  [event-id=@ events=event-rows]
  ^-  @tas
  ?^  (rows-by %event-id event-id services.events)
    %service
  ?^  (rows-by %event-id event-id expenses.events)
    %expense
  ?^  (rows-by %event-id event-id notes.events)
    %note
  ?^  (rows-by %event-id event-id acquisitions.events)
    %acquisition
  ?^  (rows-by %event-id event-id disposals.events)
    %disposal
  %unknown
::
::  An absent member renders NO line. The absence of the row is the value, so
::  a parking fee shows no station and a note shows no cost.
++  event-card
  |=  $:  row=vector:ast
          events=event-rows
          preference=(unit @tas)
          vehicle=@t
      ==
  ^-  tape
  =/  event-id  (cell-atom %event-id row)
  =/  kind  (event-kind-of event-id events)
  =/  observed=tape
    ;:  weld
      (trip (format-da:render `@da`(cell-atom %observed-start row)))
      " ("
      (escape (cell-text %source-zone row))
      ")"
    ==
  =/  total-line=tape
    =/  cost-rows  (rows-by %event-id event-id costs.events)
    =/  total-rows  (rows-by %event-id event-id cost-totals.events)
    ?:  ?|  ?=(~ cost-rows)
            ?=(~ total-rows)
        ==
      ~
    =/  total
      %:  format-total:render
          (cell-atom %total-mills i.total-rows)
          (cell-term %currency i.cost-rows)
          (cell-atom %minor-unit-decimals i.cost-rows)
      ==
    ::  M7 T4. The money on a purchase and on a sale means something the word
    ::  TOTAL does not say, so the label follows the kind. The attribute does
    ::  not: one machine name serves every kind.
    =/  caption=tape
      ?+  kind  "TOTAL"
        %acquisition  "PURCHASE PRICE"
        %disposal     "AMOUNT RECEIVED"
      ==
    ;:  weld
      "<div><dt>"
      caption
      "</dt><dd data-event-total=\""
      (escape total)
      "\">"
      (escape total)
      " <small>entered</small></dd></div>"
    ==
  =/  odometer-line=tape
    =/  odometer-rows  (rows-by %event-id event-id odometers.events)
    ?~  odometer-rows
      ~
    =/  source-unit  (cell-term %unit i.odometer-rows)
    =/  target  ?~(preference source-unit u.preference)
    =/  shown
      %:  convert-distance:render
          (cell-atom %value-digits i.odometer-rows)
          (cell-atom %decimal-places i.odometer-rows)
          source-unit
          target
      ==
    =/  reading
      (format-distance:render converted-digits.shown converted-places.shown converted-unit.shown converted.shown)
    ;:  weld
      "<div><dt>ODOMETER</dt><dd data-event-odometer=\""
      (escape reading)
      "\">"
      (escape reading)
      "</dd></div>"
    ==
  =/  station-line=tape
    =/  station-rows  (rows-by %event-id event-id stations.events)
    ?~  station-rows
      ~
    ;:  weld
      "<div><dt>STATION</dt><dd data-event-station=\""
      (escape (cell-text %station i.station-rows))
      "\">"
      (escape (cell-text %station i.station-rows))
      " - "
      (escape (cell-text %place i.station-rows))
      "</dd></div>"
    ==
  =/  tag-line=tape
    =/  tag-rows  (rows-by %event-id event-id tags.events)
    ?~  tag-rows
      ~
    =/  labels=tape
      =/  remaining=(list vector:ast)  tag-rows
      |-  ^-  tape
      ?~  remaining
        ~
      %+  weld
        ::  M7 T12. The attribute is what the edit control reads back to
        ::  re-check the boxes. The text beside it is what a person reads.
        ;:  weld
          "<li data-event-tag=\""
          (escape (cell-text %tag i.remaining))
          "\">"
          (escape (cell-text %tag i.remaining))
          "</li>"
        ==
      $(remaining t.remaining)
    ;:  weld
      "<div><dt>TAGS</dt><dd><ul class=\"event-tags\">"
      labels
      "</ul></dd></div>"
    ==
  ::  M7 T2. Every selected subtype renders. One real service record carries
  ::  ten, so the card lists them all rather than naming a first and a count.
  ::  The count attribute is there so a reader can check the list is whole.
  =/  subtype-line=tape
    =/  subtype-rows  (rows-by %event-id event-id service-subtypes.events)
    ?~  subtype-rows
      ~
    ::  Obelisk has no executing ORDER BY, so the rows arrive in storage order.
    ::  Ten of them in storage order read as a jumble, so Rover sorts by label
    ::  itself. `aor` compares the two cords as text; `lth` would compare them
    ::  as little-endian numbers, which is not alphabetical.
    =/  ordered=(list vector:ast)
      %+  sort  subtype-rows
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text %service-subtype a) (cell-text %service-subtype b))
    =/  labels=tape
      =/  remaining=(list vector:ast)  ordered
      |-  ^-  tape
      ?~  remaining
        ~
      %+  weld
        ;:  weld
          "<li data-event-subtype=\""
          (escape (cell-text %service-subtype i.remaining))
          "\">"
          (escape (cell-text %service-subtype i.remaining))
          "</li>"
        ==
      $(remaining t.remaining)
    ;:  weld
      "<div><dt>SUBTYPES</dt><dd data-event-subtype-count=\""
      (trip (scot %ud (lent subtype-rows)))
      "\"><ul class=\"event-subtypes\">"
      labels
      "</ul></dd></div>"
    ==
  ::  M7 T4. How the vehicle left. Only a disposal has this row, and every
  ::  disposal has one, so its absence on any other kind is not an omission.
  =/  disposal-kind-line=tape
    =/  disposal-rows  (rows-by %event-id event-id disposals.events)
    ?~  disposal-rows
      ~
    =/  label  (cell-text %disposal-kind i.disposal-rows)
    ;:  weld
      "<div><dt>DISPOSAL KIND</dt><dd data-event-disposal-kind=\""
      (escape label)
      "\">"
      (escape label)
      "</dd></div>"
    ==
  =/  payment-line=tape
    =/  payment-rows  (rows-by %event-id event-id payments.events)
    ?~  payment-rows
      ~
    ;:  weld
      "<div><dt>PAYMENT METHOD</dt><dd>"
      (escape (cell-text %payment-method i.payment-rows))
      "</dd></div>"
    ==
  =/  note-line=tape
    =/  note-rows  (rows-by %event-id event-id note-texts.events)
    ?~  note-rows
      ~
    ;:  weld
      "<div><dt>NOTE</dt><dd>"
      (escape (cell-text %note i.note-rows))
      "</dd></div>"
    ==
  ::  M7 T12. The edit control. It carries every value the Add Event form
  ::  needs, in the exact text that form's field takes, so pressing it
  ::  re-opens the form a person already knows with their own entry in it.
  ::
  ::  The odometer here is the SOURCE reading, not the converted one on the
  ::  card above. A person correcting a note must not have their mileage
  ::  silently rewritten into whatever unit the display preference names.
  =/  edit-total=tape
    =/  cost-rows  (rows-by %event-id event-id costs.events)
    =/  total-rows  (rows-by %event-id event-id cost-totals.events)
    ?:  ?|  ?=(~ cost-rows)
            ?=(~ total-rows)
        ==
      ~
    %-  escape
    %:  format-total:render
        (cell-atom %total-mills i.total-rows)
        (cell-term %currency i.cost-rows)
        (cell-atom %minor-unit-decimals i.cost-rows)
    ==
  =/  odometer-rows  (rows-by %event-id event-id odometers.events)
  =/  edit-mileage=tape
    ?~  odometer-rows
      ~
    %-  trip
    %^  format-scaled:render
      (cell-atom %value-digits i.odometer-rows)
      (cell-atom %decimal-places i.odometer-rows)
    %.n
  =/  edit-mileage-unit=@tas
    ?~  odometer-rows
      %mi
    (cell-term %unit i.odometer-rows)
  =/  edit-station=tape
    =/  station-rows  (rows-by %event-id event-id stations.events)
    ?~  station-rows
      "none"
    (escape (cell-text %station i.station-rows))
  =/  edit-payment=tape
    =/  payment-rows  (rows-by %event-id event-id payments.events)
    ?~  payment-rows
      ~
    (escape (cell-text %payment-method i.payment-rows))
  =/  edit-disposal-kind=tape
    =/  disposal-rows  (rows-by %event-id event-id disposals.events)
    ?~  disposal-rows
      ~
    (escape (cell-text %disposal-kind i.disposal-rows))
  =/  edit-notes=tape
    =/  note-rows  (rows-by %event-id event-id note-texts.events)
    ?~  note-rows
      ~
    (escape (cell-text %note i.note-rows))
  =/  edit-control=tape
    ;:  weld
      "<div class=\"card-actions\"><button type=\"button\" class=\"card-edit\" data-edit-event data-edit-vehicle=\""
      (escape vehicle)
      "\" data-edit-kind=\""
      (escape (scot %tas kind))
      "\" data-edit-observed=\""
      (input-da `@da`(cell-atom %observed-start row))
      "\" data-edit-zone=\""
      (escape (cell-text %source-zone row))
      "\" data-edit-total=\""
      edit-total
      "\" data-edit-mileage=\""
      edit-mileage
      "\" data-edit-mileage-unit=\""
      (escape (scot %tas edit-mileage-unit))
      "\" data-edit-station=\""
      edit-station
      "\" data-edit-payment=\""
      edit-payment
      "\" data-edit-disposal-kind=\""
      edit-disposal-kind
      "\" data-edit-notes=\""
      edit-notes
      "\">Edit</button></div>"
    ==
  ;:  weld
    "<article class=\"history-card event\" data-event-kind=\""
    (escape (scot %tas kind))
    "\"><header><span>"
    (cuss (trip (scot %tas kind)))
    "</span><time>"
    observed
    "</time></header><dl>"
    total-line
    disposal-kind-line
    odometer-line
    station-line
    subtype-line
    tag-line
    payment-line
    note-line
    "</dl>"
    edit-control
    "</article>"
  ==
::
++  history-cards
  |=  $:  rows=(list vector:ast)
          measurements=(list vector:ast)
          batteries=(list vector:ast)
          costs=charging-cost-rows
          odometers=(list vector:ast)
          station-links=(list vector:ast)
          additive-links=(list vector:ast)
          subtype-links=(list vector:ast)
          economy-breaks=(list vector:ast)
          events=event-rows
          preference=(unit @tas)
          vehicle=@t
      ==
  ^-  tape
  ?~  rows
    ~
  =/  is-event  (vector-key:act %event-id i.rows)
  =/  is-fill  (vector-key:act %quantity-milli i.rows)
  =/  card=tape
    ?^  is-event
      (event-card i.rows events preference vehicle)
    ?^  is-fill
      (fill-card i.rows station-links additive-links subtype-links economy-breaks)
    (charge-card i.rows measurements batteries costs odometers preference)
  (weld card $(rows t.rows))
::
++  pagination-controls
  |=  [history-page=@ud total=@ud target=@t]
  ^-  tape
  =/  history-window-size=@ud  25
  =/  offset  (mul history-page history-window-size)
  =/  through  (min total (add offset history-window-size))
  ;:  weld
    "<nav class=\"pagination\" aria-label=\"History pages\"><span>Showing "
    (trip (scot %ud ?:(=(0 total) 0 +(offset))))
    "-"
    (trip (scot %ud through))
    " of "
    (trip (scot %ud total))
    "</span>"
    ?:  (gth history-page 0)
      ;:  weld
        "<button type=\"button\" data-view-page=\""
        (trip (scot %ud (dec history-page)))
        "\" data-view-target=\""
        (escape target)
        "\">Newer</button>"
      ==
    ~
    ?:  (gth total through)
      ;:  weld
        "<button type=\"button\" data-view-page=\""
        (trip (scot %ud +(history-page)))
        "\" data-view-target=\""
        (escape target)
        "\">Older</button>"
      ==
    ~
    "</nav>"
  ==
::
::  Mixed kinds order by one rule: `observed-start` descending, with the shipped
::  recorded-at tie-break behind it. An event is a thing that happened to the
::  vehicle, so it belongs in the same column as a fill, not in a second list
::  the owner has to cross-read against a date.
++  ordered-history
  |=  $:  fills=(list vector:ast)
          charges=(list vector:ast)
          measurements=(list vector:ast)
          batteries=(list vector:ast)
          costs=charging-cost-rows
          odometers=(list vector:ast)
          station-links=(list vector:ast)
          additive-links=(list vector:ast)
          subtype-links=(list vector:ast)
          economy-breaks=(list vector:ast)
          events=event-rows
          preference=(unit @tas)
          history-page=@ud
          vehicle=@t
      ==
  ^-  tape
  =/  history-window-size=@ud  25
  =/  all-ordered
    %^  order-vectors:act  %observed-start  %.y
    :(weld fills charges events.events)
  =/  ordered
    (scag history-window-size (slag (mul history-page history-window-size) all-ordered))
  ?:  ?=(~ ordered)
    "<p class=\"empty\">No acquisition or event history.</p>"
  ;:  weld
    %:  history-cards
        ordered
        measurements
        batteries
        costs
        odometers
        station-links
        additive-links
        subtype-links
        economy-breaks
        events
        preference
        vehicle
    ==
    (pagination-controls history-page (lent all-ordered) 'vehicle-settings-screen')
  ==
::
::  M7 T7. Join the parts a person actually recorded, and nothing else. An
::  empty part contributes no separator, so a vehicle with a make and no model
::  reads "Ford" rather than "Ford " or "Ford ,".
++  join-parts
  |=  [separator=tape parts=(list tape)]
  ^-  tape
  =/  live=(list tape)  (skip parts |=(part=tape ?=(~ part)))
  |-
  ^-  tape
  ?~  live
    ~
  ?~  t.live
    i.live
  ;:(weld i.live separator $(live t.live))
::
::  One specification value of one vehicle, or nothing at all. Nothing is what
::  an unrecorded field is: there is no row to find, so there is no empty
::  string to render and no placeholder to explain away.
++  spec-text-of
  |=  [vehicle-id=@ relation=@tas column=@tas specs=spec-index]
  ^-  (unit @t)
  =/  rows  (rows-for vehicle-id (~(gut by specs) relation ~))
  ?~  rows
    ~
  `(cell-text column i.rows)
::
++  spec-number-of
  |=  [vehicle-id=@ relation=@tas column=@tas specs=spec-index]
  ^-  (unit @ud)
  =/  rows  (rows-for vehicle-id (~(gut by specs) relation ~))
  ?~  rows
    ~
  `(cell-atom column i.rows)
::
::  One line of the rendered description, present only when it has something to
::  say. `part` names the line so a reader - a person or a fixture - can find
::  it without parsing the sentence.
++  spec-line
  |=  [class=tape part=tape body=tape]
  ^-  tape
  ?~  body
    ~
  ;:  weld
    "<p class=\""
    class
    "\" data-vehicle-spec=\""
    part
    "\">"
    body
    "</p>"
  ==
::
::  What the vehicle screen says about what the vehicle IS. A description, not
::  a table of terms: the year, make, model and sub-model read as one name, and
::  the colour, body, engine, transmission, drive and bed read as one sentence.
::  A vehicle with no specification row at all renders NOTHING here, which is
::  the state every installed database is in.
++  vehicle-description
  |=  [vehicle-id=@ specs=spec-index]
  ^-  tape
  =/  text
    |=  [relation=@tas column=@tas]
    ^-  tape
    =/  found  (spec-text-of vehicle-id relation column specs)
    ?~(found ~ (escape u.found))
  =/  model-year  (spec-number-of vehicle-id %vehicle-model-year %model-year specs)
  =/  headline
    %+  join-parts  " "
    :~  ?~(model-year ~ (trip (format-scaled:render u.model-year 0 %.n)))
        (text %vehicle-make %make)
        (text %vehicle-model %model)
        (text %vehicle-sub-model %sub-model)
    ==
  =/  appearance
    %+  join-parts  " "
    :~  (text %vehicle-color %color)
        (text %vehicle-body-type %body-type)
    ==
  =/  detail
    %+  join-parts  ", "
    :~  appearance
        (text %vehicle-engine %engine)
        (text %vehicle-transmission %transmission)
        (text %vehicle-drive-type %drive-type)
        (text %vehicle-bed-type %bed-type)
    ==
  =/  vin  (text %vehicle-vin %vin)
  =/  plate  (text %vehicle-license-plate %plate)
  ;:  weld
    (spec-line "vehicle-description" "headline" headline)
    (spec-line "vehicle-description-detail" "detail" ?~(detail ~ (weld detail ".")))
    (spec-line "vehicle-identifier" "vin" ?~(vin ~ (weld "<span class=\"key\">VIN</span> " vin)))
    (spec-line "vehicle-identifier" "plate" ?~(plate ~ (weld "<span class=\"key\">PLATE</span> " plate)))
    (spec-line "vehicle-note" "note" (text %vehicle-notes %note))
  ==
::
++  spec-input
  |=  [label=tape name=tape value=tape]
  ^-  tape
  ;:  weld
    "<label>"
    label
    "<input name=\""
    name
    "\" value=\""
    value
    "\"></label>"
  ==
::
::  Where a person types the specification. Every control starts empty, exactly
::  as the tank-size control has since M0, and an empty control writes no row.
++  vehicle-spec-form
  |=  [vehicle-id=@ specs=spec-index]
  ^-  tape
  =/  text
    |=  [relation=@tas column=@tas]
    ^-  tape
    =/  found  (spec-text-of vehicle-id relation column specs)
    ?~(found ~ (escape u.found))
  =/  model-year  (spec-number-of vehicle-id %vehicle-model-year %model-year specs)
  ;:  weld
    "<fieldset class=\"vehicle-settings-group\" data-settings-group=\"specification\"><legend>Specification</legend>"
    (spec-input "Year" "specYear" ?~(model-year ~ (trip (format-scaled:render u.model-year 0 %.n))))
    (spec-input "Make" "specMake" (text %vehicle-make %make))
    (spec-input "Model" "specModel" (text %vehicle-model %model))
    (spec-input "Sub-model" "specSubModel" (text %vehicle-sub-model %sub-model))
    (spec-input "Body type" "specBodyType" (text %vehicle-body-type %body-type))
    (spec-input "Colour" "specColor" (text %vehicle-color %color))
    (spec-input "Engine" "specEngine" (text %vehicle-engine %engine))
    (spec-input "Transmission" "specTransmission" (text %vehicle-transmission %transmission))
    (spec-input "Drive type" "specDriveType" (text %vehicle-drive-type %drive-type))
    (spec-input "Bed type" "specBedType" (text %vehicle-bed-type %bed-type))
    (spec-input "VIN" "specVin" (text %vehicle-vin %vin))
    (spec-input "Licence plate" "specPlate" (text %vehicle-license-plate %plate))
    "<label>Notes<input name=\"specNotes\" value=\""
    (text %vehicle-notes %note)
    "\"></label></fieldset>"
  ==
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
          costs=charging-cost-rows
          energy-odometers=(list vector:ast)
          station-links=(list vector:ast)
          additive-links=(list vector:ast)
          preferences=(list vector:ast)
          subtype-links=(list vector:ast)
          economy-breaks=(list vector:ast)
          subtypes=(list vector:ast)
          default-subtypes=(list vector:ast)
          driving-modes=(list vector:ast)
          available-definitions=(list vector:ast)
          available-modes=(list vector:ast)
          vehicle-consumables=(list vector:ast)
          consumable-tank-sizes=(list vector:ast)
          tank-sizes=(list vector:ast)
          refill-reserves=(list vector:ast)
          events=event-rows
          specs=spec-index
          is-default=?
          history-page=@ud
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
  =/  vehicle-definitions  (rows-for id definition-rows)
  =/  tank  (rows-for id tank-sizes)
  =/  refill-reserve  (rows-for id refill-reserves)
  =/  tank-value=tape
    ?~  tank
      ~
    (trip (format-scaled:render (cell-atom %digits i.tank) (cell-atom %decimals i.tank) %.n))
  =/  tank-unit=@tas
    ?~  tank
      %gal
    (cell-term %size-unit i.tank)
  =/  refill-reserve-value=tape
    ?~  refill-reserve
      ~
    (scow %ud (cell-atom %reserve-percent i.refill-reserve))
  =/  selected-subtype=(unit @t)
    ?~  default-subtype
      ~
    `(cell-text %subtype u.default-subtype)
  =/  subtype-controls
    (vehicle-subtype-options subtypes vehicle-definitions selected-subtype)
  =/  energy-controls
    (vehicle-energy-source-checks available-definitions vehicle-definitions)
  =/  mode-controls
    (vehicle-mode-membership-checks available-modes modes)
  =/  current-default-energy=(unit @t)
    =/  selected  (rows-for id default-rows)
    ?~  selected
      ~
    `(cell-text %default-energy i.selected)
  =/  default-energy-controls
    (default-energy-options vehicle-definitions current-default-energy)
  =/  can-fill  (active-energy-kind %reservoir vehicle-definitions)
  =/  can-charge  (active-energy-kind %electricity vehicle-definitions)
  =/  def-link  (row-by-text %consumable 'DEF' (rows-for id vehicle-consumables))
  =/  def-enabled
    ?~  def-link
      %.n
    !=(0 (cell-atom %link-archived u.def-link))
  =/  show-def
    ?|  (active-energy-label 'Diesel' vehicle-definitions)
        ?=(^ def-link)
    ==
  =/  def-tank  (row-by-text %consumable 'DEF' (rows-for id consumable-tank-sizes))
  =/  def-tank-value=tape
    ?~  def-tank
      ~
    (trip (format-scaled:render (cell-atom %digits u.def-tank) (cell-atom %decimals u.def-tank) %.n))
  =/  def-tank-unit=@tas
    ?~  def-tank
      %gal
    (cell-term %unit u.def-tank)
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
        costs
        energy-odometers
        station-links
        additive-links
        subtype-links
        economy-breaks
        events(events (rows-for id events.events))
        preference
        history-page
        (cell-text %label row)
    ==
  ;:  weld
    "<article class=\"vehicle-card\" data-vehicle-settings-panel data-vehicle=\""
    (escape (cell-text %label row))
    "\" hidden><header><div><p class=\"eyebrow\">VEHICLE SETTINGS</p><h2>"
    (escape (cell-text %label row))
    "</h2></div><span class=\"status\">"
    ?:(is-default "DEFAULT" ?:(archived "ARCHIVED" "ACTIVE"))
    "</span></header>"
    (vehicle-description id specs)
    "<div class=\"vehicle-actions\">"
    "<button type=\"button\" data-set-default-vehicle data-vehicle=\""
    (escape (cell-text %label row))
    "\">Set Default</button></div><div class=\"vehicle-entry-actions\">"
    ?:  can-fill
      ;:  weld
        "<button type=\"button\" data-vehicle-action=\"fill\" data-vehicle=\""
        (escape (cell-text %label row))
        "\">Add Fill</button>"
      ==
    ~
    ?:  can-charge
      ;:  weld
        "<button type=\"button\" data-vehicle-action=\"charge\" data-vehicle=\""
        (escape (cell-text %label row))
        "\">Add Charge</button>"
      ==
    ~
    "<button type=\"button\" data-vehicle-action=\"odometer\" data-vehicle=\""
    (escape (cell-text %label row))
    "\">Add Odometer</button></div><form class=\"vehicle-settings-form\"><input type=\"hidden\" name=\"vehicle\" value=\""
    (escape label)
    "\"><label class=\"settings-identity-row\">Vehicle name<input name=\"label\" value=\""
    (escape label)
    "\" required></label><fieldset class=\"vehicle-settings-group\" data-settings-group=\"fuel-system\"><legend>Fuel System</legend><label>Default subtype<select name=\"defaultSubtype\"><option value=\"\">Not set</option>"
    subtype-controls
    "</select></label><label>Tank size<input name=\"tankSize\" inputmode=\"decimal\" value=\""
    tank-value
    "\"></label><label>Tank units<select name=\"tankUnit\"><option value=\"gal\""
    ?:(=(%gal tank-unit) " selected" "")
    ">gal</option><option value=\"litre\""
    ?:(=(%litre tank-unit) " selected" "")
    ">litre</option></select></label><label>Fill up when tank reaches <input name=\"refillReserve\" inputmode=\"numeric\" min=\"0\" max=\"99\" step=\"1\" value=\""
    refill-reserve-value
    "\">%</label></fieldset><fieldset class=\"vehicle-settings-group membership-checks\" data-settings-group=\"energy-sources\" data-energy-source-checks><legend>Energy Sources</legend><div class=\"check-grid\">"
    energy-controls
    "</div><button type=\"button\" data-add-energy-source>Add energy source type</button><label>Default energy source<select name=\"defaultEnergy\"><option value=\"\">Not set</option>"
    default-energy-controls
    "</select></label></fieldset><fieldset class=\"vehicle-settings-group membership-checks\" data-settings-group=\"driving-modes\" data-driving-mode-checks><legend>Driving Modes</legend><div class=\"check-grid\">"
    mode-controls
    "</div><button type=\"button\" data-add-driving-mode>Add driving mode type</button></fieldset>"
    ?:  show-def
      ;:  weld
        "<fieldset class=\"vehicle-settings-group\" data-settings-group=\"def\" data-def-configuration><legend>DEF</legend><label class=\"check-option\" data-def-toggle-row><input type=\"checkbox\" name=\"defEnabled\" value=\"yes\""
        ?:(def-enabled " checked" "")
        "><span>Enable DEF</span></label><label data-def-tank-row"
        ?:(def-enabled "" " hidden")
        ">DEF tank size<span class=\"input-unit\"><input name=\"defTankSize\" inputmode=\"decimal\" value=\""
        def-tank-value
        "\"><select name=\"defTankUnit\" aria-label=\"DEF tank unit\"><option value=\"gal\""
        ?:(=(%gal def-tank-unit) " selected" "")
        ">gal</option><option value=\"litre\""
        ?:(=(%litre def-tank-unit) " selected" "")
        ">litre</option></select></span></label></fieldset>"
      ==
    ~
    (vehicle-spec-form id specs)
    "<button type=\"submit\">Save Vehicle Settings</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form>"
    preference-control
    "<button type=\"button\" class=\"archive-vehicle-control\" data-remove-vehicle data-vehicle=\""
    (escape (cell-text %label row))
    "\">Archive vehicle</button><details class=\"vehicle-settings\"><summary>Configuration summary</summary>"
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
          stations=(list vector:ast)
          station-links=(list vector:ast)
          additives=(list vector:ast)
          additive-links=(list vector:ast)
          subtypes=(list vector:ast)
          subtype-links=(list vector:ast)
          driving-modes=(list vector:ast)
          fill-driving-modes=(list vector:ast)
          fill-average-speeds=(list vector:ast)
          fill-drive-balances=(list vector:ast)
          fill-notes=(list vector:ast)
          fill-payment-links=(list vector:ast)
          economy-breaks=(list vector:ast)
          tags=(list vector:ast)
          fill-tags=(list vector:ast)
          payment-methods=(list vector:ast)
      ==
  ^-  tape
  =/  vehicle  (vehicle-label (cell-atom %vehicle-id row) vehicles)
  =/  acquisition  (cell-atom %acquisition-id row)
  =/  odometer  (rows-by %acquisition-id acquisition odometer-links)
  =/  station-link  (rows-by %acquisition-id acquisition station-links)
  =/  acquisition-additives  (rows-by %acquisition-id acquisition additive-links)
  =/  subtype-link  (rows-by %acquisition-id acquisition subtype-links)
  =/  mode-link  (rows-by %acquisition-id acquisition fill-driving-modes)
  =/  speed-link  (rows-by %acquisition-id acquisition fill-average-speeds)
  =/  balance-link  (rows-by %acquisition-id acquisition fill-drive-balances)
  =/  note-link  (rows-by %acquisition-id acquisition fill-notes)
  =/  payment-link  (rows-by %acquisition-id acquisition fill-payment-links)
  =/  acquisition-tags  (rows-by %acquisition-id acquisition fill-tags)
  =/  missed-fill  ?=(^ (rows-by %acquisition-id acquisition economy-breaks))
  =/  station-selected=(unit @t)
    ?~  station-link  ~  `(cell-text %station i.station-link)
  =/  subtype-selected=(unit @t)
    ?~  subtype-link  ~  `(cell-text %subtype i.subtype-link)
  =/  mode-selected=(unit @t)
    ?~  mode-link  ~  `(cell-text %driving-mode i.mode-link)
  =/  payment-selected=(unit @t)
    ?~  payment-link  ~  `(cell-text %payment-method i.payment-link)
  =/  note-value=@t
    ?~  note-link  ''  (cell-text %note i.note-link)
  =/  mileage-value=tape
    ?~  odometer
      ~
    (trip (format-scaled:render (cell-atom %value-digits i.odometer) (cell-atom %decimal-places i.odometer) %.n))
  =/  mileage-unit=@tas
    ?~  odometer  %mi  (cell-term %unit i.odometer)
  =/  speed-value=tape
    ?~  speed-link
      ~
    (trip (format-scaled:render (cell-atom %digits i.speed-link) (cell-atom %decimals i.speed-link) %.n))
  =/  speed-unit=@tas
    ?~  speed-link  %mph  (cell-term %speed-unit i.speed-link)
  =/  balance-value=tape
    ?~  balance-link  ~  (scow %ud (cell-atom %highway-percent i.balance-link))
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
    "</dd></div><div><dt>Partial fill</dt><dd><label class=\"check-option read-only-check\"><input type=\"checkbox\" disabled"
    ?:(=(%partial (cell-term %tank-state row)) " checked" "")
    "><span>Partial fill</span></label></dd></div></dl><form class=\"history-edit-form\">"
    "<input type=\"hidden\" name=\"vehicle\" value=\""
    (escape vehicle)
    "\"><input type=\"hidden\" name=\"originalObserved\" value=\""
    observed-input
    "\"><label>Date and time<input type=\"datetime-local\" name=\"observed\" value=\""
    observed-input
    "\" required></label><input type=\"hidden\" name=\"definition\" value=\""
    (escape (cell-text %energy row))
    "\"><input type=\"hidden\" name=\"zone\" value=\""
    (escape (cell-text %source-zone row))
    "\"><label>Odometer <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"mileage\" inputmode=\"decimal\" value=\""
    mileage-value
    "\"><select name=\"mileageUnit\"><option value=\"mi\""
    ?:(=(%mi mileage-unit) " selected" "")
    ">mi</option><option value=\"km\""
    ?:(=(%km mileage-unit) " selected" "")
    ">km</option></select></div></label><label>Station <span class=\"optional\">optional</span><select name=\"station\"><option value=\"none\""
    ?:  ?=(~ station-selected)  " selected"  ""
    ">Not recorded</option>"
    (selected-options stations %label station-selected)
    "</select></label><input type=\"hidden\" name=\"newStationLabel\" value=\"\"><input type=\"hidden\" name=\"newPlaceLabel\" value=\"\"><input type=\"hidden\" name=\"newStationKind\" value=\"private\"><label>Fuel subtype <span class=\"optional\">optional</span><select name=\"subtype\"><option value=\"\""
    ?:  ?=(~ subtype-selected)  " selected"  ""
    ">Not recorded</option>"
    (selected-options (rows-by-text %energy (cell-text %energy row) subtypes) %label subtype-selected)
    "</select></label><fieldset><legend>Additives <span class=\"optional\">optional</span></legend><div class=\"check-grid\">"
    (selected-active-check-options additives %label acquisition-additives %additive 'additives')
    "</div></fieldset><fieldset><legend>Tags <span class=\"optional\">optional</span></legend><div class=\"check-grid\">"
    (selected-active-check-options tags %label acquisition-tags %tag 'tags')
    "</div></fieldset><label class=\"check-option\"><input type=\"checkbox\" name=\"missedFill\" value=\"yes\""
    ?:(missed-fill " checked" "")
    "><span>Missed fill</span></label><label>Driving mode <span class=\"optional\">optional</span><select name=\"drivingMode\"><option value=\"\""
    ?:  ?=(~ mode-selected)  " selected"  ""
    ">Not recorded</option>"
    (selected-active-mode-options (rows-by-text %vehicle vehicle driving-modes) mode-selected)
    "</select></label><label>Average speed <span class=\"optional\">optional</span><div class=\"input-unit\"><input name=\"averageSpeed\" inputmode=\"decimal\" value=\""
    speed-value
    "\"><select name=\"speedUnit\"><option value=\"mph\""
    ?:(=(%mph speed-unit) " selected" "")
    ">mph</option><option value=\"kph\""
    ?:(=(%kph speed-unit) " selected" "")
    ">km/h</option></select></div></label><label>Highway driving percent <span class=\"optional\">optional</span><input name=\"driveBalance\" type=\"number\" min=\"0\" max=\"100\" value=\""
    balance-value
    "\"></label><input type=\"hidden\" name=\"newTag\" value=\"\"><label>Notes<textarea name=\"notes\">"
    (escape note-value)
    "</textarea></label><label>Payment Method<select name=\"paymentMethod\"><option value=\"\""
    ?:  ?=(~ payment-selected)  " selected"  ""
    ">Not recorded</option>"
    (selected-active-options payment-methods %label payment-selected)
    "</select></label><label>Quantity<input name=\"quantity\" inputmode=\"decimal\" value=\""
    (escape (format-scaled:render (cell-atom %quantity-milli row) 3 %.n))
    "\"></label><label>Unit price<input name=\"price\" inputmode=\"decimal\" value=\""
    (escape (format-unit-price:render (cell-atom %unit-price-mills row) (cell-term %currency row)))
    "\"></label><label class=\"check-option\"><input type=\"checkbox\" name=\"partialFill\""
    ?:(=(%partial (cell-term %tank-state row)) " checked" "")
    "><span>Partial fill</span></label><input type=\"hidden\" name=\"tank\" value=\""
    ?:(=(%partial (cell-term %tank-state row)) "partial" "full")
    "\"><input type=\"hidden\" name=\"profile\" value=\""
    (escape (scot %tas (cell-term %price-profile row)))
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
          station-links=(list vector:ast)
          additives=(list vector:ast)
          additive-links=(list vector:ast)
          subtypes=(list vector:ast)
          subtype-links=(list vector:ast)
          driving-modes=(list vector:ast)
          fill-driving-modes=(list vector:ast)
          fill-average-speeds=(list vector:ast)
          fill-drive-balances=(list vector:ast)
          fill-notes=(list vector:ast)
          fill-payment-links=(list vector:ast)
          economy-breaks=(list vector:ast)
          tags=(list vector:ast)
          fill-tags=(list vector:ast)
          payment-methods=(list vector:ast)
          selected-vehicle=(unit vector:ast)
          history-page=@ud
      ==
  ^-  tape
  =/  history-window-size=@ud  25
  =/  scoped-fills=(list vector:ast)
    ?~  selected-vehicle
      ~
    (rows-for (cell-atom %vehicle-id u.selected-vehicle) fills)
  =/  all-ordered  (order-vectors:act %observed-start %.y scoped-fills)
  =/  ordered
    (scag history-window-size (slag (mul history-page history-window-size) all-ordered))
  =/  selected-label=(unit @t)
    ?~  selected-vehicle
      ~
    `(cell-text %label u.selected-vehicle)
  =/  render-rows
    |=  rows=(list vector:ast)
    ^-  tape
    ?~  rows
      ~
    =/  rendered
      %:  history-row
          i.rows
          vehicles
          odometer-links
          stations
          station-links
          additives
          additive-links
          subtypes
          subtype-links
          driving-modes
          fill-driving-modes
          fill-average-speeds
          fill-drive-balances
          fill-notes
          fill-payment-links
          economy-breaks
          tags
          fill-tags
          payment-methods
      ==
    (weld rendered $(rows t.rows))
  =/  rows=tape  (render-rows ordered)
  ;:  weld
    "<section id=\"history-screen\" class=\"app-screen\" hidden data-view-vehicle=\""
    ?~(selected-label "" (escape u.selected-label))
    "\"><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER LOG</p><h1>HISTORY</h1></header>"
    "<label>Vehicle<select id=\"history-vehicle-filter\">"
    ?~(selected-label "<option value=\"\" selected>Select a vehicle</option>" "")
    (vehicle-options vehicles)
    "</select></label><div class=\"history-table-head\"><span>DATE</span><span>ODOMETER</span><span>GALLONS</span><span>TOTAL COST</span></div><div id=\"history-table\">"
    rows
    "</div>"
    (pagination-controls history-page (lent all-ordered) 'history-screen')
    "<p id=\"history-empty\" class=\"empty\" hidden>No fill history for this vehicle.</p></section>"
  ==
::
++  statistic-interval-rows
  |=  $:  fills=(list vector:ast)
          vehicles=(list vector:ast)
          tank-sizes=(list vector:ast)
          derivations=(map @ derived-fill)
          mode=@tas
      ==
  ^-  tape
  ?~  fills
    ~
  =/  row  i.fills
  =/  rest
    $(fills t.fills)
  ?.  =(%full (cell-term %tank-state row))
    rest
  =/  vehicle-id  (cell-atom %vehicle-id row)
  =/  vehicle  (vehicle-label vehicle-id vehicles)
  =/  date  (trip (format-da:render `@da`(cell-atom %observed-start row)))
  =/  derived  (~(get by derivations) (cell-atom %acquisition-id row))
  =/  interval=(unit interval-proof)
    ?~  derived
      ~
    interval.u.derived
  =/  economy=(unit economy-proof)
    ?~  derived
      ~
    economy.u.derived
  =/  tank  (rows-by %vehicle-id vehicle-id tank-sizes)
  =/  break-reason=(unit @tas)
    ?~  derived
      ~
    break-reason.u.derived
  =/  break-label=tape
    ?~(break-reason ~ (weld "%" (trip (scot %tas u.break-reason))))
  =/  break-text=tape
    ?~(break-reason ~ (trip (economy-break-text u.break-reason)))
  =/  broken  !=(~ break-label)
  =/  display=tape
    ?+  mode  "Unavailable"
      %distance
        ?~  interval
          "Unavailable"
        ;:  weld
          (trip (format-scaled:render distance-milli.u.interval 3 %.n))
          " "
          (trip (scot %tas distance-unit.u.interval))
        ==
      %time
        ?~  interval
          "Unavailable"
        =/  hours-milli
          (div (add (mul elapsed-seconds.u.interval 1.000) 1.800) 3.600)
        (weld (trip (format-scaled:render hours-milli 3 %.n)) " h")
      %tank
        ?:  ?|  ?=(~ economy)
                !=(1 (lent tank))
            ==
          "Unavailable"
        =/  tank-row  (snag 0 tank)
        =/  places  (cell-atom %decimals tank-row)
        ?:  (gth places 3)
          "Unavailable"
        =/  tank-milli
          (mul (cell-atom %digits tank-row) (pow-ten:render (sub 3 places)))
        =/  distance-milli
          (div (add (mul milli.u.economy tank-milli) 500) 1.000)
        ;:  weld
          (trip (format-scaled:render distance-milli 3 %.n))
          " "
          ?:  =('mpg' unit.u.economy)
            "mi"
          "km"
        ==
    ==
  =/  reason=tape
    ?:  broken
      break-text
    ?+  mode  "An eligible interval is required."
      %distance  "Adjacent odometer-linked full fills are required."
      %time  "Two eligible ordered fills are required for the selected vehicle."
      %tank  "Tank size and an eligible economy interval are required; Rover never guesses tank size."
    ==
  =/  attribute=tape
    ?:  =("Unavailable" display)
      ~
    ?+  mode  ~
      %distance  (weld " data-distance-between-fills=\"" (weld display "\""))
      %time  (weld " data-time-between-fills=\"" (weld display "\""))
      %tank  (weld " data-distance-per-tank=\"" (weld display "\""))
    ==
  ;:  weld
    "<tr data-statistics-vehicle=\""
    (escape vehicle)
    "\""
    attribute
    ?:  broken
      (weld " data-interval-break=\"" (weld break-label "\""))
    ""
    "><td>"
    date
    "</td><td>"
    display
    "</td><td>"
    ?:(=("Unavailable" display) reason "Eligible full-fill interval.")
    "</td></tr>"
    rest
  ==
::
++  statistic-fill-rows
  |=  $:  fills=(list vector:ast)
          vehicles=(list vector:ast)
          subtype-links=(list vector:ast)
          derivations=(map @ derived-fill)
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
  =/  derived  (~(get by derivations) acquisition)
  =/  economy=(unit economy-proof)
    ?~  derived
      ~
    economy.u.derived
  =/  break-reason=(unit @tas)
    ?~  derived
      ~
    break-reason.u.derived
  =/  break-label=tape
    ?~(break-reason ~ (weld "%" (trip (scot %tas u.break-reason))))
  =/  break-text=tape
    ?~(break-reason ~ (trip (economy-break-text u.break-reason)))
  =/  broken  !=(~ break-label)
  =/  rendered=tape
    ?+  mode  ~
      %economy
        ;:  weld
          "<tr data-statistics-vehicle=\""
          (escape vehicle)
          "\" data-economy-vehicle=\""
          (escape vehicle)
          "\" data-economy=\""
          ?~(economy "Unavailable" (weld (trip (format-scaled:render milli.u.economy 3 %.n)) (weld " " (trip unit.u.economy))))
          "\""
          ?:  broken
            (weld " data-economy-break=\"" (weld break-label "\""))
          ""
          "><td>"
          date
          "</td><td>"
          ?:(?=(~ subtype) "Not recorded" (escape (cell-text %subtype i.subtype)))
          "</td><td>"
          ?~(economy "Unavailable" (weld (trip (format-scaled:render milli.u.economy 3 %.n)) (weld " " (trip unit.u.economy))))
          "</td><td>"
          ?:  ?=(~ economy)
            ?:  broken
              break-text
            "An eligible adjacent full-fill interval is required."
          "Eligible full-fill interval."
          "</td></tr>"
        ==
      %cost
        ;:  weld
          "<tr data-statistics-vehicle=\""
          (escape vehicle)
          "\" data-fuel-cost=\""
          (escape total)
          "\"><td>"
          date
          "</td><td>"
          (escape total)
          "</td></tr>"
        ==
      %price
        ;:  weld
          "<tr data-statistics-vehicle=\""
          (escape vehicle)
          "\" data-average-price=\""
          (escape price)
          "\"><td>"
          date
          "</td><td>"
          (escape price)
          "</td></tr>"
        ==
    ==
  (weld rendered $(fills t.fills))
::
++  sum-unit-prices
  |=  rows=(list vector:ast)
  ^-  @ud
  ?~(rows 0 (add (cell-atom %unit-price-mills i.rows) $(rows t.rows)))
::
++  same-price-context
  |=  [currency=@tas quantity-unit=@tas rows=(list vector:ast)]
  ^-  ?
  ?~  rows
    %.y
  ?&  =(currency (cell-term %currency i.rows))
      =(quantity-unit (cell-term %quantity-unit i.rows))
      $(rows t.rows)
  ==
::
++  average-price-stat-rows
  |=  [vehicles=(list vector:ast) fills=(list vector:ast)]
  ^-  tape
  ?~  vehicles
    ~
  =/  rest  $(vehicles t.vehicles)
  ?:  =(0 (cell-atom %archived i.vehicles))
    rest
  =/  vehicle-id  (cell-atom %vehicle-id i.vehicles)
  =/  scoped  (rows-for vehicle-id fills)
  ?~  scoped
    rest
  =/  vehicle  (cell-text %label i.vehicles)
  =/  currency  (cell-term %currency i.scoped)
  =/  quantity-unit  (cell-term %quantity-unit i.scoped)
  =/  compatible  (same-price-context currency quantity-unit scoped)
  =/  count  (lent scoped)
  =/  display=@t
    ?.  compatible
      'Unavailable'
    =/  mean
      (div (add (sum-unit-prices scoped) (div count 2)) count)
    (format-unit-price:render mean currency)
  ;:  weld
    "<tr data-statistics-vehicle=\""
    (escape vehicle)
    "\" data-average-price=\""
    (escape display)
    "\"><td>Lifetime</td><td>"
    (scow %ud count)
    "</td><td>"
    (escape display)
    "</td><td>"
    ?:  compatible
      ;:  weld
        (escape (scot %tas currency))
        " per "
        (escape (scot %tas quantity-unit))
        "; exact half-up mean."
      ==
    "Incompatible currencies or quantity units are not averaged."
    "</td></tr>"
    rest
  ==
::
++  statistic-owned-row
  |=  [row=vector:ast spans=(list ownership-interval)]
  ^-  ?
  ?~  spans
    %.y
  =/  date=@da  `@da`(cell-atom %observed-start row)
  ?~  (ownership-segment spans date)
    %.n
  %.y
::
++  empty-cost-tally
  ^-  cost-tally
  [0 (sun:si 0) ~ ~ %.y]
::
++  add-cost-tally
  |=  $:  amount=@ud
          currency=@tas
          minor-decimals=@ud
          credit=?
          tally=cost-tally
      ==
  ^-  cost-tally
  =/  signed=@sd  (new:si ?:(credit %.n %.y) amount)
  =/  same-context=?
    ?~  currency.tally
      %.y
    ?~  minor-decimals.tally
      %.n
    ?&  =(u.currency.tally currency)
        =(u.minor-decimals.tally minor-decimals)
    ==
  :*  +(entries.tally)
      (sum:si total.tally signed)
      ?~(currency.tally `currency currency.tally)
      ?~(minor-decimals.tally `minor-decimals minor-decimals.tally)
      ?&(compatible.tally same-context)
  ==
::
++  merge-cost-tallies
  |=  [a=cost-tally b=cost-tally]
  ^-  cost-tally
  ?:  =(0 entries.a)
    b
  ?:  =(0 entries.b)
    a
  :*  (add entries.a entries.b)
      (sum:si total.a total.b)
      currency.a
      minor-decimals.a
      ?&  compatible.a
          compatible.b
          =(currency.a currency.b)
          =(minor-decimals.a minor-decimals.b)
      ==
  ==
::
++  purchase-cost-tally
  |=  $:  rows=(list vector:ast)
          spans=(list ownership-interval)
          tally=cost-tally
      ==
  ^-  cost-tally
  ?~  rows
    tally
  ?.  (statistic-owned-row i.rows spans)
    $(rows t.rows)
  =/  proof
    %:  derive-fill-total:act
        (cell-atom %quantity-milli i.rows)
        (cell-atom %unit-price-mills i.rows)
        (cell-atom %minor-unit-decimals i.rows)
        (cell-atom %cash-increment-mills i.rows)
        ;;(settlement-mode:rover (cell-term %settlement-mode i.rows))
    ==
  =/  next
    %:  add-cost-tally
        total-mills.proof
        (cell-term %currency i.rows)
        (cell-atom %minor-unit-decimals i.rows)
        %.n
        tally
    ==
  $(rows t.rows, tally next)
::
++  event-cost-tally
  |=  $:  rows=(list vector:ast)
          cost-index=(map @ (list vector:ast))
          total-index=(map @ (list vector:ast))
          spans=(list ownership-interval)
          credit=?
          tally=cost-tally
      ==
  ^-  cost-tally
  ?~  rows
    tally
  ?.  (statistic-owned-row i.rows spans)
    $(rows t.rows)
  =/  event-id  (cell-atom %event-id i.rows)
  =/  cost  (one-indexed-row event-id cost-index)
  =/  total-row  (one-indexed-row event-id total-index)
  ?:  ?|(?=(~ cost) ?=(~ total-row))
    $(rows t.rows)
  =/  next
    %:  add-cost-tally
        (cell-atom %total-mills u.total-row)
        (cell-term %currency u.cost)
        (cell-atom %minor-unit-decimals u.cost)
        credit
        tally
    ==
  $(rows t.rows, tally next)
::
++  cost-tally-attribute
  |=  tally=cost-tally
  ^-  tape
  (trip (format-sscaled:render total.tally 0 %.n))
::
++  cost-tally-money
  |=  tally=cost-tally
  ^-  @t
  ?:  ?|  =(0 entries.tally)
          =(%.n compatible.tally)
          ?=(~ currency.tally)
          ?=(~ minor-decimals.tally)
      ==
    'Unavailable'
  =/  minor-scale  (pow-ten:render u.minor-decimals.tally)
  =/  mill-step  (div 1.000 minor-scale)
  =/  minor-units  (div (abs:si total.tally) mill-step)
  =/  number
    (format-scaled:render minor-units u.minor-decimals.tally %.y)
  =/  amount=tape
    ;:  weld
      (currency-prefix:render u.currency.tally)
      (trip number)
    ==
  ?:  (syn:si total.tally)
    (crip amount)
  (crip ['-' amount])
::
++  statistic-row-in-interval
  |=  [row=vector:ast span=ownership-interval]
  ^-  ?
  =/  date=@da  `@da`(cell-atom %observed-start row)
  ?&  ?~(start.span %.y (gte date u.start.span))
      ?~(end.span %.y (lte date u.end.span))
  ==
::
++  ownership-distance-proof
  |=  $:  odometers=(list vector:ast)
          span=(unit ownership-interval)
      ==
  ^-  (unit distance-proof)
  =/  scoped=(list vector:ast)
    ?~  span
      odometers
    %+  skim  odometers
    |=  row=vector:ast
    (statistic-row-in-interval row u.span)
  =/  ordered  (order-vectors:act %observed-start %.n scoped)
  ?~  ordered
    ~
  ?~  t.ordered
    ~
  =/  first=vector:ast  i.ordered
  =/  last-row  (last-vector ordered)
  ?~  last-row
    ~
  =/  last=vector:ast  u.last-row
  =/  first-places  (cell-atom %decimal-places first)
  =/  last-places  (cell-atom %decimal-places last)
  ?:  ?|  (gth first-places 3)
          (gth last-places 3)
          !=((cell-term %unit first) (cell-term %unit last))
      ==
    ~
  =/  first-milli
    (mul (cell-atom %value-digits first) (pow-ten:render (sub 3 first-places)))
  =/  last-milli
    (mul (cell-atom %value-digits last) (pow-ten:render (sub 3 last-places)))
  ?.  (gth last-milli first-milli)
    ~
  `[(sub last-milli first-milli) (cell-term %unit last)]
::
++  cost-per-distance-value
  |=  [tally=cost-tally distance=distance-proof]
  ^-  @sd
  =/  magnitude
    (round-div-half-up:act (mul (abs:si total.tally) 1.000) milli.distance)
  (new:si (syn:si total.tally) magnitude)
::
++  cost-per-distance-money
  |=  [value=@sd currency=@tas distance-unit=@tas]
  ^-  @t
  =/  number  (format-scaled:render (abs:si value) 3 %.y)
  =/  amount=tape
    ;:  weld
      (currency-prefix:render currency)
      (trip number)
      "/"
      (trip (scot %tas distance-unit))
    ==
  ?:  (syn:si value)
    (crip amount)
  (crip ['-' amount])
::
++  total-cost-tally
  |=  $:  cost-rows=statistics-cost-rows
          cost-index=(map @ (list vector:ast))
          total-index=(map @ (list vector:ast))
          spans=(list ownership-interval)
      ==
  ^-  cost-tally
  =/  total
    (purchase-cost-tally fuels.cost-rows spans empty-cost-tally)
  =.  total
    %+  merge-cost-tallies  total
    (purchase-cost-tally consumables.cost-rows spans empty-cost-tally)
  =.  total
    %+  merge-cost-tallies  total
    (event-cost-tally services.cost-rows cost-index total-index spans %.n empty-cost-tally)
  =.  total
    %+  merge-cost-tallies  total
    (event-cost-tally expenses.cost-rows cost-index total-index spans %.n empty-cost-tally)
  =.  total
    %+  merge-cost-tallies  total
    (event-cost-tally notes.cost-rows cost-index total-index spans %.n empty-cost-tally)
  =.  total
    %+  merge-cost-tallies  total
    (event-cost-tally acquisitions.cost-rows cost-index total-index spans %.n empty-cost-tally)
  %+  merge-cost-tallies  total
  (event-cost-tally disposals.cost-rows cost-index total-index spans %.y empty-cost-tally)
::
++  ownership-interval-label
  |=  [span=ownership-interval index=@ud]
  ^-  tape
  ;:  weld
    "Ownership interval "
    (scow %ud +(index))
    " ("
    ?~(start.span "first record" (trip (format-da:render u.start.span)))
    " to "
    ?~(end.span "present" (trip (format-da:render u.end.span)))
    ")"
  ==
::
++  ownership-interval-cost-rows
  |=  $:  spans=(list ownership-interval)
          index=@ud
          cost-rows=statistics-cost-rows
          cost-index=(map @ (list vector:ast))
          total-index=(map @ (list vector:ast))
      ==
  ^-  tape
  ?~  spans
    ~
  =/  tally
    (total-cost-tally cost-rows cost-index total-index [i.spans ~])
  =/  distance
    (ownership-distance-proof vehicle-odometers.cost-rows `i.spans)
  =/  row=tape
    ?:  ?|  =(0 entries.tally)
            =(%.n compatible.tally)
        ==
      ;:  weld
        "<tr data-ownership-interval=\""
        (scow %ud +(index))
        "\" data-interval-unavailable><td>"
        (ownership-interval-label i.spans index)
        "</td><td>Unavailable</td><td>Compatible costs and two increasing odometer readings are required inside this ownership interval.</td></tr>"
      ==
    ?~  currency.tally
      ;:  weld
        "<tr data-ownership-interval=\""
        (scow %ud +(index))
        "\" data-interval-unavailable><td>"
        (ownership-interval-label i.spans index)
        "</td><td>Unavailable</td><td>Compatible costs and two increasing odometer readings are required inside this ownership interval.</td></tr>"
      ==
    ?~  distance
      ;:  weld
        "<tr data-ownership-interval=\""
        (scow %ud +(index))
        "\" data-interval-unavailable><td>"
        (ownership-interval-label i.spans index)
        "</td><td>Unavailable</td><td>Compatible costs and two increasing odometer readings are required inside this ownership interval.</td></tr>"
      ==
    =/  value  (cost-per-distance-value tally u.distance)
    ;:  weld
      "<tr data-ownership-interval=\""
      (scow %ud +(index))
      "\" data-interval-total-mills=\""
      (cost-tally-attribute tally)
      "\" data-interval-cost-per-distance-mills=\""
      (trip (format-sscaled:render value 0 %.n))
      "\"><td>"
      (ownership-interval-label i.spans index)
      "</td><td>"
      (escape (cost-tally-money tally))
      "</td><td>"
      (escape (cost-per-distance-money value u.currency.tally unit.u.distance))
      "</td></tr>"
    ==
  (weld row $(spans t.spans, index +(index)))
::
++  cost-per-distance-statistic
  |=  $:  tally=cost-tally
          odometers=(list vector:ast)
          spans=(list ownership-interval)
          interval-rows=tape
          vehicle-label=@t
      ==
  ^-  tape
  =/  row=tape
    ?:  (gth (lent spans) 1)
      "<tr data-cost-per-distance-unavailable=\"ownership-gap\"><td>Lifetime</td><td>Unavailable</td><td>The vehicle was not owned for part of this interval, so the derived value is unavailable.</td></tr>"
    ?:  ?|  =(0 entries.tally)
            =(%.n compatible.tally)
            ?=(~ currency.tally)
        ==
      "<tr data-cost-per-distance-unavailable=\"cost\"><td>Lifetime</td><td>Unavailable</td><td>Compatible recorded costs are required.</td></tr>"
    =/  span=(unit ownership-interval)
      ?~  spans
        ~
      `i.spans
    =/  distance  (ownership-distance-proof odometers span)
    ?~  distance
      "<tr data-cost-per-distance-unavailable=\"distance\"><td>Lifetime</td><td>Unavailable</td><td>Two increasing odometer readings in one distance unit are required within the ownership interval.</td></tr>"
    =/  value  (cost-per-distance-value tally u.distance)
    ;:  weld
      "<tr data-cost-per-distance-mills=\""
      (trip (format-sscaled:render value 0 %.n))
      "\"><td>Lifetime</td><td>"
      (escape (cost-per-distance-money value u.currency.tally unit.u.distance))
      "</td><td>Total ownership cost over "
      (trip (format-scaled:render milli.u.distance 3 %.y))
      " "
      (trip (scot %tas unit.u.distance))
      ".</td></tr>"
    ==
  ;:  weld
    "<section class=\"stat-table\" data-statistic=\"cost-per-distance\" data-statistics-vehicle=\""
    (escape vehicle-label)
    "\"><h2>Cost per distance, all-in</h2><table><thead><tr><th>Period</th><th>Cost per distance</th><th>Basis</th></tr></thead><tbody>"
    row
    interval-rows
    "</tbody></table></section>"
  ==
::
++  spend-family-row
  |=  [family=@tas label=@t tally=cost-tally]
  ^-  tape
  ;:  weld
    "<tr data-cost-family=\""
    (escape (scot %tas family))
    "\""
    ?:  ?&  (gth entries.tally 0)
            compatible.tally
        ==
      ;:  weld
        " data-family-total-mills=\""
        (cost-tally-attribute tally)
        "\""
      ==
    ""
    "><td>"
    (escape label)
    "</td><td>"
    (scow %ud entries.tally)
    "</td><td>"
    ?:(=(0 entries.tally) "No costs recorded" (escape (cost-tally-money tally)))
    "</td></tr>"
  ==
::
++  service-summary-group-rows
  |=  $:  groups=(list [@ (list vector:ast)])
          cost-index=(map @ (list vector:ast))
          total-index=(map @ (list vector:ast))
          spans=(list ownership-interval)
      ==
  ^-  tape
  ?~  groups
    ~
  =/  label=@t  `@t`-.i.groups
  =/  rows=(list vector:ast)  +.i.groups
  =/  tally
    %:  event-cost-tally
        rows
        cost-index
        total-index
        spans
        %.n
        empty-cost-tally
    ==
  ;:  weld
    "<tr data-service-subtype=\""
    (escape label)
    "\" data-service-count=\""
    (scow %ud (lent rows))
    "\""
    ?:  =(0 entries.tally)
      ""
    ;:  weld
      " data-service-total-mills=\""
      (cost-tally-attribute tally)
      "\""
    ==
    "><td>"
    (escape label)
    "</td><td>"
    (scow %ud (lent rows))
    "</td><td>"
    ?:(=(0 entries.tally) "No costs recorded" (escape (cost-tally-money tally)))
    "</td></tr>"
    $(groups t.groups)
  ==
::
++  service-summary-rows
  |=  $:  subtype-rows=(list vector:ast)
          service-rows=(list vector:ast)
          cost-index=(map @ (list vector:ast))
          total-index=(map @ (list vector:ast))
          spans=(list ownership-interval)
      ==
  ^-  tape
  =/  owned-subtypes=(list vector:ast)
    %+  skim  subtype-rows
    |=  row=vector:ast
    (statistic-owned-row row spans)
  =/  owned-services=(list vector:ast)
    %+  skim  service-rows
    |=  row=vector:ast
    (statistic-owned-row row spans)
  ?~  owned-services
    "<tr class=\"empty-state\" data-service-empty><td colspan=\"3\">No service events recorded for this vehicle.</td></tr>"
  =/  groups
    (index-rows %service-subtype owned-subtypes *(map @ (list vector:ast)))
  =/  rendered
    (service-summary-group-rows ~(tap by groups) cost-index total-index spans)
  ?:  ?=(^ rendered)
    rendered
  "<tr class=\"empty-state\" data-service-subtype-empty><td colspan=\"3\">Service events have no subtype recorded.</td></tr>"
::
++  rows-in-statistic-span
  |=  [rows=(list vector:ast) span=ownership-interval]
  ^-  (list vector:ast)
  %+  skim  rows
  |=  row=vector:ast
  (statistic-row-in-interval row span)
::
++  ownership-interval-spend-rows
  |=  $:  spans=(list ownership-interval)
          index=@ud
          cost-rows=statistics-cost-rows
          cost-index=(map @ (list vector:ast))
          total-index=(map @ (list vector:ast))
      ==
  ^-  tape
  ?~  spans
    ~
  =/  one-span  [i.spans ~]
  =/  fuel
    (purchase-cost-tally fuels.cost-rows one-span empty-cost-tally)
  =/  consumables
    (purchase-cost-tally consumables.cost-rows one-span empty-cost-tally)
  =/  service
    (event-cost-tally services.cost-rows cost-index total-index one-span %.n empty-cost-tally)
  =/  expense
    (event-cost-tally expenses.cost-rows cost-index total-index one-span %.n empty-cost-tally)
  =/  note
    (event-cost-tally notes.cost-rows cost-index total-index one-span %.n empty-cost-tally)
  =/  acquisition
    (event-cost-tally acquisitions.cost-rows cost-index total-index one-span %.n empty-cost-tally)
  =/  disposal
    (event-cost-tally disposals.cost-rows cost-index total-index one-span %.y empty-cost-tally)
  ;:  weld
    "<tr class=\"ownership-interval-heading\" data-ownership-interval=\""
    (scow %ud +(index))
    "\"><th colspan=\"3\">"
    (ownership-interval-label i.spans index)
    "</th></tr>"
    (spend-family-row %service 'Service' service)
    (spend-family-row %expense 'Expense' expense)
    (spend-family-row %fuel 'Fuel' fuel)
    (spend-family-row %consumables 'Consumables' consumables)
    (spend-family-row %acquisition 'Acquisition' acquisition)
    (spend-family-row %disposal 'Disposal proceeds' disposal)
    (spend-family-row %note 'Notes' note)
    $(spans t.spans, index +(index))
  ==
::
++  ownership-interval-service-rows
  |=  $:  spans=(list ownership-interval)
          index=@ud
          cost-rows=statistics-cost-rows
          cost-index=(map @ (list vector:ast))
          total-index=(map @ (list vector:ast))
      ==
  ^-  tape
  ?~  spans
    ~
  ;:  weld
    "<tr class=\"ownership-interval-heading\" data-service-ownership-interval=\""
    (scow %ud +(index))
    "\"><th colspan=\"3\">"
    (ownership-interval-label i.spans index)
    "</th></tr>"
    %:  service-summary-rows
        (rows-in-statistic-span service-subtypes.cost-rows i.spans)
        (rows-in-statistic-span services.cost-rows i.spans)
        cost-index
        total-index
        [i.spans ~]
    ==
    $(spans t.spans, index +(index))
  ==
::
++  ownership-cost-statistics
  |=  $:  cost-rows=statistics-cost-rows
          spans=(list ownership-interval)
          vehicle-label=@t
      ==
  ^-  tape
  =/  cost-index
    (index-rows %event-id costs.cost-rows *(map @ (list vector:ast)))
  =/  total-index
    (index-rows %event-id totals.cost-rows *(map @ (list vector:ast)))
  =/  fuel
    (purchase-cost-tally fuels.cost-rows spans empty-cost-tally)
  =/  consumables
    (purchase-cost-tally consumables.cost-rows spans empty-cost-tally)
  =/  service
    (event-cost-tally services.cost-rows cost-index total-index spans %.n empty-cost-tally)
  =/  expense
    (event-cost-tally expenses.cost-rows cost-index total-index spans %.n empty-cost-tally)
  =/  note
    (event-cost-tally notes.cost-rows cost-index total-index spans %.n empty-cost-tally)
  =/  acquisition
    (event-cost-tally acquisitions.cost-rows cost-index total-index spans %.n empty-cost-tally)
  =/  disposal
    (event-cost-tally disposals.cost-rows cost-index total-index spans %.y empty-cost-tally)
  =/  total
    (merge-cost-tallies fuel consumables)
  =.  total  (merge-cost-tallies total service)
  =.  total  (merge-cost-tallies total expense)
  =.  total  (merge-cost-tallies total note)
  =.  total  (merge-cost-tallies total acquisition)
  =.  total  (merge-cost-tallies total disposal)
  =/  crosses-gap=?  (gth (lent spans) 1)
  =/  interval-rows=tape
    ?.  crosses-gap
      ~
    (ownership-interval-cost-rows spans 0 cost-rows cost-index total-index)
  =/  total-row=tape
    ?:  crosses-gap
      "<tr data-total-cost-unavailable=\"ownership-gap\"><td>Lifetime</td><td>Unavailable: The vehicle was not owned for part of this interval, so the derived value is unavailable.</td></tr>"
    ?:  =(0 entries.total)
      "<tr class=\"empty-state\"><td colspan=\"2\">No costs recorded for this vehicle.</td></tr>"
    ?.  compatible.total
      "<tr data-total-cost-unavailable><td>Lifetime</td><td>Unavailable: recorded costs use more than one currency.</td></tr>"
    ;:  weld
      "<tr data-total-cost-mills=\""
      (cost-tally-attribute total)
      "\"><td>Lifetime</td><td>"
      (escape (cost-tally-money total))
      "</td></tr>"
    ==
  ;:  weld
    "<section class=\"stat-table\" data-statistic=\"total-cost-of-ownership\" data-statistics-vehicle=\""
    (escape vehicle-label)
    "\"><h2>Total cost of ownership</h2><table><thead><tr><th>Period</th><th>Total</th></tr></thead><tbody>"
    total-row
    "</tbody></table></section>"
    (cost-per-distance-statistic total vehicle-odometers.cost-rows spans interval-rows vehicle-label)
    "<section class=\"stat-table\" data-statistic=\"spend-by-family\" data-statistics-vehicle=\""
    (escape vehicle-label)
    "\"><h2>Spend by family</h2><table><thead><tr><th>Family</th><th>Records</th><th>Total</th></tr></thead><tbody>"
    ?:  crosses-gap
      (ownership-interval-spend-rows spans 0 cost-rows cost-index total-index)
    ;:  weld
      (spend-family-row %service 'Service' service)
      (spend-family-row %expense 'Expense' expense)
      (spend-family-row %fuel 'Fuel' fuel)
      (spend-family-row %consumables 'Consumables' consumables)
      (spend-family-row %acquisition 'Acquisition' acquisition)
      (spend-family-row %disposal 'Disposal proceeds' disposal)
      (spend-family-row %note 'Notes' note)
    ==
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"service-history-summary\" data-statistics-vehicle=\""
    (escape vehicle-label)
    "\"><h2>Service history summary</h2><table><thead><tr><th>Service subtype</th><th>Events</th><th>Total</th></tr></thead><tbody>"
    ?:  crosses-gap
      (ownership-interval-service-rows spans 0 cost-rows cost-index total-index)
    %:  service-summary-rows
        service-subtypes.cost-rows
        services.cost-rows
        cost-index
        total-index
        spans
    ==
    "</tbody></table></section>"
  ==
::
++  statistics-screen
  |=  $:  fills=(list vector:ast)
          vehicles=(list vector:ast)
          app-default=(list vector:ast)
          subtype-links=(list vector:ast)
          tank-sizes=(list vector:ast)
          def-purchases=(list vector:ast)
          def-odometers=(list vector:ast)
          derivations=(map @ derived-fill)
          ownership=(map @ (list ownership-interval))
          cost-rows=statistics-cost-rows
          selected-vehicle=(unit vector:ast)
          history-page=@ud
      ==
  ^-  tape
  =/  history-window-size=@ud  25
  =/  scoped-fills=(list vector:ast)
    ?~  selected-vehicle
      ~
    (rows-for (cell-atom %vehicle-id u.selected-vehicle) fills)
  =/  scoped-vehicles=(list vector:ast)
    ?~  selected-vehicle
      ~
    [u.selected-vehicle ~]
  =/  scoped-def-purchases=(list vector:ast)
    ?~  selected-vehicle
      ~
    (rows-for (cell-atom %vehicle-id u.selected-vehicle) def-purchases)
  =/  all-recent  (order-vectors:act %observed-start %.y scoped-fills)
  =/  recent
    (scag history-window-size (slag (mul history-page history-window-size) all-recent))
  =/  default-label=(unit @t)
    ?~  selected-vehicle
      ~
    `(cell-text %label u.selected-vehicle)
  =/  selected-spans=(list ownership-interval)
    ?~  selected-vehicle
      ~
    (~(gut by ownership) (cell-atom %vehicle-id u.selected-vehicle) ~)
  =/  scope-header=tape
    ?~  default-label
      "<p id=\"statistics-vehicle-name\" data-statistics-scope-heading data-statistics-no-default>No default vehicle set.</p>"
    ;:  weld
      "<p id=\"statistics-vehicle-name\" data-statistics-scope-heading data-statistics-vehicle=\""
      (escape u.default-label)
      "\">"
      (escape u.default-label)
      "</p>"
    ==
  =/  selector=tape
    ;:  weld
      "<label>Vehicle<select id=\"statistics-vehicle-select\">"
      ?~(default-label "<option value=\"\" selected>Select a vehicle</option>" "")
      (vehicle-options vehicles)
      "</select></label>"
    ==
  ?:  ?&  ?=(~ scoped-fills)
          ?=(~ scoped-def-purchases)
          ?=(~ fuels.cost-rows)
          ?=(~ consumables.cost-rows)
          ?=(~ events.cost-rows)
      ==
    ;:  weld
      "<section id=\"statistics-screen\" class=\"app-screen\" hidden data-view-vehicle=\""
      ?~(default-label "" (escape u.default-label))
      "\"><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER ANALYSIS</p><h1>STATISTICS</h1>"
      scope-header
      "</header>"
      selector
      "<div class=\"empty-state\" data-statistics-state=\"no-data\"><h2>No data yet</h2><p>Add a fill to begin tracking economy.</p></div></section>"
    ==
  ;:  weld
    "<section id=\"statistics-screen\" class=\"app-screen\" hidden data-view-vehicle=\""
    ?~(default-label "" (escape u.default-label))
    "\"><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER ANALYSIS</p><h1>STATISTICS</h1>"
    scope-header
    "</header>"
    selector
    "<p id=\"statistics-empty\" class=\"empty\" hidden>No statistics are recorded for this vehicle.</p>"
    (ownership-cost-statistics cost-rows selected-spans ?~(default-label '' u.default-label))
    "<section class=\"stat-table\" data-statistic=\"economy-by-subtype\"><h2>Economy per fill by fuel subtype</h2><table><thead><tr><th>Date</th><th>Fuel subtype</th><th>Economy</th><th>Eligibility</th></tr></thead><tbody>"
    (statistic-fill-rows recent scoped-vehicles subtype-links derivations %economy)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"fuel-costs\"><h2>Fuel costs</h2><table><thead><tr><th>Date</th><th>Total cost</th></tr></thead><tbody>"
    (statistic-fill-rows recent scoped-vehicles subtype-links derivations %cost)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"distance-between-fills\"><h2>Distance between fills</h2><table><thead><tr><th>Date</th><th>Distance</th><th>Eligibility</th></tr></thead><tbody>"
    (statistic-interval-rows recent scoped-vehicles tank-sizes derivations %distance)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"time-between-fills\"><h2>Time between fills</h2><table><thead><tr><th>Date</th><th>Elapsed time</th><th>Eligibility</th></tr></thead><tbody>"
    (statistic-interval-rows recent scoped-vehicles tank-sizes derivations %time)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"average-price-per-unit\"><h2>Average price per unit - lifetime</h2><table><thead><tr><th>Period</th><th>Fills</th><th>Mean unit price</th><th>Basis</th></tr></thead><tbody>"
    (average-price-stat-rows scoped-vehicles scoped-fills)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"distance-per-tank\"><h2>Distance per tank</h2><table><thead><tr><th>Date</th><th>Estimated distance</th><th>Eligibility</th></tr></thead><tbody>"
    (statistic-interval-rows recent scoped-vehicles tank-sizes derivations %tank)
    "</tbody></table></section>"
    "<section class=\"stat-table\" data-statistic=\"def-economy\"><h2>DEF economy</h2><table><thead><tr><th>Distance per DEF unit</th><th>Eligibility</th></tr></thead><tbody>"
    (def-economy-stat-rows scoped-vehicles scoped-def-purchases def-odometers ownership)
    "</tbody></table></section>"
    (pagination-controls history-page (lent all-recent) 'statistics-screen')
    "</section>"
  ==
::
++  page
  |=  $:  ship=@p
          now=@da
          history-page=@ud
          selected-label=(unit @t)
          commands=(list cmd-result:ast)
      ==
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
  =/  energy-odometers  (rows-at commands 22)
  =/  starter-definitions  (rows-at commands 23)
  =/  fill-driving-modes  (rows-at commands 24)
  =/  fill-average-speeds  (rows-at commands 25)
  =/  fill-drive-balances  (rows-at commands 26)
  =/  fill-notes  (rows-at commands 27)
  =/  fill-payment-links  (rows-at commands 28)
  =/  payment-methods  (rows-at commands 29)
  =/  consumables  (rows-at commands 30)
  =/  fill-tags  (rows-at commands 31)
  =/  available-modes  (rows-at commands 32)
  =/  vehicle-consumables  (rows-at commands 33)
  =/  consumable-tank-sizes  (rows-at commands 34)
  =/  def-purchases  (rows-at commands 35)
  =/  def-odometers  (rows-at commands 36)
  =/  localities  (rows-at commands 37)
  =/  refill-reserves  (rows-at commands 38)
  =/  costs=charging-cost-rows
    [(rows-at commands 39) (rows-at commands 40)]
  =/  events=event-rows
    :*  (rows-at commands 41)
        (rows-at commands 42)
        (rows-at commands 43)
        (rows-at commands 44)
        (rows-at commands 45)
        (rows-at commands 46)
        (rows-at commands 47)
        (rows-at commands 48)
        (rows-at commands 49)
        (rows-at commands 50)
        (rows-at commands 51)
        (rows-at commands 52)
        (rows-at commands 54)
        (rows-at commands 55)
    ==
  =/  service-subtypes  (rows-at commands 53)
  =/  disposal-kinds  (rows-at commands 56)
  ::  M7 T6. The reminder family. Four single-relation queries, joined here by
  ::  ID rather than by the engine, so no fresh database meets a three-way join
  ::  whose leftmost relation is empty.
  =/  reminders=reminder-rows
    :*  (rows-at commands 57)
        (rows-at commands 58)
        (rows-at commands 59)
        (rows-at commands 60)
    ==
  =/  custom-definitions  (rows-at commands 18)
  ::  M7 T8. The eight definition families the Definitions panel manages. Custom
  ::  fields are the ninth and keep their own panel, because they carry a
  ::  content type and a mandatory flag that no other family has.
  ::
  ::  Every list here was already read by the view. T8 added no query, no
  ::  relation, and no column: `archived` was written on the first pour of each
  ::  of these families and every selector already reads it.
  =/  definition-panel-rows=(list [family=@t title=@t rows=(list vector:ast)])
    :~  ['energy' 'Energy sources' starter-definitions]
        ['driving-mode' 'Driving modes' available-modes]
        ['consumable' 'Consumables' consumables]
        ['service-subtype' 'Service subtypes' service-subtypes]
        ['disposal-kind' 'Disposal kinds' disposal-kinds]
        ['additive' 'Additives' additives]
        ['tag' 'Tags' tags]
        ['payment-method' 'Payment methods' payment-methods]
    ==
  ::  M7 T7. The specification family, keyed by relation name. `spec-view-order`
  ::  is the one list that decides the query order, so the render never counts
  ::  indices by hand and a fourteenth field costs one entry there.
  =/  specs=spec-index
    =/  order  spec-view-order:act
    =/  index  61
    |-
    ^-  spec-index
    ?~  order
      ~
    %+  ~(put by $(order t.order, index +(index)))
      relation.i.order
    (rows-at commands index)
  =/  statistic-costs=statistics-cost-rows
    :*  (rows-at commands 74)
        (rows-at commands 75)
        (rows-at commands 76)
        (rows-at commands 77)
        (rows-at commands 78)
        (rows-at commands 79)
        (rows-at commands 80)
        (rows-at commands 81)
        (rows-at commands 82)
        (rows-at commands 83)
        (rows-at commands 84)
        (rows-at commands 85)
        (rows-at commands 86)
    ==
  =/  definition-html  (definition-options definition-rows vehicles)
  =/  starter-html  (starter-definition-options starter-definitions)
  =/  starter-subtype-html  (subtype-options subtypes)
  =/  starter-mode-html  (vehicle-mode-membership-options available-modes ~)
  =/  default-id=(unit @)
    ?~  app-default
      ~
    `(cell-atom %vehicle-id i.app-default)
  =/  selected-vehicle=(unit vector:ast)
    ?^  selected-label
      (row-by-text %label u.selected-label vehicles)
    ?~  app-default
      ~
    =/  defaults  (rows-by %vehicle-id (cell-atom %vehicle-id i.app-default) vehicles)
    ?~(defaults ~ `i.defaults)
  ::  M7 T5. The ownership map is built once and bounds every interval
  ::  derivation the page renders.
  =/  ownership
    (ownership-index events.events acquisitions.events disposals.events)
  =/  derivations
    (derive-fill-series fills energy-odometers economy-breaks ownership)
  ::  What is due, derived on this read from the stored intervals, the stored
  ::  due points, the clock, and the derived current odometer. Nothing is
  ::  stored and no wakeup is scheduled.
  =/  reminder-html=tape
    ?~  default-id
      ~
    %:  reminder-cards
        u.default-id
        reminders
        service-subtypes
        odometers
        events.events
        services.events
        odometers.events
        (~(gut by ownership) u.default-id ~)
        now
    ==
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
          costs
          energy-odometers
          station-links
          additive-links
          preferences
          subtype-links
          economy-breaks
          subtypes
          default-subtypes
          driving-modes
          starter-definitions
          available-modes
          vehicle-consumables
          consumable-tank-sizes
          tank-sizes
          refill-reserves
          events
          specs
          ?~(default-id %.n =((cell-atom %vehicle-id i.vehicles) u.default-id))
          history-page
      ==
    =/  rest=tape  $(vehicles t.vehicles)
    (weld card rest)
  =/  html=tape
    ;:  weld
      "<span id=\"rover-header-data\" hidden data-ship=\""
      (trip (scot %p ship))
      "\""
      ?~  app-default
        ~
      ;:  weld
        " data-vehicle=\""
        (escape (cell-text %label i.app-default))
        "\""
      ==
      "></span>"
      (address-locality-data localities)
      (main-hub app-default definition-rows odometers tank-sizes refill-reserves fills energy-odometers economy-breaks def-purchases def-odometers derivations ownership reminder-html)
      (entry-screens vehicles odometers definition-rows stations additives subtypes default-subtypes driving-modes tags custom-definitions payment-methods consumables localities service-subtypes disposal-kinds)
      "<section id=\"vehicles-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"main-hub\">&lsaquo; MAIN</button><header class=\"view-header\"><p class=\"eyebrow\">ROVER FLEET</p><h1>VEHICLES</h1></header><button type=\"button\" data-open-screen=\"vehicle-create-screen\">Add Vehicle</button>"
      ?:(?=(~ vehicles) "<p class=\"empty\">No vehicles recorded.</p>" (weld "<ul class=\"vehicle-list\">" (weld (vehicle-list-items vehicles) "</ul>")))
      "<details class=\"archived-vehicles\"><summary>View archived vehicles</summary><ul class=\"vehicle-list\">"
      (archived-vehicle-list-items vehicles)
      "</ul></details>"
      "</section>"
      "<section id=\"vehicle-create-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"vehicles-screen\">&lsaquo; VEHICLES</button><header class=\"view-header\"><p class=\"eyebrow\">NEW VEHICLE</p><h1>ADD VEHICLE</h1></header><form id=\"vehicle-add-form\"><label>Vehicle name<input name=\"label\" required></label><label>Primary Energy Source<select name=\"energy\">"
      starter-html
      "</select></label><label>Additional Energy Sources<select name=\"additionalEnergy\" multiple>"
      starter-html
      "</select></label><label>Default Subtype<select name=\"defaultSubtype\"><option value=\"\">Not set</option>"
      starter-subtype-html
      "</select></label><label>Tank Size<input name=\"tankSize\" inputmode=\"decimal\"></label><label>Tank Unit<select name=\"tankUnit\"><option value=\"gal\">gal</option><option value=\"litre\">litre</option></select></label><label>Driving Modes<select name=\"drivingModes\" multiple>"
      starter-mode-html
      "</select></label><fieldset data-def-configuration hidden><legend>DEF configuration</legend><label><input type=\"checkbox\" name=\"defEnabled\" value=\"yes\"> Enable DEF</label><label>DEF tank size<input name=\"defTankSize\" inputmode=\"decimal\"></label><label>DEF tank unit<select name=\"defTankUnit\"><option value=\"gal\">gal</option><option value=\"litre\">litre</option></select></label></fieldset><label>Distance Display<select name=\"distanceUnit\"><option value=\"native\">Source-native</option><option value=\"mi\">mi</option><option value=\"km\">km</option></select></label><label>Currency Display<select name=\"currency\"><option value=\"usd\">USD</option><option value=\"eur\">EUR</option></select></label><button type=\"submit\">Save Vehicle</button><output class=\"form-verdict\" aria-live=\"polite\"></output></form></section>"
      "<section id=\"vehicle-settings-screen\" class=\"app-screen\" hidden><button type=\"button\" class=\"back-control\" data-open-screen=\"vehicles-screen\">&lsaquo; VEHICLES</button>"
      ?:(?=(~ vehicles) "<p class=\"empty\">No vehicle selected.</p>" cards)
      "</section>"
      (history-screen vehicles fills energy-odometers stations station-links additives additive-links subtypes subtype-links driving-modes fill-driving-modes fill-average-speeds fill-drive-balances fill-notes fill-payment-links economy-breaks tags fill-tags payment-methods selected-vehicle history-page)
      (statistics-screen fills vehicles app-default subtype-links tank-sizes def-purchases def-odometers derivations ownership statistic-costs selected-vehicle history-page)
      (settings-screen custom-definitions definition-panel-rows)
      import-screen
    ==
  (crip html)
--
