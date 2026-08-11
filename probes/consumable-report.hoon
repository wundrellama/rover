=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-consumable-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN consumable-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN consumable-definitions D ON A.consumable-id = D.consumable-id JOIN consumable-purchases P ON A.consumable-acquisition-id = P.consumable-acquisition-id WHERE V.label = 'Rover Demo Diesel' AND D.label = 'DEF' AND A.observed-start = ~2026.07.10..14.00.00 SELECT V.label AS vehicle, D.label AS consumable, P.quantity-milli, P.quantity-unit, P.unit-price-mills, P.currency, P.settlement-mode, P.price-profile, P.minor-unit-decimals, P.cash-increment-mills; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = 'Rover Demo Diesel' SELECT A.acquisition-id AS fuel-acquisition;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
