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
++  event-name
  |=  event=import-event:rover
  ^-  @t
  %-  crip
  ;:  weld
    (trip (scot %tas kind.input.event))
    " event "
    (trip vehicle-label.input.event)
    " / "
    (scow %da observed-start.input.event)
  ==
::
++  reminder-name
  |=  input=reminder-entry:rover
  ^-  @t
  %-  crip
  ;:  weld
    "reminder "
    (trip vehicle-label.input)
    " / "
    (trip subtype-label.input)
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
    %spec  (cat 3 'specification of ' vehicle-label.work)
    %event  (event-name value.work)
    %reminder  (reminder-name value.work)
  ==
::
++  fill-work-value
  |=  work=import-work:rover
  ^-  import-fill:rover
  ?+  -.work  !!
    %fill  value.work
  ==
::
++  event-work-value
  |=  work=import-work:rover
  ^-  import-event:rover
  ?+  -.work  !!
    %event  value.work
  ==
::
++  empty-report
  ^-  import-report:rover
  [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ~ ~]
::
++  initial-report
  |=  document=import-document:rover
  ^-  import-report:rover
  =/  report  empty-report
  ::  The converter read the source, so only the converter knows what the
  ::  source held and Rover does not carry. The notices ride the document and
  ::  reach the report a person reads after the import.
  =.  notices.report  notices.document
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
++  notice-lines
  |=  notices=(list import-notice:rover)
  ^-  tape
  ?~  notices
    ~
  ;:  weld
    "  "
    (trip kind.i.notices)
    ": "
    (scow %ud count.i.notices)
    " - "
    (trip reason.i.notices)
    "\0a"
    $(notices t.notices)
  ==
::
::  The report is a product surface. A person reads it to decide whether to
::  trust the import, so it says what came in, what was already there, what
::  was refused, and what the source held that Rover does not carry. Every
::  line names a thing in words rather than a relation or a column.
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
      "\0aEvents: imported "
      (scow %ud events-imported.report)
      ", already-imported "
      (scow %ud events-already-imported.report)
      ", conflicts "
      (scow %ud events-conflicted.report)
      ", service-subtype links "
      (scow %ud event-subtype-links.report)
      "\0aReminders: imported "
      (scow %ud reminders-imported.report)
      ", already-imported "
      (scow %ud reminders-already-imported.report)
      "\0aSpecification fields: written "
      (scow %ud spec-fields-written.report)
      ", already-held "
      (scow %ud spec-fields-already.report)
      ", conflicts "
      (scow %ud spec-fields-conflicted.report)
      "\0aDefinitions: created "
      (scow %ud definitions-created.report)
      ", reused "
      (scow %ud definitions-reused.report)
      "\0aService subtypes: created "
      (scow %ud subtypes-created.report)
      ", reused "
      (scow %ud subtypes-reused.report)
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
  ::  What the source held and Rover did not take. Silence is the failure
  ::  mode: a dropped record the owner finds months later is worse than a
  ::  line that says what was left and why.
  =.  lines
    ?~  notices.report
      lines
    ;:  weld
      lines
      "Not imported, and why\0a"
      (notice-lines notices.report)
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
::  A note may hold a character urQL cannot carry inside a literal - a
::  newline is the common one. Rover parses its own script to an AST and puts
::  the note in as a typed value instead of as text, so the note is stored
::  exactly as the owner wrote it.
::
::  The relation is an argument because two relations hold a note: `fill-notes`
::  for a fuel fill and `vehicle-event-notes` for a vehicle event. Both rows
::  are (key, note), so one arm serves both.
++  replace-note
  |=  [commands=(list command:ast) relation=@tas note=@t]
  ^-  (each (list command:ast) @t)
  =/  missing  (cat 3 'parsed script lacks one insert into ' (scot %tas relation))
  =/  repeated
    (cat 3 'parsed script has more than one insert into ' (scot %tas relation))
  =/  malformed
    (cat 3 'the note insert is not one two-value row in ' (scot %tas relation))
  =/  out=(list command:ast)  ~
  =/  replaced=?  %.n
  |-
  ?~  commands
    ?:(replaced [%& (flop out)] [%| missing])
  =/  command  i.commands
  ?.  ?=(%crud-txn -.command)
    $(commands t.commands, out [command out])
  =/  transaction=crud-txn:ast  command
  ?.  ?=(%insert -.body.transaction)
    $(commands t.commands, out [command out])
  =/  insertion=insert:ast  +.body.transaction
  ?.  =(relation name.qualified-table.insertion)
    $(commands t.commands, out [command out])
  ?:  replaced
    [%| repeated]
  ?.  ?=([%data *] values.insertion)
    [%| malformed]
  =/  rows=(list (list value-or-default:ast))  +.values.insertion
  ?.  =(1 (lent rows))
    [%| malformed]
  =/  row  (snag 0 rows)
  ?.  =(2 (lent row))
    [%| malformed]
  =/  patched-row=(list value-or-default:ast)
    [(snag 0 row) [%t note] ~]
  =/  patched-insertion=insert:ast
    insertion(values [%data [patched-row ~]])
  =/  patched-transaction=crud-txn:ast
    transaction(body [%insert patched-insertion])
  $(commands t.commands, out [patched-transaction out], replaced %.y)
