=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
=/  wire  /rover-address-q9
=/  stamp=tape  (scow %da now)
=/  script=tape
  %-  zing
  :~  "CREATE DATABASE addrq9probe; "
      "CREATE TABLE addrq9probe..places (place-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (place-id); "
      "CREATE TABLE addrq9probe..place-addresses (place-id @ux, source @tas, recorded-at @da) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "CREATE TABLE addrq9probe..place-address-formatted (place-id @ux, formatted @t) PRIMARY KEY (place-id) FOREIGN KEY (place-id) REFERENCES place-addresses (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "CREATE TABLE addrq9probe..place-address-parts (place-id @ux, part @tas, value @t) PRIMARY KEY (place-id, part) FOREIGN KEY (place-id) REFERENCES place-addresses (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "INSERT INTO addrq9probe..places VALUES (0xad90.0001, 'Both Evidence Place', N, "  stamp  "); "
      "INSERT INTO addrq9probe..place-addresses VALUES (0xad90.0001, %imported, "  stamp  "); "
      "INSERT INTO addrq9probe..place-address-formatted VALUES (0xad90.0001, '10 Example Road, Sampletown'); "
      "INSERT INTO addrq9probe..place-address-parts VALUES (0xad90.0001, %line1, '10 Example Road'); "
      "INSERT INTO addrq9probe..places VALUES (0xad90.0002, 'Parts Only Place', N, "  stamp  "); "
      "INSERT INTO addrq9probe..place-addresses VALUES (0xad90.0002, %imported, "  stamp  "); "
      "INSERT INTO addrq9probe..place-address-parts VALUES (0xad90.0002, %line1, '20 Example Road'); "
      "INSERT INTO addrq9probe..place-address-parts VALUES (0xad90.0002, %locality, 'Sampletown'); "
      "INSERT INTO addrq9probe..places VALUES (0xad90.0003, 'Formatted Only Place', N, "  stamp  "); "
      "INSERT INTO addrq9probe..place-addresses VALUES (0xad90.0003, %owner, "  stamp  "); "
      "INSERT INTO addrq9probe..place-address-formatted VALUES (0xad90.0003, '30 Example Road, Sampletown'); "
      "INSERT INTO addrq9probe..places VALUES (0xad90.0004, 'No Address Place', N, "  stamp  "); "
  ==
=/  verify=tape
  %-  zing
  :~  "FROM places P SELECT P.place-id, P.label; "
      "FROM places P JOIN place-addresses A ON P.place-id = A.place-id SELECT P.label, A.source; "
      "FROM places P JOIN place-address-formatted F ON P.place-id = F.place-id SELECT P.label, F.formatted; "
      "FROM places P JOIN place-address-parts A ON P.place-id = A.place-id SELECT P.label, A.part, A.value; "
  ==
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %addrq9probe %vector script]))
;<  [pour-mark=@tas pour-vase=vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %addrq9probe %vector verify]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
