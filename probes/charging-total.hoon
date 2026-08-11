=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
;<  res=(unit vase)  bind:m
  (build-file [our %rover da+now] /lib/rover-act/hoon)
?~  res  (pure:m !>(%build-failed))
(pure:m (slap u.res (ream (crip "(derive-charging-total ~[[%energy 11.420] [%time 3.000] [%session 1.500] [%idle 2.500] [%tax 1.000] [%discount 2.000]])"))))
