/-  ast=obelisk-ast
/+  render=rover-render, view=rover-view
|%
++  rows
  |=  [commands=(list cmd-result:ast) index=@ud]
  ^-  (list vector:ast)
  (rows-at:view commands index)
::
++  one-by
  |=  [key=@tas value=@ rows=(list vector:ast)]
  ^-  (unit vector:ast)
  =/  found  (rows-by:view key value rows)
  ?~  found  ~
  `i.found
::
++  text-by
  |=  [id-key=@tas value=@ label-key=@tas rows=(list vector:ast)]
  ^-  (unit @t)
  =/  found  (one-by id-key value rows)
  ?~  found  ~
  `(cell-text:view label-key u.found)
::
++  has-row
  |=  [key=@tas value=@ rows=(list vector:ast)]
  ^-  ?
  ?=(^ (rows-by:view key value rows))
::
++  object
  |=  fields=(list [@t json])
  ^-  json
  (pairs:enjs:format fields)
::
++  j-term
  |=  value=@tas
  ^-  json
  s+(scot %tas value)
::
++  j-ud
  |=  value=@ud
  ^-  json
  n+(scot %ud value)
::
++  j-scaled
  |=  [digits=@ud places=@ud]
  ^-  json
  s+(format-scaled:render digits places %.n)
::
++  j-signed-scaled
  |=  [digits=@sd places=@ud]
  ^-  json
  s+(format-sscaled:render digits places %.n)
::
++  j-da
  |=  value=@da
  ^-  json
  s+(crip (input-da:view value))
::
++  j-day
  |=  value=@da
  ^-  json
  s+(crip (scag 10 (trip (format-da:render value))))
::
++  archived
  |=  row=vector:ast
  ^-  json
  [%b =(0 (cell-atom:view %archived row))]
::
++  unit-row-json
  |=  [key=@t value=(unit json) fields=(list [@t json])]
  ^-  (list [@t json])
  ?~  value  fields
  [[key u.value] fields]
::
++  unit-text-json
  |=  [key=@t value=(unit @t) fields=(list [@t json])]
  ^-  (list [@t json])
  ?~  value  fields
  [[key s+u.value] fields]
::
++  labels-for-links
  |=  $:  owner-key=@tas
          owner=@
          target-key=@tas
          links=(list vector:ast)
          target-id-key=@tas
          target-label-key=@tas
          targets=(list vector:ast)
      ==
  ^-  (list json)
  =/  mine  (rows-by:view owner-key owner links)
  %+  turn  mine
  |=  link=vector:ast
  =/  target  (cell-atom:view target-key link)
  =/  label  (text-by target-id-key target target-label-key targets)
  s+(need label)
::
++  source-json
  ^-  json
  =/  attachments=json
    %-  object
    :~  ['included' b+%.n]
        ['photoCount' n+'0']
        ['manifest' s+'attachments-manifest.json']
    ==
  =/  omission=json
    %-  object
    :~  ['kind' s+'photos']
        ['count' n+'0']
        ['manifest' s+'attachments-manifest.json']
        ['reason' s+'Photo attachments are stored outside the Rover database and are not included.']
    ==
  %-  object
  :~  ['app' s+'Rover']
      ['version' s+'1']
      ['attachments' attachments]
      ['omissions' [%a ~[omission]]]
  ==
::
++  simple-definitions
  |=  rows=(list vector:ast)
  ^-  (list json)
  %+  turn  rows
  |=  row=vector:ast
  %-  object
  :~  ['label' s+(cell-text:view %label row)]
      ['archived' (archived row)]
  ==
::
++  blend-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['kind' (j-term (cell-term:view %blend-kind row))]
      ['percent' (j-scaled (cell-atom:view %percent-digits row) (cell-atom:view %percent-decimals row))]
  ==
::
++  option-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['ordinal' (j-ud (cell-atom:view %ordinal row))]
      ['label' s+(cell-text:view %label row)]
  ==
::
++  brand-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['role' (j-term (cell-term:view %role row))]
      ['label' s+(cell-text:view %label row)]
  ==
::
++  identifier-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['provider' (j-term (cell-term:view %provider row))]
      ['externalId' s+(cell-text:view %external-id row)]
  ==
::
++  subtype-json
  |=  [row=vector:ast commands=(list cmd-result:ast)]
  ^-  json
  =/  subtype-id  (cell-atom:view %subtype-id row)
  =/  fields=(list [@t json])
    :~  ['label' s+(cell-text:view %label row)]
        ['archived' (archived row)]
    ==
  =/  octane  (one-by %subtype-id subtype-id (rows commands 13))
  =.  fields
    ?~  octane
      fields
    =/  next=(list [@t json])
      [['octane' s+(scot %ud (cell-atom:view %rating u.octane))] fields]
    [['method' (j-term (cell-term:view %method u.octane))] next]
  =/  cetane  (one-by %subtype-id subtype-id (rows commands 14))
  =.  fields
    ?~(cetane fields [['cetane' s+(scot %ud (cell-atom:view %rating u.cetane))] fields])
  =/  grade  (one-by %subtype-id subtype-id (rows commands 16))
  =.  fields
    ?~(grade fields [['gradeCode' s+(cell-text:view %code u.grade)] fields])
  =/  blends  (rows-by:view %subtype-id subtype-id (rows commands 15))
  =.  fields
    ?~  blends
      fields
    :-  ['blends' [%a (turn blends blend-json)]]
    fields
  (object (flop fields))
