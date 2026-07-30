/-  rover
/+  entry=rover-entry
=/  good
  %-  decode-import:entry
  '{"rover-import":1,"source":{"app":"Synthetic"},"definitions":{"energy":[{"label":"Synthetic Diesel","physicalKind":"reservoir","quantityUnit":"gal","subtypes":[{"label":"Synthetic Cetane 45","cetane":"45"}]}],"additives":[],"driving-modes":[],"tags":[],"payment-methods":[]},"places":[],"vehicles":[{"label":"Synthetic Vehicle","distanceUnit":"mi","volumeUnit":"gal","defaultEnergy":"Synthetic Diesel","fills":[{"vehicle":"Synthetic Vehicle","definition":"Synthetic Diesel","quantity":"10.000","price":"3.499","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-30T09:15","zone":"America/Chicago","mileage":"1000.0","mileageUnit":"mi","station":"none","additives":[],"subtype":"Synthetic Cetane 45","missedFill":"no","sourceApp":"synthetic","sourceRecordId":"synthetic-fill-1","sourceTotal":"34.99","tags":[]}]}]}'
?>  ?=(%& -.good)
?>  =(1 (lent vehicles.p.good))
=/  imported-vehicle=import-vehicle:rover  (snag 0 vehicles.p.good)
?>  =('Synthetic Diesel' default-energy.imported-vehicle)
?>  =(1 (lent fills.imported-vehicle))
=/  imported-fill=import-fill:rover  (snag 0 fills.imported-vehicle)
?>  =(%synthetic source-app.imported-fill)
?>  =('synthetic-fill-1' source-record-id.imported-fill)
::
=/  missing-default
  %-  decode-import:entry
  '{"rover-import":1,"source":{"app":"Synthetic"},"definitions":{"energy":[],"additives":[],"driving-modes":[],"tags":[],"payment-methods":[]},"places":[],"vehicles":[{"label":"Vehicle Without Default","distanceUnit":"mi","volumeUnit":"gal","fills":[]}]}'
?>  ?=(%| -.missing-default)
?>  =(%missing-key class.p.missing-default)
?>  =('import.vehicle Vehicle Without Default.defaultEnergy' field.p.missing-default)
%import-tests-pass
