=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  now=@da  bind:m  get-time
;<  res=(unit vase)  bind:m
  (build-file [our %rover da+now] /tests/lib/rover-enums/hoon)
?~  res  (pure:m !>(%build-failed))
=+  !<(scales=(list [@t (unit ?(%octane %cetane))]) (slap u.res limb+%rating-scales))
(pure:m !>(scales))