::
++  energy-definitions
  |=  commands=(list cmd-result:ast)
  ^-  (list json)
  %+  turn  (rows commands 3)
  |=  row=vector:ast
  =/  definition-id  (cell-atom:view %energy-definition-id row)
  =/  subtypes  (rows-by:view %energy-definition-id definition-id (rows commands 12))
  %-  object
  :~  ['label' s+(cell-text:view %label row)]
      ['physicalKind' (j-term (cell-term:view %physical-kind row))]
      ['quantityUnit' (j-term (cell-term:view %quantity-unit row))]
      ['archived' (archived row)]
      ['subtypes' [%a (turn subtypes |=(subtype=vector:ast (subtype-json subtype commands)))]]
  ==
::
++  service-definitions
  |=  commands=(list cmd-result:ast)
  ^-  (list json)
  %+  turn  (rows commands 82)
  |=  row=vector:ast
  =/  subtype-id  (cell-atom:view %service-subtype-id row)
  =/  defaults  (one-by %service-subtype-id subtype-id (rows commands 83))
  =/  fields=(list [@t json])
    :~  ['label' s+(cell-text:view %label row)]
        ['archived' (archived row)]
    ==
  =.  fields
    ?~  defaults
      fields
    =/  next=(list [@t json])
      [['defaultTimeInterval' s+(scot %ud (cell-atom:view %time-interval u.defaults))] fields]
    =.  next  [['defaultTimeUnit' (j-term (cell-term:view %time-unit u.defaults))] next]
    =.  next  [['defaultDistanceInterval' (j-scaled (cell-atom:view %distance-digits u.defaults) (cell-atom:view %distance-decimals u.defaults))] next]
    [['defaultDistanceUnit' (j-term (cell-term:view %distance-unit u.defaults))] next]
  (object (flop fields))
::
++  consumable-definitions
  |=  rows=(list vector:ast)
  ^-  (list json)
  %+  turn  rows
  |=  row=vector:ast
  %-  object
  :~  ['label' s+(cell-text:view %label row)]
      ['quantityUnit' (j-term (cell-term:view %quantity-unit row))]
      ['archived' (archived row)]
  ==
::
++  custom-definitions
  |=  commands=(list cmd-result:ast)
  ^-  (list json)
  %+  turn  (rows commands 50)
  |=  row=vector:ast
  =/  field-id  (cell-atom:view %field-id row)
  =/  options  (rows-by:view %field-id field-id (rows commands 51))
  %-  object
  :~  ['label' s+(cell-text:view %label row)]
      ['contentType' (j-term (cell-term:view %content-type row))]
      ['entryType' (j-term (cell-term:view %entry-type row))]
      ['mandatory' [%b =(0 (cell-atom:view %mandatory row))]]
      ['target' (j-term (cell-term:view %target row))]
      ['archived' (archived row)]
      ['options' [%a (turn options option-json)]]
  ==
::
++  definitions-json
  |=  commands=(list cmd-result:ast)
  ^-  json
  %-  object
  :~  ['energy' [%a (energy-definitions commands)]]
      ['service-subtypes' [%a (service-definitions commands)]]
      ['additives' [%a (simple-definitions (rows commands 18))]]
      ['driving-modes' [%a (simple-definitions (rows commands 43))]]
      ['tags' [%a (simple-definitions (rows commands 48))]]
      ['payment-methods' [%a (simple-definitions (rows commands 55))]]
      ['consumables' [%a (consumable-definitions (rows commands 60))]]
      ['disposal-kinds' [%a (simple-definitions (rows commands 84))]]
      ['custom-fields' [%a (custom-definitions commands)]]
  ==
::
++  address-parts-json
  |=  rows=(list vector:ast)
  ^-  json
  =/  fields=(list [@t json])  ~
  |-
  ?~  rows
    (object fields)
  %=  $
    rows  t.rows
    fields  [[(cell-text:view %part i.rows) s+(cell-text:view %value i.rows)] fields]
  ==
::
++  station-json
  |=  [row=vector:ast commands=(list cmd-result:ast)]
  ^-  json
  =/  station-id  (cell-atom:view %station-id row)
  =/  brands  (rows-by:view %station-id station-id (rows commands 36))
  =/  identifiers  (rows-by:view %station-id station-id (rows commands 37))
  %-  object
  :~  ['label' s+(cell-text:view %label row)]
      ['stationKind' (j-term (cell-term:view %station-kind row))]
      ['archived' (archived row)]
      ['brandOperators' [%a (turn brands brand-json)]]
      ['identifiers' [%a (turn identifiers identifier-json)]]
  ==
