::  lib/rover-act - Obelisk driver helpers for %rover.
::
/-  ast=obelisk-ast, rover
|%
+$  seed-ids
  $:  reservoir=@ux
      electricity=@ux
      vehicle=@ux
      odometer-before=@ux
      acquisition=@ux
      odometer-at-fill=@ux
  ==
+$  pricing-ids
  $:  usd-definition=@ux
      eur-definition=@ux
      vehicle=@ux
      signature=@ux
      standard=@ux
      cash=@ux
      snapshot=@ux
      eur=@ux
  ==
+$  fuel-evidence-ids
  $:  definition=@ux
      vehicle=@ux
      zero-fill=@ux
      one-fill=@ux
      many-fill=@ux
      odometer=@ux
      additive-a=@ux
      additive-b=@ux
  ==
+$  charging-evidence-ids
  $:  definition=@ux
      vehicle=@ux
      acquisition=@ux
      energy-measurement=@ux
      power-measurement=@ux
      range-measurement=@ux
      percent-observation=@ux
      segments-observation=@ux
      health-observation=@ux
  ==
+$  charging-cost-ids
  $:  definition=@ux
      vehicle=@ux
      free-acquisition=@ux
      unknown-acquisition=@ux
      itemized-acquisition=@ux
      receipt-acquisition=@ux
      energy-component=@ux
      time-component=@ux
      session-component=@ux
      idle-component=@ux
      tax-component=@ux
      discount-component=@ux
  ==
+$  consumption-ids
  $:  definition=@ux
      vehicle=@ux
      wh-mi=@ux
      kwh-100km=@ux
      mi-kwh=@ux
  ==
+$  location-ids
  $:  reservoir-definition=@ux
      electricity-definition=@ux
      vehicle=@ux
      fill-acquisition=@ux
      charge-acquisition=@ux
      private-place=@ux
      private-station=@ux
      public-place=@ux
      mixed-station=@ux
  ==
+$  integrity-ids
  $:  definition=@ux
      vehicle=@ux
      acquisition=@ux
      place=@ux
      station=@ux
  ==
+$  entry-ids
  $:  acquisition=@ux
      odometer=@ux
      place=@ux
      station=@ux
      tag=@ux
  ==
+$  app-structure-ids
  $:  definition=@ux
      subtype-87=@ux
      subtype-91=@ux
      subtype-93=@ux
      vehicle=@ux
      mode=@ux
      other-vehicle=@ux
      tag-a=@ux
      tag-b=@ux
  ==
+$  charge-ids
  $:  acquisition=@ux
      measurement=@ux
      start-battery=@ux
      end-battery=@ux
      odometer=@ux
  ==
+$  fill-edit-support-ids
  [place=@ux station=@ux payment=@ux mode=@ux additive=@ux tag=@ux]
::
++  rover-db  %rover
::
++  fixture-id
  |=  [seed=@ux ordinal=@ud]
  ^-  @ux
  =/  candidate=@ux  (mix seed ordinal)
  ?:  =(0 candidate)
    `@ux`(add ordinal 1)
  candidate
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
  ;:  weld
    (seed-energy-starters base now)
    (seed-consumables base now)
    (seed-additives base now)
    (seed-driving-modes base now)
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
++  demo-fill
  |=  $:  base=@ux
          ordinal=@ud
          vehicle-ordinal=@ud
          definition-id=@ux
          subtype-id=@ux
          station-ordinal=@ud
          payment-ordinal=@ud
          observed=@da
          odometer=@ud
          quantity-milli=@ud
          unit-price-mills=@ud
          missed-fill=?
          now=@da
      ==
  ^-  tape
  =/  acquisition  (scow %ux (fixture-id base ordinal))
  =/  vehicle  (scow %ux (fixture-id base vehicle-ordinal))
  =/  definition  (scow %ux definition-id)
  =/  subtype  (scow %ux subtype-id)
  =/  station  (scow %ux (fixture-id base station-ordinal))
  =/  payment  (scow %ux (fixture-id base payment-ordinal))
  =/  odometer-id  (scow %ux (fixture-id base (add 1.000 ordinal)))
  =/  start  (scow %da observed)
  =/  end  (scow %da (add observed (bex 64)))
  =/  recorded  (scow %da now)
  =/  odo  (scow %ud odometer)
  =/  quantity  (scow %ud quantity-milli)
  =/  price  (scow %ud unit-price-mills)
  ;:  weld
    "INSERT INTO energy-acquisitions VALUES ({acquisition}, {vehicle}, {definition}, {start}, {end}, %second, 'America/Chicago', {recorded}); "
    "INSERT INTO fuel-fills VALUES ({acquisition}, {quantity}, %gal, %full, {price}, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO fuel-fill-subtype VALUES ({acquisition}, {subtype}); "
    "INSERT INTO odometer-observations VALUES ({odometer-id}, {vehicle}, {odo}, 0, %mi, {start}, {end}, %second, 'America/Chicago', {recorded}); "
    "INSERT INTO fuel-fill-odometers VALUES ({acquisition}, {odometer-id}); "
    "INSERT INTO energy-acquisition-stations VALUES ({acquisition}, {station}); "
    "INSERT INTO fuel-fill-payment-method VALUES ({acquisition}, {payment}); "
    ?:  missed-fill
      "INSERT INTO economy-breaks VALUES ({acquisition}, %missed-fill, {recorded}); "
    ~
  ==
::
++  seed-demo-fuel
  |=  $:  base=@ux
          now=@da
          gas-definition-id=@ux
          diesel-definition-id=@ux
          gas-87-id=@ux
          gas-93-id=@ux
          diesel-2-id=@ux
          diesel-b20-id=@ux
      ==
  ^-  tape
  =/  rec  (scow %da now)
  =/  gas-def  (scow %ux gas-definition-id)
  =/  diesel-def  (scow %ux diesel-definition-id)
  =/  gas-vehicle  (scow %ux (fixture-id base 31))
  =/  diesel-vehicle  (scow %ux (fixture-id base 32))
  =/  place-a  (scow %ux (fixture-id base 41))
  =/  station-a  (scow %ux (fixture-id base 42))
  =/  place-b  (scow %ux (fixture-id base 43))
  =/  station-b  (scow %ux (fixture-id base 44))
  =/  cash  (scow %ux (fixture-id base 51))
  =/  card  (scow %ux (fixture-id base 52))
  ;:  weld
    "INSERT INTO vehicles VALUES ({gas-vehicle}, 'Rover Demo Gasoline', N, {rec}); "
    "INSERT INTO vehicles VALUES ({diesel-vehicle}, 'Rover Demo Diesel', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({gas-vehicle}, {gas-def}, N); "
    "INSERT INTO vehicle-energy-definitions VALUES ({diesel-vehicle}, {diesel-def}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({gas-vehicle}, {gas-def}); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({diesel-vehicle}, {diesel-def}); "
    "INSERT INTO vehicle-tank-size VALUES ({gas-vehicle}, 155, 1, %gal); "
    "INSERT INTO vehicle-tank-size VALUES ({diesel-vehicle}, 26, 0, %gal); "
    "INSERT INTO places VALUES ({place-a}, 'Rover Demo North', N, {rec}); "
    "INSERT INTO stations VALUES ({station-a}, {place-a}, 'North Fuel', %fuel, N, {rec}); "
    "INSERT INTO places VALUES ({place-b}, 'Rover Demo South', N, {rec}); "
    "INSERT INTO stations VALUES ({station-b}, {place-b}, 'South Fuel', %fuel, N, {rec}); "
    "INSERT INTO payment-method-definitions VALUES ({cash}, 'Demo Cash', N, {rec}); "
    "INSERT INTO payment-method-definitions VALUES ({card}, 'Demo Fleet Card', N, {rec}); "
    (demo-fill base 101 31 gas-definition-id gas-87-id 42 51 ~2026.7.1..12.00.00 10.000 10.000 3.399 %.n now)
    (demo-fill base 102 31 gas-definition-id gas-93-id 44 52 ~2026.7.2..12.00.00 10.300 10.000 3.499 %.n now)
    (demo-fill base 103 31 gas-definition-id gas-87-id 42 52 ~2026.7.3..12.00.00 10.608 11.000 3.459 %.n now)
    (demo-fill base 104 31 gas-definition-id gas-93-id 44 51 ~2026.7.4..12.00.00 10.908 10.000 3.579 %.y now)
    (demo-fill base 105 31 gas-definition-id gas-87-id 42 52 ~2026.7.5..12.00.00 11.232 12.000 3.429 %.n now)
    (demo-fill base 106 31 gas-definition-id gas-93-id 44 52 ~2026.7.6..12.00.00 11.522 10.000 3.619 %.n now)
    (demo-fill base 201 32 diesel-definition-id diesel-2-id 42 52 ~2026.7.2..13.00.00 50.000 12.000 3.899 %.n now)
    (demo-fill base 202 32 diesel-definition-id diesel-b20-id 44 51 ~2026.7.3..13.00.00 50.400 12.500 3.979 %.n now)
    (demo-fill base 203 32 diesel-definition-id diesel-2-id 42 52 ~2026.7.4..13.00.00 50.810 12.500 4.029 %.n now)
    (demo-fill base 204 32 diesel-definition-id diesel-b20-id 44 52 ~2026.7.5..13.00.00 51.200 12.000 3.949 %.n now)
    (demo-fill base 205 32 diesel-definition-id diesel-2-id 42 51 ~2026.7.6..13.00.00 51.620 14.000 4.099 %.n now)
    (demo-fill base 206 32 diesel-definition-id diesel-b20-id 44 52 ~2026.7.7..13.00.00 52.020 12.500 4.059 %.n now)
  ==
