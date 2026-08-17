::  M7 T4. Reads the disposal-kind family and the keying of the two new typed
::  children. It runs through click, so it proves a fresh database holds the
::  starter pack with no page load and no HTTP request of any kind.
=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-disposal-kind-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM disposal-kind-definitions K SELECT K.disposal-kind-id, K.label, K.archived; FROM sys.foreign-keys WHERE child-table = %vehicle-disposals SELECT parent-table, parent-column, child-column, on-delete, on-update; FROM sys.foreign-keys WHERE child-table = %vehicle-acquisitions SELECT parent-table, parent-column, child-column, on-delete, on-update;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
