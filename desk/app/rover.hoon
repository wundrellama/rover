::  app/rover - lean tracer: accept %init-db, apply schema v1 to %obelisk.
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
      last=(unit @t)
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
++  on-save  !>(state)
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
    ?:  ?=(%init-db -.a)
      =/  wir=path  /rover/init-db
      =/  jon  !>([%tape %rover schema-v1:act])
      :_  this(pending (~(put by pending) wir 'init-db'))
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    (on-poke:def mark vase)
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:def wire sign)
      [%rover *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  !<((each (list cmd-result:ast) tang) q.cage.sign)
      =/  tag=@t
        ?:  ?=(%.y -.res)
          'schema-applied'
        'schema-failed'
      `this(last `tag)
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