::
++  demo-fuel-check
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = 'Rover Demo Gasoline' OR V.label = 'Rover Demo Diesel' SELECT V.vehicle-id, V.label; "
    "FROM energy-definitions E WHERE E.label = 'Gasoline' AND E.archived = N SELECT E.energy-definition-id; "
    "FROM energy-definitions E WHERE E.label = 'Diesel' AND E.archived = N SELECT E.energy-definition-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Gasoline' AND E.archived = N AND S.label = '87' AND S.archived = N SELECT S.subtype-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Gasoline' AND E.archived = N AND S.label = '93' AND S.archived = N SELECT S.subtype-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Diesel' AND E.archived = N AND S.label = '#2' AND S.archived = N SELECT S.subtype-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Diesel' AND E.archived = N AND S.label = 'B20' AND S.archived = N SELECT S.subtype-id; "
    "FROM vehicles V WHERE V.label = 'Rover Demo Gasoline' SELECT V.vehicle-id; "
    "FROM vehicles V WHERE V.label = 'Rover Demo Diesel' SELECT V.vehicle-id; "
    "FROM energy-definitions E WHERE E.label = 'Demo Gasoline Energy' SELECT E.energy-definition-id; "
    "FROM energy-definitions E WHERE E.label = 'Demo Diesel Energy' SELECT E.energy-definition-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Demo Gasoline Energy' AND S.label = 'Regular 87' SELECT S.subtype-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Demo Gasoline Energy' AND S.label = 'Premium 93' SELECT S.subtype-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Demo Diesel Energy' AND S.label = '#2 Diesel' SELECT S.subtype-id; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id WHERE E.label = 'Demo Diesel Energy' AND S.label = 'B20 Diesel' SELECT S.subtype-id;"
  ==
::
++  repair-demo-fuel
  |=  $:  gas-vehicle-id=@ux
          diesel-vehicle-id=@ux
          gas-definition-id=@ux
          diesel-definition-id=@ux
          gas-87-id=@ux
          gas-93-id=@ux
          diesel-2-id=@ux
          diesel-b20-id=@ux
          old-gas-definition-id=@ux
          old-diesel-definition-id=@ux
          old-gas-87-id=@ux
          old-gas-93-id=@ux
          old-diesel-2-id=@ux
          old-diesel-b20-id=@ux
      ==
  ^-  tape
  ;:  weld
    "INSERT INTO vehicle-energy-definitions VALUES ({(scow %ux gas-vehicle-id)}, {(scow %ux gas-definition-id)}, N); "
    "INSERT INTO vehicle-energy-definitions VALUES ({(scow %ux diesel-vehicle-id)}, {(scow %ux diesel-definition-id)}, N); "
    "UPDATE vehicle-default-energy-definitions SET energy-definition-id = {(scow %ux gas-definition-id)} WHERE vehicle-id = {(scow %ux gas-vehicle-id)}; "
    "UPDATE vehicle-default-energy-definitions SET energy-definition-id = {(scow %ux diesel-definition-id)} WHERE vehicle-id = {(scow %ux diesel-vehicle-id)}; "
    "UPDATE energy-acquisitions SET energy-definition-id = {(scow %ux gas-definition-id)} WHERE vehicle-id = {(scow %ux gas-vehicle-id)}; "
    "UPDATE energy-acquisitions SET energy-definition-id = {(scow %ux diesel-definition-id)} WHERE vehicle-id = {(scow %ux diesel-vehicle-id)}; "
    "UPDATE fuel-fill-subtype SET subtype-id = {(scow %ux gas-87-id)} WHERE subtype-id = {(scow %ux old-gas-87-id)}; "
    "UPDATE fuel-fill-subtype SET subtype-id = {(scow %ux gas-93-id)} WHERE subtype-id = {(scow %ux old-gas-93-id)}; "
    "UPDATE fuel-fill-subtype SET subtype-id = {(scow %ux diesel-2-id)} WHERE subtype-id = {(scow %ux old-diesel-2-id)}; "
    "UPDATE fuel-fill-subtype SET subtype-id = {(scow %ux diesel-b20-id)} WHERE subtype-id = {(scow %ux old-diesel-b20-id)}; "
    "DELETE FROM vehicle-energy-definitions WHERE vehicle-id = {(scow %ux gas-vehicle-id)} AND energy-definition-id = {(scow %ux old-gas-definition-id)}; "
    "DELETE FROM vehicle-energy-definitions WHERE vehicle-id = {(scow %ux diesel-vehicle-id)} AND energy-definition-id = {(scow %ux old-diesel-definition-id)}; "
    "DELETE FROM energy-definition-subtypes WHERE energy-definition-id = {(scow %ux old-gas-definition-id)}; "
    "DELETE FROM energy-definition-subtypes WHERE energy-definition-id = {(scow %ux old-diesel-definition-id)}; "
    "DELETE FROM energy-definitions WHERE energy-definition-id = {(scow %ux old-gas-definition-id)}; "
    "DELETE FROM energy-definitions WHERE energy-definition-id = {(scow %ux old-diesel-definition-id)};"
  ==
::
++  demo-def-check
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = 'Rover Demo Diesel' SELECT V.vehicle-id; "
    "FROM consumable-definitions C WHERE C.label = 'DEF' SELECT C.consumable-id; "
    "FROM vehicles V JOIN consumable-acquisitions A ON V.vehicle-id = A.vehicle-id WHERE V.label = 'Rover Demo Diesel' SELECT A.consumable-acquisition-id;"
  ==
::
++  demo-starter-report
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Rover Demo Gasoline' OR V.label = 'Rover Demo Diesel' SELECT V.label AS vehicle, A.energy-definition-id AS demo-energy-definition-id, E.energy-definition-id AS starter-energy-definition-id, E.label AS starter-energy; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = 'Rover Demo Gasoline' OR V.label = 'Rover Demo Diesel' SELECT V.label AS vehicle, A.energy-definition-id AS demo-energy-definition-id, S.energy-definition-id AS subtype-parent-definition-id, L.subtype-id AS demo-subtype-id, S.subtype-id AS starter-subtype-id, S.label AS starter-subtype;"
  ==
::
++  demo-def-purchase
  |=  $:  base=@ux
          ordinal=@ud
          vehicle-id=@ux
          consumable-id=@ux
          observed=@da
          odometer=@ud
          quantity-milli=@ud
          now=@da
      ==
  ^-  tape
  =/  acquisition  (scow %ux (fixture-id base ordinal))
  =/  odometer-id  (scow %ux (fixture-id base (add 100 ordinal)))
  =/  vehicle  (scow %ux vehicle-id)
  =/  consumable  (scow %ux consumable-id)
  =/  start  (scow %da observed)
  =/  end  (scow %da (add observed (bex 64)))
  =/  rec  (scow %da now)
  =/  odo  (scow %ud odometer)
  =/  quantity  (scow %ud quantity-milli)
  ;:  weld
    "INSERT INTO consumable-acquisitions VALUES ({acquisition}, {vehicle}, {consumable}, {start}, {end}, %second, 'America/Chicago', {rec}); "
    "INSERT INTO consumable-purchases VALUES ({acquisition}, {quantity}, %gal, 4299, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO odometer-observations VALUES ({odometer-id}, {vehicle}, {odo}, 0, %mi, {start}, {end}, %second, 'America/Chicago', {rec}); "
    "INSERT INTO consumable-acquisition-odometers VALUES ({acquisition}, {odometer-id}); "
  ==
::
++  seed-demo-def
  |=  [base=@ux vehicle-id=@ux consumable-id=@ux now=@da]
  ^-  tape
  =/  vehicle  (scow %ux vehicle-id)
  =/  consumable  (scow %ux consumable-id)
  ;:  weld
    "INSERT INTO vehicle-consumables VALUES ({vehicle}, {consumable}, N); "
    "INSERT INTO vehicle-consumable-tank-size VALUES ({vehicle}, {consumable}, 5, 0, %gal); "
    (demo-def-purchase base 1 vehicle-id consumable-id ~2026.7.10..14.00.00 50.200 1.000 now)
    (demo-def-purchase base 2 vehicle-id consumable-id ~2026.7.24..14.00.00 51.200 2.000 now)
    (demo-def-purchase base 3 vehicle-id consumable-id ~2026.7.29..14.00.00 52.200 2.000 now)
  ==
::
++  starter-check
  ^-  tape
  ;:  weld
    "FROM energy-definitions E SELECT E.energy-definition-id, E.label, E.archived; "
    "FROM consumable-definitions C SELECT C.consumable-id, C.label, C.archived; "
    "FROM additive-definitions A SELECT A.additive-id, A.label, A.archived; "
    "FROM driving-mode-definitions D SELECT D.mode-id, D.label, D.archived;"
  ==
