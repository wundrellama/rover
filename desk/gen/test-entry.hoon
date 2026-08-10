/-  rover
/+  entry=rover-entry
=/  good
  %-  decode-fill:entry
  '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"12.345","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T21:30","zone":"America/Chicago","mileage":"10012.5","mileageUnit":"mi","station":"new","newStationLabel":"Home pump","newPlaceLabel":"Home","newStationKind":"private","additives":["Injector cleaner","Fuel stabilizer"]}'
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
?>  ?=(^ new-station.p.good)
?>  =('Home pump' station-label.u.new-station.p.good)
?>  =(%private station-kind.u.new-station.p.good)
?>  =(2 (lent additive-labels.p.good))
::
=/  parts-only
  %-  decode-fill:entry
  '{"vehicle":"Fixture Vehicle","definition":"Fixture Fuel","quantity":"4.250","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-30T09:15","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"new","newStationLabel":"Parts Station","newPlaceLabel":"Parts Place","newStationKind":"fuel","newAddressLine1":"20 Example Road","newLocality":"Sampletown","additives":[]}'
?>  ?=(%& -.parts-only)
?>  ?=(^ new-station.p.parts-only)
?>  ?=(^ address.u.new-station.p.parts-only)
=/  parts-address  u.address.u.new-station.p.parts-only
?>  ?=(~ formatted.parts-address)
?>  ?=(^ line1.parts-address)
?>  =('20 Example Road' u.line1.parts-address)
?>  ?=(^ locality.parts-address)
?>  =('Sampletown' u.locality.parts-address)
::
=/  bad
  %-  decode-fill:entry
  '{"vehicle":"Phase A Vehicle","definition":"Regular 87","quantity":"twelve","price":"$3.49","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-28T21:30","zone":"America/Chicago","mileage":"","mileageUnit":"mi","station":"none","newStationLabel":"","newPlaceLabel":"","newStationKind":"private","additives":[]}'
?>  ?=(%| -.bad)
?>  =(%bad-shape class.p.bad)
?>  =('fill.quantity' field.p.bad)
::
=/  charge
  %-  decode-charge:entry
  '{"vehicle":"Phase A Vehicle","definition":"Electricity","start":"2026-07-28T20:00","end":"2026-07-28T21:00","zone":"America/Chicago","energyDelivered":"42.75","energySource":"charger-reported","startBattery":"20.5","endBattery":"80","mileage":"10020.0","mileageUnit":"mi","costState":"free","currency":"usd"}'
?>  ?=(%& -.charge)
?>  ?=(^ delivered.p.charge)
?>  =(4.275 digits.u.delivered.p.charge)
?>  =(2 places.u.delivered.p.charge)
?>  =(%charger point.u.delivered.p.charge)
?>  =(%reported evidence.u.delivered.p.charge)
?>  ?=(^ start-battery.p.charge)
?>  =(205 digits.u.start-battery.p.charge)
?>  =(1 places.u.start-battery.p.charge)
?>  =(%free cost-state.p.charge)
?>  ?=(~ components.p.charge)
?>  ?=(~ source-total-mills.p.charge)
::
=/  itemized-charge
  %-  decode-charge:entry
  '{"vehicle":"Cost Vehicle","definition":"Electricity","start":"2026-08-01T12:00","end":"2026-08-01T12:45","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[{"component":"energy","quantity":"45.678","unit":"kwh","rate":"0.250","amount":"11.420"},{"component":"discount","quantity":"1","unit":"session","rate":"2.000","amount":"2.000"}]}'