::
++  place-json
  |=  [row=vector:ast commands=(list cmd-result:ast)]
  ^-  json
  =/  place-id  (cell-atom:view %place-id row)
  =/  stations  (rows-by:view %place-id place-id (rows commands 10))
  =/  address  (one-by %place-id place-id (rows commands 31))
  =/  formatted  (one-by %place-id place-id (rows commands 32))
  =/  parts  (rows-by:view %place-id place-id (rows commands 33))
  =/  coordinates  (one-by %place-id place-id (rows commands 34))
  =/  accuracy  (one-by %place-id place-id (rows commands 35))
  =/  fields=(list [@t json])
    :~  ['label' s+(cell-text:view %label row)]
        ['archived' (archived row)]
        ['stations' [%a (turn stations |=(station=vector:ast (station-json station commands)))]]
        ['stationKind' ?~(stations s+'fuel' (j-term (cell-term:view %station-kind i.stations)))]
    ==
  =.  fields
    ?~  address
      fields
    =/  address-fields=(list [@t json])
      :~  ['source' (j-term (cell-term:view %source u.address))]
          ['parts' (address-parts-json parts)]
      ==
    =.  address-fields
      ?~(formatted address-fields [['formatted' s+(cell-text:view %formatted u.formatted)] address-fields])
    [['address' (object (flop address-fields))] fields]
  =.  fields
    ?~  coordinates
      fields
    =/  coordinate-fields=(list [@t json])
      :~  ['lat' (j-signed-scaled `@sd`(cell-atom:view %latitude-scaled u.coordinates) (cell-atom:view %coord-scale u.coordinates))]
          ['lon' (j-signed-scaled `@sd`(cell-atom:view %longitude-scaled u.coordinates) (cell-atom:view %coord-scale u.coordinates))]
          ['source' (j-term (cell-term:view %source u.coordinates))]
      ==
    =.  coordinate-fields
      ?~  accuracy
        coordinate-fields
      %+  weld
        :~  ['accuracy' (j-scaled (cell-atom:view %radius-digits u.accuracy) (cell-atom:view %radius-decimals u.accuracy))]
            ['accuracyUnit' (j-term (cell-term:view %radius-unit u.accuracy))]
        ==
      coordinate-fields
    [['coordinates' (object (flop coordinate-fields))] fields]
  (object (flop fields))
::
++  places-json
  |=  commands=(list cmd-result:ast)
  ^-  (list json)
  %+  turn  (rows commands 9)
  |=  row=vector:ast
  (place-json row commands)
::
++  spec-json
  |=  [vehicle-id=@ commands=(list cmd-result:ast)]
  ^-  json
  =/  names=(list [key=@t column=@tas index=@ud])
    :~  ['specVin' %vin 88]
        ['specPlate' %plate 89]
        ['specYear' %model-year 90]
        ['specMake' %make 91]
        ['specModel' %model 92]
        ['specSubModel' %sub-model 93]
        ['specBodyType' %body-type 94]
        ['specColor' %color 95]
        ['specEngine' %engine 96]
        ['specTransmission' %transmission 97]
        ['specDriveType' %drive-type 98]
        ['specBedType' %bed-type 99]
        ['specNotes' %note 100]
    ==
  =/  fields=(list [@t json])  ~
  |-
  ?~  names
    (object (flop fields))
  =/  found  (one-by %vehicle-id vehicle-id (rows commands index.i.names))
  =/  next  fields
  =.  next
    ?~  found
      fields
    =/  value=json
      ?:  =(%model-year column.i.names)
        (j-scaled (cell-atom:view column.i.names u.found) 0)
      s+(cell-text:view column.i.names u.found)
    [[key.i.names value] fields]
  $(names t.names, fields next)
::
++  odometer-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['reading' (j-scaled (cell-atom:view %value-digits row) (cell-atom:view %decimal-places row))]
      ['unit' (j-term (cell-term:view %unit row))]
      ['observed' (j-da `@da`(cell-atom:view %observed-start row))]
      ['zone' s+(cell-text:view %source-zone row)]
  ==
::
++  standalone-odometer-json
  |=  [row=vector:ast vehicle-label=@t]
  ^-  json
  %-  object
  :~  ['vehicle' s+vehicle-label]
      ['reading' (j-scaled (cell-atom:view %value-digits row) (cell-atom:view %decimal-places row))]
      ['unit' (j-term (cell-term:view %unit row))]
      ['observed' (j-da `@da`(cell-atom:view %observed-start row))]
      ['zone' s+(cell-text:view %source-zone row)]
  ==
::
++  odometer-for-link
  |=  [parent-key=@tas parent=@ links=(list vector:ast) odometers=(list vector:ast)]
  ^-  (unit vector:ast)
  =/  link  (one-by parent-key parent links)
  ?~  link  ~
  (one-by %odometer-id (cell-atom:view %odometer-id u.link) odometers)
::
++  custom-value-json
  |=  [row=vector:ast type=@tas definitions=(list vector:ast)]
  ^-  json
  =/  field-id  (cell-atom:view %field-id row)
  =/  definition  (one-by %field-id field-id definitions)
  ?>  ?=(^ definition)
  =/  fields=(list [@t json])
    :~  ['label' s+(cell-text:view %label u.definition)]
        ['type' (j-term type)]
    ==
  =.  fields
    ?:  =(%text type)
      [['value' s+(cell-text:view %value row)] fields]
    ?:  =(%number type)
      %+  weld
        :~  ['value' (j-scaled (cell-atom:view %digits row) (cell-atom:view %decimals row))]
            ['unit' (j-term (cell-term:view %value-unit row))]
        ==
      fields
    [['value' [%b =(0 (cell-atom:view %value row))]] fields]
  (object (flop fields))
