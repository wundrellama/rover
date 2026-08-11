=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-charging-cost-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-costs C ON A.acquisition-id = C.acquisition-id WHERE V.label = 'Charging Cost Vehicle' SELECT V.label AS vehicle, A.observed-start, C.cost-state, C.currency; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-cost-components C ON A.acquisition-id = C.acquisition-id WHERE V.label = 'Charging Cost Vehicle' SELECT V.label AS vehicle, C.component, C.quantity, C.quantity-decimals, C.quantity-unit, C.rate-mills, C.amount-mills; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-cost-source-totals T ON A.acquisition-id = T.acquisition-id WHERE V.label = 'Charging Cost Vehicle' SELECT V.label AS vehicle, A.observed-start, T.total-mills;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
