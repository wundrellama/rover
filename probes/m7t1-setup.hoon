=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-m7t1-setup
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V WHERE V.label = 'M7 T1 Vehicle' SELECT V.vehicle-id, V.label; FROM stations S JOIN places P ON S.place-id = P.place-id WHERE S.label = 'M7 T1 Shop' AND P.label = 'M7 T1 Place' SELECT S.station-id, S.label, P.place-id, P.label AS place; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = 'M7 T1 Vehicle' AND A.observed-start = ~2026.08.01..09.00.00 SELECT V.vehicle-id, A.acquisition-id;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
