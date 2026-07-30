=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
=/  wire  /rover-import-probe
=/  stamp=tape  (scow %da now)
=/  script=tape
  %-  zing
  :~  "CREATE DATABASE impprobe; "
      "CREATE TABLE impprobe..vehicles (vehicle-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (vehicle-id); "
      "CREATE TABLE impprobe..energy-definitions (energy-definition-id @ux, label @t, physical-kind @tas, quantity-unit @tas, archived @f, recorded-at @da) PRIMARY KEY (energy-definition-id); "
      "CREATE TABLE impprobe..vehicle-energy-definitions (vehicle-id @ux, energy-definition-id @ux, archived @f) PRIMARY KEY (vehicle-id, energy-definition-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT, (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "CREATE TABLE impprobe..energy-acquisitions (acquisition-id @ux, vehicle-id @ux, energy-definition-id @ux, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (acquisition-id) FOREIGN KEY (vehicle-id, energy-definition-id) REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "CREATE TABLE impprobe..acquisition-imports (acquisition-id @ux, source-app @tas, source-record-id @t) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
      "INSERT INTO impprobe..vehicles VALUES (0xbeef.0001, 'Import Probe Truck', N, "  stamp  "); "
      "INSERT INTO impprobe..energy-definitions VALUES (0xbeef.0010, 'Diesel', %reservoir, %gal, N, "  stamp  "); "
      "INSERT INTO impprobe..vehicle-energy-definitions VALUES (0xbeef.0001, 0xbeef.0010, N); "
      "INSERT INTO impprobe..energy-acquisitions VALUES (0xbeef.0101, 0xbeef.0001, 0xbeef.0010, ~2026.3.14..08.22.00, ~2026.3.14..08.23.00, %minute, 'America/Chicago', "  stamp  "); "
      "INSERT INTO impprobe..acquisition-imports VALUES (0xbeef.0101, %acar, '78432901'); "
      "INSERT INTO impprobe..energy-acquisitions VALUES (0xbeef.0102, 0xbeef.0001, 0xbeef.0010, ~2026.3.14..08.22.00, ~2026.3.14..08.23.00, %minute, 'America/Chicago', "  stamp  "); "
      "INSERT INTO impprobe..acquisition-imports VALUES (0xbeef.0102, %fuelly, '78432901'); "
      "INSERT INTO impprobe..energy-acquisitions VALUES (0xbeef.0103, 0xbeef.0001, 0xbeef.0010, ~2026.4.1..10.00.00, ~2026.4.1..10.01.00, %minute, 'America/Chicago', "  stamp  "); "
  ==
=/  verify=tape
  %-  zing
  :~  "FROM acquisition-imports I SELECT I.acquisition-id, I.source-app, I.source-record-id; "
      "FROM energy-acquisitions A JOIN acquisition-imports I ON A.acquisition-id = I.acquisition-id WHERE I.source-app = %acar SELECT A.observed-start, I.source-record-id; "
      "FROM energy-acquisitions A SELECT A.acquisition-id, A.observed-start; "
  ==
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %impprobe script]))
;<  [pour-mark=@tas pour-vase=vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape %impprobe verify]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