::
++  starter-report
  ^-  tape
  ;:  weld
    "FROM energy-definitions E WHERE E.archived = N SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id SELECT E.label AS energy, S.label AS subtype, S.archived; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-octane O ON S.subtype-id = O.subtype-id SELECT E.label AS energy, S.label AS subtype, O.rating, O.method; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-blend B ON S.subtype-id = B.subtype-id SELECT E.label AS energy, S.label AS subtype, B.blend-kind, B.percent-digits, B.percent-decimals;"
  ==
::
++  consumable-starter-report
  ^-  tape
  "FROM consumable-definitions C WHERE C.archived = N SELECT C.consumable-id, C.label, C.quantity-unit, C.archived;"
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
++  consumable-report
  |=  [vehicle-label=@t consumable-label=@t observed-start=@da]
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN consumable-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN consumable-definitions D ON A.consumable-id = D.consumable-id JOIN consumable-purchases P ON A.consumable-acquisition-id = P.consumable-acquisition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND D.label = '"
    (sql-quote consumable-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT V.label AS vehicle, D.label AS consumable, P.quantity-milli, P.quantity-unit, P.unit-price-mills, P.currency, P.settlement-mode, P.price-profile, P.minor-unit-decimals, P.cash-increment-mills; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' SELECT A.acquisition-id AS fuel-acquisition;"
  ==
::
++  charge-subtype-report
  |=  [vehicle-label=@t observed-start=@da]
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN charging-session-subtype L ON C.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT V.label AS vehicle, S.label AS charging-subtype;"
  ==
::
++  fill-edit-support-lookup
  |=  label=@t
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote label)
    "' SELECT V.vehicle-id;"
  ==
::
++  seed-fill-edit-support
  |=  [ids=fill-edit-support-ids vehicle-id=@ux now=@da]
  ^-  tape
  ;:  weld
    "INSERT INTO places VALUES ("
    (scow %ux place.ids)
    ", 'Edit Station Place', N, "
    (scow %da now)
    "); INSERT INTO stations VALUES ("
    (scow %ux station.ids)
    ", "
    (scow %ux place.ids)
    ", 'Edit Station', %fuel, N, "
    (scow %da now)
    "); INSERT INTO payment-method-definitions VALUES ("
    (scow %ux payment.ids)
    ", 'Personal Visa', N, "
    (scow %da now)
    "); INSERT INTO driving-mode-definitions VALUES ("
    (scow %ux mode.ids)
    ", 'Mixed Driving', N, "
    (scow %da now)
    "); INSERT INTO vehicle-driving-modes VALUES ("
    (scow %ux vehicle-id)
    ", "
    (scow %ux mode.ids)
    ", N); INSERT INTO additive-definitions VALUES ("
    (scow %ux additive.ids)
    ", 'Octane Booster', N, "
    (scow %da now)
    "); INSERT INTO tag-definitions VALUES ("
    (scow %ux tag.ids)
    ", 'Road Trip', N, "
    (scow %da now)
    ");"
  ==
::
++  fill-edit-report
  |=  [vehicle-label=@t observed-start=@da]
  ^-  tape
  =/  prefix=tape
    ;:  weld
      "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id "
      "WHERE V.label = '"
      (sql-quote vehicle-label)
      "' AND A.observed-start = "
      (scow %da observed-start)
    ==
  ;:  weld
    prefix
    " SELECT V.label AS vehicle, A.acquisition-id, A.observed-start, A.source-zone, F.quantity-milli, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT S.label AS subtype; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-acquisition-stations L ON A.acquisition-id = L.acquisition-id JOIN stations S ON L.station-id = S.station-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT S.label AS station; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-driving-mode L ON A.acquisition-id = L.acquisition-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT D.label AS driving-mode; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-average-speed S ON A.acquisition-id = S.acquisition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT S.digits, S.decimals, S.speed-unit; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-drive-balance B ON A.acquisition-id = B.acquisition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT B.highway-percent; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fill-notes X ON A.acquisition-id = X.acquisition-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT X.note; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-payment-method L ON A.acquisition-id = L.acquisition-id JOIN payment-method-definitions P ON L.method-id = P.method-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT P.label AS payment-method; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-additives L ON A.acquisition-id = L.acquisition-id JOIN additive-definitions D ON L.additive-id = D.additive-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT D.label AS additive; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-tags L ON A.acquisition-id = L.acquisition-id JOIN tag-definitions T ON L.tag-id = T.tag-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT T.label AS tag; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-odometers L ON A.acquisition-id = L.acquisition-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE V.label = '"
    (sql-quote vehicle-label)
    "' AND A.observed-start = "
    (scow %da observed-start)
    " SELECT O.odometer-id, O.value-digits, O.decimal-places, O.unit;"
  ==
::
++  station-report
  |=  station-label=@t
  ^-  tape
  =/  quoted  (sql-quote station-label)
  ;:  weld
    "FROM stations S JOIN places P ON S.place-id = P.place-id WHERE S.label = '"
    quoted
    "' SELECT S.label AS station, P.label AS place, S.station-kind; "
    "FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-addresses A ON P.place-id = A.place-id WHERE S.label = '"
    quoted
    "' SELECT A.source; "
    "FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-address-formatted F ON P.place-id = F.place-id WHERE S.label = '"
    quoted
    "' SELECT F.formatted; "
    "FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-address-parts A ON P.place-id = A.place-id WHERE S.label = '"
    quoted
    "' SELECT A.part, A.value; "
    "FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-coordinates C ON P.place-id = C.place-id WHERE S.label = '"
    quoted
    "' SELECT C.latitude-scaled, C.longitude-scaled, C.coord-scale, C.source;"
  ==
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
++  format-mills
  |=  [prefix=@t mills=@ud]
  ^-  @t
  =/  major  (div mills 1.000)
  =/  fraction  (mod mills 1.000)
  =/  fraction-text=tape  (scow %ud fraction)
  =/  padded=tape
    ?:  (lth fraction 10)
      (weld "00" fraction-text)
    ?:  (lth fraction 100)
      (weld "0" fraction-text)
    fraction-text
  (crip (weld (trip prefix) (weld (scow %ud major) (weld "." padded))))
::
++  preview-us
  |=  entered-cents=@ud
  ^-  price-preview:rover
  =/  mills  (add (mul entered-cents 10) 9)
  [%usd %us-usd-gal entered-cents 2 mills (format-mills '$' mills)]
::
++  preview-eur
  |=  entered-mills=@ud
  ^-  price-preview:rover
  :*  %eur
      %eu-eur-litre
      entered-mills
      3
      entered-mills
      (format-mills 'EUR ' entered-mills)
  ==
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
++  integrity-op
  |=  scenario=integrity-kind:rover
  ^-  @t
  ?-  scenario
    %missing-pair       'integrity-missing-pair'
    %bad-default        'integrity-bad-default'
    %delete-vehicle     'integrity-delete-vehicle'
    %delete-definition  'integrity-delete-definition'
    %delete-place       'integrity-delete-place'
    %delete-station     'integrity-delete-station'
    %zero-subtype       'integrity-zero-subtype'
    %two-subtypes       'integrity-two-subtypes'
  ==
::
++  integrity-scenario
  |=  op=@t
  ^-  (unit integrity-kind:rover)
  ?:  =('integrity-missing-pair' op)       `%missing-pair
  ?:  =('integrity-bad-default' op)        `%bad-default
  ?:  =('integrity-delete-vehicle' op)     `%delete-vehicle
  ?:  =('integrity-delete-definition' op)  `%delete-definition
  ?:  =('integrity-delete-place' op)       `%delete-place
  ?:  =('integrity-delete-station' op)     `%delete-station
  ?:  =('integrity-zero-subtype' op)       `%zero-subtype
  ?:  =('integrity-two-subtypes' op)       `%two-subtypes
  ~
::
++  integrity-message
  |=  scenario=integrity-kind:rover
  ^-  @t
  ?-  scenario
    %missing-pair       'rejected acquisition: vehicle and energy definition are not allowed'
    %bad-default        'rejected default: energy definition is not an allowed vehicle link'
    %delete-vehicle     'rejected deletion: vehicle is referenced'
    %delete-definition  'rejected deletion: energy definition is referenced'
    %delete-place       'rejected deletion: place is referenced'
    %delete-station     'rejected deletion: station is referenced'
    %zero-subtype       'rejected acquisition before mutation: zero subtypes'
    %two-subtypes       'rejected acquisition before mutation: two subtypes'
  ==
