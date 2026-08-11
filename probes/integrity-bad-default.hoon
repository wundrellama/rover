=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-integrity-bad-default
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "INSERT INTO energy-definitions VALUES (0x8fa1, 'Integrity Bad Default Energy', %reservoir, %gal, N, ~2026.08.11..12.00.00); INSERT INTO vehicles VALUES (0x8fa2, 'Integrity Bad Default Vehicle', N, ~2026.08.11..12.00.00); INSERT INTO vehicle-default-energy-definitions VALUES (0x8fa2, 0x8fa1);"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
