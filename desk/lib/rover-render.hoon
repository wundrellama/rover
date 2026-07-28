::  lib/rover-render - Rover's human-units boundary.
::
::  Stored scaled integers enter here. Human decimal strings leave here.
::  Entry parsing takes the reverse path. No floating point and no raw IDs.
::
|%
++  pow-ten
  |=  exponent=@ud
  ^-  @ud
  ?:  =(0 exponent)
    1
  (mul 10 $(exponent (dec exponent)))
::
++  trim-spaces
  |=  txt=tape
  ^-  tape
  =/  led
    |-  ^-  tape
    ?:  ?&  ?=(^ txt)
            =(' ' i.txt)
        ==
      $(txt t.txt)
    txt
  =/  rev  (flop led)
  %-  flop
  |-  ^-  tape
  ?:  ?&  ?=(^ rev)
          =(' ' i.rev)
      ==
    $(rev t.rev)
  rev
::
++  group-digits
  |=  digits=tape
  ^-  tape
  %+  turn  (scow %ud (scan digits (bass 10 (plus dit))))
  |=(char=@t ?:(=('.' char) ',' char))
::
++  format-scaled
  |=  [digits=@ud places=@ud grouped=?]
  ^-  @t
  =/  txt=tape  (a-co:co digits)
  =.  txt
    ?:  (gte (lent txt) +(places))
      txt
    (weld (reap (sub +(places) (lent txt)) '0') txt)
  =/  cut  (sub (lent txt) places)
  =/  whole=tape  (scag cut txt)
  =.  whole  ?:(grouped (group-digits whole) whole)
  ?:  =(0 places)
    (crip whole)
  (crip ;:(weld whole "." (slag cut txt)))
::
++  format-sscaled
  |=  [digits=@sd places=@ud grouped=?]
  ^-  @t
  ?:  (syn:si digits)
    (format-scaled (abs:si digits) places grouped)
  (crip ['-' (trip (format-scaled (abs:si digits) places grouped))])
::
++  term-text
  |=  value=@tas
  ^-  tape
  (trip (scot %tas value))
::
++  currency-prefix
  |=  currency=@tas
  ^-  tape
  ?+  currency  (weld (term-text currency) " ")
    %usd  "$"
    %eur  "EUR "
    %gbp  "GBP "
    %chf  "CHF "
    %jpy  "JPY "
    %krw  "KRW "
    %cny  "CNY "
    %brl  "BRL "
    %cad  "CAD "
    %aud  "AUD "
  ==
::
++  format-quantity
  |=  [quantity-milli=@ud unit=@tas]
  ^-  @t
  %-  crip
  ;:  weld
    (trip (format-scaled quantity-milli 3 %.n))
    " "
    (term-text unit)
  ==
::
++  format-unit-price
  |=  [unit-price-mills=@ud currency=@tas]
  ^-  @t
  %-  crip
  %+  weld
    (currency-prefix currency)
  (trip (format-scaled unit-price-mills 3 %.y))
::
++  format-total
  |=  [total-mills=@ud currency=@tas minor-unit-decimals=@ud]
  ^-  @t
  =/  minor-scale  (pow-ten minor-unit-decimals)
  ?>  (lte minor-scale 1.000)
  =/  mills-per-minor  (div 1.000 minor-scale)
  ?>  =(0 (mod total-mills mills-per-minor))
  =/  minor-units  (div total-mills mills-per-minor)
  %-  crip
  %+  weld
    (currency-prefix currency)
  (trip (format-scaled minor-units minor-unit-decimals %.y))
::
++  format-distance
  |=  [value-digits=@ud decimal-places=@ud unit=@tas converted=?]
  ^-  @t
  %-  crip
  ;:  weld
    (trip (format-scaled value-digits decimal-places %.y))
    " "
    (term-text unit)
    ?:(converted " (converted)" "")
  ==
::
++  format-coordinate
  |=  [scaled=@sd coord-scale=@ud]
  ^-  @t
  (format-sscaled scaled coord-scale %.n)
::
++  parse-decimal
  |=  [txt=@t max-places=@ud]
  ^-  (each [digits=@ud places=@ud] ?(%bad-shape %excess-precision))
  =/  tap
    (trim-spaces (skip (trip txt) |=(c=@t =(',' c))))
  =/  parsed=(unit [whole=tape frac=tape])
    %+  rush  (crip tap)
    ;~  plug
      (plus nud)
      ;~(pose ;~(pfix dot (star nud)) (easy *tape))
    ==
  ?~  parsed
    [%| %bad-shape]
  =/  places  (lent frac.u.parsed)
  ?:  (gth places max-places)
    [%| %excess-precision]
  =/  all  (weld whole.u.parsed frac.u.parsed)
  [%& [(scan all (bass 10 (plus dit))) places]]
::
++  parse-us-price
  |=  txt=@t
  ^-  (each [unit-price-mills=@ud display=@t] ?(%bad-shape %excess-precision))
  =/  tap  (trim-spaces (trip txt))
  =.  tap
    ?:  ?&  ?=(^ tap)
            =('$' i.tap)
        ==
      (trim-spaces t.tap)
    tap
  =/  parsed  (parse-decimal (crip tap) 3)
  ?:  ?=(%| -.parsed)
    [%| p.parsed]
  =/  digits  digits.p.parsed
  =/  places  places.p.parsed
  =/  mills
    ?:  =(3 places)
      digits
    =/  cents  (mul digits (pow-ten (sub 2 places)))
    (add (mul cents 10) 9)
  [%& [mills (format-unit-price mills %usd)]]
--
