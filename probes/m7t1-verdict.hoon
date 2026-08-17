=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
=/  wire  /rover-m7t1-verdict
=/  query
  "FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id WHERE V.label = 'M7 T1 Vehicle' SELECT E.event-id; FROM vehicles V JOIN odometer-observations O ON V.vehicle-id = O.vehicle-id WHERE V.label = 'M7 T1 Vehicle' SELECT O.odometer-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN service-events S ON E.event-id = S.event-id WHERE V.label = 'M7 T1 Vehicle' SELECT E.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN expense-events X ON E.event-id = X.event-id WHERE V.label = 'M7 T1 Vehicle' SELECT E.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN note-events H ON E.event-id = H.event-id WHERE V.label = 'M7 T1 Vehicle' SELECT E.event-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN vehicle-event-costs C ON E.event-id = C.event-id JOIN vehicle-event-cost-source-totals T ON C.event-id = T.event-id WHERE V.label = 'M7 T1 Vehicle' SELECT T.total-mills; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN expense-events X ON E.event-id = X.event-id JOIN vehicle-event-stations S ON E.event-id = S.event-id WHERE V.label = 'M7 T1 Vehicle' SELECT S.station-id; FROM vehicles V JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN note-events H ON E.event-id = H.event-id JOIN vehicle-event-costs C ON E.event-id = C.event-id WHERE V.label = 'M7 T1 Vehicle' SELECT C.event-id; FROM places P WHERE P.label = 'M7 T1 Place' SELECT P.place-id; FROM stations S WHERE S.label = 'M7 T1 Shop' SELECT S.station-id; FROM vehicles V JOIN energy-acquisitions A ON V.vehicle-id = A.vehicle-id JOIN fuel-fills F ON A.acquisition-id = F.acquisition-id JOIN energy-acquisition-stations FS ON A.acquisition-id = FS.acquisition-id JOIN vehicle-events E ON V.vehicle-id = E.vehicle-id JOIN service-events S ON E.event-id = S.event-id JOIN vehicle-event-stations ES ON E.event-id = ES.event-id WHERE V.label = 'M7 T1 Vehicle' AND FS.station-id = ES.station-id SELECT E.event-id;"
;<  ~  bind:m  (watch wire [our %obelisk] /server)
;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%script %rover %vector query]))
;<  [mark =vase]  bind:m  (take-fact wire)
;<  ~  bind:m  (take-kick wire)
=/  counts=(list @ud)
  =/  commands=(list *)  ;;((list *) +.q.vase)
  %+  turn  commands
  |=  command=*
  =/  results=(list *)  ;;((list *) +.command)
  |-
  ?~  results
    0
  =/  result=*  i.results
  ?:  ?&  ?^  result
          =(%vector-count -.result)
          ?=(@ +.result)
      ==
    ;;(@ud +.result)
  $(results t.results)
=/  expected=(list @ud)  ~[3 4 1 1 1 2 0 0 1 1 1]
=/  verdict
  ?:  =(expected counts)
    [%m7t1-pass 3 4 1 1 1 2 0 0 1 1 1]
  [%m7t1-fail counts]
(pure:m !>(verdict))
