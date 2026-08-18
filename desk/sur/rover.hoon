|%
+$  id  @ux
+$  distance-unit  ?(%mi %km)
+$  precision  ?(%second %minute %day)
+$  physical-kind  ?(%reservoir %electricity)
+$  tank-state  ?(%full %partial)
+$  station-kind  ?(%fuel %charging %mixed %private)
+$  currency  ?(%usd %eur %gbp %chf %jpy %krw %cny %brl %cad %aud)
+$  settlement-mode  ?(%standard %cash)
+$  octane-method  ?(%aki %ron)
::  Which scale a fuel's anti-knock/ignition rating is measured on. Ratified
::  2026-07-30 (import Q2): ignition mode stays a ROVER-SIDE LOOKUP, not a
::  column and not a relation. Nothing is stored; Rover derives the expected
::  scale from the definition and uses it to check that a subtype carries the
::  right rating child.
+$  rating-scale  ?(%octane %cetane)
+$  blend-kind  ?(%ethanol %biodiesel)
+$  energy-measure-unit  ?(%kwh %kw %mi %km)
+$  measurement-point  ?(%wall %charger %vehicle %estimate)
+$  measurement-evidence
  ?(%measured %reported %vehicle-reported %imported %estimated)
+$  battery-measure  ?(%charge-level %health %range-estimate)
+$  battery-form  ?(%percent %segments)
+$  session-endpoint  ?(%start %end)
+$  cost-state  ?(%free %unknown %itemized %receipt-total-only)
+$  cost-component  ?(%energy %time %session %idle %tax %discount)
+$  cost-quantity-unit  ?(%kwh %minute %session)
+$  consumption-unit
  ?(%wh-mi %wh-km %mi-kwh %km-kwh %kwh-100mi %kwh-100km %mpge)
+$  consumption-scope
  ?(%instant %trip %since-charge %since-reset %recent-window %lifetime %regulatory)
+$  consumption-source  ?(%dashboard %telematics %owner %imported)
+$  coordinate-source  ?(%owner %gps %receipt %directory %geocoder %imported)
+$  address-source  ?(%owner %receipt %directory %geocoder %imported)
+$  address-part  ?(%country %locality %region %postal-code %sublocality %line1 %line2)
+$  station-role  ?(%brand %operator)
+$  radius-unit  ?(%metre %foot)
+$  economy-break-reason  ?(%missed-fill %excluded %owner-marked)
+$  charging-break-reason  ?(%missed-session %excluded %owner-marked)
+$  price-profile
  $?  %us-usd-gal
      %eu-eur-litre
      %ch-chf-litre
      %jp-jpy-litre
      %kr-krw-litre
      %cn-cny-litre
      %br-brl-litre
      %uk-gbp-litre
      %ca-cad-litre
      %au-aud-litre
  ==
+$  observed
  $:  start=@da
      end=@da
      =precision
      zone=@t
  ==
+$  odo-reading  [digits=@ud places=@ud odo-unit=distance-unit]
+$  scaled-entry  [digits=@ud places=@ud value-unit=@tas]
+$  entry-verdict  [class=@tas field=@t]
+$  station-address-entry
  $:  formatted=(unit @t)
      line1=(unit @t)
      line2=(unit @t)
      locality=(unit @t)
      region=(unit @t)
      postal-code=(unit @t)
      country=(unit @t)
  ==
+$  station-coordinate-entry
  [latitude=@sd longitude=@sd]
+$  new-station-entry
  $:  place-label=@t
      station-label=@t
      station-kind=station-kind
      address=(unit station-address-entry)
      coordinates=(unit station-coordinate-entry)
  ==
+$  fill-entry
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency
      price-profile=price-profile
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state
      settlement-mode=settlement-mode
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading)
      station-label=(unit @t)
      new-station=(unit new-station-entry)
      additive-labels=(list @t)
      subtype-label=(unit @t)
      missed-fill=?
      driving-mode-label=(unit @t)
      average-speed=(unit scaled-entry)
      drive-balance=(unit @ud)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
      notes=(unit @t)
      payment-method-label=(unit @t)
  ==
+$  import-simple-definition
  [label=@t]
+$  import-subtype-default
  $:  time-interval=@ud
      time-unit=reminder-time-unit
      distance-digits=@ud
      distance-places=@ud
      distance-unit=distance-unit
  ==
+$  import-service-subtype
  [label=@t default=(unit import-subtype-default)]
+$  import-energy-subtype
  $:  label=@t
      octane=(unit @ud)
      octane-method=(unit octane-method)
      cetane=(unit @ud)
      blends=(list [kind=blend-kind digits=@ud places=@ud])
      grade-code=(unit @t)
  ==
