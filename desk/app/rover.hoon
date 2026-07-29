::  app/rover - lean tracer: accept %init-db, apply M0 schema to %obelisk.
::  One path, proven. Other actions land as separate proven increments.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, default-agent, dbug, entry=rover-entry, render=rover-render, view=rover-view
/*  shell-html  %html  /app/rover/shell/html
/*  tile-png    %png   /app/rover/assets/tile/png
/*  font-regular       %woff2x  /app/rover/assets/fonts/berkeleymono-regular/woff2x
/*  font-bold          %woff2x  /app/rover/assets/fonts/berkeleymono-bold/woff2x
/*  font-oblique       %woff2x  /app/rover/assets/fonts/berkeleymono-oblique/woff2x
/*  font-bold-oblique  %woff2x  /app/rover/assets/fonts/berkeleymono-bold-oblique/woff2x
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
  ==
+$  new-station-entry-10
  [place-label=@t station-label=@t station-kind=station-kind:rover]
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
      charge-pending=(map wire charge-entry:rover)
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
      charge-pending=(map wire charge-entry:rover)
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
      charge-pending=(map wire charge-entry:rover)
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
      charge-pending=(map wire charge-entry:rover)
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
      charge-pending=(map wire charge-entry:rover)
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
      charge-pending=(map wire charge-entry:rover)
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
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
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
++  font-oblique-octs
  ^-  octs
  font-oblique
::
++  font-bold-oblique-octs
  ^-  octs
  font-bold-oblique
::
++  text-octs
  |=  text=@t
  ^-  octs
  (as-octs:mimes:html text)
::
++  entry-refusal
  |=  verdict=entry-verdict:rover
  ^-  @t
  (cat 3 '%' (cat 3 (scot %tas class.verdict) (cat 3 ': ' field.verdict)))
::
++  handle-http
  |=  [sat=state-13 =bowl:gall eyre-id=@ta req=inbound-request:eyre]
  ^-  [(list card) state-13]
  ?.  authenticated.req
    =/  loc  (cat 3 '/~/login?redirect=' url.request.req)
    [(http-give eyre-id 303 ['location' loc]~ ~) sat]
  ?>  =(our.bowl src.bowl)
  ?:  =(%'POST' method.request.req)
    ?:  =('/apps/rover/add-consumable' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: consumable')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-consumable:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-consumable-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%tape %rover (consumable-lookup:act vehicle-label.p.decoded consumable-label.p.decoded)])
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
        !>([%tape %rover (insert-custom-definition:act (fixture-id:act base 501) p.decoded now.bowl)])
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
      =/  jon  !>([%tape %rover (custom-field-lookup:act label)])
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
        !>([%tape %rover (edit-fill-lookup:act vehicle-label.p.decoded (need original-observed) definition-label.p.decoded)])
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
      =/  jon  !>([%tape %rover (vehicle-edit-lookup:act vehicle-label.p.decoded)])
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
      =/  jon  !>([%tape %rover (app-default-lookup:act vehicle-label.p.decoded)])
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
      =/  jon  !>([%tape %rover (vehicle-lookup:act vehicle-label.p.decoded)])
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
      =/  jon  !>([%tape %rover new-vehicle-lookup:act])
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
      =/  jon  !>([%tape %rover (preference-lookup:act vehicle-label.p.decoded)])
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
        !>([%tape %rover (fill-lookup:act vehicle-label.p.decoded definition-label.p.decoded)])
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
      =/  jon  !>([%tape %rover (vehicle-lookup:act vehicle-label.p.decoded)])
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
      !>([%tape %rover (fill-lookup:act vehicle-label.p.decoded definition-label.p.decoded)])
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
  ?:  =('/apps/rover/assets/fonts/BerkeleyMono-Regular.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-regular-octs) sat]
  ?:  =('/apps/rover/assets/fonts/BerkeleyMono-Bold.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-bold-octs) sat]
  ?:  =('/apps/rover/assets/fonts/BerkeleyMono-Oblique.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-oblique-octs) sat]
  ?:  =('/apps/rover/assets/fonts/BerkeleyMono-Bold-Oblique.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-bold-oblique-octs) sat]
  ?:  =('/apps/rover/view' url.request.req)
    =/  wir=wire  /rover-http/(scot %da now.bowl)/[eyre-id]
    =/  jon  !>([%tape %rover ui-view:act])
    =/  new-sat
      sat(pending (~(put by pending.sat) wir 'ui-view'), http-pending (~(put by http-pending.sat) wir eyre-id))
    :_  new-sat
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  [(http-give eyre-id 200 ['content-type' 'text/html']~ `shell-page) sat]
--
=|  state-13
=*  state  -
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  [[bind-eyre]~ this]
::
++  on-save  !>([%13 state])
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  s  !<(versioned-state old)
  =/  loaded=_this
    ?-  -.s
      %0  this(state [pending.+.s last.+.s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~])
      %1  this(state [pending.+.s last.+.s preview.+.s total.+.s ~ ~ ~ ~ ~ ~ ~ ~])
      %2  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s ~ ~ ~ ~ ~ ~ ~])
      %3  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s ~ ~ ~ ~ ~ ~])
      %4  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ ~ ~ ~])
      %5  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ ~ ~ ~])
      %6  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ charge-pending.+.s odometer-pending.+.s ~ ~])
      %7  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ charge-pending.+.s odometer-pending.+.s ~ ~])
      %8  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ charge-pending.+.s odometer-pending.+.s preference-pending.+.s ~])
      %9  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ charge-pending.+.s odometer-pending.+.s preference-pending.+.s ~])
      %10  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s])
      %11  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s])
      %12  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s])
      %13  this(state +.s)
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
        =/  jon  !>([%tape %rover schema-m0:act])
        :_  this(pending (~(put by pending) wir 'init-db'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %app-structure-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover app-structure-report:act])
        :_  this(pending (~(put by pending) wir 'app-structure-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %ensure-ui-schema
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover display-preference-schema:act])
        :_  this(pending (~(put by pending) wir 'ensure-ui-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %ensure-def-schema
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover def-schema:act])
        :_  this(pending (~(put by pending) wir 'ensure-def-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %display-preference-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover display-preference-report:act])
        :_  this(pending (~(put by pending) wir 'display-preference-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %charging-cost-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover charging-cost-report:act])
        :_  this(pending (~(put by pending) wir 'charging-cost-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %charging-evidence-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover charging-evidence-report:act])
        :_  this(pending (~(put by pending) wir 'charging-evidence-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %content-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover content-report:act])
        :_  this(pending (~(put by pending) wir 'content-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %consumption-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover consumption-report:act])
        :_  this(pending (~(put by pending) wir 'consumption-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %fuel-evidence-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover fuel-evidence-report:act])
        :_  this(pending (~(put by pending) wir 'fuel-evidence-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %location-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover location-report:act])
        :_  this(pending (~(put by pending) wir 'location-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %pricing-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover pricing-report:act])
        :_  this(pending (~(put by pending) wir 'pricing-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %run-integrity
        ?:  ?|  =(%zero-subtype scenario.a)
                =(%two-subtypes scenario.a)
            ==
          =/  check=result:rover
            ?:  =(%zero-subtype scenario.a)
              (validate-acquisition-subtypes:act %.n %.n)
            (validate-acquisition-subtypes:act %.y %.y)
          ?>  ?=(%err -.check)
          `this(integrity `[scenario.a %.y (integrity-message:act scenario.a)])
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=integrity-ids:act
          :*  (fixture-id:act base 91)
              (fixture-id:act base 92)
              (fixture-id:act base 93)
              (fixture-id:act base 94)
              (fixture-id:act base 95)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon
          !>([%tape %rover (integrity-script:act scenario.a ids now.bowl)])
        :_  this(pending (~(put by pending) wir (integrity-op:act scenario.a)))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-starters
        =/  wir=path  /rover-starter-check/(scot %da now.bowl)
        =/  jon  !>([%tape %rover starter-check:act])
        :_  this(pending (~(put by pending) wir 'seed-starters-check'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %rename-energy-source
        =/  wir=path  /rover-energy-rename/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (energy-definition-lookup:act old-label.a)])
        :_  this(pending (~(put by pending) wir new-label.a))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-fill-edit-support
        =/  wir=path  /rover-fill-edit-support/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (fill-edit-support-lookup:act vehicle-label.a)])
        :_  this(pending (~(put by pending) wir 'seed-fill-edit-support'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %fill-edit-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (fill-edit-report:act vehicle-label.a observed-start.a)])
        :_  this(pending (~(put by pending) wir 'fill-edit-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %station-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (station-report:act station-label.a)])
        :_  this(pending (~(put by pending) wir 'station-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %consumable-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon
          !>([%tape %rover (consumable-report:act vehicle-label.a consumable-label.a observed-start.a)])
        :_  this(pending (~(put by pending) wir 'consumable-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %charge-subtype-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon
          !>([%tape %rover (charge-subtype-report:act vehicle-label.a observed-start.a)])
        :_  this(pending (~(put by pending) wir 'charge-subtype-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %vehicle-settings-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (vehicle-settings-report:act vehicle-label.a)])
        :_  this(pending (~(put by pending) wir 'vehicle-settings-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %starter-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover starter-report:act])
        :_  this(pending (~(put by pending) wir 'starter-report'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-pricing
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=pricing-ids:act
          :*  (fixture-id:act base 21)
              (fixture-id:act base 22)
              (fixture-id:act base 23)
              (fixture-id:act base 24)
              (fixture-id:act base 25)
              (fixture-id:act base 26)
              (fixture-id:act base 27)
              (fixture-id:act base 28)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-pricing:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-pricing'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-fuel-evidence
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=fuel-evidence-ids:act
          :*  (fixture-id:act base 31)
              (fixture-id:act base 32)
              (fixture-id:act base 33)
              (fixture-id:act base 34)
              (fixture-id:act base 35)
              (fixture-id:act base 36)
              (fixture-id:act base 37)
              (fixture-id:act base 38)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-fuel-evidence:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-fuel-evidence'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-app-structure
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=app-structure-ids:act
          :*  (fixture-id:act base 201)
              (fixture-id:act base 202)
              (fixture-id:act base 203)
              (fixture-id:act base 204)
              (fixture-id:act base 205)
              (fixture-id:act base 206)
              (fixture-id:act base 207)
              (fixture-id:act base 208)
              (fixture-id:act base 209)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-app-structure:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-app-structure'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-charging-evidence
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=charging-evidence-ids:act
          :*  (fixture-id:act base 41)
              (fixture-id:act base 42)
              (fixture-id:act base 43)
              (fixture-id:act base 44)
              (fixture-id:act base 45)
              (fixture-id:act base 46)
              (fixture-id:act base 47)
              (fixture-id:act base 48)
              (fixture-id:act base 49)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-charging-evidence:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-charging-evidence'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-charging-cost
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=charging-cost-ids:act
          :*  (fixture-id:act base 51)
              (fixture-id:act base 52)
              (fixture-id:act base 53)
              (fixture-id:act base 54)
              (fixture-id:act base 55)
              (fixture-id:act base 56)
              (fixture-id:act base 57)
              (fixture-id:act base 58)
              (fixture-id:act base 59)
              (fixture-id:act base 60)
              (fixture-id:act base 61)
              (fixture-id:act base 62)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-charging-cost:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-charging-cost'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-consumption
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=consumption-ids:act
          :*  (fixture-id:act base 71)
              (fixture-id:act base 72)
              (fixture-id:act base 73)
              (fixture-id:act base 74)
              (fixture-id:act base 75)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-consumption:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-consumption'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-location
        =/  base=@ux  (cut 7 [0 1] eny.bowl)
        =/  ids=location-ids:act
          :*  (fixture-id:act base 81)
              (fixture-id:act base 82)
              (fixture-id:act base 83)
              (fixture-id:act base 84)
              (fixture-id:act base 85)
              (fixture-id:act base 86)
              (fixture-id:act base 87)
              (fixture-id:act base 88)
              (fixture-id:act base 89)
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-location:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-location'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-spike
        =/  seed  eny.bowl
        =/  base=@ux  (cut 7 [0 1] seed)
        =/  id-1=@ux  (mix base 1)
        =/  id-2=@ux  (mix base 2)
        =/  id-3=@ux  (mix base 3)
        =/  id-4=@ux  (mix base 4)
        =/  id-5=@ux  (mix base 5)
        =/  id-6=@ux  (mix base 6)
        =.  id-1  ?:  =(0 id-1)  `@ux`1  id-1
        =.  id-2  ?:  =(0 id-2)  `@ux`2  id-2
        =.  id-3  ?:  =(0 id-3)  `@ux`3  id-3
        =.  id-4  ?:  =(0 id-4)  `@ux`4  id-4
        =.  id-5  ?:  =(0 id-5)  `@ux`5  id-5
        =.  id-6  ?:  =(0 id-6)  `@ux`6  id-6
        =/  ids=seed-ids:act
          :*  id-1
              id-2
              id-3
              id-4
              id-5
              id-6
          ==
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (seed-spike:act ids now.bowl)])
        :_  this(pending (~(put by pending) wir 'seed-spike'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %try-second-app-default
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover (second-app-default:act now.bowl)])
        :_  this(pending (~(put by pending) wir 'try-second-app-default'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %verify-schema
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover verify-schema:act])
        :_  this(pending (~(put by pending) wir 'verify-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %vehicle-history
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover vehicle-history:act])
        :_  this(pending (~(put by pending) wir 'vehicle-history'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %current-odometer
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover current-odometer:act])
        :_  this(pending (~(put by pending) wir 'current-odometer'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %preview-us
        `this(preview `(preview-us:act entered-cents.a))
      %preview-eur
        `this(preview `(preview-eur:act entered-mills.a))
      %derive-fill-total
        `this(total `(derive-fill-total:act input.a))
      %derive-charging-total
        `this(charging-total `(derive-charging-total:act components.a))
    ==
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:def wire sign)
      [%rover-consumable-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?:  ?|  ?=(%.n -.res)
              ?=(~ eyre-id)
              ?=(~ body)
          ==
        `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
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
      =/  jon  !>([%tape %rover script])
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
      [%rover-consumable-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ body)
          ==
        `this
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
      [%rover-starter-check *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this(last `res)
      =/  definitions  (rows-at:view p.res 0)
      =/  consumables  (rows-at:view p.res 1)
      ?:  ?&  ?=(^ definitions)
              ?=(^ consumables)
          ==
        `this(last `res, pending (~(del by pending) wire))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover/starter-write/(scot %da now.bowl)
      =/  script=tape
        ?:  ?=(^ definitions)
          (seed-consumables:act base now.bowl)
        (seed-starters:act base now.bowl)
      =/  jon  !>([%tape %rover script])
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
      [%rover-energy-rename *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  new-label  (~(get by pending) wire)
      ?:  ?|  ?=(%.n -.res)
              ?=(~ new-label)
          ==
        `this(last `res)
      =/  definitions  (rows-at:view p.res 0)
      ?.  =(1 (lent definitions))
        `this(last `res)
      =/  write-wire=path  /rover/energy-rename/(scot %da now.bowl)
      =/  jon
        !>([%tape %rover (rename-energy-definition:act `@ux`(cell-atom:view %energy-definition-id (snag 0 definitions)) u.new-label)])
      =/  next-pending
        (~(put by (~(del by pending) wire)) write-wire 'rename-energy-source')
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ body)
          ==
        `this
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
        !>([%tape %rover (update-vehicle-settings:act `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles)) p.decoded subtype-id current-energy-ids resolved-energy-ids current-mode-ids resolved-mode-ids current-def def-consumable-id now.bowl)])
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
      [%rover-fill-edit-support *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this(last `res)
      =/  vehicles  (rows-at:view p.res 0)
      ?.  =(1 (lent vehicles))
        `this(last `res)
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=fill-edit-support-ids:act
        :*  (fixture-id:act base 921)
            (fixture-id:act base 922)
            (fixture-id:act base 923)
            (fixture-id:act base 924)
            (fixture-id:act base 925)
            (fixture-id:act base 926)
        ==
      =/  write-wire=path  /rover/fill-edit-support/(scot %da now.bowl)
      =/  jon
        !>([%tape %rover (seed-fill-edit-support:act ids `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles)) now.bowl)])
      =/  next-pending
        (~(put by (~(del by pending) wire)) write-wire 'seed-fill-edit-support-write')
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ body)
          ==
        `this
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
      =/  jon  !>([%tape %rover script])
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
      [%rover-edit-fill-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ body)
          ==
        `this
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
        !>([%tape %rover (update-fill:act `@ux`(cell-atom:view %acquisition-id (snag 0 rows)) `@ux`(cell-atom:view %vehicle-id (snag 0 rows)) `@ux`(cell-atom:view %energy-definition-id definition-row) (cell-term:view %quantity-unit definition-row) station-id p.additive-proof subtype-id mode-id p.tag-proof payment-id current-odometer-id (fixture-id:act base 901) p.decoded now.bowl)])
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ body)
          ==
        `this
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
      =/  jon  !>([%tape %rover script])
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
      =/  write-wire=path  /rover-remove-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        !>([%tape %rover (delete-vehicle:act `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles)))])
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
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%restricted: remove-vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Removed vehicle'))
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ body)
          ==
        `this
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
      =/  jon  !>([%tape %rover script])
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ label)
          ==
        `this
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
          ==
        `this
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
      =/  jon  !>([%tape %rover script])
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
          ==
        `this
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
          ==
        `this
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
      =/  jon  !>([%tape %rover script])
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
          ==
        `this
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
          ==
        `this
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
      =/  jon  !>([%tape %rover script])
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
          ==
        `this
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
      =/  message  (cat 3 'Saved charge - ' delivered-text)
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
      [%rover-fill-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by fill-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
              ?=(~ body)
          ==
        `this
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
      =/  jon  !>([%tape %rover script])
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
      ?:  ?|  ?=(~ eyre-id)
              ?=(~ input)
          ==
        `this
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
      [%rover-http *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        ~&  [%rover-ui-view-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(as-octs:mimes:html 'Unavailable - database query refused')
        ==
      :_  this
      %:  http-give
          u.eyre-id
          200
          ['content-type' 'text/html']~
          `(as-octs:mimes:html (page:view p.res))
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
      =/  op  (~(get by pending) wire)
      =/  scenario=(unit integrity-kind:rover)
        ?~  op  ~
        (integrity-scenario:act u.op)
      ?^  scenario
        ?:  ?=(%.n -.res)
          `this(last ~, integrity `[u.scenario %.y (integrity-message:act u.scenario)])
        `this(last ~, integrity `[u.scenario %.n 'unexpectedly accepted invalid mutation'])
      ?.  ?=(%.n -.res)
        =/  cooked
          ?~  op  res
          ?:  =('vehicle-history' u.op)
            [%.y (order-command-results:act %observed-start %.n p.res)]
          ?:  =('current-odometer' u.op)
            [%.y (latest-command-results:act p.res)]
          res
        `this(last `cooked)
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
  ?>  ?=([%eyre %connect ~] wire)
  ?>  ?=([%eyre %bound *] sign-arvo)
  ~?  !accepted.sign-arvo  [%rover %eyre-bind-refused]
  `this
++  on-fail   on-fail:def
--
