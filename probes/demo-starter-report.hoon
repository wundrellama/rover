=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-demo-starter-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN energy-definitions E ON A.energy-definition-id = E.energy-definition-id WHERE V.label = 'Rover Demo Gasoline' OR V.label = 'Rover Demo Diesel' SELECT V.label AS vehicle, A.energy-definition-id AS demo-energy-definition-id, E.energy-definition-id AS starter-energy-definition-id, E.label AS starter-energy; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-subtype L ON A.acquisition-id = L.acquisition-id JOIN energy-definition-subtypes S ON L.subtype-id = S.subtype-id WHERE V.label = 'Rover Demo Gasoline' OR V.label = 'Rover Demo Diesel' SELECT V.label AS vehicle, A.energy-definition-id AS demo-energy-definition-id, S.energy-definition-id AS subtype-parent-definition-id, L.subtype-id AS demo-subtype-id, S.subtype-id AS starter-subtype-id, S.label AS starter-subtype;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
