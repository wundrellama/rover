::  lib/rover-entry - decode human entry JSON into canonical Rover intent.
::
::  All decimal and date strings are validated here. Named verdicts identify
::  the human-facing field; no raw database ID is accepted by this boundary.
::
/-  rover
/+  render=rover-render
|%
+$  price-proof
  $:  unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
  ==
::
++  json-string
  |=  [key=@t object=(map @t json)]
  ^-  (unit @t)
  =/  value  (~(get by object) key)
  ?~  value
    ~
  ?.  ?=(%s -.u.value)
    ~
  `+.u.value
::
++  json-strings
  |=  [key=@t object=(map @t json)]
  ^-  (unit (list @t))
  =/  value  (~(get by object) key)
  ?~  value
    ~
  ?.  ?=(%a -.u.value)
    ~
  =/  values=(list json)  +.u.value
  =/  texts=(list @t)  ~
  |-
  ?~  values
    `(flop texts)
  ?.  ?=(%s -.i.values)
    ~
  $(values t.values, texts [+.i.values texts])
::
++  json-object
  |=  body=@t
  ^-  (unit (map @t json))
  =/  parsed  (de:json:html body)
  ?~  parsed
    ~
  ?.  ?=(%o -.u.parsed)
    ~
  `+.u.parsed
::
++  local-da
  |=  txt=@t
  ^-  (unit @da)
  =/  tap=tape  (trip txt)
  ?.  =(16 (lent tap))
    ~
  ?.  ?&  =('-' (snag 4 tap))
          =('-' (snag 7 tap))
          =('T' (snag 10 tap))
          =(':' (snag 13 tap))
      ==
    ~
  =/  digits
    %+  skip  tap
    |=  char=@t
    ?|  =('-' char)
        =('T' char)
        =(':' char)
    ==
  ?.  (levy digits |=(char=@t &((gte char '0') (lte char '9'))))
    ~
  =/  da-text
    %-  crip
    ;:  weld
      "~"
      (scag 4 tap)
      "."
      (scag 2 (slag 5 tap))
      "."
      (scag 2 (slag 8 tap))
      ".."
      (scag 2 (slag 11 tap))
      "."
      (scag 2 (slag 14 tap))
      ".00"
    ==
  =/  parsed  (slaw %da da-text)
  ?~  parsed
    ~
  `u.parsed
::
++  nonempty
  |=  value=@t
  ^-  ?
  ?=(^ (trim-spaces:render (trip value)))
