::  app/rover - lean tracer: accept %init-db, apply M0 schema to %obelisk.
::  One path, proven. Other actions land as separate proven increments.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, default-agent, dbug, view=rover-view
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
++  handle-http
  |=  [sat=state-4 =bowl:gall eyre-id=@ta req=inbound-request:eyre]
  ^-  [(list card) state-4]
  ?.  authenticated.req
    =/  loc  (cat 3 '/~/login?redirect=' url.request.req)
    [(http-give eyre-id 303 ['location' loc]~ ~) sat]
  ?>  =(our.bowl src.bowl)
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
=|  state-4
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
++  on-save  !>([%4 state])
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  s  !<(versioned-state old)
  =/  loaded=_this
    ?-  -.s
      %0  this(state [pending.+.s last.+.s ~ ~ ~ ~ ~])
      %1  this(state [pending.+.s last.+.s preview.+.s total.+.s ~ ~ ~])
      %2  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s ~ ~])
      %3  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s ~])
      %4  this(state +.s)
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
