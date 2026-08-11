=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-current-odometer
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'Phase A Vehicle' SELECT V.label AS vehicle, O.value-digits, O.decimal-places, O.unit, O.observed-start, O.observed-end, O.recorded-at;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