::
++  decode-fill
  |=  body=@t
  ^-  (each fill-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'fill']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'fill']
  =/  object=(map @t json)  +.u.parsed
  =/  vehicle  (json-string 'vehicle' object)
  ?~  vehicle
    [%| %missing-key 'fill.vehicle']
  ?.  (nonempty u.vehicle)
    [%| %bad-shape 'fill.vehicle']
  =/  definition  (json-string 'definition' object)
  ?~  definition
    [%| %missing-key 'fill.definition']
  ?.  (nonempty u.definition)
    [%| %bad-shape 'fill.definition']
  =/  quantity  (json-string 'quantity' object)
  ?~  quantity
    [%| %missing-key 'fill.quantity']
  =/  parsed-quantity  (parse-decimal:render u.quantity 3)
  ?:  ?=(%| -.parsed-quantity)
    [%| p.parsed-quantity 'fill.quantity']
  =/  quantity-scale
    (pow-ten:render (sub 3 places.p.parsed-quantity))
  =/  quantity-milli=@ud
    (mul digits.p.parsed-quantity quantity-scale)
  ?.  (gth quantity-milli 0)
    [%| %bad-range 'fill.quantity']
  =/  price  (json-string 'price' object)
  ?~  price
    [%| %missing-key 'fill.price']
  =/  profile  (json-string 'profile' object)
  ?~  profile
    [%| %missing-key 'fill.profile']
  =/  price-proof
    ^-  (each price-proof ?(%bad-shape %excess-precision))
    ?:  =('us-usd-gal' u.profile)
      =/  decoded  (parse-us-price:render u.price)
      ?:  ?=(%| -.decoded)
        [%| p.decoded]
      [%& unit-price-mills.p.decoded display.p.decoded %usd %us-usd-gal 2 50]
    ?:  =('eu-eur-litre' u.profile)
      =/  decoded  (parse-decimal:render u.price 3)
      ?:  ?=(%| -.decoded)
        [%| p.decoded]
      =/  mills
        (mul digits.p.decoded (pow-ten:render (sub 3 places.p.decoded)))
      [%& mills (format-unit-price:render mills %eur) %eur %eu-eur-litre 2 0]
    [%| %bad-shape]
  ?:  ?=(%| -.price-proof)
    [%| p.price-proof 'fill.price']
  =/  tank  (json-string 'tank' object)
  ?~  tank
    [%| %missing-key 'fill.tank']
  =/  tank-term  (slaw %tas u.tank)
  ?.  ?&  ?=(^ tank-term)
          ?|  =(%full u.tank-term)
              =(%partial u.tank-term)
          ==
      ==
    [%| %bad-shape 'fill.tank']
  =/  tank-state=tank-state:rover
    ;;(tank-state:rover u.tank-term)
  =/  settlement  (json-string 'settlement' object)
  ?~  settlement
    [%| %missing-key 'fill.settlement']
  =/  settlement-term  (slaw %tas u.settlement)
  ?.  ?&  ?=(^ settlement-term)
          ?|  =(%standard u.settlement-term)
              =(%cash u.settlement-term)
          ==
      ==
    [%| %bad-shape 'fill.settlement']
  =/  settlement-mode=settlement-mode:rover
    ;;(settlement-mode:rover u.settlement-term)
  =/  observed  (json-string 'observed' object)
  ?~  observed
    [%| %missing-key 'fill.observed']
  =/  observed-start  (local-da u.observed)
  ?~  observed-start
    [%| %bad-shape 'fill.observed']
  =/  zone  (json-string 'zone' object)
  ?~  zone
    [%| %missing-key 'fill.zone']
  ?.  (nonempty u.zone)
    [%| %bad-shape 'fill.zone']
  =/  mileage-text  (json-string 'mileage' object)
  ?~  mileage-text
    [%| %missing-key 'fill.mileage']
  =/  mileage=(unit odo-reading:rover)
    ?:  =(0 (lent (trim-spaces:render (trip u.mileage-text))))
      ~
    =/  parsed-mileage  (parse-decimal:render u.mileage-text 3)
    ?:  ?=(%| -.parsed-mileage)
      ~
    =/  mileage-unit  (json-string 'mileageUnit' object)
    ?~  mileage-unit
      ~
    =/  unit-term  (slaw %tas u.mileage-unit)
    ?.  ?&  ?=(^ unit-term)
            ?|  =(%mi u.unit-term)
                =(%km u.unit-term)
            ==
        ==
      ~
    =/  odo-unit=distance-unit:rover
      ;;(distance-unit:rover u.unit-term)
    `[digits.p.parsed-mileage places.p.parsed-mileage odo-unit]
  ?:  ?&  (gth (lent (trim-spaces:render (trip u.mileage-text))) 0)
          ?=(~ mileage)
      ==
    [%| %bad-shape 'fill.mileage']
  =/  station  (json-string 'station' object)
  ?~  station
    [%| %missing-key 'fill.station']
  =/  station-label=(unit @t)
    ?:  =('none' u.station)
      ~
    ?:  =('new' u.station)
      ~
    ?.  (nonempty u.station)
      ~
    `u.station
  =/  new-station=(unit new-station-entry:rover)
    ?.  =('new' u.station)
      ~
    =/  station-name  (json-string 'newStationLabel' object)
    ?~  station-name
      ~
    ?.  (nonempty u.station-name)
      ~
    =/  place-name  (json-string 'newPlaceLabel' object)
    ?~  place-name
      ~
    ?.  (nonempty u.place-name)
      ~
    =/  kind  (json-string 'newStationKind' object)
    ?~  kind
      ~
    =/  kind-term  (slaw %tas u.kind)
    ?.  ?&  ?=(^ kind-term)
            ?|  =(%private u.kind-term)
                =(%fuel u.kind-term)
                =(%charging u.kind-term)
                =(%mixed u.kind-term)
            ==
        ==
      ~
    `[u.place-name u.station-name ;;(station-kind:rover u.kind-term)]
  ?:  ?&  =('new' u.station)
          ?=(~ new-station)
      ==
    [%| %bad-shape 'fill.station']
  ?:  ?&  !=('none' u.station)
          !=('new' u.station)
          ?=(~ station-label)
      ==
    [%| %bad-shape 'fill.station']
  =/  additive-labels  (json-strings 'additives' object)
  ?~  additive-labels
    [%| %missing-key 'fill.additives']
  ?.  (levy u.additive-labels nonempty)
    [%| %bad-shape 'fill.additives']
  =/  subtype-text  (json-string 'subtype' object)
  =/  subtype-label=(unit @t)
    ?~  subtype-text
      ~
    ?:  (nonempty u.subtype-text)
      `u.subtype-text
    ~
  =/  missed-text  (json-string 'missedFill' object)
  =/  missed-fill=?
    ?~  missed-text
      %.n
    =('yes' u.missed-text)
  =/  mode-text  (json-string 'drivingMode' object)
  =/  driving-mode-label=(unit @t)
    ?~  mode-text
      ~
    ?:  (nonempty u.mode-text)
      `u.mode-text
    ~
  =/  speed-text  (json-string 'averageSpeed' object)
  =/  average-speed=(unit scaled-entry:rover)
    ?~  speed-text
      ~
    ?.  (nonempty u.speed-text)
      ~
    =/  parsed-speed  (parse-decimal:render u.speed-text 3)
    ?:  ?=(%| -.parsed-speed)
      ~
    =/  speed-unit-text  (json-string 'speedUnit' object)
    ?~  speed-unit-text
      ~
    =/  speed-unit  (slaw %tas u.speed-unit-text)
    ?~  speed-unit
      ~
    `[digits.p.parsed-speed places.p.parsed-speed u.speed-unit]
  ?:  ?&  ?=(^ speed-text)
          (nonempty u.speed-text)
          ?=(~ average-speed)
      ==
    [%| %bad-shape 'fill.average-speed']
  =/  balance-text  (json-string 'driveBalance' object)
  =/  drive-balance=(unit @ud)
    ?~  balance-text
      ~
    ?.  (nonempty u.balance-text)
      ~
    =/  parsed-balance  (slaw %ud u.balance-text)
    ?~  parsed-balance
      ~
    ?:  (lte u.parsed-balance 100)
      `u.parsed-balance
    ~
  ?:  ?&  ?=(^ balance-text)
          (nonempty u.balance-text)
          ?=(~ drive-balance)
      ==
    [%| %bad-range 'fill.drive-balance']
  =/  tag-labels  (json-strings 'tags' object)
  =/  safe-tag-labels=(list @t)
    ?~  tag-labels
      ~
    u.tag-labels
  ?.  (levy safe-tag-labels nonempty)
    [%| %bad-shape 'fill.tags']
  =/  new-tag-text  (json-string 'newTag' object)
  =/  new-tag-label=(unit @t)
    ?~  new-tag-text
      ~
    ?:  (nonempty u.new-tag-text)
      `u.new-tag-text
    ~
  :-  %&
  :*  u.vehicle
      u.definition
      quantity-milli
      unit-price-mills.p.price-proof
      price-display.p.price-proof
      currency.p.price-proof
      price-profile.p.price-proof
      minor-unit-decimals.p.price-proof
      cash-increment-mills.p.price-proof
      tank-state
      settlement-mode
      u.observed-start
      u.zone
      mileage
      station-label
      new-station
      u.additive-labels
      subtype-label
      missed-fill
      driving-mode-label
      average-speed
      drive-balance
      safe-tag-labels
      new-tag-label
  ==