::
::  Which relation holds the note for this kind of work, and what the note is.
::  An empty answer means the work carries no note that needs the parse path.
++  work-note
  |=  work=import-work:rover
  ^-  (unit [relation=@tas note=@t])
  ?+  -.work  ~
    %fill
      ?~  notes.input.value.work
        ~
      `[%fill-notes u.notes.input.value.work]
    %event
      ?~  notes.input.value.work
        ~
      `[%vehicle-event-notes u.notes.input.value.work]
  ==
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
::  M7 T9. Which specification fields the vehicle already holds, and which the
::  document would add. One query per relation, in `spec-view-order`, exactly
::  as the vehicle screen reads them. No join: a fresh database holds no
::  specification row at all, and a join whose leftmost relation is empty
::  crashes the pinned engine.
++  spec-lookup
  |=  label=@t
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote:act label)
    "' SELECT V.vehicle-id; "
    spec-queries:act
  ==
::
::  The thirteen fields, paired with the value the document carries, in the
::  order `spec-queries` returns them.
++  spec-import-fields
  |=  input=vehicle-spec-entry:rover
  ^-  (list [relation=@tas column=@tas value=(unit @t)])
  =/  text
    |=  value=spec-text:rover
    ^-  (unit @t)
    ?~(value ~ u.value)
  ::  Plain digits, because `sql-ud` is what writes the column and what reads
  ::  it back. `scow` would put Hoon's dot separators in, and 2.019 never
  ::  equals the 2019 the database holds.
  =/  year=(unit @t)
    ?~  model-year.input
      ~
    ?~  u.model-year.input
      ~
    `(crip (sql-ud:act u.u.model-year.input))
  :~  [%vehicle-vin %vin (text vin.input)]
      [%vehicle-license-plate %plate (text plate.input)]
      [%vehicle-model-year %model-year year]
      [%vehicle-make %make (text make.input)]
      [%vehicle-model %model (text model.input)]
      [%vehicle-sub-model %sub-model (text sub-model.input)]
      [%vehicle-body-type %body-type (text body-type.input)]
      [%vehicle-color %color (text color.input)]
      [%vehicle-engine %engine (text engine.input)]
      [%vehicle-transmission %transmission (text transmission.input)]
      [%vehicle-drive-type %drive-type (text drive-type.input)]
      [%vehicle-bed-type %bed-type (text bed-type.input)]
      [%vehicle-notes %note (text note.input)]
  ==
::
::  One INSERT per field the vehicle does NOT already hold. There is no DELETE
::  here, and that is the point: import adds evidence and never overwrites a
::  value the owner corrected in Rover after an earlier run. A field whose
::  stored value differs is reported as a conflict by the caller.
++  insert-spec-field
  |=  [vehicle-id=@ux relation=@tas value=@t stamped=(unit @da)]
  ^-  tape
  ::  The model year is the one number in the family. Every other field is
  ::  text and travels quoted.
  =/  literal=tape
    ?:  =(%vehicle-model-year relation)
      (trip value)
    ;:  weld
      "'"
      (sql-quote:act value)
      "'"
    ==
  =/  stamp=tape
    ?~  stamped
      ~
    (weld ", " (scow %da u.stamped))
  ;:  weld
    "INSERT INTO "
    (trip relation)
    " VALUES ("
    (scow %ux vehicle-id)
    ", "
    literal
    stamp
    "); "
  ==
::
::  M7 T9. Has this event already arrived, and does it still say what it said?
::  The provenance row answers the first question exactly. The typed child and
::  the entered total answer the second, and the associations follow in
::  `event-comparison-lookup`.
++  event-existing-lookup
  |=  event=import-event:rover
  ^-  tape
  =/  source
    ;:  weld
      "I.source-app = "
      (sql-term:act source-app.event)
      " AND I.source-record-id = '"
      (sql-quote:act source-record-id.event)
      "'"
    ==
  =/  join
    "FROM vehicle-events E JOIN event-imports I ON E.event-id = I.event-id "
  ;:  weld
    join
    "JOIN vehicles V ON E.vehicle-id = V.vehicle-id WHERE "
    source
    " SELECT E.event-id, V.label AS vehicle, E.observed-start, E.observed-end, E.observed-precision, E.source-zone; "
    join
    "JOIN service-events C ON E.event-id = C.event-id WHERE "
    source
    " SELECT C.event-id AS child; "
    join
    "JOIN expense-events C ON E.event-id = C.event-id WHERE "
    source
    " SELECT C.event-id AS child; "
    join
    "JOIN note-events C ON E.event-id = C.event-id WHERE "
    source
    " SELECT C.event-id AS child; "
    join
    "JOIN vehicle-event-cost-totals T ON E.event-id = T.event-id WHERE "
    source
    " SELECT T.total-mills;"
  ==
::
++  event-comparison-lookup
  |=  event=import-event:rover
  ^-  tape
  =/  source
    ;:  weld
      "I.source-app = "
      (sql-term:act source-app.event)
      " AND I.source-record-id = '"
      (sql-quote:act source-record-id.event)
      "'"
    ==
  =/  join
    "FROM vehicle-events E JOIN event-imports I ON E.event-id = I.event-id "
  ;:  weld
    join
    "JOIN vehicle-event-odometers L ON E.event-id = L.event-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE "
    source
    " SELECT O.value-digits, O.decimal-places, O.unit; "
    join
    "JOIN vehicle-event-stations L ON E.event-id = L.event-id JOIN stations S ON L.station-id = S.station-id WHERE "
    source
    " SELECT S.label AS station; "
    join
    "JOIN vehicle-event-tags L ON E.event-id = L.event-id JOIN tag-definitions T ON L.tag-id = T.tag-id WHERE "
    source
    " SELECT T.label AS tag; "
    join
    "JOIN vehicle-event-service-subtypes L ON E.event-id = L.event-id JOIN service-subtype-definitions S ON L.service-subtype-id = S.service-subtype-id WHERE "
    source
    " SELECT S.label AS subtype; "
    join
    "JOIN vehicle-event-payment-method L ON E.event-id = L.event-id JOIN payment-method-definitions P ON L.method-id = P.method-id WHERE "
    source
    " SELECT P.label AS payment-method; "
    join
    ::  The alias is `Q`, not `N`. `N` is urQL's own literal for false - the
    ::  one `archived = N` writes - so the parser refuses it as a name.
    ::  `fill-notes Q` in the fill comparison already reads this way.
    "JOIN vehicle-event-notes Q ON E.event-id = Q.event-id WHERE "
    source
    " SELECT Q.note;"
  ==
::
::  M7 T9. A reminder is addressed by the vehicle and the service subtype it
::  names, which is what a person means by "the oil reminder on the truck".
::  A second import finds the row it wrote and adds nothing.
++  reminder-existing-lookup
  |=  input=reminder-entry:rover
  ^-  tape
  =/  predicate
    ;:  weld
      "V.label = '"
      (sql-quote:act vehicle-label.input)
      "' AND S.label = '"
      (sql-quote:act subtype-label.input)
      "'"
    ==
  =/  join
    ;:  weld
      "FROM service-reminders R JOIN vehicles V ON R.vehicle-id = V.vehicle-id "
      "JOIN service-subtype-definitions S ON R.service-subtype-id = S.service-subtype-id "
    ==
  ;:  weld
    join
    "WHERE "
    predicate
    " SELECT R.reminder-id, R.archived; "
    "FROM vehicles V WHERE V.label = '"
    (sql-quote:act vehicle-label.input)
    "' SELECT V.vehicle-id; "
    "FROM service-subtype-definitions S WHERE S.label = '"
    (sql-quote:act subtype-label.input)
    "' AND S.archived = N SELECT S.service-subtype-id, S.label;"
  ==
::
++  insert-import-event
  |=  $:  ids=event-ids:act
          vehicle-id=@ux
          station-id=(unit @ux)
          tag-ids=(list @ux)
          subtype-ids=(list @ux)
          payment-method-id=(unit @ux)
          event=import-event:rover
          recorded-at=@da
      ==
  ^-  tape
  ;:  weld
    %:  insert-event:act
        ids
        vehicle-id
        station-id
        tag-ids
        subtype-ids
        ~
        payment-method-id
        input.event
        recorded-at
    ==
    " INSERT INTO event-imports VALUES ("
    (scow %ux event.ids)
    ", "
    (sql-term:act source-app.event)
    ", '"
    (sql-quote:act source-record-id.event)
    "');"
  ==
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
      (simples %service-subtype service-subtypes.definitions.document)
    ==
  =/  place-work
    %+  turn  places.document
    |=  value=import-place:rover
    ^-  import-work:rover
    ?^  station-kind.value
      [%place u.station-kind.value value]
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
  ::  A specification, an event and a reminder each name a vehicle, so all
  ::  three follow the vehicles. An event also names a station, a tag, a
  ::  payment method and a subtype, and a reminder names a subtype, so all of
  ::  them follow the definitions and the places as well.
  =/  spec-work
    %+  murn  vehicles.document
    |=  value=import-vehicle:rover
    ^-  (unit import-work:rover)
    ?:  =(*vehicle-spec-entry:rover specification.value)
      ~
    `[%spec label.value specification.value]
  =/  event-work
    =/  build
      |=  values=(list import-vehicle:rover)
      ^-  (list import-work:rover)
      ?~  values
        ~
      %+  weld
        %+  turn  events.i.values
        |=  value=import-event:rover
        ^-  import-work:rover
        [%event value]
      $(values t.values)
    (build vehicles.document)
  =/  reminder-work
    =/  build
      |=  values=(list import-vehicle:rover)
      ^-  (list import-work:rover)
      ?~  values
        ~
      %+  weld
        %+  turn  reminders.i.values
        |=  value=reminder-entry:rover
        ^-  import-work:rover
        [%reminder value]
      $(values t.values)
    (build vehicles.document)
  ;:  weld
    energy-work
    simple-work
    place-work
    vehicle-work
    spec-work
    fill-work
    event-work
    reminder-work
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
    ::  M7 T9. The service-subtype catalog is a definition family of the same
    ::  shape, so it reaches the same create-if-absent path. Matching is by
    ::  LABEL, which is what makes the source's duplicate `Car Wash` land on
    ::  the one row the T2 starter pack already seeded.
    %service-subtype
      ['service-subtype-definitions' 'service-subtype-id']
  ==
