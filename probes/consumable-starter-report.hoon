=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-consumable-starter-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM consumable-definitions C WHERE C.archived = N SELECT C.consumable-id, C.label, C.quantity-unit, C.archived;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