::
++  decode-odometer
  |=  body=@t
  ^-  (each odometer-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'odometer']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'odometer']
  =/  object=(map @t json)  +.u.parsed
  =/  vehicle  (json-string 'vehicle' object)
  ?~  vehicle
    [%| %missing-key 'odometer.vehicle']
  ?.  (nonempty u.vehicle)
    [%| %bad-shape 'odometer.vehicle']
  =/  reading  (json-string 'reading' object)
  ?~  reading
    [%| %missing-key 'odometer.reading']
  =/  parsed-reading  (parse-decimal:render u.reading 3)
  ?:  ?=(%| -.parsed-reading)
    [%| p.parsed-reading 'odometer.reading']
  =/  unit  (json-string 'unit' object)
  ?~  unit
    [%| %missing-key 'odometer.unit']
  =/  unit-term  (slaw %tas u.unit)
  ?.  ?&  ?=(^ unit-term)
          ?|  =(%mi u.unit-term)
              =(%km u.unit-term)
          ==
      ==
    [%| %bad-shape 'odometer.unit']
  =/  odo-unit=distance-unit:rover
    ;;(distance-unit:rover u.unit-term)
  =/  observed  (json-string 'observed' object)
  ?~  observed
    [%| %missing-key 'odometer.observed']
  =/  observed-start  (local-da u.observed)
  ?~  observed-start
    [%| %bad-shape 'odometer.observed']
  =/  zone  (json-string 'zone' object)
  ?~  zone
    [%| %missing-key 'odometer.zone']
  ?.  (nonempty u.zone)
    [%| %bad-shape 'odometer.zone']
  [%& u.vehicle [digits.p.parsed-reading places.p.parsed-reading odo-unit] u.observed-start u.zone]
