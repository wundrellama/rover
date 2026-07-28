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
+$  address-part  ?(%locality %region %postal-code %sublocality %line1 %line2)
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
+$  action
  $%  [%init-db ~]
      [%seed-spike ~]
      [%verify-schema ~]
      [%vehicle-history ~]
      [%current-odometer ~]
  ==
+$  result
  $%  [%ok msg=@t]
      [%err why=@t]
  ==
--
