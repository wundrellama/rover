=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
=/  wire  /rover-cetane-pour
=/  stamp=tape  (scow %da now)
=/  script=tape
  %-  zing
  :~  "CREATE DATABASE cetprobe; "
      "CREATE TABLE cetprobe..energy-definitions (energy-definition-id @ux, label @t, physical-kind @tas, quantity-unit @tas, archived @f, recorded-at @da) PRIMARY KEY (energy-definition-id); "
      "CREATE TABLE cetprobe..energy-definition-subtypes (subtype-id @ux, energy-definition-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (subtype-id) FOREIGN KEY (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "CREATE TABLE cetprobe..energy-subtype-octane (subtype-id @ux, rating @ud, method @tas) PRIMARY KEY (subtype-id) FOREIGN KEY (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "CREATE TABLE cetprobe..energy-subtype-cetane (subtype-id @ux, rating @ud) PRIMARY KEY (subtype-id) FOREIGN KEY (subtype-id) REFERENCES energy-definition-subtypes (subtype-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "INSERT INTO cetprobe..energy-definitions VALUES (0xdada.0001, 'Diesel', %reservoir, %gal, N, "  stamp  "); "
      "INSERT INTO cetprobe..energy-definition-subtypes VALUES (0xdada.0101, 0xdada.0001, 'ULSD', N, "  stamp  "); "
      "INSERT INTO cetprobe..energy-subtype-cetane VALUES (0xdada.0101, 45); "
      "INSERT INTO cetprobe..energy-definitions VALUES (0xdada.0002, 'Gasoline', %reservoir, %gal, N, "  stamp  "); "
      "INSERT INTO cetprobe..energy-definition-subtypes VALUES (0xdada.0201, 0xdada.0002, 'Premium', N, "  stamp  "); "
      "INSERT INTO cetprobe..energy-subtype-octane VALUES (0xdada.0201, 93, %aki); "
  ==
=/  verify=tape
  %-  zing
  :~  "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-cetane C ON S.subtype-id = C.subtype-id SELECT E.label AS energy, S.label AS subtype, C.rating; "
      "FROM energy-definitions E JOIN energy-definition-subtypes S ON E.energy-definition-id = S.energy-definition-id JOIN energy-subtype-octane O ON S.subtype-id = O.subtype-id SELECT E.label AS energy, S.label AS subtype, O.rating, O.method; "
  ==
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %cetprobe script]))
;<  [pour-mark pour-vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %cetprobe verify]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
