::
::::  /hoon/html/mar
  ::
/?    310
  ::
::::  compute
  ::
=,  html
|_  htm=@t
++  grow
  ^?
  |%
  ++  mime  [/text/html (met 3 htm) htm]
  ++  hymn  (need (de-xml htm))
  --
++  grab
  ^?
  |%
  ++  noun  @t
  ++  mime  |=([p=mite q=octs] q.q)
  --
++  grad  %mime
--