::
++  energy-lookup
  |=  input=import-energy-definition:rover
  ^-  tape
  =/  subtype-labels
    %+  turn  subtypes.input
    |=  subtype=import-energy-subtype:rover
    label.subtype
  ;:  weld
    "FROM energy-definitions E WHERE E.label = '"
    (sql-quote:act label.input)
    "' SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived; "
    "FROM energy-definition-subtypes S JOIN energy-definitions E ON S.energy-definition-id = E.energy-definition-id WHERE E.label = '"
    (sql-quote:act label.input)
    "' AND ("
    (label-predicate 'S' subtype-labels)
    ") SELECT S.subtype-id, S.energy-definition-id, S.label, S.archived;"
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
::  Result sets 3 and 4 carry the links the vehicle already has. Import needs
::  them only when the vehicle exists, to tell a missing link from a link it
::  must revive. A vehicle import created in this batch has neither.
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
    " SELECT D.mode-id, D.label, D.archived; "
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = '"
    (sql-quote:act label.vehicle)
    "' SELECT E.energy-definition-id, E.label, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '"
    (sql-quote:act label.vehicle)
    "' SELECT D.mode-id, D.label, L.archived AS link-archived;"
  ==
::
++  work-lookup
  |=  work=import-work:rover
  ^-  tape
  ?-  -.work
    %energy
      (energy-lookup value.work)
    %simple
      (simple-lookup kind.work label.value.work)
    %place
      (place-lookup label.value.work)
    %vehicle
      (vehicle-lookup value.work)
    %fill
      (fill-existing-lookup value.work)
    %spec
      (spec-lookup vehicle-label.work)
    %event
      (event-existing-lookup value.work)
    %reminder
      (reminder-existing-lookup value.work)
  ==
