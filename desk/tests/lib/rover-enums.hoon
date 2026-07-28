/-  rover
|%
++  pricing
  ^-  [(list currency:rover) (list settlement-mode:rover) (list price-profile:rover)]
  :*  ~[%usd %eur %gbp %chf %jpy %krw %cny %brl %cad %aud]
      ~[%standard %cash]
      :~  %us-usd-gal
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
  ==
::
++  definition-attributes
  ^-  [(list octane-method:rover) (list blend-kind:rover)]
  [~[%aki %ron] ~[%ethanol %biodiesel]]
::
++  charging-measurements
  ^-  [(list energy-measure-unit:rover) (list measurement-point:rover) (list measurement-evidence:rover)]
  :*  ~[%kwh %kw %mi %km]
      ~[%wall %charger %vehicle %estimate]
      ~[%measured %reported %vehicle-reported %imported %estimated]
  ==
::
++  battery
  ^-  [(list battery-measure:rover) (list battery-form:rover) (list session-endpoint:rover)]
  :*  ~[%charge-level %health %range-estimate]
      ~[%percent %segments]
      ~[%start %end]
  ==
::
++  charging-cost
  ^-  [(list cost-state:rover) (list cost-component:rover)]
  :*  ~[%free %unknown %itemized %receipt-total-only]
      ~[%energy %time %session %idle %tax %discount]
  ==
::
++  consumption
  ^-  [(list consumption-unit:rover) (list consumption-scope:rover) (list consumption-source:rover)]
  :*  ~[%wh-mi %wh-km %mi-kwh %km-kwh %kwh-100mi %kwh-100km %mpge]
      ~[%instant %trip %since-charge %since-reset %recent-window %lifetime %regulatory]
      ~[%dashboard %telematics %owner %imported]
  ==
::
++  location
  ^-  [(list coordinate-source:rover) (list address-source:rover) (list address-part:rover) (list station-role:rover) (list radius-unit:rover)]
  :*  ~[%owner %gps %receipt %directory %geocoder %imported]
      ~[%owner %receipt %directory %geocoder %imported]
      ~[%country %locality %region %postal-code %sublocality %line1 %line2]
      ~[%brand %operator]
      ~[%metre %foot]
  ==
::
++  breaks
  ^-  [(list economy-break-reason:rover) (list charging-break-reason:rover)]
  :*  ~[%missed-fill %excluded %owner-marked]
      ~[%missed-session %excluded %owner-marked]
  ==
--
