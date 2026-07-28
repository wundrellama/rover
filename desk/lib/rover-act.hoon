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
++  schema-m0
  ^-  tape
  ;:  weld
    "CREATE DATABASE rover; "
    "CREATE TABLE rover..vehicles (vehicle-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (vehicle-id); "
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
    "CREATE TABLE rover..energy-definition-octane (energy-definition-id @ux, rating @ud, method @tas) PRIMARY KEY (energy-definition-id) FOREIGN KEY (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-definition-blend (energy-definition-id @ux, blend-kind @tas, percent-digits @ud, percent-decimals @ud) PRIMARY KEY (energy-definition-id, blend-kind) FOREIGN KEY (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-definition-grade-code (energy-definition-id @ux, code @t) PRIMARY KEY (energy-definition-id) FOREIGN KEY (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
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
    "CREATE TABLE rover..place-addresses (place-id @ux, formatted @t, source @tas, recorded-at @da) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-address-parts (place-id @ux, part @tas, value @t) PRIMARY KEY (place-id, part) FOREIGN KEY (place-id) REFERENCES place-addresses (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-coordinates (place-id @ux, latitude-scaled @sd, longitude-scaled @sd, coord-scale @ud, source @tas, recorded-at @da) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-coordinate-accuracy (place-id @ux, radius-digits @ud, radius-decimals @ud, radius-unit @tas) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES place-coordinates (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..station-brand-operator (station-id @ux, role @tas, label @t) PRIMARY KEY (station-id, role) FOREIGN KEY (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..station-identifiers (station-id @ux, provider @tas, external-id @t) PRIMARY KEY (station-id, provider) FOREIGN KEY (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..acquisition-station-equipment (acquisition-id @ux, equipment-label @t, receipt-text @t) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisition-stations (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
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
    "INSERT INTO energy-definitions VALUES ({res-id}, 'Regular 87', %reservoir, %gal, N, {rec}); "
    "INSERT INTO energy-definitions VALUES ({ele-id}, 'Electricity', %electricity, %kwh, N, {rec}); "
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
    "INSERT INTO energy-definitions VALUES ({usd-id}, 'Pricing US gallon', %reservoir, %gal, N, {rec}); "
    "INSERT INTO energy-definitions VALUES ({eur-id}, 'Pricing EUR litre', %reservoir, %litre, N, {rec}); "
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
    %relation    item
    %message     item
    %vector-count  item
    %server-time  item
    %security-time  item
    %schema-time  item
    %data-time   item
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
    %relation    item
    %message     item
    %server-time  item
    %security-time  item
    %schema-time  item
    %data-time   item
  ==
::
++  latest-command-results
  |=  commands=(list cmd-result:ast)
  ^-  (list cmd-result:ast)
  %+  turn  commands
  |=  command=cmd-result:ast
  [%results (latest-results +.command)]
--
