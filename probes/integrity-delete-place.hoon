=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-integrity-delete-place
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "INSERT INTO places VALUES (0x8fd4, 'Integrity Referenced Place', N, ~2026.08.11..12.00.00); INSERT INTO stations VALUES (0x8fd5, 0x8fd4, 'Integrity Place Station', %mixed, N, ~2026.08.11..12.00.00); DELETE FROM places WHERE place-id = 0x8fd4;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
