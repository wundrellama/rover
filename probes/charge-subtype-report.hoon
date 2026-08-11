=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-charge-subtype-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN charging-sessions C ON A.acquisition-id = C.acquisition-id JOIN charging-session-subtype L ON C.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE A.observed-start = ~2026.07.31..12.00.00 SELECT V.label AS vehicle, S.label AS charging-subtype;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
