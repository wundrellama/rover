/-  rover
/+  act=rover-act, entry=rover-entry, imp=rover-import
=/  good
  %-  decode-import:entry
  '{"rover-import":1,"source":{"app":"Synthetic"},"definitions":{"energy":[{"label":"Synthetic Diesel","physicalKind":"reservoir","quantityUnit":"gal","subtypes":[{"label":"Synthetic Cetane 45","cetane":"45"}]}],"additives":[],"driving-modes":[],"tags":[],"payment-methods":[]},"places":[],"vehicles":[{"label":"Synthetic Vehicle","distanceUnit":"mi","volumeUnit":"gal","defaultEnergy":"Synthetic Diesel","fills":[{"vehicle":"Synthetic Vehicle","definition":"Synthetic Diesel","quantity":"10.000","price":"3.499","profile":"us-usd-gal","tank":"full","settlement":"standard","observed":"2026-07-30T09:15","zone":"America/Chicago","mileage":"1000.0","mileageUnit":"mi","station":"none","additives":[],"subtype":"Synthetic Cetane 45","missedFill":"no","sourceApp":"synthetic","sourceRecordId":"synthetic-fill-1","sourceTotal":"34.99","tags":[]}]}]}'
?>  ?=(%& -.good)
?>  =(1 (lent vehicles.p.good))
=/  imported-energy=import-energy-definition:rover
  (snag 0 energy.definitions.p.good)
?>  (contains:imp (energy-lookup:imp imported-energy) "FROM energy-definition-subtypes")
=/  subtype-only-script
  (insert-energy-subtypes:imp 0x4321 0x2002 subtypes.imported-energy ~2026.7.30..09.15.00)
?>  (contains:imp subtype-only-script "INSERT INTO energy-definition-subtypes")
?>  !(contains:imp subtype-only-script "INSERT INTO energy-definitions")
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
::
=/  mismatch-input=import-vehicle:rover
  imported-vehicle(distance-unit %km, volume-unit %litre)
=/  mismatches  (unit-mismatches:imp mismatch-input)
?>  =(2 (lent mismatches))
::
=/  total-class
  (source-total-class:imp imported-fill)
?>  ?=(^ total-class)
?>  =(%exact u.total-class)
=/  precise-total-fill=import-fill:rover
  imported-fill(source-total `'34.99000')
=/  precise-total-class
  (source-total-class:imp precise-total-fill)
?>  ?=(^ precise-total-class)
?>  =(%exact u.precise-total-class)
=/  report  (initial-report:imp p.good)
?>  =(1 station-none.report)
?>  =(1 total-exact.report)
?>  =(0 unit-mismatches.report)
?>  =(3 (lent (import-works:imp p.good)))
::
=/  base  0x1234
=/  ids=entry-ids:act
  :*  (fixture-id:act base 101)
      (fixture-id:act base 102)
      (fixture-id:act base 103)
      (fixture-id:act base 104)
      (fixture-id:act base 105)
  ==
?>  =(5 (lent (unique-ids:act [acquisition.ids odometer.ids place.ids station.ids tag.ids ~])))
?>  !=(0 acquisition.ids)
?>  !=(0 odometer.ids)
?>  !=(0 place.ids)
?>  !=(0 station.ids)
?>  !=(0 tag.ids)
=/  canonical
  (canonical-fill:imp input.imported-fill)
=/  script
  %:  insert-import-fill:imp
      ids
      0x2001
      0x2002
      %gal
      ~
      ~
      `0x2003
      ~
      ~
      ~
      canonical
      source-app.imported-fill
      source-record-id.imported-fill
      ~2026.7.30..09.15.00
  ==
?>  (contains:imp script "INSERT INTO acquisition-imports VALUES")
?>  !(contains:imp script "vehicle-display-preferences")
?>  !(contains:imp script "UPSERT")
?>  !(contains:imp script " AS OF ")
?>  (contains:imp (fill-existing-lookup:imp imported-fill) "acquisition-imports I")
?>  !(contains:imp (fill-existing-lookup:imp imported-fill) "FROM vehicles V JOIN vehicle-energy-definitions")
?>  (contains:imp (fill-support-lookup:imp imported-fill) "FROM vehicles V JOIN vehicle-energy-definitions")
=/  apostrophe-text=@t  (crip "Driver's")
?>  =("Driver\\'s" (sql-quote:act apostrophe-text))
?>  =(%.n (urql-cord-safe:imp (crip "first\0asecond")))
%import-tests-pass
