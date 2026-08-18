::  lib/rover-export - read the stored facts and render the import payload.
::
::  The export format IS the import format. Every arm here answers one
::  question: what would `+decode-import` have to read to rebuild this row?
::  Nothing derived leaves this file - no total paid, no economy, no current
::  odometer - because the receiving ship derives its own conclusions and a
::  stored derivation would drift from the inputs beside it.
::
::  Reads are WIDE and carry the primary key of every row. A narrow projection
::  collapses identical rows in the pinned engine, so `SELECT R.reason` over
::  the whole of `economy-breaks` returns ONE row for a thousand fills. Reads
::  also never join: the pinned engine crashes on a join whose leftmost
::  relation is empty, and matching by ID in Hoon costs nothing here.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, render=rover-render, view=rover-view
|%
::  Every relation the export reads, in one list. The list decides the order of
::  the result sets, and `+read-index` is the only thing that maps a name to a
::  position, so a new read is one entry rather than a renumbering.
++  export-reads
  ^-  (list [name=@tas cols=tape])
  ;:  weld
  ^-  (list [name=@tas cols=tape])
  :~  [%vehicles "vehicle-id, label, archived"]
      [%vehicle-tank-size "vehicle-id, digits, decimals, size-unit"]
      [%vehicle-refill-reserve "vehicle-id, reserve-percent"]
      [%vehicle-display-preferences "vehicle-id, distance-unit, currency"]
      [%energy-definitions "energy-definition-id, label, physical-kind, quantity-unit, archived"]
      [%energy-definition-subtypes "subtype-id, energy-definition-id, label, archived"]
      [%energy-subtype-octane "subtype-id, rating, method"]
      [%energy-subtype-cetane "subtype-id, rating"]
      [%vehicle-energy-definitions "vehicle-id, energy-definition-id, archived"]
      [%vehicle-default-energy-definitions "vehicle-id, energy-definition-id"]
      [%vehicle-default-energy-subtype "vehicle-id, subtype-id"]
      [%driving-mode-definitions "mode-id, label, archived"]
      [%vehicle-driving-modes "vehicle-id, mode-id, archived"]
      [%additive-definitions "additive-id, label, archived"]
      [%tag-definitions "tag-id, label, archived"]
      [%payment-method-definitions "method-id, label, archived"]
      [%consumable-definitions "consumable-id, label, quantity-unit, archived"]
      [%vehicle-consumables "vehicle-id, consumable-id, archived"]
      [%vehicle-consumable-tank-size "vehicle-id, consumable-id, digits, decimals, unit"]
      [%service-subtype-definitions "service-subtype-id, label, archived"]
      [%service-subtype-reminder-defaults "service-subtype-id, time-interval, time-unit, distance-digits, distance-decimals, distance-unit"]
      [%disposal-kind-definitions "disposal-kind-id, label, archived"]
      [%custom-field-definitions "field-id, label, content-type, entry-type, mandatory, target, archived"]
      [%places "place-id, label, archived"]
      [%place-addresses "place-id, source"]
      [%place-address-formatted "place-id, formatted"]
      [%place-address-parts "place-id, part, value"]
      [%place-coordinates "place-id, latitude-scaled, longitude-scaled, coord-scale, source"]
      [%stations "station-id, place-id, label, station-kind, archived"]
      [%odometer-observations "odometer-id, vehicle-id, value-digits, decimal-places, unit, observed-start, source-zone"]
      [%energy-acquisitions "acquisition-id, vehicle-id, energy-definition-id, observed-start, observed-end, observed-precision, source-zone"]
      [%fuel-fills "acquisition-id, quantity-milli, quantity-unit, tank-state, unit-price-mills, currency, settlement-mode, price-profile, minor-unit-decimals, cash-increment-mills"]
      [%charging-sessions "acquisition-id"]
      [%energy-acquisition-odometers "acquisition-id, odometer-id"]
      [%energy-acquisition-stations "acquisition-id, station-id"]
      [%fuel-fill-subtype "acquisition-id, subtype-id"]
      [%fuel-fill-additives "acquisition-id, additive-id"]
      [%economy-breaks "acquisition-id, reason"]
      [%fuel-fill-driving-mode "acquisition-id, mode-id"]
      [%fuel-fill-average-speed "acquisition-id, digits, decimals, speed-unit"]
      [%fuel-fill-drive-balance "acquisition-id, highway-percent"]
      [%fuel-fill-tags "acquisition-id, tag-id"]
      [%fill-notes "acquisition-id, note"]
      [%fuel-fill-payment-method "acquisition-id, method-id"]
      [%acquisition-imports "acquisition-id, source-app, source-record-id"]
      [%charging-energy-measurements "measurement-id, acquisition-id, quantity, decimals, measure-unit, point, evidence"]
      [%charging-session-batteries "acquisition-id, endpoint, battery-observation-id"]
      [%battery-observation-percent "battery-observation-id, value-digits, value-decimals"]
      [%charging-costs "acquisition-id, cost-state, currency"]
      [%charging-cost-components "component-id, acquisition-id, component, quantity, quantity-decimals, quantity-unit, rate-mills, amount-mills"]
      [%charging-cost-source-totals "acquisition-id, total-mills"]
      [%charging-session-subtype "acquisition-id, subtype-id"]
      [%consumable-acquisitions "consumable-acquisition-id, vehicle-id, consumable-id, observed-start, observed-end, observed-precision, source-zone"]
      [%consumable-purchases "consumable-acquisition-id, quantity-milli, quantity-unit, unit-price-mills, currency, settlement-mode, price-profile, minor-unit-decimals, cash-increment-mills"]
      [%consumable-acquisition-odometers "consumable-acquisition-id, odometer-id"]
      [%consumable-acquisition-stations "consumable-acquisition-id, station-id"]
      [%vehicle-events "event-id, vehicle-id, observed-start, observed-end, observed-precision, source-zone"]
      [%service-events "event-id"]
      [%expense-events "event-id"]
      [%note-events "event-id"]
      [%vehicle-acquisitions "event-id"]
      [%vehicle-disposals "event-id, disposal-kind-id"]
      [%vehicle-event-costs "event-id, cost-state, currency, minor-unit-decimals"]
      [%vehicle-event-cost-totals "event-id, total-mills"]
      [%vehicle-event-odometers "event-id, odometer-id"]
      [%vehicle-event-stations "event-id, station-id"]
      [%vehicle-event-tags "event-id, tag-id"]
      [%vehicle-event-payment-method "event-id, method-id"]
      [%vehicle-event-notes "event-id, note"]
      [%vehicle-event-service-subtypes "event-id, service-subtype-id"]
      [%service-reminders "reminder-id, vehicle-id, service-subtype-id, archived"]
      [%service-reminder-time "reminder-id, interval-count, interval-unit, due-at"]
      [%service-reminder-distance "reminder-id, interval-digits, interval-decimals, due-digits, due-decimals, distance-unit"]
      [%app-default-vehicle "scope, vehicle-id"]
      [%custom-field-values-number "field-id, parent-id, digits, decimals, value-unit"]
      [%custom-field-values-text "field-id, parent-id, value"]
      [%custom-field-values-boolean "field-id, parent-id, value"]
  ==
  ::  The thirteen T7 specification relations, in `spec-view-order`.
  %+  turn  spec-view-order:act
  |=  [relation=@tas column=@tas]
  ^-  [@tas tape]
  [relation (weld "vehicle-id, " (trip column))]
  ::  Stored fact kinds the format does not model. They are read for their
  ::  COUNT only, so the payload can name what it leaves behind. Silence is
  ::  the failure mode; a count is one line and no schema.
  ^-  (list [name=@tas cols=tape])
  :~  [%custom-field-options "field-id, ordinal, label"]
      [%station-brand-operator "station-id, role, label"]
      [%station-identifiers "station-id, provider, external-id"]
      [%place-coordinate-accuracy "place-id, radius-digits, radius-decimals, radius-unit"]
      [%acquisition-station-equipment "acquisition-id, equipment-label, receipt-text"]
      [%energy-subtype-blend "subtype-id, blend-kind, percent-digits, percent-decimals"]
      [%energy-subtype-grade-code "subtype-id, code"]
      [%battery-observation-segments "battery-observation-id, filled, total"]
      [%consumption-observations "consumption-id, vehicle-id"]
      [%charging-efficiency-breaks "acquisition-id, reason"]
  ==
  ==
