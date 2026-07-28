/-  rover
/+  act=rover-act
::
=/  us=price-preview:rover  (preview-us:act 349)
?>  =(3.499 unit-price-mills.us)
?>  =('$3.499' display.us)
?>  =(%usd currency.us)
?>  =(%us-usd-gal profile.us)
?>  =(349 entered-digits.us)
?>  =(2 entered-decimals.us)
::
=/  eur=price-preview:rover  (preview-eur:act 1.749)
?>  =(1.749 unit-price-mills.eur)
?>  =('EUR 1.749' display.eur)
?>  =(%eur currency.eur)
?>  =(%eu-eur-litre profile.eur)
?>  =(1.749 entered-digits.eur)
?>  =(3 entered-decimals.eur)
::
=/  signature=total-proof:rover
  (derive-fill-total:act 12.345 3.499 2 0 %standard)
?>  =(43.195.155 product.signature)
?>  =(43.200 standard-total-mills.signature)
?>  =(43.200 total-mills.signature)
::
=/  standard=total-proof:rover
  (derive-fill-total:act 12.344 3.499 2 50 %standard)
=/  cash=total-proof:rover
  (derive-fill-total:act 12.344 3.499 2 50 %cash)
?>  =(43.191.656 product.standard)
?>  =(43.190 total-mills.standard)
?>  =(43.200 total-mills.cash)
?>  =(quantity-milli.standard quantity-milli.cash)
?>  =(unit-price-mills.standard unit-price-mills.cash)
?>  =(minor-unit-decimals.standard minor-unit-decimals.cash)
?>  =(cash-increment-mills.standard cash-increment-mills.cash)
%pricing-tests-pass
