=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-live-owner-vehicles
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM vehicles SELECT label, archived;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
