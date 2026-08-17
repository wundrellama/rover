=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-disposal-kind-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM disposal-kind-definitions D SELECT D.disposal-kind-id, D.label, D.archived; FROM sys.foreign-keys WHERE child-table = %vehicle-disposals SELECT parent-table, parent-column, child-column, on-delete, on-update;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
