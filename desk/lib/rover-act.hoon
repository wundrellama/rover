::  lib/rover-act — synchronous Obelisk driver as a spider strand library.
::  Implements the pinned integration contract: watch /server on a unique wire,
::  poke %obelisk-action [%tape %rover urql], take one %noun fact, take the kick,
::  decode (each (list cmd-result:ast) tang).
::
::  urQL pokes are the ONLY application read path (predicates/joins server-side).
::  Scries are reserved for admin/diagnostics elsewhere.
/-  ast=obelisk-ast
|%
++  rover-db  %rover
::  +run-urql: run one urQL script against the %rover database, returning the
::  decoded command results. Caller is responsible for making mutation scripts
::  mutation-only (no query before the last mutation in a script).
++  run-urql
  |=  [wire=path urql=tape]
  =/  m  (strand ,vase)
  ^-  form:m
  ;<  our=@p  bind:m  get-our
  ;<  ~  bind:m  (watch wire [our %obelisk] /server)
  ;<  ~  bind:m  (poke [our %obelisk] %obelisk-action !>([%tape rover-db urql]))
  ;<  [mark=@tas =vase]  bind:m  (take-fact wire)
  ;<  ~  bind:m  (take-kick wire)
  (pure:m vase)
::
::  +run-urql-each: typed variant returning the each directly.
++  run-urql-each
  |=  [wire=path urql=tape]
  =/  m  (strand ,(each (list cmd-result:ast) tang))
  ^-  form:m
  ;<  =vase  bind:m  (run-urql wire urql)
  =/  res  !<((each (list cmd-result:ast) tang) vase)
  (pure:m res)
::
::  +vectors-of: flatten all %result-set rows out of a result list.
++  vectors-of
  |=  results=(list cmd-result:ast)
  ^-  (list vector:ast)
  %+  roll  results
  |=  [r=cmd-result:ast acc=(list vector:ast)]
  %+  weld  acc
  %+  roll  +.r
  |=  [x=result:ast a=(list vector:ast)]
  ?+  -.x  a
    %result-set  (weld a +.x)
  ==
::
::  +cell: get a typed atom from a result vector by column name.
++  cell
  |=  [name=@tas v=vector:ast]
  ^-  dime
  =/  cells  +.v
  |-
  ?~  cells  ~|([%missing-column name] !!)
  ?:  =(name p.i.cells)  q.i.cells
  $(cells t.cells)
::
++  cell-ud
  |=  [name=@tas v=vector:ast]
  ^-  @ud
  =/  d  (cell name v)
  ?>  =(%ud p.d)
  `@ud`q.d
::
++  cell-tas
  |=  [name=@tas v=vector:ast]
  ^-  @tas
  =/  d  (cell name v)
  ?>  =(%tas p.d)
  `@tas`q.d
::
++  cell-t
  |=  [name=@tas v=vector:ast]
  ^-  @t
  =/  d  (cell name v)
  ?>  =(%t p.d)
  `@t`q.d
::
++  cell-ux
  |=  [name=@tas v=vector:ast]
  ^-  @ux
  =/  d  (cell name v)
  ?>  =(%ux p.d)
  `@ux`q.d
::
++  cell-da
  |=  [name=@tas v=vector:ast]
  ^-  @da
  =/  d  (cell name v)
  ?>  =(%da p.d)
  `@da`q.d
--