::
++  insert-energy-subtypes
  |=  $:  base=@ux
          definition-id=@ux
          values=(list import-energy-subtype:rover)
          recorded-at=@da
      ==
  ^-  tape
  =/  build
    |=  [remaining=(list import-energy-subtype:rover) ordinal=@ud]
    ^-  tape
    ?~  remaining
      ~
    =/  subtype-id  (fixture-id:act base (add 10 ordinal))
    =/  value  i.remaining
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
      $(remaining t.remaining, ordinal +(ordinal))
    ==
  (build values 0)
::
++  insert-energy
  |=  [base=@ux input=import-energy-definition:rover recorded-at=@da]
  ^-  tape
  =/  definition-id  (fixture-id:act base 1)
  ;:  weld
    %:  insert-energy-source-type:act
        definition-id
        label.input
        physical-kind.input
        quantity-unit.input
        recorded-at
    ==
    (insert-energy-subtypes base definition-id subtypes.input recorded-at)
  ==
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
::  Widening an existing vehicle. Import adds a link the vehicle lacks and
::  clears archived on a link it uses again. It never sets archived, so it
::  cannot take an energy source or a driving mode away from the owner. Compare
::  +sync-energy-current and +sync-mode-current in lib/rover-act.hoon, which
::  reconcile the whole set for an owner edit and do flip the flag.
++  widen-energy-links
  |=  [vehicle-id=@ux desired=(list @ux) linked=(list @ux) archived=(list @ux)]
  ^-  tape
  ?~  desired
    ~
  =/  rest  $(desired t.desired)
  ?:  (has-id:act i.desired archived)
    ;:  weld
      "UPDATE vehicle-energy-definitions SET archived = N WHERE vehicle-id = "
      (scow %ux vehicle-id)
      " AND energy-definition-id = "
      (scow %ux i.desired)
      "; "
      rest
    ==
  ?:  (has-id:act i.desired linked)
    rest
  ;:  weld
    "INSERT INTO vehicle-energy-definitions VALUES ("
    (scow %ux vehicle-id)
    ", "
    (scow %ux i.desired)
    ", N); "
    rest
  ==
