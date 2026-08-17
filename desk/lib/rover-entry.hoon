::  lib/rover-entry - decode human entry JSON into canonical Rover intent.
::
::  All decimal and date strings are validated here. Named verdicts identify
::  the human-facing field; no raw database ID is accepted by this boundary.
::
/-  rover
/+  act=rover-act, render=rover-render
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
++  json-array
  |=  [key=@t object=(map @t json)]
  ^-  (unit (list json))
  =/  value  (~(get by object) key)
  ?~  value
    ~
  ?.  ?=(%a -.u.value)
    ~
  `+.u.value
::
++  json-map
  |=  value=json
  ^-  (unit (map @t json))
  ?.  ?=(%o -.value)
    ~
  `+.value
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
++  optional-text
  |=  [key=@t object=(map @t json)]
  ^-  (unit @t)
  =/  value  (json-string key object)
  ?~  value
    ~
  ?:  (nonempty u.value)
    value
  ~
::
++  decode-mills
  |=  [key=@t field=@t object=(map @t json)]
  ^-  (each @ud entry-verdict:rover)
  =/  text  (json-string key object)
  ?~  text
    [%| %missing-key field]
  =/  parsed  (parse-decimal:render u.text 3)
  ?:  ?=(%| -.parsed)
    [%| %bad-shape field]
  [%& (mul digits.p.parsed (pow-ten:render (sub 3 places.p.parsed)))]
::
++  decode-charging-components
  |=  values=(list json)
  ^-  (each (list charging-component-entry:rover) entry-verdict:rover)
  =/  rows=(list charging-component-entry:rover)  ~
  |-
  ?~  values
    [%& (flop rows)]
  =/  fields  (json-map i.values)
  ?~  fields
    [%| %bad-shape 'charge.components']
  =/  kind  (json-string 'component' u.fields)
  ?~  kind
    [%| %missing-key 'charge.component']
  =/  kind-term  (slaw %tas u.kind)
  ?.  ?&  ?=(^ kind-term)
          ?|  =(%energy u.kind-term)
              =(%time u.kind-term)
              =(%session u.kind-term)
              =(%idle u.kind-term)
              =(%tax u.kind-term)
              =(%discount u.kind-term)
          ==
      ==
    [%| %bad-shape 'charge.component']
  =/  quantity-text  (json-string 'quantity' u.fields)
  ?~  quantity-text
    [%| %missing-key 'charge.component-quantity']
  =/  quantity  (parse-decimal:render u.quantity-text 3)
  ?:  ?=(%| -.quantity)
    [%| %bad-shape 'charge.component-quantity']
  =/  unit-text  (json-string 'unit' u.fields)
  ?~  unit-text
    [%| %missing-key 'charge.component-unit']
  =/  unit-term  (slaw %tas u.unit-text)
  ?.  ?&  ?=(^ unit-term)
          ?|  =(%kwh u.unit-term)
              =(%minute u.unit-term)
              =(%session u.unit-term)
          ==
      ==
    [%| %bad-shape 'charge.component-unit']
  =/  rate  (decode-mills 'rate' 'charge.component-rate' u.fields)
  ?:  ?=(%| -.rate)
    [%| p.rate]
  =/  amount  (decode-mills 'amount' 'charge.component-amount' u.fields)
  ?:  ?=(%| -.amount)
    [%| p.amount]
  =/  row=charging-component-entry:rover
    :*  ;;(cost-component:rover u.kind-term)
        digits.p.quantity
        places.p.quantity
        ;;(cost-quantity-unit:rover u.unit-term)
        p.rate
        p.amount
    ==
  $(values t.values, rows [row rows])
