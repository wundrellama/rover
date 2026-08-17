::  lib/rover-act - Obelisk driver helpers for %rover.
::
/-  ast=obelisk-ast, rover
|%
+$  entry-ids
  $:  acquisition=@ux
      odometer=@ux
      place=@ux
      station=@ux
      tag=@ux
  ==
+$  event-ids
  $:  event=@ux
      odometer=@ux
      place=@ux
      station=@ux
      tag=@ux
  ==
+$  charge-ids
  $:  acquisition=@ux
      measurement=@ux
      start-battery=@ux
      end-battery=@ux
      odometer=@ux
      components=(list @ux)
  ==
::
++  rover-db  %rover
::
++  database-list
  ^-  tape
  "FROM sys.sys.databases SELECT database;"
::
++  fixture-id
  |=  [seed=@ux ordinal=@ud]
  ^-  @ux
  =/  candidate=@ux  (mix seed ordinal)
  ?:  =(0 candidate)
    `@ux`(add ordinal 1)
  candidate
::
++  charging-component-ids
  |=  [seed=@ux count=@ud base-ordinal=@ud]
  ^-  (list @ux)
  =/  index=@ud  0
  |-  ^-  (list @ux)
  ?:  =(index count)
    ~
  [(fixture-id seed (add base-ordinal index)) $(index +(index))]
