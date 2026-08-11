=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-starter-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM energy-definitions E WHERE E.archived = N SELECT E.energy-definition-id, E.label, E.physical-kind, E.quantity-unit, E.archived; FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id SELECT E.label AS energy, S.label AS subtype, S.archived; FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-octane O ON S.subtype-id = O.subtype-id SELECT E.label AS energy, S.label AS subtype, O.rating, O.method; FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-blend B ON S.subtype-id = B.subtype-id SELECT E.label AS energy, S.label AS subtype, B.blend-kind, B.percent-digits, B.percent-decimals;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
