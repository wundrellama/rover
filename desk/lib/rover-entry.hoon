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
++  json-boolean
  |=  [key=@t object=(map @t json)]
  ^-  (unit ?)
  =/  value  (~(get by object) key)
  ?~  value
    ~
  ?.  ?=(%b -.u.value)
    ~
  `+.u.value
::
++  json-number
  |=  [key=@t object=(map @t json)]
  ^-  (unit @ud)
  =/  value  (~(get by object) key)
  ?~  value
    ~
  ?.  ?=(%n -.u.value)
    ~
  (slaw %ud +.u.value)
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
::  M7 T6. A calendar day, the way `<input type="date">` sends one. The reminder
::  due point is a day and not an instant, so it lands at midnight of that day
::  rather than carrying a time the owner never entered.
++  local-day
  |=  txt=@t
  ^-  (unit @da)
  =/  tap=tape  (trip txt)
  ?.  =(10 (lent tap))
    ~
  ?.  ?&  =('-' (snag 4 tap))
          =('-' (snag 7 tap))
      ==
    ~
  =/  digits
    (skip tap |=(char=@t =('-' char)))
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
    ==
  (slaw %da da-text)
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
++  decode-import-consumables
  |=  values=(list json)
  ^-  (each (list import-consumable-definition:rover) entry-verdict:rover)
  =/  out=(list import-consumable-definition:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.definitions.consumables']
  =/  label  (json-string 'label' u.object)
  =/  unit-text  (json-string 'quantityUnit' u.object)
  ?:  ?|  ?=(~ label)
          ?=(~ unit-text)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.definitions.consumables']
  =/  unit-term  (slaw %tas u.unit-text)
  ?~  unit-term
    [%| %bad-shape 'import.definitions.consumables.quantityUnit']
  $(values t.values, out [[u.label u.unit-term] out])
::
++  decode-import-options
  |=  values=(list json)
  ^-  (each (list import-custom-option:rover) entry-verdict:rover)
  =/  out=(list import-custom-option:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.definitions.custom-fields.options']
  =/  ordinal  (json-number 'ordinal' u.object)
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ ordinal)
          ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.definitions.custom-fields.options']
  $(values t.values, out [[u.ordinal u.label] out])
::
++  decode-import-custom-definitions
  |=  values=(list json)
  ^-  (each (list import-custom-definition:rover) entry-verdict:rover)
  =/  out=(list import-custom-definition:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.definitions.custom-fields']
  =/  label  (json-string 'label' u.object)
  =/  content  (json-string 'contentType' u.object)
  =/  entry  (json-string 'entryType' u.object)
  =/  mandatory  (json-boolean 'mandatory' u.object)
  =/  target  (json-string 'target' u.object)
  ?:  ?|  ?=(~ label)
          ?=(~ content)
          ?=(~ entry)
          ?=(~ mandatory)
          ?=(~ target)
      ==
    [%| %bad-shape 'import.definitions.custom-fields']
  =/  content-term  (slaw %tas u.content)
  =/  entry-term  (slaw %tas u.entry)
  =/  target-term  (slaw %tas u.target)
  ?:  ?|  ?=(~ content-term)
          ?=(~ entry-term)
          ?=(~ target-term)
      ==
    [%| %bad-shape 'import.definitions.custom-fields']
  =/  option-json  (json-array 'options' u.object)
  =/  options=(each (list import-custom-option:rover) entry-verdict:rover)
    ?~  option-json  [%& ~]
    (decode-import-options u.option-json)
  ?:  ?=(%| -.options)
    options
  =/  row=import-custom-definition:rover
    [u.label u.content-term u.entry-term u.mandatory u.target-term p.options]
  $(values t.values, out [row out])
::
++  decode-import-custom-values
  |=  values=(list json)
  ^-  (each (list import-custom-value:rover) entry-verdict:rover)
  =/  out=(list import-custom-value:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.fills.customFields']
  =/  label  (json-string 'label' u.object)
  =/  type-text  (json-string 'type' u.object)
  ?:  ?|  ?=(~ label)
          ?=(~ type-text)
      ==
    [%| %bad-shape 'import.vehicle.fills.customFields']
  =/  type-term  (slaw %tas u.type-text)
  ?~  type-term
    [%| %bad-shape 'import.vehicle.fills.customFields.type']
  =/  value-text=@t
    ?:  =(%boolean u.type-term)
      ''
    =/  value  (json-string 'value' u.object)
    ?~  value  ''
    u.value
  =/  boolean=(unit ?)
    ?:  =(%boolean u.type-term)
      (json-boolean 'value' u.object)
    `%.n
  ?:  ?|  ?&  !=(%boolean u.type-term)
              =(0 value-text)
          ==
          ?&  =(%boolean u.type-term)
              ?=(~ boolean)
          ==
      ==
    [%| %bad-shape 'import.vehicle.fills.customFields.value']
  =/  unit-text  (json-string 'unit' u.object)
  =/  value-unit=@tas
    ?~  unit-text  %unitless
    =/  parsed  (slaw %tas u.unit-text)
    ?~  parsed  %unitless
    u.parsed
  =/  row=import-custom-value:rover
    [u.label u.type-term value-text value-unit ?~(boolean %.n u.boolean)]
  $(values t.values, out [row out])
