=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %rover] %rover-action !>([%content-report ~]))
;<  ~  bind:m  (sleep ~s3)
;<  now=@da  bind:m  get-time
=/  result
  (mule |.(.^(noun %gx /(scot %p our)/rover/(scot %da now)/last/noun)))
(pure:m !>(result))
