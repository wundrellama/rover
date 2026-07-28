/-  rover
/+  entry=rover-entry
=/  good
  %-  decode-fill:entry
  '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"12.345","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T21:30","zone":"America/Chicago","mileage":"10012.5","mileageUnit":"mi"}'
?>  ?=(%& -.good)
?>  =(12.345 quantity-milli.p.good)
?>  =(3.499 unit-price-mills.p.good)
?>  =('$3.499' price-display.p.good)
?>  =(%usd currency.p.good)
?>  =(%us-usd-gal price-profile.p.good)
?>  =(2 minor-unit-decimals.p.good)
?>  =(50 cash-increment-mills.p.good)
?>  =(%full tank-state.p.good)
?>  =(%standard settlement-mode.p.good)
?>  ?=(^ mileage.p.good)
?>  =(100.125 digits.u.mileage.p.good)
?>  =(1 places.u.mileage.p.good)
?>  =(%mi odo-unit.u.mileage.p.good)
::
=/  bad
  %-  decode-fill:entry
  '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"twelve","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T21:30","zone":"America/Chicago","mileage":"","mileageUnit":"mi"}'
?>  ?=(%| -.bad)
?>  =(%bad-shape class.p.bad)
?>  =('fill.quantity' field.p.bad)
%entry-tests-pass
