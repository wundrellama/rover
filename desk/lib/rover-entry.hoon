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
  ==
--
