=/  m  (strand ,vase)
;<  =bowl:strand  bind:m  get-bowl
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-nuke !>([%rover %.y]))
;<  ~  bind:m  (sleep ~s3)
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-install !>([%rover our.bowl %rover]))
;<  ~  bind:m  (sleep ~s3)
;<  ~  bind:m  (poke [our.bowl %hood] %kiln-revive !>(%rover))
;<  ~  bind:m  (sleep ~s3)
(pure:m !>(%rover-reinstalled))
