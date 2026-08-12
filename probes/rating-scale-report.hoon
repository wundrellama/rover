=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
;<  res=(unit vase)  bind:m
  (build-file [our %rover da+now] /lib/rover-act/hoon)
?~  res  (pure:m !>(%build-failed))
(pure:m (slap u.res (ream (crip "(turn ~['Gasoline' 'Ethanol' 'Propane' 'Diesel' 'Electricity' 'Hydrogen' 'CNG' 'LNG'] |=(l=@t [l (rating-scale-for l)]))"))))