::
++  decode-import-vehicle-consumables
  |=  values=(list json)
  ^-  (each (list import-vehicle-consumable:rover) entry-verdict:rover)
  =/  out=(list import-vehicle-consumable:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.consumables']
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.vehicle.consumables.label']
  =/  tank-value  (~(get by u.object) 'tankSize')
  =/  tank-size=(unit scaled-entry:rover)
    ?~  tank-value  ~
    =/  tank-object  (json-map u.tank-value)
    ?~  tank-object  ~
    =/  value-text  (json-string 'value' u.tank-object)
    =/  unit-text  (json-string 'unit' u.tank-object)
    ?:  ?|  ?=(~ value-text)
            ?=(~ unit-text)
        ==
      ~
    =/  parsed  (parse-decimal:render u.value-text 3)
    ?:  ?=(%| -.parsed)  ~
    =/  unit-term  (slaw %tas u.unit-text)
    ?~  unit-term  ~
    `[digits.p.parsed places.p.parsed u.unit-term]
  ?:  ?&  ?=(^ tank-value)
          ?=(~ tank-size)
      ==
    [%| %bad-shape 'import.vehicle.consumables.tankSize']
  $(values t.values, out [[u.label tank-size] out])
::
++  decode-import-service-subtypes
  |=  values=(list json)
  ^-  (each (list import-service-subtype:rover) entry-verdict:rover)
  =/  out=(list import-service-subtype:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.definitions.service-subtypes']
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ label)
          =(%.n (nonempty u.label))
      ==
    [%| %bad-shape 'import.definitions.service-subtypes.label']
  =/  time-text  (json-string 'defaultTimeInterval' u.object)
  =/  time-unit-text  (json-string 'defaultTimeUnit' u.object)
  =/  distance-text  (json-string 'defaultDistanceInterval' u.object)
  =/  distance-unit-text  (json-string 'defaultDistanceUnit' u.object)
  =/  has-default
    ?|  ?=(^ time-text)
        ?=(^ time-unit-text)
        ?=(^ distance-text)
        ?=(^ distance-unit-text)
    ==
  =/  default=(unit import-subtype-default:rover)
    ?.  has-default
      ~
    ?:  ?|  ?=(~ time-text)
            ?=(~ time-unit-text)
            ?=(~ distance-text)
            ?=(~ distance-unit-text)
        ==
      ~
    =/  time  (slaw %ud u.time-text)
    =/  time-unit  (slaw %tas u.time-unit-text)
    =/  distance  (parse-decimal:render u.distance-text 3)
    =/  distance-unit  (slaw %tas u.distance-unit-text)
    ?:  ?|  ?=(~ time)
            =(0 u.time)
            ?=(~ time-unit)
            ?=(%| -.distance)
            =(0 digits.p.distance)
            ?=(~ distance-unit)
        ==
      ~
    ?.  ?&  ?=(reminder-time-unit:rover u.time-unit)
            ?|  =(%mi u.distance-unit)
                =(%km u.distance-unit)
            ==
        ==
      ~
    :-  ~
    :*  u.time
        ;;(reminder-time-unit:rover u.time-unit)
        digits.p.distance
        places.p.distance
        ;;(distance-unit:rover u.distance-unit)
    ==
  ?:  ?&  has-default
          ?=(~ default)
      ==
    [%| %bad-shape 'import.definitions.service-subtypes.default']
  $(values t.values, out [[u.label default] out])
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
  =/  blend-json  (json-array 'blends' u.object)
  =/  blends=(list [kind=blend-kind:rover digits=@ud places=@ud])  ~
  =.  blends
    ?~  blend-json  ~
    =/  remaining  u.blend-json
    =/  built=(list [kind=blend-kind:rover digits=@ud places=@ud])  ~
    |-
    ?~  remaining  (flop built)
    =/  blend-object  (json-map i.remaining)
    ?~  blend-object  ~
    =/  kind-text  (json-string 'kind' u.blend-object)
    =/  percent-text  (json-string 'percent' u.blend-object)
    ?:  ?|  ?=(~ kind-text)
            ?=(~ percent-text)
        ==
      ~
    =/  kind-term  (slaw %tas u.kind-text)
    =/  percent  (parse-decimal:render u.percent-text 3)
    ?.  ?&  ?=(^ kind-term)
            ?=(blend-kind:rover u.kind-term)
            ?=(%& -.percent)
        ==
      ~
    $(remaining t.remaining, built [[;;(blend-kind:rover u.kind-term) digits.p.percent places.p.percent] built])
  ?:  ?&  ?=(^ blend-json)
          !=((lent u.blend-json) (lent blends))
      ==
    [%| %bad-shape 'import.definitions.energy.subtypes.blends']
  =/  grade-code  (optional-text 'gradeCode' u.object)
  =/  row=import-energy-subtype:rover
    [u.label octane method cetane blends grade-code]
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
++  decode-import-brand-operators
  |=  values=(list json)
  ^-  (each (list [role=station-role:rover label=@t]) entry-verdict:rover)
  =/  out=(list [role=station-role:rover label=@t])  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.places.stations.brandOperators']
  =/  role-text  (json-string 'role' u.object)
  =/  label  (json-string 'label' u.object)
  ?:  ?|  ?=(~ role-text)
          ?=(~ label)
      ==
    [%| %bad-shape 'import.places.stations.brandOperators']
  =/  role-term  (slaw %tas u.role-text)
  ?.  ?&  ?=(^ role-term)
          ?=(station-role:rover u.role-term)
      ==
    [%| %bad-shape 'import.places.stations.brandOperators.role']
  $(values t.values, out [[;;(station-role:rover u.role-term) u.label] out])
::
++  decode-import-identifiers
  |=  values=(list json)
  ^-  (each (list [provider=@tas external-id=@t]) entry-verdict:rover)
  =/  out=(list [provider=@tas external-id=@t])  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.places.stations.identifiers']
  =/  provider-text  (json-string 'provider' u.object)
  =/  external-id  (json-string 'externalId' u.object)
  ?:  ?|  ?=(~ provider-text)
          ?=(~ external-id)
      ==
    [%| %bad-shape 'import.places.stations.identifiers']
  =/  provider  (slaw %tas u.provider-text)
  ?~  provider
    [%| %bad-shape 'import.places.stations.identifiers.provider']
  $(values t.values, out [[u.provider u.external-id] out])
::
++  decode-import-stations
  |=  values=(list json)
  ^-  (each (list import-station:rover) entry-verdict:rover)
  =/  out=(list import-station:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.places.stations']
  =/  label  (json-string 'label' u.object)
  =/  kind-text  (json-string 'stationKind' u.object)
  ?:  ?|  ?=(~ label)
          ?=(~ kind-text)
      ==
    [%| %bad-shape 'import.places.stations']
  =/  kind-term  (slaw %tas u.kind-text)
  ?.  ?&  ?=(^ kind-term)
          ?=(station-kind:rover u.kind-term)
      ==
    [%| %bad-shape 'import.places.stations.stationKind']
  =/  brands-json  (json-array 'brandOperators' u.object)
  =/  brands=(each (list [role=station-role:rover label=@t]) entry-verdict:rover)
    ?~  brands-json  [%& ~]
    (decode-import-brand-operators u.brands-json)
  ?:  ?=(%| -.brands)  brands
  =/  identifiers-json  (json-array 'identifiers' u.object)
  =/  identifiers=(each (list [provider=@tas external-id=@t]) entry-verdict:rover)
    ?~  identifiers-json  [%& ~]
    (decode-import-identifiers u.identifiers-json)
  ?:  ?=(%| -.identifiers)  identifiers
  =/  row=import-station:rover
    [u.label ;;(station-kind:rover u.kind-term) p.brands p.identifiers]
  $(values t.values, out [row out])
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
  =/  station-kind-text  (json-string 'stationKind' u.object)
  =/  station-kind-term=(unit @tas)
    ?~  station-kind-text
      `%fuel
    (slaw %tas u.station-kind-text)
  ?.  ?&  ?=(^ station-kind-term)
          ?=(station-kind:rover u.station-kind-term)
      ==
    [%| %bad-shape 'import.places.stationKind']
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
    =/  source-text  (json-string 'source' u.address-object)
    =/  source=address-source:rover
      ?~  source-text  %imported
      =/  source-term  (slaw %tas u.source-text)
      ?.  ?&  ?=(^ source-term)
              ?=(address-source:rover u.source-term)
          ==
        %imported
      ;;(address-source:rover u.source-term)
    ?:  ?|  ?=(^ formatted)
            ?=(^ parts)
        ==
      `[formatted parts source]
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
    =/  accuracy-text  (json-string 'accuracy' u.coordinates-object)
    =/  accuracy-unit-text  (json-string 'accuracyUnit' u.coordinates-object)
    =/  accuracy=(unit [digits=@ud places=@ud unit=radius-unit:rover])
      ?~  accuracy-text  ~
      ?~  accuracy-unit-text  ~
      =/  parsed  (parse-decimal:render u.accuracy-text 3)
      ?:  ?=(%| -.parsed)  ~
      =/  unit-term  (slaw %tas u.accuracy-unit-text)
      ?.  ?&  ?=(^ unit-term)
              ?=(radius-unit:rover u.unit-term)
          ==
        ~
      `[digits.p.parsed places.p.parsed ;;(radius-unit:rover u.unit-term)]
    `[(need latitude) (need longitude) ;;(coordinate-source:rover u.source-term) accuracy]
  ?:  ?&  ?=(^ coordinates-value)
          ?=(~ coordinates)
      ==
    [%| %bad-shape 'import.places.coordinates']
  =/  station-json  (json-array 'stations' u.object)
  =/  stations=(each (list import-station:rover) entry-verdict:rover)
    ?~  station-json
      [%& ~[[u.label ;;(station-kind:rover u.station-kind-term) ~ ~]]]
    (decode-import-stations u.station-json)
  ?:  ?=(%| -.stations)
    stations
  =/  row=import-place:rover
    [u.label ;;(station-kind:rover u.station-kind-term) address coordinates p.stations]
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
  =/  record-id  (json-string 'sourceRecordId' u.object)
  ?:  !=(?=(^ app-text) ?=(^ record-id))
    [%| %bad-shape 'import.vehicle.fills.provenance']
  =/  app-term=(unit @tas)
    ?~  app-text  ~
    (slaw %tas u.app-text)
  ?:  ?&  ?=(^ app-text)
          ?=(~ app-term)
      ==
    [%| %bad-shape 'import.vehicle.fills.sourceApp']
  ?:  ?&  ?=(^ record-id)
          =(%.n (nonempty u.record-id))
      ==
    [%| %bad-shape 'import.vehicle.fills.sourceRecordId']
  =/  source-total  (optional-text 'sourceTotal' u.object)
  =/  custom-json  (json-array 'customFields' u.object)
  =/  custom-values=(each (list import-custom-value:rover) entry-verdict:rover)
    ?~  custom-json  [%& ~]
    (decode-import-custom-values u.custom-json)
  ?:  ?=(%| -.custom-values)
    custom-values
  =/  row=import-fill:rover
    [p.decoded app-term record-id source-total p.custom-values]
  $(values t.values, out [row out])
::
++  decode-import-events
  |=  [vehicle=@t kind=event-kind:rover values=(list json)]
  ^-  (each (list import-event:rover) entry-verdict:rover)
  =/  out=(list import-event:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.events']
  =/  decoded  (decode-event-object kind `u.object)
  ?:  ?=(%| -.decoded)
    decoded
  ?.  =(vehicle vehicle-label.p.decoded)
    [%| %bad-shape 'import.vehicle.events.vehicle']
  =/  app-text  (json-string 'sourceApp' u.object)
  =/  record-id  (json-string 'sourceRecordId' u.object)
  ?:  !=(?=(^ app-text) ?=(^ record-id))
    [%| %bad-shape 'import.vehicle.events.provenance']
  =/  app-term=(unit @tas)
    ?~  app-text  ~
    (slaw %tas u.app-text)
  ?:  ?&  ?=(^ app-text)
          ?=(~ app-term)
      ==
    [%| %bad-shape 'import.vehicle.events.sourceApp']
  $(values t.values, out [[p.decoded app-term record-id] out])
