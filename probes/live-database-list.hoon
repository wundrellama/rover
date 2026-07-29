=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-live-databases
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %sys "FROM sys.sys.databases SELECT database;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
