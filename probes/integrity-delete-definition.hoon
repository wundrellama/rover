=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m
  (poke [our %rover] %rover-action !>([%run-integrity %delete-definition]))
;<  ~  bind:m  (sleep ~s2)
;<  now=@da  bind:m  get-time
=/  result
  .^(noun %gx /(scot %p our)/rover/(scot %da now)/integrity/noun)
(pure:m !>(result))
