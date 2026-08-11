=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-try-second-app-default
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "INSERT INTO app-default-vehicle VALUES (%app, 0x1, ~2026.08.11..12.00.00);"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
