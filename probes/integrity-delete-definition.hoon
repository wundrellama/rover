=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-integrity-delete-definition
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "INSERT INTO energy-definitions VALUES (0x8fc1, 'Integrity Referenced Energy', %reservoir, %gal, N, ~2026.08.11..12.00.00); INSERT INTO vehicles VALUES (0x8fc2, 'Integrity Definition Vehicle', N, ~2026.08.11..12.00.00); INSERT INTO vehicle-energy-definitions VALUES (0x8fc2, 0x8fc1, N); DELETE FROM energy-definitions WHERE energy-definition-id = 0x8fc1;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