::
++  decode-import-charges
  |=  [vehicle=@t values=(list json)]
  ^-  (each (list charge-entry:rover) entry-verdict:rover)
  =/  out=(list charge-entry:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.chargingSessions']
  =/  decoded  (decode-charge-object `u.object)
  ?:  ?=(%| -.decoded)
    decoded
  ?.  =(vehicle vehicle-label.p.decoded)
    [%| %bad-shape 'import.vehicle.chargingSessions.vehicle']
  $(values t.values, out [p.decoded out])
::
++  decode-import-consumable-acquisitions
  |=  [vehicle=@t values=(list json)]
  ^-  (each (list import-consumable:rover) entry-verdict:rover)
  =/  out=(list import-consumable:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.consumableAcquisitions']
  =/  decoded  (decode-consumable-object `u.object)
  ?:  ?=(%| -.decoded)
    decoded
  ?.  =(vehicle vehicle-label.p.decoded)
    [%| %bad-shape 'import.vehicle.consumableAcquisitions.vehicle']
  =/  station-text  (json-string 'station' u.object)
  =/  station-label=(unit @t)
    ?~  station-text  ~
    ?:  =('none' u.station-text)  ~
    ?:  (nonempty u.station-text)  `u.station-text
    ~
  $(values t.values, out [[p.decoded station-label] out])
::
++  decode-import-odometers
  |=  [vehicle=@t values=(list json)]
  ^-  (each (list odometer-entry:rover) entry-verdict:rover)
  =/  out=(list odometer-entry:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.odometerReadings']
  =/  decoded  (decode-odometer-object `u.object)
  ?:  ?=(%| -.decoded)
    decoded
  ?.  =(vehicle vehicle-label.p.decoded)
    [%| %bad-shape 'import.vehicle.odometerReadings.vehicle']
  $(values t.values, out [p.decoded out])
