::  app/rover - lean tracer: accept %init-db, apply M0 schema to %obelisk.
::  One path, proven. Other actions land as separate proven increments.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, default-agent, dbug, entry=rover-entry, exp=rover-export, imp=rover-import, render=rover-render, view=rover-view
/*  shell-html  %html  /app/rover/shell/html
/*  tile-png    %png   /app/rover/assets/tile/png
/*  font-regular       %woff2x  /app/rover/assets/fonts/jetbrainsmono-regular/woff2x
/*  font-bold          %woff2x  /app/rover/assets/fonts/jetbrainsmono-bold/woff2x
|%
+$  versioned-state
  $%  [%0 state-0]
      [%1 state-1]
      [%2 state-2]
      [%3 state-3]
      [%4 state-4]
      [%5 state-5]
      [%6 state-6]
      [%7 state-7]
      [%8 state-8]
      [%9 state-9]
      [%10 state-10]
      [%11 state-11]
      [%12 state-12]
      [%13 state-13]
      [%14 state-14]
      [%15 state-15]
      [%16 state-16]
      [%17 state-17]
      [%18 state-18]
      [%19 state-19]
  ==
+$  new-station-entry-10
  [place-label=@t station-label=@t station-kind=station-kind:rover]
+$  station-address-entry-13
  $:  formatted=@t
      line1=(unit @t)
      line2=(unit @t)
      locality=(unit @t)
      region=(unit @t)
      postal-code=(unit @t)
      country=(unit @t)
  ==
+$  new-station-entry-13
  $:  place-label=@t
      station-label=@t
      station-kind=station-kind:rover
      address=(unit station-address-entry-13)
      coordinates=(unit station-coordinate-entry:rover)
  ==
+$  fill-entry-13
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-13)
      additive-labels=(list @t)
      subtype-label=(unit @t)
      missed-fill=?
      driving-mode-label=(unit @t)
      average-speed=(unit scaled-entry:rover)
      drive-balance=(unit @ud)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
      notes=(unit @t)
      payment-method-label=(unit @t)
  ==
+$  fill-entry-5
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
  ==
+$  fill-entry-8
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-10)
      additive-labels=(list @t)
  ==
+$  fill-entry-10
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-10)
      additive-labels=(list @t)
      subtype-label=(unit @t)
      missed-fill=?
      driving-mode-label=(unit @t)
      average-speed=(unit scaled-entry:rover)
      drive-balance=(unit @ud)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
  ==
+$  state-0
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
  ==
+$  state-1
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
  ==
+$  state-2
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
  ==
+$  state-3
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
  ==
+$  state-4
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
  ==
+$  state-5
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
  ==
+$  state-6
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-5)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
  ==
+$  state-7
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
  ==
+$  state-8
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-8)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
  ==
+$  state-9
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
  ==
+$  state-10
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  state-11
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-11)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  fill-entry-11
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-10)
      additive-labels=(list @t)
      subtype-label=(unit @t)
      missed-fill=?
      driving-mode-label=(unit @t)
      average-speed=(unit scaled-entry:rover)
      drive-balance=(unit @ud)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
      notes=(unit @t)
      payment-method-label=(unit @t)
  ==
+$  state-12
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry-12)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  charge-entry-12
  $:  vehicle-label=@t
      definition-label=@t
      observed-start=@da
      observed-end=@da
      source-zone=@t
      delivered=(unit delivered-energy:rover)
      start-battery=(unit battery-reading:rover)
      end-battery=(unit battery-reading:rover)
      mileage=(unit odo-reading:rover)
      cost-state=cost-state:rover
      currency=currency:rover
  ==
+$  state-13
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-13)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  state-14
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  charge-entry-15
  $:  vehicle-label=@t
      definition-label=@t
      observed-start=@da
      observed-end=@da
      source-zone=@t
      delivered=(unit delivered-energy:rover)
      start-battery=(unit battery-reading:rover)
      end-battery=(unit battery-reading:rover)
      mileage=(unit odo-reading:rover)
      cost-state=cost-state:rover
      currency=currency:rover
      subtype-label=(unit @t)
  ==
+$  state-15
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit import-run:rover)
  ==
+$  state-16
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
  ==
::  M7 T10 widened the import document, so `import-run` holds a different
::  noun than it did. The flag is transient - it is `~` except during an
::  import that is in flight - so the archival mold reads it as a bare noun
::  and the migration drops it rather than reshaping work that a code reload
::  has already interrupted.
+$  state-17
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
      bootstrap-ready=?
  ==
+$  state-18
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
      bootstrap-ready=?
  ==
::  M7 T10 again. `import-run` now carries the row a comparison is reading,
::  so the noun changed shape a second time. The rule is the same: the
::  archival mold reads it as a bare noun, and the migration drops an import
::  that a code reload already interrupted.
+$  state-19
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit import-run:rover)
      bootstrap-ready=?
  ==
+$  card  card:agent:gall
--
=>  |%
++  bind-eyre
  ^-  card
  [%pass /eyre/connect %arvo %e %connect [~ /apps/rover] %rover]
::
++  http-give
  |=  [eyre-id=@ta status=@ud hed=header-list:http bod=(unit octs)]
  ^-  (list card)
  =/  pax=path  /http-response/[eyre-id]
  :~  :*  %give  %fact  ~[pax]  %http-response-header
          !>(`response-header:http`[status hed])
      ==
      [%give %fact ~[pax] %http-response-data !>(bod)]
      [%give %kick ~[pax] ~]
  ==
::
++  restart-http
  |=  eyre-id=@ta
  ^-  (list card)
  %:  http-give
      eyre-id
      503
      ['content-type' 'text/plain']~
      `(text-octs 'Rover restarted while saving. Please submit again.')
  ==
::
++  shell-page
  ^-  octs
  (as-octs:mimes:html shell-html)
::
++  tile-octs
  ^-  octs
  (as-octs:mimes:html tile-png)
::
++  font-regular-octs
  ^-  octs
  font-regular
::
++  font-bold-octs
  ^-  octs
  font-bold
::
++  text-octs
  |=  text=@t
  ^-  octs
  (as-octs:mimes:html text)
::
++  database-present
  |=  commands=(list cmd-result:ast)
  ^-  ?
  =/  rows  (rows-at:view commands 0)
  ?=(^ (row-by-text:view %database 'rover' rows))
::
++  obelisk-script-cards
  |=  [our=@p wir=wire script=tape]
  ^-  (list card)
  =/  jon  !>([%script %rover %vector script])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  row-member
  |=  [needle=vector:ast rows=(list vector:ast)]
  ^-  ?
  ?~  rows
    %.n
  ?:  =(needle i.rows)
    %.y
  $(rows t.rows)
::
::  Compare as sets, not as returned list order. Both projections include the
::  acquisition primary key, so Obelisk's identical-row collapse cannot make
::  this count under-report the table.
++  migration-rows-match
  |=  [source=(list vector:ast) destination=(list vector:ast)]
  ^-  ?
  ?&  =((lent source) (lent destination))
      %+  levy  source
      |=  row=vector:ast
      (row-member row destination)
  ==
::
++  energy-odometer-values
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  acquisition  (cell-atom:view %acquisition-id i.rows)
  =/  odometer  (cell-atom:view %odometer-id i.rows)
  ;:  weld
    "("
    (scow %ux acquisition)
    ", "
    (scow %ux odometer)
    ")"
    ?~(t.rows ";" (weld " " (energy-odometer-values t.rows)))
  ==
::
++  energy-odometer-copy-script
  |=  rows=(list vector:ast)
  ^-  tape
  ?>  ?=(^ rows)
  ;:  weld
    "INSERT INTO energy-acquisition-odometers VALUES "
    (energy-odometer-values rows)
  ==
::
++  starter-seed-script
  |=  [commands=(list cmd-result:ast) base=@ux now=@da]
  ^-  tape
  =/  definitions  (rows-at:view commands 0)
  =/  consumables  (rows-at:view commands 1)
  =/  additives  (rows-at:view commands 2)
  =/  driving-modes  (rows-at:view commands 3)
  =/  service-subtypes  (rows-at:view commands 4)
  =/  disposal-kinds  (rows-at:view commands 5)
  %:  seed-missing-starters:act
      base
      now
      ?=(~ definitions)
      ?=(~ consumables)
      ?=(~ additives)
      ?=(~ driving-modes)
      ?=(~ service-subtypes)
      ?=(~ disposal-kinds)
  ==
::
++  entry-refusal
  |=  verdict=entry-verdict:rover
  ^-  @t
  (cat 3 '%' (cat 3 (scot %tas class.verdict) (cat 3 ': ' field.verdict)))
::
++  import-lookup-cards
  |=  [our=@p run=import-run:rover]
  ^-  (list card)
  ?~  remaining.run
    ~
  =/  wir=wire  /rover-import-lookup/(scot %ud serial.run)
  =/  jon  !>([%script %rover %vector (work-lookup:imp i.remaining.run)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-write-cards
  |=  [our=@p serial=@ud script=tape]
  ^-  (list card)
  =/  wir=wire  /rover-import-write/script/(scot %ud serial)
  =/  jon  !>([%script %rover %vector script])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-parse-cards
  |=  [our=@p serial=@ud script=tape]
  ^-  (list card)
  =/  wir=wire  /rover-import-write/parse/(scot %ud serial)
  =/  jon  !>([%parse %rover script])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-command-write-cards
  |=  [our=@p serial=@ud commands=(list command:ast)]
  ^-  (list card)
  =/  wir=wire  /rover-import-write/cmd-list/(scot %ud serial)
  =/  jon  !>([%cmd-list %vector commands])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-support-cards
  |=  [our=@p serial=@ud fill=import-fill:rover]
  ^-  (list card)
  =/  wir=wire  /rover-import-support/(scot %ud serial)
  =/  jon  !>([%script %rover %vector (fill-support-lookup:imp fill)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-comparison-cards
  |=  [our=@p serial=@ud acquisition-id=@ux]
  ^-  (list card)
  =/  wir=wire  /rover-import-comparison/(scot %ud serial)
  =/  jon  !>([%script %rover %vector (fill-comparison-lookup:imp acquisition-id)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-comparison-tail-cards
  |=  [our=@p serial=@ud acquisition-id=@ux]
  ^-  (list card)
  =/  wir=wire  /rover-import-comparison-tail/(scot %ud serial)
  =/  jon  !>([%script %rover %vector (fill-comparison-tail-lookup:imp acquisition-id)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  continue-import
  |=  [sat=state-19 our=@p run=import-run:rover]
  ^-  [(list card) state-19]
  ?~  remaining.run
    :_  sat(import-run ~)
    %:  http-give
        eyre-id.run
        200
        ['content-type' 'text/plain']~
        `(text-octs (report-text:imp report.run))
    ==
  [(import-lookup-cards our run) sat(import-run `run)]
::
++  import-detail
  |=  [prefix=@t work=import-work:rover detail=@t]
  ^-  @t
  %-  crip
  ;:  weld
    (trip prefix)
    ": "
    (trip (work-name:imp work))
    ?:  =(0 detail)
      ""
    ;:  weld
      " - "
      (trip detail)
    ==
  ==
::
++  handle-http
  |=  [sat=state-19 =bowl:gall eyre-id=@ta req=inbound-request:eyre]
  ^-  [(list card) state-19]
  ?.  authenticated.req
    =/  loc  (cat 3 '/~/login?redirect=' url.request.req)
    [(http-give eyre-id 303 ['location' loc]~ ~) sat]
  ?>  =(our.bowl src.bowl)
  ?:  =(%'POST' method.request.req)
    ?:  =('/apps/rover/view' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: page')) sat]
      =/  request-text=@t  `@t`q.u.body.request.req
      =/  request-object  (json-object:entry request-text)
      =/  page-value=(unit @t)
        ?~  request-object
          `request-text
        (json-string:entry 'page' u.request-object)
      ?~  page-value
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: page')) sat]
      =/  page-text=@t  u.page-value
      =/  parsed  (slaw %ud page-text)
      ?:  ?|  ?=(~ parsed)
              (gth u.parsed 1.000.000)
          ==
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: page')) sat]
      =/  wir=wire
        ?:  bootstrap-ready.sat
          /rover-http/recover/(scot %da now.bowl)/[eyre-id]
        /rover-bootstrap-probe/(scot %da now.bowl)/[eyre-id]
      =/  jon
        ?:  bootstrap-ready.sat
          !>([%script %rover %vector ui-view:act])
        !>([%script %sys %vector database-list:act])
      =/  new-sat
        sat(pending (~(put by pending.sat) wir request-text), http-pending (~(put by http-pending.sat) wir eyre-id))
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/import' url.request.req)
      ?^  import-run.sat
        [(http-give eyre-id 409 ['content-type' 'text/plain']~ `(text-octs 'An import is already running')) sat]
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: import')) sat]
      =/  decoded  (decode-import:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  run=import-run:rover
        :*  eyre-id
            %.n
            1
            (import-works:imp p.decoded)
            (initial-report:imp p.decoded)
            ~
        ==
      (continue-import sat our.bowl run)
    ::
    ?:  =('/apps/rover/add-consumable' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: consumable')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-consumable:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-consumable-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (consumable-lookup:act vehicle-label.p.decoded consumable-label.p.decoded)])
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          fill-body-pending  (~(put by fill-body-pending.sat) wir body-text)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M7 T1. One endpoint for all three event kinds. The kind selects which
    ::  typed child the write creates; every association attaches to the parent,
    ::  so the three kinds share one lookup and one insert.
    ::
    ::  M7 T4 adds two more routes to the SAME handler. Buying and selling the
    ::  vehicle are events like any other, so they extend this match rather
    ::  than opening a second decoder that could drift from this one.
    ?:  ?|  =('/apps/rover/add-service-event' url.request.req)
            =('/apps/rover/add-expense-event' url.request.req)
            =('/apps/rover/add-note-event' url.request.req)
            =('/apps/rover/add-acquisition-event' url.request.req)
            =('/apps/rover/add-disposal-event' url.request.req)
        ==
      ::  One handler, five routes. The route selects the kind, so a client
      ::  cannot send a kind that disagrees with the typed child it gets.
      =/  kind=event-kind:rover
        ?:  =('/apps/rover/add-service-event' url.request.req)  %service
        ?:  =('/apps/rover/add-expense-event' url.request.req)  %expense
        ?:  =('/apps/rover/add-acquisition-event' url.request.req)  %acquisition
        ?:  =('/apps/rover/add-disposal-event' url.request.req)  %disposal
        %note
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: event')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-event:entry kind body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      ::  The kind rides the wire, so the response handler recovers it without
      ::  re-reading the body. The body never carried it.
      =/  wir=wire  /rover-event-lookup/[kind]/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (event-lookup:act vehicle-label.p.decoded)])
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          fill-body-pending  (~(put by fill-body-pending.sat) wir body-text)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M7 T6. One reminder. The write is two phases like an event write: the
    ::  vehicle and the service subtype are resolved by label first, and an
    ::  unknown one is refused rather than invented.
    ?:  =('/apps/rover/add-reminder' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: reminder')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-reminder:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-reminder-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (reminder-lookup:act vehicle-label.p.decoded)])
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          fill-body-pending  (~(put by fill-body-pending.sat) wir body-text)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-custom-field' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-custom-definition:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  wir=wire  /rover-custom-create/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (insert-custom-definition:act (fixture-id:act base 501) p.decoded now.bowl)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  ?|  =('/apps/rover/add-energy-source-type' url.request.req)
            =('/apps/rover/add-driving-mode-type' url.request.req)
        ==
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  object  (json-object:entry body-text)
      ?~  object
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type')) sat]
      =/  label  (json-string:entry 'label' u.object)
      ?:  ?|  ?=(~ label)
              !(nonempty:entry u.label)
          ==
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type.label')) sat]
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  type=@tas
        ?:  =('/apps/rover/add-energy-source-type' url.request.req)
          %energy
        %mode
      =/  script=tape
        ?:  =(%mode type)
          (insert-driving-mode-type:act (fixture-id:act base 602) u.label now.bowl)
        =/  kind-text  (json-string:entry 'physicalKind' u.object)
        =/  unit-text  (json-string:entry 'quantityUnit' u.object)
        ?:  ?|  ?=(~ kind-text)
                ?=(~ unit-text)
            ==
          ~
        =/  kind  (slaw %tas u.kind-text)
        =/  unit  (slaw %tas u.unit-text)
        ?:  ?|  ?=(~ kind)
                ?=(~ unit)
                !?=(?(%reservoir %electricity) u.kind)
                !?=(?(%gal %litre %kg %kwh) u.unit)
            ==
          ~
        (insert-energy-source-type:act (fixture-id:act base 601) u.label u.kind u.unit now.bowl)
      ?~  script
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type')) sat]
      =/  wir=wire  /rover-type-create/[type]/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector script])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  ?|  =('/apps/rover/archive-custom-field' url.request.req)
            =('/apps/rover/change-custom-field-type' url.request.req)
        ==
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  label=@t
        ?:  =('/apps/rover/archive-custom-field' url.request.req)
          =/  decoded  (decode-custom-field-label:entry body-text)
          ?:  ?=(%| -.decoded)
            ''
          label.p.decoded
        =/  decoded  (decode-custom-field-change:entry body-text)
        ?:  ?=(%| -.decoded)
          ''
        label.p.decoded
      ?.  (nonempty:entry label)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field')) sat]
      =/  operation=@tas
        ?:  =('/apps/rover/archive-custom-field' url.request.req)
          %archive
        %change
      =/  wir=wire  /rover-custom-lookup/[operation]/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (custom-field-lookup:act label)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M7 T8. The definition lifecycle. One handler, three routes, nine
    ::  families. The route selects the operation and the body names the
    ::  family, the same split the five event routes use: a client cannot ask
    ::  for an operation the endpoint it called does not perform.
    ::
    ::  The write is two phases, like every other label-addressed write here.
    ::  The first phase finds the definition and, for a rename, whatever else
    ::  already carries the new label. The second phase writes.
    ?:  ?|  =('/apps/rover/rename-definition' url.request.req)
            =('/apps/rover/archive-definition' url.request.req)
            =('/apps/rover/restore-definition' url.request.req)
        ==
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: definition')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  operation=@tas
        ?:  =('/apps/rover/rename-definition' url.request.req)  %rename
        ?:  =('/apps/rover/archive-definition' url.request.req)  %archive
        %restore
      =/  decoded  (decode-definition-lifecycle:entry body-text =(%rename operation))
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  fam  (definition-family-of:act family.p.decoded)
      ?~  fam
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%unknown-family: definition.family')) sat]
      ::  The second lookup probes the new label on a rename and the current
      ::  label otherwise, so the script keeps one shape for all three routes.
      =/  probe=@t
        ?:(=(%rename operation) new-label.p.decoded label.p.decoded)
      =/  wir=wire
        /rover-definition-lookup/[operation]/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (definition-lookup:act u.fam label.p.decoded probe)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/edit-fill' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-fill:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  object  (json-object:entry body-text)
      =/  original-text
        ?~  object
          ~
        (json-string:entry 'originalObserved' u.object)
      =/  original-observed
        ?~  original-text
          `observed-start.p.decoded
        (local-da:entry u.original-text)
      ?~  original-observed
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill.original-date')) sat]
      =/  wir=wire  /rover-edit-fill-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (edit-fill-lookup:act vehicle-label.p.decoded (need original-observed) definition-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/edit-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-vehicle-edit:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-edit-vehicle-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (vehicle-edit-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/set-default-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  decoded  (decode-vehicle-label:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-default-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (app-default-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir 'set-default')
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/remove-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  decoded  (decode-vehicle-label:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-remove-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (archive-vehicle-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir 'remove-vehicle')
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  decoded  (decode-new-vehicle:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-add-vehicle-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector new-vehicle-lookup:act])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir `@t`q.u.body.request.req)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/set-preference' url.request.req)
      ?~  body.request.req
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs '%bad-shape: preference')
        ==
      =/  decoded  (decode-preference:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs (entry-refusal p.decoded))
        ==
      =/  wir=wire  /rover-preference-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (preference-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          preference-pending  (~(put by preference-pending.sat) wir p.decoded)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-charge' url.request.req)
      ?~  body.request.req
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs '%bad-shape: charge')
        ==
      =/  decoded  (decode-charge:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs (entry-refusal p.decoded))
        ==
      =/  wir=wire  /rover-charge-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (fill-lookup:act vehicle-label.p.decoded definition-label.p.decoded)])
      =/  new-sat
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          charge-pending  (~(put by charge-pending.sat) wir p.decoded)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-odometer' url.request.req)
      ?~  body.request.req
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs '%bad-shape: odometer')
        ==
      =/  decoded  (decode-odometer:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs (entry-refusal p.decoded))
        ==
      =/  wir=wire  /rover-odometer-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (vehicle-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          odometer-pending  (~(put by odometer-pending.sat) wir p.decoded)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?.  =('/apps/rover/add-fill' url.request.req)
      [(http-give eyre-id 405 ~ ~) sat]
    ?~  body.request.req
      :_  sat
      %:  http-give
          eyre-id
          400
          ['content-type' 'text/plain']~
          `(text-octs '%bad-shape: fill')
      ==
    =/  fill-body=@t  `@t`q.u.body.request.req
    =/  decoded  (decode-fill:entry fill-body)
    ?:  ?=(%| -.decoded)
      :_  sat
      %:  http-give
          eyre-id
          400
          ['content-type' 'text/plain']~
          `(text-octs (entry-refusal p.decoded))
      ==
    =/  wir=wire  /rover-fill-lookup/(scot %da now.bowl)/[eyre-id]
    =/  jon
      !>([%script %rover %vector (fill-lookup:act vehicle-label.p.decoded definition-label.p.decoded)])
    =/  new-sat
      %_  sat
        http-pending  (~(put by http-pending.sat) wir eyre-id)
        fill-pending  (~(put by fill-pending.sat) wir p.decoded)
        fill-body-pending  (~(put by fill-body-pending.sat) wir fill-body)
      ==
    :_  new-sat
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ?.  =(%'GET' method.request.req)
    [(http-give eyre-id 405 ~ ~) sat]
  ?:  =('/apps/rover/assets/tile.png' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'image/png']~ `tile-octs) sat]
  ?:  =('/apps/rover/assets/fonts/JetBrainsMono-Regular.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-regular-octs) sat]
  ?:  =('/apps/rover/assets/fonts/JetBrainsMono-Bold.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-bold-octs) sat]
  ::  M7 T10. The whole history as one file. It is a GET because a download
  ::  control is a link, and it is read-only: nothing about an export mutates.
  ::  The owner's Eyre session is already required above, so the file the
  ::  browser receives is the owner's own and reaches nobody else.
  ?:  =('/apps/rover/export' url.request.req)
    =/  wir=wire  /rover-export/(scot %da now.bowl)/[eyre-id]
    =/  jon  !>([%script %rover %vector export-view:exp])
    :_  sat(http-pending (~(put by http-pending.sat) wir eyre-id))
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ?:  =('/apps/rover/view' url.request.req)
    =/  wir=wire
      ?:  bootstrap-ready.sat
        /rover-http/recover/(scot %da now.bowl)/[eyre-id]
      /rover-bootstrap-probe/(scot %da now.bowl)/[eyre-id]
    =/  jon
      ?:  bootstrap-ready.sat
        !>([%script %rover %vector ui-view:act])
      !>([%script %sys %vector database-list:act])
    =/  new-sat
      sat(pending (~(put by pending.sat) wir '0'), http-pending (~(put by http-pending.sat) wir eyre-id))
    :_  new-sat
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  [(http-give eyre-id 200 ['content-type' 'text/html']~ `shell-page) sat]
--
=|  state-19
=*  state  -
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  =/  wir=wire  /rover-install-probe/(scot %da now.bowl)
  =/  jon  !>([%script %sys %vector database-list:act])
  :_  this(bootstrap-ready %.n)
  :~  bind-eyre
      [%pass wir %agent [our.bowl %obelisk] %watch /server]
      [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
  ==
::
++  on-save  !>([%19 state])
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  s  !<(versioned-state old)
  =/  loaded=_this
    ?-  -.s
      %0  this(state [pending.+.s last.+.s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %.n])
      %1  this(state [pending.+.s last.+.s preview.+.s total.+.s ~ ~ ~ ~ ~ ~ ~ ~ ~ %.n])
      %2  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s ~ ~ ~ ~ ~ ~ ~ ~ %.n])
      %3  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s ~ ~ ~ ~ ~ ~ ~ %.n])
      %4  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ ~ ~ ~ ~ %.n])
      %5  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ ~ ~ ~ ~ %.n])
      %6  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s ~ ~ ~ %.n])
      %7  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s ~ ~ ~ %.n])
      %8  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s ~ ~ %.n])
      %9  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s ~ ~ %.n])
      %10  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n])
      %11  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n])
      %12  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n])
      %13  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n])
      %14  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n])
      %15  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n])
      %16  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n])
      %17  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ bootstrap-ready.+.s])
      %18  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ bootstrap-ready.+.s])
      %19  this(state +.s)
    ==
  [[bind-eyre]~ loaded]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    =^  cards  state  (handle-http state bowl eyre-id req)
    [cards this]
  ::
      %rover-action
    ?>  =(our.bowl src.bowl)
    =/  a  !<(action:rover vase)
    ?-  -.a
      %init-db
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector schema-m0:act])
        :_  this(pending (~(put by pending) wir 'init-db'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %ensure-ui-schema
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector display-preference-schema:act])
        :_  this(pending (~(put by pending) wir 'ensure-ui-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      ::  Read the relation list first, then pour only what is absent. Obelisk
      ::  has no CREATE TABLE IF NOT EXISTS and a script is atomic, so a single
      ::  already-poured relation would abort the whole catch-up.
      %ensure-def-schema
        =/  wir=path  /rover-def-check/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector def-schema-check:act])
        :_  this(pending (~(put by pending) wir 'ensure-def-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-starters
        =/  wir=path  /rover-starter-check/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector starter-check:act])
        :_  this(pending (~(put by pending) wir 'seed-starters-check'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %verify-schema
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector verify-schema:act])
        :_  this(pending (~(put by pending) wir 'verify-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
    ==
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:def wire sign)
      [%rover-def-check *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this(pending (~(del by pending) wire), last `res)
      =/  present=(list @tas)
        %+  turn  (rows-at:view p.res 0)
        |=  row=vector:ast
        ^-  @tas
        (cell-term:view %name row)
      =/  old-present
        (lien present |=(had=@tas =(had %fuel-fill-odometers)))
      =/  new-present
        (lien present |=(had=@tas =(had %energy-acquisition-odometers)))
      ?:  old-present
        =/  next-wire=path
          ?:  new-present
            /rover-energy-odometer-precheck/(scot %da now.bowl)
          /rover-energy-odometer-create/(scot %da now.bowl)
        =/  script=tape
          ?:  new-present
            energy-odometer-migration-check:act
          energy-odometer-create:act
        :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
        (obelisk-script-cards our.bowl next-wire script)
      =/  script  (missing-def-schema:act present)
      ?~  script
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path  /rover/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector script])
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-create *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-create-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path
        /rover-energy-odometer-precheck-delay/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-precheck *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-precheck-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  source  (rows-at:view p.res 0)
      =/  destination  (rows-at:view p.res 1)
      ~&  [%rover-energy-odometer-source-count (lent source)]
      ?:  (migration-rows-match source destination)
        ~&  [%rover-energy-odometer-preverified (lent source)]
        =/  next-wire=path
          /rover-energy-odometer-drop-delay/(scot %da now.bowl)
        :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
        ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
      ?^  destination
        ~&  [%rover-energy-odometer-migration-refused %destination-not-empty (lent source) (lent destination)]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path
        /rover-energy-odometer-copy/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      (obelisk-script-cards our.bowl next-wire (energy-odometer-copy-script source))
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-copy *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-copy-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path
        /rover-energy-odometer-verify/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      (obelisk-script-cards our.bowl next-wire energy-odometer-migration-check:act)
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-verify *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-verify-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  source  (rows-at:view p.res 0)
      =/  destination  (rows-at:view p.res 1)
      ?.  (migration-rows-match source destination)
        ~&  [%rover-energy-odometer-migration-refused %content-mismatch (lent source) (lent destination)]
        `this(pending (~(del by pending) wire), last `res)
      ~&  [%rover-energy-odometer-verified (lent source)]
      =/  next-wire=path
        /rover-energy-odometer-drop-delay/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-drop *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-drop-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path  /rover-def-check/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      (obelisk-script-cards our.bowl next-wire def-schema-check:act)
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-probe *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      ?:  (database-present p.res)
        `this(bootstrap-ready %.y)
      =/  next-wire=path  /rover-install-pour/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector schema-m0:act])
      :_  this
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-pour *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      =/  next-wire=path  /rover-install-delay/(scot %da now.bowl)
      :_  this
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-starter-check *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  script  (starter-seed-script p.res base now.bowl)
      ?~  script
        `this(bootstrap-ready %.y)
      =/  next-wire=path  /rover-install-starter-write/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector script])
      :_  this
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-starter-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      `this(bootstrap-ready %.y)
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-export *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  cleared  this(http-pending (~(del by http-pending) wire))
      ?~  eyre-id
        `cleared
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: export'))
      =/  payload  (export-json:exp p.res our.bowl now.bowl)
      =/  filename
        %-  crip
        ;:  weld
          "attachment; filename=\"rover-export-"
          (trip (export-day:exp now.bowl))
          ".json\""
        ==
      :_  cleared
      %:  http-give
          u.eyre-id
          200
          :~  ['content-type' 'application/json']
              ['content-disposition' filename]
          ==
          `(as-octs:mimes:html payload)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-consumable-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?~  eyre-id
        `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: consumable'))
      =/  decoded  (decode-consumable:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: consumable'))
      =/  vehicles  (rows-at:view p.res 0)
      =/  definitions  (rows-at:view p.res 1)
      ?.  ?&  =(1 (lent vehicles))
              =(1 (lent definitions))
          ==
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: consumable'))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-consumable-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        %:  insert-consumable:act
            (fixture-id:act base 9.101)
            (fixture-id:act base 9.102)
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            `@ux`(cell-atom:view %consumable-id (snag 0 definitions))
            (cell-term:view %quantity-unit (snag 0 definitions))
            p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) write-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-event-lookup ?(%service %expense %note %acquisition %disposal) *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: event'))
      =/  decoded  (decode-event:entry i.t.wire u.body)
      ?:  ?=(%| -.decoded)
        :_  cleared
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: event'))
      ?.  (gte (lent p.res) 6)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: event'))
      =/  vehicles  (rows-at:view p.res 0)
      =/  station-rows  (rows-at:view p.res 1)
      =/  tag-rows  (rows-at:view p.res 2)
      =/  payment-rows  (rows-at:view p.res 3)
      =/  subtype-rows  (rows-at:view p.res 4)
      =/  disposal-kind-rows  (rows-at:view p.res 5)
      ?.  =(1 (lent vehicles))
        :_  cleared
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.vehicle'))
      =/  station-id=(unit @ux)
        ?~  station-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.station-label.p.decoded station-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.p.decoded)
              ?=(~ station-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.station'))
      =/  tag-proof
        (ids-for-labels:view tag-labels.p.decoded tag-rows %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.tags'))
      ::  A subtype the catalog does not hold is a refusal, never a silent
      ::  create. Only the starter pack and a later T8 endpoint make
      ::  definitions; an event never invents one.
      =/  subtype-proof
        (ids-for-labels:view subtype-labels.p.decoded subtype-rows %label %service-subtype-id)
      ?:  ?=(%| -.subtype-proof)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.subtypes'))
      ::  M7 T4. A disposal names one catalog row. An unknown label is a
      ::  refusal, never a silent create: only the starter pack and a later T8
      ::  endpoint make definitions, and a sale never invents one.
      =/  disposal-kind-id=(unit @ux)
        ?~  disposal-kind-label.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.disposal-kind-label.p.decoded disposal-kind-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %disposal-kind-id u.found)
      ?:  ?&  ?=(^ disposal-kind-label.p.decoded)
              ?=(~ disposal-kind-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.disposal-kind'))
      =/  payment-method-id=(unit @ux)
        ?~  payment-method-label.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.payment-method-label.p.decoded payment-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.p.decoded)
              ?=(~ payment-method-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.payment-method'))
      ?:  ?&  ?=(^ new-tag-label.p.decoded)
              ?=(^ (row-by-text:view %label u.new-tag-label.p.decoded tag-rows))
          ==
        :_  cleared
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%already-exists: event.new-tag'))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=event-ids:act
        :*  (fixture-id:act base 9.301)
            (fixture-id:act base 9.302)
            (fixture-id:act base 9.303)
            (fixture-id:act base 9.304)
            (fixture-id:act base 9.305)
        ==
      =/  write-wire=path  /rover-event-write/[i.t.wire]/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        %:  insert-event:act
            ids
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            station-id
            p.tag-proof
            p.subtype-proof
            disposal-kind-id
            payment-method-id
            p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) write-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-event-write ?(%service %expense %note %acquisition %disposal) *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      =/  decoded  (decode-event:entry i.t.wire u.body)
      ?:  ?|  ?=(%.n -.res)
              ?=(%| -.decoded)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: event'))
      =/  saved=@t
        =/  head  (cat 3 'Saved ' (cat 3 (scot %tas kind.p.decoded) ' event'))
        ?~  total-mills.p.decoded
          head
        (cat 3 head (cat 3 ' - ' total-display.p.decoded))
      :_  cleared
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs saved))
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-reminder-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: reminder'))
      =/  decoded  (decode-reminder:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  cleared
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: reminder'))
      ?.  (gte (lent p.res) 2)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: reminder'))
      =/  vehicles  (rows-at:view p.res 0)
      =/  subtype-rows  (rows-at:view p.res 1)
      ?.  =(1 (lent vehicles))
        :_  cleared
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: reminder.vehicle'))
      =/  found  (row-by-text:view %label subtype-label.p.decoded subtype-rows)
      ?~  found
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: reminder.subtype'))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-reminder-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        %:  insert-reminder:act
            (fixture-id:act base 9.601)
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            `@ux`(cell-atom:view %service-subtype-id u.found)
            p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) write-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-reminder-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      =/  decoded  (decode-reminder:entry u.body)
      ?:  ?|  ?=(%.n -.res)
              ?=(%| -.decoded)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: reminder'))
      :_  cleared
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs (cat 3 'Saved reminder - ' subtype-label.p.decoded))
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-consumable-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-consumable:entry u.body)
      =/  next
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?:  ?|  ?=(%.n -.res)
              ?=(%| -.decoded)
          ==
        :_  next
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: consumable'))
      =/  proof
        %:  derive-fill-total:act
            quantity-milli.p.decoded
            unit-price-mills.p.decoded
            minor-unit-decimals.p.decoded
            cash-increment-mills.p.decoded
            settlement-mode.p.decoded
        ==
      =/  total
        (format-total:render total-mills.proof currency.p.decoded minor-unit-decimals.p.decoded)
      :_  next
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs (cat 3 'Saved consumable purchase - ' total))
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-bootstrap-probe *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while checking for the Rover database. Obelisk refused the database list query.')
        ==
      =/  exists  (database-present p.res)
      =/  next-wire=path
        ?:  exists
          /rover-bootstrap-starter-check/existing/(scot %da now.bowl)/[u.eyre-id]
        /rover-bootstrap-pour/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        ?:  exists
          !>([%script %rover %vector starter-check:act])
        !>([%script %rover %vector schema-m0:act])
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http, bootstrap-ready %.n)
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while checking for the Rover database. Obelisk did not accept the database list request.')
      ==
    ==
  ::
      [%rover-bootstrap-pour *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while creating the Rover database. Obelisk refused the schema pour.')
        ==
      =/  next-wire=path
        /rover-bootstrap-delay/(scot %da now.bowl)/[u.eyre-id]
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http)
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while creating the Rover database. Obelisk did not accept the schema pour.')
      ==
    ==
  ::
      [%rover-bootstrap-starter-check @tas *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  source=@tas  i.t.wire
      ?:  ?=(%.n -.res)
        ?:  =(source %existing)
          =/  next-wire=path
            /rover-http/final/(scot %da now.bowl)/[u.eyre-id]
          =/  jon  !>([%script %rover %vector ui-view:act])
          =/  next-pending
            (~(put by (~(del by pending) wire)) next-wire u.request-text)
          =/  next-http
            (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
          :_  this(pending next-pending, http-pending next-http)
          :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
              [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
          ==
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while checking starter definitions. Obelisk refused the starter query.')
      ==
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  script  (starter-seed-script p.res base now.bowl)
      ?:  ?&  =(source %existing)
              ?=(^ script)
          ==
        =/  next-wire=path
          /rover-bootstrap-delay/(scot %da now.bowl)/[u.eyre-id]
        =/  next-pending
          (~(put by (~(del by pending) wire)) next-wire u.request-text)
        =/  next-http
          (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
        :_  this(pending next-pending, http-pending next-http)
        ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
      =/  next-wire=path
        ?:  ?=(~ script)
          ?:  =(source %existing)
            /rover-http/final/(scot %da now.bowl)/[u.eyre-id]
          /rover-http/bootstrapped/(scot %da now.bowl)/[u.eyre-id]
        /rover-bootstrap-starter-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        ?:  ?=(~ script)
          !>([%script %rover %vector ui-view:act])
        !>([%script %rover %vector script])
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http, bootstrap-ready ?=(~ script))
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while checking starter definitions. Obelisk did not accept the starter query.')
      ==
    ==
  ::
      [%rover-bootstrap-starter-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while adding starter definitions. Obelisk refused the starter seed.')
        ==
      =/  next-wire=path  /rover-http/bootstrapped/(scot %da now.bowl)/[u.eyre-id]
      =/  jon  !>([%script %rover %vector ui-view:act])
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http, bootstrap-ready %.y)
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while adding starter definitions. Obelisk did not accept the starter seed.')
      ==
    ==
  ::
      [%rover-starter-check *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this(last `res)
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  script  (starter-seed-script p.res base now.bowl)
      ?:  ?=(~ script)
        `this(last `res, pending (~(del by pending) wire))
      =/  write-wire=path  /rover/starter-write/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector script])
      =/  next-pending
        (~(put by (~(del by pending) wire)) write-wire 'seed-starters-write')
      :_  this(pending next-pending)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-vehicle-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-vehicle-edit:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: vehicle'))
      =/  vehicles  (rows-at:view p.res 0)
      ?.  =(1 (lent vehicles))
        :_  this
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle'))
      =/  subtype-id=(unit @ux)
        ?~  default-subtype.p.decoded
          ~
        =/  found  (row-by-text:view %label u.default-subtype.p.decoded (rows-at:view p.res 1))
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ default-subtype.p.decoded)
              ?=(~ subtype-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.default-subtype'))
      =/  current-energy-ids=(list @ux)
        %+  turn  (rows-at:view p.res 2)
        |=  row=vector:ast
        `@ux`(cell-atom:view %energy-definition-id row)
      =/  energy-result=(each (list @ux) @t)
        ?~  energy-labels.p.decoded
          [%& current-energy-ids]
        (ids-for-labels:view u.energy-labels.p.decoded (rows-at:view p.res 3) %label %energy-definition-id)
      ?:  ?=(%| -.energy-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.energy-source'))
      =/  resolved-energy-ids=(unit (list @ux))
        ?~  energy-labels.p.decoded
          ~
        `(unique-ids:act p.energy-result)
      =/  default-energy-id=(unit @ux)
        ?~  default-energy.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.default-energy.p.decoded (rows-at:view p.res 3))
        ?~  found
          ~
        ``@ux`(cell-atom:view %energy-definition-id u.found)
      ?:  ?&  ?=(^ default-energy.p.decoded)
              ?|  ?=(~ default-energy-id)
                  ?&  ?=(^ resolved-energy-ids)
                      !(has-id:act u.default-energy-id u.resolved-energy-ids)
                  ==
              ==
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.default-energy-source'))
      =/  current-mode-ids=(list @ux)
        %+  turn  (rows-at:view p.res 4)
        |=  row=vector:ast
        `@ux`(cell-atom:view %mode-id row)
      =/  mode-result=(each (list @ux) @t)
        ?~  driving-mode-labels.p.decoded
          [%& current-mode-ids]
        (ids-for-labels:view u.driving-mode-labels.p.decoded (rows-at:view p.res 5) %label %mode-id)
      ?:  ?=(%| -.mode-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.driving-mode'))
      =/  resolved-mode-ids=(unit (list @ux))
        ?~  driving-mode-labels.p.decoded
          ~
        `(unique-ids:act p.mode-result)
      =/  current-def-rows  (rows-at:view p.res 7)
      =/  current-def  ?=(^ current-def-rows)
      =/  def-consumable-id=(unit @ux)
        ?^  current-def-rows
          ``@ux`(cell-atom:view %consumable-id i.current-def-rows)
        =/  definitions  (rows-at:view p.res 6)
        ?~  definitions
          ~
        ``@ux`(cell-atom:view %consumable-id i.definitions)
      ?:  ?&  ?=(^ def-enabled.p.decoded)
              u.def-enabled.p.decoded
              ?=(~ def-consumable-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.consumable.DEF'))
      =/  write-wire=path  /rover-edit-vehicle-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        !>([%script %rover %vector (update-vehicle-settings:act `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles)) p.decoded subtype-id current-energy-ids resolved-energy-ids default-energy-id current-mode-ids resolved-mode-ids current-def def-consumable-id now.bowl)])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-vehicle-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Saved vehicle settings'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-custom-create *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: custom-field'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Created custom field'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-type-create *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: configuration-type'))
      =/  type=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  message
        ?:(=(%energy type) 'Created energy source type' 'Created driving mode type')
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs message))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-custom-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: custom-field'))
      =/  definitions  (rows-at:view p.res 0)
      ?.  =(1 (lent definitions))
        :_  this
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: custom-field'))
      ?:  ?&  =(%change operation-term)
              ?|  ?=(^ (rows-at:view p.res 1))
                  ?=(^ (rows-at:view p.res 2))
                  ?=(^ (rows-at:view p.res 3))
              ==
          ==
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%immutable: custom-field.content-type - archive and recreate'))
      =/  field-id=@ux
        `@ux`(cell-atom:view %field-id (snag 0 definitions))
      =/  script=tape
        ?:  =(%archive operation-term)
          (archive-custom-field:act field-id)
        =/  decoded  (decode-custom-field-change:entry u.body)
        ?:  ?=(%| -.decoded)
          ~
        (change-custom-field-type:act field-id content-type.p.decoded)
      ?~  script
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field'))
      =/  write-wire=path
        /rover-custom-write/[operation-term]/(scot %da now.bowl)/[u.eyre-id]
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-custom-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: custom-field'))
      =/  message  ?:(=(%archive operation-term) 'Archived custom field' 'Changed custom field type')
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs message))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
  ::  M7 T8. Phase one of the definition lifecycle. The lookup answered; decide
  ::  whether the write may happen, and build it.
      [%rover-definition-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: definition'))
      =/  decoded
        (decode-definition-lifecycle:entry u.body =(%rename operation-term))
      ?:  ?=(%| -.decoded)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded)))
      =/  fam  (definition-family-of:act family.p.decoded)
      ?~  fam
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%unknown-family: definition.family'))
      =/  definitions  (rows-at:view p.res 0)
      ?.  =(1 (lent definitions))
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: definition'))
      ::  A rename may not put two rows of one family under one label. The
      ::  label is how every Rover surface names a definition, so a collision
      ::  would leave both rows unaddressable — including the one just renamed.
      ::  Nothing here compares the meaning of the two labels: the app does not
      ::  police whether a rename is a correction or a repurpose.
      ?:  ?&  =(%rename operation-term)
              ?=(^ (rows-at:view p.res 1))
          ==
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%duplicate-label: definition'))
      =/  definition-id=@ux
        `@ux`(cell-atom:view `@tas`id-column.u.fam (snag 0 definitions))
      =/  script=tape
        ?:  =(%rename operation-term)
          (rename-definition:act u.fam definition-id new-label.p.decoded)
        (set-definition-archived:act u.fam definition-id =(%archive operation-term))
      =/  write-wire=path
        /rover-definition-write/[operation-term]/(scot %da now.bowl)/[u.eyre-id]
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-definition-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: definition'))
      =/  message=@t
        ?:  =(%rename operation-term)   'Renamed definition'
        ?:  =(%archive operation-term)  'Archived definition'
        'Restored definition'
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs message))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-fill-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-fill:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-fill'))
      ?~  p.res
        :_  this
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill'))
      ?.  (gte (lent p.res) 9)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-fill.evidence'))
      =/  rows  (rows-at:view p.res 0)
      ?.  =(1 (lent rows))
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%ambiguous: edit-fill'))
      =/  definition-rows  (rows-at:view p.res 1)
      ?.  =(1 (lent definition-rows))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.definition'))
      =/  definition-row  (snag 0 definition-rows)
      ?.  =(%reservoir (cell-term:view %physical-kind definition-row))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%wrong-kind: edit-fill.definition'))
      =/  station-id=(unit @ux)
        ?~  station-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.station-label.p.decoded (rows-at:view p.res 2))
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.p.decoded)
              ?=(~ station-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.station'))
      =/  additive-proof
        (ids-for-labels:view additive-labels.p.decoded (rows-at:view p.res 3) %label %additive-id)
      ?:  ?=(%| -.additive-proof)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.additives'))
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.subtype-label.p.decoded (rows-at:view p.res 4))
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ subtype-label.p.decoded)
              ?=(~ subtype-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.subtype'))
      =/  mode-id=(unit @ux)
        ?~  driving-mode-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.driving-mode-label.p.decoded (rows-at:view p.res 5))
        ?~  found
          ~
        ``@ux`(cell-atom:view %mode-id u.found)
      ?:  ?&  ?=(^ driving-mode-label.p.decoded)
              ?=(~ mode-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.driving-mode'))
      =/  tag-proof
        (ids-for-labels:view tag-labels.p.decoded (rows-at:view p.res 6) %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.tags'))
      =/  payment-id=(unit @ux)
        ?~  payment-method-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.payment-method-label.p.decoded (rows-at:view p.res 7))
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.p.decoded)
              ?=(~ payment-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.payment-method'))
      =/  current-odometer-id=(unit @ux)
        ?~  (rows-at:view p.res 8)
          ~
        ``@ux`(cell-atom:view %odometer-id (snag 0 (rows-at:view p.res 8)))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-edit-fill-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        !>([%script %rover %vector (update-fill:act `@ux`(cell-atom:view %acquisition-id (snag 0 rows)) `@ux`(cell-atom:view %vehicle-id (snag 0 rows)) `@ux`(cell-atom:view %energy-definition-id definition-row) (cell-term:view %quantity-unit definition-row) station-id p.additive-proof subtype-id mode-id p.tag-proof payment-id current-odometer-id (fixture-id:act base 901) p.decoded now.bowl)])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-fill-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-fill:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-fill'))
      =/  proof
        %:  derive-fill-total:act
            quantity-milli.p.decoded
            unit-price-mills.p.decoded
            minor-unit-decimals.p.decoded
            cash-increment-mills.p.decoded
            settlement-mode.p.decoded
        ==
      =/  total
        %:  format-total:render
            total-mills.proof
            currency.p.decoded
            minor-unit-decimals.p.decoded
        ==
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs (cat 3 'Saved fill changes - ' total)))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-default-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: default-vehicle'))
      =/  vehicles  (rows-at:view p.res 0)
      ?.  =(1 (lent vehicles))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: default-vehicle'))
      =/  write-wire=path  /rover-default-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  write-app-default:act
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            ?=(^ (rows-at:view p.res 1))
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending
            (~(put by (~(del by pending) wire)) write-wire 'set-default-write')
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-default-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: default-vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Saved default vehicle'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-remove-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: remove-vehicle'))
      ?~  p.res
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: remove-vehicle'))
      =/  vehicles  (result-rows:view i.p.res)
      ?.  =(1 (lent vehicles))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: remove-vehicle'))
      =/  vehicle-id  `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
      =/  defaults  (rows-at:view p.res 1)
      ?:  ?&  ?=(^ defaults)
              =(vehicle-id (cell-atom:view %vehicle-id i.defaults))
          ==
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%default-vehicle: choose a new default before archiving'))
      =/  write-wire=path  /rover-remove-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        !>([%script %rover %vector (archive-vehicle:act vehicle-id)])
      =/  new-state
        %_  state
          pending
            (~(put by (~(del by pending) wire)) write-wire 'remove-vehicle-write')
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-remove-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%database-refused: archive-vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Archived vehicle'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-add-vehicle-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-new-vehicle:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: add-vehicle'))
      =/  definitions  (rows-at:view p.res 0)
      =/  modes  (rows-at:view p.res 1)
      =/  primary  (row-by-text:view %label energy-label.p.decoded definitions)
      ?~  primary
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.energy-source'))
      =/  additional-result
        (ids-for-labels:view additional-energy-labels.p.decoded definitions %label %energy-definition-id)
      ?:  ?=(%| -.additional-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.energy-source'))
      =/  mode-result
        (ids-for-labels:view driving-mode-labels.p.decoded modes %label %mode-id)
      ?:  ?=(%| -.mode-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.driving-mode'))
      =/  primary-id=@ux  `@ux`(cell-atom:view %energy-definition-id u.primary)
      =/  def-consumable-id=(unit @ux)
        ?:  def-enabled.p.decoded
          =/  def-rows  (rows-at:view p.res 2)
          ?~  def-rows
            ~
          ``@ux`(cell-atom:view %consumable-id i.def-rows)
        ~
      ?:  ?&  def-enabled.p.decoded
              ?=(~ def-consumable-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.consumable.DEF'))
      =/  definition-ids
        (unique-ids:act [primary-id p.additional-result])
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-add-vehicle-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  insert-vehicle:act
            (fixture-id:act base 401)
            vehicle-label.p.decoded
            primary-id
            definition-ids
            (unique-ids:act p.mode-result)
            def-consumable-id
            def-tank-size.p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending
            (~(put by (~(del by pending) wire)) write-wire vehicle-label.p.decoded)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-add-vehicle-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  label  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  label
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: add-vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs (cat 3 'Added vehicle - ' u.label)))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-preference-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by preference-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-preference-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: preference.vehicle')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: preference.vehicle')
        ==
      =/  vehicles  (rows-at:view p.res 0)
      ?.  =(1 (lent vehicles))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: preference.vehicle')
        ==
      =/  vehicle-id=@ux  `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
      =/  preferences  (rows-at:view p.res 1)
      =/  existing  (rows-by:view %vehicle-id vehicle-id preferences)
      =/  write-wire=path  /rover-preference-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  write-preference:act
            vehicle-id
            ?=(^ existing)
            u.input
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), preference-pending (~(put by preference-pending) write-wire u.input))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), preference-pending (~(del by preference-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-preference-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by preference-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-preference-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: preference')
        ==
      =/  mode=@t
        ?~  distance-unit.u.input
          'source-native'
        (scot %tas u.distance-unit.u.input)
      =/  message  (cat 3 'Saved display preference - ' mode)
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), preference-pending (~(del by preference-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-odometer-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by odometer-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-odometer-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: odometer.vehicle')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: odometer.vehicle')
        ==
      =/  rows  (result-rows:view i.p.res)
      ?.  =(1 (lent rows))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: odometer.vehicle')
        ==
      =/  row  (snag 0 rows)
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-odometer-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  insert-odometer:act
            (fixture-id:act base 201)
            `@ux`(cell-atom:view %vehicle-id row)
            u.input
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), odometer-pending (~(put by odometer-pending) write-wire u.input))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), odometer-pending (~(del by odometer-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-odometer-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by odometer-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-odometer-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: odometer')
        ==
      =/  reading
        (format-distance:render digits.reading.u.input places.reading.u.input odo-unit.reading.u.input %.n)
      =/  message  (cat 3 'Saved odometer - ' reading)
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), odometer-pending (~(del by odometer-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-charge-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by charge-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-charge-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: charge.definition')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: charge.definition')
        ==
      =/  rows  (result-rows:view i.p.res)
      ?.  =(1 (lent rows))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: charge.definition')
        ==
      =/  row  (snag 0 rows)
      ?.  =(%electricity (cell-term:view %physical-kind row))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%wrong-kind: charge.definition')
        ==
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.u.input
          ~
        =/  subtype
          (row-by-text:view %label u.subtype-label.u.input (rows-at:view p.res 3))
        ?~  subtype
          ~
        ``@ux`(cell-atom:view %subtype-id u.subtype)
      ?:  ?&  ?=(^ subtype-label.u.input)
              ?=(~ subtype-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: charge.subtype')
        ==
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=charge-ids:act
        :*  (fixture-id:act base 301)
            (fixture-id:act base 302)
            (fixture-id:act base 303)
            (fixture-id:act base 304)
            (fixture-id:act base 305)
            (charging-component-ids:act base (lent components.u.input) 310)
        ==
      =/  write-wire=path  /rover-charge-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  insert-charge:act
            ids
            `@ux`(cell-atom:view %vehicle-id row)
            `@ux`(cell-atom:view %energy-definition-id row)
            subtype-id
            u.input
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), charge-pending (~(put by charge-pending) write-wire u.input))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), charge-pending (~(del by charge-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-charge-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by charge-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-charge-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: charge')
        ==
      =/  delivered-text=@t
        ?~  delivered.u.input
          'Energy delivered not recorded'
        %-  crip
        ;:  weld
          "Energy delivered "
          (trip (format-scaled:render digits.u.delivered.u.input places.u.delivered.u.input %.n))
          " kWh"
        ==
      ::  Only an itemized or receipt-only charge reports a cost. %free and
      ::  %unknown carry no total, so their verdict stays the delivered energy.
      =/  cost-text=@t
        ?-  cost-state.u.input
          %free     ''
          %unknown  ''
          %itemized
            =/  amounts=(list charging-component-amount:rover)
              %+  turn  components.u.input
              |=  row=charging-component-entry:rover
              ^-  charging-component-amount:rover
              [component.row amount-mills.row]
            =/  proof  (derive-charging-total:act amounts)
            =/  total  (format-mills:render total-mills.proof currency.u.input)
            (cat 3 ' - itemized total ' total)
          %receipt-total-only
            ?~  source-total-mills.u.input
              ''
            =/  mills  u.source-total-mills.u.input
            =/  total  (format-mills:render mills currency.u.input)
            (cat 3 ' - receipt total ' total)
        ==
      =/  message  (cat 3 (cat 3 'Saved charge - ' delivered-text) cost-text)
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), charge-pending (~(del by charge-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-19]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?:  ?=(%.n -.res)
        (fail 'database lookup refused')
      =/  commands  p.res
      ?-  -.work
        %energy
          ?.  (gte (lent commands) 2)
            (fail 'incomplete energy definition lookup result')
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing label')
          ?^  rows
            =/  subtype-rows  (rows-at:view commands 1)
            =/  ambiguous=?
              %+  lien  subtypes.value.work
              |=  subtype=import-energy-subtype:rover
              (gth (lent (rows-by-text:view %label label.subtype subtype-rows)) 1)
            ?:  ambiguous
              (fail 'ambiguous existing subtype label')
            =/  missing=(list import-energy-subtype:rover)
              %+  skim  subtypes.value.work
              |=  subtype=import-energy-subtype:rover
              ?=(~ (rows-by-text:view %label label.subtype subtype-rows))
            =/  definition-id=@ux
              `@ux`(cell-atom:view %energy-definition-id i.rows)
            ::  M7 T10. An archived definition stays archived across a round
            ::  trip, and one the receiving ship holds in the other state is
            ::  corrected. This is the only place the flag can be honoured
            ::  for a definition the import did not create.
            =/  archive-script
              ;:  weld
                %:  archive-sync:imp
                    %energy
                    definition-id
                    (stored-archived:imp i.rows)
                    archived.value.work
                ==
                (subtype-archive-sync:imp subtypes.value.work subtype-rows)
              ==
            =/  report
              %_  report.run
                definitions-reused  +(definitions-reused.report.run)
                definitions-archived
                  ?~  archive-script
                    definitions-archived.report.run
                  +(definitions-archived.report.run)
              ==
            ?:  ?&  ?=(~ missing)
                    ?=(~ archive-script)
                ==
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            =/  base=@ux  (cut 7 [0 1] eny.bowl)
            =/  script
              %+  weld  archive-script
              (insert-energy-subtypes:imp base definition-id missing now.bowl)
            =/  next
              run(writing %.y, serial +(serial.run), report report)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run script)
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script  (insert-energy:imp base value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %service-subtype
          ?.  (gte (lent commands) 2)
            (fail 'incomplete service subtype lookup result')
          =/  definitions  (rows-at:view commands 0)
          =/  defaults  (rows-at:view commands 1)
          ?:  ?|  (gth (lent definitions) 1)
                  (gth (lent defaults) 1)
              ==
            (fail 'ambiguous existing service subtype label')
          ?^  definitions
            =/  archive-script
              %:  archive-sync:imp
                  %service-subtype
                  `@ux`(cell-atom:view %service-subtype-id i.definitions)
                  (stored-archived:imp i.definitions)
                  archived.value.work
              ==
            =/  report
              %_  report.run
                definitions-reused  +(definitions-reused.report.run)
                definitions-archived
                  ?~  archive-script
                    definitions-archived.report.run
                  +(definitions-archived.report.run)
              ==
            ?~  default.value.work
              ?~  archive-script
                (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
              =/  next  run(writing %.y, serial +(serial.run), report report)
              :_  this(import-run `next)
              (import-write-cards our.bowl serial.run archive-script)
            ?^  defaults
              ?:  (subtype-default-matches:imp u.default.value.work i.defaults)
                =/  reused
                  report(subtype-defaults-reused +(subtype-defaults-reused.report))
                (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report reused))
              =/  conflicted
                %_  report
                  conflicts  +(conflicts.report)
                  messages
                    [(import-detail 'Conflict' work 'default reminder interval differs') messages.report]
                ==
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report conflicted))
            =/  script
              (insert-subtype-default:imp `@ux`(cell-atom:view %service-subtype-id i.definitions) u.default.value.work)
            =/  created
              report(subtype-defaults-created +(subtype-defaults-created.report))
            =/  next  run(writing %.y, serial +(serial.run), report created)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run script)
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script  (insert-service-subtype:imp base value.work now.bowl)
          =/  report
            %_  report.run
              definitions-created  +(definitions-created.report.run)
              subtype-defaults-created
                ?~(default.value.work subtype-defaults-created.report.run +(subtype-defaults-created.report.run))
            ==
          =/  next  run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %simple
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing label')
          ?^  rows
            =/  meta  (simple-table:imp kind.work)
            =/  archive-script
              %:  archive-sync:imp
                  kind.work
                  `@ux`(cell-atom:view `@tas`id.meta i.rows)
                  (stored-archived:imp i.rows)
                  archived.value.work
              ==
            =/  report
              %_  report.run
                definitions-reused  +(definitions-reused.report.run)
                definitions-archived
                  ?~  archive-script
                    definitions-archived.report.run
                  +(definitions-archived.report.run)
              ==
            ?~  archive-script
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            =/  next
              run(writing %.y, serial +(serial.run), report report)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run archive-script)
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            (insert-simple:imp base kind.work value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        ::  M7 T10. A consumable definition and a custom field are two more
        ::  create-if-absent definition families. Neither is a `%simple` one:
        ::  a consumable carries the unit its quantity is measured in, and a
        ::  custom field carries its content type and whether it is mandatory.
        %consumable-definition
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing label')
          ?^  rows
            =/  archive-script
              %:  archive-sync:imp
                  %consumable
                  `@ux`(cell-atom:view %consumable-id i.rows)
                  (stored-archived:imp i.rows)
                  archived.value.work
              ==
            =/  report
              %_  report.run
                definitions-reused  +(definitions-reused.report.run)
                definitions-archived
                  ?~  archive-script
                    definitions-archived.report.run
                  +(definitions-archived.report.run)
              ==
            ?~  archive-script
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            =/  next
              run(writing %.y, serial +(serial.run), report report)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run archive-script)
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            (insert-consumable-definition:imp base value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %custom-field
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing label')
          ?^  rows
            ::  The content type is immutable once a value exists, so a
            ::  document that disagrees with the field already here is a
            ::  conflict rather than an update.
            ?.  =(content-type.value.work (cell-term:view %content-type i.rows))
              =/  conflicted
                %_  report.run
                  conflicts  +(conflicts.report.run)
                  messages
                    [(import-detail 'Conflict' work 'content type differs') messages.report.run]
                ==
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report conflicted))
            =/  archive-script
              %:  archive-sync:imp
                  %custom-field
                  `@ux`(cell-atom:view %field-id i.rows)
                  (stored-archived:imp i.rows)
                  archived.value.work
              ==
            =/  report
              %_  report.run
                definitions-reused  +(definitions-reused.report.run)
                definitions-archived
                  ?~  archive-script
                    definitions-archived.report.run
                  +(definitions-archived.report.run)
              ==
            ?~  archive-script
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            =/  next
              run(writing %.y, serial +(serial.run), report report)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run archive-script)
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script  (insert-custom-field:imp base value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        ::  M7 T10. A place holds one or more stations, and a station carries
        ::  a label of its own. The lookup returns every station of the place,
        ::  so the write adds the ones the document names that are missing and
        ::  leaves the rest alone.
        %place
          =/  places  (rows-at:view commands 0)
          =/  stations  (rows-at:view commands 1)
          ?:  (gth (lent places) 1)
            (fail 'ambiguous existing label')
          =/  existing-place-id=(unit @ux)
            ?~  places
              ~
            ``@ux`(cell-atom:view %place-id i.places)
          =/  existing-stations  (row-texts:imp %label stations)
          =/  report
            ?^  existing-place-id
              report.run(places-reused +(places-reused.report.run))
            report.run(places-created +(places-created.report.run))
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  archive-script
            ?~  places
              ""
            (place-archive-sync:imp value.work i.places stations)
          =/  script
            %+  weld  archive-script
            %:  insert-place:imp
                base
                value.work
                station-kind.value.work
                existing-place-id
                existing-stations
                now.bowl
            ==
          ?~  script
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %vehicle
          ?.  (gte (lent commands) 5)
            (fail 'incomplete vehicle lookup result')
          =/  vehicles  (rows-at:view commands 0)
          ?:  (gth (lent vehicles) 1)
            (fail 'ambiguous existing label')
          =/  definitions  (rows-at:view commands 1)
          =/  modes  (rows-at:view commands 2)
          =/  definition-ids  (row-ids:view %energy-definition-id definitions)
          =/  mode-ids  (row-ids:view %mode-id modes)
          ::  A batch that carries none of a vehicle's fills still creates the
          ::  vehicle, so a later batch meets a vehicle that lacks the energy
          ::  definitions and driving modes its own fills use. Import widens the
          ::  vehicle: it adds those links. It never archives a link and never
          ::  moves vehicle-default-energy-definitions, so a widened vehicle
          ::  keeps the configuration its owner chose. Ruled 2026-08-12 in
          ::  ~/brain/projects/rover/import-gui.md.
          ?^  vehicles
            =/  report
              report.run(vehicles-reused +(vehicles-reused.report.run))
            =/  linked-definitions  (rows-at:view commands 3)
            =/  linked-modes  (rows-at:view commands 4)
            =/  archived-definitions  (archived-link-rows:view linked-definitions)
            =/  archived-modes  (archived-link-rows:view linked-modes)
            =/  script
              %:  widen-import-vehicle:imp
                  `@ux`(cell-atom:view %vehicle-id i.vehicles)
                  definition-ids
                  mode-ids
                  (row-ids:view %energy-definition-id linked-definitions)
                  (row-ids:view %energy-definition-id archived-definitions)
                  (row-ids:view %mode-id linked-modes)
                  (row-ids:view %mode-id archived-modes)
                  specification.value.work
                  now.bowl
              ==
            ?~  script
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            =/  next
              run(writing %.y, serial +(serial.run), report report)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run script)
          =/  default
            (row-by-text:view %label default-energy.value.work definitions)
          ?~  default
            (fail 'default energy definition was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            %:  insert-import-vehicle:imp
                base
                value.work
                `@ux`(cell-atom:view %energy-definition-id u.default)
                definition-ids
                mode-ids
                now.bowl
            ==
          =/  report
            report.run(vehicles-created +(vehicles-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %fill
          ?.  (gte (lent commands) 1)
            (fail 'incomplete database lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            =/  report
              %_  report.run
                conflicts  +(conflicts.report.run)
                messages
                  [(import-detail 'Conflict' work 'ambiguous provenance') messages.report.run]
              ==
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          ?^  existing
            =/  differences  (existing-main-differences:imp value.work commands)
            =/  found=@ux  `@ux`(cell-atom:view %acquisition-id i.existing)
            ?~  differences
              :_  this(import-run `run(comparing `found))
              (import-comparison-cards our.bowl serial.run found)
            =/  report
              %_  report.run
                conflicts  +(conflicts.report.run)
                messages
                  [(import-detail 'Conflict' work (join-fields:imp differences)) messages.report.run]
              ==
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  mismatches
            (fill-unit-mismatches:imp distance-unit.work volume-unit.work value.work)
          ?^  mismatches
            (fail (cat 3 'unit mismatch: ' (join-fields:imp mismatches)))
          :_  this
          (import-support-cards our.bowl serial.run value.work)
        ::
        %event
          ?.  (gte (lent commands) 7)
            (fail 'incomplete event lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            =/  report
              report.run(event-conflicts +(event-conflicts.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          ?^  existing
            =/  report
              report.run(events-already-imported +(events-already-imported.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  input  input.value.work
          =/  event-vehicle-rows  (rows-at:view commands 1)
          ?.  =(1 (lent event-vehicle-rows))
            (fail 'event vehicle was not found')
          =/  event-vehicle-row=vector:ast  (snag 0 event-vehicle-rows)
          =/  station-rows  (rows-at:view commands 2)
          =/  tag-rows  (rows-at:view commands 3)
          =/  payment-rows  (rows-at:view commands 4)
          =/  subtype-rows  (rows-at:view commands 5)
          =/  disposal-rows  (rows-at:view commands 6)
          =/  station-id=(unit @ux)
            ?~  station-label.input
              ~
            =/  found  (row-by-text:view %label u.station-label.input station-rows)
            ?~  found
              ~
            ``@ux`(cell-atom:view %station-id u.found)
          ?:  ?&  ?=(^ station-label.input)
                  ?=(~ station-id)
              ==
            (fail 'event station was not found')
          =/  tag-proof
            (ids-for-labels:view tag-labels.input tag-rows %label %tag-id)
          ?:  ?=(%| -.tag-proof)
            (fail 'an event tag definition was not found')
          =/  subtype-proof
            (ids-for-labels:view subtype-labels.input subtype-rows %label %service-subtype-id)
          ?:  ?=(%| -.subtype-proof)
            (fail 'an event subtype definition was not found')
          =/  disposal-kind-id=(unit @ux)
            ?~  disposal-kind-label.input
              ~
            =/  found  (row-by-text:view %label u.disposal-kind-label.input disposal-rows)
            ?~  found
              ~
            ``@ux`(cell-atom:view %disposal-kind-id u.found)
          ?:  ?&  ?=(^ disposal-kind-label.input)
                  ?=(~ disposal-kind-id)
              ==
            (fail 'event disposal kind was not found')
          =/  payment-id=(unit @ux)
            ?~  payment-method-label.input
              ~
            =/  found  (row-by-text:view %label u.payment-method-label.input payment-rows)
            ?~  found
              ~
            ``@ux`(cell-atom:view %method-id u.found)
          ?:  ?&  ?=(^ payment-method-label.input)
                  ?=(~ payment-id)
              ==
            (fail 'event payment method was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  ids=event-ids:act
            :*  (fixture-id:act base 201)
                (fixture-id:act base 202)
                (fixture-id:act base 203)
                (fixture-id:act base 204)
                (fixture-id:act base 205)
            ==
          =/  command-note=(unit @t)
            ?~  notes.input
              ~
            ?:  (urql-cord-safe:imp u.notes.input)
              ~
            notes.input
          =/  script-input=event-entry:rover
            ?~  command-note
              input
            input(notes `'Rover import note placeholder')
          =/  script
            %:  insert-event:act
                ids
                `@ux`(cell-atom:view %vehicle-id event-vehicle-row)
                station-id
                p.tag-proof
                p.subtype-proof
                disposal-kind-id
                payment-id
                script-input
                now.bowl
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          ?~  command-note
            (import-write-cards our.bowl serial.run script)
          (import-parse-cards our.bowl serial.run script)
        ::
        %reminder
          ?.  (gte (lent commands) 3)
            (fail 'incomplete reminder lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            (fail 'ambiguous existing reminder')
          ?^  existing
            =/  report
              report.run(reminders-already-imported +(reminders-already-imported.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  reminder-vehicle-rows  (rows-at:view commands 1)
          =/  subtypes  (rows-at:view commands 2)
          ?.  =(1 (lent reminder-vehicle-rows))
            (fail 'reminder vehicle was not found')
          =/  reminder-vehicle-row=vector:ast  (snag 0 reminder-vehicle-rows)
          =/  found  (row-by-text:view %label subtype-label.value.work subtypes)
          ?~  found
            (fail 'reminder subtype was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            %:  insert-reminder:act
                (fixture-id:act base 601)
                `@ux`(cell-atom:view %vehicle-id reminder-vehicle-row)
                `@ux`(cell-atom:view %service-subtype-id u.found)
                value.work
                now.bowl
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        ::  M7 T10. A charging session lands through the same lookup the entry
        ::  path uses, so every invariant it enforces - the definition must be
        ::  electricity, the subtype must exist - is enforced once.
        %charge
          ?.  (gte (lent commands) 5)
            (fail 'incomplete charge lookup result')
          =/  existing  (rows-at:view commands 0)
          ?^  existing
            =/  report
              report.run(charges-already-imported +(charges-already-imported.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  support-rows  (rows-at:view commands 1)
          ?.  =(1 (lent support-rows))
            (fail 'charge vehicle or energy definition was not found')
          =/  support=vector:ast  (snag 0 support-rows)
          ?.  =(%electricity (cell-term:view %physical-kind support))
            (fail 'charge definition is not an electricity source')
          =/  charge-subtype-id=(unit @ux)
            ?~  subtype-label.input.value.work
              ~
            =/  found
              %+  row-by-text:view  %label
              [u.subtype-label.input.value.work (rows-at:view commands 4)]
            ?~  found
              ~
            ``@ux`(cell-atom:view %subtype-id u.found)
          ?:  ?&  ?=(^ subtype-label.input.value.work)
                  ?=(~ charge-subtype-id)
              ==
            (fail 'charge subtype was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  ids=charge-ids:act
            :*  (fixture-id:act base 701)
                (fixture-id:act base 702)
                (fixture-id:act base 703)
                (fixture-id:act base 704)
                (fixture-id:act base 705)
                (charging-component-ids:act base (lent components.input.value.work) 710)
            ==
          =/  provenance-script=tape
            ?~  provenance.value.work
              ~
            ;:  weld
              " INSERT INTO acquisition-imports VALUES ("
              (scow %ux acquisition.ids)
              ", "
              (sql-term:act source-app.u.provenance.value.work)
              ", '"
              (sql-quote:act source-record-id.u.provenance.value.work)
              "');"
            ==
          =/  script
            %+  weld
              %:  insert-charge:act
                  ids
                  `@ux`(cell-atom:view %vehicle-id support)
                  `@ux`(cell-atom:view %energy-definition-id support)
                  charge-subtype-id
                  input.value.work
                  now.bowl
              ==
            provenance-script
          =/  report
            report.run(charges-imported +(charges-imported.report.run))
          =/  next  run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %consumable-purchase
          ?.  (gte (lent commands) 3)
            (fail 'incomplete consumable purchase lookup result')
          =/  existing  (rows-at:view commands 0)
          ?^  existing
            =/  report
              report.run(purchases-already-imported +(purchases-already-imported.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  purchase-vehicles  (rows-at:view commands 1)
          =/  purchase-definitions  (rows-at:view commands 2)
          ?.  ?&  =(1 (lent purchase-vehicles))
                  =(1 (lent purchase-definitions))
              ==
            (fail 'consumable purchase vehicle or definition was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            %:  insert-consumable:act
                (fixture-id:act base 801)
                (fixture-id:act base 802)
                `@ux`(cell-atom:view %vehicle-id (snag 0 purchase-vehicles))
                `@ux`(cell-atom:view %consumable-id (snag 0 purchase-definitions))
                (cell-term:view %quantity-unit (snag 0 purchase-definitions))
                value.work
                now.bowl
            ==
          =/  report
            report.run(purchases-imported +(purchases-imported.report.run))
          =/  next  run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        ::  M7 T10. Everything a vehicle holds that is not a record: the
        ::  display preference, the refill reserve, the default subtype, and
        ::  the three link families. It runs last, so every definition it
        ::  names by label already exists.
        %vehicle-extras
          ?.  (gte (lent commands) 12)
            (fail 'incomplete vehicle settings lookup result')
          =/  extras-vehicles  (rows-at:view commands 0)
          ?.  =(1 (lent extras-vehicles))
            (fail 'vehicle was not found')
          =/  extras-vehicle-id=@ux
            `@ux`(cell-atom:view %vehicle-id (snag 0 extras-vehicles))
          =/  energy-catalog  (rows-at:view commands 1)
          =/  mode-catalog  (rows-at:view commands 2)
          =/  consumable-catalog  (rows-at:view commands 3)
          =/  subtype-catalog  (rows-at:view commands 4)
          =/  linked-consumables  (rows-at:view commands 5)
          =/  tank-rows  (rows-at:view commands 9)
          =/  linked-energy  (rows-at:view commands 10)
          =/  linked-modes  (rows-at:view commands 11)
          =/  resolve
            |*  [links=(list import-vehicle-link:rover) catalog=(list vector:ast) column=@tas linked=(list vector:ast)]
            ^-  (list [target=@ux archived=? linked=?])
            %+  murn  links
            |=  link=import-vehicle-link:rover
            ^-  (unit [target=@ux archived=? linked=?])
            =/  found  (row-by-text:view %label label.link catalog)
            ?~  found
              ~
            =/  target  `@ux`(cell-atom:view column u.found)
            :-  ~
            :+  target
              archived.link
            ?=(^ (rows-by:view column target linked))
          =/  energy-links
            (resolve energy-links.value.work energy-catalog %energy-definition-id linked-energy)
          =/  mode-links
            (resolve mode-links.value.work mode-catalog %mode-id linked-modes)
          =/  consumable-links
            ^-  (list [target=@ux archived=? linked=? tank=(unit scaled-entry:rover)])
            %+  murn  consumable-links.value.work
            |=  link=import-vehicle-consumable:rover
            ^-  (unit [target=@ux archived=? linked=? tank=(unit scaled-entry:rover)])
            =/  found  (row-by-text:view %label label.link consumable-catalog)
            ?~  found
              ~
            =/  target  `@ux`(cell-atom:view %consumable-id u.found)
            :-  ~
            :^    target
                archived.link
              ?=(^ (rows-by:view %consumable-id target linked-consumables))
            tank-size.link
          =/  default-subtype-id=(unit @ux)
            ?~  default-subtype.value.work
              ~
            =/  found
              (row-by-text:view %label u.default-subtype.value.work subtype-catalog)
            ?~  found
              ~
            ``@ux`(cell-atom:view %subtype-id u.found)
          =/  script
            %:  vehicle-extras-write:imp
                extras-vehicle-id
                value.work
                energy-links
                mode-links
                consumable-links
                default-subtype-id
                now.bowl
            ==
          =/  written
            ;:  add
              (lent energy-links)
              (lent mode-links)
              (lent consumable-links)
            ==
          =/  report
            report.run(vehicle-links-written (add vehicle-links-written.report.run written))
          ?~  script
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  next  run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %app-default
          ?.  (gte (lent commands) 2)
            (fail 'incomplete default vehicle lookup result')
          =/  default-vehicles  (rows-at:view commands 0)
          ?.  =(1 (lent default-vehicles))
            (fail 'default vehicle was not found')
          =/  script
            %:  app-default-write:imp
                `@ux`(cell-atom:view %vehicle-id (snag 0 default-vehicles))
                ?=(^ (rows-at:view commands 1))
                now.bowl
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
      ==
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-comparison *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-19]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?.  =(%fill -.work)
        (fail 'internal comparison lookup mismatch')
      =/  fill  (fill-work-value:imp work)
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        (fail 'database comparison lookup refused')
      ?.  (gte (lent p.res) 6)
        (fail 'incomplete database comparison lookup result')
      =/  differences  (existing-child-differences:imp fill p.res)
      ?~  differences
        ?~  comparing.run
          (fail 'internal comparison lost the row it was reading')
        :_  this
        (import-comparison-tail-cards our.bowl serial.run u.comparing.run)
      =/  report
        %_  report.run
          conflicts  +(conflicts.report.run)
          messages
            [(import-detail 'Conflict' work (join-fields:imp differences)) messages.report.run]
        ==
      (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-comparison-tail *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-19]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?.  =(%fill -.work)
        (fail 'internal comparison-tail lookup mismatch')
      =/  fill  (fill-work-value:imp work)
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        (fail 'database comparison-tail lookup refused')
      ?.  (gte (lent p.res) 5)
        (fail 'incomplete database comparison-tail lookup result')
      =/  differences  (existing-tail-differences:imp fill p.res)
      ?~  differences
        =/  report
          report.run(already-imported +(already-imported.report.run))
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      =/  report
        %_  report.run
          conflicts  +(conflicts.report.run)
          messages
            [(import-detail 'Conflict' work (join-fields:imp differences)) messages.report.run]
        ==
      (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-support *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-19]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?.  =(%fill -.work)
        (fail 'internal support lookup mismatch')
      =/  fill  (fill-work-value:imp work)
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        (fail 'database support lookup refused')
      =/  commands  p.res
      ?.  (gte (lent commands) 7)
        (fail 'incomplete database support lookup result')
      =/  input  (canonical-fill:imp input.fill)
      =/  supports  (rows-at:view commands 0)
      ?.  =(1 (lent supports))
        (fail 'vehicle or energy definition was not found')
      =/  support  (snag 0 supports)
      ?.  =(%reservoir (cell-term:view %physical-kind support))
        (fail 'energy definition is not a reservoir fuel')
      =/  quantity-unit  (cell-term:view %quantity-unit support)
      ?.  =((fill-volume-unit:imp price-profile.input) quantity-unit)
        (fail 'fill profile and energy quantity unit differ')
      =/  station-rows  (rows-at:view commands 1)
      =/  station-id=(unit @ux)
        ?~  station-label.input
          ~
        =/  found
          (row-by-text:view %label u.station-label.input station-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.input)
              ?=(~ station-id)
          ==
        (fail 'station was not found')
      =/  additive-proof
        (ids-for-labels:view additive-labels.input (rows-at:view commands 2) %label %additive-id)
      ?:  ?=(%| -.additive-proof)
        (fail 'an additive definition was not found')
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.input
          ~
        =/  found
          (row-by-text:view %label u.subtype-label.input (rows-at:view commands 3))
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ subtype-label.input)
              ?=(~ subtype-id)
          ==
        (fail 'energy subtype was not found')
      =/  driving-mode-id=(unit @ux)
        ?~  driving-mode-label.input
          ~
        =/  found
          (row-by-text:view %label u.driving-mode-label.input (rows-at:view commands 4))
        ?~  found
          ~
        ``@ux`(cell-atom:view %mode-id u.found)
      ?:  ?&  ?=(^ driving-mode-label.input)
              ?=(~ driving-mode-id)
          ==
        (fail 'driving mode was not linked to the vehicle')
      =/  tag-proof
        (ids-for-labels:view tag-labels.input (rows-at:view commands 5) %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        (fail 'a tag definition was not found')
      =/  payment-method-id=(unit @ux)
        ?~  payment-method-label.input
          ~
        =/  found
          (row-by-text:view %label u.payment-method-label.input (rows-at:view commands 6))
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.input)
              ?=(~ payment-method-id)
          ==
        (fail 'payment method was not found')
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=entry-ids:act
        :*  (fixture-id:act base 101)
            (fixture-id:act base 102)
            (fixture-id:act base 103)
            (fixture-id:act base 104)
            (fixture-id:act base 105)
        ==
      =/  command-note=(unit @t)
        ?~  notes.input
          ~
        ?:  (urql-cord-safe:imp u.notes.input)
          ~
        notes.input
      =/  script-input=fill-entry:rover
        ?~  command-note
          input
        input(notes `'Rover import note placeholder')
      ::  M7 T10. The owner-defined field values this fill carries. A value
      ::  naming a field that is not here, or one the field's content type
      ::  cannot hold, is named in the report rather than guessed at.
      =/  custom-proof
        %:  custom-value-script:imp
            acquisition.ids
            custom-values.fill
            (rows-at:view commands 7)
        ==
      =/  script
        %:  insert-import-fill:imp
            ids
            `@ux`(cell-atom:view %vehicle-id support)
            `@ux`(cell-atom:view %energy-definition-id support)
            quantity-unit
            station-id
            p.additive-proof
            subtype-id
            driving-mode-id
            p.tag-proof
            payment-method-id
            script-input
            provenance.fill
            script.custom-proof
            now.bowl
        ==
      =/  next
        %_  run
          writing  %.y
          serial   +(serial.run)
          report
            %_  report.run
              custom-values-written
                (add custom-values-written.report.run written.custom-proof)
              messages
                %+  weld  messages.report.run
                %+  turn  skipped.custom-proof
                |=(label=@t (import-detail 'Unmapped' work label))
            ==
        ==
      :_  this(import-run `next)
      ?~  command-note
        (import-write-cards our.bowl serial.run script)
      (import-parse-cards our.bowl serial.run script)
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance-failure
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        =/  next
          run(writing %.n, remaining t.remaining.run, report report)
        =/  continued=[(list card) state-19]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  phase=@ta
        ?~  t.wire
          %script
        i.t.wire
      ?:  =(%parse phase)
        =/  parsed  ;;((each (list command:ast) tang) +.q.cage.sign)
        ?:  ?=(%.n -.parsed)
          (advance-failure 'atomic database mutation parse refused')
        =/  patched
          ?-  -.work
            %fill
              =/  fill  (fill-work-value:imp work)
              (replace-fill-note:imp p.parsed (need notes.input.fill))
            %event
              (replace-event-note:imp p.parsed (need notes.input.value.work))
            %energy                 !!
            %service-subtype        !!
            %simple                 !!
            %place                  !!
            %vehicle                !!
            %reminder               !!
            %consumable-definition  !!
            %custom-field           !!
            %charge                 !!
            %consumable-purchase    !!
            %vehicle-extras         !!
            %app-default            !!
          ==
        ?:  ?=(%| -.patched)
          (advance-failure p.patched)
        :_  this
        (import-command-write-cards our.bowl serial.run p.patched)
      ?:  =(%cmd-list phase)
        =/  report
          ?-  -.work
            %fill
              report.run(imported +(imported.report.run))
            %event
              report.run(events-imported +(events-imported.report.run))
            %reminder
              report.run(reminders-imported +(reminders-imported.report.run))
            %energy                 report.run
            %service-subtype        report.run
            %simple                 report.run
            %place                  report.run
            %vehicle                report.run
            %consumable-definition  report.run
            %custom-field           report.run
            %charge                 report.run
            %consumable-purchase    report.run
            %vehicle-extras         report.run
            %app-default            report.run
          ==
        =/  next
          run(writing %.n, remaining t.remaining.run, report report)
        =/  continued=[(list card) state-19]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  report
        ?:  ?=(%.n -.res)
          %_  report.run
            failures  +(failures.report.run)
            messages
              [(import-detail 'Failure' work 'atomic database mutation refused') messages.report.run]
          ==
        ?-  -.work
          %fill
            report.run(imported +(imported.report.run))
          %event
            report.run(events-imported +(events-imported.report.run))
          %reminder
            report.run(reminders-imported +(reminders-imported.report.run))
          %energy                 report.run
          %service-subtype        report.run
          %simple                 report.run
          %place                  report.run
          %vehicle                report.run
          %consumable-definition  report.run
          %custom-field           report.run
          %charge                 report.run
          %consumable-purchase    report.run
          %vehicle-extras         report.run
          %app-default            report.run
        ==
      =/  next
        run(writing %.n, remaining t.remaining.run, report report)
      =/  continued=[(list card) state-19]
        (continue-import state our.bowl next)
      [-.continued this(state +.continued)]
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-fill-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by fill-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?|  ?=(~ input)
              ?=(~ body)
          ==
        :_  %_  this
              http-pending  (~(del by http-pending) wire)
              fill-pending  (~(del by fill-pending) wire)
              fill-body-pending  (~(del by fill-body-pending) wire)
            ==
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-fill-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: fill.definition')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.definition')
        ==
      =/  rows  (result-rows:view i.p.res)
      ?.  =(1 (lent rows))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: fill.definition')
        ==
      =/  row  (snag 0 rows)
      =/  kind  (cell-term:view %physical-kind row)
      =/  quantity-unit  (cell-term:view %quantity-unit row)
      ?.  =(%reservoir kind)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%wrong-kind: fill.definition')
        ==
      =/  expected-unit=@tas
        ?:  =(%us-usd-gal price-profile.u.input)
          %gal
        %litre
      ?.  =(expected-unit quantity-unit)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%unit-mismatch: fill.profile')
        ==
      ?.  (gte (lent p.res) 9)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: fill.evidence')
        ==
      =/  station-rows  (rows-at:view p.res 1)
      =/  additive-rows  (rows-at:view p.res 2)
      =/  subtype-rows  (rows-at:view p.res 3)
      =/  driving-mode-rows  (rows-at:view p.res 5)
      =/  tag-rows  (rows-at:view p.res 6)
      =/  custom-rows  (rows-at:view p.res 7)
      =/  payment-rows  (rows-at:view p.res 8)
      =/  station-id=(unit @ux)
        ?~  station-label.u.input
          ~
        =/  found  (row-by-text:view %label u.station-label.u.input station-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.u.input)
              ?=(~ station-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.station')
        ==
      =/  additive-proof
        (ids-for-labels:view additive-labels.u.input additive-rows %label %additive-id)
      ?:  ?=(%| -.additive-proof)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.additives')
        ==
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.u.input
          ~
        =/  found
          (row-by-text:view %label u.subtype-label.u.input subtype-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ subtype-label.u.input)
              ?=(~ subtype-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.subtype')
        ==
      =/  driving-mode-id=(unit @ux)
        ?~  driving-mode-label.u.input
          ~
        =/  found
          (row-by-text:view %label u.driving-mode-label.u.input driving-mode-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %mode-id u.found)
      ?:  ?&  ?=(^ driving-mode-label.u.input)
              ?=(~ driving-mode-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.driving-mode')
        ==
      =/  tag-proof
        (ids-for-labels:view tag-labels.u.input tag-rows %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.tags')
        ==
      =/  payment-method-id=(unit @ux)
        ?~  payment-method-label.u.input
          ~
        =/  found
          (row-by-text:view %label u.payment-method-label.u.input payment-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.u.input)
              ?=(~ payment-method-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.payment-method')
        ==
      ?:  ?&  ?=(^ new-tag-label.u.input)
              ?=(^ (row-by-text:view %label u.new-tag-label.u.input tag-rows))
          ==
        :_  this
        %:  http-give
            u.eyre-id
            409
            ['content-type' 'text/plain']~
            `(text-octs '%already-exists: fill.new-tag')
        ==
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=entry-ids:act
        :*  (fixture-id:act base 101)
            (fixture-id:act base 102)
            (fixture-id:act base 103)
            (fixture-id:act base 104)
            (fixture-id:act base 105)
        ==
      =/  object  (need (json-object:entry u.body))
      =/  custom-script
        =/  build
          |=  rows=(list vector:ast)
          ^-  (each tape @t)
          ?~  rows
            [%& ~]
          =/  archived  =(0 (cell-atom:view %archived i.rows))
          ?:  archived
            $(rows t.rows)
          =/  label  (cell-text:view %label i.rows)
          =/  key  (cat 3 'custom-' label)
          =/  value-unit  (json-string:entry key object)
          =/  value=@t  ?~(value-unit '' u.value-unit)
          =/  mandatory  =(0 (cell-atom:view %mandatory i.rows))
          ?:  ?&  mandatory
                  !(nonempty:entry value)
              ==
            [%| label]
          ?.  (nonempty:entry value)
            $(rows t.rows)
          =/  content  (cell-term:view %content-type i.rows)
          =/  row-script=tape
            ?+  content  ~
              %text
                (insert-custom-text:act `@ux`(cell-atom:view %field-id i.rows) acquisition.ids value)
              %boolean
                (insert-custom-boolean:act `@ux`(cell-atom:view %field-id i.rows) acquisition.ids =('yes' value))
              %number
                =/  number  (parse-decimal:render value 3)
                ?:  ?=(%| -.number)
                  ~
                %:  insert-custom-number:act
                    `@ux`(cell-atom:view %field-id i.rows)
                    acquisition.ids
                    digits.p.number
                    places.p.number
                ==
            ==
          ?:  ?&  =(%number content)
                  ?=(~ row-script)
              ==
            [%| label]
          =/  rest  $(rows t.rows)
          ?:  ?=(%| -.rest)
            rest
          [%& (weld row-script p.rest)]
        (build custom-rows)
      ?:  ?=(%| -.custom-script)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs (cat 3 '%mandatory-or-invalid: custom-field.' p.custom-script))
        ==
      =/  write-wire=path
        /rover-fill-write/(scot %da now.bowl)/[u.eyre-id]
      =/  fill-script
        %:  insert-fill:act
            ids
            `@ux`(cell-atom:view %vehicle-id row)
            `@ux`(cell-atom:view %energy-definition-id row)
            quantity-unit
            station-id
            p.additive-proof
            subtype-id
            driving-mode-id
            p.tag-proof
            payment-method-id
            u.input
            now.bowl
        ==
      =/  script  (weld fill-script p.custom-script)
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), fill-pending (~(put by fill-pending) write-wire u.input), fill-body-pending (~(put by fill-body-pending) write-wire u.body))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-pending (~(del by fill-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-fill-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by fill-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-fill-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: fill')
        ==
      =/  proof
        %:  derive-fill-total:act
            quantity-milli.u.input
            unit-price-mills.u.input
            minor-unit-decimals.u.input
            cash-increment-mills.u.input
            settlement-mode.u.input
        ==
      =/  total-display
        %:  format-total:render
            total-mills.proof
            currency.u.input
            minor-unit-decimals.u.input
        ==
      =/  message
        %-  crip
        ;:  weld
          "Saved fill - "
          (trip price-display.u.input)
          " - derived "
          (trip total-display)
        ==
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-pending (~(del by fill-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-http @tas *]
    =/  mode=@tas  i.t.wire
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        ~&  [%rover-ui-view-refused p.res]
        ?:  =(mode %recover)
          ?~  request-text
            :_  this(http-pending (~(del by http-pending) wire))
            (restart-http u.eyre-id)
          =/  next-wire=path
            /rover-bootstrap-probe/(scot %da now.bowl)/[u.eyre-id]
          =/  jon  !>([%script %sys %vector database-list:act])
          =/  next-pending
            (~(put by (~(del by pending) wire)) next-wire u.request-text)
          =/  next-http
            (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
          :_  this(pending next-pending, http-pending next-http)
          :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
              [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
          ==
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Rover could not load the vehicle log. Obelisk refused the view query.')
        ==
      =/  history-page=@ud
        ?~  request-text
          0
        =/  request-object  (json-object:entry u.request-text)
        =/  page-text=@t
          ?~  request-object
            u.request-text
          =/  page-value  (json-string:entry 'page' u.request-object)
          ?~(page-value '0' u.page-value)
        =/  parsed  (slaw %ud page-text)
        ?~(parsed 0 u.parsed)
      =/  selected-label=(unit @t)
        ?~  request-text
          ~
        =/  request-object  (json-object:entry u.request-text)
        ?~  request-object
          ~
        (json-string:entry 'vehicle' u.request-object)
      =/  headers=header-list:http
        ?:  =(mode %bootstrapped)
          :~  ['content-type' 'text/html']
              ['x-rover-bootstrap' 'performed']
          ==
        ['content-type' 'text/html']~
      :_  this(bootstrap-ready %.y)
      %:  http-give
          u.eyre-id
          200
          headers
          `(as-octs:mimes:html (page:view our.bowl now.bowl history-page selected-label p.res))
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?.  ?=(%.n -.res)
        `this(last `res)
      ~&  "{<(slog p.res)>}"
      `this(last `res)
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
      [%x %last ~]
    ``noun+!>(last)
  ::
      [%x %preview ~]
    ``noun+!>(preview)
  ::
      [%x %total ~]
    ``noun+!>(total)
  ::
      [%x %charging-total ~]
    ``noun+!>(charging-total)
  ::
      [%x %integrity ~]
    ``noun+!>(integrity)
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  ?=([%http-response @ ~] path)
  `this
::
++  on-leave
  |=  =path
  ^-  (quip card _this)
  ?>  ?=([%http-response @ ~] path)
  `this
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%rover-energy-odometer-precheck-delay *] wire)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      `this(pending (~(del by pending) wire))
    =/  next-wire=path
      /rover-energy-odometer-precheck/(scot %da now.bowl)
    :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
    (obelisk-script-cards our.bowl next-wire energy-odometer-migration-check:act)
  ?:  ?=([%rover-energy-odometer-drop-delay *] wire)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      `this(pending (~(del by pending) wire))
    =/  next-wire=path
      /rover-energy-odometer-drop/(scot %da now.bowl)
    :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
    (obelisk-script-cards our.bowl next-wire energy-odometer-drop-old:act)
  ?:  ?=([%rover-install-delay *] wire)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      `this
    =/  next-wire=path  /rover-install-starter-check/(scot %da now.bowl)
    =/  jon  !>([%script %rover %vector starter-check:act])
    :_  this
    :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
        [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ?:  ?=([%rover-bootstrap-delay *] wire)
    =/  eyre-id  (~(get by http-pending) wire)
    =/  request-text  (~(get by pending) wire)
    ?~  eyre-id
      `this
    ?~  request-text
      :_  this(http-pending (~(del by http-pending) wire))
      (restart-http u.eyre-id)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while waiting to add starter definitions. The system timer refused the request.')
      ==
    =/  next-wire=path
      /rover-bootstrap-starter-check/created/(scot %da now.bowl)/[u.eyre-id]
    =/  jon  !>([%script %rover %vector starter-check:act])
    =/  next-pending
      (~(put by (~(del by pending) wire)) next-wire u.request-text)
    =/  next-http
      (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
    :_  this(pending next-pending, http-pending next-http)
    :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
        [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ?>  ?=([%eyre %connect ~] wire)
  ?>  ?=([%eyre %bound *] sign-arvo)
  ~?  !accepted.sign-arvo  [%rover %eyre-bind-refused]
  `this
++  on-fail   on-fail:def
--