::
::  Which stored fact kinds the export deliberately leaves behind, and why.
::  Every name here is read for its count above.
++  not-carried-kinds
  ^-  (list [name=@tas reason=@t])
  :~  :-  %custom-field-options
      'a custom field with a fixed option list has no entry path yet'
      :-  %station-brand-operator
      'brand and operator have no entry path yet'
      :-  %station-identifiers
      'a provider identifier must never cross a boundary'
      :-  %place-coordinate-accuracy
      'coordinate accuracy has no entry path yet'
      :-  %acquisition-station-equipment
      'the pump or charger used has no entry path yet'
      :-  %energy-subtype-blend
      'a blend percentage has no entry path yet'
      :-  %energy-subtype-grade-code
      'a grade code has no entry path yet'
      :-  %battery-observation-segments
      'a battery reading in segments rather than percent has no entry path yet'
      :-  %consumption-observations
      'a dashboard consumption reading has no entry path yet'
      :-  %charging-efficiency-breaks
      'a charging break has no entry path yet'
  ==
::
++  export-view
  ^-  tape
  =/  build
    |=  reads=(list [name=@tas cols=tape])
    ^-  tape
    ?~  reads
      ~
    ;:  weld
      "FROM "
      (trip name.i.reads)
      " X SELECT X."
      (join-columns cols.i.reads)
      "; "
      $(reads t.reads)
    ==
  (build export-reads)
::
::  "a, b" becomes "a, X.b". The alias has to repeat on every column, and
::  writing it once per relation keeps the read list readable.
++  join-columns
  |=  cols=tape
  ^-  tape
  ?~  cols
    ~
  ?.  ?&  =(',' i.cols)
          ?=(^ t.cols)
          =(' ' i.t.cols)
      ==
    [i.cols $(cols t.cols)]
  ?>  ?=(^ t.cols)
  (weld ", X." $(cols t.t.cols))
::
++  read-index
  |=  name=@tas
  ^-  @ud
  =/  reads  export-reads
  =/  ordinal  0
  |-
  ?~  reads
    ~|([%rover-export-unknown-read name] !!)
  ?:  =(name name.i.reads)
    ordinal
  $(reads t.reads, ordinal +(ordinal))
::
++  read-rows
  |=  [name=@tas commands=(list cmd-result:ast)]
  ^-  (list vector:ast)
  =/  index  (read-index name)
  ?.  (lth index (lent commands))
    ~
  (rows-at:view commands index)
::
::  The @f bunt is %.y, so a stored 0 is archived and a stored 1 is active.
++  flag-archived
  |=  [key=@tas row=vector:ast]
  ^-  ?
  =(0 (cell-atom:view key row))
::
++  jo
  |=  entries=(list [@t json])
  ^-  json
  [%o (malt entries)]
::
++  js
  |=  value=@t
  ^-  json
  [%s value]
::
++  jt
  |=  value=@tas
  ^-  json
  [%s (crip (trip (scot %tas value)))]
::
++  jb
  |=  value=?
  ^-  json
  [%b value]
::
++  jn
  |=  value=@ud
  ^-  json
  [%n (crip (a-co:co value))]
::
++  ja
  |=  values=(list json)
  ^-  json
  [%a values]
::
++  scaled
  |=  [digits=@ud places=@ud]
  ^-  @t
  (format-scaled:render digits places %.n)
::
++  whole
  |=  value=@ud
  ^-  @t
  (crip (a-co:co value))
::
::  A stored instant, in the sixteen characters `+local-da` reads back. Import
::  parses to the minute, so a second the entry path never wrote is never
::  claimed here either.
++  export-da
  |=  value=@da
  ^-  @t
  =/  parts  (yore value)
  =/  n2
    |=  number=@ud
    ^-  tape
    ?:((lth number 10) ['0' (a-co:co number)] (a-co:co number))
  =/  n4
    |=  number=@ud
    ^-  tape
    =/  txt  (a-co:co number)
    (weld (reap (sub 4 (min 4 (lent txt))) '0') txt)
  %-  crip
  ;:  weld
    (n4 y.parts)
    "-"
    (n2 m.parts)
    "-"
    (n2 d.t.parts)
    "T"
    (n2 h.t.parts)
    ":"
    (n2 m.t.parts)
  ==
::
::  A stored day, the ten characters `+local-day` reads back.
++  export-day
  |=  value=@da
  ^-  @t
  (crip (scag 10 (trip (export-da value))))
::
::  The minor-unit figure a stored mills total renders as. `+parse-money` reads
::  it straight back, so nothing is rounded in either direction.
++  export-money
  |=  [total-mills=@ud minor-unit-decimals=@ud]
  ^-  @t
  =/  minor-scale  (pow-ten:render minor-unit-decimals)
  =/  mills-per-minor  (div 1.000 minor-scale)
  (scaled (div total-mills mills-per-minor) minor-unit-decimals)