::
++  widen-mode-links
  |=  [vehicle-id=@ux desired=(list @ux) linked=(list @ux) archived=(list @ux)]
  ^-  tape
  ?~  desired
    ~
  =/  rest  $(desired t.desired)
  ?:  (has-id:act i.desired archived)
    ;:  weld
      "UPDATE vehicle-driving-modes SET archived = N WHERE vehicle-id = "
      (scow %ux vehicle-id)
      " AND mode-id = "
      (scow %ux i.desired)
      "; "
      rest
    ==
  ?:  (has-id:act i.desired linked)
    rest
  ;:  weld
    "INSERT INTO vehicle-driving-modes VALUES ("
    (scow %ux vehicle-id)
    ", "
    (scow %ux i.desired)
    ", N); "
    rest
  ==
::
::  The script is empty when the vehicle already carries every link the batch
::  needs, which is the common case. The caller then writes nothing.
++  widen-import-vehicle
  |=  $:  vehicle-id=@ux
          definition-ids=(list @ux)
          mode-ids=(list @ux)
          linked-definition-ids=(list @ux)
          archived-definition-ids=(list @ux)
          linked-mode-ids=(list @ux)
          archived-mode-ids=(list @ux)
      ==
  ^-  tape
  %+  weld
    %:  widen-energy-links
        vehicle-id
        (unique-ids:act definition-ids)
        linked-definition-ids
        archived-definition-ids
    ==
  %:  widen-mode-links
      vehicle-id
      (unique-ids:act mode-ids)
      linked-mode-ids
      archived-mode-ids
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
    "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id JOIN energy-acquisition-odometers L ON A.acquisition-id = L.acquisition-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE "
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
::  M7 T9. The stored event against the document, for the second run of the
::  same import. A record whose values changed reports a conflict and writes
::  nothing: Rover never issues UPSERT, and an edit the owner made in Rover
::  must survive a stale foreign export.
++  existing-event-main-differences
  |=  [event=import-event:rover commands=(list cmd-result:ast)]
  ^-  (list @t)
  =/  input  input.event
  =/  main  (rows-at:view commands 0)
  ?.  =(1 (lent main))
    ['provenance' ~]
  =/  row  (snag 0 main)
  =/  differences=(list @t)  ~
  =.  differences
    (add-diff !=(vehicle-label.input (cell-text:view %vehicle row)) 'vehicle' differences)
  =.  differences
    (add-diff !=(observed-start.input (cell-atom:view %observed-start row)) 'observed' differences)
  =.  differences
    (add-diff !=((add observed-start.input (bex 64)) (cell-atom:view %observed-end row)) 'observed' differences)
  =.  differences
    (add-diff !=(%second (cell-term:view %observed-precision row)) 'observed' differences)
  =.  differences
    (add-diff !=(source-zone.input (cell-text:view %source-zone row)) 'zone' differences)
  ::  The kind is which typed child exists, so it is checked by counting
  ::  child rows rather than by reading a column. No column holds it.
  =/  service  (lent (rows-at:view commands 1))
  =/  expense  (lent (rows-at:view commands 2))
  =/  note  (lent (rows-at:view commands 3))
  =/  expected
    ?+  kind.input  [0 0 0]
      %service  [1 0 0]
      %expense  [0 1 0]
      %note     [0 0 1]
    ==
  =.  differences
    (add-diff !=(expected [service expense note]) 'kind' differences)
  =/  totals  (rows-at:view commands 4)
  =/  total-diff
    ?~  total-mills.input
      ?=(^ totals)
    ?|  !=(1 (lent totals))
        !=(u.total-mills.input (cell-atom:view %total-mills (snag 0 totals)))
    ==
  =.  differences  (add-diff total-diff 'total' differences)
  (flop differences)
