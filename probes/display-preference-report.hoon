=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-display-preference-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, O.value-digits, O.decimal-places, O.unit; FROM vehicles V JOIN vehicle-display-preferences P ON V.vehicle-id = P.vehicle-id WHERE V.label = 'Fuel Evidence Vehicle' SELECT V.label AS vehicle, P.distance-unit, P.currency;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
