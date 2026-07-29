=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
;<  res=(unit vase)  bind:m
  (build-file [our %obelisk da+now] /app/obelisk/hoon)
(pure:m !>(?=(^ res)))
