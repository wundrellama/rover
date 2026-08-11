=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-integrity-delete-station
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "INSERT INTO energy-definitions VALUES (0x8fe1, 'Integrity Station Energy', %reservoir, %gal, N, ~2026.08.11..12.00.00); INSERT INTO vehicles VALUES (0x8fe2, 'Integrity Station Vehicle', N, ~2026.08.11..12.00.00); INSERT INTO vehicle-energy-definitions VALUES (0x8fe2, 0x8fe1, N); INSERT INTO energy-acquisitions VALUES (0x8fe3, 0x8fe2, 0x8fe1, ~2026.7.28..19.01.00, ~2026.7.28..19.01.01, %second, 'America/Chicago', ~2026.08.11..12.00.00); INSERT INTO fuel-fills VALUES (0x8fe3, 1000, %gal, %full, 3499, %usd, %standard, %us-usd-gal, 2, 50); INSERT INTO places VALUES (0x8fe4, 'Integrity Station Place', N, ~2026.08.11..12.00.00); INSERT INTO stations VALUES (0x8fe5, 0x8fe4, 'Integrity Referenced Station', %mixed, N, ~2026.08.11..12.00.00); INSERT INTO energy-acquisition-stations VALUES (0x8fe3, 0x8fe5); DELETE FROM stations WHERE station-id = 0x8fe5;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