::
++  decode-charge
  |=  body=@t
  ^-  (each charge-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'charge']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'charge']
  =/  object=(map @t json)  +.u.parsed
  =/  vehicle  (json-string 'vehicle' object)
  ?~  vehicle
    [%| %missing-key 'charge.vehicle']
  ?.  (nonempty u.vehicle)
    [%| %bad-shape 'charge.vehicle']
  =/  definition  (json-string 'definition' object)
  ?~  definition
    [%| %missing-key 'charge.definition']
  ?.  (nonempty u.definition)
    [%| %bad-shape 'charge.definition']
  =/  start  (json-string 'start' object)
  ?~  start
    [%| %missing-key 'charge.start']
  =/  observed-start  (local-da u.start)
  ?~  observed-start
    [%| %bad-shape 'charge.start']
  =/  end  (json-string 'end' object)
  ?~  end
    [%| %missing-key 'charge.end']
  =/  observed-end  (local-da u.end)
  ?~  observed-end
    [%| %bad-shape 'charge.end']
  ?.  (gth u.observed-end u.observed-start)
    [%| %bad-range 'charge.end']
  =/  zone  (json-string 'zone' object)
  ?~  zone
    [%| %missing-key 'charge.zone']
  ?.  (nonempty u.zone)
    [%| %bad-shape 'charge.zone']
  =/  energy-text  (json-string 'energyDelivered' object)
  ?~  energy-text
    [%| %missing-key 'charge.energy-delivered']
  =/  energy-source  (json-string 'energySource' object)
  ?~  energy-source
    [%| %missing-key 'charge.energy-source']
  =/  delivered=(unit delivered-energy:rover)
    ?:  =(0 (lent (trim-spaces:render (trip u.energy-text))))
      ~
    =/  energy  (parse-decimal:render u.energy-text 3)
    ?:  ?=(%| -.energy)
      ~
    ?.  (gth digits.p.energy 0)
      ~
    ?:  =('wall-measured' u.energy-source)
      `[digits.p.energy places.p.energy %wall %measured]
    ?:  =('charger-reported' u.energy-source)
      `[digits.p.energy places.p.energy %charger %reported]
    ?:  =('vehicle-reported' u.energy-source)
      `[digits.p.energy places.p.energy %vehicle %vehicle-reported]
    ?:  =('estimate' u.energy-source)
      `[digits.p.energy places.p.energy %estimate %estimated]
    ~
  ?:  ?&  (gth (lent (trim-spaces:render (trip u.energy-text))) 0)
          ?=(~ delivered)
      ==
    [%| %bad-shape 'charge.energy-delivered']
  =/  start-text  (json-string 'startBattery' object)
  ?~  start-text
    [%| %missing-key 'charge.start-battery']
  =/  start-battery=(unit battery-reading:rover)
    ?:  =(0 (lent (trim-spaces:render (trip u.start-text))))
      ~
    =/  level  (parse-decimal:render u.start-text 2)
    ?:  ?=(%| -.level)
      ~
    ?.  (lte digits.p.level (mul 100 (pow-ten:render places.p.level)))
      ~
    `[digits.p.level places.p.level]
  ?:  ?&  (gth (lent (trim-spaces:render (trip u.start-text))) 0)
          ?=(~ start-battery)
      ==
    [%| %bad-shape 'charge.start-battery']
  =/  end-text  (json-string 'endBattery' object)
  ?~  end-text
    [%| %missing-key 'charge.end-battery']
  =/  end-battery=(unit battery-reading:rover)
    ?:  =(0 (lent (trim-spaces:render (trip u.end-text))))
      ~
    =/  level  (parse-decimal:render u.end-text 2)
    ?:  ?=(%| -.level)
      ~
    ?.  (lte digits.p.level (mul 100 (pow-ten:render places.p.level)))
      ~
    `[digits.p.level places.p.level]
  ?:  ?&  (gth (lent (trim-spaces:render (trip u.end-text))) 0)
          ?=(~ end-battery)
      ==
    [%| %bad-shape 'charge.end-battery']
  =/  mileage-text  (json-string 'mileage' object)
  ?~  mileage-text
    [%| %missing-key 'charge.mileage']
  =/  mileage-unit  (json-string 'mileageUnit' object)
  ?~  mileage-unit
    [%| %missing-key 'charge.mileage-unit']
  =/  mileage=(unit odo-reading:rover)
    ?:  =(0 (lent (trim-spaces:render (trip u.mileage-text))))
      ~
    =/  reading  (parse-decimal:render u.mileage-text 3)
    ?:  ?=(%| -.reading)
      ~
    =/  unit-term  (slaw %tas u.mileage-unit)
    ?.  ?&  ?=(^ unit-term)
            ?|  =(%mi u.unit-term)
                =(%km u.unit-term)
            ==
        ==
      ~
    `[digits.p.reading places.p.reading ;;(distance-unit:rover u.unit-term)]
  ?:  ?&  (gth (lent (trim-spaces:render (trip u.mileage-text))) 0)
          ?=(~ mileage)
      ==
    [%| %bad-shape 'charge.mileage']
  =/  cost  (json-string 'costState' object)
  ?~  cost
    [%| %missing-key 'charge.cost-state']
  =/  cost-term  (slaw %tas u.cost)
  ?.  ?&  ?=(^ cost-term)
          ?|  =(%free u.cost-term)
              =(%unknown u.cost-term)
          ==
      ==
    [%| %bad-shape 'charge.cost-state']
  =/  currency-text  (json-string 'currency' object)
  ?~  currency-text
    [%| %missing-key 'charge.currency']
  =/  currency-term  (slaw %tas u.currency-text)
  ?.  ?&  ?=(^ currency-term)
          ?|  =(%usd u.currency-term)
              =(%eur u.currency-term)
          ==
      ==
    [%| %bad-shape 'charge.currency']
  :-  %&
  :*  u.vehicle
      u.definition
      u.observed-start
      u.observed-end
      u.zone
      delivered
      start-battery
      end-battery
      mileage
      ;;(cost-state:rover u.cost-term)
      ;;(currency:rover u.currency-term)
  ==
::
++  decode-preference
  |=  body=@t
  ^-  (each preference-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'preference']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'preference']
  =/  object=(map @t json)  +.u.parsed
  =/  vehicle  (json-string 'vehicle' object)
  ?~  vehicle
    [%| %missing-key 'preference.vehicle']
  ?.  (nonempty u.vehicle)
    [%| %bad-shape 'preference.vehicle']
  =/  distance  (json-string 'distanceUnit' object)
  ?~  distance
    [%| %missing-key 'preference.distance-unit']
  =/  distance-unit=(unit distance-unit:rover)
    ?:  =('native' u.distance)
      ~
    =/  distance-term  (slaw %tas u.distance)
    ?.  ?&  ?=(^ distance-term)
            ?|  =(%mi u.distance-term)
                =(%km u.distance-term)
            ==
        ==
      ~
    `;;(distance-unit:rover u.distance-term)
  ?:  ?&  !=('native' u.distance)
          ?=(~ distance-unit)
      ==
    [%| %bad-shape 'preference.distance-unit']
  =/  currency-text  (json-string 'currency' object)
  ?~  currency-text
    [%| %missing-key 'preference.currency']
  =/  currency-term  (slaw %tas u.currency-text)
  ?.  ?&  ?=(^ currency-term)
          ?|  =(%usd u.currency-term)
              =(%eur u.currency-term)
          ==
      ==
    [%| %bad-shape 'preference.currency']
  [%& u.vehicle distance-unit ;;(currency:rover u.currency-term)]