::
++  integrity-script
  |=  [scenario=integrity-kind:rover ids=integrity-ids now=@da]
  ^-  tape
  =/  def-id  (scow %ux definition.ids)
  =/  veh-id  (scow %ux vehicle.ids)
  =/  acq-id  (scow %ux acquisition.ids)
  =/  plc-id  (scow %ux place.ids)
  =/  sta-id  (scow %ux station.ids)
  =/  rec     (scow %da now)
  ?-  scenario
    %missing-pair
      ;:  weld
        "INSERT INTO energy-definitions VALUES ({def-id}, 'Integrity Missing Pair Energy', %reservoir, %gal, N, {rec}); "
        "INSERT INTO vehicles VALUES ({veh-id}, 'Integrity Missing Pair Vehicle', N, {rec}); "
        "INSERT INTO energy-acquisitions VALUES ({acq-id}, {veh-id}, {def-id}, ~2026.7.28..19.00.00, ~2026.7.28..19.00.01, %second, 'America/Chicago', {rec});"
      ==
    %bad-default
      ;:  weld
        "INSERT INTO energy-definitions VALUES ({def-id}, 'Integrity Bad Default Energy', %reservoir, %gal, N, {rec}); "
        "INSERT INTO vehicles VALUES ({veh-id}, 'Integrity Bad Default Vehicle', N, {rec}); "
        "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {def-id});"
      ==
    %delete-vehicle
      ;:  weld
        "INSERT INTO energy-definitions VALUES ({def-id}, 'Integrity Vehicle Energy', %reservoir, %gal, N, {rec}); "
        "INSERT INTO vehicles VALUES ({veh-id}, 'Integrity Referenced Vehicle', N, {rec}); "
        "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {def-id}, N); "
        "DELETE FROM vehicles WHERE vehicle-id = {veh-id};"
      ==
    %delete-definition
      ;:  weld
        "INSERT INTO energy-definitions VALUES ({def-id}, 'Integrity Referenced Energy', %reservoir, %gal, N, {rec}); "
        "INSERT INTO vehicles VALUES ({veh-id}, 'Integrity Definition Vehicle', N, {rec}); "
        "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {def-id}, N); "
        "DELETE FROM energy-definitions WHERE energy-definition-id = {def-id};"
      ==
    %delete-place
      ;:  weld
        "INSERT INTO places VALUES ({plc-id}, 'Integrity Referenced Place', N, {rec}); "
        "INSERT INTO stations VALUES ({sta-id}, {plc-id}, 'Integrity Place Station', %mixed, N, {rec}); "
        "DELETE FROM places WHERE place-id = {plc-id};"
      ==
    %delete-station
      ;:  weld
        "INSERT INTO energy-definitions VALUES ({def-id}, 'Integrity Station Energy', %reservoir, %gal, N, {rec}); "
        "INSERT INTO vehicles VALUES ({veh-id}, 'Integrity Station Vehicle', N, {rec}); "
        "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {def-id}, N); "
        "INSERT INTO energy-acquisitions VALUES ({acq-id}, {veh-id}, {def-id}, ~2026.7.28..19.01.00, ~2026.7.28..19.01.01, %second, 'America/Chicago', {rec}); "
        "INSERT INTO fuel-fills VALUES ({acq-id}, 1000, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
        "INSERT INTO places VALUES ({plc-id}, 'Integrity Station Place', N, {rec}); "
        "INSERT INTO stations VALUES ({sta-id}, {plc-id}, 'Integrity Referenced Station', %mixed, N, {rec}); "
        "INSERT INTO energy-acquisition-stations VALUES ({acq-id}, {sta-id}); "
        "DELETE FROM stations WHERE station-id = {sta-id};"
      ==
    %zero-subtype  !!
    %two-subtypes   !!
  ==
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
    "CREATE TABLE rover..fuel-fill-odometers (acquisition-id @ux, odometer-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (odometer-id) REFERENCES odometer-observations (odometer-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
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
    "CREATE TABLE rover..vehicle-consumables (vehicle-id @ux, consumable-id @ux, archived @f) PRIMARY KEY (vehicle-id, consumable-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (consumable-id) REFERENCES consumable-definitions (consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-consumable-tank-size (vehicle-id @ux, consumable-id @ux, digits @ud, decimals @ud, unit @tas) PRIMARY KEY (vehicle-id, consumable-id) FOREIGN KEY (vehicle-id, consumable-id) REFERENCES vehicle-consumables (vehicle-id, consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-acquisitions (consumable-acquisition-id @ux, vehicle-id @ux, consumable-id @ux, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (consumable-id) REFERENCES consumable-definitions (consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-purchases (consumable-acquisition-id @ux, quantity-milli @ud, quantity-unit @tas, unit-price-mills @ud, currency @tas, settlement-mode @tas, price-profile @tas, minor-unit-decimals @ud, cash-increment-mills @ud) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (consumable-acquisition-id) REFERENCES consumable-acquisitions (consumable-acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-acquisition-stations (consumable-acquisition-id @ux, station-id @ux) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (consumable-acquisition-id) REFERENCES consumable-acquisitions (consumable-acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..consumable-acquisition-odometers (consumable-acquisition-id @ux, odometer-id @ux) PRIMARY KEY (consumable-acquisition-id) FOREIGN KEY (consumable-acquisition-id) REFERENCES consumable-acquisitions (consumable-acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (odometer-id) REFERENCES odometer-observations (odometer-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
  ==
::
++  display-preference-schema
  ^-  tape
  "CREATE TABLE rover..vehicle-display-preferences (vehicle-id @ux, distance-unit @tas, currency @tas, recorded-at @da) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
::
++  def-schema
  ^-  tape
  ;:  weld
    "CREATE TABLE rover..vehicle-consumables (vehicle-id @ux, consumable-id @ux, archived @f) PRIMARY KEY (vehicle-id, consumable-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (consumable-id) REFERENCES consumable-definitions (consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-consumable-tank-size (vehicle-id @ux, consumable-id @ux, digits @ud, decimals @ud, unit @tas) PRIMARY KEY (vehicle-id, consumable-id) FOREIGN KEY (vehicle-id, consumable-id) REFERENCES vehicle-consumables (vehicle-id, consumable-id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
  ==
::
++  display-preference-report
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, O.value-digits, O.decimal-places, O.unit;"
    " FROM vehicles V JOIN vehicle-display-preferences P ON V.vehicle-id = P.vehicle-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, P.distance-unit, P.currency;"
  ==
