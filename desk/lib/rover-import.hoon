/-  ast=obelisk-ast, rover
/+  act=rover-act, render=rover-render, view=rover-view
|%
++  starts-with
  |=  [hay=tape needle=tape]
  ^-  ?
  ?~  needle
    %.y
  ?~  hay
    %.n
  ?&  =(i.hay i.needle)
      $(hay t.hay, needle t.needle)
  ==
::
++  contains
  |=  [hay=tape needle=tape]
  ^-  ?
  ?:  (starts-with hay needle)
    %.y
  ?~  hay
    %.n
  $(hay t.hay)
::
++  fill-volume-unit
  |=  profile=price-profile:rover
  ^-  @tas
  ?:(=(%us-usd-gal profile) %gal %litre)
::
++  effective-station-label
  |=  input=fill-entry:rover
  ^-  (unit @t)
  ?^  station-label.input
    station-label.input
  ?^  new-station.input
    `station-label.u.new-station.input
  ~
::
++  canonical-fill
  |=  input=fill-entry:rover
  ^-  fill-entry:rover
  =/  tags=(list @t)
    ?~  new-tag-label.input
      tag-labels.input
    [u.new-tag-label.input tag-labels.input]
  %_  input
    station-label  (effective-station-label input)
    new-station    ~
    tag-labels     tags
    new-tag-label  ~
  ==
::
++  unit-mismatches
  |=  vehicle=import-vehicle:rover
  ^-  (list @t)
  =/  mismatches=(list @t)  ~
  =/  fills  fills.vehicle
  |-
  ?~  fills
    (flop mismatches)
  =/  input  input.i.fills
  =/  name
    %-  crip
    ;:  weld
      (trip label.vehicle)
      " / "
      (scow %da observed-start.input)
    ==
  =.  mismatches
    ?:  !=((fill-volume-unit price-profile.input) volume-unit.vehicle)
      [(cat 3 name ': volume unit') mismatches]
    mismatches
  =.  mismatches
    ?:  ?&  ?=(^ mileage.input)
            !=(odo-unit.u.mileage.input distance-unit.vehicle)
        ==
      [(cat 3 name ': distance unit') mismatches]
    mismatches
  $(fills t.fills)
::
++  fill-unit-mismatches
  |=  [distance-unit=distance-unit:rover volume-unit=@tas fill=import-fill:rover]
  ^-  (list @t)
  =/  input  input.fill
  =/  mismatches=(list @t)  ~
  =.  mismatches
    ?:  !=((fill-volume-unit price-profile.input) volume-unit)
      ['volume-unit' mismatches]
    mismatches
  =.  mismatches
    ?:  ?&  ?=(^ mileage.input)
            !=(odo-unit.u.mileage.input distance-unit)
        ==
      ['distance-unit' mismatches]
    mismatches
  (flop mismatches)
::
++  fill-name
  |=  fill=import-fill:rover
  ^-  @t
  %-  crip
  ;:  weld
    (trip vehicle-label.input.fill)
    " / "
    (scow %da observed-start.input.fill)
  ==
::
++  work-name
  |=  work=import-work:rover
  ^-  @t
  ?-  -.work
    %energy  (cat 3 'energy definition ' label.value.work)
    %simple
      %-  crip
      ;:  weld
        (trip (scot %tas kind.work))
        " definition "
        (trip label.value.work)
      ==
    %place  (cat 3 'place ' label.value.work)
    %vehicle  (cat 3 'vehicle ' label.value.work)
    %fill  (fill-name value.work)
  ==
::
++  fill-work-value
  |=  work=import-work:rover
  ^-  import-fill:rover
  ?+  -.work  !!
    %fill  value.work
  ==
::
++  empty-report
  ^-  import-report:rover
  [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ~]
::
++  initial-report
  |=  document=import-document:rover
  ^-  import-report:rover
  =/  report  empty-report
  =/  vehicles  vehicles.document
  |-
  ?~  vehicles
    report
  =/  vehicle  i.vehicles
  =/  mismatches  (unit-mismatches vehicle)
  =.  report
    %_  report
      unit-mismatches  (add unit-mismatches.report (lent mismatches))
      messages         (weld messages.report mismatches)
    ==
  =/  fills  fills.vehicle
  |-
  ?~  fills
    ^$(vehicles t.vehicles, report report)
  =/  fill  i.fills
  =.  report
    ?:  ?=(~ (effective-station-label input.fill))
      report(station-none +(station-none.report))
    report
  =/  class  (source-total-class fill)
  =.  report
    ?~  class
      report
    ?-  u.class
      %exact       report(total-exact +(total-exact.report))
      %off-by-one  report(total-off-by-one +(total-off-by-one.report))
      %beyond      report(total-beyond +(total-beyond.report))
    ==
  $(fills t.fills)
::
++  join-fields
  |=  fields=(list @t)
  ^-  @t
  ?~  fields
    ''
  %-  crip
  ?~  t.fields
    (trip i.fields)
  ;:  weld
    (trip i.fields)
    ", "
    (trip (join-fields t.fields))
  ==
::
++  report-text
  |=  report=import-report:rover
  ^-  @t
  =/  lines=tape
    ;:  weld
      "Rover import complete\0a"
      "Fills: imported "
      (scow %ud imported.report)
      ", already-imported "
      (scow %ud already-imported.report)
      ", conflicts "
      (scow %ud conflicts.report)
      ", failures "
      (scow %ud failures.report)
      "\0aDefinitions: created "
      (scow %ud definitions-created.report)
      ", reused "
      (scow %ud definitions-reused.report)
      "\0aPlaces: created "
      (scow %ud places-created.report)
      ", reused "
      (scow %ud places-reused.report)
      "\0aVehicles: created "
      (scow %ud vehicles-created.report)
      ", reused "
      (scow %ud vehicles-reused.report)
      "\0aStation-none fills: "
      (scow %ud station-none.report)
      "\0aTotal cross-check: exact "
      (scow %ud total-exact.report)
      ", off-by-one "
      (scow %ud total-off-by-one.report)
      ", beyond "
      (scow %ud total-beyond.report)
      "\0aUnit mismatches: "
      (scow %ud unit-mismatches.report)
      "\0asourceEfficiency: ignored by the Hoon import path\0a"
    ==
  =/  messages  messages.report
  |-
  ?~  messages
    (crip lines)
  $(messages t.messages, lines ;:(weld lines "Detail: " (trip i.messages) "\0a"))
::
++  source-total-class
  |=  fill=import-fill:rover
  ^-  (unit ?(%exact %off-by-one %beyond))
  ?~  source-total.fill
    ~
  =/  input  input.fill
  =/  parsed
    (parse-decimal:render u.source-total.fill (lent (trip u.source-total.fill)))
  ?:  ?=(%| -.parsed)
    `%beyond
  =/  source-minor
    ?:  (lte places.p.parsed minor-unit-decimals.input)
      %+  mul  digits.p.parsed
      (pow-ten:render (sub minor-unit-decimals.input places.p.parsed))
    %+  round-div-half-up:act  digits.p.parsed
    (pow-ten:render (sub places.p.parsed minor-unit-decimals.input))
  =/  proof
    %:  derive-fill-total:act
        quantity-milli.input
        unit-price-mills.input
        minor-unit-decimals.input
        cash-increment-mills.input
        settlement-mode.input
    ==
  =/  minor-scale  (pow-ten:render minor-unit-decimals.input)
  =/  mills-per-minor  (div 1.000 minor-scale)
  =/  derived-minor  (div total-mills.proof mills-per-minor)
  =/  delta
    ?:  (gte derived-minor source-minor)
      (sub derived-minor source-minor)
    (sub source-minor derived-minor)
  ?:  =(0 delta)
    `%exact
  ?:(=(1 delta) `%off-by-one `%beyond)
::
++  urql-cord-safe
  |=  value=@t
  ^-  ?
  =/  chars  (trip value)
  |-
  ?~  chars
    %.y
  ?&  (gte i.chars 32)
      !=(i.chars 127)
      $(chars t.chars)
  ==
::
++  replace-fill-note
  |=  [commands=(list command:ast) note=@t]
  ^-  (each (list command:ast) @t)
  =/  out=(list command:ast)  ~
  =/  replaced=?  %.n
  |-
  ?~  commands
    ?:(replaced [%& (flop out)] [%| 'parsed script lacks one fill-notes insert'])
  =/  command  i.commands
  ?.  ?=(%crud-txn -.command)
    $(commands t.commands, out [command out])
  =/  transaction=crud-txn:ast  command
  ?.  ?=(%insert -.body.transaction)
    $(commands t.commands, out [command out])
  =/  insertion=insert:ast  +.body.transaction
  ?.  =(%fill-notes name.qualified-table.insertion)
    $(commands t.commands, out [command out])
  ?:  replaced
    [%| 'parsed script contains more than one fill-notes insert']
  ?.  ?=([%data *] values.insertion)
    [%| 'fill-notes insert does not contain literal data']
  =/  rows=(list (list value-or-default:ast))  +.values.insertion
  ?.  =(1 (lent rows))
    [%| 'fill-notes insert does not contain one row']
  =/  row  (snag 0 rows)
  ?.  =(2 (lent row))
    [%| 'fill-notes insert does not contain two values']
  =/  patched-row=(list value-or-default:ast)
    [(snag 0 row) [%t note] ~]
  =/  patched-insertion=insert:ast
    insertion(values [%data [patched-row ~]])
  =/  patched-transaction=crud-txn:ast
    transaction(body [%insert patched-insertion])
  $(commands t.commands, out [patched-transaction out], replaced %.y)
::
++  unique-texts
  |=  values=(list @t)
  ^-  (list @t)
  ?~  values
    ~
  ?:  (lien t.values |=(value=@t =(i.values value)))
    $(values t.values)
  [i.values $(values t.values)]
::
++  vehicle-energy-labels
  |=  vehicle=import-vehicle:rover
  ^-  (list @t)
  =/  labels=(list @t)  [default-energy.vehicle ~]
  =/  fills  fills.vehicle
  |-
  ?~  fills
    (unique-texts (flop labels))
  $(fills t.fills, labels [definition-label.input.i.fills labels])
::
++  vehicle-mode-labels
  |=  vehicle=import-vehicle:rover
  ^-  (list @t)
  =/  labels=(list @t)  ~
  =/  fills  fills.vehicle
  |-
  ?~  fills
    (unique-texts (flop labels))
  =.  labels
    ?~  driving-mode-label.input.i.fills
      labels
    [u.driving-mode-label.input.i.fills labels]
  $(fills t.fills)
::
++  station-kind-for
  |=  [label=@t vehicles=(list import-vehicle:rover)]
  ^-  station-kind:rover
  ?~  vehicles
    %fuel
  =/  fills  fills.i.vehicles
  |-
  ?~  fills
    (station-kind-for label t.vehicles)
  ?^  new-station.input.i.fills
    ?:  =(label place-label.u.new-station.input.i.fills)
      station-kind.u.new-station.input.i.fills
    $(fills t.fills)
  $(fills t.fills)
::
++  import-works
  |=  document=import-document:rover
  ^-  (list import-work:rover)
  =/  energy-work
    %+  turn  energy.definitions.document
    |=  value=import-energy-definition:rover
    ^-  import-work:rover
    [%energy value]
  =/  simples
    |=  [kind=import-simple-kind:rover values=(list import-simple-definition:rover)]
    ^-  (list import-work:rover)
    %+  turn  values
    |=  value=import-simple-definition:rover
    ^-  import-work:rover
    [%simple kind value]
  =/  simple-work
    ;:  weld
      (simples %additive additives.definitions.document)
      (simples %driving-mode driving-modes.definitions.document)
      (simples %tag tags.definitions.document)
      (simples %payment-method payment-methods.definitions.document)
    ==
  =/  place-work
    %+  turn  places.document
    |=  value=import-place:rover
    ^-  import-work:rover
    [%place (station-kind-for label.value vehicles.document) value]
  =/  vehicle-work
    %+  turn  vehicles.document
    |=  value=import-vehicle:rover
    ^-  import-work:rover
    [%vehicle value]
  =/  fill-work
    =/  build
      |=  values=(list import-vehicle:rover)
      ^-  (list import-work:rover)
      ?~  values
        ~
      =/  vehicle  i.values
      %+  weld
        %+  turn  fills.vehicle
        |=  value=import-fill:rover
        ^-  import-work:rover
        [%fill distance-unit.vehicle volume-unit.vehicle value]
      $(values t.values)
    (build vehicles.document)
  ;:  weld
    energy-work
    simple-work
    place-work
    vehicle-work
    fill-work
  ==
::
++  simple-table
  |=  kind=import-simple-kind:rover
  ^-  [table=@t id=@t]
  ?-  kind
    %additive
      ['additive-definitions' 'additive-id']
    %driving-mode
      ['driving-mode-definitions' 'mode-id']
    %tag
      ['tag-definitions' 'tag-id']
    %payment-method
      ['payment-method-definitions' 'method-id']
  ==
::
++  energy-lookup
  |=  label=@t
  ^-  tape
  ;:  weld
    "FROM energy-definitions E WHERE E.label = '"
    (sql-quote:act label)
    "' SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived;"
  ==
::
++  simple-lookup
  |=  [kind=import-simple-kind:rover label=@t]
  ^-  tape
  =/  meta  (simple-table kind)
  ;:  weld
    "FROM "
    (trip table.meta)
    " D WHERE D.label = '"
    (sql-quote:act label)
    "' SELECT D."
    (trip id.meta)
    ", D.label, D.archived;"
  ==
::
++  place-lookup
  |=  label=@t
  ^-  tape
  =/  quoted  (sql-quote:act label)
  ;:  weld
    "FROM places P WHERE P.label = '"
    quoted
    "' SELECT P.place-id, P.label, P.archived; "
    "FROM stations S JOIN places P ON S.place-id = P.place-id WHERE S.label = '"
    quoted
    "' SELECT S.station-id, S.place-id, S.label, S.station-kind, S.archived, P.label AS place;"
  ==
::
++  label-predicate
  |=  [alias=@t labels=(list @t)]
  ^-  tape
  ?~  labels
    ;:  weld
      (trip alias)
      ".label = ''"
    ==
  =/  row
    ;:  weld
      (trip alias)
      ".label = '"
      (sql-quote:act i.labels)
      "'"
    ==
  ?~  t.labels
    row
  ;:  weld
    row
    " OR "
    $(labels t.labels)
  ==
::
++  active-label-predicate
  |=  [alias=@t labels=(list @t)]
  ^-  tape
  ?~  labels
    ;:  weld
      (trip alias)
      ".label = '' AND "
      (trip alias)
      ".archived = N"
    ==
  =/  row
    ;:  weld
      (trip alias)
      ".label = '"
      (sql-quote:act i.labels)
      "' AND "
      (trip alias)
      ".archived = N"
    ==
  ?~  t.labels
    row
  ;:  weld
    row
    " OR "
    $(labels t.labels)
  ==
::
++  vehicle-lookup
  |=  vehicle=import-vehicle:rover
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote:act label.vehicle)
    "' SELECT V.vehicle-id, V.label, V.archived; "
    "FROM energy-definitions E WHERE "
    (active-label-predicate 'E' (vehicle-energy-labels vehicle))
    " SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived; "
    "FROM driving-mode-definitions D WHERE "
    (active-label-predicate 'D' (vehicle-mode-labels vehicle))
    " SELECT D.mode-id, D.label, D.archived;"
  ==
::
++  work-lookup
  |=  work=import-work:rover
  ^-  tape
  ?-  -.work
    %energy
      (energy-lookup label.value.work)
    %simple
      (simple-lookup kind.work label.value.work)
    %place
      (place-lookup label.value.work)
    %vehicle
      (vehicle-lookup value.work)
    %fill
      (fill-existing-lookup value.work)
  ==
::
++  insert-energy
  |=  [base=@ux input=import-energy-definition:rover recorded-at=@da]
  ^-  tape
  =/  definition-id  (fixture-id:act base 1)
  =/  definition
    %:  insert-energy-source-type:act
        definition-id
        label.input
        physical-kind.input
        quantity-unit.input
        recorded-at
    ==
  =/  subtypes
    |=  [values=(list import-energy-subtype:rover) ordinal=@ud]
    ^-  tape
    ?~  values
      ~
    =/  subtype-id  (fixture-id:act base (add 10 ordinal))
    =/  value  i.values
    =/  rating=tape
      ?^  octane.value
        ;:  weld
          " INSERT INTO energy-subtype-octane VALUES ("
          (scow %ux subtype-id)
          ", "
          (sql-ud:act u.octane.value)
          ", "
          (sql-term:act (need octane-method.value))
          ");"
        ==
      ?^  cetane.value
        ;:  weld
          " INSERT INTO energy-subtype-cetane VALUES ("
          (scow %ux subtype-id)
          ", "
          (sql-ud:act u.cetane.value)
          ");"
        ==
      ~
    ;:  weld
      " INSERT INTO energy-definition-subtypes VALUES ("
      (scow %ux subtype-id)
      ", "
      (scow %ux definition-id)
      ", '"
      (sql-quote:act label.value)
      "', N, "
      (scow %da recorded-at)
      ");"
      rating
      $(values t.values, ordinal +(ordinal))
    ==
  (weld definition (subtypes subtypes.input 0))
::
++  insert-simple
  |=  [base=@ux kind=import-simple-kind:rover label=@t recorded-at=@da]
  ^-  tape
  =/  meta  (simple-table kind)
  ;:  weld
    "INSERT INTO "
    (trip table.meta)
    " VALUES ("
    (scow %ux (fixture-id:act base 1))
    ", '"
    (sql-quote:act label)
    "', N, "
    (scow %da recorded-at)
    ");"
  ==
::
++  insert-address-parts
  |=  [place-id=@ux parts=(list [part=address-part:rover value=@t])]
  ^-  tape
  ?~  parts
    ~
  ;:  weld
    " INSERT INTO place-address-parts VALUES ("
    (scow %ux place-id)
    ", "
    (sql-term:act part.i.parts)
    ", '"
    (sql-quote:act value.i.parts)
    "');"
    $(parts t.parts)
  ==
::
++  insert-place
  |=  $:  base=@ux
          input=import-place:rover
          station-kind=station-kind:rover
          existing-place-id=(unit @ux)
          recorded-at=@da
      ==
  ^-  tape
  =/  place-id  ?~(existing-place-id (fixture-id:act base 1) u.existing-place-id)
  =/  place-row=tape
    ?^  existing-place-id
      ~
    ;:  weld
      "INSERT INTO places VALUES ("
      (scow %ux place-id)
      ", '"
      (sql-quote:act label.input)
      "', N, "
      (scow %da recorded-at)
      ");"
    ==
  =/  address-rows=tape
    ?:  ?|  ?=(^ existing-place-id)
            ?=(~ address.input)
        ==
      ~
    =/  address  u.address.input
    =/  formatted-row=tape
      ?~  formatted.address
        ~
      ;:  weld
        " INSERT INTO place-address-formatted VALUES ("
        (scow %ux place-id)
        ", '"
        (sql-quote:act u.formatted.address)
        "');"
      ==
    ;:  weld
      " INSERT INTO place-addresses VALUES ("
      (scow %ux place-id)
      ", %imported, "
      (scow %da recorded-at)
      ");"
      formatted-row
      (insert-address-parts place-id parts.address)
    ==
  =/  coordinate-row=tape
    ?:  ?|  ?=(^ existing-place-id)
            ?=(~ coordinates.input)
        ==
      ~
    ;:  weld
      " INSERT INTO place-coordinates VALUES ("
      (scow %ux place-id)
      ", "
      (scow %sd latitude.u.coordinates.input)
      ", "
      (scow %sd longitude.u.coordinates.input)
      ", 7, "
      (sql-term:act source.u.coordinates.input)
      ", "
      (scow %da recorded-at)
      ");"
    ==
  ;:  weld
    place-row
    " INSERT INTO stations VALUES ("
    (scow %ux (fixture-id:act base 2))
    ", "
    (scow %ux place-id)
    ", '"
    (sql-quote:act label.input)
    "', "
    (sql-term:act station-kind)
    ", N, "
    (scow %da recorded-at)
    ");"
    address-rows
    coordinate-row
  ==
::
++  insert-import-vehicle
  |=  $:  base=@ux
          input=import-vehicle:rover
          default-definition-id=@ux
          definition-ids=(list @ux)
          mode-ids=(list @ux)
          recorded-at=@da
      ==
  ^-  tape
  =/  vehicle-id  (fixture-id:act base 1)
  =/  tank-row=tape
    ?~  tank-size.input
      ~
    ;:  weld
      " INSERT INTO vehicle-tank-size VALUES ("
      (scow %ux vehicle-id)
      ", "
      (sql-ud:act digits.u.tank-size.input)
      ", "
      (sql-ud:act places.u.tank-size.input)
      ", "
      (sql-term:act value-unit.u.tank-size.input)
      ");"
    ==
  ;:  weld
    %:  insert-vehicle:act
        vehicle-id
        label.input
        default-definition-id
        (unique-ids:act definition-ids)
        (unique-ids:act mode-ids)
        ~
        ~
        recorded-at
    ==
    tank-row
  ==
::
++  fill-existing-lookup
  |=  fill=import-fill:rover
  ^-  tape
  =/  source
    ;:  weld
      "I.source-app = "
      (sql-term:act source-app.fill)
      " AND I.source-record-id = '"
      (sql-quote:act source-record-id.fill)
      "'"
    ==
  ;:  weld
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN vehicles V ON A.vehicle-id = V.vehicle-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE "
    source
    " SELECT A.acquisition-id, V.label AS vehicle, E.label AS definition, A.observed-start, A.observed-end, A.observed-precision, A.source-zone, F.quantity-milli, F.quantity-unit, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills;"
  ==
::
++  fill-comparison-lookup
  |=  fill=import-fill:rover
  ^-  tape
  =/  source
    ;:  weld
      "I.source-app = "
      (sql-term:act source-app.fill)
      " AND I.source-record-id = '"
      (sql-quote:act source-record-id.fill)
      "'"
    ==
  ;:  weld
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-odometers L ON A.acquisition-id = L.acquisition-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE "
    source
    " SELECT O.value-digits, O.decimal-places, O.unit, O.observed-start, O.observed-end, O.observed-precision, O.source-zone; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN energy-acquisition-stations L ON A.acquisition-id = L.acquisition-id JOIN stations S ON L.station-id = S.station-id WHERE "
    source
    " SELECT S.label AS station; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE "
    source
    " SELECT S.label AS subtype; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-additives L ON A.acquisition-id = L.acquisition-id JOIN additive-definitions D ON L.additive-id = D.additive-id WHERE "
    source
    " SELECT D.label AS additive; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN economy-breaks B ON A.acquisition-id = B.acquisition-id WHERE "
    source
    " SELECT B.reason; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-driving-mode L ON A.acquisition-id = L.acquisition-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE "
    source
    " SELECT D.label AS driving-mode;"
  ==
::
++  fill-comparison-tail-lookup
  |=  fill=import-fill:rover
  ^-  tape
  =/  source
    ;:  weld
      "I.source-app = "
      (sql-term:act source-app.fill)
      " AND I.source-record-id = '"
      (sql-quote:act source-record-id.fill)
      "'"
    ==
  ;:  weld
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-average-speed S ON A.acquisition-id = S.acquisition-id WHERE "
    source
    " SELECT S.digits, S.decimals, S.speed-unit; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-drive-balance B ON A.acquisition-id = B.acquisition-id WHERE "
    source
    " SELECT B.highway-percent; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-tags L ON A.acquisition-id = L.acquisition-id JOIN tag-definitions T ON L.tag-id = T.tag-id WHERE "
    source
    " SELECT T.label AS tag; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fill-notes Q ON A.acquisition-id = Q.acquisition-id WHERE "
    source
    " SELECT Q.note; "
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN fuel-fill-payment-method L ON A.acquisition-id = L.acquisition-id JOIN payment-method-definitions P ON L.method-id = P.method-id WHERE "
    source
    " SELECT P.label AS payment-method;"
  ==
::
++  fill-support-lookup
  |=  fill=import-fill:rover
  ^-  tape
  =/  input  (canonical-fill input.fill)
  =/  station-labels=(list @t)
    ?~  station-label.input  ~  [u.station-label.input ~]
  =/  subtype-labels=(list @t)
    ?~  subtype-label.input  ~  [u.subtype-label.input ~]
  =/  mode-labels=(list @t)
    ?~  driving-mode-label.input  ~  [u.driving-mode-label.input ~]
  =/  payment-labels=(list @t)
    ?~  payment-method-label.input  ~  [u.payment-method-label.input ~]
  ;:  weld
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = '"
    (sql-quote:act vehicle-label.input)
    "' AND E.label = '"
    (sql-quote:act definition-label.input)
    "' AND V.archived = N AND L.archived = N AND E.archived = N SELECT V.vehicle-id, E.energy-definition-id, E.quantity-unit, E.physical-kind; "
    "FROM stations S WHERE "
    (active-label-predicate 'S' station-labels)
    " SELECT S.station-id, S.label; "
    "FROM additive-definitions D WHERE "
    (active-label-predicate 'D' additive-labels.input)
    " SELECT D.additive-id, D.label; "
    "FROM energy-definition-subtypes S JOIN energy-definitions E ON S.energy-definition-id = E.energy-definition-id WHERE E.label = '"
    (sql-quote:act definition-label.input)
    "' AND "
    (label-predicate 'S' subtype-labels)
    " AND S.archived = N SELECT S.subtype-id, S.label; "
    "FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '"
    (sql-quote:act vehicle-label.input)
    "' AND "
    (label-predicate 'D' mode-labels)
    " AND D.archived = N AND L.archived = N SELECT D.mode-id, D.label; "
    "FROM tag-definitions T WHERE "
    (active-label-predicate 'T' tag-labels.input)
    " SELECT T.tag-id, T.label; "
    "FROM payment-method-definitions P WHERE "
    (label-predicate 'P' payment-labels)
    " AND P.archived = N SELECT P.method-id, P.label;"
  ==
::
++  row-texts
  |=  [key=@tas rows=(list vector:ast)]
  ^-  (list @t)
  %+  turn  rows
  |=  row=vector:ast
  (cell-text:view key row)
::
++  same-texts
  |=  [expected=(list @t) key=@tas rows=(list vector:ast)]
  ^-  ?
  =((sort expected aor) (sort (row-texts key rows) aor))
::
++  optional-text-diff
  |=  [expected=(unit @t) key=@tas rows=(list vector:ast)]
  ^-  ?
  ?~  expected
    ?=(^ rows)
  ?|  !=(1 (lent rows))
      !=(u.expected (cell-text:view key (snag 0 rows)))
  ==
::
++  add-diff
  |=  [different=? field=@t differences=(list @t)]
  ^-  (list @t)
  ?:(different [field differences] differences)
::
++  existing-main-differences
  |=  [fill=import-fill:rover commands=(list cmd-result:ast)]
  ^-  (list @t)
  =/  input  (canonical-fill input.fill)
  =/  main  (rows-at:view commands 0)
  ?.  =(1 (lent main))
    ['provenance' ~]
  =/  row  (snag 0 main)
  =/  differences=(list @t)  ~
  =.  differences
    (add-diff !=(vehicle-label.input (cell-text:view %vehicle row)) 'vehicle' differences)
  =.  differences
    (add-diff !=(definition-label.input (cell-text:view %definition row)) 'definition' differences)
  =.  differences
    (add-diff !=(observed-start.input (cell-atom:view %observed-start row)) 'observed' differences)
  =.  differences
    (add-diff !=((add observed-start.input (bex 64)) (cell-atom:view %observed-end row)) 'observed' differences)
  =.  differences
    (add-diff !=(%second (cell-term:view %observed-precision row)) 'observed' differences)
  =.  differences
    (add-diff !=(source-zone.input (cell-text:view %source-zone row)) 'zone' differences)
  =.  differences
    (add-diff !=(quantity-milli.input (cell-atom:view %quantity-milli row)) 'quantity' differences)
  =.  differences
    (add-diff !=((fill-volume-unit price-profile.input) (cell-term:view %quantity-unit row)) 'quantity-unit' differences)
  =.  differences
    (add-diff !=(tank-state.input (cell-term:view %tank-state row)) 'tank-state' differences)
  =.  differences
    (add-diff !=(unit-price-mills.input (cell-atom:view %unit-price-mills row)) 'unit-price' differences)
  =.  differences
    (add-diff !=(currency.input (cell-term:view %currency row)) 'currency' differences)
  =.  differences
    (add-diff !=(settlement-mode.input (cell-term:view %settlement-mode row)) 'settlement' differences)
  =.  differences
    (add-diff !=(price-profile.input (cell-term:view %price-profile row)) 'profile' differences)
  =.  differences
    (add-diff !=(minor-unit-decimals.input (cell-atom:view %minor-unit-decimals row)) 'minor-unit-decimals' differences)
  =.  differences
    (add-diff !=(cash-increment-mills.input (cell-atom:view %cash-increment-mills row)) 'cash-increment' differences)
  (flop differences)
::
++  existing-child-differences
  |=  [fill=import-fill:rover commands=(list cmd-result:ast)]
  ^-  (list @t)
  =/  input  (canonical-fill input.fill)
  =/  differences=(list @t)  ~
  =/  odometers  (rows-at:view commands 0)
  =/  odometer-diff=?
    ?~  mileage.input
      ?=(^ odometers)
    ?|  !=(1 (lent odometers))
        !=(digits.u.mileage.input (cell-atom:view %value-digits (snag 0 odometers)))
        !=(places.u.mileage.input (cell-atom:view %decimal-places (snag 0 odometers)))
        !=(odo-unit.u.mileage.input (cell-term:view %unit (snag 0 odometers)))
        !=(observed-start.input (cell-atom:view %observed-start (snag 0 odometers)))
        !=((add observed-start.input (bex 64)) (cell-atom:view %observed-end (snag 0 odometers)))
        !=(%second (cell-term:view %observed-precision (snag 0 odometers)))
        !=(source-zone.input (cell-text:view %source-zone (snag 0 odometers)))
    ==
  =.  differences  (add-diff odometer-diff 'odometer' differences)
  =.  differences
    (add-diff (optional-text-diff station-label.input %station (rows-at:view commands 1)) 'station' differences)
  =.  differences
    (add-diff (optional-text-diff subtype-label.input %subtype (rows-at:view commands 2)) 'subtype' differences)
  =.  differences
    (add-diff =(%.n (same-texts additive-labels.input %additive (rows-at:view commands 3))) 'additives' differences)
  =/  breaks  (rows-at:view commands 4)
  =/  break-diff
    ?:  missed-fill.input
      ?|  !=(1 (lent breaks))
          !=(%missed-fill (cell-term:view %reason (snag 0 breaks)))
      ==
    ?=(^ breaks)
  =.  differences  (add-diff break-diff 'missed-fill' differences)
  =.  differences
    (add-diff (optional-text-diff driving-mode-label.input %driving-mode (rows-at:view commands 5)) 'driving-mode' differences)
  (flop differences)
::
++  existing-tail-differences
  |=  [fill=import-fill:rover commands=(list cmd-result:ast)]
  ^-  (list @t)
  =/  input  (canonical-fill input.fill)
  =/  differences=(list @t)  ~
  =/  speeds  (rows-at:view commands 0)
  =/  speed-diff
    ?~  average-speed.input
      ?=(^ speeds)
    ?|  !=(1 (lent speeds))
        !=(digits.u.average-speed.input (cell-atom:view %digits (snag 0 speeds)))
        !=(places.u.average-speed.input (cell-atom:view %decimals (snag 0 speeds)))
        !=(value-unit.u.average-speed.input (cell-term:view %speed-unit (snag 0 speeds)))
    ==
  =.  differences  (add-diff speed-diff 'average-speed' differences)
  =/  balances  (rows-at:view commands 1)
  =/  balance-diff
    ?~  drive-balance.input
      ?=(^ balances)
    ?|  !=(1 (lent balances))
        !=(u.drive-balance.input (cell-atom:view %highway-percent (snag 0 balances)))
    ==
  =.  differences  (add-diff balance-diff 'drive-balance' differences)
  =.  differences
    (add-diff =(%.n (same-texts tag-labels.input %tag (rows-at:view commands 2))) 'tags' differences)
  =.  differences
    (add-diff (optional-text-diff notes.input %note (rows-at:view commands 3)) 'notes' differences)
  =.  differences
    (add-diff (optional-text-diff payment-method-label.input %payment-method (rows-at:view commands 4)) 'payment-method' differences)
  (flop differences)
::
++  insert-import-fill
  |=  $:  ids=entry-ids:act
          vehicle-id=@ux
          definition-id=@ux
          quantity-unit=@tas
          station-id=(unit @ux)
          additive-ids=(list @ux)
          subtype-id=(unit @ux)
          driving-mode-id=(unit @ux)
          tag-ids=(list @ux)
          payment-method-id=(unit @ux)
          input=fill-entry:rover
          source-app=@tas
          source-record-id=@t
          recorded-at=@da
      ==
  ^-  tape
  ;:  weld
    %:  insert-fill:act
        ids
        vehicle-id
        definition-id
        quantity-unit
        station-id
        additive-ids
        subtype-id
        driving-mode-id
        tag-ids
        payment-method-id
        input
        recorded-at
    ==
    " INSERT INTO acquisition-imports VALUES ("
    (scow %ux acquisition.ids)
    ", "
    (sql-term:act source-app)
    ", '"
    (sql-quote:act source-record-id)
    "');"
  ==
--
