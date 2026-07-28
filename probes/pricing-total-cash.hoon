=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m
  (poke [our %rover] %rover-action !>([%derive-fill-total 12.344 3.499 2 50 %cash]))
;<  now=@da  bind:m  get-time
=/  result
  .^(noun %gx /(scot %p our)/rover/(scot %da now)/total/noun)
(pure:m !>(result))