::
++  custom-values-json
  |=  [parent=@ commands=(list cmd-result:ast)]
  ^-  (list json)
  =/  definitions  (rows commands 50)
  ;:  weld
    %+  turn  (rows-by:view %parent-id parent (rows commands 53))
    |=  row=vector:ast
    (custom-value-json row %text definitions)
    %+  turn  (rows-by:view %parent-id parent (rows commands 52))
    |=  row=vector:ast
    (custom-value-json row %number definitions)
    %+  turn  (rows-by:view %parent-id parent (rows commands 54))
    |=  row=vector:ast
    (custom-value-json row %boolean definitions)
  ==
::
++  source-fields
  |=  [acquisition-id=@ commands=(list cmd-result:ast) fields=(list [@t json])]
  ^-  (list [@t json])
  =/  provenance  (one-by %acquisition-id acquisition-id (rows commands 58))
  ?~  provenance  fields
  %+  weld
    :~  ['sourceApp' (j-term (cell-term:view %source-app u.provenance))]
        ['sourceRecordId' s+(cell-text:view %source-record-id u.provenance)]
    ==
  fields
::
++  fill-json
  |=  [acquisition=vector:ast fill=vector:ast vehicle-label=@t distance-unit=@tas commands=(list cmd-result:ast)]
  ^-  json
  =/  acquisition-id  (cell-atom:view %acquisition-id acquisition)
  =/  definition-id  (cell-atom:view %energy-definition-id acquisition)
  =/  definition  (text-by %energy-definition-id definition-id %label (rows commands 3))
  =/  odometer  (odometer-for-link %acquisition-id acquisition-id (rows commands 65) (rows commands 2))
  =/  station-link  (one-by %acquisition-id acquisition-id (rows commands 11))
  =/  station=(unit @t)
    ?~  station-link  ~
    (text-by %station-id (cell-atom:view %station-id u.station-link) %label (rows commands 10))
  =/  subtype-link  (one-by %acquisition-id acquisition-id (rows commands 42))
  =/  subtype=(unit @t)
    ?~  subtype-link  ~
    (text-by %subtype-id (cell-atom:view %subtype-id u.subtype-link) %label (rows commands 12))
  =/  speed  (one-by %acquisition-id acquisition-id (rows commands 46))
  =/  balance  (one-by %acquisition-id acquisition-id (rows commands 47))
  =/  mode-link  (one-by %acquisition-id acquisition-id (rows commands 45))
  =/  mode=(unit @t)
    ?~  mode-link  ~
    (text-by %mode-id (cell-atom:view %mode-id u.mode-link) %label (rows commands 43))
  =/  note  (one-by %acquisition-id acquisition-id (rows commands 57))
  =/  payment-link  (one-by %acquisition-id acquisition-id (rows commands 56))
  =/  payment=(unit @t)
    ?~  payment-link  ~
    (text-by %method-id (cell-atom:view %method-id u.payment-link) %label (rows commands 55))
  =/  broken  (one-by %acquisition-id acquisition-id (rows commands 20))
  =/  missed=@t
    ?~  broken  'no'
    ?:  =(%missed-fill (cell-term:view %reason u.broken))  'yes'
    'no'
  =/  fields=(list [@t json])
    :~  ['vehicle' s+vehicle-label]
        ['definition' s+(need definition)]
        ['quantity' (j-scaled (cell-atom:view %quantity-milli fill) 3)]
        ['price' (j-scaled (cell-atom:view %unit-price-mills fill) 3)]
        ['profile' (j-term (cell-term:view %price-profile fill))]
        ['tank' (j-term (cell-term:view %tank-state fill))]
        ['settlement' (j-term (cell-term:view %settlement-mode fill))]
        ['observed' (j-da `@da`(cell-atom:view %observed-start acquisition))]
        ['zone' s+(cell-text:view %source-zone acquisition)]
        ['mileage' ?~(odometer s+'' (j-scaled (cell-atom:view %value-digits u.odometer) (cell-atom:view %decimal-places u.odometer)))]
        ['mileageUnit' ?~(odometer (j-term distance-unit) (j-term (cell-term:view %unit u.odometer)))]
        ['station' ?~(station s+'none' s+u.station)]
        ['additives' [%a (labels-for-links %acquisition-id acquisition-id %additive-id (rows commands 19) %additive-id %label (rows commands 18))]]
        ['subtype' ?~(subtype s+'' s+u.subtype)]
        ['missedFill' s+missed]
        ['drivingMode' ?~(mode s+'' s+u.mode)]
        ['averageSpeed' ?~(speed s+'' (j-scaled (cell-atom:view %digits u.speed) (cell-atom:view %decimals u.speed)))]
        ['speedUnit' ?~(speed s+'mph' (j-term (cell-term:view %speed-unit u.speed)))]
        ['driveBalance' ?~(balance s+'' s+(scot %ud (cell-atom:view %highway-percent u.balance)))]
        ['tags' [%a (labels-for-links %acquisition-id acquisition-id %tag-id (rows commands 49) %tag-id %label (rows commands 48))]]
        ['notes' ?~(note s+'' s+(cell-text:view %note u.note))]
        ['paymentMethod' ?~(payment s+'' s+u.payment)]
        ['customFields' [%a (custom-values-json acquisition-id commands)]]
    ==
  (object (flop (source-fields acquisition-id commands fields)))
