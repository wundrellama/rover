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
  ==
+$  charge-ids
  $:  acquisition=@ux
      measurement=@ux
      start-battery=@ux
      end-battery=@ux
      odometer=@ux
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
    "CREATE TABLE rover..place-addresses (place-id @ux, formatted @t, source @tas, recorded-at @da) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-address-parts (place-id @ux, part @tas, value @t) PRIMARY KEY (place-id, part) FOREIGN KEY (place-id) REFERENCES place-addresses (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-coordinates (place-id @ux, latitude-scaled @sd, longitude-scaled @sd, coord-scale @ud, source @tas, recorded-at @da) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..place-coordinate-accuracy (place-id @ux, radius-digits @ud, radius-decimals @ud, radius-unit @tas) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES place-coordinates (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..station-brand-operator (station-id @ux, role @tas, label @t) PRIMARY KEY (station-id, role) FOREIGN KEY (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..station-identifiers (station-id @ux, provider @tas, external-id @t) PRIMARY KEY (station-id, provider) FOREIGN KEY (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..acquisition-station-equipment (acquisition-id @ux, equipment-label @t, receipt-text @t) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisition-stations (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..app-default-vehicle (scope @tas, vehicle-id @ux, recorded-at @da) PRIMARY KEY (scope) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE rover..vehicle-tank-size (vehicle-id @ux, digits @ud, decimals @ud, size-unit @tas) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
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
  ==
::
++  display-preference-schema
  ^-  tape
  "CREATE TABLE rover..vehicle-display-preferences (vehicle-id @ux, distance-unit @tas, currency @tas, recorded-at @da) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
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
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Gasoline', %reservoir, %gal, N, {rec}); "
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
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Fixture Electricity', %electricity, %kwh, N, {rec}); "
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
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Cost Fixture Electricity', %electricity, %kwh, N, {rec}); "
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
    "INSERT INTO energy-definitions VALUES ({def-id}, 'Consumption Fixture Electricity', %electricity, %kwh, N, {rec}); "
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
    "FROM place-addresses A SELECT A.formatted, A.source; "
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
  =/  rec      (scow %da now)
  ;:  weld
    "INSERT INTO energy-definitions VALUES ({res-id}, 'Location Fixture Fuel', %reservoir, %gal, N, {rec}); "
    "INSERT INTO energy-definitions VALUES ({ele-id}, 'Location Fixture Electricity', %electricity, %kwh, N, {rec}); "
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
    "INSERT INTO place-addresses VALUES ({pub-plc}, '123 Market St, Chicago, IL 60601, USA', %owner, {rec}); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %country, 'US'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %locality, 'Chicago'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %region, 'IL'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %postal-code, '60601'); "
    "INSERT INTO place-address-parts VALUES ({pub-plc}, %line1, '123 Market St'); "
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
    "FROM places P JOIN place-addresses A ON P.place-id = A.place-id WHERE P.label = 'Public Market' SELECT P.label AS place, A.formatted, A.source; "
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
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id SELECT V.vehicle-id, A.acquisition-id, E.label AS energy, F.quantity-milli, F.quantity-unit, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.minor-unit-decimals, F.cash-increment-mills, A.observed-start, A.observed-end, A.source-zone, A.recorded-at;"
    " FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id JOIN charging-costs K ON C.acquisition-id = K.acquisition-id SELECT V.vehicle-id, C.acquisition-id, E.label AS energy, A.observed-start, A.observed-end, A.source-zone, A.recorded-at, K.cost-state, K.currency;"
    " FROM charging-energy-measurements M SELECT M.acquisition-id, M.quantity, M.decimals, M.measure-unit, M.point, M.evidence;"
    " FROM charging-session-batteries L JOIN battery-observation-percent P ON L.battery-observation-id = P.battery-observation-id SELECT L.acquisition-id, L.endpoint, P.value-digits, P.value-decimals;"
    " FROM stations S JOIN places P ON S.place-id = P.place-id SELECT S.station-id, S.label, S.station-kind, S.archived, P.label AS place;"
    " FROM additive-definitions D SELECT D.additive-id, D.label, D.archived;"
    " FROM energy-acquisition-stations L JOIN stations S ON L.station-id = S.station-id JOIN places P ON S.place-id = P.place-id SELECT L.acquisition-id, S.label AS station, P.label AS place;"
    " FROM fuel-fill-additives L JOIN additive-definitions D ON L.additive-id = D.additive-id SELECT L.acquisition-id, D.label AS additive;"
    " FROM vehicle-display-preferences P SELECT P.vehicle-id, P.distance-unit, P.currency;"
    " FROM fuel-fill-subtype L JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id SELECT L.acquisition-id, S.label AS subtype;"
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
  =/  escaped=tape  ?:  =(39 i.chars)  "''"  [i.chars ~]
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
  ;:(weld new-station-rows acquisition-row fill-row mileage-rows station-row additive-rows)
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
  ;:(weld base delivered-row start-row end-row mileage-row)
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