::
++  existing-event-child-differences
  |=  [event=import-event:rover commands=(list cmd-result:ast)]
  ^-  (list @t)
  =/  input  input.event
  =/  differences=(list @t)  ~
  =/  odometers  (rows-at:view commands 0)
  =/  odometer-diff=?
    ?~  mileage.input
      ?=(^ odometers)
    ?|  !=(1 (lent odometers))
        !=(digits.u.mileage.input (cell-atom:view %value-digits (snag 0 odometers)))
        !=(places.u.mileage.input (cell-atom:view %decimal-places (snag 0 odometers)))
        !=(odo-unit.u.mileage.input (cell-term:view %unit (snag 0 odometers)))
    ==
  =.  differences  (add-diff odometer-diff 'odometer' differences)
  =.  differences
    (add-diff (optional-text-diff station-label.input %station (rows-at:view commands 1)) 'station' differences)
  =.  differences
    (add-diff =(%.n (same-texts tag-labels.input %tag (rows-at:view commands 2))) 'tags' differences)
  =.  differences
    (add-diff =(%.n (same-texts subtype-labels.input %subtype (rows-at:view commands 3))) 'subtypes' differences)
  =.  differences
    (add-diff (optional-text-diff payment-method-label.input %payment-method (rows-at:view commands 4)) 'payment-method' differences)
  =.  differences
    (add-diff (optional-text-diff notes.input %note (rows-at:view commands 5)) 'notes' differences)
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
