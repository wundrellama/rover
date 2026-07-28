::  app/rover - lean Phase-A spike driver.
::  Owns identity/validation/projections; canonical state lives in %obelisk.
::  Drives Obelisk over /server wires: watch -> poke %obelisk-action [%tape
::  %rover urql] -> one %noun fact -> kick. Decode (each (list cmd-result)
::  tang). urQL pokes are the only application read path; no whole-table scry.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, default-agent, dbug
|%
+$  versioned-state
  $%  [%0 state-0]
  ==
::  pending: wire -> the urQL we sent (for diagnostics) and a tag.
+$  state-0
  $:  pending=(map wire @tas)
      last-result=(unit @t)
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
::  +on-poke: accept %rover-action. Local same-ship callers only in v1.
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?.  =(our.bowl src.bowl)
    ~|(%rover-denied !!)
  ?+  mark  (on-poke:def mark vase)
      %rover-action
    =/  a  !<(action:rover vase)
    ?:  ?=(%init-db -.a)
      ::  one mutation-only script: create db + eleven relations
      =/  wir=path  /rover/init-db
      :_  this(pending (~(put by pending) wir %init-db))
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action !>([%tape %rover schema-v1:act])]
      ==
    (on-poke:def mark vase)
  ==
::
::  +on-agent: receive the %noun fact, then the kick.
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:def wire sign)
      [%rover *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      ::  decode the result; store a human tag in last-result
      =/  res  !<((each (list cmd-result:ast) tang) q.cage.sign)
      =/  tag=@t
        ?-  -.res
          %.n  'schema-failed'
          %.y  (crip "schema-applied results={(a-co:co (lent p.res))}")
        ==
      `this(last-result `tag)
    ::
        %kick
      ::  subscription closed after the single fact; clean up pending
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ==
::
::  +on-peek: diagnostic scries only (not the application read path).
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
      [%x %last ~]        ``noun+!>(last-result)
  ==
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