::
++  decode-vehicle-label
  |=  body=@t
  ^-  (each vehicle-label-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'vehicle']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'vehicle']
  =/  object=(map @t json)  +.u.parsed
  =/  vehicle  (json-string 'vehicle' object)
  ?~  vehicle
    [%| %missing-key 'vehicle.vehicle']
  ?.  (nonempty u.vehicle)
    [%| %bad-shape 'vehicle.vehicle']
  [%& u.vehicle]
::
++  decode-new-vehicle
  |=  body=@t
  ^-  (each new-vehicle-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'vehicle']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'vehicle']
  =/  object=(map @t json)  +.u.parsed
  =/  label  (json-string 'label' object)
  ?~  label
    [%| %missing-key 'vehicle.label']
  ?.  (nonempty u.label)
    [%| %bad-shape 'vehicle.label']
  =/  energy  (json-string 'energy' object)
  ?~  energy
    [%| %missing-key 'vehicle.energy-source']
  ?.  (nonempty u.energy)
    [%| %bad-shape 'vehicle.energy-source']
  [%& u.label u.energy]
::
++  decode-vehicle-edit
  |=  body=@t
  ^-  (each vehicle-edit-entry:rover entry-verdict:rover)
  =/  object  (json-object body)
  ?~  object
    [%| %bad-shape 'vehicle']
  =/  vehicle  (json-string 'vehicle' u.object)
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ vehicle)
          ?=(~ label)
      ==
    [%| %missing-key 'vehicle.label']
  ?.  ?&  (nonempty u.vehicle)
          (nonempty u.label)
      ==
    [%| %bad-shape 'vehicle.label']
  =/  tank-text  (json-string 'tankSize' u.object)
  =/  tank-unit-text  (json-string 'tankUnit' u.object)
  =/  tank-size=(unit scaled-entry:rover)
    ?~  tank-text
      ~
    ?.  (nonempty u.tank-text)
      ~
    =/  parsed  (parse-decimal:render u.tank-text 3)
    ?:  ?=(%| -.parsed)
      ~
    =/  unit  ?~(tank-unit-text ~ (slaw %tas u.tank-unit-text))
    ?~  unit
      ~
    ?:  ?|  =(%gal u.unit)
            =(%litre u.unit)
        ==
      `[digits.p.parsed places.p.parsed u.unit]
    ~
  ?:  ?&  ?=(^ tank-text)
          (nonempty u.tank-text)
          ?=(~ tank-size)
      ==
    [%| %bad-shape 'vehicle.tank-size']
  =/  subtype-text  (json-string 'defaultSubtype' u.object)
  =/  default-subtype=(unit @t)
    ?~  subtype-text
      ~
    ?.  (nonempty u.subtype-text)
      ~
    `u.subtype-text
  [%& u.vehicle u.label tank-size default-subtype]