::
++  cost-component-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['component' (j-term (cell-term:view %component row))]
      ['quantity' (j-scaled (cell-atom:view %quantity row) (cell-atom:view %quantity-decimals row))]
      ['unit' (j-term (cell-term:view %quantity-unit row))]
      ['rate' (j-scaled (cell-atom:view %rate-mills row) 3)]
      ['amount' (j-scaled (cell-atom:view %amount-mills row) 3)]
  ==
::
++  measurement-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['quantity' (j-scaled (cell-atom:view %quantity row) (cell-atom:view %decimals row))]
      ['unit' (j-term (cell-term:view %measure-unit row))]
      ['point' (j-term (cell-term:view %point row))]
      ['evidence' (j-term (cell-term:view %evidence row))]
  ==
::
++  energy-source-text
  |=  measurement=vector:ast
  ^-  @t
  =/  point  (cell-term:view %point measurement)
  =/  evidence  (cell-term:view %evidence measurement)
  ?:  =(%wall point)
    ?:  =(%measured evidence)  'wall-measured'
    'estimate'
  ?:  =(%charger point)
    ?:  =(%reported evidence)  'charger-reported'
    'estimate'
  ?:  =(%vehicle point)
    ?:  =(%vehicle-reported evidence)  'vehicle-reported'
    'estimate'
  'estimate'
::
++  battery-percent
  |=  [acquisition-id=@ endpoint=@tas commands=(list cmd-result:ast)]
  ^-  (unit vector:ast)
  =/  links  (rows-by:view %acquisition-id acquisition-id (rows commands 25))
  =/  link=(unit vector:ast)
    |-  ^-  (unit vector:ast)
    ?~  links  ~
    ?:  =(endpoint (cell-term:view %endpoint i.links))  `i.links
    $(links t.links)
  ?~  link  ~
  (one-by %battery-observation-id (cell-atom:view %battery-observation-id u.link) (rows commands 23))
::
++  charge-json
  |=  [acquisition=vector:ast vehicle-label=@t distance-unit=@tas commands=(list cmd-result:ast)]
  ^-  json
  =/  acquisition-id  (cell-atom:view %acquisition-id acquisition)
  =/  definition  (text-by %energy-definition-id (cell-atom:view %energy-definition-id acquisition) %label (rows commands 3))
  =/  measurements  (rows-by:view %acquisition-id acquisition-id (rows commands 21))
  =/  delivered=(unit vector:ast)  ?~(measurements ~ `i.measurements)
  =/  start-battery  (battery-percent acquisition-id %start commands)
  =/  end-battery  (battery-percent acquisition-id %end commands)
  =/  odometer  (odometer-for-link %acquisition-id acquisition-id (rows commands 65) (rows commands 2))
  =/  cost  (one-by %acquisition-id acquisition-id (rows commands 27))
  =/  source-total  (one-by %acquisition-id acquisition-id (rows commands 29))
  =/  subtype-link  (one-by %acquisition-id acquisition-id (rows commands 59))
  =/  subtype=(unit @t)
    ?~  subtype-link  ~
    (text-by %subtype-id (cell-atom:view %subtype-id u.subtype-link) %label (rows commands 12))
  %-  object
  :~  ['vehicle' s+vehicle-label]
      ['definition' s+(need definition)]
      ['start' (j-da `@da`(cell-atom:view %observed-start acquisition))]
      ['end' (j-da `@da`(cell-atom:view %observed-end acquisition))]
      ['zone' s+(cell-text:view %source-zone acquisition)]
      ['energyDelivered' ?~(delivered s+'' (j-scaled (cell-atom:view %quantity u.delivered) (cell-atom:view %decimals u.delivered)))]
      ['energySource' ?~(delivered s+'estimate' s+(energy-source-text u.delivered))]
      ['startBattery' ?~(start-battery s+'' (j-scaled (cell-atom:view %value-digits u.start-battery) (cell-atom:view %value-decimals u.start-battery)))]
      ['endBattery' ?~(end-battery s+'' (j-scaled (cell-atom:view %value-digits u.end-battery) (cell-atom:view %value-decimals u.end-battery)))]
      ['mileage' ?~(odometer s+'' (j-scaled (cell-atom:view %value-digits u.odometer) (cell-atom:view %decimal-places u.odometer)))]
      ['mileageUnit' ?~(odometer (j-term distance-unit) (j-term (cell-term:view %unit u.odometer)))]
      ['costState' ?~(cost s+'unknown' (j-term (cell-term:view %cost-state u.cost)))]
      ['currency' ?~(cost s+'usd' (j-term (cell-term:view %currency u.cost)))]
      ['components' [%a (turn (rows-by:view %acquisition-id acquisition-id (rows commands 28)) cost-component-json)]]
      ['sourceTotal' ?~(source-total s+'' (j-scaled (cell-atom:view %total-mills u.source-total) 3))]
      ['subtype' ?~(subtype s+'' s+u.subtype)]
      ['measurements' [%a (turn measurements measurement-json)]]
  ==
