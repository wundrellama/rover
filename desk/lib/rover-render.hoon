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
::  How many digits the currency's minor unit carries. Yen and won have none.
++  currency-minor-decimals
  |=  currency=@tas
  ^-  @ud
  ?+  currency  2
    %jpy  0
    %krw  0
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
::  Exact thousandths of the currency unit. Charging tariffs price below the
::  minor unit, so mills never collapse to whole cents here.
++  format-mills
  |=  [mills=@ud currency=@tas]
  ^-  @t
  %-  crip
  %+  weld
    (currency-prefix currency)
  (trip (format-scaled mills 3 %.y))
::
++  format-unit-price
  |=  [unit-price-mills=@ud currency=@tas]
  ^-  @t
  (format-mills unit-price-mills currency)
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
++  convert-distance
  |=  [digits=@ud places=@ud source=@tas target=@tas]
  ^-  [converted-digits=@ud converted-places=@ud converted-unit=@tas converted=?]
  ?:  =(source target)
    [digits places source %.n]
  =/  numerator=@ud
    ?:  ?&  =(%mi source)
            =(%km target)
        ==
      (mul digits 1.609.344)
    ?:  ?&  =(%km source)
            =(%mi target)
        ==
      (mul digits 1.000.000)
    !!
  =/  denominator=@ud
    ?:  =(%mi source)
      1.000.000
    1.609.344
  =/  converted-digits
    (div (add numerator (div denominator 2)) denominator)
  [converted-digits places target %.y]
::
++  format-coordinate
  |=  [scaled=@sd coord-scale=@ud]
  ^-  @t
  (format-sscaled scaled coord-scale %.n)
::
++  format-da
  |=  value=@da
  ^-  @t
  =/  parts  (yore value)
  ?.  ?&  a.parts
          (lte y.parts 9.999)
          =(~ f.t.parts)
      ==
    (scot %da value)
  =/  n2
    |=  number=@ud
    ^-  tape
    ?:  (lth number 10)
      ['0' (a-co:co number)]
    (a-co:co number)
  =/  n4
    |=  number=@ud
    ^-  tape
    =/  txt  (a-co:co number)
    (weld (reap (sub 4 (min 4 (lent txt))) '0') txt)
  %-  crip
  ;:  weld
    (n4 y.parts)
    "-"
    (n2 m.parts)
    "-"
    (n2 d.t.parts)
    " "
    (n2 h.t.parts)
    ":"
    (n2 m.t.parts)
    ":"
    (n2 s.t.parts)
  ==
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
::  An ENTERED total, not a calculated one. `parse-us-price` completes a fuel
::  price to the market's third digit, because a pump price carries one. An
::  invoice total does not: the owner reads $412.75 off the paper and that is
::  the whole observation. So this accepts at most the currency's minor-unit
::  digits and scales exactly, adding nothing.
++  parse-money
  |=  [txt=@t currency=@tas minor-unit-decimals=@ud]
  ^-  (each [total-mills=@ud display=@t] ?(%bad-shape %excess-precision))
  ?.  (lte minor-unit-decimals 3)
    [%| %bad-shape]
  =/  tap  (trim-spaces (trip txt))
  =.  tap
    ?:  ?&  ?=(^ tap)
            =('$' i.tap)
        ==
      (trim-spaces t.tap)
    tap
  =/  parsed  (parse-decimal (crip tap) minor-unit-decimals)
  ?:  ?=(%| -.parsed)
    [%| p.parsed]
  =/  mills
    (mul digits.p.parsed (pow-ten (sub 3 places.p.parsed)))
  [%& [mills (format-total mills currency minor-unit-decimals)]]
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