::
++  id-of
  |=  [key=@tas row=vector:ast]
  ^-  @ux
  `@ux`(cell-atom:view key row)
::
::  One row of `rows` whose `key` column equals `value`, or none.
++  row-with
  |=  [key=@tas value=@ rows=(list vector:ast)]
  ^-  (unit vector:ast)
  ?~  rows
    ~
  ?:  =(value (cell-atom:view key i.rows))
    `i.rows
  $(rows t.rows)
::
++  rows-with
  |=  [key=@tas value=@ rows=(list vector:ast)]
  ^-  (list vector:ast)
  %+  skim  rows
  |=  row=vector:ast
  =(value (cell-atom:view key row))
::
::  The label a definition row holds, found by its ID. Absent means the row is
::  gone, which the schema's RESTRICT keys make impossible; the empty label is
::  never written, so it cannot be mistaken for a real one.
++  label-of
  |=  [key=@tas value=@ rows=(list vector:ast)]
  ^-  @t
  =/  found  (row-with key value rows)
  ?~  found
    ''
  (cell-text:view %label u.found)
::
++  sort-texts
  |=  values=(list @t)
  ^-  (list @t)
  (sort values aor)
::
::  Labels of the rows a link relation points at, sorted so two exports of one
::  database agree. The set the engine returns has no stable order.
++  linked-labels
  |=  $:  link-key=@tas
          link-value=@
          target-key=@tas
          links=(list vector:ast)
          targets=(list vector:ast)
      ==
  ^-  (list @t)
  %-  sort-texts
  %+  turn  (rows-with link-key link-value links)
  |=  row=vector:ast
  (label-of target-key (cell-atom:view target-key row) targets)
::
::  Every optional member below writes a key only when its row exists. An
::  absent row is an ABSENT KEY, never a null, a zero, or an empty string:
::  that is the no-sentinel rule crossing the boundary in the export
::  direction, and `+decode-import` reads it back the same way.
::
::  Absence is spelled `?~` at every site rather than through a helper gate. A
::  gate evaluates BOTH arguments, so `(helper ?=(^ row) key (read u.row))`
::  reads the absent row before the test can stop it, and crashes.
++  one-key
  |=  [key=@t value=json]
  ^-  (list [@t json])
  [key value]~
::
++  export-json
  |=  [commands=(list cmd-result:ast) ship=@p now=@da]
  ^-  @t
  =/  rows
    |=  name=@tas
    ^-  (list vector:ast)
    (read-rows name commands)
  ::  ---- the definition layer ----------------------------------------
  =/  energy-rows  (rows %energy-definitions)
  =/  subtype-rows  (rows %energy-definition-subtypes)
  =/  octane-rows  (rows %energy-subtype-octane)
  =/  cetane-rows  (rows %energy-subtype-cetane)
  =/  energy-json
    %+  turn
      %+  sort  energy-rows
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    |=  row=vector:ast
    ^-  json
    =/  definition-id  (id-of %energy-definition-id row)
    =/  mine  (rows-with %energy-definition-id definition-id subtype-rows)
    =/  subtypes
      %+  turn
        %+  sort  mine
        |=  [a=vector:ast b=vector:ast]
        (aor (cell-text:view %label a) (cell-text:view %label b))
      |=  subtype=vector:ast
      ^-  json
      =/  subtype-id  (id-of %subtype-id subtype)
      =/  octane  (row-with %subtype-id subtype-id octane-rows)
      =/  cetane  (row-with %subtype-id subtype-id cetane-rows)
      %-  jo
      ;:  weld
        ^-  (list [@t json])
        :~  ['label' (js (cell-text:view %label subtype))]
            ['archived' (jb (flag-archived %archived subtype))]
        ==
        ?~  octane
          ~
        ^-  (list [@t json])
        :~  ['octane' (js (whole (cell-atom:view %rating u.octane)))]
            ['method' (jt (cell-term:view %method u.octane))]
        ==
        ?~  cetane
          ~
        (one-key 'cetane' (js (whole (cell-atom:view %rating u.cetane))))
      ==
    %-  jo
    :~  ['label' (js (cell-text:view %label row))]
        ['physicalKind' (jt (cell-term:view %physical-kind row))]
        ['quantityUnit' (jt (cell-term:view %quantity-unit row))]
        ['archived' (jb (flag-archived %archived row))]
        ['subtypes' (ja subtypes)]
    ==
  =/  simple-json
    |=  defs=(list vector:ast)
    ^-  (list json)
    %+  turn
      %+  sort  defs
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    |=  row=vector:ast
    ^-  json
    %-  jo
    :~  ['label' (js (cell-text:view %label row))]
        ['archived' (jb (flag-archived %archived row))]
    ==
  =/  consumable-rows  (rows %consumable-definitions)
  =/  consumable-json
    %+  turn
      %+  sort  consumable-rows
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    |=  row=vector:ast
    ^-  json
    %-  jo
    :~  ['label' (js (cell-text:view %label row))]
        ['quantityUnit' (jt (cell-term:view %quantity-unit row))]
        ['archived' (jb (flag-archived %archived row))]
    ==
  =/  service-subtype-rows  (rows %service-subtype-definitions)
  =/  default-rows  (rows %service-subtype-reminder-defaults)
  =/  service-subtype-json
    %+  turn
      %+  sort  service-subtype-rows
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    |=  row=vector:ast
    ^-  json
    =/  subtype-id  (id-of %service-subtype-id row)
    =/  fallback  (row-with %service-subtype-id subtype-id default-rows)
    %-  jo
    ;:  weld
      ^-  (list [@t json])
      :~  ['label' (js (cell-text:view %label row))]
          ['archived' (jb (flag-archived %archived row))]
      ==
      ?~  fallback
        ~
      ^-  (list [@t json])
      :~  :-  'defaultTimeInterval'
          (js (whole (cell-atom:view %time-interval u.fallback)))
          :-  'defaultTimeUnit'
          (jt (cell-term:view %time-unit u.fallback))
          :-  'defaultDistanceInterval'
          %-  js
          %+  scaled
            (cell-atom:view %distance-digits u.fallback)
          (cell-atom:view %distance-decimals u.fallback)
          :-  'defaultDistanceUnit'
          (jt (cell-term:view %distance-unit u.fallback))
      ==
    ==
  =/  custom-rows  (rows %custom-field-definitions)
  =/  custom-json
    %+  turn
      %+  sort  custom-rows
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    |=  row=vector:ast
    ^-  json
    %-  jo
    :~  ['label' (js (cell-text:view %label row))]
        ['contentType' (jt (cell-term:view %content-type row))]
        ['mandatory' (jb (flag-archived %mandatory row))]
        ['archived' (jb (flag-archived %archived row))]
    ==
  =/  definitions
    %-  jo
    :~  ['energy' (ja energy-json)]
        ['service-subtypes' (ja service-subtype-json)]
        ['additives' (ja (simple-json (rows %additive-definitions)))]
        ['driving-modes' (ja (simple-json (rows %driving-mode-definitions)))]
        ['tags' (ja (simple-json (rows %tag-definitions)))]
        ['payment-methods' (ja (simple-json (rows %payment-method-definitions)))]
        ['consumables' (ja consumable-json)]
        ['disposal-kinds' (ja (simple-json (rows %disposal-kind-definitions)))]
        ['custom-fields' (ja custom-json)]
    ==
  ::  ---- places and their stations -----------------------------------
  =/  place-rows  (rows %places)
  =/  address-rows  (rows %place-addresses)
  =/  formatted-rows  (rows %place-address-formatted)
  =/  part-rows  (rows %place-address-parts)
  =/  coordinate-rows  (rows %place-coordinates)
  =/  station-rows  (rows %stations)
  =/  places-json
    %+  turn
      %+  sort  place-rows
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    |=  row=vector:ast
    ^-  json
    =/  place-id  (id-of %place-id row)
    =/  address  (row-with %place-id place-id address-rows)
    =/  formatted  (row-with %place-id place-id formatted-rows)
    =/  parts  (rows-with %place-id place-id part-rows)
    =/  coordinates  (row-with %place-id place-id coordinate-rows)
    =/  mine
      %+  sort  (rows-with %place-id place-id station-rows)
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    =/  address-json
      |=  found=vector:ast
      ^-  json
      %-  jo
      ;:  weld
        ^-  (list [@t json])
        [['source' (jt (cell-term:view %source found))] ~]
        ?~  formatted
          ~
        (one-key 'formatted' (js (cell-text:view %formatted u.formatted)))
        ?~  parts
          ~
        :_  ~
        :-  'parts'
        %-  jo
        %+  turn  parts
        |=  part=vector:ast
        ^-  [@t json]
        :-  (crip (trip (scot %tas (cell-term:view %part part))))
        (js (cell-text:view %value part))
      ==
    %-  jo
    ;:  weld
      ^-  (list [@t json])
      :~  ['label' (js (cell-text:view %label row))]
          ['archived' (jb (flag-archived %archived row))]
          :-  'stations'
          %-  ja
          %+  turn  mine
          |=  station=vector:ast
          ^-  json
          %-  jo
          :~  ['label' (js (cell-text:view %label station))]
              ['kind' (jt (cell-term:view %station-kind station))]
              ['archived' (jb (flag-archived %archived station))]
          ==
      ==
      ?~  address
        ~
      (one-key 'address' (address-json u.address))
      :: coordinates keep the scale the row itself stores, so no row
      :: misrepresents its own precision.
      ?~  coordinates
        ~
      :_  ~
      :-  'coordinates'
      %-  jo
      :~  :-  'lat'
          %-  js
          %+  format-sscaled:render
            `@sd`(cell-atom:view %latitude-scaled u.coordinates)
          [(cell-atom:view %coord-scale u.coordinates) %.n]
          :-  'lon'
          %-  js
          %+  format-sscaled:render
            `@sd`(cell-atom:view %longitude-scaled u.coordinates)
          [(cell-atom:view %coord-scale u.coordinates) %.n]
          ['source' (jt (cell-term:view %source u.coordinates))]
      ==
    ==
  ::  ---- everything a vehicle carries --------------------------------
  =/  vehicle-rows  (rows %vehicles)
  =/  odometer-rows  (rows %odometer-observations)
  =/  acquisition-rows  (rows %energy-acquisitions)
  =/  fill-rows  (rows %fuel-fills)
  =/  charge-rows  (rows %charging-sessions)
  =/  acquisition-odometers  (rows %energy-acquisition-odometers)
  =/  acquisition-stations  (rows %energy-acquisition-stations)
  =/  fill-subtypes  (rows %fuel-fill-subtype)
  =/  fill-additives  (rows %fuel-fill-additives)
  =/  break-rows  (rows %economy-breaks)
  =/  fill-modes  (rows %fuel-fill-driving-mode)
  =/  fill-speeds  (rows %fuel-fill-average-speed)
  =/  fill-balances  (rows %fuel-fill-drive-balance)
  =/  fill-tags  (rows %fuel-fill-tags)
  =/  fill-note-rows  (rows %fill-notes)
  =/  fill-payments  (rows %fuel-fill-payment-method)
  =/  provenance-rows  (rows %acquisition-imports)
  =/  measurement-rows  (rows %charging-energy-measurements)
  =/  battery-links  (rows %charging-session-batteries)
  =/  battery-percents  (rows %battery-observation-percent)
  =/  charging-cost-rows  (rows %charging-costs)
  =/  component-rows  (rows %charging-cost-components)
  =/  charge-total-rows  (rows %charging-cost-source-totals)
  =/  charge-subtypes  (rows %charging-session-subtype)
  =/  purchase-parents  (rows %consumable-acquisitions)
  =/  purchase-rows  (rows %consumable-purchases)
  =/  purchase-odometers  (rows %consumable-acquisition-odometers)
  =/  purchase-stations  (rows %consumable-acquisition-stations)
  =/  event-rows  (rows %vehicle-events)
  =/  event-costs  (rows %vehicle-event-costs)
  =/  event-totals  (rows %vehicle-event-cost-totals)
  =/  event-odometers  (rows %vehicle-event-odometers)
  =/  event-stations  (rows %vehicle-event-stations)
  =/  event-tags  (rows %vehicle-event-tags)
  =/  event-payments  (rows %vehicle-event-payment-method)
  =/  event-notes  (rows %vehicle-event-notes)
  =/  event-subtypes  (rows %vehicle-event-service-subtypes)
  =/  disposal-rows  (rows %vehicle-disposals)
  =/  reminder-rows  (rows %service-reminders)
  =/  reminder-times  (rows %service-reminder-time)
  =/  reminder-distances  (rows %service-reminder-distance)
  =/  tag-rows  (rows %tag-definitions)
  =/  additive-rows  (rows %additive-definitions)
  =/  mode-rows  (rows %driving-mode-definitions)
  =/  payment-rows  (rows %payment-method-definitions)
  =/  disposal-kind-rows  (rows %disposal-kind-definitions)
  =/  number-values  (rows %custom-field-values-number)
  =/  text-values  (rows %custom-field-values-text)
  =/  boolean-values  (rows %custom-field-values-boolean)
  ::  The station a link points at, by label. A station label is what the
  ::  import reads; the ID it replaces never crosses the boundary.
  =/  station-label-of
    |=  station-id=@
    ^-  @t
    (label-of %station-id station-id station-rows)
  =/  odometer-fields
    |=  odometer-id=@
    ^-  (list [@t json])
    =/  found  (row-with %odometer-id odometer-id odometer-rows)
    ?~  found
      ~
    :~  :-  'mileage'
        %-  js
        %+  scaled
          (cell-atom:view %value-digits u.found)
        (cell-atom:view %decimal-places u.found)
        ['mileageUnit' (jt (cell-term:view %unit u.found))]
    ==
  =/  custom-fields-of
    |=  parent-id=@
    ^-  (list [@t json])
    =/  numbers
      %+  turn  (rows-with %parent-id parent-id number-values)
      |=  row=vector:ast
      ^-  [@t json]
      :-  (cat 3 'custom-' (label-of %field-id (cell-atom:view %field-id row) custom-rows))
      %-  js
      %+  scaled
        (cell-atom:view %digits row)
      (cell-atom:view %decimals row)
    =/  texts
      %+  turn  (rows-with %parent-id parent-id text-values)
      |=  row=vector:ast
      ^-  [@t json]
      :-  (cat 3 'custom-' (label-of %field-id (cell-atom:view %field-id row) custom-rows))
      (js (cell-text:view %value row))
    =/  booleans
      %+  turn  (rows-with %parent-id parent-id boolean-values)
      |=  row=vector:ast
      ^-  [@t json]
      :-  (cat 3 'custom-' (label-of %field-id (cell-atom:view %field-id row) custom-rows))
      (js ?:((flag-archived %value row) 'yes' 'no'))
    ;:(weld numbers texts booleans)
  =/  vehicles-json
    %+  turn
      %+  sort  vehicle-rows
      |=  [a=vector:ast b=vector:ast]
      (aor (cell-text:view %label a) (cell-text:view %label b))
    |=  row=vector:ast
    ^-  json
    =/  vehicle-id  (id-of %vehicle-id row)
    =/  vehicle-label  (cell-text:view %label row)
    =/  tank  (row-with %vehicle-id vehicle-id (rows %vehicle-tank-size))
    =/  reserve  (row-with %vehicle-id vehicle-id (rows %vehicle-refill-reserve))
    =/  preference
      (row-with %vehicle-id vehicle-id (rows %vehicle-display-preferences))
    =/  default-energy
      %+  row-with  %vehicle-id
      [vehicle-id (rows %vehicle-default-energy-definitions)]
    =/  default-subtype
      (row-with %vehicle-id vehicle-id (rows %vehicle-default-energy-subtype))
    =/  energy-links
      (rows-with %vehicle-id vehicle-id (rows %vehicle-energy-definitions))
    =/  mode-links
      (rows-with %vehicle-id vehicle-id (rows %vehicle-driving-modes))
    =/  consumable-links
      (rows-with %vehicle-id vehicle-id (rows %vehicle-consumables))
    =/  consumable-tanks  (rows %vehicle-consumable-tank-size)
    =/  mine-acquisitions  (rows-with %vehicle-id vehicle-id acquisition-rows)
    =/  mine-fills
      %+  skim  mine-acquisitions
      |=  parent=vector:ast
      ?=(^ (row-with %acquisition-id (id-of %acquisition-id parent) fill-rows))
    =/  mine-charges
      %+  skim  mine-acquisitions
      |=  parent=vector:ast
      ?=(^ (row-with %acquisition-id (id-of %acquisition-id parent) charge-rows))
    =/  by-start
      |=  [a=vector:ast b=vector:ast]
      (lth (cell-atom:view %observed-start a) (cell-atom:view %observed-start b))
    ::  ---- one fuel fill --------------------------------------------
    =/  fills-json
      %+  turn  (sort mine-fills by-start)
      |=  parent=vector:ast
      ^-  json
      =/  acquisition-id  (id-of %acquisition-id parent)
      =/  fill  (need (row-with %acquisition-id acquisition-id fill-rows))
      =/  odometer  (row-with %acquisition-id acquisition-id acquisition-odometers)
      =/  station  (row-with %acquisition-id acquisition-id acquisition-stations)
      =/  subtype  (row-with %acquisition-id acquisition-id fill-subtypes)
      =/  economy-break  (row-with %acquisition-id acquisition-id break-rows)
      =/  mode  (row-with %acquisition-id acquisition-id fill-modes)
      =/  speed  (row-with %acquisition-id acquisition-id fill-speeds)
      =/  balance  (row-with %acquisition-id acquisition-id fill-balances)
      =/  note  (row-with %acquisition-id acquisition-id fill-note-rows)
      =/  payment  (row-with %acquisition-id acquisition-id fill-payments)
      =/  provenance  (row-with %acquisition-id acquisition-id provenance-rows)
      %-  jo
      ;:  weld
        ^-  (list [@t json])
        :~  ['vehicle' (js vehicle-label)]
            :-  'definition'
            %-  js
            %+  label-of  %energy-definition-id
            [(cell-atom:view %energy-definition-id parent) energy-rows]
            :-  'observed'
            (js (export-da `@da`(cell-atom:view %observed-start parent)))
            ['zone' (js (cell-text:view %source-zone parent))]
            :-  'quantity'
            (js (scaled (cell-atom:view %quantity-milli fill) 3))
            :-  'price'
            (js (scaled (cell-atom:view %unit-price-mills fill) 3))
            ['profile' (jt (cell-term:view %price-profile fill))]
            ['tank' (jt (cell-term:view %tank-state fill))]
            ['settlement' (jt (cell-term:view %settlement-mode fill))]
            :-  'station'
            (js ?~(station 'none' (station-label-of (cell-atom:view %station-id u.station))))
            :-  'additives'
            %-  ja
            %+  turn
              %^  linked-labels  %acquisition-id  acquisition-id
              [%additive-id fill-additives additive-rows]
            |=(label=@t (js label))
            :-  'tags'
            %-  ja
            %+  turn
              %^  linked-labels  %acquisition-id  acquisition-id
              [%tag-id fill-tags tag-rows]
            |=(label=@t (js label))
            ['missedFill' (js ?~(economy-break 'no' 'yes'))]
        ==
        ?~  odometer
          ~
        (odometer-fields (cell-atom:view %odometer-id u.odometer))
        ?~  subtype
          ~
        %+  one-key  'subtype'
        %-  js
        %+  label-of  %subtype-id
        [(cell-atom:view %subtype-id u.subtype) subtype-rows]
        ?~  mode
          ~
        %+  one-key  'drivingMode'
        %-  js
        %+  label-of  %mode-id
        [(cell-atom:view %mode-id u.mode) mode-rows]
        ?~  speed
          ~
        ^-  (list [@t json])
        :~  :-  'averageSpeed'
            %-  js
            %+  scaled
              (cell-atom:view %digits u.speed)
            (cell-atom:view %decimals u.speed)
            ['speedUnit' (jt (cell-term:view %speed-unit u.speed))]
        ==
        ?~  balance
          ~
        %+  one-key  'driveBalance'
        (js (whole (cell-atom:view %highway-percent u.balance)))
        ?~  note
          ~
        (one-key 'notes' (js (cell-text:view %note u.note)))
        ?~  payment
          ~
        %+  one-key  'paymentMethod'
        %-  js
        %+  label-of  %method-id
        [(cell-atom:view %method-id u.payment) payment-rows]
        ?~  provenance
          ~
        ^-  (list [@t json])
        :~  ['sourceApp' (jt (cell-term:view %source-app u.provenance))]
            :-  'sourceRecordId'
            (js (cell-text:view %source-record-id u.provenance))
        ==
        (custom-fields-of acquisition-id)
      ==
    ::  ---- one charging session --------------------------------------
    =/  charges-json
      %+  turn  (sort mine-charges by-start)
      |=  parent=vector:ast
      ^-  json
      =/  acquisition-id  (id-of %acquisition-id parent)
      =/  odometer  (row-with %acquisition-id acquisition-id acquisition-odometers)
      =/  measurement
        (row-with %acquisition-id acquisition-id measurement-rows)
      =/  cost  (row-with %acquisition-id acquisition-id charging-cost-rows)
      =/  source-total
        (row-with %acquisition-id acquisition-id charge-total-rows)
      =/  subtype  (row-with %acquisition-id acquisition-id charge-subtypes)
      =/  batteries  (rows-with %acquisition-id acquisition-id battery-links)
      =/  battery-level
        |=  endpoint=@tas
        ^-  (unit @t)
        =/  link
          %+  row-with  %endpoint
          [`@`endpoint batteries]
        ?~  link
          ~
        =/  percent
          %+  row-with  %battery-observation-id
          [(cell-atom:view %battery-observation-id u.link) battery-percents]
        ?~  percent
          ~
        :-  ~
        %+  scaled
          (cell-atom:view %value-digits u.percent)
        (cell-atom:view %value-decimals u.percent)
      =/  start-level  (battery-level %start)
      =/  end-level  (battery-level %end)
      =/  components
        %+  turn  (rows-with %acquisition-id acquisition-id component-rows)
        |=  component=vector:ast
        ^-  json
        %-  jo
        :~  ['component' (jt (cell-term:view %component component))]
            :-  'quantity'
            %-  js
            %+  scaled
              (cell-atom:view %quantity component)
            (cell-atom:view %quantity-decimals component)
            ['unit' (jt (cell-term:view %quantity-unit component))]
            :-  'rate'
            (js (scaled (cell-atom:view %rate-mills component) 3))
            :-  'amount'
            (js (scaled (cell-atom:view %amount-mills component) 3))
        ==
      %-  jo
      ;:  weld
        ^-  (list [@t json])
        :~  ['vehicle' (js vehicle-label)]
            :-  'definition'
            %-  js
            %+  label-of  %energy-definition-id
            [(cell-atom:view %energy-definition-id parent) energy-rows]
            :-  'start'
            (js (export-da `@da`(cell-atom:view %observed-start parent)))
            :-  'end'
            (js (export-da `@da`(cell-atom:view %observed-end parent)))
            ['zone' (js (cell-text:view %source-zone parent))]
            :-  'costState'
            (jt ?~(cost %unknown (cell-term:view %cost-state u.cost)))
            :-  'currency'
            (jt ?~(cost %usd (cell-term:view %currency u.cost)))
            ['components' (ja components)]
        ==
        ?~  measurement
          ~
        ^-  (list [@t json])
        :~  :-  'energyDelivered'
            %-  js
            %+  scaled
              (cell-atom:view %quantity u.measurement)
            (cell-atom:view %decimals u.measurement)
            :-  'energySource'
            %-  js
            =/  point  (cell-term:view %point u.measurement)
            ?:  =(%wall point)     'wall-measured'
            ?:  =(%charger point)  'charger-reported'
            ?:  =(%vehicle point)  'vehicle-reported'
            'estimate'
        ==
        ?~  start-level
          ~
        (one-key 'startBattery' (js u.start-level))
        ?~  end-level
          ~
        (one-key 'endBattery' (js u.end-level))
        ?~  odometer
          ~
        (odometer-fields (cell-atom:view %odometer-id u.odometer))
        ?~  source-total
          ~
        %+  one-key  'sourceTotal'
        (js (scaled (cell-atom:view %total-mills u.source-total) 3))
        ?~  subtype
          ~
        %+  one-key  'subtype'
        %-  js
        %+  label-of  %subtype-id
        [(cell-atom:view %subtype-id u.subtype) subtype-rows]
      ==
    ::  ---- one consumable purchase -----------------------------------
    =/  mine-purchases  (rows-with %vehicle-id vehicle-id purchase-parents)
    =/  purchases-json
      %+  turn  (sort mine-purchases by-start)
      |=  parent=vector:ast
      ^-  json
      =/  purchase-id  (id-of %consumable-acquisition-id parent)
      =/  purchase
        (need (row-with %consumable-acquisition-id purchase-id purchase-rows))
      =/  odometer
        (row-with %consumable-acquisition-id purchase-id purchase-odometers)
      =/  station
        (row-with %consumable-acquisition-id purchase-id purchase-stations)
      %-  jo
      ;:  weld
        ^-  (list [@t json])
        :~  ['vehicle' (js vehicle-label)]
            :-  'consumable'
            %-  js
            %+  label-of  %consumable-id
            [(cell-atom:view %consumable-id parent) consumable-rows]
            :-  'observed'
            (js (export-da `@da`(cell-atom:view %observed-start parent)))
            ['zone' (js (cell-text:view %source-zone parent))]
            :-  'quantity'
            (js (scaled (cell-atom:view %quantity-milli purchase) 3))
            :-  'price'
            (js (scaled (cell-atom:view %unit-price-mills purchase) 3))
            ['settlement' (jt (cell-term:view %settlement-mode purchase))]
        ==
        ?~  odometer
          ~
        (odometer-fields (cell-atom:view %odometer-id u.odometer))
        ?~  station
          ~
        %+  one-key  'station'
        (js (station-label-of (cell-atom:view %station-id u.station)))
      ==
    ::  ---- one vehicle event -----------------------------------------
    =/  mine-events  (rows-with %vehicle-id vehicle-id event-rows)
    =/  events-of
      |=  child=(list vector:ast)
      ^-  (list json)
      =/  ours
        %+  skim  mine-events
        |=  parent=vector:ast
        ?=(^ (row-with %event-id (id-of %event-id parent) child))
      %+  turn  (sort ours by-start)
      |=  parent=vector:ast
      ^-  json
      =/  event-id  (id-of %event-id parent)
      =/  cost  (row-with %event-id event-id event-costs)
      =/  total  (row-with %event-id event-id event-totals)
      =/  odometer  (row-with %event-id event-id event-odometers)
      =/  station  (row-with %event-id event-id event-stations)
      =/  payment  (row-with %event-id event-id event-payments)
      =/  note  (row-with %event-id event-id event-notes)
      =/  disposal  (row-with %event-id event-id disposal-rows)
      %-  jo
      ;:  weld
        ^-  (list [@t json])
        :~  ['vehicle' (js vehicle-label)]
            :-  'observed'
            (js (export-da `@da`(cell-atom:view %observed-start parent)))
            ['zone' (js (cell-text:view %source-zone parent))]
            :-  'currency'
            (jt ?~(cost %usd (cell-term:view %currency u.cost)))
            :-  'station'
            (js ?~(station 'none' (station-label-of (cell-atom:view %station-id u.station))))
            :-  'tags'
            %-  ja
            %+  turn
              %^  linked-labels  %event-id  event-id
              [%tag-id event-tags tag-rows]
            |=(label=@t (js label))
            :-  'subtypes'
            %-  ja
            %+  turn
              %^  linked-labels  %event-id  event-id
              [%service-subtype-id event-subtypes service-subtype-rows]
            |=(label=@t (js label))
        ==
        ?~  total
          ~
        ^-  (list [@t json])
        :_  ~
        :-  'total'
        %-  js
        %+  export-money
          (cell-atom:view %total-mills u.total)
        ?~(cost 2 (cell-atom:view %minor-unit-decimals u.cost))
        ?~  odometer
          ~
        (odometer-fields (cell-atom:view %odometer-id u.odometer))
        ?~  payment
          ~
        %+  one-key  'paymentMethod'
        %-  js
        %+  label-of  %method-id
        [(cell-atom:view %method-id u.payment) payment-rows]
        ?~  note
          ~
        (one-key 'notes' (js (cell-text:view %note u.note)))
        ?~  disposal
          ~
        %+  one-key  'disposalKind'
        %-  js
        %+  label-of  %disposal-kind-id
        [(cell-atom:view %disposal-kind-id u.disposal) disposal-kind-rows]
      ==
    ::  ---- one reminder ----------------------------------------------
    =/  mine-reminders  (rows-with %vehicle-id vehicle-id reminder-rows)
    =/  reminders-json
      %+  turn
        %+  skim  mine-reminders
        |=(reminder=vector:ast !(flag-archived %archived reminder))
      |=  reminder=vector:ast
      ^-  json
      =/  reminder-id  (id-of %reminder-id reminder)
      =/  time  (row-with %reminder-id reminder-id reminder-times)
      =/  distance  (row-with %reminder-id reminder-id reminder-distances)
      %-  jo
      ;:  weld
        ^-  (list [@t json])
        :~  ['vehicle' (js vehicle-label)]
            :-  'subtype'
            %-  js
            %+  label-of  %service-subtype-id
            [(cell-atom:view %service-subtype-id reminder) service-subtype-rows]
        ==
        ?~  time
          ~
        ^-  (list [@t json])
        :~  :-  'timeInterval'
            (js (whole (cell-atom:view %interval-count u.time)))
            ['timeUnit' (jt (cell-term:view %interval-unit u.time))]
            :-  'timeDue'
            (js (export-day `@da`(cell-atom:view %due-at u.time)))
        ==
        ?~  distance
          ~
        ^-  (list [@t json])
        :~  :-  'distanceInterval'
            %-  js
            %+  scaled
              (cell-atom:view %interval-digits u.distance)
            (cell-atom:view %interval-decimals u.distance)
            :-  'distanceDue'
            %-  js
            %+  scaled
              (cell-atom:view %due-digits u.distance)
            (cell-atom:view %due-decimals u.distance)
            :-  'distanceUnit'
            (jt (cell-term:view %distance-unit u.distance))
        ==
      ==
    ::  ---- the specification ------------------------------------------
    =/  spec-json
      %-  jo
      %-  zing
      %+  turn  spec-view-order:act
      |=  [relation=@tas column=@tas]
      ^-  (list [@t json])
      =/  found  (row-with %vehicle-id vehicle-id (rows relation))
      ?~  found
        ~
      :_  ~
      :-  (spec-key relation)
      ?:  =(%vehicle-model-year relation)
        (js (whole (cell-atom:view column u.found)))
      (js (cell-text:view column u.found))
    ::  A vehicle's units are validation context, not a stored preference
    ::  (import Q14). They are reported from the data itself: the first fill
    ::  decides, and a vehicle with no fill falls back to its definition.
    =/  volume-unit
      ?^  mine-fills
        =/  found
          %+  row-with  %acquisition-id
          [(id-of %acquisition-id i.mine-fills) fill-rows]
        ?~(found %gal (cell-term:view %quantity-unit u.found))
      ?~  default-energy
        %gal
      =/  found
        %+  row-with  %energy-definition-id
        [(cell-atom:view %energy-definition-id u.default-energy) energy-rows]
      ?~(found %gal (cell-term:view %quantity-unit u.found))
    =/  distance-unit
      =/  mine-odometers  (rows-with %vehicle-id vehicle-id odometer-rows)
      ?^  mine-odometers
        (cell-term:view %unit i.mine-odometers)
      ?~  preference
        %mi
      (cell-term:view %distance-unit u.preference)
    %-  jo
    ;:  weld
      ^-  (list [@t json])
      :~  ['label' (js vehicle-label)]
          ['archived' (jb (flag-archived %archived row))]
          ['distanceUnit' (jt distance-unit)]
          ['volumeUnit' (jt volume-unit)]
          :-  'defaultEnergy'
          %-  js
          ?~  default-energy
            ''
          %+  label-of  %energy-definition-id
          [(cell-atom:view %energy-definition-id u.default-energy) energy-rows]
          :-  'energySources'
          %-  ja
          %+  turn  energy-links
          |=  link=vector:ast
          ^-  json
          %-  jo
          :~  :-  'label'
              %-  js
              %+  label-of  %energy-definition-id
              [(cell-atom:view %energy-definition-id link) energy-rows]
              ['archived' (jb (flag-archived %archived link))]
          ==
          :-  'drivingModes'
          %-  ja
          %+  turn  mode-links
          |=  link=vector:ast
          ^-  json
          %-  jo
          :~  :-  'label'
              (js (label-of %mode-id (cell-atom:view %mode-id link) mode-rows))
              ['archived' (jb (flag-archived %archived link))]
          ==
          :-  'consumables'
          %-  ja
          %+  turn  consumable-links
          |=  link=vector:ast
          ^-  json
          =/  consumable-id  (cell-atom:view %consumable-id link)
          =/  size
            %+  row-with  %consumable-id
            [consumable-id (rows-with %vehicle-id vehicle-id consumable-tanks)]
          %-  jo
          ;:  weld
            ^-  (list [@t json])
            :~  :-  'label'
                (js (label-of %consumable-id consumable-id consumable-rows))
                ['archived' (jb (flag-archived %archived link))]
            ==
            ?~  size
              ~
            :_  ~
            :-  'tankSize'
            %-  jo
            :~  :-  'value'
                %-  js
                %+  scaled
                  (cell-atom:view %digits u.size)
                (cell-atom:view %decimals u.size)
                ['unit' (jt (cell-term:view %unit u.size))]
            ==
          ==
          ['specification' spec-json]
          ['fills' (ja fills-json)]
          ['charges' (ja charges-json)]
          ['consumablePurchases' (ja purchases-json)]
          ['serviceEvents' (ja (events-of (rows %service-events)))]
          ['expenseEvents' (ja (events-of (rows %expense-events)))]
          ['noteEvents' (ja (events-of (rows %note-events)))]
          ['acquisitionEvents' (ja (events-of (rows %vehicle-acquisitions)))]
          ['disposalEvents' (ja (events-of (rows %vehicle-disposals)))]
          ['reminders' (ja reminders-json)]
      ==
      ?~  tank
        ~
      :_  ~
      :-  'tankSize'
      %-  jo
      :~  :-  'value'
          %-  js
          %+  scaled
            (cell-atom:view %digits u.tank)
          (cell-atom:view %decimals u.tank)
          ['unit' (jt (cell-term:view %size-unit u.tank))]
      ==
      ?~  reserve
        ~
      %+  one-key  'refillReserve'
      (js (whole (cell-atom:view %reserve-percent u.reserve)))
      ?~  default-subtype
        ~
      %+  one-key  'defaultSubtype'
      %-  js
      %+  label-of  %subtype-id
      [(cell-atom:view %subtype-id u.default-subtype) subtype-rows]
      ?~  preference
        ~
      :_  ~
      :-  'preference'
      %-  jo
      :~  ['distanceUnit' (jt (cell-term:view %distance-unit u.preference))]
          ['currency' (jt (cell-term:view %currency u.preference))]
      ==
    ==
  ::  ---- the whole payload --------------------------------------------
  =/  app-default
    =/  found  (row-with %scope `@`%app (rows %app-default-vehicle))
    ?~  found
      ~
    :_  ~
    :-  'appDefaultVehicle'
    (js (label-of %vehicle-id (cell-atom:view %vehicle-id u.found) vehicle-rows))
  ::  A reading that a fill, a purchase or an event carries travels inside
  ::  that record. A reading entered on its own carries no record, and the
  ::  format has no place to put it, so the export COUNTS it and says so.
  ::  Inventing a section for it would be inventing format.
  =/  loose-odometers
    =/  linked=(list @)
      %-  zing
      ^-  (list (list @))
      :~  (turn acquisition-odometers |=(row=vector:ast (cell-atom:view %odometer-id row)))
          (turn purchase-odometers |=(row=vector:ast (cell-atom:view %odometer-id row)))
          (turn event-odometers |=(row=vector:ast (cell-atom:view %odometer-id row)))
      ==
    %+  skim  odometer-rows
    |=  row=vector:ast
    ^-  ?
    =/  odometer-id  (cell-atom:view %odometer-id row)
    !(lien linked |=(other=@ =(other odometer-id)))
  =/  omissions
    %+  weld
      %+  turn  not-carried-kinds
      |=  [name=@tas reason=@t]
      ^-  json
      %-  jo
      :~  ['kind' (jt name)]
          ['rows' (jn (lent (rows name)))]
          ['reason' (js reason)]
      ==
    ^-  (list json)
    :_  ~
    %-  jo
    :~  ['kind' (jt %standalone-odometer-readings)]
        ['rows' (jn (lent loose-odometers))]
        :-  'reason'
        %-  js
        'a reading that no fill, purchase or event carries has no place in the format'
    ==
  %-  en:json:html
  %-  jo
  %+  weld  app-default
  ^-  (list [@t json])
  :~  ['rover-import' [%n '1']]
      :-  'source'
      %-  jo
      :~  ['app' (js 'Rover')]
          ['ship' (js (crip (scow %p ship)))]
          ['exported' (js (export-da now))]
      ==
      :-  'not-carried'
      %-  jo
      :~  :-  'attachments'
          %-  jo
          :~  ['photos' (jn 0)]
              :-  'manifest'
              %-  js
              'attachments.json beside the converted export; Rover stores no photo row'
              :-  'reason'
              %-  js
              'photos live outside the database by ruling 17, and the attachment task is not built'
          ==
          ['kinds' (ja omissions)]
      ==
      ['definitions' definitions]
      ['places' (ja places-json)]
      ['vehicles' (ja vehicles-json)]
  ==
::
::  The specification key one relation writes. `+decode-spec-object` reads
::  these names, so the list here follows `spec-view-order` exactly.
++  spec-key
  |=  relation=@tas
  ^-  @t
  ?+  relation  'specNotes'
    %vehicle-vin            'specVin'
    %vehicle-license-plate  'specPlate'
    %vehicle-model-year     'specYear'
    %vehicle-make           'specMake'
    %vehicle-model          'specModel'
    %vehicle-sub-model      'specSubModel'
    %vehicle-body-type      'specBodyType'
    %vehicle-color          'specColor'
    %vehicle-engine         'specEngine'
    %vehicle-transmission   'specTransmission'
    %vehicle-drive-type     'specDriveType'
    %vehicle-bed-type       'specBedType'
    %vehicle-notes          'specNotes'
  ==
--