::
++  seed-spike
  |=  [ids=seed-ids now=@da]
  ^-  tape
  =/  res-id  (scow %ux reservoir.ids)
  =/  ele-id  (scow %ux electricity.ids)
  =/  veh-id  (scow %ux vehicle.ids)
  =/  odo-a    (scow %ux odometer-before.ids)
  =/  acq-id   (scow %ux acquisition.ids)
  =/  odo-b    (scow %ux odometer-at-fill.ids)
  =/  rec      (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({res-id}, 'Regular 87', %reservoir, %gal, Y, {rec}); "
    "INSERT INTO energy-definitions VALUES ({ele-id}, 'Electricity', %electricity, %kwh, Y, {rec}); "
    "INSERT INTO vehicles VALUES ({veh-id}, 'Phase A Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {res-id}, N); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {ele-id}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {res-id}); "
    "INSERT INTO odometer-observations VALUES ({odo-a}, {veh-id}, 100000, 1, %mi, ~2026.7.27..12.00.00, ~2026.7.27..12.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO energy-acquisitions VALUES ({acq-id}, {veh-id}, {res-id}, ~2026.7.28..12.00.00, ~2026.7.28..12.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({acq-id}, 12345, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO odometer-observations VALUES ({odo-b}, {veh-id}, 100125, 1, %mi, ~2026.7.28..12.00.00, ~2026.7.28..12.00.01, %second, 'America/Chicago', {rec});"
  ==
::
++  seed-pricing
  |=  [ids=pricing-ids now=@da]
  ^-  tape
  =/  usd-id  (scow %ux usd-definition.ids)
  =/  eur-id  (scow %ux eur-definition.ids)
  =/  veh-id  (scow %ux vehicle.ids)
  =/  sig-id  (scow %ux signature.ids)
  =/  std-id  (scow %ux standard.ids)
  =/  csh-id  (scow %ux cash.ids)
  =/  snp-id  (scow %ux snapshot.ids)
  =/  eur-acq  (scow %ux eur.ids)
  =/  rec      (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({usd-id}, 'Pricing US gallon', %reservoir, %gal, Y, {rec}); "
    "INSERT INTO energy-definitions VALUES ({eur-id}, 'Pricing EUR litre', %reservoir, %litre, Y, {rec}); "
    "INSERT INTO vehicles VALUES ({veh-id}, 'Pricing Fixture Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {usd-id}, N); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {eur-id}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {usd-id}); "
    "INSERT INTO energy-acquisitions VALUES ({sig-id}, {veh-id}, {usd-id}, ~2026.7.28..13.00.00, ~2026.7.28..13.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({sig-id}, 12345, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO energy-acquisitions VALUES ({std-id}, {veh-id}, {usd-id}, ~2026.7.28..13.01.00, ~2026.7.28..13.01.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({std-id}, 12344, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO energy-acquisitions VALUES ({csh-id}, {veh-id}, {usd-id}, ~2026.7.28..13.02.00, ~2026.7.28..13.02.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({csh-id}, 12344, %gal, %full, 3499, %usd, %cash, %us-usd-gal, 2, 50); "
    "INSERT INTO energy-acquisitions VALUES ({snp-id}, {veh-id}, {usd-id}, ~2026.7.28..13.03.00, ~2026.7.28..13.03.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({snp-id}, 12344, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 3, 0); "
    "INSERT INTO energy-acquisitions VALUES ({eur-acq}, {veh-id}, {eur-id}, ~2026.7.28..13.04.00, ~2026.7.28..13.04.01, %second, 'Europe/Paris', {rec}); "
    "INSERT INTO fuel-fills VALUES ({eur-acq}, 1000, %litre, %full, 1749, %eur, %standard, %eu-eur-litre, 2, 0);"
  ==
::
++  pricing-report
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Pricing Fixture Vehicle' SELECT V.label AS vehicle, E.label AS energy, F.quantity-milli, F.quantity-unit, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills, A.observed-start; "
    "FROM sys.columns WHERE namespace = %dbo AND name = %fuel-fills SELECT col-name;"
  ==
::
++  seed-fuel-evidence
  |=  [ids=fuel-evidence-ids now=@da]
  ^-  tape
  =/  def-id   (scow %ux definition.ids)
  =/  sub-id   (scow %ux (fixture-id definition.ids 39))
  =/  veh-id   (scow %ux vehicle.ids)
  =/  zero-id  (scow %ux zero-fill.ids)
  =/  one-id   (scow %ux one-fill.ids)
  =/  many-id  (scow %ux many-fill.ids)
  =/  odo-id   (scow %ux odometer.ids)
  =/  add-a    (scow %ux additive-a.ids)
  =/  add-b    (scow %ux additive-b.ids)
  =/  rec      (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Gasoline', %reservoir, %gal, Y, {rec}); "
    "INSERT INTO energy-definition-subtypes VALUES ({sub-id}, {def-id}, 'Regular 87 E10', N, {rec}); "
    "INSERT INTO energy-subtype-octane VALUES ({sub-id}, 87, %aki); "
    "INSERT INTO energy-subtype-blend VALUES ({sub-id}, %ethanol, 100, 1); "
    "INSERT INTO vehicles VALUES ({veh-id}, 'Fuel Evidence Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {def-id}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {def-id}); "
    "INSERT INTO vehicle-default-energy-subtype VALUES ({veh-id}, {sub-id}, {rec}); "
    "INSERT INTO additive-definitions VALUES ({add-a}, 'Injector cleaner', N, {rec}); "
    "INSERT INTO additive-definitions VALUES ({add-b}, 'Fuel stabilizer', N, {rec}); "
    "INSERT INTO energy-acquisitions VALUES ({zero-id}, {veh-id}, {def-id}, ~2026.7.28..14.00.00, ~2026.7.28..14.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({zero-id}, 1000, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO fuel-fill-subtype VALUES ({zero-id}, {sub-id}); "
    "INSERT INTO odometer-observations VALUES ({odo-id}, {veh-id}, 200000, 1, %mi, ~2026.7.28..14.00.00, ~2026.7.28..14.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fill-odometers VALUES ({zero-id}, {odo-id}); "
    "INSERT INTO energy-acquisitions VALUES ({one-id}, {veh-id}, {def-id}, ~2026.7.28..14.01.00, ~2026.7.28..14.01.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({one-id}, 1000, %gal, %partial, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO fuel-fill-subtype VALUES ({one-id}, {sub-id}); "
    "INSERT INTO fuel-fill-additives VALUES ({one-id}, {add-a}); "
    "INSERT INTO energy-acquisitions VALUES ({many-id}, {veh-id}, {def-id}, ~2026.7.28..14.02.00, ~2026.7.28..14.02.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({many-id}, 1000, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO fuel-fill-subtype VALUES ({many-id}, {sub-id}); "
    "INSERT INTO fuel-fill-additives VALUES ({many-id}, {add-a}); "
    "INSERT INTO fuel-fill-additives VALUES ({many-id}, {add-b}); "
    "INSERT INTO economy-breaks VALUES ({many-id}, %missed-fill, {rec});"
  ==
::
++  fuel-evidence-report
  ^-  tape
  ;:  weld
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-octane O ON S.subtype-id = O.subtype-id WHERE S.label = 'Regular 87 E10' SELECT E.label AS energy, S.label AS subtype, O.rating, O.method; "
    "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-blend B ON S.subtype-id = B.subtype-id WHERE S.label = 'Regular 87 E10' SELECT E.label AS energy, S.label AS subtype, B.blend-kind, B.percent-digits, B.percent-decimals; "
    "FROM vehicles V JOIN vehicle-default-energy-subtype D ON V.vehicle-id = D.vehicle-id JOIN energy-definition-subtypes S ON D.subtype-id = S.subtype-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, S.label AS default-subtype; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, A.observed-start, S.label AS subtype; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, A.observed-start, F.quantity-milli, F.quantity-unit, F.unit-price-mills, F.currency, F.settlement-mode; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-additives L ON A.acquisition-id = L.acquisition-id JOIN additive-definitions D ON L.additive-id = D.additive-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, A.observed-start, D.label AS additive; "
    "FROM additive-definitions D WHERE D.label = 'Injector cleaner' OR D.label = 'Fuel stabilizer' SELECT D.label AS additive, D.archived; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-odometers L ON A.acquisition-id = L.acquisition-id JOIN odometer-observations O ON L.odometer-id = O.odometer-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, A.observed-start, O.value-digits, O.decimal-places, O.unit; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN economy-breaks B ON A.acquisition-id = B.acquisition-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, A.observed-start, B.reason;"
  ==
::
++  seed-app-structure
  |=  [ids=app-structure-ids now=@da]
  ^-  tape
  =/  def  (scow %ux definition.ids)
  =/  sub87  (scow %ux subtype-87.ids)
  =/  sub91  (scow %ux subtype-91.ids)
  =/  sub93  (scow %ux subtype-93.ids)
  =/  vehicle  (scow %ux vehicle.ids)
  =/  mode  (scow %ux mode.ids)
  =/  other  (scow %ux other-vehicle.ids)
  =/  tag-a  (scow %ux tag-a.ids)
  =/  tag-b  (scow %ux tag-b.ids)
  =/  rec  (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({def}, 'Structure Gasoline', %reservoir, %gal, Y, {rec}); "
    "INSERT INTO energy-definition-subtypes VALUES ({sub87}, {def}, 'Structure 87 AKI', N, {rec}); "
    "INSERT INTO energy-definition-subtypes VALUES ({sub91}, {def}, 'Structure 91 AKI', N, {rec}); "
    "INSERT INTO energy-definition-subtypes VALUES ({sub93}, {def}, 'Structure 93 AKI', N, {rec}); "
    "INSERT INTO energy-subtype-octane VALUES ({sub87}, 87, %aki); "
    "INSERT INTO energy-subtype-octane VALUES ({sub91}, 91, %aki); "
    "INSERT INTO energy-subtype-octane VALUES ({sub93}, 93, %aki); "
    "INSERT INTO vehicles VALUES ({vehicle}, 'Structure Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({vehicle}, {def}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({vehicle}, {def}); "
    "INSERT INTO vehicle-default-energy-subtype VALUES ({vehicle}, {sub91}, {rec}); "
    "INSERT INTO vehicles VALUES ({other}, 'Mode Scope Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({other}, {def}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({other}, {def}); "
    "INSERT INTO driving-mode-definitions VALUES ({mode}, 'Tow / Haul', N, {rec}); "
    "INSERT INTO vehicle-driving-modes VALUES ({vehicle}, {mode}, N); "
    "INSERT INTO tag-definitions VALUES ({tag-a}, 'Road trip', N, {rec}); "
    "INSERT INTO tag-definitions VALUES ({tag-b}, 'Winter', N, {rec});"
  ==
::
++  app-structure-report
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id JOIN energy-subtype-octane O ON S.subtype-id = O.subtype-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, S.label AS subtype, O.rating, O.method; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN economy-breaks B ON A.acquisition-id = B.acquisition-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, B.reason; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-driving-mode L ON A.acquisition-id = L.acquisition-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, D.label AS driving-mode; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-average-speed S ON A.acquisition-id = S.acquisition-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, S.digits, S.decimals, S.speed-unit; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-drive-balance B ON A.acquisition-id = B.acquisition-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, B.highway-percent; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-tags L ON A.acquisition-id = L.acquisition-id JOIN tag-definitions T ON L.tag-id = T.tag-id WHERE V.label = 'Structure Vehicle' SELECT A.observed-start, T.label AS tag;"
    " FROM app-default-vehicle A JOIN vehicles V ON A.vehicle-id = V.vehicle-id SELECT A.scope, V.label AS default-vehicle;"
    " FROM custom-field-definitions C JOIN custom-field-values-number V ON C.field-id = V.field-id SELECT C.label AS custom-field, V.digits, V.decimals, V.value-unit;"
    " FROM custom-field-definitions C JOIN custom-field-values-text V ON C.field-id = V.field-id SELECT C.label AS custom-field, V.value;"
    " FROM custom-field-definitions C JOIN custom-field-values-boolean V ON C.field-id = V.field-id SELECT C.label AS custom-field, V.value;"
  ==
::
++  second-app-default
  |=  now=@da
  ^-  tape
  ;:  weld
    "INSERT INTO app-default-vehicle VALUES (%app, 0x1, "
    (scow %da now)
    ");"
  ==
::
++  seed-charging-evidence
  |=  [ids=charging-evidence-ids now=@da]
  ^-  tape
  =/  def-id   (scow %ux definition.ids)
  =/  veh-id   (scow %ux vehicle.ids)
  =/  acq-id   (scow %ux acquisition.ids)
  =/  nrg-id   (scow %ux energy-measurement.ids)
  =/  pwr-id   (scow %ux power-measurement.ids)
  =/  rng-id   (scow %ux range-measurement.ids)
  =/  pct-id   (scow %ux percent-observation.ids)
  =/  seg-id   (scow %ux segments-observation.ids)
  =/  hea-id   (scow %ux health-observation.ids)
  =/  rec      (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Fixture Electricity', %electricity, %kwh, Y, {rec}); "
    "INSERT INTO vehicles VALUES ({veh-id}, 'Charging Evidence Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {def-id}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {def-id}); "
    "INSERT INTO energy-acquisitions VALUES ({acq-id}, {veh-id}, {def-id}, ~2026.7.28..15.00.00, ~2026.7.28..15.30.00, %minute, 'America/Chicago', {rec}); "
    "INSERT INTO charging-sessions VALUES ({acq-id}); "
    "INSERT INTO charging-energy-measurements VALUES ({nrg-id}, {acq-id}, 45678, 3, %kwh, %charger, %reported, {rec}); "
    "INSERT INTO charging-energy-measurements VALUES ({pwr-id}, {acq-id}, 72, 1, %kw, %charger, %measured, {rec}); "
    "INSERT INTO charging-energy-measurements VALUES ({rng-id}, {acq-id}, 50, 0, %mi, %estimate, %estimated, {rec}); "
    "INSERT INTO battery-observations VALUES ({pct-id}, {veh-id}, %charge-level, ~2026.7.28..15.00.00, ~2026.7.28..15.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO battery-observation-percent VALUES ({pct-id}, 805, 1); "
    "INSERT INTO battery-observations VALUES ({seg-id}, {veh-id}, %charge-level, ~2026.7.28..15.30.00, ~2026.7.28..15.30.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO battery-observation-segments VALUES ({seg-id}, 9, 12); "
    "INSERT INTO battery-observations VALUES ({hea-id}, {veh-id}, %health, ~2026.7.28..15.31.00, ~2026.7.28..15.31.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO battery-observation-percent VALUES ({hea-id}, 950, 1); "
    "INSERT INTO charging-session-batteries VALUES ({acq-id}, %start, {pct-id}); "
    "INSERT INTO charging-session-batteries VALUES ({acq-id}, %end, {seg-id}); "
    "INSERT INTO charging-efficiency-breaks VALUES ({acq-id}, %owner-marked, {rec});"
  ==
::
++  charging-evidence-report
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-energy-measurements M ON A.acquisition-id = M.acquisition-id WHERE V.label = 'Charging Evidence Vehicle' SELECT V.label AS vehicle, M.quantity, M.decimals, M.measure-unit, M.point, M.evidence; "
    "FROM vehicles V JOIN battery-observations B ON V.vehicle-id = B.vehicle-id WHERE V.label = 'Charging Evidence Vehicle' SELECT V.label AS vehicle, B.measure, B.observed-start; "
    "FROM vehicles V JOIN battery-observations B ON V.vehicle-id = B.vehicle-id JOIN battery-observation-percent P ON B.battery-observation-id = P.battery-observation-id WHERE V.label = 'Charging Evidence Vehicle' SELECT V.label AS vehicle, B.measure, P.value-digits, P.value-decimals; "
    "FROM vehicles V JOIN battery-observations B ON V.vehicle-id = B.vehicle-id JOIN battery-observation-segments S ON B.battery-observation-id = S.battery-observation-id WHERE V.label = 'Charging Evidence Vehicle' SELECT V.label AS vehicle, B.measure, S.filled, S.total; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-session-batteries L ON A.acquisition-id = L.acquisition-id JOIN battery-observations B ON L.battery-observation-id = B.battery-observation-id WHERE V.label = 'Charging Evidence Vehicle' SELECT V.label AS vehicle, L.endpoint, B.measure, B.observed-start; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-efficiency-breaks B ON A.acquisition-id = B.acquisition-id WHERE V.label = 'Charging Evidence Vehicle' SELECT V.label AS vehicle, B.reason;"
  ==
::
++  seed-charging-cost
  |=  [ids=charging-cost-ids now=@da]
  ^-  tape
  =/  def-id   (scow %ux definition.ids)
  =/  veh-id   (scow %ux vehicle.ids)
  =/  free-id  (scow %ux free-acquisition.ids)
  =/  unk-id   (scow %ux unknown-acquisition.ids)
  =/  itm-id   (scow %ux itemized-acquisition.ids)
  =/  rcp-id   (scow %ux receipt-acquisition.ids)
  =/  nrg-id   (scow %ux energy-component.ids)
  =/  tim-id   (scow %ux time-component.ids)
  =/  ses-id   (scow %ux session-component.ids)
  =/  idl-id   (scow %ux idle-component.ids)
  =/  tax-id   (scow %ux tax-component.ids)
  =/  dsc-id   (scow %ux discount-component.ids)
  =/  rec      (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Cost Fixture Electricity', %electricity, %kwh, Y, {rec}); "
    "INSERT INTO vehicles VALUES ({veh-id}, 'Charging Cost Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {def-id}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {def-id}); "
    "INSERT INTO energy-acquisitions VALUES ({free-id}, {veh-id}, {def-id}, ~2026.7.28..16.00.00, ~2026.7.28..16.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO charging-sessions VALUES ({free-id}); "
    "INSERT INTO charging-costs VALUES ({free-id}, %free, %usd, {rec}); "
    "INSERT INTO energy-acquisitions VALUES ({unk-id}, {veh-id}, {def-id}, ~2026.7.28..16.01.00, ~2026.7.28..16.01.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO charging-sessions VALUES ({unk-id}); "
    "INSERT INTO charging-costs VALUES ({unk-id}, %unknown, %usd, {rec}); "
    "INSERT INTO energy-acquisitions VALUES ({itm-id}, {veh-id}, {def-id}, ~2026.7.28..16.02.00, ~2026.7.28..16.02.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO charging-sessions VALUES ({itm-id}); "
    "INSERT INTO charging-costs VALUES ({itm-id}, %itemized, %usd, {rec}); "
    "INSERT INTO charging-cost-components VALUES ({nrg-id}, {itm-id}, %energy, 45678, 3, %kwh, 250, 11420); "
    "INSERT INTO charging-cost-components VALUES ({tim-id}, {itm-id}, %time, 30, 0, %minute, 100, 3000); "
    "INSERT INTO charging-cost-components VALUES ({ses-id}, {itm-id}, %session, 1, 0, %session, 1500, 1500); "
    "INSERT INTO charging-cost-components VALUES ({idl-id}, {itm-id}, %idle, 5, 0, %minute, 500, 2500); "
    "INSERT INTO charging-cost-components VALUES ({tax-id}, {itm-id}, %tax, 1, 0, %session, 1000, 1000); "
    "INSERT INTO charging-cost-components VALUES ({dsc-id}, {itm-id}, %discount, 1, 0, %session, 2000, 2000); "
    "INSERT INTO energy-acquisitions VALUES ({rcp-id}, {veh-id}, {def-id}, ~2026.7.28..16.03.00, ~2026.7.28..16.03.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO charging-sessions VALUES ({rcp-id}); "
    "INSERT INTO charging-costs VALUES ({rcp-id}, %receipt-total-only, %usd, {rec}); "
    "INSERT INTO charging-cost-source-totals VALUES ({rcp-id}, 22340);"
  ==
::
++  charging-cost-report
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-costs C ON A.acquisition-id = C.acquisition-id WHERE V.label = 'Charging Cost Vehicle' SELECT V.label AS vehicle, A.observed-start, C.cost-state, C.currency; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-cost-components C ON A.acquisition-id = C.acquisition-id WHERE V.label = 'Charging Cost Vehicle' SELECT V.label AS vehicle, C.component, C.quantity, C.quantity-decimals, C.quantity-unit, C.rate-mills, C.amount-mills; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-cost-source-totals T ON A.acquisition-id = T.acquisition-id WHERE V.label = 'Charging Cost Vehicle' SELECT V.label AS vehicle, A.observed-start, T.total-mills;"
  ==
::
++  seed-consumption
  |=  [ids=consumption-ids now=@da]
  ^-  tape
  =/  def-id  (scow %ux definition.ids)
  =/  veh-id  (scow %ux vehicle.ids)
  =/  wh-id   (scow %ux wh-mi.ids)
  =/  eu-id   (scow %ux kwh-100km.ids)
  =/  mpk-id  (scow %ux mi-kwh.ids)
  =/  rec     (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Consumption Fixture Electricity', %electricity, %kwh, Y, {rec}); "
    "INSERT INTO vehicles VALUES ({veh-id}, 'Consumption Evidence Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {def-id}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {def-id}); "
    "INSERT INTO consumption-observations VALUES ({wh-id}, {veh-id}, 275, 0, %wh-mi, %instant, %dashboard, ~2026.7.28..17.00.00, ~2026.7.28..17.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO consumption-observations VALUES ({eu-id}, {veh-id}, 182, 1, %kwh-100km, %trip, %telematics, ~2026.7.28..17.01.00, ~2026.7.28..17.01.01, %second, 'Europe/Paris', {rec}); "
    "INSERT INTO consumption-observations VALUES ({mpk-id}, {veh-id}, 37, 1, %mi-kwh, %since-charge, %dashboard, ~2026.7.28..17.02.00, ~2026.7.28..17.02.01, %second, 'America/Chicago', {rec});"
  ==
::
++  consumption-report
  ^-  tape
  "FROM vehicles V JOIN consumption-observations C ON V.vehicle-id = C.vehicle-id WHERE V.label = 'Consumption Evidence Vehicle' SELECT V.label AS vehicle, C.value-digits, C.value-decimals, C.consumption-unit, C.scope, C.source, C.observed-start, C.observed-end, C.observed-precision, C.source-zone;"
::
++  content-report
  ^-  tape
  ;:  weld
    "FROM vehicles V SELECT V.label, V.archived; "
    "FROM odometer-observations O SELECT O.value-digits, O.decimal-places, O.unit; "
    "FROM energy-definitions E SELECT E.label, E.physical-kind, E.quantity-unit, E.archived; "
    "FROM vehicle-energy-definitions L SELECT L.archived; "
    "FROM vehicle-default-energy-definitions D JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id SELECT E.label AS default-energy; "
    "FROM energy-acquisitions A SELECT A.observed-start, A.observed-end, A.observed-precision, A.source-zone; "
    "FROM fuel-fills F SELECT F.quantity-milli, F.quantity-unit, F.unit-price-mills, F.currency, F.settlement-mode; "
    "FROM charging-sessions C JOIN energy-acquisitions A ON C.acquisition-id = A.acquisition-id SELECT A.observed-start AS charging-start; "
    "FROM places P SELECT P.label, P.archived; "
    "FROM stations S SELECT S.label, S.station-kind, S.archived; "
    "FROM energy-acquisition-stations L JOIN stations S ON L.station-id = S.station-id SELECT S.label AS linked-station; "
    "FROM energy-definition-subtypes S SELECT S.label, S.archived; "
    "FROM energy-subtype-octane O SELECT O.rating, O.method; "
    "FROM energy-subtype-blend B SELECT B.blend-kind, B.percent-digits, B.percent-decimals; "
    "FROM energy-subtype-grade-code G SELECT G.code; "
    "FROM vehicle-default-energy-subtype D SELECT D.recorded-at; "
    "FROM fuel-fill-subtype L SELECT L.acquisition-id; "
    "FROM fuel-fill-odometers L JOIN odometer-observations O ON L.odometer-id = O.odometer-id SELECT O.value-digits AS linked-odometer; "
    "FROM additive-definitions D SELECT D.label, D.archived; "
    "FROM fuel-fill-additives L JOIN additive-definitions D ON L.additive-id = D.additive-id SELECT D.label AS linked-additive; "
    "FROM economy-breaks B SELECT B.reason; "
    "FROM charging-energy-measurements M SELECT M.quantity, M.decimals, M.measure-unit, M.point, M.evidence; "
    "FROM battery-observations B SELECT B.measure, B.observed-start, B.observed-end, B.observed-precision, B.source-zone; "
    "FROM battery-observation-percent P SELECT P.value-digits, P.value-decimals; "
    "FROM battery-observation-segments S SELECT S.filled, S.total; "
    "FROM charging-session-batteries B SELECT B.endpoint; "
    "FROM charging-efficiency-breaks B SELECT B.reason; "
    "FROM charging-costs C SELECT C.cost-state, C.currency; "
    "FROM charging-cost-components C SELECT C.component, C.amount-mills; "
    "FROM charging-cost-source-totals T SELECT T.total-mills; "
    "FROM consumption-observations C SELECT C.value-digits, C.value-decimals, C.consumption-unit, C.scope, C.source; "
    "FROM place-addresses A SELECT A.source; "
    "FROM place-address-formatted F SELECT F.formatted; "
    "FROM place-address-parts A SELECT A.part, A.value; "
    "FROM place-coordinates C SELECT C.latitude-scaled, C.longitude-scaled, C.coord-scale, C.source; "
    "FROM place-coordinate-accuracy A SELECT A.radius-digits, A.radius-decimals, A.radius-unit; "
    "FROM station-brand-operator B SELECT B.role, B.label; "
    "FROM station-identifiers I SELECT I.provider; "
    "FROM acquisition-station-equipment E SELECT E.equipment-label, E.receipt-text;"
  ==
::
++  seed-location
  |=  [ids=location-ids now=@da]
  ^-  tape
  =/  res-id  (scow %ux reservoir-definition.ids)
  =/  sub-id  (scow %ux (fixture-id reservoir-definition.ids 90))
  =/  ele-id  (scow %ux electricity-definition.ids)
  =/  veh-id  (scow %ux vehicle.ids)
  =/  fil-id  (scow %ux fill-acquisition.ids)
  =/  chg-id  (scow %ux charge-acquisition.ids)
  =/  prv-plc  (scow %ux private-place.ids)
  =/  prv-sta  (scow %ux private-station.ids)
  =/  pub-plc  (scow %ux public-place.ids)
  =/  mix-sta  (scow %ux mixed-station.ids)
  ::  Q9 fixture: a place whose address arrives as PARTS ONLY, with no
  ::  formatted text - the shape 105 of 420 real aCar fills take. Derived from
  ::  the public place id so no new field is needed on location-ids.
  =/  prt-plc  (scow %ux (fixture-id public-place.ids 91))
  =/  rec      (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({res-id}, 'Location Fixture Fuel', %reservoir, %gal, Y, {rec}); "
    "INSERT INTO energy-definitions VALUES ({ele-id}, 'Location Fixture Electricity', %electricity, %kwh, Y, {rec}); "
    "INSERT INTO energy-definition-subtypes VALUES ({sub-id}, {res-id}, 'Location Grade', N, {rec}); "
    "INSERT INTO energy-subtype-grade-code VALUES ({sub-id}, 'LOC-RES'); "
    "INSERT INTO vehicles VALUES ({veh-id}, 'Location Evidence Vehicle', N, {rec}); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {res-id}, N); "
    "INSERT INTO vehicle-energy-definitions VALUES ({veh-id}, {ele-id}, N); "
    "INSERT INTO vehicle-default-energy-definitions VALUES ({veh-id}, {res-id}); "
    "INSERT INTO places VALUES ({prv-plc}, 'Private Home', N, {rec}); "
    "INSERT INTO stations VALUES ({prv-sta}, {prv-plc}, 'Home Charger', %private, N, {rec}); "
    "INSERT INTO places VALUES ({pub-plc}, 'Public Market', N, {rec}); "
    "INSERT INTO stations VALUES ({mix-sta}, {pub-plc}, 'Market Mixed Station', %mixed, N, {rec}); "
    "INSERT INTO place-addresses VALUES ({pub-plc}, %owner, {rec}); "
    "INSERT INTO place-address-formatted VALUES ({pub-plc}, '123 Market St, Chicago, IL 60601, USA'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %country, 'US'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %locality, 'Chicago'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %region, 'IL'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %postal-code, '60601'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %line1, '123 Market St'); "
    ::  Q9: parts-only place. Address row exists (evidence, source %imported)
    ::  with NO place-address-formatted child - previously impossible, because
    ::  formatted was a mandatory column on the parent.
    "INSERT INTO places VALUES ({prt-plc}, 'Parts Only Depot', N, {rec}); "
    "INSERT INTO place-addresses VALUES ({prt-plc}, %imported, {rec}); "
    "INSERT INTO place-address-parts VALUES ({prt-plc}, %line1, '900 Depot Rd'); "
    "INSERT INTO place-address-parts VALUES ({prt-plc}, %locality, 'Aurora'); "
    "INSERT INTO place-address-parts VALUES ({prt-plc}, %region, 'IL'); "
    "INSERT INTO place-coordinates VALUES ({pub-plc}, -418.781.136, --876.297.982, 7, %gps, {rec}); "
    "INSERT INTO place-coordinate-accuracy VALUES ({pub-plc}, 47, 1, %metre); "
    "INSERT INTO station-brand-operator VALUES ({mix-sta}, %brand, 'Shell'); "
    "INSERT INTO station-brand-operator VALUES ({mix-sta}, %operator, 'Acme Mobility'); "
    "INSERT INTO station-identifiers VALUES ({mix-sta}, %chargepoint, 'CP-1234'); "
    "INSERT INTO energy-acquisitions VALUES ({fil-id}, {veh-id}, {res-id}, ~2026.7.28..18.00.00, ~2026.7.28..18.00.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO fuel-fills VALUES ({fil-id}, 9000, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); "
    "INSERT INTO fuel-fill-subtype VALUES ({fil-id}, {sub-id}); "
    "INSERT INTO energy-acquisition-stations VALUES ({fil-id}, {mix-sta}); "
    "INSERT INTO acquisition-station-equipment VALUES ({fil-id}, 'Pump 7', 'PUMP 7'); "
    "INSERT INTO energy-acquisitions VALUES ({chg-id}, {veh-id}, {ele-id}, ~2026.7.28..18.30.00, ~2026.7.28..18.30.01, %second, 'America/Chicago', {rec}); "
    "INSERT INTO charging-sessions VALUES ({chg-id}); "
    "INSERT INTO energy-acquisition-stations VALUES ({chg-id}, {mix-sta});"
  ==
::
++  location-report
  ^-  tape
  ;:  weld
    "FROM places P JOIN stations S ON P.place-id = S.place-id WHERE P.label = 'Private Home' OR P.label = 'Public Market' SELECT P.label AS place, P.archived AS place-archived, S.label AS station, S.station-kind, S.archived AS station-archived; "
    "FROM places P JOIN place-addresses A ON P.place-id = A.place-id WHERE P.label = 'Public Market' SELECT P.label AS place, A.source; "
    "FROM places P JOIN place-address-formatted F ON P.place-id = F.place-id WHERE P.label = 'Public Market' SELECT P.label AS place, F.formatted; "
    ::  Q9 coverage: a place whose address is PARTS ONLY, no formatted text -
    ::  the 105-record aCar case. It must have an address row and a locality
    ::  part, and must NOT appear in the formatted query above.
    "FROM places P JOIN place-address-formatted F ON P.place-id = F.place-id WHERE P.label = 'Parts Only Depot' SELECT P.label AS parts-only-with-formatted; "
    "FROM places P JOIN place-address-parts A ON P.place-id = A.place-id WHERE P.label = 'Parts Only Depot' SELECT P.label AS place, A.part, A.value; "
    "FROM places P JOIN place-addresses A ON P.place-id = A.place-id WHERE P.label = 'Private Home' SELECT P.label AS private-place-with-address; "
    "FROM places P JOIN place-address-parts A ON P.place-id = A.place-id WHERE P.label = 'Public Market' SELECT P.label AS place, A.part, A.value; "
    "FROM places P JOIN place-coordinates C ON P.place-id = C.place-id WHERE P.label = 'Public Market' SELECT P.label AS place, C.latitude-scaled, C.longitude-scaled, C.coord-scale, C.source; "
    "FROM places P JOIN place-coordinates C ON P.place-id = C.place-id WHERE P.label = 'Private Home' SELECT P.label AS private-place-with-coordinates; "
    "FROM places P JOIN place-coordinate-accuracy A ON P.place-id = A.place-id WHERE P.label = 'Public Market' SELECT P.label AS place, A.radius-digits, A.radius-decimals, A.radius-unit; "
    "FROM stations S JOIN station-brand-operator B ON S.station-id = B.station-id WHERE S.label = 'Market Mixed Station' SELECT S.label AS station, B.role, B.label; "
    "FROM stations S JOIN station-identifiers I ON S.station-id = I.station-id WHERE S.label = 'Market Mixed Station' SELECT S.label AS station, I.provider; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id JOIN energy-acquisition-stations L ON A.acquisition-id = L.acquisition-id JOIN stations S ON L.station-id = S.station-id WHERE V.label = 'Location Evidence Vehicle' SELECT V.label AS vehicle, E.physical-kind, S.label AS station, S.station-kind, A.observed-start; "
    "FROM stations S JOIN energy-acquisition-stations L ON S.station-id = L.station-id JOIN acquisition-station-equipment E ON L.acquisition-id = E.acquisition-id WHERE S.label = 'Market Mixed Station' SELECT S.label AS station, E.equipment-label, E.receipt-text; "
    "FROM energy-definitions D JOIN energy-definition-subtypes S ON D.energy-definition-id = S.energy-definition-id JOIN energy-subtype-grade-code G ON S.subtype-id = G.subtype-id WHERE D.label = 'Location Fixture Fuel' SELECT D.label AS energy, S.label AS subtype, G.code;"
  ==
::
++  verify-schema
  ^-  tape
  ;:  weld
    "FROM sys.tables WHERE namespace = %dbo SELECT name; "
    "FROM sys.columns WHERE namespace = %dbo SELECT name, col-name, col-type; "
    "FROM sys.foreign-keys SELECT parent-table, child-table, ordinal, parent-column, child-column, on-delete, on-update;"
  ==
::
++  vehicle-history
  ^-  tape
  ;:  weld
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, V.archived AS vehicle-archived, E.label AS energy, E.physical-kind, E.archived AS energy-archived, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id JOIN vehicle-energy-definitions L ON D.vehicle-id = L.vehicle-id AND D.energy-definition-id = L.energy-definition-id JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, E.label AS default-energy, L.archived AS link-archived; "
    "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, O.value-digits, O.decimal-places, O.unit, O.observed-start, O.observed-end, O.recorded-at; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, E.label AS energy, F.quantity-milli, F.quantity-unit, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills, A.observed-start, A.observed-end;"
  ==
::
++  current-odometer
  ^-  tape
  "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, O.value-digits, O.decimal-places, O.unit, O.observed-start, O.observed-end, O.recorded-at;"
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
    " FROM fuel-fill-odometers L JOIN odometer-observations O ON L.odometer-id = O.odometer-id SELECT L.acquisition-id, O.value-digits, O.decimal-places, O.unit;"
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
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-odometers L ON A.acquisition-id = L.acquisition-id WHERE V.label = '"
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
      "); INSERT INTO fuel-fill-odometers VALUES ("
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
++  energy-definition-lookup
  |=  label=@t
  ^-  tape
  ;:  weld
    "FROM energy-definitions E WHERE E.label = '"
    (sql-quote label)
    "' AND E.archived = N SELECT E.energy-definition-id, E.label, E.archived;"
  ==
::
++  consumable-definition-lookup
  |=  label=@t
  ^-  tape
  ;:  weld
    "FROM consumable-definitions C WHERE C.label = '"
    (sql-quote label)
    "' AND C.archived = N SELECT C.consumable-id, C.label, C.archived;"
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
++  rename-energy-definition
  |=  [definition-id=@ux new-label=@t]
  ^-  tape
  ;:  weld
    "UPDATE energy-definitions SET label = '"
    (sql-quote new-label)
    "' WHERE energy-definition-id = "
    (scow %ux definition-id)
    ";"
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
++  rename-consumable-definition
  |=  [consumable-id=@ux new-label=@t]
  ^-  tape
  ;:  weld
    "UPDATE consumable-definitions SET label = '"
    (sql-quote new-label)
    "' WHERE consumable-id = "
    (scow %ux consumable-id)
    ";"
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
++  vehicle-settings-report
  |=  label=@t
  ^-  tape
  ;:  weld
    "FROM vehicles V WHERE V.label = '"
    (sql-quote label)
    "' SELECT V.label AS vehicle, V.archived; "
    "FROM vehicles V JOIN vehicle-tank-size T ON V.vehicle-id = T.vehicle-id WHERE V.label = '"
    (sql-quote label)
    "' SELECT V.label AS vehicle, T.digits, T.decimals, T.size-unit; "
    "FROM vehicles V JOIN vehicle-refill-reserve R ON V.vehicle-id = R.vehicle-id WHERE V.label = '"
    (sql-quote label)
    "' SELECT V.label AS vehicle, R.reserve-percent; "
    "FROM vehicles V JOIN vehicle-default-energy-subtype D ON V.vehicle-id = D.vehicle-id JOIN energy-definition-subtypes S ON D.subtype-id = S.subtype-id WHERE V.label = '"
    (sql-quote label)
    "' SELECT V.label AS vehicle, S.label AS default-subtype; "
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id WHERE V.label = '"
    (sql-quote label)
    "' SELECT E.label AS energy, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id WHERE V.label = '"
    (sql-quote label)
    "' SELECT D.label AS driving-mode, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-consumables L ON V.vehicle-id = L.vehicle-id JOIN consumable-definitions C ON L.consumable-id = C.consumable-id WHERE V.label = '"
    (sql-quote label)
    "' AND C.label = 'DEF' SELECT C.label AS consumable, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-consumable-tank-size T ON V.vehicle-id = T.vehicle-id JOIN consumable-definitions C ON T.consumable-id = C.consumable-id WHERE V.label = '"
    (sql-quote label)
    "' AND C.label = 'DEF' SELECT T.digits, T.decimals, T.unit; "
    "FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id WHERE V.label = '"
    (sql-quote label)
    "' SELECT E.label AS default-energy;"
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
      "); INSERT INTO fuel-fill-odometers VALUES ("
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
    (insert-odometer odometer.ids vehicle-id odo-input recorded-at)
  ;:(weld base subtype-row delivered-row start-row end-row mileage-row)
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
::
++  order-results
  |=  [key=@tas descending=? results=(list result:ast)]
  ^-  (list result:ast)
  %+  turn  results
  |=  item=result:ast
  ?-  -.item
    %result-set  [%result-set (order-vectors key descending +.item)]
    %action      item
    %relation-name  item
    %message     item
    %vector-count  item
    %server-time  item
    %security-time  item
    %schema-time  item
    %data-time   item
    %relations   item
    %select-relation  item
  ==
::
++  order-command-results
  |=  [key=@tas descending=? commands=(list cmd-result:ast)]
  ^-  (list cmd-result:ast)
  %+  turn  commands
  |=  command=cmd-result:ast
  [%results (order-results key descending +.command)]
::
++  latest-results
  |=  results=(list result:ast)
  ^-  (list result:ast)
  %+  turn  results
  |=  item=result:ast
  ?-  -.item
    %result-set
      =/  ordered  (order-vectors %observed-start %.y +.item)
      [%result-set ?~(ordered ~ ~[i.ordered])]
    %vector-count  [%vector-count 1]
    %action      item
    %relation-name  item
    %message     item
    %server-time  item
    %security-time  item
    %schema-time  item
    %data-time   item
    %relations   item
    %select-relation  item
  ==
::
++  latest-command-results
  |=  commands=(list cmd-result:ast)
  ^-  (list cmd-result:ast)
  %+  turn  commands
  |=  command=cmd-result:ast
  [%results (latest-results +.command)]
--
