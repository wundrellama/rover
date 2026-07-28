::  app/rover - lean tracer: accept %init-db, apply M0 schema to %obelisk.
::  One path, proven. Other actions land as separate proven increments.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, default-agent, dbug
|%
+$  versioned-state
  $%  [%0 state-0]
      [%1 state-1]
      [%2 state-2]
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
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-2
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  `this
::
++  on-save  !>([%2 state])
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  s  !<(versioned-state old)
  ?-  -.s
    %0  `this(state [pending.+.s last.+.s ~ ~ ~])
    %1  `this(state [pending.+.s last.+.s preview.+.s total.+.s ~])
    %2  `this(state +.s)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?>  =(our.bowl src.bowl)
  ?+  mark  (on-poke:def mark vase)
      %rover-action
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
      %fuel-evidence-report
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%tape %rover fuel-evidence-report:act])
        :_  this(pending (~(put by pending) wir 'fuel-evidence-report'))
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
      [%rover *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?.  ?=(%.n -.res)
        =/  op  (~(get by pending) wire)
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
  ==
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