::
++  parse-coordinate
  |=  txt=@t
  ^-  (unit @sd)
  =/  chars  (trim-spaces:render (trip txt))
  ?~  chars
    ~
  =/  positive  !=('-' i.chars)
  =/  magnitude-text
    ?:  positive
      chars
    t.chars
  ?~  magnitude-text
    ~
  =/  parsed  (parse-decimal:render (crip magnitude-text) 7)
  ?:  ?=(%| -.parsed)
    ~
  =/  scaled
    (mul digits.p.parsed (pow-ten:render (sub 7 places.p.parsed)))
  `(new:si positive scaled)
::
++  decode-fill
  |=  body=@t
  ^-  (each fill-entry:rover entry-verdict:rover)
  =/  object  (json-object body)
  ?~  object
    [%| %bad-shape 'fill']
  (decode-fill-object u.object)
::
++  decode-fill-object
  |=  object=(map @t json)
  ^-  (each fill-entry:rover entry-verdict:rover)
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
    =/  formatted  (optional-text 'newAddressFormatted' object)
    =/  line1  (optional-text 'newAddressLine1' object)
    =/  line2  (optional-text 'newAddressLine2' object)
    =/  locality  (optional-text 'newLocality' object)
    =/  region  (optional-text 'newRegion' object)
    =/  postal-code  (optional-text 'newPostalCode' object)
    =/  country  (optional-text 'newCountry' object)
    =/  any-part
      ?|  ?=(^ line1)
          ?=(^ line2)
          ?=(^ locality)
          ?=(^ region)
          ?=(^ postal-code)
          ?=(^ country)
      ==
    =/  address=(unit station-address-entry:rover)
      ?.  ?|  ?=(^ formatted)
              any-part
          ==
        ~
      `[formatted line1 line2 locality region postal-code country]
    =/  latitude-text  (optional-text 'newLatitude' object)
    =/  longitude-text  (optional-text 'newLongitude' object)
    ?:  !=(?=(~ latitude-text) ?=(~ longitude-text))
      ~
    =/  coordinates=(unit station-coordinate-entry:rover)
      ?~  latitude-text
        ~
      =/  latitude  (parse-coordinate u.latitude-text)
      =/  longitude  (parse-coordinate (need longitude-text))
      ?:  ?|  ?=(~ latitude)
              ?=(~ longitude)
              (gth (abs:si (need latitude)) 900.000.000)
              (gth (abs:si (need longitude)) 1.800.000.000)
          ==
        ~
      `[(need latitude) (need longitude)]
    ?:  ?&  ?=(^ latitude-text)
            ?=(~ coordinates)
        ==
      ~
    `[u.place-name u.station-name ;;(station-kind:rover u.kind-term) address coordinates]
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
  =/  notes-text  (json-string 'notes' object)
  =/  notes=(unit @t)
    ?~  notes-text
      ~
    ?:  (nonempty u.notes-text)
      `u.notes-text
    ~
  =/  payment-text  (json-string 'paymentMethod' object)
  =/  payment-method-label=(unit @t)
    ?~  payment-text
      ~
    ?:  (nonempty u.payment-text)
      `u.payment-text
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
      notes
      payment-method-label
  ==
::
++  decode-import-simple
  |=  [field=@t values=(list json)]
  ^-  (each (list import-simple-definition:rover) entry-verdict:rover)
  =/  out=(list import-simple-definition:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape field]
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape field]
  $(values t.values, out [[u.label] out])