::
++  decode-import-reminders
  |=  [vehicle=@t values=(list json)]
  ^-  (each (list reminder-entry:rover) entry-verdict:rover)
  =/  out=(list reminder-entry:rover)  ~
  |-
  ?~  values
    [%& (flop out)]
  =/  object  (json-map i.values)
  ?~  object
    [%| %bad-shape 'import.vehicle.reminders']
  =/  decoded  (decode-reminder-object `u.object)
  ?:  ?=(%| -.decoded)
    decoded
  ?.  =(vehicle vehicle-label.p.decoded)
    [%| %bad-shape 'import.vehicle.reminders.vehicle']
  $(values t.values, out [p.decoded out])
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
  =/  specification-value  (~(get by u.object) 'specification')
  =/  specification=(each vehicle-spec-entry:rover entry-verdict:rover)
    ?~  specification-value
      [%& *vehicle-spec-entry:rover]
    =/  specification-object  (json-map u.specification-value)
    ?~  specification-object
      [%| %bad-shape 'import.vehicle.specification']
    (decode-spec-object u.specification-object)
  ?:  ?=(%| -.specification)
    specification
  =/  fill-json  (json-array 'fills' u.object)
  ?~  fill-json
    [%| %missing-key 'import.vehicle.fills']
  =/  fills  (decode-import-fills u.label u.fill-json)
  ?:  ?=(%| -.fills)
    fills
  =/  service-json  (json-array 'serviceEvents' u.object)
  =/  services=(each (list import-event:rover) entry-verdict:rover)
    ?~  service-json
      [%& ~]
    (decode-import-events u.label %service u.service-json)
  ?:  ?=(%| -.services)
    services
  =/  note-json  (json-array 'noteEvents' u.object)
  =/  notes=(each (list import-event:rover) entry-verdict:rover)
    ?~  note-json
      [%& ~]
    (decode-import-events u.label %note u.note-json)
  ?:  ?=(%| -.notes)
    notes
  =/  expense-json  (json-array 'expenseEvents' u.object)
  =/  expenses=(each (list import-event:rover) entry-verdict:rover)
    ?~  expense-json
      [%& ~]
    (decode-import-events u.label %expense u.expense-json)
  ?:  ?=(%| -.expenses)
    expenses
  =/  acquisition-json  (json-array 'acquisitionEvents' u.object)
  =/  acquisitions=(each (list import-event:rover) entry-verdict:rover)
    ?~  acquisition-json
      [%& ~]
    (decode-import-events u.label %acquisition u.acquisition-json)
  ?:  ?=(%| -.acquisitions)
    acquisitions
  =/  disposal-json  (json-array 'disposalEvents' u.object)
  =/  disposals=(each (list import-event:rover) entry-verdict:rover)
    ?~  disposal-json
      [%& ~]
    (decode-import-events u.label %disposal u.disposal-json)
  ?:  ?=(%| -.disposals)
    disposals
  =/  charge-json  (json-array 'chargingSessions' u.object)
  =/  charges=(each (list charge-entry:rover) entry-verdict:rover)
    ?~  charge-json
      [%& ~]
    (decode-import-charges u.label u.charge-json)
  ?:  ?=(%| -.charges)
    charges
  =/  consumable-json  (json-array 'consumableAcquisitions' u.object)
  =/  consumables=(each (list import-consumable:rover) entry-verdict:rover)
    ?~  consumable-json
      [%& ~]
    (decode-import-consumable-acquisitions u.label u.consumable-json)
  ?:  ?=(%| -.consumables)
    consumables
  =/  odometer-json  (json-array 'odometerReadings' u.object)
  =/  odometers=(each (list odometer-entry:rover) entry-verdict:rover)
    ?~  odometer-json
      [%& ~]
    (decode-import-odometers u.label u.odometer-json)
  ?:  ?=(%| -.odometers)
    odometers
  =/  reminder-json  (json-array 'reminders' u.object)
  =/  reminders=(each (list reminder-entry:rover) entry-verdict:rover)
    ?~  reminder-json
      [%& ~]
    (decode-import-reminders u.label u.reminder-json)
  ?:  ?=(%| -.reminders)
    reminders
  =/  additional-energy=(list @t)
    =/  values  (json-strings 'additionalEnergy' u.object)
    ?~  values  ~
    u.values
  =/  driving-modes=(list @t)
    =/  values  (json-strings 'drivingModes' u.object)
    ?~  values  ~
    u.values
  =/  default-subtype  (optional-text 'defaultSubtype' u.object)
  =/  reserve-text  (optional-text 'refillReserve' u.object)
  =/  refill-reserve=(unit @ud)
    ?~  reserve-text  ~
    (slaw %ud u.reserve-text)
  ?:  ?&  ?=(^ reserve-text)
          ?=(~ refill-reserve)
      ==
    [%| %bad-shape 'import.vehicle.refillReserve']
  =/  vehicle-consumable-json  (json-array 'consumables' u.object)
  =/  vehicle-consumables=(each (list import-vehicle-consumable:rover) entry-verdict:rover)
    ?~  vehicle-consumable-json  [%& ~]
    (decode-import-vehicle-consumables u.vehicle-consumable-json)
  ?:  ?=(%| -.vehicle-consumables)
    vehicle-consumables
  =/  row=import-vehicle:rover
    :*  u.label
        ;;(distance-unit:rover u.distance-term)
        u.volume-term
        tank-size
        u.default
        p.specification
        p.fills
        p.services
        p.notes
        p.reminders
        additional-energy
        driving-modes
        default-subtype
        refill-reserve
        p.charges
        p.consumables
        p.expenses
        p.acquisitions
        p.disposals
        p.odometers
        p.vehicle-consumables
    ==
  $(values t.values, out [row out])
::
++  import-archives-from
  |=  [family=@tas values=(list json)]
  ^-  (list import-archive:rover)
  =/  out=(list import-archive:rover)  ~
  |-
  ?~  values
    (flop out)
  =/  object  (json-map i.values)
  ?~  object
    $(values t.values)
  =/  label  (json-string 'label' u.object)
  =/  archived  (json-boolean 'archived' u.object)
  ?:  ?&  ?=(^ label)
          ?=(^ archived)
          u.archived
      ==
    $(values t.values, out [[family u.label] out])
  $(values t.values)
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
  =/  service-json  (json-array 'service-subtypes' u.definitions-object)
  =/  additive-json  (json-array 'additives' u.definitions-object)
  =/  mode-json  (json-array 'driving-modes' u.definitions-object)
  =/  tag-json  (json-array 'tags' u.definitions-object)
  =/  payment-json  (json-array 'payment-methods' u.definitions-object)
  =/  consumable-json  (json-array 'consumables' u.definitions-object)
  =/  disposal-json  (json-array 'disposal-kinds' u.definitions-object)
  =/  custom-json  (json-array 'custom-fields' u.definitions-object)
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
  =/  services=(each (list import-service-subtype:rover) entry-verdict:rover)
    ?~  service-json
      [%& ~]
    (decode-import-service-subtypes u.service-json)
  ?:  ?=(%| -.services)
    services
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
  =/  consumables=(each (list import-consumable-definition:rover) entry-verdict:rover)
    ?~  consumable-json  [%& ~]
    (decode-import-consumables u.consumable-json)
  ?:  ?=(%| -.consumables)
    consumables
  =/  disposals=(each (list import-simple-definition:rover) entry-verdict:rover)
    ?~  disposal-json  [%& ~]
    (decode-import-simple 'import.definitions.disposal-kinds' u.disposal-json)
  ?:  ?=(%| -.disposals)
    disposals
  =/  custom-fields=(each (list import-custom-definition:rover) entry-verdict:rover)
    ?~  custom-json  [%& ~]
    (decode-import-custom-definitions u.custom-json)
  ?:  ?=(%| -.custom-fields)
    custom-fields
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
    [p.energy p.services p.additives p.modes p.tags p.payments p.consumables p.disposals p.custom-fields]
  =/  archives=(list import-archive:rover)
    ;:  weld
      (import-archives-from %energy u.energy-json)
      ?~(service-json ~ (import-archives-from %service-subtype u.service-json))
      (import-archives-from %additive u.additive-json)
      (import-archives-from %driving-mode u.mode-json)
      (import-archives-from %tag u.tag-json)
      (import-archives-from %payment-method u.payment-json)
      ?~(consumable-json ~ (import-archives-from %consumable u.consumable-json))
      ?~(disposal-json ~ (import-archives-from %disposal-kind u.disposal-json))
      ?~(custom-json ~ (import-archives-from %custom-field u.custom-json))
      (import-archives-from %vehicle u.vehicle-json)
    ==
  [%& definitions p.places p.vehicles archives]
::
++  decode-consumable
  |=  body=@t
  ^-  (each consumable-entry:rover entry-verdict:rover)
  (decode-consumable-object (json-object body))
::
++  decode-consumable-object
  |=  object=(unit (map @t json))
  ^-  (each consumable-entry:rover entry-verdict:rover)
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
  (decode-event-object kind (json-object body))
::
++  decode-event-object
  |=  [kind=event-kind:rover object=(unit (map @t json))]
  ^-  (each event-entry:rover entry-verdict:rover)
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
  ::  M7 T2. Several subtypes at once. An absent key and an empty array mean
  ::  the same thing, and both write no link row.
  =/  subtype-labels  (json-strings 'subtypes' u.object)
  =/  subtypes=(list @t)
    ?~  subtype-labels
      ~
    (skim u.subtype-labels nonempty)
  ::  M7 T4. The kind of disposal. It is read only for a disposal, so a body
  ::  that names one on any other route is ignored exactly as a body that
  ::  names an event kind is ignored: the route decides, not the client.
  =/  disposal-kind=(unit @t)
    ?.  ?=(%disposal kind)
      ~
    (optional-text 'disposalKind' u.object)
  ?:  ?&  ?=(%disposal kind)
          ?=(~ disposal-kind)
      ==
    [%| %missing-key 'event.disposal-kind']
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
      subtypes
      disposal-kind
      payment-method
      notes
  ==
::
::  M7 T6. One reminder as a person entered it. Each interval is optional and a
::  blank field writes no child row, but a reminder with NEITHER interval names
::  no moment at all, so that is refused rather than stored.
++  decode-reminder
  |=  body=@t
  ^-  (each reminder-entry:rover entry-verdict:rover)
  (decode-reminder-object (json-object body))
::
++  decode-reminder-object
  |=  object=(unit (map @t json))
  ^-  (each reminder-entry:rover entry-verdict:rover)
  ?~  object
    [%| %bad-shape 'reminder']
  =/  vehicle  (json-string 'vehicle' u.object)
  ?~  vehicle
    [%| %missing-key 'reminder.vehicle']
  ?.  (nonempty u.vehicle)
    [%| %bad-shape 'reminder.vehicle']
  =/  subtype  (json-string 'subtype' u.object)
  ?~  subtype
    [%| %missing-key 'reminder.subtype']
  ?.  (nonempty u.subtype)
    [%| %bad-shape 'reminder.subtype']
  =/  time-count-text  (optional-text 'timeInterval' u.object)
  =/  time-unit-text  (optional-text 'timeUnit' u.object)
  =/  time-due-text  (optional-text 'timeDue' u.object)
  ::  The unit control carries a default and a drop-down always sends one, so
  ::  it alone never means the owner asked for a time interval. The count and
  ::  the due date are what a person types, and either one asks.
  =/  time-asked
    ?|  ?=(^ time-count-text)
        ?=(^ time-due-text)
    ==
  =/  time=(unit reminder-time-entry:rover)
    ?.  time-asked
      ~
    ?~  time-count-text  ~
    ?~  time-unit-text  ~
    ?~  time-due-text  ~
    =/  count  (slaw %ud u.time-count-text)
    ?~  count  ~
    ?:  =(0 u.count)  ~
    =/  unit-term  (slaw %tas u.time-unit-text)
    ?~  unit-term  ~
    ?.  ?=(reminder-time-unit:rover u.unit-term)  ~
    =/  due  (local-day u.time-due-text)
    ?~  due  ~
    `[u.count ;;(reminder-time-unit:rover u.unit-term) u.due]
  ::  A half-filled time interval is a mistake, not an absent one. Saying so is
  ::  better than dropping the two fields the owner did fill in.
  ?:  ?&  time-asked
          ?=(~ time)
      ==
    [%| %bad-shape 'reminder.time-interval']
  =/  distance-interval-text  (optional-text 'distanceInterval' u.object)
  =/  distance-due-text  (optional-text 'distanceDue' u.object)
  =/  distance-asked
    ?|  ?=(^ distance-interval-text)
        ?=(^ distance-due-text)
    ==
  =/  distance=(unit reminder-distance-entry:rover)
    ?.  distance-asked
      ~
    ?~  distance-interval-text  ~
    ?~  distance-due-text  ~
    =/  parsed-interval  (parse-decimal:render u.distance-interval-text 3)
    ?:  ?=(%| -.parsed-interval)  ~
    ?:  =(0 digits.p.parsed-interval)  ~
    =/  parsed-due  (parse-decimal:render u.distance-due-text 3)
    ?:  ?=(%| -.parsed-due)  ~
    =/  unit-text  (json-string 'distanceUnit' u.object)
    ?~  unit-text  ~
    =/  unit-term  (slaw %tas u.unit-text)
    ?~  unit-term  ~
    ?.  ?|  =(%mi u.unit-term)
            =(%km u.unit-term)
        ==
      ~
    :-  ~
    :*  digits.p.parsed-interval
        places.p.parsed-interval
        digits.p.parsed-due
        places.p.parsed-due
        ;;(distance-unit:rover u.unit-term)
    ==
  ?:  ?&  distance-asked
          ?=(~ distance)
      ==
    [%| %bad-shape 'reminder.distance-interval']
  ?:  ?&  ?=(~ time)
          ?=(~ distance)
      ==
    [%| %missing-key 'reminder.interval']
  [%& u.vehicle u.subtype time distance]
::
++  decode-odometer
  |=  body=@t
  ^-  (each odometer-entry:rover entry-verdict:rover)
  (decode-odometer-object (json-object body))
::
++  decode-odometer-object
  |=  wrapped=(unit (map @t json))
  ^-  (each odometer-entry:rover entry-verdict:rover)
  ?~  wrapped
    [%| %bad-shape 'odometer']
  =/  object=(map @t json)  u.wrapped
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
  (decode-charge-object (json-object body))
::
++  decode-charge-object
  |=  wrapped=(unit (map @t json))
  ^-  (each charge-entry:rover entry-verdict:rover)
  ?~  wrapped
    [%| %bad-shape 'charge']
  =/  object=(map @t json)  u.wrapped
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
++  decode-spec-object
  |=  object=(map @t json)
  ^-  (each vehicle-spec-entry:rover entry-verdict:rover)
  =/  spec-text-of
    |=  key=@t
    ^-  spec-text:rover
    =/  text  (json-string key object)
    ?~  text
      ~
    ?.  (nonempty u.text)
      [~ ~]
    ``u.text
  =/  year-text  (json-string 'specYear' object)
  =/  model-year=spec-number:rover
    ?~  year-text
      ~
    ?.  (nonempty u.year-text)
      [~ ~]
    =/  parsed  (parse-decimal:render u.year-text 0)
    ?:  ?=(%| -.parsed)
      ~
    ?:  ?|  (lth digits.p.parsed 1.000)
            (gth digits.p.parsed 9.999)
        ==
      ~
    ``digits.p.parsed
  ?:  ?&  ?=(^ year-text)
          (nonempty u.year-text)
          ?=(~ model-year)
      ==
    [%| %bad-shape 'vehicle.specification.year']
  :-  %&
  :*  (spec-text-of 'specVin')
      (spec-text-of 'specPlate')
      model-year
      (spec-text-of 'specMake')
      (spec-text-of 'specModel')
      (spec-text-of 'specSubModel')
      (spec-text-of 'specBodyType')
      (spec-text-of 'specColor')
      (spec-text-of 'specEngine')
      (spec-text-of 'specTransmission')
      (spec-text-of 'specDriveType')
      (spec-text-of 'specBedType')
      (spec-text-of 'specNotes')
  ==
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
  =/  specification  (decode-spec-object u.object)
  ?:  ?=(%| -.specification)
    specification
  [%& u.vehicle u.label tank-size refill-reserve default-subtype default-energy energy-labels mode-labels def-enabled def-tank-size p.specification]
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
::
::  M7 T8. One body for rename, archive and restore. The operation is NOT in
::  the body: the route carries it, so a request cannot ask for an operation
::  its endpoint does not perform.
::
::  `newLabel` is read only when the caller says the request needs it. Archive
::  and restore carry no second label, and a body that sends one anyway is not
::  refused for it, because the route decides what happens.
++  decode-definition-lifecycle
  |=  [body=@t needs-new-label=?]
  ^-  (each definition-lifecycle-entry:rover entry-verdict:rover)
  =/  parsed  (de:json:html body)
  ?~  parsed
    [%| %bad-shape 'definition']
  ?.  ?=(%o -.u.parsed)
    [%| %bad-shape 'definition']
  =/  object=(map @t json)  +.u.parsed
  =/  family-text  (json-string 'family' object)
  ?~  family-text
    [%| %missing-key 'definition.family']
  =/  family  (slaw %tas u.family-text)
  ?~  family
    [%| %bad-shape 'definition.family']
  =/  label  (json-string 'label' object)
  ?~  label
    [%| %missing-key 'definition.label']
  ?.  (nonempty u.label)
    [%| %bad-shape 'definition.label']
  ?.  needs-new-label
    [%& u.family u.label '']
  =/  new-label  (json-string 'newLabel' object)
  ?~  new-label
    [%| %missing-key 'definition.new-label']
  ?.  (nonempty u.new-label)
    [%| %bad-shape 'definition.new-label']
  [%& u.family u.label u.new-label]
--
