=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-bootstrap-row-counts
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m
  %-  poke
  :-  [our %obelisk]
  :-  %obelisk-action
  !>  :*
      %script
      %rover
      %vector
      "FROM energy-definitions E SELECT E.energy-definition-id; FROM energy-definition-subtypes S SELECT S.subtype-id; FROM energy-subtype-octane O SELECT O.subtype-id AS octane-subtype-id; FROM energy-subtype-cetane C SELECT C.subtype-id AS cetane-subtype-id; FROM energy-subtype-blend B SELECT B.subtype-id AS blend-subtype-id; FROM consumable-definitions C SELECT C.consumable-id; FROM additive-definitions A SELECT A.additive-id; FROM driving-mode-definitions D SELECT D.mode-id;"
      ==
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