?>  ?=(%& -.itemized-charge)
?>  =(%itemized cost-state.p.itemized-charge)
?>  =(2 (lent components.p.itemized-charge))
?>  ?=(~ source-total-mills.p.itemized-charge)
=/  energy-component  (snag 0 components.p.itemized-charge)
?>  =(%energy component.energy-component)
?>  =(45.678 quantity.energy-component)
?>  =(3 quantity-decimals.energy-component)
?>  =(%kwh quantity-unit.energy-component)
?>  =(250 rate-mills.energy-component)
?>  =(11.420 amount-mills.energy-component)
=/  discount-component  (snag 1 components.p.itemized-charge)
?>  =(%discount component.discount-component)
?>  =(%session quantity-unit.discount-component)
?>  =(2.000 amount-mills.discount-component)
::
=/  receipt-charge
  %-  decode-charge:entry
  '{"vehicle":"Cost Vehicle","definition":"Electricity","start":"2026-08-01T14:00","end":"2026-08-01T14:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"receipt-total-only","currency":"usd","sourceTotal":"22.34","components":[]}'
?>  ?=(%& -.receipt-charge)
?>  =(%receipt-total-only cost-state.p.receipt-charge)
?>  ?=(~ components.p.receipt-charge)
?>  ?=(^ source-total-mills.p.receipt-charge)
?>  =(22.340 u.source-total-mills.p.receipt-charge)
::
=/  empty-itemized
  %-  decode-charge:entry
  '{"vehicle":"Cost Vehicle","definition":"Electricity","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[]}'
?>  ?=(%| -.empty-itemized)
?>  =(%bad-shape class.p.empty-itemized)
?>  =('charge.components' field.p.empty-itemized)
::
=/  unknown-component
  %-  decode-charge:entry
  '{"vehicle":"Cost Vehicle","definition":"Electricity","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[{"component":"parking","quantity":"1","unit":"session","rate":"1.000","amount":"1.000"}]}'
?>  ?=(%| -.unknown-component)
?>  =(%bad-shape class.p.unknown-component)
?>  =('charge.component' field.p.unknown-component)
::
=/  receipt-with-components
  %-  decode-charge:entry
  '{"vehicle":"Cost Vehicle","definition":"Electricity","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"receipt-total-only","currency":"usd","sourceTotal":"22.34","components":[{"component":"energy","quantity":"1","unit":"kwh","rate":"1.000","amount":"1.000"}]}'
?>  ?=(%| -.receipt-with-components)
?>  =(%bad-shape class.p.receipt-with-components)
?>  =('charge.components' field.p.receipt-with-components)
::
=/  free-with-total
  %-  decode-charge:entry
  '{"vehicle":"Cost Vehicle","definition":"Electricity","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"free","currency":"usd","sourceTotal":"22.34","components":[]}'
?>  ?=(%| -.free-with-total)
?>  =(%bad-shape class.p.free-with-total)
?>  =('charge.source-total' field.p.free-with-total)
::
=/  over-discount
  %-  decode-charge:entry
  '{"vehicle":"Cost Vehicle","definition":"Electricity","start":"2026-08-01T16:00","end":"2026-08-01T16:30","zone":"America/Chicago","energyDelivered":"","energySource":"charger-reported","startBattery":"","endBattery":"","mileage":"","mileageUnit":"mi","costState":"itemized","currency":"usd","sourceTotal":"","components":[{"component":"energy","quantity":"1","unit":"kwh","rate":"1.000","amount":"1.000"},{"component":"discount","quantity":"1","unit":"session","rate":"2.000","amount":"2.000"}]}'
?>  ?=(%| -.over-discount)
?>  =(%bad-range class.p.over-discount)
?>  =('charge.components' field.p.over-discount)
::
=/  odometer
  %-  decode-odometer:entry
  '{"vehicle":"Phase A Vehicle","reading":"10,020.125","unit":"mi","observed":"2026-07-28T21:00","zone":"America/Chicago"}'
?>  ?=(%& -.odometer)
?>  =(10.020.125 digits.reading.p.odometer)
?>  =(3 places.reading.p.odometer)
?>  =(%mi odo-unit.reading.p.odometer)
::
=/  preference
  (decode-preference:entry '{"vehicle":"Phase A Vehicle","distanceUnit":"km","currency":"usd"}')
?>  ?=(%& -.preference)
?>  ?=(^ distance-unit.p.preference)
?>  =(%km u.distance-unit.p.preference)
%entry-tests-pass
