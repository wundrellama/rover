=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-integrity-missing-pair
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "INSERT INTO energy-definitions VALUES (0x8f91, 'Integrity Missing Pair Energy', %reservoir, %gal, N, ~2026.08.11..12.00.00); INSERT INTO vehicles VALUES (0x8f92, 'Integrity Missing Pair Vehicle', N, ~2026.08.11..12.00.00); INSERT INTO energy-acquisitions VALUES (0x8f93, 0x8f92, 0x8f91, ~2026.7.28..19.00.00, ~2026.7.28..19.00.01, %second, 'America/Chicago', ~2026.08.11..12.00.00);"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
