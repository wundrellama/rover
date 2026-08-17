=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-service-subtype-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM service-subtype-definitions S SELECT S.service-subtype-id, S.label, S.archived; FROM vehicle-event-service-subtypes L JOIN service-subtype-definitions S ON L.service-subtype-id = S.service-subtype-id SELECT L.event-id, S.label AS service-subtype; FROM sys.foreign-keys WHERE child-table = %vehicle-event-service-subtypes SELECT parent-table, parent-column, child-column, on-delete, on-update;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
