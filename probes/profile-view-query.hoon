=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-profile-view-query
=/  query=tape
  ;:  weld
    "FROM vehicles V SELECT V.vehicle-id, V.label, V.archived; "
    "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id SELECT V.vehicle-id, O.value-digits, O.decimal-places, O.unit, O.observed-start, O.observed-end, O.source-zone, O.recorded-at; "
    "FROM vehicles V JOIN vehicle-energy-definitions L ON V.vehicle-id = L.vehicle-id JOIN energy-definitions E ON L.energy-definition-id = E.energy-definition-id SELECT V.vehicle-id, E.label AS energy, E.physical-kind, E.quantity-unit, E.archived AS energy-archived, L.archived AS link-archived; "
    "FROM vehicles V JOIN vehicle-default-energy-definitions D ON V.vehicle-id = D.vehicle-id JOIN energy-definitions E ON D.energy-definition-id = E.energy-definition-id SELECT V.vehicle-id, E.label AS default-energy; "
    "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id SELECT V.vehicle-id, A.acquisition-id, E.label AS energy, F.quantity-milli, F.quantity-unit, F.tank-state, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills, A.observed-start, A.observed-end, A.source-zone, A.recorded-at;"
    " FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id JOIN charging-costs K ON C.acquisition-id = K.acquisition-id SELECT V.vehicle-id, C.acquisition-id, E.label AS energy, A.observed-start, A.observed-end, A.source-zone, A.recorded-at, K.cost-state, K.currency;"
    " FROM charging-energy-measurements M SELECT M.acquisition-id, M.quantity, M.decimals, M.measure-unit, M.point, M.evidence;"
    " FROM charging-session-batteries L JOIN battery-observation-percent P ON L.battery-observation-id = P.battery-observation-id SELECT L.acquisition-id, L.endpoint, P.value-digits, P.value-decimals;"
    " FROM stations S JOIN places P ON S.place-id = P.place-id SELECT S.station-id, S.label, S.station-kind, S.archived, P.place-id, P.label AS place;"
    " FROM additive-definitions D SELECT D.additive-id, D.label, D.archived;"
    " FROM energy-acquisition-stations L JOIN stations S ON L.station-id = S.station-id JOIN places P ON S.place-id = P.place-id SELECT L.acquisition-id, S.label AS station, P.label AS place;"
    " FROM fuel-fill-additives L JOIN additive-definitions D ON L.additive-id = D.additive-id SELECT L.acquisition-id, D.label AS additive;"
    " FROM vehicle-display-preferences P SELECT P.vehicle-id, P.distance-unit, P.currency;"
    " FROM fuel-fill-subtype L JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id SELECT L.acquisition-id, S.label AS subtype;"
    " FROM energy-definition-subtypes S JOIN energy-definitions E ON S.energy-definition-id = E.energy-definition-id WHERE S.archived = N AND E.archived = N SELECT S.subtype-id, S.energy-definition-id, S.label, S.archived, E.label AS energy;"
    " FROM vehicles V JOIN vehicle-default-energy-subtype D ON V.vehicle-id = D.vehicle-id JOIN energy-definition-subtypes S ON D.subtype-id = S.subtype-id SELECT V.label AS vehicle, S.label AS subtype;"
    " FROM vehicles V JOIN vehicle-driving-modes L ON V.vehicle-id = L.vehicle-id JOIN driving-mode-definitions D ON L.mode-id = D.mode-id SELECT V.label AS vehicle, D.label, D.archived AS mode-archived, L.archived AS link-archived;"
    " FROM tag-definitions T SELECT T.tag-id, T.label, T.archived;"
    " FROM custom-field-definitions C WHERE C.target = %fill SELECT C.field-id, C.label, C.content-type, C.entry-type, C.mandatory, C.archived;"
    " FROM economy-breaks B SELECT B.acquisition-id, B.reason;"
    " FROM app-default-vehicle A JOIN vehicles V ON A.vehicle-id = V.vehicle-id WHERE A.scope = %app SELECT V.vehicle-id, V.label, A.recorded-at;"
    " FROM vehicle-tank-size T SELECT T.vehicle-id, T.digits, T.decimals, T.size-unit;"
    " FROM fuel-fill-odometers L JOIN odometer-observations O ON L.odometer-id = O.odometer-id SELECT L.acquisition-id, O.value-digits, O.decimal-places, O.unit;"
    " FROM energy-definitions E SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived;"
    " FROM fuel-fill-driving-mode L JOIN driving-mode-definitions D ON L.mode-id = D.mode-id SELECT L.acquisition-id, D.label AS driving-mode;"
    " FROM fuel-fill-average-speed S SELECT S.acquisition-id, S.digits, S.decimals, S.speed-unit;"
    " FROM fuel-fill-drive-balance B SELECT B.acquisition-id, B.highway-percent;"
    " FROM fill-notes X SELECT X.acquisition-id, X.note;"
    " FROM fuel-fill-payment-method L JOIN payment-method-definitions P ON L.method-id = P.method-id SELECT L.acquisition-id, P.label AS payment-method;"
    " FROM payment-method-definitions P SELECT P.method-id, P.label, P.archived;"
    " FROM consumable-definitions C SELECT C.consumable-id, C.label, C.quantity-unit, C.archived;"
    " FROM fuel-fill-tags L JOIN tag-definitions T ON L.tag-id = T.tag-id SELECT L.acquisition-id, T.label AS tag;"
    " FROM driving-mode-definitions D SELECT D.mode-id, D.label, D.archived;"
    " FROM vehicles V JOIN vehicle-consumables L ON V.vehicle-id = L.vehicle-id JOIN consumable-definitions C ON L.consumable-id = C.consumable-id SELECT V.vehicle-id, C.consumable-id, C.label AS consumable, L.archived AS link-archived;"
    " FROM vehicle-consumable-tank-size T JOIN consumable-definitions C ON T.consumable-id = C.consumable-id SELECT T.vehicle-id, T.consumable-id, C.label AS consumable, T.digits, T.decimals, T.unit;"
    " FROM vehicles V JOIN consumable-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN consumable-definitions C ON A.consumable-id = C.consumable-id JOIN consumable-purchases P ON A.consumable-acquisition-id = P.consumable-acquisition-id WHERE C.label = 'DEF' SELECT V.vehicle-id, A.consumable-acquisition-id, C.label AS consumable, P.quantity-milli, P.quantity-unit, A.observed-start;"
    " FROM consumable-acquisition-odometers L JOIN odometer-observations O ON L.odometer-id = O.odometer-id SELECT L.consumable-acquisition-id, O.value-digits, O.decimal-places, O.unit;"
    " FROM places P JOIN place-address-parts A ON P.place-id = A.place-id WHERE A.part = %locality SELECT P.place-id, P.label AS place, A.value AS locality;"
  ==
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector query]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m !>(~))