::
++  decode-custom-definition
  |=  body=@t
  ^-  (each custom-definition-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'custom-field']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'custom-field']
  =/  object=(map @t json)  +.u.parsed
  =/  label  (json-string 'label' object)
  ?~  label
    [%| %missing-key 'custom-field.label']
  ?.  (nonempty u.label)
    [%| %bad-shape 'custom-field.label']
  =/  content  (json-string 'contentType' object)
  ?~  content
    [%| %missing-key 'custom-field.content-type']
  =/  content-term  (slaw %tas u.content)
  ?.  ?&  ?=(^ content-term)
          ?|  =(%number u.content-term)
              =(%text u.content-term)
              =(%boolean u.content-term)
          ==
      ==
    [%| %bad-shape 'custom-field.content-type']
  =/  mandatory-text  (json-string 'mandatory' object)
  =/  mandatory  ?:(?=(^ mandatory-text) =('yes' u.mandatory-text) %.n)
  [%& u.label u.content-term mandatory]
::
++  decode-custom-field-change
  |=  body=@t
  ^-  (each custom-field-change-entry:rover entry-verdict:rover)
  =/  decoded  (decode-custom-definition body)
  ?:  ?=(%| -.decoded)
    decoded
  [%& label.p.decoded content-type.p.decoded]
::
++  decode-custom-field-label
  |=  body=@t
  ^-  (each custom-field-label-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'custom-field']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'custom-field']
  =/  object=(map @t json)  +.u.parsed
  =/  label  (json-string 'label' object)
  ?~  label
    [%| %missing-key 'custom-field.label']
  ?.  (nonempty u.label)
    [%| %bad-shape 'custom-field.label']
  [%& u.label]
--
