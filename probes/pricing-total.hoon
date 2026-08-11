=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
;<  res=(unit vase)  bind:m
  (build-file [our %rover da+now] /lib/rover-act/hoon)
?~  res  (pure:m !>(%build-failed))
(pure:m (slap u.res (ream (crip "(derive-fill-total [12.345 3.499 2 50 %standard])"))))
