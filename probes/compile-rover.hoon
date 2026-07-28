=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
;<  res=(unit vase)  bind:m  (build-file [our %rover da+now] /app/rover/hoon)
(pure:m !>(?=(^ res)))
