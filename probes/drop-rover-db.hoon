=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-drop-database
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %sys %vector "DROP DATABASE FORCE rover;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
