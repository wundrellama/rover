::  app/rover - lean tracer: accept %init-db, apply M0 schema to %obelisk.
::  One path, proven. Other actions land as separate proven increments.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, default-agent, dbug
|%
+$  versioned-state
  $%  [%0 state-0]
  ==
+$  state-0
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
  ==
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-0
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
++  on-save  !>([%0 state])
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  s  !<(versioned-state old)
  ?-  -.s
    %0  `this(state +.s)
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
  ==
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
