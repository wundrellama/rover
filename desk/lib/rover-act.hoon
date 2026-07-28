::  lib/rover-act - Obelisk driver helpers for %rover.
::
/-  ast=obelisk-ast
|%
+$  seed-ids
  $:  reservoir=@ux
      electricity=@ux
      vehicle=@ux
      odometer-before=@ux
      acquisition=@ux
      odometer-at-fill=@ux
  ==
::
++  rover-db  %rover
::
++  schema-v1
  ^-  tape
  ;:  weld
    "CREATE DATABASE rover; "
    "CREATE TABLE rover..vehicles (vehicle-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (vehicle-id); "
    "CREATE TABLE rover..odometer-observations (odometer-id @ux, vehicle-id @ux, value-digits @ud, decimal-places @ud, unit @tas, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (odometer-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-definitions (energy-definition-id @ux, label @t, physical-kind @tas, quantity-unit @tas, archived @f, recorded-at @da) PRIMARY KEY (energy-definition-id); "
    "CREATE TABLE rover..vehicle-energy-definitions (vehicle-id @ux, energy-definition-id @ux, archived @f) PRIMARY KEY (vehicle-id, energy-definition-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-default-energy-definitions (vehicle-id @ux, energy-definition-id @ux) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id, energy-definition-id) REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-acquisitions (acquisition-id @ux, vehicle-id @ux, energy-definition-id @ux, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (acquisition-id) FOREIGN KEY (vehicle-id, energy-definition-id) REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..fuel-fills (acquisition-id @ux, quantity-milli @ud, quantity-unit @tas, tank-state @tas) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..charging-sessions (acquisition-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..places (place-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (place-id); "
    "CREATE TABLE rover..stations (station-id @ux, place-id @ux, label @t, station-kind @tas, archived @f, recorded-at @da) PRIMARY KEY (station-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..energy-acquisition-stations (acquisition-id @ux, station-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
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
    "INSERT INTO fuel-fills VALUES ({acq-id}, 12345, %gal, %full); "
    "INSERT INTO odometer-observations VALUES ({odo-b}, {veh-id}, 100125, 1, %mi, ~2026.7.28..12.00.00, ~2026.7.28..12.00.01, %second, 'America/Chicago', {rec});"
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
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, E.label AS energy, F.quantity-milli, F.quantity-unit, F.tank-state, A.observed-start, A.observed-end;"
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
