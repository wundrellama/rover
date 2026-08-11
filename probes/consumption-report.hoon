=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-consumption-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles V JOIN consumption-observations C ON V.vehicle-id = C.vehicle-id WHERE V.label = 'Consumption Evidence Vehicle' SELECT V.label AS vehicle, C.value-digits, C.value-decimals, C.consumption-unit, C.scope, C.source, C.observed-start, C.observed-end, C.observed-precision, C.source-zone;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