+$  import-energy-definition
  $:  label=@t
      physical-kind=physical-kind
      quantity-unit=@tas
      subtypes=(list import-energy-subtype)
  ==
+$  import-place-address
  $:  formatted=(unit @t)
      parts=(list [part=address-part value=@t])
      source=address-source
  ==
+$  import-place-coordinates
  $:  latitude=@sd
      longitude=@sd
      source=coordinate-source
      accuracy=(unit [digits=@ud places=@ud unit=radius-unit])
  ==
+$  import-station
  $:  label=@t
      station-kind=station-kind
      brand-operators=(list [role=station-role label=@t])
      identifiers=(list [provider=@tas external-id=@t])
  ==
+$  import-place
  $:  label=@t
      station-kind=station-kind
      address=(unit import-place-address)
      coordinates=(unit import-place-coordinates)
      stations=(list import-station)
  ==
+$  import-custom-value
  $:  label=@t
      content-type=@tas
      value-text=@t
      value-unit=@tas
      boolean-value=?
  ==
+$  import-fill
  $:  input=fill-entry
      source-app=(unit @tas)
      source-record-id=(unit @t)
      source-total=(unit @t)
      custom-values=(list import-custom-value)
  ==
+$  import-event
  $:  input=event-entry
      source-app=(unit @tas)
      source-record-id=(unit @t)
  ==
+$  import-consumable-definition
  [label=@t quantity-unit=@tas]
+$  import-custom-option
  [ordinal=@ud label=@t]
+$  import-custom-definition
  $:  label=@t
      content-type=@tas
      entry-type=@tas
      mandatory=?
      target=@tas
      options=(list import-custom-option)
  ==
+$  import-archive
  [family=@tas label=@t]
+$  import-consumable
  [input=consumable-entry station-label=(unit @t)]
+$  import-vehicle-consumable
  [label=@t tank-size=(unit scaled-entry)]
+$  import-vehicle
  $:  label=@t
      distance-unit=distance-unit
      volume-unit=@tas
      tank-size=(unit scaled-entry)
      default-energy=@t
      specification=vehicle-spec-entry
      fills=(list import-fill)
      service-events=(list import-event)
      note-events=(list import-event)
      reminders=(list reminder-entry)
      additional-energy=(list @t)
      driving-modes=(list @t)
      default-subtype=(unit @t)
      refill-reserve=(unit @ud)
      charging-sessions=(list charge-entry)
      consumable-acquisitions=(list import-consumable)
      expense-events=(list import-event)
      acquisition-events=(list import-event)
      disposal-events=(list import-event)
      odometers=(list odometer-entry)
      vehicle-consumables=(list import-vehicle-consumable)
  ==
+$  import-definitions
  $:  energy=(list import-energy-definition)
      service-subtypes=(list import-service-subtype)
      additives=(list import-simple-definition)
      driving-modes=(list import-simple-definition)
      tags=(list import-simple-definition)
      payment-methods=(list import-simple-definition)
      consumables=(list import-consumable-definition)
      disposal-kinds=(list import-simple-definition)
      custom-fields=(list import-custom-definition)
  ==
+$  import-document
  $:  definitions=import-definitions
      places=(list import-place)
      vehicles=(list import-vehicle)
      archives=(list import-archive)
  ==
+$  import-simple-kind  ?(%additive %driving-mode %tag %payment-method %disposal-kind)
+$  import-work
  $%  [%energy value=import-energy-definition]
      [%service-subtype value=import-service-subtype]
      [%simple kind=import-simple-kind value=import-simple-definition]
      [%place value=import-place]
      [%vehicle value=import-vehicle]
      $:  %fill
          distance-unit=distance-unit
          volume-unit=@tas
          value=import-fill
      ==
      [%event value=import-event]
      [%reminder value=reminder-entry]
      [%consumable-definition value=import-consumable-definition]
      [%custom-definition value=import-custom-definition]
      [%charge value=charge-entry]
      [%consumable value=import-consumable]
      [%odometer value=odometer-entry]
      [%archive value=import-archive]
  ==
+$  import-report
  $:  imported=@ud
      already-imported=@ud
      conflicts=@ud
      failures=@ud
      definitions-created=@ud
      definitions-reused=@ud
      places-created=@ud
      places-reused=@ud
      vehicles-created=@ud
      vehicles-reused=@ud
      station-none=@ud
      total-exact=@ud
      total-off-by-one=@ud
      total-beyond=@ud
      unit-mismatches=@ud
      events-imported=@ud
      events-already-imported=@ud
      event-conflicts=@ud
      reminders-imported=@ud
      reminders-already-imported=@ud
      subtype-defaults-created=@ud
      subtype-defaults-reused=@ud
      messages=(list @t)
  ==
