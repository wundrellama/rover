=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m
  %-  poke
  :-  [our %rover]
  :*  %rover-action
      !>  :*  %derive-charging-total
              :~  [%energy 11.420]
                  [%time 3.000]
                  [%session 1.500]
                  [%idle 2.500]
                  [%tax 1.000]
                  [%discount 2.000]
              ==
          ==
  ==
;<  now=@da  bind:m  get-time
=/  result
  .^(noun %gx /(scot %p our)/rover/(scot %da now)/charging-total/noun)
(pure:m !>(result))
