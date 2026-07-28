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
+$  entry-verdict  [class=@tas field=@t]
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
  ==
+$  odometer-entry
  $:  vehicle-label=@t
      reading=odo-reading
      observed-start=@da
      source-zone=@t
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
      [%charging-cost-report ~]
      [%charging-evidence-report ~]
      [%content-report ~]
      [%consumption-report ~]
      [%fuel-evidence-report ~]
      [%location-report ~]
      [%pricing-report ~]
      [%run-integrity scenario=integrity-kind]
      [%seed-fuel-evidence ~]
      [%seed-charging-evidence ~]
      [%seed-charging-cost ~]
      [%seed-consumption ~]
      [%seed-location ~]
      [%seed-pricing ~]
      [%seed-spike ~]
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