+$  import-run
  $:  eyre-id=@ta
      writing=?
      serial=@ud
      remaining=(list import-work)
      report=import-report
  ==
+$  delivered-energy
  $:  digits=@ud
      places=@ud
      point=measurement-point
      evidence=measurement-evidence
  ==
+$  battery-reading  [digits=@ud places=@ud]
::  One itemized charging-cost line as the owner entered it. Quantity keeps
::  source-native digits and decimals; rate and amount are exact mills. The
::  amount is source-reported, not quantity times rate: a tariff may round.
+$  charging-component-entry
  $:  component=cost-component
      quantity=@ud
      quantity-decimals=@ud
      quantity-unit=cost-quantity-unit
      rate-mills=@ud
      amount-mills=@ud
  ==
+$  charge-entry
  $:  vehicle-label=@t
      definition-label=@t
      observed-start=@da
      observed-end=@da
      source-zone=@t
      delivered=(unit delivered-energy)
      start-battery=(unit battery-reading)
      end-battery=(unit battery-reading)
      mileage=(unit odo-reading)
      cost-state=cost-state
      currency=currency
      components=(list charging-component-entry)
      source-total-mills=(unit @ud)
      subtype-label=(unit @t)
  ==
+$  consumable-entry
  $:  vehicle-label=@t
      consumable-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency
      price-profile=price-profile
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      settlement-mode=settlement-mode
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading)
  ==
+$  odometer-entry
  $:  vehicle-label=@t
      reading=odo-reading
      observed-start=@da
      source-zone=@t
  ==
::  Which typed child of `vehicle-events` a new event creates. The kind is not
::  a column: it is which child row exists. This term never reaches the
::  database - it selects the INSERT target and nothing else.
::
::  M7 T4 extends the union rather than adding a second decoder. Acquisition
::  and disposal reach the same handler through their own routes, so a client
::  cannot name a kind that disagrees with the child it gets.
+$  event-kind  ?(%service %expense %note %acquisition %disposal)
::  One vehicle event as a human entered it (M7 T1). Every optional member is
::  a unit, and a `~` writes NO row rather than a bunt, a zero, or an empty
::  string. The total is entered: a shop invoice has no quantity and no unit
::  price, so there is nothing to multiply.
+$  event-entry
  $:  vehicle-label=@t
      kind=event-kind
      observed-start=@da
      source-zone=@t
      total-mills=(unit @ud)
      total-display=@t
      currency=currency
      minor-unit-decimals=@ud
      mileage=(unit odo-reading)
      station-label=(unit @t)
      new-station=(unit new-station-entry)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
      ::  M7 T2. Several subtypes at once, because the real corpus holds one
      ::  service record carrying ten. An empty list writes NO link row: the
      ::  absence of the rows is what "no subtype" means, and there is no
      ::  `None` definition and no sentinel row.
      subtype-labels=(list @t)
      ::  M7 T4. The kind of disposal, by label. It is mandatory on a disposal
      ::  and absent on every other kind: a sale, a write-off, and a theft are
      ::  different facts, and the amount alone cannot tell them apart. An
      ::  acquisition carries no kind - see the T4 report for why.
      disposal-kind-label=(unit @t)
      payment-method-label=(unit @t)
      notes=(unit @t)
  ==
::  M7 T6. How long a reminder interval runs. A term, never a baked count of
::  seconds: three months is a calendar step, and a column holding 7.776.000
::  seconds would say something else and would round differently every month.
+$  reminder-time-unit  ?(%day %week %month %year)
::  An interval in time and the point it is next due. The two travel together
::  because a reminder with a due point and no interval cannot advance, and an
::  interval with no due point has nowhere to start.
+$  reminder-time-entry
  [interval-count=@ud interval-unit=reminder-time-unit due-at=@da]
::  An interval in distance and the reading it is next due at, both in one
::  unit. Source-native digits and precision are retained exactly, the way
::  every other distance in Rover is.
+$  reminder-distance-entry
  $:  interval-digits=@ud
      interval-places=@ud
      due-digits=@ud
      due-places=@ud
      reminder-distance-unit=distance-unit
  ==
