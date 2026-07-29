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
  $:  formatted=@t
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
+$  delivered-energy
  $:  digits=@ud
      places=@ud
      point=measurement-point
      evidence=measurement-evidence
  ==
+$  battery-reading  [digits=@ud places=@ud]
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
+$  vehicle-edit-entry
  $:  vehicle-label=@t
      label=@t
      tank-size=(unit scaled-entry)
      default-subtype=(unit @t)
      energy-labels=(unit (list @t))
      driving-mode-labels=(unit (list @t))
      def-enabled=(unit ?)
      def-tank-size=(unit scaled-entry)
  ==
+$  custom-definition-entry
  [label=@t content-type=@tas mandatory=?]
+$  custom-field-change-entry
  [label=@t content-type=@tas]
+$  custom-field-label-entry  [label=@t]
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
      [%app-structure-report ~]
      [%ensure-ui-schema ~]
      [%ensure-def-schema ~]
      [%display-preference-report ~]
      [%charging-cost-report ~]
      [%charging-evidence-report ~]
      [%content-report ~]
      [%consumption-report ~]
      [%fuel-evidence-report ~]
      [%location-report ~]
      [%pricing-report ~]
      [%run-integrity scenario=integrity-kind]
      [%rename-energy-source old-label=@t new-label=@t]
      [%seed-fill-edit-support vehicle-label=@t]
      [%fill-edit-report vehicle-label=@t observed-start=@da]
      [%station-report station-label=@t]
      [%consumable-report vehicle-label=@t consumable-label=@t observed-start=@da]
      [%charge-subtype-report vehicle-label=@t observed-start=@da]
      [%vehicle-settings-report vehicle-label=@t]
      [%seed-starters ~]
      [%starter-report ~]
      [%seed-fuel-evidence ~]
      [%seed-app-structure ~]
      [%seed-charging-evidence ~]
      [%seed-charging-cost ~]
      [%seed-consumption ~]
      [%seed-location ~]
      [%seed-pricing ~]
      [%seed-spike ~]
      [%try-second-app-default ~]
      [%verify-schema ~]
      [%vehicle-history ~]
      [%current-odometer ~]
      [%derive-charging-total components=(list charging-component-amount)]
      [%preview-us entered-cents=@ud]
      [%preview-eur entered-mills=@ud]
      [%derive-fill-total input=fill-total-input]
  ==
+$  result
  $%  [%ok msg=@t]
      [%err why=@t]
  ==
--