::
++  decode-import-subtypes
  |=  values=(list json)
  ^-  (each (list import-energy-subtype:rover) entry-verdict:rover)
  =/  out=(list import-energy-subtype:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.definitions.energy.subtypes']
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.definitions.energy.subtypes.label']
  =/  octane-text  (json-string 'octane' u.object)
  =/  cetane-text  (json-string 'cetane' u.object)
  ?:  ?&  ?=(^ octane-text)
          ?=(^ cetane-text)
      ==
    [%| %bad-shape 'import.definitions.energy.subtypes.rating']
  =/  octane=(unit @ud)
    ?~  octane-text
      ~
    (slaw %ud u.octane-text)
  =/  cetane=(unit @ud)
    ?~  cetane-text
      ~
    (slaw %ud u.cetane-text)
  ?:  ?|  ?&  ?=(^ octane-text)
              ?=(~ octane)
          ==
          ?&  ?=(^ cetane-text)
              ?=(~ cetane)
          ==
      ==
    [%| %bad-shape 'import.definitions.energy.subtypes.rating']
  =/  method-text  (json-string 'method' u.object)
  =/  method=(unit octane-method:rover)
    ?~  method-text
      ~
    =/  term  (slaw %tas u.method-text)
    ?.  ?&  ?=(^ term)
            ?|  =(%aki u.term)
                =(%ron u.term)
            ==
        ==
      ~
    `;;(octane-method:rover u.term)
  ?:  !=(?=(^ octane) ?=(^ method))
    [%| %bad-shape 'import.definitions.energy.subtypes.method']
  ?:  ?&  ?=(^ cetane)
          ?=(^ method)
      ==
    [%| %bad-shape 'import.definitions.energy.subtypes.method']
  =/  row=import-energy-subtype:rover
    [u.label octane method cetane]
  $(values t.values, out [row out])
::
++  decode-import-energy
  |=  values=(list json)
  ^-  (each (list import-energy-definition:rover) entry-verdict:rover)
  =/  out=(list import-energy-definition:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.definitions.energy']
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.definitions.energy.label']
  =/  kind-text  (json-string 'physicalKind' u.object)
  ?~  kind-text
    [%| %missing-key 'import.definitions.energy.physicalKind']
  =/  kind-term  (slaw %tas u.kind-text)
  ?.  ?&  ?=(^ kind-term)
          ?|  =(%reservoir u.kind-term)
              =(%electricity u.kind-term)
          ==
      ==
    [%| %bad-shape 'import.definitions.energy.physicalKind']
  =/  unit-text  (json-string 'quantityUnit' u.object)
  ?~  unit-text
    [%| %missing-key 'import.definitions.energy.quantityUnit']
  =/  unit-term  (slaw %tas u.unit-text)
  ?~  unit-term
    [%| %bad-shape 'import.definitions.energy.quantityUnit']
  =/  subtype-json  (json-array 'subtypes' u.object)
  ?~  subtype-json
    [%| %missing-key 'import.definitions.energy.subtypes']
  =/  subtypes  (decode-import-subtypes u.subtype-json)
  ?:  ?=(%| -.subtypes)
    subtypes
  =/  row=import-energy-definition:rover
    :*  u.label
        ;;(physical-kind:rover u.kind-term)
        u.unit-term
        p.subtypes
    ==
  $(values t.values, out [row out])
::
++  import-part
  |=  [key=@t part=address-part:rover object=(map @t json)]
  ^-  (unit [part=address-part:rover value=@t])
  =/  value  (json-string key object)
  ?~  value
    ~
  ?.  (nonempty u.value)
    ~
  `[part u.value]
::
++  decode-import-places
  |=  values=(list json)
  ^-  (each (list import-place:rover) entry-verdict:rover)
  =/  out=(list import-place:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.places']
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.places.label']
  =/  address-value  (~(get by u.object) 'address')
  =/  address=(unit import-place-address:rover)
    ?~  address-value
      ~
    =/  address-object  (json-map u.address-value)
    ?~  address-object
      ~
    =/  formatted  (optional-text 'formatted' u.address-object)
    =/  parts-value  (~(get by u.address-object) 'parts')
    =/  parts=(list [part=address-part:rover value=@t])  ~
    =.  parts
      ?:  ?=(^ parts-value)
        =/  parts-object  (json-map u.parts-value)
        ?:  ?=(^ parts-object)
          =/  country  (import-part 'country' %country u.parts-object)
          =/  locality  (import-part 'locality' %locality u.parts-object)
          =/  region  (import-part 'region' %region u.parts-object)
          =/  postal  (import-part 'postal-code' %postal-code u.parts-object)
          =/  sublocality  (import-part 'sublocality' %sublocality u.parts-object)
          =/  line1  (import-part 'line1' %line1 u.parts-object)
          =/  line2  (import-part 'line2' %line2 u.parts-object)
          =.  parts  ?~(line2 parts [u.line2 parts])
          =.  parts  ?~(line1 parts [u.line1 parts])
          =.  parts  ?~(sublocality parts [u.sublocality parts])
          =.  parts  ?~(postal parts [u.postal parts])
          =.  parts  ?~(region parts [u.region parts])
          =.  parts  ?~(locality parts [u.locality parts])
          =.  parts  ?~(country parts [u.country parts])
          parts
        ~
      parts
    ?:  ?|  ?=(^ formatted)
            ?=(^ parts)
        ==
      `[formatted parts]
    ~
  ?:  ?&  ?=(^ address-value)
          ?=(~ address)
      ==
    [%| %bad-shape 'import.places.address']
  =/  coordinates-value  (~(get by u.object) 'coordinates')
  =/  coordinates=(unit import-place-coordinates:rover)
    ?~  coordinates-value
      ~
    =/  coordinates-object  (json-map u.coordinates-value)
    ?~  coordinates-object
      ~
    =/  lat-text  (json-string 'lat' u.coordinates-object)
    =/  lon-text  (json-string 'lon' u.coordinates-object)
    =/  source-text  (json-string 'source' u.coordinates-object)
    ?:  ?|  ?=(~ lat-text)
            ?=(~ lon-text)
            ?=(~ source-text)
        ==
      ~
    =/  latitude  (parse-coordinate u.lat-text)
    =/  longitude  (parse-coordinate u.lon-text)
    =/  source-term  (slaw %tas u.source-text)
    ?:  ?|  ?=(~ latitude)
            ?=(~ longitude)
            ?=(~ source-term)
        ==
      ~
    ?.  ?|  =(%owner u.source-term)
            =(%gps u.source-term)
            =(%receipt u.source-term)
            =(%directory u.source-term)
            =(%geocoder u.source-term)
            =(%imported u.source-term)
        ==
      ~
    `[(need latitude) (need longitude) ;;(coordinate-source:rover u.source-term)]
  ?:  ?&  ?=(^ coordinates-value)
          ?=(~ coordinates)
      ==
    [%| %bad-shape 'import.places.coordinates']
  =/  row=import-place:rover  [u.label address coordinates]
  $(values t.values, out [row out])
::
++  decode-import-fills
  |=  [vehicle=@t values=(list json)]
  ^-  (each (list import-fill:rover) entry-verdict:rover)
  =/  out=(list import-fill:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.fills']
  =/  decoded  (decode-fill-object u.object)
  ?:  ?=(%| -.decoded)
    decoded
  ?.  =(vehicle vehicle-label.p.decoded)
    [%| %bad-shape 'import.vehicle.fills.vehicle']
  =/  app-text  (json-string 'sourceApp' u.object)
  ?~  app-text
    [%| %missing-key 'import.vehicle.fills.sourceApp']
  =/  app-term  (slaw %tas u.app-text)
  ?~  app-term
    [%| %bad-shape 'import.vehicle.fills.sourceApp']
  =/  record-id  (json-string 'sourceRecordId' u.object)
  ?:  ?|  ?=(~ record-id)
          =(%.n (nonempty u.record-id))
      ==
    [%| %missing-key 'import.vehicle.fills.sourceRecordId']
  =/  source-total  (optional-text 'sourceTotal' u.object)
  =/  row=import-fill:rover
    [p.decoded u.app-term u.record-id source-total]
  $(values t.values, out [row out])
::
++  decode-import-vehicles
  |=  values=(list json)
  ^-  (each (list import-vehicle:rover) entry-verdict:rover)
  =/  out=(list import-vehicle:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicles']
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.vehicle.label']
  =/  distance-text  (json-string 'distanceUnit' u.object)
  ?~  distance-text
    [%| %missing-key 'import.vehicle.distanceUnit']
  =/  distance-term  (slaw %tas u.distance-text)
  ?.  ?&  ?=(^ distance-term)
          ?|  =(%mi u.distance-term)
              =(%km u.distance-term)
          ==
      ==
    [%| %bad-shape 'import.vehicle.distanceUnit']
  =/  volume-text  (json-string 'volumeUnit' u.object)
  ?~  volume-text
    [%| %missing-key 'import.vehicle.volumeUnit']
  =/  volume-term  (slaw %tas u.volume-text)
  ?~  volume-term
    [%| %bad-shape 'import.vehicle.volumeUnit']
  =/  tank-value  (~(get by u.object) 'tankSize')
  =/  tank-size=(unit scaled-entry:rover)
    ?~  tank-value
      ~
    =/  tank-object  (json-map u.tank-value)
    ?~  tank-object
      ~
    =/  value-text  (json-string 'value' u.tank-object)
    =/  unit-text  (json-string 'unit' u.tank-object)
    ?:  ?|  ?=(~ value-text)
            ?=(~ unit-text)
        ==
      ~
    =/  parsed  (parse-decimal:render u.value-text 3)
    ?:  ?=(%| -.parsed)
      ~
    =/  unit-term  (slaw %tas u.unit-text)
    ?~  unit-term
      ~
    `[digits.p.parsed places.p.parsed u.unit-term]
  ?:  ?&  ?=(^ tank-value)
          ?=(~ tank-size)
      ==
    [%| %bad-shape 'import.vehicle.tankSize']
  =/  default  (json-string 'defaultEnergy' u.object)
  ?~  default
    =/  field
      (crip (weld "import.vehicle " (weld (trip u.label) ".defaultEnergy")))
    [%| %missing-key field]
  ?.  (nonempty u.default)
    [%| %bad-shape 'import.vehicle.defaultEnergy']
  =/  fill-json  (json-array 'fills' u.object)
  ?~  fill-json
    [%| %missing-key 'import.vehicle.fills']
  =/  fills  (decode-import-fills u.label u.fill-json)
  ?:  ?=(%| -.fills)
    fills
  =/  row=import-vehicle:rover
    :*  u.label
        ;;(distance-unit:rover u.distance-term)
        u.volume-term
        tank-size
        u.default
        p.fills
    ==
  $(values t.values, out [row out])
::
++  decode-import
  |=  body=@t
  ^-  (each import-document:rover entry-verdict:rover)
  =/  object  (json-object body)
  ?~  object
    [%| %bad-shape 'import']
  =/  version  (~(get by u.object) 'rover-import')
  ?.  ?&  ?=(^ version)
          ?=(%n -.u.version)
          =('1' +.u.version)
      ==
    [%| %bad-shape 'import.rover-import']
  =/  source  (~(get by u.object) 'source')
  ?.  ?&  ?=(^ source)
          ?=(%o -.u.source)
      ==
    [%| %bad-shape 'import.source']
  =/  definitions-value  (~(get by u.object) 'definitions')
  ?~  definitions-value
    [%| %missing-key 'import.definitions']
  =/  definitions-object  (json-map u.definitions-value)
  ?~  definitions-object
    [%| %bad-shape 'import.definitions']
  =/  energy-json  (json-array 'energy' u.definitions-object)
  =/  additive-json  (json-array 'additives' u.definitions-object)
  =/  mode-json  (json-array 'driving-modes' u.definitions-object)
  =/  tag-json  (json-array 'tags' u.definitions-object)
  =/  payment-json  (json-array 'payment-methods' u.definitions-object)
  ?:  ?|  ?=(~ energy-json)
          ?=(~ additive-json)
          ?=(~ mode-json)
          ?=(~ tag-json)
          ?=(~ payment-json)
      ==
    [%| %bad-shape 'import.definitions']
  =/  energy  (decode-import-energy u.energy-json)
  ?:  ?=(%| -.energy)
    energy
  =/  additives  (decode-import-simple 'import.definitions.additives' u.additive-json)
  ?:  ?=(%| -.additives)
    additives
  =/  modes  (decode-import-simple 'import.definitions.driving-modes' u.mode-json)
  ?:  ?=(%| -.modes)
    modes
  =/  tags  (decode-import-simple 'import.definitions.tags' u.tag-json)
  ?:  ?=(%| -.tags)
    tags
  =/  payments  (decode-import-simple 'import.definitions.payment-methods' u.payment-json)
  ?:  ?=(%| -.payments)
    payments
  =/  place-json  (json-array 'places' u.object)
  ?~  place-json
    [%| %missing-key 'import.places']
  =/  places  (decode-import-places u.place-json)
  ?:  ?=(%| -.places)
    places
  =/  vehicle-json  (json-array 'vehicles' u.object)
  ?~  vehicle-json
    [%| %missing-key 'import.vehicles']
  =/  vehicles  (decode-import-vehicles u.vehicle-json)
  ?:  ?=(%| -.vehicles)
    vehicles
  =/  definitions=import-definitions:rover
    [p.energy p.additives p.modes p.tags p.payments]
  [%& definitions p.places p.vehicles]
::
++  decode-consumable
  |=  body=@t
  ^-  (each consumable-entry:rover entry-verdict:rover)
  =/  object  (json-object body)
  ?~  object
    [%| %bad-shape 'consumable']
  =/  vehicle  (json-string 'vehicle' u.object)
  =/  consumable  (json-string 'consumable' u.object)
  =/  quantity  (json-string 'quantity' u.object)
  =/  price  (json-string 'price' u.object)
  =/  observed  (json-string 'observed' u.object)
  =/  zone  (json-string 'zone' u.object)
  ?:  ?|  ?=(~ vehicle)
          ?=(~ consumable)
          ?=(~ quantity)
          ?=(~ price)
          ?=(~ observed)
          ?=(~ zone)
      ==
    [%| %missing-key 'consumable']
  ?.  ?&  (nonempty u.vehicle)
          (nonempty u.consumable)
          (nonempty u.zone)
      ==
    [%| %bad-shape 'consumable']
  =/  parsed-quantity  (parse-decimal:render u.quantity 3)
  ?:  ?=(%| -.parsed-quantity)
    [%| %bad-shape 'consumable.quantity']
  =/  quantity-milli
    (mul digits.p.parsed-quantity (pow-ten:render (sub 3 places.p.parsed-quantity)))
  ?.  (gth quantity-milli 0)
    [%| %bad-range 'consumable.quantity']
  =/  parsed-price  (parse-us-price:render u.price)
  ?:  ?=(%| -.parsed-price)
    [%| %bad-shape 'consumable.price']
  =/  observed-start  (local-da u.observed)
  ?~  observed-start
    [%| %bad-shape 'consumable.observed']
  =/  settlement-text  (json-string 'settlement' u.object)
  =/  settlement-mode=settlement-mode:rover
    ?:  ?&  ?=(^ settlement-text)
            =('cash' u.settlement-text)
        ==
      %cash
    %standard
  =/  mileage-text  (json-string 'mileage' u.object)
  =/  mileage=(unit odo-reading:rover)
    ?~  mileage-text
      ~
    ?:  =(0 (lent (trim-spaces:render (trip u.mileage-text))))
      ~
    =/  parsed-mileage  (parse-decimal:render u.mileage-text 3)
    ?:  ?=(%| -.parsed-mileage)
      ~
    =/  mileage-unit  (json-string 'mileageUnit' u.object)
    ?~  mileage-unit
      ~
    =/  unit-term  (slaw %tas u.mileage-unit)
    ?.  ?&  ?=(^ unit-term)
            ?|  =(%mi u.unit-term)
                =(%km u.unit-term)
            ==
        ==
      ~
    `[digits.p.parsed-mileage places.p.parsed-mileage ;;(distance-unit:rover u.unit-term)]
  ?:  ?&  ?=(^ mileage-text)
          (gth (lent (trim-spaces:render (trip u.mileage-text))) 0)
          ?=(~ mileage)
      ==
    [%| %bad-shape 'consumable.mileage']
  :-  %&
  :*  u.vehicle
      u.consumable
      quantity-milli
      unit-price-mills.p.parsed-price
      display.p.parsed-price
      %usd
      %us-usd-gal
      2
      50
      settlement-mode
      u.observed-start
      u.zone
      mileage
  ==
::
::  A vehicle event as the owner entered it (M7 T1). Every refusal names the
::  human field, never a column or an id.
::
::  The total is OPTIONAL and ENTERED. A blank total writes no cost row at all,
::  which is how a note without a cost and a zero-cost record stay different
::  things. It is parsed with +parse-money, not +parse-us-price: an invoice
::  total has no market third digit to complete.
++  decode-event
  ::  The kind comes from the route, never from the body. A client cannot
  ::  name a kind that disagrees with the typed child the route selects.
  |=  [kind=event-kind:rover body=@t]
  ^-  (each event-entry:rover entry-verdict:rover)
  =/  object  (json-object body)
  ?~  object
    [%| %bad-shape 'event']
  =/  vehicle  (json-string 'vehicle' u.object)
  ?~  vehicle
    [%| %missing-key 'event.vehicle']
  ?.  (nonempty u.vehicle)
    [%| %bad-shape 'event.vehicle']
  =/  observed  (json-string 'observed' u.object)
  ?~  observed
    [%| %missing-key 'event.observed']
  =/  observed-start  (local-da u.observed)
  ?~  observed-start
    [%| %bad-shape 'event.observed']
  =/  zone  (json-string 'zone' u.object)
  ?~  zone
    [%| %missing-key 'event.zone']
  ?.  (nonempty u.zone)
    [%| %bad-shape 'event.zone']
  =/  currency-text  (json-string 'currency' u.object)
  =/  currency=currency:rover
    ?~  currency-text
      %usd
    =/  term  (slaw %tas u.currency-text)
    ?.  ?&  ?=(^ term)
            ?=(currency:rover u.term)
        ==
      %usd
    ;;(currency:rover u.term)
  =/  minor-unit-decimals  (currency-minor-decimals:render currency)
  =/  total-text  (optional-text 'total' u.object)
  =/  total-parse
    ^-  (each [mills=(unit @ud) display=@t] ?(%bad-shape %excess-precision))
    ?~  total-text
      [%& [~ '']]
    =/  parsed  (parse-money:render u.total-text currency minor-unit-decimals)
    ?:  ?=(%| -.parsed)
      [%| p.parsed]
    [%& [`total-mills.p.parsed display.p.parsed]]
  ?:  ?=(%| -.total-parse)
    [%| p.total-parse 'event.total']
  =/  total-mills=(unit @ud)  mills.p.total-parse
  =/  total-display=@t  display.p.total-parse
  =/  mileage-text  (optional-text 'mileage' u.object)
  =/  mileage=(unit odo-reading:rover)
    ?~  mileage-text
      ~
    =/  parsed-mileage  (parse-decimal:render u.mileage-text 3)
    ?:  ?=(%| -.parsed-mileage)
      ~
    =/  mileage-unit  (json-string 'mileageUnit' u.object)
    ?~  mileage-unit
      ~
    =/  unit-term  (slaw %tas u.mileage-unit)
    ?.  ?&  ?=(^ unit-term)
            ?|  =(%mi u.unit-term)
                =(%km u.unit-term)
            ==
        ==
      ~
    `[digits.p.parsed-mileage places.p.parsed-mileage ;;(distance-unit:rover u.unit-term)]
  ?:  ?&  ?=(^ mileage-text)
          ?=(~ mileage)
      ==
    [%| %bad-shape 'event.mileage']
  =/  station  (json-string 'station' u.object)
  ?~  station
    [%| %missing-key 'event.station']
  =/  station-label=(unit @t)
    ?:  ?|  =('none' u.station)
            =('new' u.station)
        ==
      ~
    ?.  (nonempty u.station)
      ~
    `u.station
  =/  new-station=(unit new-station-entry:rover)
    ?.  =('new' u.station)
      ~
    =/  station-name  (optional-text 'newStationLabel' u.object)
    ?~  station-name
      ~
    =/  place-name  (optional-text 'newPlaceLabel' u.object)
    ?~  place-name
      ~
    =/  kind-value  (json-string 'newStationKind' u.object)
    ?~  kind-value
      ~
    =/  station-kind-term  (slaw %tas u.kind-value)
    ?.  ?&  ?=(^ station-kind-term)
            ?=(station-kind:rover u.station-kind-term)
        ==
      ~
    `[u.place-name u.station-name ;;(station-kind:rover u.station-kind-term) ~ ~]
  ?:  ?&  =('new' u.station)
          ?=(~ new-station)
      ==
    [%| %bad-shape 'event.station']
  ?:  ?&  !=('none' u.station)
          !=('new' u.station)
          ?=(~ station-label)
      ==
    [%| %bad-shape 'event.station']
  =/  tag-labels  (json-strings 'tags' u.object)
  =/  tags=(list @t)
    ?~  tag-labels
      ~
    (skim u.tag-labels nonempty)
  =/  new-tag  (optional-text 'newTag' u.object)
  ::  M7 T4. The route still decides the event kind. A disposal additionally
  ::  names the mandatory definition its typed child references; every other
  ::  route ignores this body member, so it cannot smuggle disposal meaning
  ::  onto an unrelated child.
  =/  disposal-kind-entered  (optional-text 'disposalKind' u.object)
  =/  disposal-kind=(unit @t)
    ?:  =(%disposal kind)
      disposal-kind-entered
    ~
  ?:  ?&  =(%disposal kind)
          ?=(~ disposal-kind)
      ==
    [%| %missing-key 'event.disposal-kind']
  ::  M7 T2. Several subtypes at once. An absent key and an empty array mean
  ::  the same thing, and both write no link row.
  =/  subtype-labels  (json-strings 'subtypes' u.object)
  =/  subtypes=(list @t)
    ?~  subtype-labels
      ~
    (skim u.subtype-labels nonempty)
  =/  payment-method  (optional-text 'paymentMethod' u.object)
  =/  notes  (optional-text 'notes' u.object)
  :-  %&
  :*  u.vehicle
      kind
      u.observed-start
      u.zone
      total-mills
      total-display
      currency
      minor-unit-decimals
      mileage
      station-label
      new-station
      tags
      new-tag
      disposal-kind
      subtypes
      payment-method
      notes
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
              =(%itemized u.cost-term)
              =(%receipt-total-only u.cost-term)
          ==
      ==
    [%| %bad-shape 'charge.cost-state']
  =/  cost-state  ;;(cost-state:rover u.cost-term)
  ::  Both cost fields stay optional keys. A caller that records no charging
  ::  cost evidence omits them; an absent key is not an empty-but-present one.
  =/  decoded-components
    ^-  (each (list charging-component-entry:rover) entry-verdict:rover)
    =/  value  (~(get by object) 'components')
    ?~  value
      [%& ~]
    ?.  ?=(%a -.u.value)
      [%| %bad-shape 'charge.components']
    (decode-charging-components +.u.value)
  ?:  ?=(%| -.decoded-components)
    [%| p.decoded-components]
  =/  components  p.decoded-components
  =/  decoded-total
    ^-  (each (unit @ud) entry-verdict:rover)
    =/  value  (~(get by object) 'sourceTotal')
    ?~  value
      [%& ~]
    ?.  ?=(%s -.u.value)
      [%| %bad-shape 'charge.source-total']
    ?.  (nonempty +.u.value)
      [%& ~]
    =/  mills  (decode-mills 'sourceTotal' 'charge.source-total' object)
    ?:  ?=(%| -.mills)
      [%| p.mills]
    [%& `p.mills]
  ?:  ?=(%| -.decoded-total)
    [%| p.decoded-total]
  =/  source-total-mills  p.decoded-total
  ::  %itemized needs at least one component and derives its own total.
  ::  %receipt-total-only needs exactly one source total and no components.
  ::  %free and %unknown take neither. An omitted row means no total; a zero
  ::  row would claim the source reported zero.
  =/  wants-components  =(%itemized cost-state)
  =/  wants-source-total  =(%receipt-total-only cost-state)
  ?.  =(wants-components ?=(^ components))
    [%| %bad-shape 'charge.components']
  ?.  =(wants-source-total ?=(^ source-total-mills))
    [%| %bad-shape 'charge.source-total']
  ::  derive-charging-total owns the arithmetic and refuses discounts that
  ::  exceed the charged components. Report its refusal, do not restate it.
  =/  amounts=(list charging-component-amount:rover)
    %+  turn  components
    |=  row=charging-component-entry:rover
    ^-  charging-component-amount:rover
    [component.row amount-mills.row]
  =/  balance  (mule |.((derive-charging-total:act amounts)))
  ?:  ?=(%| -.balance)
    [%| %bad-range 'charge.components']
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
  =/  subtype-text  (json-string 'subtype' object)
  =/  subtype-label=(unit @t)
    ?~  subtype-text
      ~
    ?:  (nonempty u.subtype-text)
      `u.subtype-text
    ~
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
      cost-state
      ;;(currency:rover u.currency-term)
      components
      source-total-mills
      subtype-label
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
  =/  additional  (json-strings 'additionalEnergy' object)
  =/  modes  (json-strings 'drivingModes' object)
  =/  additional-labels=(list @t)  ?~(additional ~ u.additional)
  =/  mode-labels=(list @t)  ?~(modes ~ u.modes)
  ?.  ?&  (levy additional-labels nonempty)
          (levy mode-labels nonempty)
      ==
    [%| %bad-shape 'vehicle.configuration']
  =/  def-text  (json-string 'defEnabled' object)
  ?.  ?~(def-text %.y ?|(=('yes' u.def-text) =('no' u.def-text)))
    [%| %bad-shape 'vehicle.def-enabled']
  =/  def-enabled  ?~(def-text %.n =('yes' u.def-text))
  =/  def-tank-text  (json-string 'defTankSize' object)
  =/  def-unit-text  (json-string 'defTankUnit' object)
  =/  def-tank-size=(unit scaled-entry:rover)
    ?~  def-tank-text
      ~
    ?.  (nonempty u.def-tank-text)
      ~
    =/  parsed  (parse-decimal:render u.def-tank-text 3)
    ?:  ?=(%| -.parsed)
      ~
    =/  unit  ?~(def-unit-text ~ (slaw %tas u.def-unit-text))
    ?~  unit
      ~
    ?:  ?|  =(%gal u.unit)
            =(%litre u.unit)
        ==
      `[digits.p.parsed places.p.parsed u.unit]
    ~
  ?:  ?&  ?=(^ def-tank-text)
          (nonempty u.def-tank-text)
          ?=(~ def-tank-size)
      ==
    [%| %bad-shape 'vehicle.def-tank-size']
  [%& u.label u.energy additional-labels mode-labels def-enabled def-tank-size]
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
  =/  reserve-text  (json-string 'refillReserve' u.object)
  =/  refill-reserve=(unit @ud)
    ?~  reserve-text
      ~
    ?.  (nonempty u.reserve-text)
      ~
    (slaw %ud u.reserve-text)
  ?:  ?&  ?=(^ reserve-text)
          (nonempty u.reserve-text)
          ?=(~ refill-reserve)
      ==
    [%| %bad-shape 'vehicle.refill-reserve']
  ?:  ?&  ?=(^ refill-reserve)
          (gte u.refill-reserve 100)
      ==
    [%| %out-of-range 'vehicle.refill-reserve']
  =/  subtype-text  (json-string 'defaultSubtype' u.object)
  =/  default-subtype=(unit @t)
    ?~  subtype-text
      ~
    ?.  (nonempty u.subtype-text)
      ~
    `u.subtype-text
  =/  energy-text  (json-string 'defaultEnergy' u.object)
  =/  default-energy=(unit @t)
    ?~  energy-text
      ~
    ?.  (nonempty u.energy-text)
      ~
    `u.energy-text
  =/  energy-labels  (json-strings 'energySources' u.object)
  =/  mode-labels  (json-strings 'drivingModes' u.object)
  ?.  ?&  ?~(energy-labels %.y (levy u.energy-labels nonempty))
          ?~(mode-labels %.y (levy u.mode-labels nonempty))
      ==
    [%| %bad-shape 'vehicle.configuration']
  =/  def-text  (json-string 'defEnabled' u.object)
  ?.  ?~(def-text %.y ?|(=('yes' u.def-text) =('no' u.def-text)))
    [%| %bad-shape 'vehicle.def-enabled']
  =/  def-enabled=(unit ?)
    ?~  def-text
      ~
    `=('yes' u.def-text)
  =/  def-tank-text  (json-string 'defTankSize' u.object)
  =/  def-unit-text  (json-string 'defTankUnit' u.object)
  =/  def-tank-size=(unit scaled-entry:rover)
    ?~  def-tank-text
      ~
    ?.  (nonempty u.def-tank-text)
      ~
    =/  parsed  (parse-decimal:render u.def-tank-text 3)
    ?:  ?=(%| -.parsed)
      ~
    =/  unit  ?~(def-unit-text ~ (slaw %tas u.def-unit-text))
    ?~  unit
      ~
    ?:  ?|  =(%gal u.unit)
            =(%litre u.unit)
        ==
      `[digits.p.parsed places.p.parsed u.unit]
    ~
  ?:  ?&  ?=(^ def-tank-text)
          (nonempty u.def-tank-text)
          ?=(~ def-tank-size)
      ==
    [%| %bad-shape 'vehicle.def-tank-size']
  [%& u.vehicle u.label tank-size refill-reserve default-subtype default-energy energy-labels mode-labels def-enabled def-tank-size]
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