::
++  consumable-json
  |=  [acquisition=vector:ast vehicle-label=@t distance-unit=@tas commands=(list cmd-result:ast)]
  ^-  json
  =/  acquisition-id  (cell-atom:view %consumable-acquisition-id acquisition)
  =/  definition  (text-by %consumable-id (cell-atom:view %consumable-id acquisition) %label (rows commands 60))
  =/  purchase  (one-by %consumable-acquisition-id acquisition-id (rows commands 62))
  ?>  ?=(^ purchase)
  =/  odometer  (odometer-for-link %consumable-acquisition-id acquisition-id (rows commands 64) (rows commands 2))
  =/  station-link  (one-by %consumable-acquisition-id acquisition-id (rows commands 63))
  =/  station=(unit @t)
    ?~  station-link  ~
    (text-by %station-id (cell-atom:view %station-id u.station-link) %label (rows commands 10))
  %-  object
  :~  ['vehicle' s+vehicle-label]
      ['consumable' s+(need definition)]
      ['quantity' (j-scaled (cell-atom:view %quantity-milli u.purchase) 3)]
      ['price' (j-scaled (cell-atom:view %unit-price-mills u.purchase) 3)]
      ['profile' (j-term (cell-term:view %price-profile u.purchase))]
      ['settlement' (j-term (cell-term:view %settlement-mode u.purchase))]
      ['observed' (j-da `@da`(cell-atom:view %observed-start acquisition))]
      ['zone' s+(cell-text:view %source-zone acquisition)]
      ['mileage' ?~(odometer s+'' (j-scaled (cell-atom:view %value-digits u.odometer) (cell-atom:view %decimal-places u.odometer)))]
      ['mileageUnit' ?~(odometer (j-term distance-unit) (j-term (cell-term:view %unit u.odometer)))]
      ['station' ?~(station s+'none' s+u.station)]
  ==
::
++  event-kind
  |=  [event-id=@ commands=(list cmd-result:ast)]
  ^-  @tas
  ?:  (has-row %event-id event-id (rows commands 69))  %service
  ?:  (has-row %event-id event-id (rows commands 70))  %expense
  ?:  (has-row %event-id event-id (rows commands 71))  %note
  ?:  (has-row %event-id event-id (rows commands 72))  %acquisition
  %disposal
::
++  event-json
  |=  [row=vector:ast vehicle-label=@t distance-unit=@tas commands=(list cmd-result:ast)]
  ^-  json
  =/  event-id  (cell-atom:view %event-id row)
  =/  cost  (one-by %event-id event-id (rows commands 74))
  =/  total  (one-by %event-id event-id (rows commands 75))
  =/  odometer  (odometer-for-link %event-id event-id (rows commands 76) (rows commands 2))
  =/  station-link  (one-by %event-id event-id (rows commands 77))
  =/  station=(unit @t)
    ?~  station-link  ~
    (text-by %station-id (cell-atom:view %station-id u.station-link) %label (rows commands 10))
  =/  note  (one-by %event-id event-id (rows commands 80))
  =/  payment-link  (one-by %event-id event-id (rows commands 79))
  =/  payment=(unit @t)
    ?~  payment-link  ~
    (text-by %method-id (cell-atom:view %method-id u.payment-link) %label (rows commands 55))
  =/  disposal  (one-by %event-id event-id (rows commands 73))
  =/  disposal-kind=(unit @t)
    ?~  disposal  ~
    (text-by %disposal-kind-id (cell-atom:view %disposal-kind-id u.disposal) %label (rows commands 84))
  =/  total-text=json
    ?~  cost  s+''
    ?~  total  s+''
    =/  decimals  (cell-atom:view %minor-unit-decimals u.cost)
    =/  scale  (pow-ten:render decimals)
    =/  mills-per-minor  (div 1.000 scale)
    (j-scaled (div (cell-atom:view %total-mills u.total) mills-per-minor) decimals)
  %-  object
  :~  ['vehicle' s+vehicle-label]
      ['observed' (j-da `@da`(cell-atom:view %observed-start row))]
      ['zone' s+(cell-text:view %source-zone row)]
      ['currency' ?~(cost s+'usd' (j-term (cell-term:view %currency u.cost)))]
      ['total' total-text]
      ['mileage' ?~(odometer s+'' (j-scaled (cell-atom:view %value-digits u.odometer) (cell-atom:view %decimal-places u.odometer)))]
      ['mileageUnit' ?~(odometer (j-term distance-unit) (j-term (cell-term:view %unit u.odometer)))]
      ['station' ?~(station s+'none' s+u.station)]
      ['tags' [%a (labels-for-links %event-id event-id %tag-id (rows commands 78) %tag-id %label (rows commands 48))]]
      ['subtypes' [%a (labels-for-links %event-id event-id %service-subtype-id (rows commands 81) %service-subtype-id %label (rows commands 82))]]
      ['disposalKind' ?~(disposal-kind s+'' s+u.disposal-kind)]
      ['paymentMethod' ?~(payment s+'' s+u.payment)]
      ['notes' ?~(note s+'' s+(cell-text:view %note u.note))]
  ==
