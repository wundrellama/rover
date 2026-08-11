=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-pricing-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Pricing Fixture Vehicle' SELECT V.label AS vehicle, E.label AS energy, F.quantity-milli, F.quantity-unit, F.unit-price-mills, F.currency, F.settlement-mode, F.price-profile, F.minor-unit-decimals, F.cash-increment-mills, A.observed-start; FROM sys.columns WHERE namespace = %dbo AND name = %fuel-fills SELECT col-name;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