::  One reminder as a human entered it. Each interval is optional and each
::  absent one writes NO child row - never a zero interval and never a bunt
::  date. At least one of the two must be present: a reminder with neither
::  interval names no moment at all.
+$  reminder-entry
  $:  vehicle-label=@t
      subtype-label=@t
      time=(unit reminder-time-entry)
      distance=(unit reminder-distance-entry)
  ==
+$  preference-entry
  [vehicle-label=@t distance-unit=(unit distance-unit) currency=currency]
+$  vehicle-label-entry  [vehicle-label=@t]
+$  new-vehicle-entry
  $:  vehicle-label=@t
      energy-label=@t
      additional-energy-labels=(list @t)
      driving-mode-labels=(list @t)
      def-enabled=?
      def-tank-size=(unit scaled-entry)
  ==
::  M7 T7. One specification field, as a person left it in the form.
::
::  Two units, because there are three states and two are not enough. The
::  OUTER one says whether the body named the field at all: a body that never
::  mentions a make leaves the make exactly as it was. The INNER one says
::  whether the person put anything in it: a field sent empty removes its row.
::  A value is a row, an absence is NO row, and neither is ever an empty
::  string, a zero, or a bunt.
+$  spec-text  (unit (unit @t))
+$  spec-number  (unit (unit @ud))
::  The twelve specification fields plus the vehicle note. Insurance is NOT
::  here: ruled 2026-08-18, a bare policy string is a stub of a feature rather
::  than a feature, and the fence stays shut until insurance is designed whole.
::
::  `vin` and `plate` are identifying personal data. They travel in this one
::  entry because one form writes them, but they reach two relations of their
::  own and share none with a descriptive field.
+$  vehicle-spec-entry
  $:  vin=spec-text
      plate=spec-text
      model-year=spec-number
      make=spec-text
      model=spec-text
      sub-model=spec-text
      body-type=spec-text
      color=spec-text
      engine=spec-text
      transmission=spec-text
      drive-type=spec-text
      bed-type=spec-text
      note=spec-text
  ==
+$  vehicle-edit-entry
  $:  vehicle-label=@t
      label=@t
      tank-size=(unit scaled-entry)
      refill-reserve=(unit @ud)
      default-subtype=(unit @t)
      default-energy=(unit @t)
      energy-labels=(unit (list @t))
      driving-mode-labels=(unit (list @t))
      def-enabled=(unit ?)
      def-tank-size=(unit scaled-entry)
      specification=vehicle-spec-entry
  ==
+$  custom-definition-entry
  [label=@t content-type=@tas mandatory=?]
+$  custom-field-change-entry
  [label=@t content-type=@tas]
+$  custom-field-label-entry  [label=@t]
::  M7 T8. The definition lifecycle. One shape serves rename, archive and
::  restore, because all three address one definition the same way: the family
::  it belongs to, then its label. `new-label` is empty for archive and for
::  restore, which carry no second label.
::
::  The label is the address. Rover has no other handle on a definition at the
::  Eyre boundary, because a raw machine ID never crosses it.
+$  definition-operation  ?(%rename %archive %restore)
+$  definition-lifecycle-entry
  $:  family=@tas
      label=@t
      new-label=@t
  ==
::  A definition family, as the write path needs it: the term a request names,
::  the relation the rows live in, and the column that keys them.
+$  definition-family
  $:  family=@tas
      relation=@t
      id-column=@t
  ==
+$  price-preview
  $:  currency=currency
      profile=price-profile
      entered-digits=@ud
      entered-decimals=@ud
      unit-price-mills=@ud
      display=@t
  ==
+$  total-proof
  $:  quantity-milli=@ud
      unit-price-mills=@ud
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      settlement-mode=settlement-mode
      product=@ud
      standard-total-mills=@ud
      total-mills=@ud
  ==
+$  fill-total-input
  $:  quantity-milli=@ud
      unit-price-mills=@ud
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      settlement-mode=settlement-mode
  ==
+$  charging-component-amount
  [component=cost-component amount-mills=@ud]
+$  charging-total-proof
  $:  positive-mills=@ud
      discount-mills=@ud
      total-mills=@ud
  ==
+$  integrity-kind
  $?  %missing-pair
      %bad-default
      %delete-vehicle
      %delete-definition
      %delete-place
      %delete-station
      %zero-subtype
      %two-subtypes
  ==
+$  integrity-proof
  $:  scenario=integrity-kind
      rejected=?
      message=@t
  ==
+$  action
  $%  [%init-db ~]
      [%ensure-ui-schema ~]
      [%ensure-def-schema ~]
      [%verify-schema ~]
      [%seed-starters ~]
  ==
+$  result
  $%  [%ok msg=@t]
      [%err why=@t]
  ==
--