::
++  events-of-kind
  |=  [vehicle-id=@ kind=@tas vehicle-label=@t distance-unit=@tas commands=(list cmd-result:ast)]
  ^-  (list json)
  =/  events  (rows-by:view %vehicle-id vehicle-id (rows commands 68))
  =/  matched
    %+  skim  events
    |=  row=vector:ast
    =(kind (event-kind (cell-atom:view %event-id row) commands))
  %+  turn  matched
  |=  row=vector:ast
  (event-json row vehicle-label distance-unit commands)
::
++  reminder-json
  |=  [row=vector:ast vehicle-label=@t distance-unit=@tas commands=(list cmd-result:ast)]
  ^-  json
  =/  reminder-id  (cell-atom:view %reminder-id row)
  =/  subtype  (text-by %service-subtype-id (cell-atom:view %service-subtype-id row) %label (rows commands 82))
  =/  time  (one-by %reminder-id reminder-id (rows commands 86))
  =/  distance  (one-by %reminder-id reminder-id (rows commands 87))
  %-  object
  :~  ['vehicle' s+vehicle-label]
      ['subtype' s+(need subtype)]
      ['archived' (archived row)]
      ['timeInterval' ?~(time s+'' s+(scot %ud (cell-atom:view %interval-count u.time)))]
      ['timeUnit' ?~(time s+'month' (j-term (cell-term:view %interval-unit u.time)))]
      ['timeDue' ?~(time s+'' (j-day `@da`(cell-atom:view %due-at u.time)))]
      ['distanceInterval' ?~(distance s+'' (j-scaled (cell-atom:view %interval-digits u.distance) (cell-atom:view %interval-decimals u.distance)))]
      ['distanceDue' ?~(distance s+'' (j-scaled (cell-atom:view %due-digits u.distance) (cell-atom:view %due-decimals u.distance)))]
      ['distanceUnit' ?~(distance (j-term distance-unit) (j-term (cell-term:view %distance-unit u.distance)))]
  ==
::
++  vehicle-consumable-json
  |=  [row=vector:ast commands=(list cmd-result:ast)]
  ^-  json
  =/  label
    (text-by %consumable-id (cell-atom:view %consumable-id row) %label (rows commands 60))
  =/  vehicle-id  (cell-atom:view %vehicle-id row)
  =/  consumable-id  (cell-atom:view %consumable-id row)
  =/  tanks  (rows-by:view %vehicle-id vehicle-id (rows commands 67))
  =/  tank  (one-by %consumable-id consumable-id tanks)
  =/  fields=(list [@t json])
    :~  ['label' s+(need label)]
        ['archived' [%b =(0 (cell-atom:view %archived row))]]
    ==
  =.  fields
    ?~  tank  fields
    =/  tank-fields=(list [@t json])
      :~  ['value' (j-scaled (cell-atom:view %digits u.tank) (cell-atom:view %decimals u.tank))]
          ['unit' (j-term (cell-term:view %unit u.tank))]
      ==
    [['tankSize' (object tank-fields)] fields]
  (object (flop fields))
::
++  tank-json
  |=  row=vector:ast
  ^-  json
  %-  object
  :~  ['value' (j-scaled (cell-atom:view %digits row) (cell-atom:view %decimals row))]
      ['unit' (j-term (cell-term:view %size-unit row))]
  ==
