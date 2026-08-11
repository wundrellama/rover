=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-station-report
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector "FROM stations S JOIN places P ON S.place-id = P.place-id WHERE S.label = 'Edit Station' SELECT S.label AS station, P.label AS place, S.station-kind; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-addresses A ON P.place-id = A.place-id WHERE S.label = 'Edit Station' SELECT A.source; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-address-formatted F ON P.place-id = F.place-id WHERE S.label = 'Edit Station' SELECT F.formatted; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-address-parts A ON P.place-id = A.place-id WHERE S.label = 'Edit Station' SELECT A.part, A.value; FROM stations S JOIN places P ON S.place-id = P.place-id JOIN place-coordinates C ON P.place-id = C.place-id WHERE S.label = 'Edit Station' SELECT C.latitude-scaled, C.longitude-scaled, C.coord-scale, C.source;"]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
(pure:m vase)
