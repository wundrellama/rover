=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-live-demo-fills
=/  query=tape
  "FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id WHERE V.label = 'Rover Demo Gasoline' SELECT A.acquisition-id, A.observed-start, F.tank-state; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fill-odometers L ON A.acquisition-id = L.acquisition-id WHERE V.label = 'Rover Demo Gasoline' SELECT A.acquisition-id;"
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %rover query]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