::
++  vehicle-json
  |=  [row=vector:ast commands=(list cmd-result:ast)]
  ^-  json
  =/  vehicle-id  (cell-atom:view %vehicle-id row)
  =/  label  (cell-text:view %label row)
  =/  preference  (one-by %vehicle-id vehicle-id (rows commands 1))
  =/  distance-unit=@tas  ?~(preference %mi (cell-term:view %distance-unit u.preference))
  =/  default-link  (one-by %vehicle-id vehicle-id (rows commands 5))
  ?>  ?=(^ default-link)
  =/  default-id  (cell-atom:view %energy-definition-id u.default-link)
  =/  default-definition  (one-by %energy-definition-id default-id (rows commands 3))
  ?>  ?=(^ default-definition)
  =/  tank  (one-by %vehicle-id vehicle-id (rows commands 40))
  =/  reserve  (one-by %vehicle-id vehicle-id (rows commands 41))
  =/  default-subtype-link  (one-by %vehicle-id vehicle-id (rows commands 17))
  =/  default-subtype=(unit @t)
    ?~  default-subtype-link  ~
    (text-by %subtype-id (cell-atom:view %subtype-id u.default-subtype-link) %label (rows commands 12))
  =/  fills=(list json)
    =/  acquisitions  (rows-by:view %vehicle-id vehicle-id (rows commands 6))
    =/  selected
      %+  skim  acquisitions
      |=  acquisition=vector:ast
      (has-row %acquisition-id (cell-atom:view %acquisition-id acquisition) (rows commands 7))
    %+  turn  selected
    |=  acquisition=vector:ast
    =/  fill  (one-by %acquisition-id (cell-atom:view %acquisition-id acquisition) (rows commands 7))
    (fill-json acquisition (need fill) label distance-unit commands)
  =/  charges=(list json)
    =/  acquisitions  (rows-by:view %vehicle-id vehicle-id (rows commands 6))
    =/  selected
      %+  skim  acquisitions
      |=  acquisition=vector:ast
      (has-row %acquisition-id (cell-atom:view %acquisition-id acquisition) (rows commands 8))
    %+  turn  selected
    |=  acquisition=vector:ast
    (charge-json acquisition label distance-unit commands)
  =/  consumables=(list json)
    %+  turn  (rows-by:view %vehicle-id vehicle-id (rows commands 61))
    |=  acquisition=vector:ast
    (consumable-json acquisition label distance-unit commands)
  =/  reminders=(list json)
    %+  turn  (rows-by:view %vehicle-id vehicle-id (rows commands 85))
    |=  reminder=vector:ast
    (reminder-json reminder label distance-unit commands)
  =/  linked-odometers=(set @)
    =/  ids=(list @)
      ;:  weld
        (turn (rows commands 65) |=(link=vector:ast (cell-atom:view %odometer-id link)))
        (turn (rows commands 64) |=(link=vector:ast (cell-atom:view %odometer-id link)))
        (turn (rows commands 76) |=(link=vector:ast (cell-atom:view %odometer-id link)))
      ==
    (silt ids)
  =/  standalone
    %+  skim  (rows-by:view %vehicle-id vehicle-id (rows commands 2))
    |=  odometer=vector:ast
    =(%.n (~(has in linked-odometers) (cell-atom:view %odometer-id odometer)))
  =/  energy-links  (rows-by:view %vehicle-id vehicle-id (rows commands 4))
  =/  mode-links  (rows-by:view %vehicle-id vehicle-id (rows commands 44))
  =/  vehicle-consumables  (rows-by:view %vehicle-id vehicle-id (rows commands 66))
  =/  volume-unit=@tas
    ?^  tank
      (cell-term:view %size-unit u.tank)
    ?:  =(%reservoir (cell-term:view %physical-kind u.default-definition))
      (cell-term:view %quantity-unit u.default-definition)
    %gal
  =/  fields=(list [@t json])
    :~  ['label' s+label]
        ['archived' (archived row)]
        ['distanceUnit' (j-term distance-unit)]
        ['volumeUnit' (j-term volume-unit)]
        ['defaultEnergy' s+(cell-text:view %label u.default-definition)]
        ['additionalEnergy' [%a (labels-for-links %vehicle-id vehicle-id %energy-definition-id energy-links %energy-definition-id %label (rows commands 3))]]
        ['drivingModes' [%a (labels-for-links %vehicle-id vehicle-id %mode-id mode-links %mode-id %label (rows commands 43))]]
        ['fills' [%a fills]]
        ['chargingSessions' [%a charges]]
        ['consumableAcquisitions' [%a consumables]]
        ['serviceEvents' [%a (events-of-kind vehicle-id %service label distance-unit commands)]]
        ['expenseEvents' [%a (events-of-kind vehicle-id %expense label distance-unit commands)]]
        ['noteEvents' [%a (events-of-kind vehicle-id %note label distance-unit commands)]]
        ['acquisitionEvents' [%a (events-of-kind vehicle-id %acquisition label distance-unit commands)]]
        ['disposalEvents' [%a (events-of-kind vehicle-id %disposal label distance-unit commands)]]
        ['reminders' [%a reminders]]
        ['odometerReadings' [%a (turn standalone |=(odometer=vector:ast (standalone-odometer-json odometer label)))]]
        ['specification' (spec-json vehicle-id commands)]
        ['consumables' [%a (turn vehicle-consumables |=(link=vector:ast (vehicle-consumable-json link commands)))]]
    ==
  =.  fields
    ?~  tank
      fields
    [['tankSize' (tank-json u.tank)] fields]
  =.  fields
    ?~(reserve fields [['refillReserve' s+(scot %ud (cell-atom:view %reserve-percent u.reserve))] fields])
  =.  fields
    ?~(default-subtype fields [['defaultSubtype' s+u.default-subtype] fields])
  (object (flop fields))
::
++  vehicles-json
  |=  commands=(list cmd-result:ast)
  ^-  (list json)
  %+  turn  (rows commands 0)
  |=  row=vector:ast
  (vehicle-json row commands)
::
++  document
  |=  commands=(list cmd-result:ast)
  ^-  @t
  =/  payload=json
    %-  object
    :~  ['rover-import' n+'1']
        ['source' source-json]
        ['definitions' (definitions-json commands)]
        ['places' [%a (places-json commands)]]
        ['vehicles' [%a (vehicles-json commands)]]
    ==
  (en:json:html payload)
--