::
++  starter-definition
  |=  [base=@ux ordinal=@ud label=tape kind=@tas unit=@tas now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO energy-definitions VALUES ("
    (scow %ux (fixture-id base ordinal))
    ", '"
    label
    "', "
    (sql-term kind)
    ", "
    (sql-term unit)
    ", N, "
    (scow %da now)
    "); "
  ==
::
++  starter-subtype
  |=  [base=@ux ordinal=@ud definition-ordinal=@ud label=tape now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO energy-definition-subtypes VALUES ("
    (scow %ux (fixture-id base ordinal))
    ", "
    (scow %ux (fixture-id base definition-ordinal))
    ", '"
    label
    "', N, "
    (scow %da now)
    "); "
  ==
::
++  starter-octane
  |=  [base=@ux ordinal=@ud rating=@ud method=@tas]
  ^-  tape
  ;:  weld
    "INSERT INTO energy-subtype-octane VALUES ("
    (scow %ux (fixture-id base ordinal))
    ", "
    (sql-ud rating)
    ", "
    (sql-term method)
    "); "
  ==
::
::  Ignition-mode lookup (import Q2, ratified 2026-07-30). Rover-side only:
::  nothing about ignition mode is stored in Obelisk. This maps a SHIPPED
::  STARTER definition label to the rating scale its subtypes may carry, and
::  reconciliation uses it to catch a rating child on the wrong scale.
::
::  The principle is ignition mode, because that is what the physics keys on:
::    spark ignition       -> the fuel must RESIST self-ignition -> octane
::    compression ignition -> the fuel must READILY self-ignite  -> cetane
::
::  Returns a UNIT, and the ~ cases are deliberate, not laziness:
::    * Electricity, Hydrogen - no anti-knock rating exists at all.
::    * CNG, LNG - rated on METHANE NUMBER, a third scale Rover does not model.
::      Returning %octane for them would assert a rating type they do not use.
::    * Any owner-invented definition ("Tractor juice") - Rover has no basis to
::      classify it. The owner knows their fuel; Rover does not guess.
::
::  Consequence: the reconciliation check below only fires when the scale is
::  KNOWN. For an unknown definition Rover permits either rating child, because
::  refusing would mean overriding the owner on a fact only they hold. This is
::  not a permission decision - it is a factual classification, so the
::  fail-closed rule for authorization does not apply here.
++  rating-scale-for
  |=  label=@t
  ^-  (unit rating-scale:rover)
  ?+  label  ~
    %'Gasoline'     [~ %octane]
    %'Ethanol'      [~ %octane]
    %'Propane'      [~ %octane]
    %'Diesel'       [~ %cetane]
  ==
::
::  Does this rating child belong on a subtype of this definition? Used by
::  reconciliation, never to silently rewrite a row.
++  rating-scale-ok
  |=  [label=@t scale=rating-scale:rover]
  ^-  ?
  =/  expected  (rating-scale-for label)
  ?~  expected  &
  =(scale u.expected)
::
++  starter-cetane
  |=  [base=@ux ordinal=@ud rating=@ud]
  ^-  tape
  ;:  weld
    "INSERT INTO energy-subtype-cetane VALUES ("
    (scow %ux (fixture-id base ordinal))
    ", "
    (sql-ud rating)
    "); "
  ==
::
++  starter-blend
  |=  [base=@ux ordinal=@ud kind=@tas percent=@ud]
  ^-  tape
  ;:  weld
    "INSERT INTO energy-subtype-blend VALUES ("
    (scow %ux (fixture-id base ordinal))
    ", "
    (sql-term kind)
    ", "
    (sql-ud percent)
    ", 0); "
  ==
::
++  seed-starters
  |=  [base=@ux now=@da]
  ^-  tape
  (seed-missing-starters base now %.y %.y %.y %.y %.y %.y)
::
++  seed-missing-starters
  |=  $:  base=@ux
          now=@da
          energy-empty=?
          consumables-empty=?
          additives-empty=?
          driving-modes-empty=?
          service-subtypes-empty=?
          disposal-kinds-empty=?
      ==
  ^-  tape
  ;:  weld
    ?:  energy-empty
      (seed-energy-starters base now)
    ~
    ?:  consumables-empty
      (seed-consumables base now)
    ~
    ?:  additives-empty
      (seed-additives base now)
    ~
    ?:  driving-modes-empty
      (seed-driving-modes base now)
    ~
    ?:  service-subtypes-empty
      (seed-service-subtypes base now)
    ~
    ?:  disposal-kinds-empty
      (seed-disposal-kinds base now)
    ~
  ==
::
++  seed-energy-starters
  |=  [base=@ux now=@da]
  ^-  tape
  ;:  weld
    (starter-definition base 1 "Gasoline" %reservoir %gal now)
    (starter-definition base 2 "Diesel" %reservoir %gal now)
    (starter-definition base 3 "Electricity" %electricity %kwh now)
    (starter-definition base 4 "Propane" %reservoir %gal now)
    (starter-definition base 5 "Hydrogen" %reservoir %kg now)
    (starter-definition base 6 "CNG" %reservoir %kg now)
    (starter-definition base 7 "LNG" %reservoir %kg now)
    (starter-definition base 8 "Ethanol" %reservoir %gal now)
    (starter-subtype base 101 1 "85" now)
    (starter-subtype base 102 1 "87" now)
    (starter-subtype base 103 1 "88" now)
    (starter-subtype base 104 1 "89" now)
    (starter-subtype base 105 1 "90" now)
    (starter-subtype base 106 1 "91" now)
    (starter-subtype base 107 1 "92" now)
    (starter-subtype base 108 1 "93" now)
    (starter-subtype base 109 1 "95" now)
    (starter-subtype base 110 1 "98" now)
    (starter-subtype base 111 1 "100" now)
    (starter-octane base 101 85 %aki)
    (starter-octane base 102 87 %aki)
    (starter-octane base 103 88 %aki)
    (starter-octane base 104 89 %aki)
    (starter-octane base 105 90 %aki)
    (starter-octane base 106 91 %aki)
    (starter-octane base 107 92 %aki)
    (starter-octane base 108 93 %aki)
    (starter-octane base 109 95 %ron)
    (starter-octane base 110 98 %ron)
    (starter-octane base 111 100 %ron)
    (starter-blend base 103 %ethanol 15)
    (starter-blend base 109 %ethanol 10)
    (starter-blend base 110 %ethanol 5)
    (starter-blend base 111 %ethanol 5)
    ::  Gasoline subtype labels ARE their octane number ("87" rated 87 AKI), so
    ::  the octane rows above restate the label - not a new assertion.
    ::
    ::  Diesel is deliberately DIFFERENT. Its subtype labels are grades (#2,
    ::  Winter, B20, HVO100) and the grade is NOT the rating. US pumps do post
    ::  cetane sometimes, just infrequently - so a cetane figure is a real fact
    ::  an owner may hold, it simply cannot be inferred from the grade. No
    ::  starter cetane rows are seeded: inventing "#2 = cetane 40" would make
    ::  Rover synthesise evidence no source supplied, and absence of the child
    ::  row already means "no rating recorded" (the no-sentinel rule).
    ::  +starter-cetane exists for the paths that DO have a source: owner entry
    ::  from a pump that posted it, and import (aCar's ULSD carries cetane 45).
    (starter-subtype base 201 2 "#2" now)
    (starter-subtype base 202 2 "#1" now)
    (starter-subtype base 203 2 "Winter" now)
    (starter-subtype base 204 2 "Off-road (dyed)" now)
    (starter-subtype base 205 2 "B20" now)
    (starter-subtype base 206 2 "R99" now)
    (starter-subtype base 207 2 "B7" now)
    (starter-subtype base 208 2 "Premium" now)
    (starter-subtype base 209 2 "Arctic" now)
    (starter-subtype base 210 2 "HVO100" now)
    (starter-blend base 205 %biodiesel 20)
    (starter-blend base 206 %biodiesel 99)
    (starter-blend base 207 %biodiesel 7)
    (starter-subtype base 301 3 "DC Fast" now)
    (starter-subtype base 302 3 "AC Level 2" now)
    (starter-subtype base 303 3 "AC Level 1" now)
    (starter-subtype base 401 4 "HD-5" now)
    (starter-subtype base 402 4 "Autogas" now)
    (starter-subtype base 501 5 "H70" now)
    (starter-subtype base 502 5 "H35" now)
    (starter-subtype base 601 6 "CNG" now)
    (starter-subtype base 701 7 "LNG" now)
    (starter-subtype base 801 8 "E85" now)
    (starter-subtype base 802 8 "E100 hydrous" now)
    (starter-blend base 801 %ethanol 85)
    (starter-blend base 802 %ethanol 100)
  ==
::
++  seed-consumables
  |=  [base=@ux now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO consumable-definitions VALUES ("
    (scow %ux (fixture-id base 9.001))
    ", 'DEF', %gal, N, "
    (scow %da now)
    "); INSERT INTO consumable-definitions VALUES ("
    (scow %ux (fixture-id base 9.002))
    ", 'Washer Fluid', %gal, N, "
    (scow %da now)
    "); INSERT INTO consumable-definitions VALUES ("
    (scow %ux (fixture-id base 9.003))
    ", 'Motor Oil', %quart, N, "
    (scow %da now)
    "); INSERT INTO consumable-definitions VALUES ("
    (scow %ux (fixture-id base 9.004))
    ", 'Coolant', %gal, N, "
    (scow %da now)
    ");"
  ==
::
++  seed-additives
  |=  [base=@ux now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO additive-definitions VALUES ("
    (scow %ux (fixture-id base 9.101))
    ", 'Injector cleaner', N, "
    (scow %da now)
    "); INSERT INTO additive-definitions VALUES ("
    (scow %ux (fixture-id base 9.102))
    ", 'Fuel stabilizer', N, "
    (scow %da now)
    ");"
  ==
::
++  seed-driving-modes
  |=  [base=@ux now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO driving-mode-definitions VALUES ("
    (scow %ux (fixture-id base 9.201))
    ", 'Normal', N, "
    (scow %da now)
    "); INSERT INTO driving-mode-definitions VALUES ("
    (scow %ux (fixture-id base 9.202))
    ", 'Economy', N, "
    (scow %da now)
    "); INSERT INTO driving-mode-definitions VALUES ("
    (scow %ux (fixture-id base 9.203))
    ", 'Sport', N, "
    (scow %da now)
    "); INSERT INTO driving-mode-definitions VALUES ("
    (scow %ux (fixture-id base 9.204))
    ", 'Towing', N, "
    (scow %da now)
    "); INSERT INTO driving-mode-definitions VALUES ("
    (scow %ux (fixture-id base 9.205))
    ", 'Winter', N, "
    (scow %da now)
    ");"
  ==
::
::  M7 T2. The service subtype starter pack.
::
::  ONE catalog, not two. The owner's aCar export splits its 65 definitions
::  into a service list and an expense list, and three labels - Car Wash,
::  Insurance, and Registration - appear in both. Rover keys the subtype link
::  to `vehicle-events`, so one definition already serves a service event and
::  an expense event alike. Seeding each of the three twice would put two
::  identical entries in one selector, and the owner could not archive either
::  one until T8. Each label is therefore seeded ONCE.
::
::  No category column. A category would be a display grouping that the schema
::  cannot enforce, because the link keys to the event parent and Rover records
::  what happened rather than what should.
++  service-subtype-starters
  ^-  (list tape)
  :~  ::  Fluids and filters
      "Engine Oil"
      "Oil Filter"
      "Air Filter"
      "Cabin Air Filter"
      "Fuel Filter"
      "Transmission Fluid"
      "Transmission Filter"
      "Differential Fluid"
      "Transfer Case Fluid"
      "Brake Fluid"
      "Power Steering Fluid"
      "Coolant System"
      "Engine Antifreeze"
      "Windshield Washer Fluid"
      "Diesel Exhaust Fluid"
      ::  Brakes, tires, and suspension
      "Brakes, Front"
      "Brakes, Rear"
      "Brake Rotors"
      "Tire Rotation"
      "New Tires"
      "Tire Repair"
      "Wheel Alignment"
      "Wheel Balancing"
      "Shocks and Struts"
      "Suspension"
      ::  Engine and drivetrain
      "Spark Plugs"
      "Ignition Coils"
      "Glow Plugs"
      "Timing Belt"
      "Timing Chain"
      "Belts"
      "Hoses"
      "Water Pump"
      "Thermostat"
      "Fuel Pump"
      "Fuel Injectors"
      "Throttle Body Cleaning"
      "Valve Adjustment"
      "Engine Tune-Up"
      "Turbocharger"
      "Clutch"
      ::  Exhaust and emissions
      "Exhaust System"
      "Muffler"
      "Catalytic Converter"
      "Diesel Particulate Filter"
      "Oxygen Sensor"
      "EGR Valve"
      ::  Electrical
      "Battery"
      "Alternator"
      "Starter Motor"
      "Headlights"
      ::  Body, glass, and comfort
      "Windshield Wipers"
      "Windshield"
      "Air Conditioning Service"
      "Body Work"
      "Detailing"
      ::  Compliance, and the labels aCar splits between service and expense
      "Inspection"
      "Emissions Test"
      "Registration"
      "Insurance"
      "Car Wash"
      "Roadside Assistance"
      "Towing"
      "Parking"
      "Tolls"
      "Diagnostics"
  ==
::
++  seed-service-subtypes
  |=  [base=@ux now=@da]
  ^-  tape
  =/  labels=(list tape)  service-subtype-starters
  =/  ordinal=@ud  9.401
  |-  ^-  tape
  ?~  labels
    ~
  %+  weld
    ;:  weld
      "INSERT INTO service-subtype-definitions VALUES ("
      (scow %ux (fixture-id base ordinal))
      ", '"
      i.labels
      "', N, "
      (scow %da now)
      "); "
    ==
  $(labels t.labels, ordinal +(ordinal))
::
++  disposal-kind-starters
  ^-  (list tape)
  :~  "Sold"
      "Traded in"
      "Totaled"
      "Scrapped"
      "Gifted"
      "Stolen"
  ==
::
++  seed-disposal-kinds
  |=  [base=@ux now=@da]
  ^-  tape
  =/  labels=(list tape)  disposal-kind-starters
  =/  ordinal=@ud  9.501
  |-  ^-  tape
  ?~  labels
    ~
  %+  weld
    ;:  weld
      "INSERT INTO disposal-kind-definitions VALUES ("
      (scow %ux (fixture-id base ordinal))
      ", '"
      i.labels
      "', N, "
      (scow %da now)
      "); "
    ==
  $(labels t.labels, ordinal +(ordinal))
::
++  starter-check
  ^-  tape
  ;:  weld
    "FROM energy-definitions E SELECT E.energy-definition-id, E.label, E.archived; "
    "FROM consumable-definitions C SELECT C.consumable-id, C.label, C.archived; "
    "FROM additive-definitions A SELECT A.additive-id, A.label, A.archived; "
    "FROM driving-mode-definitions D SELECT D.mode-id, D.label, D.archived; "
    "FROM service-subtype-definitions S SELECT S.service-subtype-id, S.label, S.archived; "
    "FROM disposal-kind-definitions D SELECT D.disposal-kind-id, D.label, D.archived;"
  ==
::
++  consumable-lookup
  |=  [vehicle-label=@t consumable-label=@t]
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT V.vehicle-id; FROM consumable-definitions C WHERE C.label = '"
    (sql-quote consumable-label)
    "' SELECT C.consumable-id, C.quantity-unit, C.archived;"
  ==
::
++  insert-consumable
  |=  $:  acquisition-id=@ux
          odometer-id=@ux
          vehicle-id=@ux
          consumable-id=@ux
          quantity-unit=@tas
          input=consumable-entry:rover
          recorded-at=@da
      ==
  ^-  tape
  =/  acquisition  (scow %ux acquisition-id)
  =/  odometer-script=tape
    ?~  mileage.input
      ~
    =/  odometer  (scow %ux odometer-id)
    ;:  weld
      " INSERT INTO odometer-observations VALUES ("
      odometer
      ", "
      (scow %ux vehicle-id)
      ", "
      (sql-ud digits.u.mileage.input)
      ", "
      (sql-ud places.u.mileage.input)
      ", "
      (sql-term odo-unit.u.mileage.input)
      ", "
      (scow %da observed-start.input)
      ", "
      (scow %da (add observed-start.input (bex 64)))
      ", %second, '"
      (sql-quote source-zone.input)
      "', "
      (scow %da recorded-at)
      "); INSERT INTO consumable-acquisition-odometers VALUES ("
      acquisition
      ", "
      odometer
      "); "
    ==
  ;:  weld
    "INSERT INTO consumable-acquisitions VALUES ("
    acquisition
    ", "
    (scow %ux vehicle-id)
    ", "
    (scow %ux consumable-id)
    ", "
    (scow %da observed-start.input)
    ", "
    (scow %da (add observed-start.input (bex 64)))
    ", %second, '"
    (sql-quote source-zone.input)
    "', "
    (scow %da recorded-at)
    "); INSERT INTO consumable-purchases VALUES ("
    acquisition
    ", "
    (sql-ud quantity-milli.input)
    ", "
    (sql-term quantity-unit)
    ", "
    (sql-ud unit-price-mills.input)
    ", "
    (sql-term currency.input)
    ", "
    (sql-term settlement-mode.input)
    ", "
    (sql-term price-profile.input)
    ", "
    (sql-ud minor-unit-decimals.input)
    ", "
    (sql-ud cash-increment-mills.input)
    ");"
    odometer-script
  ==
::
::  Everything a vehicle event may reference, by human label. The station, tag,
::  and payment-method definitions already hold the owner's real data, so a
::  service visit selects the same rows a fuel fill selects. Only the link rows
::  are new.
++  event-lookup
  |=  vehicle-label=@t
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT V.vehicle-id;"
    " FROM stations S JOIN places P ON S.place-id = P.place-id SELECT S.station-id, S.label, S.archived, P.label AS place;"
    " FROM tag-definitions T SELECT T.tag-id, T.label, T.archived;"
    " FROM payment-method-definitions P SELECT P.method-id, P.label, P.archived;"
    " FROM service-subtype-definitions S SELECT S.service-subtype-id, S.label, S.archived;"
    " FROM disposal-kind-definitions D SELECT D.disposal-kind-id, D.label, D.archived;"
  ==
::
::  One atomic script for one vehicle event, shaped after +insert-consumable.
::  Every optional member writes a row only when the owner supplied it: an
::  absent station, odometer, cost, tag, payment method, or note is an absent
::  row, never a bunt, a zero, or an empty string.
++  insert-event
  |=  $:  ids=event-ids
          vehicle-id=@ux
          station-id=(unit @ux)
          tag-ids=(list @ux)
          subtype-ids=(list @ux)
          payment-method-id=(unit @ux)
          disposal-kind-id=(unit @ux)
          input=event-entry:rover
          recorded-at=@da
      ==
  ^-  tape
  =/  event  (scow %ux event.ids)
  =/  vehicle  (scow %ux vehicle-id)
  =/  observed-start  (scow %da observed-start.input)
  =/  observed-end  (scow %da (add observed-start.input (bex 64)))
  =/  recorded  (scow %da recorded-at)
  =/  zone  (sql-quote source-zone.input)
  =/  new-station-rows=tape
    ?~  new-station.input
      ~
    ;:  weld
      "INSERT INTO places VALUES ("
      (scow %ux place.ids)
      ", '"
      (sql-quote place-label.u.new-station.input)
      "', N, "
      recorded
      "); INSERT INTO stations VALUES ("
      (scow %ux station.ids)
      ", "
      (scow %ux place.ids)
      ", '"
      (sql-quote station-label.u.new-station.input)
      "', "
      (sql-term station-kind.u.new-station.input)
      ", N, "
      recorded
      "); "
    ==
  =/  event-row=tape
    ;:  weld
      "INSERT INTO vehicle-events VALUES ("
      event
      ", "
      vehicle
      ", "
      observed-start
      ", "
      observed-end
      ", %second, '"
      zone
      "', "
      recorded
      ");"
    ==
  ::  The kind is this row and nothing else. No column repeats it.
  =/  child-row=tape
    ?-  kind.input
      %service
        (weld " INSERT INTO service-events VALUES (" (weld event ");"))
      %expense
        (weld " INSERT INTO expense-events VALUES (" (weld event ");"))
      %note
        (weld " INSERT INTO note-events VALUES (" (weld event ");"))
      %acquisition
        (weld " INSERT INTO vehicle-acquisitions VALUES (" (weld event ");"))
      %disposal
        ;:  weld
          " INSERT INTO vehicle-disposals VALUES ("
          event
          ", "
          (scow %ux (need disposal-kind-id))
          ");"
        ==
    ==
  =/  cost-rows=tape
    ?~  total-mills.input
      ~
    ;:  weld
      " INSERT INTO vehicle-event-costs VALUES ("
      event
      ", %receipt-total-only, "
      (sql-term currency.input)
      ", "
      (sql-ud minor-unit-decimals.input)
      ", "
      recorded
      "); INSERT INTO vehicle-event-cost-totals VALUES ("
      event
      ", "
      (sql-ud u.total-mills.input)
      ");"
    ==
  ::  The reading itself is never copied onto the event. One
  ::  odometer-observations list per vehicle holds every reading, and the event
  ::  links to that list.
  =/  mileage-rows=tape
    ?~  mileage.input
      ~
    =/  odometer  (scow %ux odometer.ids)
    ;:  weld
      " INSERT INTO odometer-observations VALUES ("
      odometer
      ", "
      vehicle
      ", "
      (sql-ud digits.u.mileage.input)
      ", "
      (sql-ud places.u.mileage.input)
      ", "
      (sql-term odo-unit.u.mileage.input)
      ", "
      observed-start
      ", "
      observed-end
      ", %second, '"
      zone
      "', "
      recorded
      "); INSERT INTO vehicle-event-odometers VALUES ("
      event
      ", "
      odometer
      ");"
    ==
  =/  effective-station=(unit @ux)
    ?^  station-id
      station-id
    ?^  new-station.input
      `station.ids
    ~
  =/  station-row=tape
    ?~  effective-station
      ~
    ;:  weld
      " INSERT INTO vehicle-event-stations VALUES ("
      event
      ", "
      (scow %ux u.effective-station)
      ");"
    ==
  =/  new-tag-rows=tape
    ?~  new-tag-label.input
      ~
    ;:  weld
      " INSERT INTO tag-definitions VALUES ("
      (scow %ux tag.ids)
      ", '"
      (sql-quote u.new-tag-label.input)
      "', N, "
      recorded
      "); INSERT INTO vehicle-event-tags VALUES ("
      event
      ", "
      (scow %ux tag.ids)
      ");"
    ==
  =/  payment-row=tape
    ?~  payment-method-id
      ~
    ;:  weld
      " INSERT INTO vehicle-event-payment-method VALUES ("
      event
      ", "
      (scow %ux u.payment-method-id)
      ");"
    ==
  =/  notes-row=tape
    ?~  notes.input
      ~
    ;:  weld
      " INSERT INTO vehicle-event-notes VALUES ("
      event
      ", '"
      (sql-quote u.notes.input)
      "');"
    ==
  ;:  weld
    new-station-rows
    event-row
    child-row
    cost-rows
    mileage-rows
    station-row
    new-tag-rows
    (insert-event-tags event.ids tag-ids)
    (insert-event-subtypes event.ids subtype-ids)
    payment-row
    notes-row
  ==
::
++  insert-event-tags
  |=  [event-id=@ux tag-ids=(list @ux)]
  ^-  tape
  ?~  tag-ids
    ~
  =/  row
    ;:  weld
      " INSERT INTO vehicle-event-tags VALUES ("
      (scow %ux event-id)
      ", "
      (scow %ux i.tag-ids)
      ");"
    ==
  (weld row $(tag-ids t.tag-ids))
::
::  One row per selected subtype, in the same atomic script as the event. An
::  empty list writes nothing at all - no sentinel, and no `None` definition.
++  insert-event-subtypes
  |=  [event-id=@ux subtype-ids=(list @ux)]
  ^-  tape
  ?~  subtype-ids
    ~
  =/  row
    ;:  weld
      " INSERT INTO vehicle-event-service-subtypes VALUES ("
      (scow %ux event-id)
      ", "
      (scow %ux i.subtype-ids)
      ");"
    ==
  (weld row $(subtype-ids t.subtype-ids))
::
++  pow-ten
  |=  exponent=@ud
  ^-  @ud
  ?:  =(0 exponent)
    1
  (mul 10 $(exponent (dec exponent)))
::
++  round-div-half-up
  |=  [numerator=@ud denominator=@ud]
  ^-  @ud
  ?>  (gth denominator 0)
  (div (add numerator (div denominator 2)) denominator)
::
++  derive-fill-total
  |=  input=fill-total-input:rover
  ^-  total-proof:rover
  =/  minor-scale  (pow-ten minor-unit-decimals.input)
  ?>  (lte minor-scale 1.000)
  =/  product  (mul quantity-milli.input unit-price-mills.input)
  =/  minor-units
    (round-div-half-up (mul product minor-scale) 1.000.000)
  =/  standard-total-mills
    (mul minor-units (div 1.000 minor-scale))
  =/  total-mills
    ?:  ?&  =(%cash settlement-mode.input)
            (gth cash-increment-mills.input 0)
        ==
      %+  mul  cash-increment-mills.input
      (round-div-half-up standard-total-mills cash-increment-mills.input)
    standard-total-mills
  :*  quantity-milli.input
      unit-price-mills.input
      minor-unit-decimals.input
      cash-increment-mills.input
      settlement-mode.input
      product
      standard-total-mills
      total-mills
  ==
::
++  derive-charging-total
  |=  components=(list charging-component-amount:rover)
  ^-  charging-total-proof:rover
  =/  positive=@ud  0
  =/  discounts=@ud  0
  |-
  ?~  components
    ?>  (gte positive discounts)
    [positive discounts (sub positive discounts)]
  =/  item  i.components
  ?:  =(%discount component.item)
    $(components t.components, discounts (add discounts amount-mills.item))
  $(components t.components, positive (add positive amount-mills.item))
::
++  validate-acquisition-subtypes
  |=  [fuel=? charge=?]
  ^-  result:rover
  ?:  =(fuel charge)
    [%err 'exactly one acquisition subtype is required']
  [%ok 'exactly one acquisition subtype selected']
::
++  schema-m0
  ^-  tape
  ;:  weld
    "CREATE DATABASE rover; "
    "CREATE TABLE rover..vehicles (vehicle-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (vehicle-id); "
    "CREATE TABLE rover..vehicle-display-preferences (vehicle-id @ux, distance-unit @tas, currency @tas, recorded-at @da) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..odometer-observations (odometer-id @ux, vehicle-id @ux, value-digits @ud, decimal-places @ud, unit @tas, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (odometer-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-definitions (energy-definition-id @ux, label @t, physical-kind @tas, quantity-unit @tas, archived @f, recorded-at @da) PRIMARY KEY (energy-definition-id); "
    "CREATE TABLE rover..vehicle-energy-definitions (vehicle-id @ux, energy-definition-id @ux, archived @f) PRIMARY KEY (vehicle-id, energy-definition-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-default-energy-definitions (vehicle-id @ux, energy-definition-id @ux) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id, energy-definition-id) REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-acquisitions (acquisition-id @ux, vehicle-id @ux, energy-definition-id @ux, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (acquisition-id) FOREIGN KEY (vehicle-id, energy-definition-id) REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..fuel-fills (acquisition-id @ux, quantity-milli @ud, quantity-unit @tas, tank-state @tas, unit-price-mills @ud, currency @tas, settlement-mode @tas, price-profile @tas, minor-unit-decimals @ud, cash-increment-mills @ud) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-sessions (acquisition-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..places (place-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (place-id); "
    "CREATE TABLE rover..stations (station-id @ux, place-id @ux, label @t, station-kind @tas, archived @f, recorded-at @da) PRIMARY KEY (station-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-acquisition-stations (acquisition-id @ux, station-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-definition-subtypes (subtype-id @ux, energy-definition-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (subtype-id) FOREIGN KEY (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-subtype-octane (subtype-id @ux, rating @ud, method @tas) PRIMARY KEY (subtype-id) FOREIGN KEY (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    ::  Cetane sibling (import Q1, ratified 2026-07-30). Compression-ignition
    ::  fuels rate on cetane, spark-ignition fuels on octane; the two are
    ::  mutually exclusive by physics. No method column - civilian diesel has no
    ::  competing scale. Rover invariant: at most one rating child per subtype.
    "CREATE TABLE rover..energy-subtype-cetane (subtype-id @ux, rating @ud) PRIMARY KEY (subtype-id) FOREIGN KEY (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-subtype-blend (subtype-id @ux, blend-kind @tas, percent-digits @ud, percent-decimals @ud) PRIMARY KEY (subtype-id, blend-kind) FOREIGN KEY (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-subtype-grade-code (subtype-id @ux, code @t) PRIMARY KEY (subtype-id) FOREIGN KEY (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-default-energy-subtype (vehicle-id @ux, subtype-id @ux, recorded-at @da) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..additive-definitions (additive-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (additive-id); "
    "CREATE TABLE rover..fuel-fill-additives (acquisition-id @ux, additive-id @ux) PRIMARY KEY (acquisition-id, additive-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (additive-id) REFERENCES additive-definitions (additive-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..economy-breaks (acquisition-id @ux, reason @tas, recorded-at @da) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-energy-measurements (measurement-id @ux, acquisition-id @ux, quantity @ud, decimals @ud, measure-unit @tas, point @tas, evidence @tas, recorded-at @da) PRIMARY KEY (measurement-id) FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..battery-observations (battery-observation-id @ux, vehicle-id @ux, measure @tas, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (battery-observation-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..battery-observation-percent (battery-observation-id @ux, value-digits @ud, value-decimals @ud) PRIMARY KEY (battery-observation-id) FOREIGN KEY (battery-observation-id) REFERENCES battery-observations (battery-observation-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..battery-observation-segments (battery-observation-id @ux, filled @ud, total @ud) PRIMARY KEY (battery-observation-id) FOREIGN KEY (battery-observation-id) REFERENCES battery-observations (battery-observation-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-session-batteries (acquisition-id @ux, endpoint @tas, battery-observation-id @ux) PRIMARY KEY (acquisition-id, endpoint) FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (battery-observation-id) REFERENCES battery-observations (battery-observation-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-efficiency-breaks (acquisition-id @ux, reason @tas, recorded-at @da) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-costs (acquisition-id @ux, cost-state @tas, currency @tas, recorded-at @da) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-cost-components (component-id @ux, acquisition-id @ux, component @tas, quantity @ud, quantity-decimals @ud, quantity-unit @tas, rate-mills @ud, amount-mills @ud) PRIMARY KEY (component-id) FOREIGN KEY (acquisition-id) REFERENCES charging-costs (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-cost-source-totals (acquisition-id @ux, total-mills @ud) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES charging-costs (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumption-observations (consumption-id @ux, vehicle-id @ux, value-digits @ud, value-decimals @ud, consumption-unit @tas, scope @tas, source @tas, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (consumption-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-addresses (place-id @ux, source @tas, recorded-at @da) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    ::  Q9 (2026-07-30): formatted lives in its own child, so a source that
    ::  supplies structured parts WITHOUT a text line is recordable. 105 of 420
    ::  real aCar fills are exactly that case. Invariant: at least one child
    ::  (formatted, parts, or both) - NOT XOR; 275 records have both.
    "CREATE TABLE rover..place-address-formatted (place-id @ux, formatted @t) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES place-addresses (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-address-parts (place-id @ux, part @tas, value @t) PRIMARY KEY (place-id, part) FOREIGN KEY (place-id) REFERENCES place-addresses (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-coordinates (place-id @ux, latitude-scaled @sd, longitude-scaled @sd, coord-scale @ud, source @tas, recorded-at @da) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-coordinate-accuracy (place-id @ux, radius-digits @ud, radius-decimals @ud, radius-unit @tas) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES place-coordinates (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..station-brand-operator (station-id @ux, role @tas, label @t) PRIMARY KEY (station-id, role) FOREIGN KEY (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..station-identifiers (station-id @ux, provider @tas, external-id @t) PRIMARY KEY (station-id, provider) FOREIGN KEY (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..acquisition-station-equipment (acquisition-id @ux, equipment-label @t, receipt-text @t) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisition-stations (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..app-default-vehicle (scope @tas, vehicle-id @ux, recorded-at @da) PRIMARY KEY (scope) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-tank-size (vehicle-id @ux, digits @ud, decimals @ud, size-unit @tas) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-refill-reserve (vehicle-id @ux, reserve-percent @ud) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..fuel-fill-subtype (acquisition-id @ux, subtype-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..driving-mode-definitions (mode-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (mode-id); "
    "CREATE TABLE rover..vehicle-driving-modes (vehicle-id @ux, mode-id @ux, archived @f) PRIMARY KEY (vehicle-id, mode-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (mode-id) REFERENCES driving-mode-definitions (mode-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..fuel-fill-driving-mode (acquisition-id @ux, mode-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (mode-id) REFERENCES driving-mode-definitions (mode-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..fuel-fill-average-speed (acquisition-id @ux, digits @ud, decimals @ud, speed-unit @tas) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..fuel-fill-drive-balance (acquisition-id @ux, highway-percent @ud) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..tag-definitions (tag-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (tag-id); "
    "CREATE TABLE rover..fuel-fill-tags (acquisition-id @ux, tag-id @ux) PRIMARY KEY (acquisition-id, tag-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (tag-id) REFERENCES tag-definitions (tag-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..custom-field-definitions (field-id @ux, label @t, content-type @tas, entry-type @tas, mandatory @f, target @tas, archived @f, recorded-at @da) PRIMARY KEY (field-id); "
    "CREATE TABLE rover..custom-field-options (field-id @ux, ordinal @ud, label @t) PRIMARY KEY (field-id, ordinal) FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..custom-field-values-number (field-id @ux, parent-id @ux, digits @ud, decimals @ud, value-unit @tas) PRIMARY KEY (field-id, parent-id) FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..custom-field-values-text (field-id @ux, parent-id @ux, value @t) PRIMARY KEY (field-id, parent-id) FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..custom-field-values-boolean (field-id @ux, parent-id @ux, value @f) PRIMARY KEY (field-id, parent-id) FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..payment-method-definitions (method-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (method-id); "
    "CREATE TABLE rover..fuel-fill-payment-method (acquisition-id @ux, method-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (method-id) REFERENCES payment-method-definitions (method-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..fill-notes (acquisition-id @ux, note @t) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    ::  Re-import detection (import Q5, ratified 2026-07-30). Namespaced foreign
    ::  record id, same rule as station-identifiers: NEVER crosses a human or
    ::  agent boundary. Absence = owner-entered. A known source record whose
    ::  values changed reports a conflict and imports nothing - never UPSERT.
    "CREATE TABLE rover..acquisition-imports (acquisition-id @ux, source-app @tas, source-record-id @t) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-session-subtype (acquisition-id @ux, subtype-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-definitions (consumable-id @ux, label @t, quantity-unit @tas, archived @f, recorded-at @da) PRIMARY KEY (consumable-id); "
    "CREATE TABLE rover..consumable-acquisitions (consumable-acquisition-id @ux, vehicle-id @ux, consumable-id @ux, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (consumable-id) REFERENCES consumable-definitions (consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-purchases (consumable-acquisition-id @ux, quantity-milli @ud, quantity-unit @tas, unit-price-mills @ud, currency @tas, settlement-mode @tas, price-profile @tas, minor-unit-decimals @ud, cash-increment-mills @ud) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (consumable-acquisition-id) REFERENCES consumable-acquisitions (consumable-acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-acquisition-stations (consumable-acquisition-id @ux, station-id @ux) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (consumable-acquisition-id) REFERENCES consumable-acquisitions (consumable-acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-acquisition-odometers (consumable-acquisition-id @ux, odometer-id @ux) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (consumable-acquisition-id) REFERENCES consumable-acquisitions (consumable-acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (odometer-id) REFERENCES odometer-observations (odometer-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    (relation-pour def-relations)
  ==
::
++  display-preference-schema
  ^-  tape
  "CREATE TABLE rover..vehicle-display-preferences (vehicle-id @ux, distance-unit @tas, currency @tas, recorded-at @da) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
::
::  The definition-layer pour, named relation by relation. `schema-m0` welds the
::  whole list for a fresh database; `ensure-def-schema` pours only the members
::  an installed ship is missing. One copy of each statement, so the two paths
::  cannot drift.
::
::  ORDER IS LOAD-BEARING. Obelisk rejects a foreign key to a table that does
::  not exist yet, so every parent precedes its children here.
++  def-relations
  ^-  (list [name=@tas ddl=tape])
  :~  ::  M7 T3. The link keys to the energy event-family parent, so fuel fills
      ::  and charging sessions share one optional odometer association.
      :-  %energy-acquisition-odometers
      "CREATE TABLE rover..energy-acquisition-odometers (acquisition-id @ux, odometer-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (odometer-id) REFERENCES odometer-observations (odometer-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %vehicle-consumables
      "CREATE TABLE rover..vehicle-consumables (vehicle-id @ux, consumable-id @ux, archived @f) PRIMARY KEY (vehicle-id, consumable-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (consumable-id) REFERENCES consumable-definitions (consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %vehicle-consumable-tank-size
      "CREATE TABLE rover..vehicle-consumable-tank-size (vehicle-id @ux, consumable-id @ux, digits @ud, decimals @ud, unit @tas) PRIMARY KEY (vehicle-id, consumable-id) FOREIGN KEY (vehicle-id, consumable-id) REFERENCES vehicle-consumables (vehicle-id, consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  M7 T1. The third event-family parent, beside energy-acquisitions and
      ::  consumable-acquisitions. It carries the common event header and NO
      ::  type-specific column: the kind is which typed child row exists.
      :-  %vehicle-events
      "CREATE TABLE rover..vehicle-events (event-id @ux, vehicle-id @ux, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (event-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  M7 T4. Buying a vehicle is an event-family child. Its price,
      ::  odometer, counterparty, payment method, tags, and notes all use the
      ::  parent-keyed associations below, so the typed child is identity only.
      :-  %vehicle-acquisitions
      "CREATE TABLE rover..vehicle-acquisitions (event-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  Identity only, exactly as charging-sessions carries identity only.
      ::  Rover's atomic write and reconciliation hold exactly-one-child;
      ::  Obelisk cannot express a cross-table XOR.
      :-  %service-events
      "CREATE TABLE rover..service-events (event-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %expense-events
      "CREATE TABLE rover..expense-events (event-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %note-events
      "CREATE TABLE rover..note-events (event-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  Disposal kind is mandatory and intrinsic to disposing of a vehicle.
      ::  It therefore lives on the typed child, not in an association that
      ::  could attach a disposal-only value to an unrelated event kind.
      :-  %disposal-kind-definitions
      "CREATE TABLE rover..disposal-kind-definitions (disposal-kind-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (disposal-kind-id); "
      :-  %vehicle-disposals
      "CREATE TABLE rover..vehicle-disposals (event-id @ux, disposal-kind-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (disposal-kind-id) REFERENCES disposal-kind-definitions (disposal-kind-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  Cost evidence, shaped like charging-costs. The state column is what
      ::  lets a later itemized service invoice attach components without a
      ::  column on this row. An event with no cost has NO row here.
      :-  %vehicle-event-costs
      "CREATE TABLE rover..vehicle-event-costs (event-id @ux, cost-state @tas, currency @tas, minor-unit-decimals @ud, recorded-at @da) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  The entered total, held exactly as charging-cost-source-totals holds
      ::  a receipt total. A shop invoice has no quantity and no unit price, so
      ::  there are no operands to multiply and nothing is derived.
      :-  %vehicle-event-cost-totals
      "CREATE TABLE rover..vehicle-event-cost-totals (event-id @ux, total-mills @ud) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-event-costs (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  Every association below keys to the PARENT. A link keyed to a typed
      ::  child leaves every sibling of that child with a hole - the defect
      ::  fuel-fill-subtype and fuel-fill-odometers each shipped once. M7 T3
      ::  repairs the latter with energy-acquisition-odometers.
      :-  %vehicle-event-odometers
      "CREATE TABLE rover..vehicle-event-odometers (event-id @ux, odometer-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (odometer-id) REFERENCES odometer-observations (odometer-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %vehicle-event-stations
      "CREATE TABLE rover..vehicle-event-stations (event-id @ux, station-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %vehicle-event-tags
      "CREATE TABLE rover..vehicle-event-tags (event-id @ux, tag-id @ux) PRIMARY KEY (event-id, tag-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (tag-id) REFERENCES tag-definitions (tag-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %vehicle-event-payment-method
      "CREATE TABLE rover..vehicle-event-payment-method (event-id @ux, method-id @ux) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (method-id) REFERENCES payment-method-definitions (method-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      :-  %vehicle-event-notes
      "CREATE TABLE rover..vehicle-event-notes (event-id @ux, note @t) PRIMARY KEY (event-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      ::  M7 T2. An owner-editable name for a kind of service work, shaped
      ::  exactly like tag-definitions. The primary key is ONE column, so a
      ::  later child - the T6 default reminder interval - can reference the
      ::  complete primary key, which is all Obelisk permits a foreign key to
      ::  reference.
      :-  %service-subtype-definitions
      "CREATE TABLE rover..service-subtype-definitions (service-subtype-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (service-subtype-id); "
      ::  Many-to-many, and keyed to the event PARENT. One real service record
      ::  in the owner's corpus carries ten subtypes at once, so this is a link
      ::  relation from the start and never a column. An event with no subtype
      ::  has no row here.
      :-  %vehicle-event-service-subtypes
      "CREATE TABLE rover..vehicle-event-service-subtypes (event-id @ux, service-subtype-id @ux) PRIMARY KEY (event-id, service-subtype-id) FOREIGN KEY (event-id) REFERENCES vehicle-events (event-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (service-subtype-id) REFERENCES service-subtype-definitions (service-subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
  ==
::
++  relation-pour
  |=  relations=(list [name=@tas ddl=tape])
  ^-  tape
  ?~  relations
    ~
  (weld ddl.i.relations $(relations t.relations))
::
++  def-schema-check
  ^-  tape
  "FROM sys.tables WHERE namespace = %dbo SELECT name;"
::
::  Obelisk has no CREATE TABLE IF NOT EXISTS, and a multi-command script is
::  atomic, so one already-poured relation would abort the whole pour. Rover
::  therefore reads the relation list first and sends only what is absent.
::  An empty tape means the installed database is already current.
++  missing-def-schema
  |=  present=(list @tas)
  ^-  tape
  %-  relation-pour
  %+  skip  def-relations
  |=  [name=@tas ddl=tape]
  (lien present |=(had=@tas =(had name)))
::
::  M7 T3 populated-data migration. Each arm is deliberately one phase:
::  Gall records the source rows before the atomic multi-row copy, reads both
::  relations after it, and only then asks Obelisk to drop the old relation.
++  energy-odometer-create
  ^-  tape
  "CREATE TABLE rover..energy-acquisition-odometers (acquisition-id @ux, odometer-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (odometer-id) REFERENCES odometer-observations (odometer-id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
::
++  energy-odometer-migration-check
  ^-  tape
  ;:  weld
    "FROM fuel-fill-odometers F SELECT F.acquisition-id, F.odometer-id; "
    "FROM energy-acquisition-odometers L SELECT L.acquisition-id, L.odometer-id;"
  ==
::
++  energy-odometer-drop-old
  ^-  tape
  "DROP TABLE FORCE fuel-fill-odometers;"
::
++  verify-schema
  ^-  tape
  ;:  weld
    "FROM sys.tables WHERE namespace = %dbo SELECT name; "
    "FROM sys.columns WHERE namespace = %dbo SELECT name, col-name, col-type; "
    "FROM sys.foreign-keys SELECT parent-table, child-table, ordinal, parent-column, child-column, on-delete, on-update;"
  ==
::
++  ui-view
  ^-  tape
  ;:  weld
    "FROM vehicles V SELECT V.vehicle-id, V.label, V.archived; "
    "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id SELECT V.vehicle-id, O.value-digits, O.decimal-places, O.unit, O.observed-start, O.observed-end, O.source-zone, O.recorded-at; "
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id SELECT V.vehicle-id, E.label AS energy, E.physical-kind, E.quantity-unit, E.archived AS energy-archived, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id SELECT V.vehicle-id, E.label AS default-energy; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id SELECT V.vehicle-id, A.acquisition-id, E.label AS energy, F.quantity-milli, F.quantity-unit, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills, A.observed-start, A.observed-end, A.source-zone, A.recorded-at;"
    " FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id JOIN charging-costs K ON C.acquisition-id = K.acquisition-id SELECT V.vehicle-id, C.acquisition-id, E.label AS energy, A.observed-start, A.observed-end, A.source-zone, A.recorded-at, K.cost-state, K.currency;"
    " FROM charging-energy-measurements M SELECT M.acquisition-id, M.quantity, M.decimals, M.measure-unit, M.point, M.evidence;"
    " FROM charging-session-batteries L JOIN battery-observation-percent P ON L.battery-observation-id = P.battery-observation-id SELECT L.acquisition-id, L.endpoint, P.value-digits, P.value-decimals;"
    " FROM stations S JOIN places P ON S.place-id = P.place-id SELECT S.station-id, S.label, S.station-kind, S.archived, P.place-id, P.label AS place;"
    " FROM additive-definitions D SELECT D.additive-id, D.label, D.archived;"
    " FROM energy-acquisition-stations L JOIN stations S ON L.station-id = S.station-id JOIN places P ON S.place-id = P.place-id SELECT L.acquisition-id, S.label AS station, P.label AS place;"
    " FROM fuel-fill-additives L JOIN additive-definitions D ON L.additive-id = D.additive-id SELECT L.acquisition-id, D.label AS additive;"
    " FROM vehicle-display-preferences P SELECT P.vehicle-id, P.distance-unit, P.currency;"
    " FROM fuel-fill-subtype L JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id SELECT L.acquisition-id, S.label AS subtype;"
    " FROM energy-definition-subtypes S JOIN energy-definitions E ON S.energy-definition-id = E.energy-definition-id WHERE S.archived = N AND E.archived = N SELECT S.subtype-id, S.energy-definition-id, S.label, S.archived, E.label AS energy;"
    " FROM vehicles V JOIN vehicle-default-energy-subtype D ON V.vehicle-id = D.vehicle-id JOIN energy-definition-subtypes S ON D.subtype-id = S.subtype-id SELECT V.label AS vehicle, S.label AS subtype;"
    " FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id SELECT V.label AS vehicle, D.label, D.archived AS mode-archived, L.archived AS link-archived;"
    " FROM tag-definitions T SELECT T.tag-id, T.label, T.archived;"
    " FROM custom-field-definitions C WHERE C.target = %fill SELECT C.field-id, C.label, C.content-type, C.entry-type, C.mandatory, C.archived;"
    " FROM economy-breaks B SELECT B.acquisition-id, B.reason;"
    " FROM app-default-vehicle A JOIN vehicles V ON A.vehicle-id = V.vehicle-id WHERE A.scope = %app SELECT V.vehicle-id, V.label, A.recorded-at;"
    " FROM vehicle-tank-size T SELECT T.vehicle-id, T.digits, T.decimals, T.size-unit;"
    " FROM energy-acquisition-odometers L JOIN odometer-observations O ON L.odometer-id = O.odometer-id SELECT L.acquisition-id, O.value-digits, O.decimal-places, O.unit;"
    " FROM energy-definitions E SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived;"
    " FROM fuel-fill-driving-mode L JOIN driving-mode-definitions D ON L.mode-id = D.mode-id SELECT L.acquisition-id, D.label AS driving-mode;"
    " FROM fuel-fill-average-speed S SELECT S.acquisition-id, S.digits, S.decimals, S.speed-unit;"
    " FROM fuel-fill-drive-balance B SELECT B.acquisition-id, B.highway-percent;"
    " FROM fill-notes X SELECT X.acquisition-id, X.note;"
    " FROM fuel-fill-payment-method L JOIN payment-method-definitions P ON L.method-id = P.method-id SELECT L.acquisition-id, P.label AS payment-method;"
    " FROM payment-method-definitions P SELECT P.method-id, P.label, P.archived;"
    " FROM consumable-definitions C SELECT C.consumable-id, C.label, C.quantity-unit, C.archived;"
    " FROM fuel-fill-tags L JOIN tag-definitions T ON L.tag-id = T.tag-id SELECT L.acquisition-id, T.label AS tag;"
    " FROM driving-mode-definitions D SELECT D.mode-id, D.label, D.archived;"
    " FROM vehicles V JOIN vehicle-consumables L ON V.vehicle-id = L.vehicle-id JOIN consumable-definitions C ON L.consumable-id = C.consumable-id SELECT V.vehicle-id, C.consumable-id, C.label AS consumable, L.archived AS link-archived;"
    " FROM vehicle-consumable-tank-size T JOIN consumable-definitions C ON T.consumable-id = C.consumable-id SELECT T.vehicle-id, T.consumable-id, C.label AS consumable, T.digits, T.decimals, T.unit;"
    " FROM vehicles V JOIN consumable-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN consumable-definitions C ON A.consumable-id = C.consumable-id JOIN consumable-purchases P ON A.consumable-acquisition-id = P.consumable-acquisition-id WHERE C.label = 'DEF' SELECT V.vehicle-id, A.consumable-acquisition-id, C.label AS consumable, P.quantity-milli, P.quantity-unit, A.observed-start;"
    " FROM consumable-acquisition-odometers L JOIN odometer-observations O ON L.odometer-id = O.odometer-id SELECT L.consumable-acquisition-id, O.value-digits, O.decimal-places, O.unit;"
    " FROM places P JOIN place-address-parts A ON P.place-id = A.place-id WHERE A.part = %locality SELECT P.place-id, P.label AS place, A.value AS locality;"
    " FROM vehicle-refill-reserve R SELECT R.vehicle-id, R.reserve-percent;"
    " FROM charging-cost-components C SELECT C.acquisition-id, C.component, C.quantity, C.quantity-decimals, C.quantity-unit, C.rate-mills, C.amount-mills;"
    " FROM charging-cost-source-totals T SELECT T.acquisition-id, T.total-mills;"
    ::  The event family reads as a parent plus its typed children plus its
    ::  parent-keyed links. The child queries are what tell the view which kind
    ::  an event is; there is no kind column to read.
    " FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id SELECT V.vehicle-id, E.event-id, E.observed-start, E.observed-end, E.source-zone, E.recorded-at;"
    " FROM service-events S SELECT S.event-id;"
    " FROM expense-events X SELECT X.event-id;"
    ::  The alias is Z, not N. `N` is the boolean false literal, and the parser
    ::  reads a relation alias `N` as that literal and rejects the script.
    " FROM note-events Z SELECT Z.event-id;"
    ::  Cost parent and total stay separate queries. An inner join would drop
    ::  a cost row that carries a state but no total.
    " FROM vehicle-event-costs C SELECT C.event-id, C.cost-state, C.currency, C.minor-unit-decimals;"
    " FROM vehicle-event-cost-totals T SELECT T.event-id, T.total-mills;"
    " FROM vehicle-event-odometers L JOIN odometer-observations O ON L.odometer-id = O.odometer-id SELECT L.event-id, O.value-digits, O.decimal-places, O.unit;"
    ::  The link relation is joined LAST on purpose. The pinned engine crashes
    ::  on a three-way join whose leftmost relation is empty and whose third
    ::  join keys off the second, which is every fresh install before the first
    ::  event. Naming places first keeps the shape legal from row zero.
    " FROM places P JOIN stations S ON P.place-id = S.place-id JOIN vehicle-event-stations L ON S.station-id = L.station-id SELECT L.event-id, S.label AS station, P.label AS place;"
    " FROM vehicle-event-tags L JOIN tag-definitions T ON L.tag-id = T.tag-id SELECT L.event-id, T.label AS tag;"
    " FROM vehicle-event-payment-method L JOIN payment-method-definitions P ON L.method-id = P.method-id SELECT L.event-id, P.label AS payment-method;"
    " FROM vehicle-event-notes X SELECT X.event-id, X.note;"
    ::  M7 T2. The subtype link and the definition catalog. The link keys to
    ::  the event parent, so one query serves every kind.
    " FROM vehicle-event-service-subtypes L JOIN service-subtype-definitions S ON L.service-subtype-id = S.service-subtype-id SELECT L.event-id, S.label AS service-subtype;"
    " FROM service-subtype-definitions S SELECT S.service-subtype-id, S.label, S.archived;"
    ::  M7 T4 appends its queries so every shipped positional result above
    ::  keeps its index. The disposal join exposes a human label, never its id.
    " FROM vehicle-acquisitions A SELECT A.event-id;"
    " FROM vehicle-disposals D JOIN disposal-kind-definitions K ON D.disposal-kind-id = K.disposal-kind-id SELECT D.event-id, K.label AS disposal-kind;"
    " FROM disposal-kind-definitions D SELECT D.disposal-kind-id, D.label, D.archived;"
  ==
::
++  sql-quote
  |=  value=@t
  ^-  tape
  (sql-quote-chars (trip value))
::
++  sql-quote-chars
  |=  chars=tape
  ^-  tape
  ?~  chars
    ~
  =/  escaped=tape  ?:  =(39 i.chars)  "\\'"  [i.chars ~]
  (weld escaped (sql-quote-chars t.chars))
::
++  sql-ud
  |=  value=@ud
  ^-  tape
  %+  skip  (scow %ud value)
  |=  char=@t
  =('.' char)
::
++  sql-term
  |=  value=@tas
  ^-  tape
  ['%' (scow %tas value)]
::
++  fill-lookup
  |=  [vehicle-label=@t definition-label=@t]
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND E.label = '"
    (sql-quote definition-label)
    "' SELECT V.vehicle-id, E.energy-definition-id, E.quantity-unit, E.physical-kind;"
    " FROM stations S JOIN places P ON S.place-id = P.place-id SELECT S.station-id, S.label, S.archived, P.label AS place;"
    " FROM additive-definitions D SELECT D.additive-id, D.label, D.archived;"
    " FROM energy-definition-subtypes S JOIN energy-definitions E ON S.energy-definition-id = E.energy-definition-id WHERE E.label = '"
    (sql-quote definition-label)
    "' SELECT S.subtype-id, S.label, S.archived;"
    " FROM vehicles V JOIN vehicle-default-energy-subtype D ON V.vehicle-id = D.vehicle-id JOIN energy-definition-subtypes S ON D.subtype-id = S.subtype-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT S.subtype-id, S.label;"
    " FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT D.mode-id, D.label, D.archived AS mode-archived, L.archived AS link-archived;"
    " FROM tag-definitions T SELECT T.tag-id, T.label, T.archived;"
    " FROM custom-field-definitions C WHERE C.target = %fill SELECT C.field-id, C.label, C.content-type, C.entry-type, C.mandatory, C.archived;"
    " FROM payment-method-definitions P SELECT P.method-id, P.label, P.archived;"
  ==
::
++  edit-fill-lookup
  |=  [vehicle-label=@t observed-start=@da definition-label=@t]
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT A.acquisition-id, V.vehicle-id; "
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND E.label = '"
    (sql-quote definition-label)
    "' SELECT E.energy-definition-id, E.quantity-unit, E.physical-kind; "
    "FROM stations S JOIN places P ON S.place-id = P.place-id SELECT S.station-id, S.label, S.archived, P.label AS place; "
    "FROM additive-definitions D SELECT D.additive-id, D.label, D.archived; "
    "FROM energy-definition-subtypes S JOIN energy-definitions E ON S.energy-definition-id = E.energy-definition-id WHERE E.label = '"
    (sql-quote definition-label)
    "' SELECT S.subtype-id, S.label, S.archived; "
    "FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT D.mode-id, D.label, D.archived AS mode-archived, L.archived AS link-archived; "
    "FROM tag-definitions T SELECT T.tag-id, T.label, T.archived; "
    "FROM payment-method-definitions P SELECT P.method-id, P.label, P.archived; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-acquisition-odometers L ON A.acquisition-id = L.acquisition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT L.odometer-id;"
  ==
::
++  update-fill
  |=  $:  acquisition-id=@ux
          vehicle-id=@ux
          definition-id=@ux
          quantity-unit=@tas
          station-id=(unit @ux)
          additive-ids=(list @ux)
          subtype-id=(unit @ux)
          driving-mode-id=(unit @ux)
          tag-ids=(list @ux)
          payment-method-id=(unit @ux)
          current-odometer-id=(unit @ux)
          new-odometer-id=@ux
          input=fill-entry:rover
          recorded-at=@da
      ==
  ^-  tape
  =/  acquisition  (scow %ux acquisition-id)
  =/  observed  (scow %da observed-start.input)
  =/  observed-end  (scow %da (add observed-start.input (bex 64)))
  =/  station-row=tape
    ?~  station-id
      ~
    ;:  weld
      " INSERT INTO energy-acquisition-stations VALUES ("
      acquisition
      ", "
      (scow %ux u.station-id)
      ");"
    ==
  =/  subtype-row=tape
    ?~  subtype-id
      ~
    ;:  weld
      " INSERT INTO fuel-fill-subtype VALUES ("
      acquisition
      ", "
      (scow %ux u.subtype-id)
      ");"
    ==
  =/  mode-row=tape
    ?~  driving-mode-id
      ~
    ;:  weld
      " INSERT INTO fuel-fill-driving-mode VALUES ("
      acquisition
      ", "
      (scow %ux u.driving-mode-id)
      ");"
    ==
  =/  speed-row=tape
    ?~  average-speed.input
      ~
    ;:  weld
      " INSERT INTO fuel-fill-average-speed VALUES ("
      acquisition
      ", "
      (sql-ud digits.u.average-speed.input)
      ", "
      (sql-ud places.u.average-speed.input)
      ", "
      (sql-term value-unit.u.average-speed.input)
      ");"
    ==
  =/  balance-row=tape
    ?~  drive-balance.input
      ~
    ;:  weld
      " INSERT INTO fuel-fill-drive-balance VALUES ("
      acquisition
      ", "
      (sql-ud u.drive-balance.input)
      ");"
    ==
  =/  break-row=tape
    ?.  missed-fill.input
      ~
    ;:  weld
      " INSERT INTO economy-breaks VALUES ("
      acquisition
      ", %missed-fill, "
      (scow %da recorded-at)
      ");"
    ==
  =/  note-row=tape
    ?~  notes.input
      ~
    ;:  weld
      " INSERT INTO fill-notes VALUES ("
      acquisition
      ", '"
      (sql-quote u.notes.input)
      "');"
    ==
  =/  payment-row=tape
    ?~  payment-method-id
      ~
    ;:  weld
      " INSERT INTO fuel-fill-payment-method VALUES ("
      acquisition
      ", "
      (scow %ux u.payment-method-id)
      ");"
    ==
  =/  odometer-row=tape
    ?~  mileage.input
      ~
    ?^  current-odometer-id
      ;:  weld
        " UPDATE odometer-observations SET value-digits = "
        (sql-ud digits.u.mileage.input)
        ", decimal-places = "
        (sql-ud places.u.mileage.input)
        ", unit = "
        (sql-term odo-unit.u.mileage.input)
        ", observed-start = "
        observed
        ", observed-end = "
        observed-end
        ", source-zone = '"
        (sql-quote source-zone.input)
        "', recorded-at = "
        (scow %da recorded-at)
        " WHERE odometer-id = "
        (scow %ux u.current-odometer-id)
        ";"
      ==
    ;:  weld
      " INSERT INTO odometer-observations VALUES ("
      (scow %ux new-odometer-id)
      ", "
      (scow %ux vehicle-id)
      ", "
      (sql-ud digits.u.mileage.input)
      ", "
      (sql-ud places.u.mileage.input)
      ", "
      (sql-term odo-unit.u.mileage.input)
      ", "
      observed
      ", "
      observed-end
      ", %second, '"
      (sql-quote source-zone.input)
      "', "
      (scow %da recorded-at)
      "); INSERT INTO energy-acquisition-odometers VALUES ("
      acquisition
      ", "
      (scow %ux new-odometer-id)
      ");"
    ==
  ;:  weld
    "UPDATE energy-acquisitions SET energy-definition-id = "
    (scow %ux definition-id)
    ", observed-start = "
    observed
    ", observed-end = "
    observed-end
    ", source-zone = '"
    (sql-quote source-zone.input)
    "', recorded-at = "
    (scow %da recorded-at)
    " WHERE acquisition-id = "
    acquisition
    "; "
    "UPDATE fuel-fills SET quantity-milli = "
    (sql-ud quantity-milli.input)
    ", tank-state = "
    (sql-term tank-state.input)
    ", unit-price-mills = "
    (sql-ud unit-price-mills.input)
    ", currency = "
    (sql-term currency.input)
    ", settlement-mode = "
    (sql-term settlement-mode.input)
    ", price-profile = "
    (sql-term price-profile.input)
    ", minor-unit-decimals = "
    (sql-ud minor-unit-decimals.input)
    ", cash-increment-mills = "
    (sql-ud cash-increment-mills.input)
    ", quantity-unit = "
    (sql-term quantity-unit)
    " WHERE acquisition-id = "
    acquisition
    "; DELETE FROM energy-acquisition-stations WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fuel-fill-additives WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fuel-fill-subtype WHERE acquisition-id = "
    acquisition
    "; DELETE FROM economy-breaks WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fuel-fill-driving-mode WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fuel-fill-average-speed WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fuel-fill-drive-balance WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fuel-fill-tags WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fill-notes WHERE acquisition-id = "
    acquisition
    "; DELETE FROM fuel-fill-payment-method WHERE acquisition-id = "
    acquisition
    "; "
    station-row
    (insert-fill-additives acquisition-id additive-ids)
    subtype-row
    break-row
    mode-row
    speed-row
    balance-row
    (insert-fill-tags acquisition-id tag-ids)
    note-row
    payment-row
    odometer-row
  ==
::
++  vehicle-lookup
  |=  vehicle-label=@t
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT V.vehicle-id;"
  ==
::
++  app-default-lookup
  |=  vehicle-label=@t
  ^-  tape
  ;:  weld
    (vehicle-lookup vehicle-label)
    " FROM app-default-vehicle A SELECT A.scope, A.vehicle-id, A.recorded-at;"
  ==
::
++  archive-vehicle-lookup
  |=  vehicle-label=@t
  ^-  tape
  ;:  weld
    (vehicle-lookup vehicle-label)
    " FROM app-default-vehicle A WHERE A.scope = %app SELECT A.vehicle-id;"
  ==
::
++  write-app-default
  |=  [vehicle-id=@ux exists=? recorded-at=@da]
  ^-  tape
  ?:  exists
    ;:  weld
      "UPDATE app-default-vehicle SET vehicle-id = "
      (scow %ux vehicle-id)
      ", recorded-at = "
      (scow %da recorded-at)
      " WHERE scope = %app;"
    ==
  ;:  weld
    "INSERT INTO app-default-vehicle VALUES (%app, "
    (scow %ux vehicle-id)
    ", "
    (scow %da recorded-at)
    ");"
  ==
::
++  delete-vehicle
  |=  vehicle-id=@ux
  ^-  tape
  =/  id  (scow %ux vehicle-id)
  ;:  weld
    "DELETE FROM vehicle-display-preferences WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-refill-reserve WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-default-energy-subtype WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-driving-modes WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-tank-size WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-default-energy-definitions WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-energy-definitions WHERE vehicle-id = "
    id
    "; DELETE FROM vehicles WHERE vehicle-id = "
    id
    ";"
  ==
::
++  archive-vehicle
  |=  vehicle-id=@ux
  ^-  tape
  ;:  weld
    "UPDATE vehicles SET archived = Y WHERE vehicle-id = "
    (scow %ux vehicle-id)
    ";"
  ==
::
++  new-vehicle-lookup
  ^-  tape
  ;:  weld
    "FROM energy-definitions E WHERE E.archived = N SELECT E.energy-definition-id, E.label, E.physical-kind; "
    "FROM driving-mode-definitions D WHERE D.archived = N SELECT D.mode-id, D.label; "
    "FROM consumable-definitions C WHERE C.label = 'DEF' AND C.archived = N SELECT C.consumable-id, C.label, C.quantity-unit;"
  ==
::
++  insert-energy-source-type
  |=  [definition-id=@ux label=@t physical-kind=@tas quantity-unit=@tas now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO energy-definitions VALUES ("
    (scow %ux definition-id)
    ", '"
    (sql-quote label)
    "', "
    (sql-term physical-kind)
    ", "
    (sql-term quantity-unit)
    ", N, "
    (scow %da now)
    ");"
  ==
::
++  insert-driving-mode-type
  |=  [mode-id=@ux label=@t now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO driving-mode-definitions VALUES ("
    (scow %ux mode-id)
    ", '"
    (sql-quote label)
    "', N, "
    (scow %da now)
    ");"
  ==
::
++  vehicle-edit-lookup
  |=  vehicle-label=@t
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT V.vehicle-id, V.label, V.archived; "
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definition-subtypes S ON L.energy-definition-id = S.energy-definition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND L.archived = N AND S.archived = N SELECT S.subtype-id, S.label, S.archived; "
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT E.energy-definition-id, E.label, L.archived AS link-archived; "
    "FROM energy-definitions E WHERE E.archived = N SELECT E.energy-definition-id, E.label; "
    "FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT D.mode-id, D.label, L.archived AS link-archived; "
    "FROM driving-mode-definitions D WHERE D.archived = N SELECT D.mode-id, D.label;"
    " FROM consumable-definitions C WHERE C.label = 'DEF' AND C.archived = N SELECT C.consumable-id, C.label, C.quantity-unit; "
    "FROM vehicles V JOIN vehicle-consumables L ON V.vehicle-id = L.vehicle-id JOIN consumable-definitions C ON L.consumable-id = C.consumable-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND C.label = 'DEF' SELECT C.consumable-id, C.label, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-consumable-tank-size T ON V.vehicle-id = T.vehicle-id JOIN consumable-definitions C ON T.consumable-id = C.consumable-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND C.label = 'DEF' SELECT C.consumable-id, T.digits, T.decimals, T.unit; "
    "FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT D.energy-definition-id;"
  ==
::
++  has-id
  |=  [needle=@ux ids=(list @ux)]
  ^-  ?
  ?~  ids
    %.n
  ?:  =(needle i.ids)
    %.y
  $(ids t.ids)
::
++  unique-ids
  |=  ids=(list @ux)
  ^-  (list @ux)
  ?~  ids
    ~
  ?:  (has-id i.ids t.ids)
    $(ids t.ids)
  [i.ids $(ids t.ids)]
::
++  sync-energy-current
  |=  [vehicle-id=@ux current=(list @ux) desired=(list @ux)]
  ^-  tape
  ?~  current
    ~
  ;:  weld
    "UPDATE vehicle-energy-definitions SET archived = "
    ?:  (has-id i.current desired)
      "N"
    "Y"
    " WHERE vehicle-id = "
    (scow %ux vehicle-id)
    " AND energy-definition-id = "
    (scow %ux i.current)
    "; "
    $(current t.current)
  ==
::
++  add-energy-missing
  |=  [vehicle-id=@ux current=(list @ux) desired=(list @ux)]
  ^-  tape
  ?~  desired
    ~
  =/  rest  $(desired t.desired)
  ?:  (has-id i.desired current)
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
++  sync-mode-current
  |=  [vehicle-id=@ux current=(list @ux) desired=(list @ux)]
  ^-  tape
  ?~  current
    ~
  ;:  weld
    "UPDATE vehicle-driving-modes SET archived = "
    ?:  (has-id i.current desired)
      "N"
    "Y"
    " WHERE vehicle-id = "
    (scow %ux vehicle-id)
    " AND mode-id = "
    (scow %ux i.current)
    "; "
    $(current t.current)
  ==
::
++  add-mode-missing
  |=  [vehicle-id=@ux current=(list @ux) desired=(list @ux)]
  ^-  tape
  ?~  desired
    ~
  =/  rest  $(desired t.desired)
  ?:  (has-id i.desired current)
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
++  update-vehicle-settings
  |=  $:  vehicle-id=@ux
          input=vehicle-edit-entry:rover
          subtype-id=(unit @ux)
          current-energy-ids=(list @ux)
          energy-ids=(unit (list @ux))
          default-energy-id=(unit @ux)
          current-mode-ids=(list @ux)
          mode-ids=(unit (list @ux))
          current-def=?
          def-consumable-id=(unit @ux)
          now=@da
      ==
  ^-  tape
  =/  id  (scow %ux vehicle-id)
  =/  tank-script=tape
    ?~  tank-size.input
      ~
    ;:  weld
      "INSERT INTO vehicle-tank-size VALUES ("
      id
      ", "
      (sql-ud digits.u.tank-size.input)
      ", "
      (sql-ud places.u.tank-size.input)
      ", "
      (sql-term value-unit.u.tank-size.input)
      "); "
    ==
  =/  reserve-script=tape
    ?~  refill-reserve.input
      ~
    ;:  weld
      "INSERT INTO vehicle-refill-reserve VALUES ("
      id
      ", "
      (sql-ud u.refill-reserve.input)
      "); "
    ==
  =/  subtype-script=tape
    ?~  subtype-id
      ~
    ;:  weld
      "INSERT INTO vehicle-default-energy-subtype VALUES ("
      id
      ", "
      (scow %ux u.subtype-id)
      ", "
      (scow %da now)
      "); "
    ==
  =/  energy-script=tape
    ?~  energy-ids
      ~
    ;:  weld
      (sync-energy-current vehicle-id current-energy-ids u.energy-ids)
      (add-energy-missing vehicle-id current-energy-ids u.energy-ids)
    ==
  =/  mode-script=tape
    ?~  mode-ids
      ~
    ;:  weld
      (sync-mode-current vehicle-id current-mode-ids u.mode-ids)
      (add-mode-missing vehicle-id current-mode-ids u.mode-ids)
    ==
  =/  default-energy-script=tape
    ?~  default-energy-id
      ~
    ;:  weld
      "DELETE FROM vehicle-default-energy-definitions WHERE vehicle-id = "
      id
      "; INSERT INTO vehicle-default-energy-definitions VALUES ("
      id
      ", "
      (scow %ux u.default-energy-id)
      "); "
    ==
  =/  def-delete=tape
    ?~  def-enabled.input
      ~
    ?~  def-consumable-id
      ~
    =/  def-id  (scow %ux u.def-consumable-id)
    ;:  weld
      "DELETE FROM vehicle-consumable-tank-size WHERE vehicle-id = "
      id
      " AND consumable-id = "
      def-id
      "; "
    ==
  =/  def-membership=tape
    ?~  def-enabled.input
      ~
    ?~  def-consumable-id
      ~
    =/  def-id  (scow %ux u.def-consumable-id)
    ?:  current-def
      ;:  weld
        "UPDATE vehicle-consumables SET archived = "
        ?:  u.def-enabled.input
          "N"
        "Y"
        " WHERE vehicle-id = "
        id
        " AND consumable-id = "
        def-id
        "; "
      ==
    ?:  u.def-enabled.input
      ;:  weld
        "INSERT INTO vehicle-consumables VALUES ("
        id
        ", "
        def-id
        ", N); "
      ==
    ~
  =/  def-tank-insert=tape
    ?~  def-enabled.input
      ~
    ?.  u.def-enabled.input
      ~
    ?~  def-consumable-id
      ~
    ?~  def-tank-size.input
      ~
    ;:  weld
      "INSERT INTO vehicle-consumable-tank-size VALUES ("
      id
      ", "
      (scow %ux u.def-consumable-id)
      ", "
      (sql-ud digits.u.def-tank-size.input)
      ", "
      (sql-ud places.u.def-tank-size.input)
      ", "
      (sql-term value-unit.u.def-tank-size.input)
      "); "
    ==
  ;:  weld
    "UPDATE vehicles SET label = '"
    (sql-quote label.input)
    "' WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-tank-size WHERE vehicle-id = "
    id
    "; DELETE FROM vehicle-refill-reserve WHERE vehicle-id = "
    id
    "; "
    "DELETE FROM vehicle-default-energy-subtype WHERE vehicle-id = "
    id
    "; "
    def-delete
    tank-script
    reserve-script
    subtype-script
    energy-script
    default-energy-script
    mode-script
    def-membership
    def-tank-insert
  ==
::
++  insert-energy-links
  |=  [vehicle-id=@ux definition-ids=(list @ux)]
  ^-  tape
  ?~  definition-ids
    ~
  ;:  weld
    "INSERT INTO vehicle-energy-definitions VALUES ("
    (scow %ux vehicle-id)
    ", "
    (scow %ux i.definition-ids)
    ", N); "
    $(definition-ids t.definition-ids)
  ==
::
++  insert-mode-links
  |=  [vehicle-id=@ux mode-ids=(list @ux)]
  ^-  tape
  ?~  mode-ids
    ~
  ;:  weld
    "INSERT INTO vehicle-driving-modes VALUES ("
    (scow %ux vehicle-id)
    ", "
    (scow %ux i.mode-ids)
    ", N); "
    $(mode-ids t.mode-ids)
  ==
::
++  insert-vehicle
  |=  $:  vehicle-id=@ux
          label=@t
          definition-id=@ux
          definition-ids=(list @ux)
          mode-ids=(list @ux)
          def-consumable-id=(unit @ux)
          def-tank-size=(unit scaled-entry:rover)
          recorded-at=@da
      ==
  ^-  tape
  =/  def-script=tape
    ?~  def-consumable-id
      ~
    =/  def-id  (scow %ux u.def-consumable-id)
    =/  tank-script=tape
      ?~  def-tank-size
        ~
      ;:  weld
        "INSERT INTO vehicle-consumable-tank-size VALUES ("
        (scow %ux vehicle-id)
        ", "
        def-id
        ", "
        (sql-ud digits.u.def-tank-size)
        ", "
        (sql-ud places.u.def-tank-size)
        ", "
        (sql-term value-unit.u.def-tank-size)
        "); "
      ==
    ;:  weld
      "INSERT INTO vehicle-consumables VALUES ("
      (scow %ux vehicle-id)
      ", "
      def-id
      ", N); "
      tank-script
    ==
  ;:  weld
    "INSERT INTO vehicles VALUES ("
    (scow %ux vehicle-id)
    ", '"
    (sql-quote label)
    "', N, "
    (scow %da recorded-at)
    "); "
    (insert-energy-links vehicle-id definition-ids)
    (insert-mode-links vehicle-id mode-ids)
    def-script
    "INSERT INTO vehicle-default-energy-definitions VALUES ("
    (scow %ux vehicle-id)
    ", "
    (scow %ux definition-id)
    ");"
  ==
::
++  insert-custom-definition
  |=  [field-id=@ux input=custom-definition-entry:rover recorded-at=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO custom-field-definitions VALUES ("
    (scow %ux field-id)
    ", '"
    (sql-quote label.input)
    "', "
    (sql-term content-type.input)
    ", %direct, "
    ?:(mandatory.input "Y" "N")
    ", %fill, N, "
    (scow %da recorded-at)
    ");"
  ==
::
++  custom-field-lookup
  |=  label=@t
  ^-  tape
  ;:  weld
    "FROM custom-field-definitions C WHERE C.label = '"
    (sql-quote label)
    "' SELECT C.field-id, C.label, C.content-type, C.mandatory, C.archived;"
    " FROM custom-field-definitions C JOIN custom-field-values-number V ON C.field-id = V.field-id WHERE C.label = '"
    (sql-quote label)
    "' SELECT V.parent-id;"
    " FROM custom-field-definitions C JOIN custom-field-values-text V ON C.field-id = V.field-id WHERE C.label = '"
    (sql-quote label)
    "' SELECT V.parent-id;"
    " FROM custom-field-definitions C JOIN custom-field-values-boolean V ON C.field-id = V.field-id WHERE C.label = '"
    (sql-quote label)
    "' SELECT V.parent-id;"
  ==
::
++  archive-custom-field
  |=  field-id=@ux
  ^-  tape
  ;:  weld
    "UPDATE custom-field-definitions SET archived = Y WHERE field-id = "
    (scow %ux field-id)
    ";"
  ==
::
++  change-custom-field-type
  |=  [field-id=@ux content-type=@tas]
  ^-  tape
  ;:  weld
    "UPDATE custom-field-definitions SET content-type = "
    (sql-term content-type)
    " WHERE field-id = "
    (scow %ux field-id)
    ";"
  ==
::
++  insert-custom-number
  |=  [field-id=@ux parent-id=@ux digits=@ud decimals=@ud]
  ^-  tape
  ;:  weld
    " INSERT INTO custom-field-values-number VALUES ("
    (scow %ux field-id)
    ", "
    (scow %ux parent-id)
    ", "
    (sql-ud digits)
    ", "
    (sql-ud decimals)
    ", %unitless);"
  ==
::
++  insert-custom-text
  |=  [field-id=@ux parent-id=@ux value=@t]
  ^-  tape
  ;:  weld
    " INSERT INTO custom-field-values-text VALUES ("
    (scow %ux field-id)
    ", "
    (scow %ux parent-id)
    ", '"
    (sql-quote value)
    "');"
  ==
::
++  insert-custom-boolean
  |=  [field-id=@ux parent-id=@ux value=?]
  ^-  tape
  ;:  weld
    " INSERT INTO custom-field-values-boolean VALUES ("
    (scow %ux field-id)
    ", "
    (scow %ux parent-id)
    ", "
    ?:(value "Y" "N")
    ");"
  ==
::
++  preference-lookup
  |=  vehicle-label=@t
  ^-  tape
  ;:  weld
    (vehicle-lookup vehicle-label)
    " FROM vehicle-display-preferences P SELECT P.vehicle-id, P.distance-unit, P.currency;"
  ==
::
++  write-preference
  |=  $:  vehicle-id=@ux
          exists=?
          input=preference-entry:rover
          recorded-at=@da
      ==
  ^-  tape
  ?~  distance-unit.input
    ;:  weld
      "DELETE FROM vehicle-display-preferences WHERE vehicle-id = "
      (scow %ux vehicle-id)
      ";"
    ==
  ?:  exists
    ;:  weld
      "UPDATE vehicle-display-preferences SET distance-unit = "
      (sql-term u.distance-unit.input)
      ", currency = "
      (sql-term currency.input)
      ", recorded-at = "
      (scow %da recorded-at)
      " WHERE vehicle-id = "
      (scow %ux vehicle-id)
      ";"
    ==
  ;:  weld
    "INSERT INTO vehicle-display-preferences VALUES ("
    (scow %ux vehicle-id)
    ", "
    (sql-term u.distance-unit.input)
    ", "
    (sql-term currency.input)
    ", "
    (scow %da recorded-at)
    ");"
  ==
::
++  insert-fill
  |=  $:  ids=entry-ids
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
          recorded-at=@da
      ==
  ^-  tape
  =/  acquisition  (scow %ux acquisition.ids)
  =/  odometer  (scow %ux odometer.ids)
  =/  vehicle  (scow %ux vehicle-id)
  =/  definition  (scow %ux definition-id)
  =/  observed-start  (scow %da observed-start.input)
  =/  observed-end  (scow %da (add observed-start.input (bex 64)))
  =/  recorded  (scow %da recorded-at)
  =/  zone  (sql-quote source-zone.input)
  =/  new-station-rows=tape
    ?~  new-station.input
      ~
    =/  place  (scow %ux place.ids)
    =/  address-rows=tape
      ?~  address.u.new-station.input
        ~
      =/  address  u.address.u.new-station.input
      =/  part-row
        |=  [part=@tas value=(unit @t)]
        ^-  tape
        ?~  value
          ~
        ;:  weld
          " INSERT INTO place-address-parts VALUES ("
          place
          ", "
          (sql-term part)
          ", '"
          (sql-quote u.value)
          "');"
        ==
      =/  formatted-row=tape
        ?~  formatted.address
          ~
        ;:  weld
          " INSERT INTO place-address-formatted VALUES ("
          place
          ", '"
          (sql-quote u.formatted.address)
          "');"
        ==
      ;:  weld
        " INSERT INTO place-addresses VALUES ("
        place
        ", %owner, "
        recorded
        ");"
        ::  Q9: parent evidence may have formatted text, structured parts, or
        ::  both. decode-fill enforces that at least one child is present.
        formatted-row
        (part-row %line1 line1.address)
        (part-row %line2 line2.address)
        (part-row %locality locality.address)
        (part-row %region region.address)
        (part-row %postal-code postal-code.address)
        (part-row %country country.address)
      ==
    =/  coordinate-rows=tape
      ?~  coordinates.u.new-station.input
        ~
      ;:  weld
        " INSERT INTO place-coordinates VALUES ("
        place
        ", "
        (scow %sd latitude.u.coordinates.u.new-station.input)
        ", "
        (scow %sd longitude.u.coordinates.u.new-station.input)
        ", 7, %owner, "
        recorded
        ");"
      ==
    ;:  weld
      "INSERT INTO places VALUES ("
      place
      ", '"
      (sql-quote place-label.u.new-station.input)
      "', N, "
      recorded
      "); INSERT INTO stations VALUES ("
      (scow %ux station.ids)
      ", "
      (scow %ux place.ids)
      ", '"
      (sql-quote station-label.u.new-station.input)
      "', "
      (sql-term station-kind.u.new-station.input)
      ", N, "
      recorded
      "); "
      address-rows
      coordinate-rows
    ==
  =/  acquisition-row
    ;:  weld
      "INSERT INTO energy-acquisitions VALUES ("
      acquisition
      ", "
      vehicle
      ", "
      definition
      ", "
      observed-start
      ", "
      observed-end
      ", %second, '"
      zone
      "', "
      recorded
      "); "
    ==
  =/  fill-row
    ;:  weld
      "INSERT INTO fuel-fills VALUES ("
      acquisition
      ", "
      (sql-ud quantity-milli.input)
      ", "
      (sql-term quantity-unit)
      ", "
      (sql-term tank-state.input)
      ", "
      (sql-ud unit-price-mills.input)
      ", "
      (sql-term currency.input)
      ", "
      (sql-term settlement-mode.input)
      ", "
      (sql-term price-profile.input)
      ", "
      (sql-ud minor-unit-decimals.input)
      ", "
      (sql-ud cash-increment-mills.input)
      ");"
    ==
  =/  mileage-rows=tape
    ?~  mileage.input
      ~
    ;:  weld
      " INSERT INTO odometer-observations VALUES ("
      odometer
      ", "
      vehicle
      ", "
      (sql-ud digits.u.mileage.input)
      ", "
      (sql-ud places.u.mileage.input)
      ", "
      (sql-term odo-unit.u.mileage.input)
      ", "
      observed-start
      ", "
      observed-end
      ", %second, '"
      zone
      "', "
      recorded
      "); INSERT INTO energy-acquisition-odometers VALUES ("
      acquisition
      ", "
      odometer
      ");"
    ==
  =/  effective-station=(unit @ux)
    ?^  station-id
      station-id
    ?^  new-station.input
      `station.ids
    ~
  =/  station-row=tape
    ?~  effective-station
      ~
    ;:  weld
      " INSERT INTO energy-acquisition-stations VALUES ("
      acquisition
      ", "
      (scow %ux u.effective-station)
      ");"
    ==
  =/  additive-rows  (insert-fill-additives acquisition.ids additive-ids)
  =/  subtype-row=tape
    ?~  subtype-id
      ~
    ;:  weld
      " INSERT INTO fuel-fill-subtype VALUES ("
      acquisition
      ", "
      (scow %ux u.subtype-id)
      ");"
    ==
  =/  economy-break-row=tape
    ?.  missed-fill.input
      ~
    ;:  weld
      " INSERT INTO economy-breaks VALUES ("
      acquisition
      ", %missed-fill, "
      recorded
      ");"
    ==
  =/  driving-mode-row=tape
    ?~  driving-mode-id
      ~
    ;:  weld
      " INSERT INTO fuel-fill-driving-mode VALUES ("
      acquisition
      ", "
      (scow %ux u.driving-mode-id)
      ");"
    ==
  =/  average-speed-row=tape
    ?~  average-speed.input
      ~
    ;:  weld
      " INSERT INTO fuel-fill-average-speed VALUES ("
      acquisition
      ", "
      (sql-ud digits.u.average-speed.input)
      ", "
      (sql-ud places.u.average-speed.input)
      ", "
      (sql-term value-unit.u.average-speed.input)
      ");"
    ==
  =/  drive-balance-row=tape
    ?~  drive-balance.input
      ~
    ;:  weld
      " INSERT INTO fuel-fill-drive-balance VALUES ("
      acquisition
      ", "
      (sql-ud u.drive-balance.input)
      ");"
    ==
  =/  new-tag-rows=tape
    ?~  new-tag-label.input
      ~
    ;:  weld
      " INSERT INTO tag-definitions VALUES ("
      (scow %ux tag.ids)
      ", '"
      (sql-quote u.new-tag-label.input)
      "', N, "
      recorded
      "); INSERT INTO fuel-fill-tags VALUES ("
      acquisition
      ", "
      (scow %ux tag.ids)
      ");"
    ==
  =/  tag-rows  (insert-fill-tags acquisition.ids tag-ids)
  =/  notes-row=tape
    ?~  notes.input
      ~
    ;:  weld
      " INSERT INTO fill-notes VALUES ("
      acquisition
      ", '"
      (sql-quote u.notes.input)
      "');"
    ==
  =/  payment-row=tape
    ?~  payment-method-id
      ~
    ;:  weld
      " INSERT INTO fuel-fill-payment-method VALUES ("
      acquisition
      ", "
      (scow %ux u.payment-method-id)
      ");"
    ==
  ;:  weld
    new-station-rows
    acquisition-row
    fill-row
    mileage-rows
    station-row
    additive-rows
    subtype-row
    economy-break-row
    driving-mode-row
    average-speed-row
    drive-balance-row
    new-tag-rows
    tag-rows
    notes-row
    payment-row
  ==
::
++  insert-fill-additives
  |=  [acquisition-id=@ux additive-ids=(list @ux)]
  ^-  tape
  ?~  additive-ids
    ~
  =/  row
    ;:  weld
      " INSERT INTO fuel-fill-additives VALUES ("
      (scow %ux acquisition-id)
      ", "
      (scow %ux i.additive-ids)
      ");"
    ==
  (weld row $(additive-ids t.additive-ids))
::
++  insert-fill-tags
  |=  [acquisition-id=@ux tag-ids=(list @ux)]
  ^-  tape
  ?~  tag-ids
    ~
  =/  row
    ;:  weld
      " INSERT INTO fuel-fill-tags VALUES ("
      (scow %ux acquisition-id)
      ", "
      (scow %ux i.tag-ids)
      ");"
    ==
  (weld row $(tag-ids t.tag-ids))
::
++  insert-odometer
  |=  $:  odometer-id=@ux
          vehicle-id=@ux
          input=odometer-entry:rover
          recorded-at=@da
      ==
  ^-  tape
  =/  observed-start  (scow %da observed-start.input)
  =/  observed-end  (scow %da (add observed-start.input (bex 64)))
  ;:  weld
    "INSERT INTO odometer-observations VALUES ("
    (scow %ux odometer-id)
    ", "
    (scow %ux vehicle-id)
    ", "
    (sql-ud digits.reading.input)
    ", "
    (sql-ud places.reading.input)
    ", "
    (sql-term odo-unit.reading.input)
    ", "
    observed-start
    ", "
    observed-end
    ", %second, '"
    (sql-quote source-zone.input)
    "', "
    (scow %da recorded-at)
    ");"
  ==
::
++  insert-charge-battery
  |=  $:  battery-id=@ux
          acquisition-id=@ux
          vehicle-id=@ux
          endpoint=session-endpoint:rover
          reading=battery-reading:rover
          observed-at=@da
          source-zone=@t
          recorded-at=@da
      ==
  ^-  tape
  ;:  weld
    " INSERT INTO battery-observations VALUES ("
    (scow %ux battery-id)
    ", "
    (scow %ux vehicle-id)
    ", %charge-level, "
    (scow %da observed-at)
    ", "
    (scow %da (add observed-at (bex 64)))
    ", %second, '"
    (sql-quote source-zone)
    "', "
    (scow %da recorded-at)
    "); INSERT INTO battery-observation-percent VALUES ("
    (scow %ux battery-id)
    ", "
    (sql-ud digits.reading)
    ", "
    (sql-ud places.reading)
    "); INSERT INTO charging-session-batteries VALUES ("
    (scow %ux acquisition-id)
    ", "
    (sql-term endpoint)
    ", "
    (scow %ux battery-id)
    ");"
  ==
::
++  insert-charge-components
  |=  $:  component-ids=(list @ux)
          acquisition-id=@ux
          rows=(list charging-component-entry:rover)
      ==
  ^-  tape
  ?~  rows
    ~
  ?~  component-ids
    ~
  =/  row=tape
    ;:  weld
      " INSERT INTO charging-cost-components VALUES ("
      (scow %ux i.component-ids)
      ", "
      (scow %ux acquisition-id)
      ", "
      (sql-term component.i.rows)
      ", "
      (sql-ud quantity.i.rows)
      ", "
      (sql-ud quantity-decimals.i.rows)
      ", "
      (sql-term quantity-unit.i.rows)
      ", "
      (sql-ud rate-mills.i.rows)
      ", "
      (sql-ud amount-mills.i.rows)
      ");"
    ==
  (weld row $(component-ids t.component-ids, rows t.rows))
::
++  insert-charge
  |=  $:  ids=charge-ids
          vehicle-id=@ux
          definition-id=@ux
          subtype-id=(unit @ux)
          input=charge-entry:rover
          recorded-at=@da
      ==
  ^-  tape
  =/  acquisition  (scow %ux acquisition.ids)
  =/  vehicle  (scow %ux vehicle-id)
  =/  recorded  (scow %da recorded-at)
  =/  base=tape
    ;:  weld
      "INSERT INTO energy-acquisitions VALUES ("
      acquisition
      ", "
      vehicle
      ", "
      (scow %ux definition-id)
      ", "
      (scow %da observed-start.input)
      ", "
      (scow %da observed-end.input)
      ", %second, '"
      (sql-quote source-zone.input)
      "', "
      recorded
      "); INSERT INTO charging-sessions VALUES ("
      acquisition
      "); INSERT INTO charging-costs VALUES ("
      acquisition
      ", "
      (sql-term cost-state.input)
      ", "
      (sql-term currency.input)
      ", "
      recorded
      ");"
    ==
  =/  delivered-row=tape
    ?~  delivered.input
      ~
    ;:  weld
      " INSERT INTO charging-energy-measurements VALUES ("
      (scow %ux measurement.ids)
      ", "
      acquisition
      ", "
      (sql-ud digits.u.delivered.input)
      ", "
      (sql-ud places.u.delivered.input)
      ", %kwh, "
      (sql-term point.u.delivered.input)
      ", "
      (sql-term evidence.u.delivered.input)
      ", "
      recorded
      ");"
    ==
  =/  subtype-row=tape
    ?~  subtype-id
      ~
    ;:  weld
      " INSERT INTO charging-session-subtype VALUES ("
      acquisition
      ", "
      (scow %ux u.subtype-id)
      ");"
    ==
  =/  start-row=tape
    ?~  start-battery.input
      ~
    %:  insert-charge-battery
        start-battery.ids
        acquisition.ids
        vehicle-id
        %start
        u.start-battery.input
        observed-start.input
        source-zone.input
        recorded-at
    ==
  =/  end-row=tape
    ?~  end-battery.input
      ~
    %:  insert-charge-battery
        end-battery.ids
        acquisition.ids
        vehicle-id
        %end
        u.end-battery.input
        observed-end.input
        source-zone.input
        recorded-at
    ==
  =/  mileage-row=tape
    ?~  mileage.input
      ~
    =/  odo-input=odometer-entry:rover
      [vehicle-label.input u.mileage.input observed-end.input source-zone.input]
    ;:  weld
      (insert-odometer odometer.ids vehicle-id odo-input recorded-at)
      " INSERT INTO energy-acquisition-odometers VALUES ("
      acquisition
      ", "
      (scow %ux odometer.ids)
      ");"
    ==
  =/  component-rows=tape
    (insert-charge-components components.ids acquisition.ids components.input)
  ::  Absence of this row means no total. A zero row would claim the source
  ::  reported zero, so never write one to stand for a missing total.
  =/  source-total-row=tape
    ?~  source-total-mills.input
      ~
    ;:  weld
      " INSERT INTO charging-cost-source-totals VALUES ("
      acquisition
      ", "
      (sql-ud u.source-total-mills.input)
      ");"
    ==
  ;:  weld
    base
    subtype-row
    delivered-row
    start-row
    end-row
    mileage-row
    component-rows
    source-total-row
  ==
::
++  vector-key
  |=  [key=@tas row=vector:ast]
  ^-  (unit @)
  =/  cells=(list vector-cell:ast)  +.row
  |-
  ?~  cells  ~
  ?:  =(key p.i.cells)
    `q.q.i.cells
  $(cells t.cells)
::
++  order-vectors
  |=  [key=@tas descending=? rows=(list vector:ast)]
  ^-  (list vector:ast)
  %+  sort  rows
  |=  [a=vector:ast b=vector:ast]
  =/  a-key  (vector-key key a)
  =/  b-key  (vector-key key b)
  ?:  ?=(~ a-key)  %.n
  ?:  ?=(~ b-key)  %.y
  ?:  =(u.a-key u.b-key)
    =/  a-recorded  (vector-key %recorded-at a)
    =/  b-recorded  (vector-key %recorded-at b)
    ?:  ?&  ?=(^ a-recorded)
            ?=(^ b-recorded)
            !=(u.a-recorded u.b-recorded)
        ==
      ?:(descending (gth u.a-recorded u.b-recorded) (lth u.a-recorded u.b-recorded))
    =/  a-tie
      =/  acquisition  (vector-key %acquisition-id a)
      ?^  acquisition  u.acquisition
      =/  odometer  (vector-key %odometer-id a)
      ?^  odometer  u.odometer
      (need (vector-key %vehicle-id a))
    =/  b-tie
      =/  acquisition  (vector-key %acquisition-id b)
      ?^  acquisition  u.acquisition
      =/  odometer  (vector-key %odometer-id b)
      ?^  odometer  u.odometer
      (need (vector-key %vehicle-id b))
    ?:(descending (gth a-tie b-tie) (lth a-tie b-tie))
  ?:  descending
    (gth u.a-key u.b-key)
  (lth u.a-key u.b-key)
--
