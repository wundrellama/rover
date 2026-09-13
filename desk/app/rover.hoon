::  app/rover - lean tracer: accept %init-db, apply M0 schema to %obelisk.
::  One path, proven. Other actions land as separate proven increments.
::
/-  ast=obelisk-ast, rover
/+  act=rover-act, default-agent, dbug, entry=rover-entry, exp=rover-export, files=rover-files, imp=rover-import, render=rover-render, view=rover-view
/*  shell-html  %html  /app/rover/shell/html
/*  tile-png    %png   /app/rover/assets/tile/png
/*  font-regular       %woff2x  /app/rover/assets/fonts/jetbrainsmono-regular/woff2x
/*  font-bold          %woff2x  /app/rover/assets/fonts/jetbrainsmono-bold/woff2x
|%
+$  versioned-state
  $%  [%0 state-0]
      [%1 state-1]
      [%2 state-2]
      [%3 state-3]
      [%4 state-4]
      [%5 state-5]
      [%6 state-6]
      [%7 state-7]
      [%8 state-8]
      [%9 state-9]
      [%10 state-10]
      [%11 state-11]
      [%12 state-12]
      [%13 state-13]
      [%14 state-14]
      [%15 state-15]
      [%16 state-16]
      [%17 state-17]
      [%18 state-18]
      [%19 state-19]
      [%20 state-20]
      [%21 state-21]
      [%22 state-22]
      [%23 state-23]
      [%24 state-24]
  ==
+$  new-station-entry-10
  [place-label=@t station-label=@t station-kind=station-kind:rover]
+$  station-address-entry-13
  $:  formatted=@t
      line1=(unit @t)
      line2=(unit @t)
      locality=(unit @t)
      region=(unit @t)
      postal-code=(unit @t)
      country=(unit @t)
  ==
+$  new-station-entry-13
  $:  place-label=@t
      station-label=@t
      station-kind=station-kind:rover
      address=(unit station-address-entry-13)
      coordinates=(unit station-coordinate-entry:rover)
  ==
+$  fill-entry-13
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-13)
      additive-labels=(list @t)
      subtype-label=(unit @t)
      missed-fill=?
      driving-mode-label=(unit @t)
      average-speed=(unit scaled-entry:rover)
      drive-balance=(unit @ud)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
      notes=(unit @t)
      payment-method-label=(unit @t)
  ==
+$  fill-entry-5
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
  ==
+$  fill-entry-8
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-10)
      additive-labels=(list @t)
  ==
+$  fill-entry-10
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-10)
      additive-labels=(list @t)
      subtype-label=(unit @t)
      missed-fill=?
      driving-mode-label=(unit @t)
      average-speed=(unit scaled-entry:rover)
      drive-balance=(unit @ud)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
  ==
+$  state-0
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
  ==
+$  state-1
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
  ==
+$  state-2
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
  ==
+$  state-3
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
  ==
+$  state-4
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
  ==
+$  state-5
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
  ==
+$  state-6
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-5)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
  ==
+$  state-7
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
  ==
+$  state-8
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-8)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
  ==
+$  state-9
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
  ==
+$  state-10
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-10)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  state-11
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-11)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  fill-entry-11
  $:  vehicle-label=@t
      definition-label=@t
      quantity-milli=@ud
      unit-price-mills=@ud
      price-display=@t
      currency=currency:rover
      price-profile=price-profile:rover
      minor-unit-decimals=@ud
      cash-increment-mills=@ud
      tank-state=tank-state:rover
      settlement-mode=settlement-mode:rover
      observed-start=@da
      source-zone=@t
      mileage=(unit odo-reading:rover)
      station-label=(unit @t)
      new-station=(unit new-station-entry-10)
      additive-labels=(list @t)
      subtype-label=(unit @t)
      missed-fill=?
      driving-mode-label=(unit @t)
      average-speed=(unit scaled-entry:rover)
      drive-balance=(unit @ud)
      tag-labels=(list @t)
      new-tag-label=(unit @t)
      notes=(unit @t)
      payment-method-label=(unit @t)
  ==
+$  state-12
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry-12)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  charge-entry-12
  $:  vehicle-label=@t
      definition-label=@t
      observed-start=@da
      observed-end=@da
      source-zone=@t
      delivered=(unit delivered-energy:rover)
      start-battery=(unit battery-reading:rover)
      end-battery=(unit battery-reading:rover)
      mileage=(unit odo-reading:rover)
      cost-state=cost-state:rover
      currency=currency:rover
  ==
+$  state-13
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry-13)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  state-14
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
  ==
+$  charge-entry-15
  $:  vehicle-label=@t
      definition-label=@t
      observed-start=@da
      observed-end=@da
      source-zone=@t
      delivered=(unit delivered-energy:rover)
      start-battery=(unit battery-reading:rover)
      end-battery=(unit battery-reading:rover)
      mileage=(unit odo-reading:rover)
      cost-state=cost-state:rover
      currency=currency:rover
      subtype-label=(unit @t)
  ==
+$  state-15
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry-15)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
  ==
+$  state-16
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
  ==
+$  state-17
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
      bootstrap-ready=?
  ==
+$  state-18
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
      bootstrap-ready=?
  ==
+$  state-19
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
      bootstrap-ready=?
  ==
+$  state-20
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit import-run:rover)
      bootstrap-ready=?
  ==
::  M8. `attachment-pending` holds a photo in flight. The bytes wait in Gall
::  ONLY between the request and the moment Obelisk resolves the owning record,
::  and they are never written to agent state on disk with a record attached -
::  a completed attachment lives in Clay or in a bucket, per ruling 17.
+$  state-21
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit import-run:rover)
      bootstrap-ready=?
      attachment-pending=(map wire attachment-write-21)
  ==
::  The in-flight shape before the S3 backend landed. It knew nothing of the
::  resolved owner or the free file name, because Clay needed neither: the
::  commit and the reference insert went out in one turn.
+$  attachment-write-21
  $:  entry=attachment-entry:rover
      bytes=octs
      content-hash=@t
      attachment-id=@ux
  ==
::  M8. The S3 backend made the write a three-phase one, so what waits in
::  `attachment-pending` now carries the record the lookup resolved.
+$  state-22
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit import-run:rover)
      bootstrap-ready=?
      attachment-pending=(map wire attachment-write:rover)
  ==
::  M8. The export became a container, so it can no longer finish in one turn
::  when a photo lives in a bucket.
::
::  The import run in this version is read as a bare noun and dropped. An
::  import in flight cannot cross an upgrade: the connection it would answer
::  is already gone, which is the same reason `attachment-pending` is dropped.
+$  state-23
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit *)
      bootstrap-ready=?
      attachment-pending=(map wire attachment-write:rover)
      export-run=(unit export-run:rover)
  ==
::  M8. The import takes the archive back, so a run now carries the photos it
::  has not attached yet.
+$  state-24
  $:  pending=(map wire @t)
      last=(unit (each (list cmd-result:ast) tang))
      preview=(unit price-preview:rover)
      total=(unit total-proof:rover)
      charging-total=(unit charging-total-proof:rover)
      integrity=(unit integrity-proof:rover)
      http-pending=(map wire @ta)
      fill-pending=(map wire fill-entry:rover)
      charge-pending=(map wire charge-entry:rover)
      odometer-pending=(map wire odometer-entry:rover)
      preference-pending=(map wire preference-entry:rover)
      fill-body-pending=(map wire @t)
      import-run=(unit import-run:rover)
      bootstrap-ready=?
      attachment-pending=(map wire attachment-write:rover)
      export-run=(unit export-run:rover)
  ==
+$  card  card:agent:gall
--
=>  |%
++  bind-eyre
  ^-  card
  [%pass /eyre/connect %arvo %e %connect [~ /apps/rover] %rover]
::
++  http-give
  |=  [eyre-id=@ta status=@ud hed=header-list:http bod=(unit octs)]
  ^-  (list card)
  =/  pax=path  /http-response/[eyre-id]
  :~  :*  %give  %fact  ~[pax]  %http-response-header
          !>(`response-header:http`[status hed])
      ==
      [%give %fact ~[pax] %http-response-data !>(bod)]
      [%give %kick ~[pax] ~]
  ==
::
++  restart-http
  |=  eyre-id=@ta
  ^-  (list card)
  %:  http-give
      eyre-id
      503
      ['content-type' 'text/plain']~
      `(text-octs 'Rover restarted while saving. Please submit again.')
  ==
::
++  shell-page
  ^-  octs
  (as-octs:mimes:html shell-html)
::
++  tile-octs
  ^-  octs
  (as-octs:mimes:html tile-png)
::
++  font-regular-octs
  ^-  octs
  font-regular
::
++  font-bold-octs
  ^-  octs
  font-bold
::
++  text-octs
  |=  text=@t
  ^-  octs
  (as-octs:mimes:html text)
::
::  M8. An attachment request names its record in the query string and carries
::  the photo as the raw request body. Base64 in a JSON field would inflate the
::  owner's 48.5 MB corpus by a third for nothing, and Eyre hands the raw bytes
::  over already.
++  url-base
  |=  url=@t
  ^-  @t
  =/  text  (trip url)
  =/  mark  (find "?" text)
  ?~  mark  url
  (crip (scag u.mark text))
::
++  url-params
  |=  url=@t
  ^-  (map @t @t)
  =/  text  (trip url)
  =/  mark  (find "?" text)
  ?~  mark  ~
  %-  ~(gas by *(map @t @t))
  %+  murn  (split-on '&' (slag +(u.mark) text))
  |=  pair=tape
  ^-  (unit [@t @t])
  =/  split  (find "=" pair)
  ?~  split  ~
  `[(percent-decode (scag u.split pair)) (percent-decode (slag +(u.split) pair))]
::
::  Percent-decoding that survives the owner's own data.
::
::  `de-urlt` answers nothing at all for a value carrying a byte above 127, so
::  one curly apostrophe in a vehicle label made the whole parameter vanish and
::  the request read as a missing key. The owner's corpus has exactly that, and
::  a photo is addressed by the vehicle label, so it refused most of the load.
::
::  A query string also writes a space as `+`, which `de-urlt` leaves standing.
++  percent-decode
  |=  text=tape
  ^-  @t
  =/  out=tape  ~
  |-  ^-  @t
  ?~  text
    (crip (flop out))
  ?:  =('+' i.text)
    $(text t.text, out [' ' out])
  ?.  =('%' i.text)
    $(text t.text, out [i.text out])
  ?.  ?=([@ @ *] t.text)
    $(text t.text, out ['%' out])
  =/  high  (hex-value i.t.text)
  =/  low  (hex-value i.t.t.text)
  ?:  ?|(?=(~ high) ?=(~ low))
    $(text t.text, out ['%' out])
  $(text t.t.t.text, out [`@tD`(add (mul 16 u.high) u.low) out])
::
++  hex-value
  |=  digit=@tD
  ^-  (unit @ud)
  ?:  ?&((gte digit '0') (lte digit '9'))  `(sub digit '0')
  ?:  ?&((gte digit 'a') (lte digit 'f'))  `(add 10 (sub digit 'a'))
  ?:  ?&((gte digit 'A') (lte digit 'F'))  `(add 10 (sub digit 'A'))
  ~
::
++  split-on
  |=  [delimiter=@tD text=tape]
  ^-  (list tape)
  =/  mark  (find ~[delimiter] text)
  ?~  mark  ~[text]
  [(scag u.mark text) $(text (slag +(u.mark) text))]
::
::  The tail of a URL path, percent-decoded. This is how a browser asks for one
::  attachment: by its file name, which is the only handle on an attachment that
::  crosses this boundary.
++  url-tail
  |=  [url=@t prefix=@t]
  ^-  (unit @t)
  =/  text  (trip (url-base url))
  =/  head  (trip prefix)
  ?.  =(head (scag (lent head) text))
    ~
  =/  rest  (percent-decode (slag (lent head) text))
  ?:  =('' rest)  ~
  `rest
::
++  url-prefix
  |=  [url=@t prefix=@t]
  ^-  ?
  =/  text  (trip (url-base url))
  =/  head  (trip prefix)
  =(head (scag (lent head) text))
::
::  M8. Landscape's %storage agent holds the owner's S3 credentials. Rover
::  reads them rather than asking a second time, exactly as %boox does.
::
::  The owner ruled on 2026-08-30 that Rover reads %storage through the /json
::  scry and looks values up BY KEY. It does not copy the /-storage mold and it
::  does not read the noun by position.
::
::  A positional read fails silently. `current-bucket` and `region` sit side by
::  side in Landscape's configuration and both are @t, so a reordering upstream
::  keeps the arity and the atom-versus-cell shape a `?=` guard tests. Rover
::  would then sign every request against a bucket named `us-east-1`, and the
::  server answers 403 - which reads as a bad credential and is not one.
::
::  %boox walks the same object by key. The keys, measured on a real pier with
::  RustFS configured:
::    credentials:   endpoint, accessKeyId, secretAccessKey
::    configuration: buckets, currentBucket, region, presignedUrl, service,
::                   publicUrlBase
::  Each scry wraps its object in the mark's own `storage-update` envelope.
::
::  A renamed key reads as an empty value, and the empty-value guard below then
::  answers "no S3 configured", which surfaces the human message the attach
::  path already writes. That is wrong-ish but loud, and it beats signing
::  against the wrong bucket in silence.
++  json-value
  |=  [jon=json key=@t]
  ^-  json
  ?.  ?=([%o *] jon)  ~
  =/  hit  (~(get by p.jon) key)
  ?~  hit  ~
  u.hit
::
::  Walk an object by key and read the string at the end of the walk. A key
::  that is absent, or a value that is not a string, answers ''.
++  json-text
  |=  [jon=json trail=(list @t)]
  ^-  @t
  =/  here=json  jon
  |-
  ?~  trail
    ?.  ?=([%s *] here)  ''
    p.here
  $(here (json-value here i.trail), trail t.trail)
::
++  storage-configuration
  |=  [our=@p now=@da]
  ^-  (unit s3-config:rover)
  ::  The liveness scry needs the trailing `/$`: gall routes a bare agent path
  ::  to the agent itself and blocks, and a blocked scry is not catchable.
  ?.  .^(? %gu /(scot %p our)/storage/(scot %da now)/$)
    ~
  =/  config=json  .^(json %gx /(scot %p our)/storage/(scot %da now)/configuration/json)
  =/  credentials=json  .^(json %gx /(scot %p our)/storage/(scot %da now)/credentials/json)
  =/  bucket=@t    (json-text config ~['storage-update' 'configuration' 'currentBucket'])
  =/  region=@t    (json-text config ~['storage-update' 'configuration' 'region'])
  =/  endpoint=@t  (json-text credentials ~['storage-update' 'credentials' 'endpoint'])
  =/  key-id=@t    (json-text credentials ~['storage-update' 'credentials' 'accessKeyId'])
  =/  secret=@t    (json-text credentials ~['storage-update' 'credentials' 'secretAccessKey'])
  ?:  ?|  =('' bucket)
          =('' endpoint)
          =('' key-id)
          =('' secret)
      ==
    ~
  `[endpoint region bucket key-id secret]
::
++  s3-configured
  |=  [our=@p now=@da]
  ^-  ?
  ?=(^ (storage-configuration our now))
::
::  The refusal a ship with no bucket gives. Human words, and it names the
::  backend that IS available rather than leaving the owner stuck.
++  storage-unconfigured
  ^-  @t
  %^    cat
    3
  'This ship has no S3 storage set up yet. '
  'Open the Landscape storage settings to point it at a bucket, or store this photo on the ship itself by choosing Clay.'
::
::  A bucket refusal, in words. The status is named because it is the only
::  thing that tells the owner whether the credentials are wrong, the bucket is
::  missing, or the server is down - but no raw error body is echoed back.
++  s3-refusal
  |=  status=@ud
  ^-  @t
  ?:  =(403 status)
    'The S3 storage refused Rover\'s credentials. Check the keys in the Landscape storage settings.'
  ?:  =(404 status)
    'The S3 storage has no such bucket or object. Check the bucket name in the Landscape storage settings.'
  ?:  =(0 status)
    'Rover could not reach the S3 storage at all. Check that the endpoint is running and reachable from this ship.'
  %-  crip
  ;:  weld
    "The S3 storage returned HTTP "  (scow %ud status)
    ". The photo was not stored."
  ==
::
::  M8, second leg, ruling 23. A new surface ships a JSON route, and the HTML
::  renderer is one client of it. These arms are what those routes answer with,
::  so a refusal has the same shape a client already parses for a success.
++  json-give
  |=  [eyre-id=@ta status=@ud payload=json]
  ^-  (list card)
  %:  http-give
      eyre-id
      status
      ['content-type' 'application/json; charset=utf-8']~
      `(text-octs (en:json:html payload))
  ==
::
++  json-message
  |=  text=@t
  ^-  json
  (pairs:enjs:format ['message' s+text]~)
::
::  Why the S3 choice is missing, in the same human words on every surface that
::  offers it. Ruling 8, and the standing rule that a ship never picks a
::  backend for the owner: the reason has to be readable, not a flag.
::  The import asks once, for the whole batch. A default that is expensive to
::  undo is a decision made for the owner: getting a photograph back out of
::  Clay needs a tombstone, a desk commit that drops the file, and a log
::  truncation, and doing that 121 times is not a remedy.
++  import-backend-unchosen
  ^-  @t
  %^    cat
    3
  'This archive carries photographs. Choose where to keep them - on this ship, or in your S3 storage. '
  'Rover does not choose for you, because moving them afterwards is slow.'
::
++  s3-unavailable
  ^-  @t
  %^    cat
    3
  'This ship has no S3 storage set up yet. '
  'Open the Landscape storage settings to point it at a bucket. Until then Rover stores photos on the ship itself.'
::
::  Which backends this ship can really offer. The entry surface and the import
::  screen both read this one route, so the two can never disagree about what
::  is available or about why.
++  backends-json
  |=  [our=@p now=@da]
  ^-  json
  =/  ready  (s3-configured our now)
  %-  pairs:enjs:format
  :~  :-  'backends'
      :-  %a
      :~  %-  pairs:enjs:format
          :~  ['name' s+'clay']
              ['label' s+'On this ship']
              ['available' b+%.y]
              ['reason' s+'Clay is the ship\'s own filesystem. The photo travels with the pier and its backups.']
          ==
          %-  pairs:enjs:format
          :~  ['name' s+'s3']
              ['label' s+'In your S3 storage']
              ['available' b+ready]
              :-  'reason'
              ?:  ready
                s+'S3 photos must be publicly readable. Anyone with a photo URL can read it, and a leaked URL cannot be revoked. Choose Clay for private photos.'
              s+s3-unavailable
          ==
      ==
  ==
::
::  One photo, addressed the way the card that carries it is addressed: the
::  record family and the moment the record holds. A vehicle photo hangs off no
::  moment, so it carries none.
::
::  Ruling 8: the file name is the whole handle. No attachment id and no record
::  id crosses this boundary in either direction.
++  photo-json
  |=  [owner=@tas timed=? endpoint=@t rows=(list vector:ast)]
  ^-  (list json)
  %+  turn  rows
  |=  row=vector:ast
  =/  name  (cell-text:view %file-name row)
  %-  pairs:enjs:format
  :~  ['owner' s+(scot %tas owner)]
      :-  'observed'
      ?.  timed  s+''
      s+(crip (input-da:view `@da`(cell-atom:view %observed-start row)))
      ['name' s+name]
      ['mediaType' s+(cell-text:view %media-type row)]
      ::  A plain integer. `scot %ud` groups with dots past four figures, and
      ::  a byte count that reads 16.422 is not a number any reader parses.
      ['bytes' n+(format-scaled:render (cell-atom:view %byte-count row) 0 %.n)]
      :-  'url'
      ?:  =(%s3 (cell-term:view %backend row))
        s+(s3-url:files endpoint (cell-text:view %locator row))
      s+(crip (weld "/apps/rover/attachment/" (en-urlt:html (trip name))))
  ==
::
++  attachment-index-json
  |=  [label=@t endpoint=@t commands=(list cmd-result:ast)]
  ^-  json
  %-  pairs:enjs:format
  :~  ['vehicle' s+label]
      :-  'photos'
      :-  %a
      ;:  weld
        (photo-json %energy %.y endpoint (rows:exp commands 0))
        (photo-json %event %.y endpoint (rows:exp commands 1))
        (photo-json %vehicle %.n endpoint (rows:exp commands 2))
      ==
  ==
::
::  M8. The export container. Every reference the database holds, in the order
::  the engine returned them - order is not asserted anywhere, because the
::  engine returns sets and their order is not stable across piers.
++  export-refs
  |=  commands=(list cmd-result:ast)
  ^-  (list attachment-ref:rover)
  %+  turn  (attachment-rows:exp commands)
  |=  row=vector:ast
  ^-  attachment-ref:rover
  :*  `@ux`(cell-atom:view %attachment-id row)
      ?:(=(%s3 (cell-term:view %backend row)) %s3 %clay)
      (cell-text:view %locator row)
      (cell-text:view %content-hash row)
      (cell-atom:view %byte-count row)
      (cell-text:view %media-type row)
      (cell-text:view %file-name row)
  ==
::
++  tar-response
  |=  [eyre-id=@ta payload=@t members=(list [name=@t bytes=octs])]
  ^-  (list card)
  =/  all
    :-  ['rover-import.json' (as-octs:mimes:html payload)]
    %+  turn  (flop members)
    |=  [name=@t bytes=octs]
    [(tar-name:files name) bytes]
  %:  http-give
      eyre-id
      200
      :~  ['content-type' 'application/x-tar']
          ['content-disposition' 'attachment; filename="rover-export-complete.tar"']
      ==
      `(tar-archive:files all)
  ==
::
++  attachment-owner-column
  |=  owner=attachment-owner:rover
  ^-  @tas
  ?-  owner
    %vehicle  %vehicle-id
    %energy   %acquisition-id
    %event    %event-id
  ==
::
++  attachment-not-found
  |=  owner=attachment-owner:rover
  ^-  @t
  ?-  owner
    %vehicle  'No vehicle by that name.'
    %energy   'No fill or charge on that vehicle at that moment.'
    %event    'No record on that vehicle at that moment.'
  ==
::
++  database-present
  |=  commands=(list cmd-result:ast)
  ^-  ?
  =/  rows  (rows-at:view commands 0)
  ?=(^ (row-by-text:view %database 'rover' rows))
::
++  obelisk-script-cards
  |=  [our=@p wir=wire script=tape]
  ^-  (list card)
  =/  jon  !>([%script %rover %vector script])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  row-member
  |=  [needle=vector:ast rows=(list vector:ast)]
  ^-  ?
  ?~  rows
    %.n
  ?:  =(needle i.rows)
    %.y
  $(rows t.rows)
::
::  Compare as sets, not as returned list order. Both projections include the
::  acquisition primary key, so Obelisk's identical-row collapse cannot make
::  this count under-report the table.
++  migration-rows-match
  |=  [source=(list vector:ast) destination=(list vector:ast)]
  ^-  ?
  ?&  =((lent source) (lent destination))
      %+  levy  source
      |=  row=vector:ast
      (row-member row destination)
  ==
::
++  energy-odometer-values
  |=  rows=(list vector:ast)
  ^-  tape
  ?~  rows
    ~
  =/  acquisition  (cell-atom:view %acquisition-id i.rows)
  =/  odometer  (cell-atom:view %odometer-id i.rows)
  ;:  weld
    "("
    (scow %ux acquisition)
    ", "
    (scow %ux odometer)
    ")"
    ?~(t.rows ";" (weld " " (energy-odometer-values t.rows)))
  ==
::
++  energy-odometer-copy-script
  |=  rows=(list vector:ast)
  ^-  tape
  ?>  ?=(^ rows)
  ;:  weld
    "INSERT INTO energy-acquisition-odometers VALUES "
    (energy-odometer-values rows)
  ==
::
++  starter-seed-script
  |=  [commands=(list cmd-result:ast) base=@ux now=@da]
  ^-  tape
  =/  definitions  (rows-at:view commands 0)
  =/  consumables  (rows-at:view commands 1)
  =/  additives  (rows-at:view commands 2)
  =/  driving-modes  (rows-at:view commands 3)
  =/  service-subtypes  (rows-at:view commands 4)
  =/  disposal-kinds  (rows-at:view commands 5)
  %:  seed-missing-starters:act
      base
      now
      ?=(~ definitions)
      ?=(~ consumables)
      ?=(~ additives)
      ?=(~ driving-modes)
      ?=(~ service-subtypes)
      ?=(~ disposal-kinds)
  ==
::
++  entry-refusal
  |=  verdict=entry-verdict:rover
  ^-  @t
  (cat 3 '%' (cat 3 (scot %tas class.verdict) (cat 3 ': ' field.verdict)))
::
++  import-lookup-cards
  |=  [our=@p run=import-run:rover]
  ^-  (list card)
  ?~  remaining.run
    ~
  =/  wir=wire  /rover-import-lookup/(scot %ud serial.run)
  =/  jon  !>([%script %rover %vector (work-lookup:imp i.remaining.run)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-write-cards
  |=  [our=@p serial=@ud script=tape]
  ^-  (list card)
  =/  wir=wire  /rover-import-write/script/(scot %ud serial)
  =/  jon  !>([%script %rover %vector script])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-parse-cards
  |=  [our=@p serial=@ud script=tape]
  ^-  (list card)
  =/  wir=wire  /rover-import-write/parse/(scot %ud serial)
  =/  jon  !>([%parse %rover script])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-command-write-cards
  |=  [our=@p serial=@ud commands=(list command:ast)]
  ^-  (list card)
  =/  wir=wire  /rover-import-write/cmd-list/(scot %ud serial)
  =/  jon  !>([%cmd-list %vector commands])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-support-cards
  |=  [our=@p serial=@ud fill=import-fill:rover]
  ^-  (list card)
  =/  wir=wire  /rover-import-support/(scot %ud serial)
  =/  jon  !>([%script %rover %vector (fill-support-lookup:imp fill)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-comparison-cards
  |=  [our=@p serial=@ud fill=import-fill:rover acquisition-id=@ux]
  ^-  (list card)
  =/  wir=wire  /rover-import-comparison/(scot %ux acquisition-id)/(scot %ud serial)
  =/  jon  !>([%script %rover %vector (fill-comparison-lookup:imp fill acquisition-id)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-comparison-tail-cards
  |=  [our=@p serial=@ud fill=import-fill:rover acquisition-id=@ux]
  ^-  (list card)
  =/  wir=wire  /rover-import-comparison-tail/(scot %ux acquisition-id)/(scot %ud serial)
  =/  jon  !>([%script %rover %vector (fill-comparison-tail-lookup:imp fill acquisition-id)])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
::  M8. Walk the reference list, gathering bytes. A Clay reference is read on
::  the spot and the walk continues in the same turn; an S3 one stops the walk
::  and waits for the bucket. When the list is empty the tar goes out.
::
::  A reference whose backend no longer holds the bytes stops the export rather
::  than quietly shipping a short archive. Silence is the failure mode.
++  continue-export
  |=  [sat=state-24 our=@p now=@da run=export-run:rover]
  ^-  [(list card) state-24]
  ?~  remaining.run
    [(tar-response eyre-id.run payload.run members.run) sat(export-run ~)]
  =/  ref  i.remaining.run
  ?:  =(%clay backend.ref)
    =/  bytes  (clay-read:files our now locator.ref)
    ?~  bytes
      :_  sat(export-run ~)
      %:  http-give
          eyre-id.run
          500
          ['content-type' 'text/plain']~
          `(text-octs (cat 3 'The export stopped: this ship no longer holds the bytes for ' file-name.ref))
      ==
    %=  $
      run  run(remaining t.remaining.run, members [[file-name.ref u.bytes] members.run])
    ==
  =/  config  (storage-configuration our now)
  ?~  config
    :_  sat(export-run ~)
    %:  http-give
        eyre-id.run
        409
        ['content-type' 'text/plain']~
        `(text-octs 'The export stopped: some photos are in S3 storage and this ship has no bucket configured to read them from.')
    ==
  =/  wir=wire  /rover-export-fetch/(scot %da now)/[eyre-id.run]
  =/  outbound
    (s3-request:files u.config 'GET' locator.ref media-type.ref ~ now)
  :_  sat(export-run `run)
  [%pass wir %arvo %i %request outbound *outbound-config:iris]~
::
::  M8. Match every photo the document names to the member that carries it.
::
::  A name the archive does not hold is a fault, not a silent omission. The
::  import says so and finishes the rest, because half an archive that reports
::  itself is worth more than a refusal that explains nothing.
++  archive-photos
  |=  $:  members=(list [name=@t bytes=octs])
          wanted=(list attachment-entry:rover)
      ==
  ^-  [photos=(list import-photo:rover) missing=@ud messages=(list @t)]
  =/  out=(list import-photo:rover)  ~
  =/  missing=@ud  0
  =/  messages=(list @t)  ~
  |-
  ?~  wanted
    [(flop out) missing (flop messages)]
  =/  found
    %+  member-named:files
      (cat 3 'attachments/' file-name.i.wanted)
    members
  ?~  found
    %=  $
      wanted    t.wanted
      missing   +(missing)
      messages  [(cat 3 'The archive names a photo it does not carry: ' file-name.i.wanted) messages]
    ==
  $(wanted t.wanted, out [[i.wanted u.found] out])
::
::  M8. Ask which record on THIS ship owns the next photo, and what it already
::  holds. The answer decides between storing the bytes, linking bytes the
::  ship already has, and doing nothing at all.
++  import-photo-cards
  |=  [our=@p run=import-run:rover]
  ^-  (list card)
  ?~  photos.run
    ~
  =/  entry  entry.i.photos.run
  =/  wir=wire  /rover-import-photo-lookup/(scot %ud serial.run)
  =/  jon
    !>  :*  %script  %rover  %vector
            %:  attachment-owner-lookup:act
                owner.entry
                vehicle-label.entry
                observed.entry
            ==
        ==
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  import-photo-write-cards
  |=  [our=@p serial=@ud script=tape]
  ^-  (list card)
  =/  wir=wire  /rover-import-photo-write/(scot %ud serial)
  =/  jon  !>([%script %rover %vector script])
  :~  [%pass wir %agent [our %obelisk] %watch /server]
      [%pass wir %agent [our %obelisk] %poke %obelisk-action jon]
  ==
::
++  continue-import
  |=  [sat=state-24 our=@p run=import-run:rover]
  ^-  [(list card) state-24]
  ?^  remaining.run
    [(import-lookup-cards our run) sat(import-run `run)]
  ::  M8. The records exist now, so the photos have something to hang off.
  ::  This phase cannot run earlier: a photo is addressed by the record it
  ::  belongs to, and until the document phase ends that record is not there.
  ?^  photos.run
    [(import-photo-cards our run) sat(import-run `run)]
  :_  sat(import-run ~)
  %:  http-give
      eyre-id.run
      200
      ['content-type' 'text/plain']~
      `(text-octs (report-text:imp report.run))
  ==
::
++  import-detail
  |=  [prefix=@t work=import-work:rover detail=@t]
  ^-  @t
  %-  crip
  ;:  weld
    (trip prefix)
    ": "
    (trip (work-name:imp work))
    ?:  =(0 detail)
      ""
    ;:  weld
      " - "
      (trip detail)
    ==
  ==
::
++  attachment-match
  |=  $:  entry=attachment-entry:rover
          content-hash=@t
          by-name=?
          rows=(list vector:ast)
      ==
  ^-  (unit vector:ast)
  |-
  ?~  rows  ~
  =/  parts  (split-on '/' (trip (cell-text:view %locator i.rows)))
  =/  content-addressed
    ?&  =(4 (lent parts))
        =("" (snag 0 parts))
        !=("" (snag 1 parts))
        =("attachments" (snag 2 parts))
        =((trip content-hash) (snag 3 parts))
    ==
  ?:  ?&  =(%s3 backend.entry)  !content-addressed  ==
    $(rows t.rows)
  ?:  ?&  =(content-hash (cell-text:view %content-hash i.rows))
          =(backend.entry (cell-term:view %backend i.rows))
          ?|  !by-name
              =(file-name.entry (cell-text:view %file-name i.rows))
          ==
      ==
    `i.rows
  $(rows t.rows)
::
++  handle-http
  |=  [sat=state-24 =bowl:gall eyre-id=@ta req=inbound-request:eyre]
  ^-  [(list card) state-24]
  ?.  authenticated.req
    =/  loc  (cat 3 '/~/login?redirect=' url.request.req)
    [(http-give eyre-id 303 ['location' loc]~ ~) sat]
  ?>  =(our.bowl src.bowl)
  ?:  =(%'POST' method.request.req)
    ?:  =('/apps/rover/view' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: page')) sat]
      =/  request-text=@t  `@t`q.u.body.request.req
      =/  request-object  (json-object:entry request-text)
      =/  page-value=(unit @t)
        ?~  request-object
          `request-text
        (json-string:entry 'page' u.request-object)
      ?~  page-value
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: page')) sat]
      =/  page-text=@t  u.page-value
      =/  parsed  (slaw %ud page-text)
      ?:  ?|  ?=(~ parsed)
              (gth u.parsed 1.000.000)
          ==
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: page')) sat]
      =/  wir=wire
        ?:  bootstrap-ready.sat
          /rover-http/recover/(scot %da now.bowl)/[eyre-id]
        /rover-bootstrap-probe/(scot %da now.bowl)/[eyre-id]
      =/  jon
        ?:  bootstrap-ready.sat
          =/  selected-label=(unit @t)
            ?~  request-object
              ~
            (json-string:entry 'vehicle' u.request-object)
          !>([%script %rover %vector (ui-view:act selected-label)])
        !>([%script %sys %vector database-list:act])
      =/  new-sat
        sat(pending (~(put by pending.sat) wir request-text), http-pending (~(put by http-pending.sat) wir eyre-id))
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  The browser sends metadata here. The bytes go directly to the bucket.
    ?:  ?|  =('/apps/rover/attachment-url' (url-base url.request.req))
            =('/apps/rover/record-attachment' (url-base url.request.req))
        ==
      ?.  bootstrap-ready.sat
        [(json-give eyre-id 503 (json-message 'Rover is still loading. Try the attachment again.')) sat]
      ?:  ?&(?=(^ body.request.req) (gth p.u.body.request.req 0))
        [(json-give eyre-id 400 (json-message 'Send photo metadata without a request body.')) sat]
      =/  decoded  (decode-attachment-metadata:entry (url-params url.request.req))
      ?:  ?=(%| -.decoded)
        [(json-give eyre-id 400 (json-message (entry-refusal p.decoded))) sat]
      ?.  (s3-configured our.bowl now.bowl)
        [(json-give eyre-id 409 (json-message storage-unconfigured)) sat]
      =/  meta  p.decoded
      =/  wir=wire  /rover-attachment-metadata/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>  :*  %script  %rover  %vector
                %:  attachment-owner-lookup:act
                    owner.entry.meta
                    vehicle-label.entry.meta
                    observed.entry.meta
                ==
            ==
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          pending       (~(put by pending.sat) wir url.request.req)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M8. A photo attaches to a record. The query string names the record
    ::  and the file; the BODY is the photo, raw, exactly as it arrived.
    ::
    ::  Ruling 17: the bytes never enter Obelisk. The database gets a reference
    ::  row and a link row, and the image goes to Clay or to an S3 bucket.
    ?:  (url-prefix url.request.req '/apps/rover/add-attachment')
      ?.  bootstrap-ready.sat
        [(http-give eyre-id 503 ['content-type' 'text/plain']~ `(text-octs 'Rover is still loading. Try the attachment again.')) sat]
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: attachment')) sat]
      =/  decoded  (decode-attachment:entry (url-params url.request.req))
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  bytes=octs  u.body.request.req
      ?:  =(0 p.bytes)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: attachment.bytes')) sat]
      ::  A ship with no %storage configuration says so in words and offers
      ::  Clay. It never picks a backend for the owner and never fails raw.
      =/  s3-ready  (s3-configured our.bowl now.bowl)
      ?:  ?&  =(%s3 backend.p.decoded)
              !s3-ready
          ==
        :_  sat
        %:  http-give
            eyre-id
            409
            ['content-type' 'text/plain']~
            `(text-octs storage-unconfigured)
        ==
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  attachment-id=@ux  (fixture-id:act base 9.201)
      =/  write=attachment-write:rover
        [p.decoded bytes (hash-octs:files bytes) attachment-id 0x0 '']
      =/  wir=wire  /rover-attachment-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>  :*  %script  %rover  %vector
                %:  attachment-owner-lookup:act
                    owner.p.decoded
                    vehicle-label.p.decoded
                    observed.p.decoded
                ==
            ==
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          attachment-pending  (~(put by attachment-pending.sat) wir write)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
    ::  M8, second leg. The import asks WHICH BACKEND, once, for the whole
    ::  batch. The choice rides in the query string, so the import document
    ::  keeps the shape ruling 19 gives it: the export format is the import
    ::  format, and neither ship writes a storage choice into it.
    ?:  =('/apps/rover/import' (url-base url.request.req))
      ?^  import-run.sat
        [(http-give eyre-id 409 ['content-type' 'text/plain']~ `(text-octs 'An import is already running')) sat]
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: import')) sat]
      ::  M8, ruling 19. The export format is the import format, and the
      ::  complete export is an archive. A body that carries a ustar header is
      ::  unpacked here; anything else is the document by itself, which is
      ::  what every importer before M8 sent and still sends.
      =/  archive=?  (tar-body:files u.body.request.req)
      =/  members=(list [name=@t bytes=octs])
        ?.  archive  ~
        (tar-members:files u.body.request.req)
      =/  carried  (member-named:files 'rover-import.json' members)
      ?:  ?&  archive
              ?=(~ carried)
          ==
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%missing-key: import.archive.rover-import.json')) sat]
      =/  document=@t
        ?~  carried  `@t`q.u.body.request.req
        `@t`q.u.carried
      =/  decoded  (decode-import:entry document)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  backend-text  (~(get by (url-params url.request.req)) 'backend')
      =/  backend=(unit attachment-backend:rover)
        ?~  backend-text  ~
        ?:  =('clay' u.backend-text)  `%clay
        ?:  =('s3' u.backend-text)  `%s3
        ~
      =/  carried-photos
        %+  archive-photos  members
        (decode-import-attachments:entry document ?~(backend %clay u.backend))
      ::  The owner picks, and Rover does not pick for the owner. An import
      ::  that carries no photograph needs no answer, so the question is only
      ::  asked where it changes something.
      ?:  ?&  ?=(^ photos.carried-photos)
              ?=(~ backend)
          ==
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs import-backend-unchosen)
        ==
      ?:  ?&  ?=(^ photos.carried-photos)
              ?=([~ %s3] backend)
              !(s3-configured our.bowl now.bowl)
          ==
        :_  sat
        %:  http-give
            eyre-id
            409
            ['content-type' 'text/plain']~
            `(text-octs s3-unavailable)
        ==
      =/  opening=import-report:rover  (initial-report:imp p.decoded)
      =/  run=import-run:rover
        :*  eyre-id
            %.n
            1
            (import-works:imp p.decoded)
            photos.carried-photos
            %_  opening
              photos-failed  missing.carried-photos
              messages       (weld messages.opening messages.carried-photos)
            ==
        ==
      (continue-import sat our.bowl run)
    ::
    ?:  =('/apps/rover/add-consumable' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: consumable')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-consumable:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-consumable-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (consumable-lookup:act vehicle-label.p.decoded consumable-label.p.decoded)])
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          fill-body-pending  (~(put by fill-body-pending.sat) wir body-text)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M7 T1. One endpoint for all three event kinds. The kind selects which
    ::  typed child the write creates; every association attaches to the parent,
    ::  so the three kinds share one lookup and one insert.
    ::
    ::  M7 T4 adds two more routes to the SAME handler. Buying and selling the
    ::  vehicle are events like any other, so they extend this match rather
    ::  than opening a second decoder that could drift from this one.
    ?:  ?|  =('/apps/rover/add-service-event' url.request.req)
            =('/apps/rover/add-expense-event' url.request.req)
            =('/apps/rover/add-note-event' url.request.req)
            =('/apps/rover/add-acquisition-event' url.request.req)
            =('/apps/rover/add-disposal-event' url.request.req)
        ==
      ::  One handler, five routes. The route selects the kind, so a client
      ::  cannot send a kind that disagrees with the typed child it gets.
      =/  kind=event-kind:rover
        ?:  =('/apps/rover/add-service-event' url.request.req)  %service
        ?:  =('/apps/rover/add-expense-event' url.request.req)  %expense
        ?:  =('/apps/rover/add-acquisition-event' url.request.req)  %acquisition
        ?:  =('/apps/rover/add-disposal-event' url.request.req)  %disposal
        %note
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: event')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-event:entry kind body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      ::  The kind rides the wire, so the response handler recovers it without
      ::  re-reading the body. The body never carried it.
      =/  wir=wire  /rover-event-lookup/[kind]/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (event-lookup:act vehicle-label.p.decoded)])
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          fill-body-pending  (~(put by fill-body-pending.sat) wir body-text)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M7 T12. Correcting an event. ONE endpoint for every kind, because the
    ::  route cannot select the typed child here: the event already has one,
    ::  and the correction has to hold to it. The requested kind therefore
    ::  arrives in the body, and the database decides whether it agrees.
    ::
    ::  The record is named the way the person sees it - the vehicle they
    ::  picked and the moment they recorded - exactly as `edit-fill` does.
    ?:  =('/apps/rover/edit-event' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-event')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  object  (json-object:entry body-text)
      ?~  object
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-event')) sat]
      =/  kind-text  (json-string:entry 'kind' u.object)
      ?~  kind-text
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%missing-key: edit-event.kind')) sat]
      =/  kind-term  (slaw %tas u.kind-text)
      ?.  ?&  ?=(^ kind-term)
              ?=(event-kind:rover u.kind-term)
          ==
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-event.kind')) sat]
      =/  kind=event-kind:rover  ;;(event-kind:rover u.kind-term)
      =/  decoded  (decode-event:entry kind body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      ::  A correction may move the moment, so the record is found by the
      ::  moment it currently holds. An absent key means the moment did not
      ::  change, which is what a form that never touched the date sends.
      =/  original-text  (json-string:entry 'originalObserved' u.object)
      =/  original-observed
        ?~  original-text
          `observed-start.p.decoded
        (local-da:entry u.original-text)
      ?~  original-observed
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-event.original-date')) sat]
      =/  wir=wire  /rover-edit-event-lookup/[kind]/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>  :*  %script  %rover  %vector
                (edit-event-lookup:act vehicle-label.p.decoded (need original-observed))
            ==
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          fill-body-pending  (~(put by fill-body-pending.sat) wir body-text)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M7 T6. One reminder. The write is two phases like an event write: the
    ::  vehicle and the service subtype are resolved by label first, and an
    ::  unknown one is refused rather than invented.
    ?:  =('/apps/rover/add-reminder' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: reminder')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-reminder:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-reminder-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (reminder-lookup:act vehicle-label.p.decoded)])
      =/  next
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          fill-body-pending  (~(put by fill-body-pending.sat) wir body-text)
        ==
      :_  next
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-custom-field' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-custom-definition:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  wir=wire  /rover-custom-create/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (insert-custom-definition:act (fixture-id:act base 501) p.decoded now.bowl)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  ?|  =('/apps/rover/add-energy-source-type' url.request.req)
            =('/apps/rover/add-driving-mode-type' url.request.req)
        ==
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  object  (json-object:entry body-text)
      ?~  object
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type')) sat]
      =/  label  (json-string:entry 'label' u.object)
      ?:  ?|  ?=(~ label)
              !(nonempty:entry u.label)
          ==
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type.label')) sat]
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  type=@tas
        ?:  =('/apps/rover/add-energy-source-type' url.request.req)
          %energy
        %mode
      =/  script=tape
        ?:  =(%mode type)
          (insert-driving-mode-type:act (fixture-id:act base 602) u.label now.bowl)
        =/  kind-text  (json-string:entry 'physicalKind' u.object)
        =/  unit-text  (json-string:entry 'quantityUnit' u.object)
        ?:  ?|  ?=(~ kind-text)
                ?=(~ unit-text)
            ==
          ~
        =/  kind  (slaw %tas u.kind-text)
        =/  unit  (slaw %tas u.unit-text)
        ?:  ?|  ?=(~ kind)
                ?=(~ unit)
                !?=(?(%reservoir %electricity) u.kind)
                !?=(?(%gal %litre %kg %kwh) u.unit)
            ==
          ~
        (insert-energy-source-type:act (fixture-id:act base 601) u.label u.kind u.unit now.bowl)
      ?~  script
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: configuration-type')) sat]
      =/  wir=wire  /rover-type-create/[type]/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector script])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  ?|  =('/apps/rover/archive-custom-field' url.request.req)
            =('/apps/rover/change-custom-field-type' url.request.req)
        ==
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  label=@t
        ?:  =('/apps/rover/archive-custom-field' url.request.req)
          =/  decoded  (decode-custom-field-label:entry body-text)
          ?:  ?=(%| -.decoded)
            ''
          label.p.decoded
        =/  decoded  (decode-custom-field-change:entry body-text)
        ?:  ?=(%| -.decoded)
          ''
        label.p.decoded
      ?.  (nonempty:entry label)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field')) sat]
      =/  operation=@tas
        ?:  =('/apps/rover/archive-custom-field' url.request.req)
          %archive
        %change
      =/  wir=wire  /rover-custom-lookup/[operation]/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (custom-field-lookup:act label)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::  M7 T8. The definition lifecycle. One handler, three routes, nine
    ::  families. The route selects the operation and the body names the
    ::  family, the same split the five event routes use: a client cannot ask
    ::  for an operation the endpoint it called does not perform.
    ::
    ::  The write is two phases, like every other label-addressed write here.
    ::  The first phase finds the definition and, for a rename, whatever else
    ::  already carries the new label. The second phase writes.
    ?:  ?|  =('/apps/rover/rename-definition' url.request.req)
            =('/apps/rover/archive-definition' url.request.req)
            =('/apps/rover/restore-definition' url.request.req)
        ==
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: definition')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  operation=@tas
        ?:  =('/apps/rover/rename-definition' url.request.req)  %rename
        ?:  =('/apps/rover/archive-definition' url.request.req)  %archive
        %restore
      =/  decoded  (decode-definition-lifecycle:entry body-text =(%rename operation))
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  fam  (definition-family-of:act family.p.decoded)
      ?~  fam
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%unknown-family: definition.family')) sat]
      ::  The second lookup probes the new label on a rename and the current
      ::  label otherwise, so the script keeps one shape for all three routes.
      =/  probe=@t
        ?:(=(%rename operation) new-label.p.decoded label.p.decoded)
      =/  wir=wire
        /rover-definition-lookup/[operation]/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (definition-lookup:act u.fam label.p.decoded probe)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/edit-fill' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-fill:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  object  (json-object:entry body-text)
      =/  original-text
        ?~  object
          ~
        (json-string:entry 'originalObserved' u.object)
      =/  original-observed
        ?~  original-text
          `observed-start.p.decoded
        (local-da:entry u.original-text)
      ?~  original-observed
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill.original-date')) sat]
      =/  wir=wire  /rover-edit-fill-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (edit-fill-lookup:act vehicle-label.p.decoded (need original-observed) definition-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/edit-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  body-text=@t  `@t`q.u.body.request.req
      =/  decoded  (decode-vehicle-edit:entry body-text)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-edit-vehicle-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (vehicle-edit-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir body-text)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/set-default-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  decoded  (decode-vehicle-label:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-default-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (app-default-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir 'set-default')
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/remove-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  decoded  (decode-vehicle-label:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-remove-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (archive-vehicle-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir 'remove-vehicle')
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-vehicle' url.request.req)
      ?~  body.request.req
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle')) sat]
      =/  decoded  (decode-new-vehicle:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded))) sat]
      =/  wir=wire  /rover-add-vehicle-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector new-vehicle-lookup:act])
      =/  new-sat
        %_  sat
          pending  (~(put by pending.sat) wir `@t`q.u.body.request.req)
          http-pending  (~(put by http-pending.sat) wir eyre-id)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/set-preference' url.request.req)
      ?~  body.request.req
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs '%bad-shape: preference')
        ==
      =/  decoded  (decode-preference:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs (entry-refusal p.decoded))
        ==
      =/  wir=wire  /rover-preference-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (preference-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          preference-pending  (~(put by preference-pending.sat) wir p.decoded)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-charge' url.request.req)
      ?~  body.request.req
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs '%bad-shape: charge')
        ==
      =/  decoded  (decode-charge:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs (entry-refusal p.decoded))
        ==
      =/  wir=wire  /rover-charge-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon
        !>([%script %rover %vector (fill-lookup:act vehicle-label.p.decoded definition-label.p.decoded)])
      =/  new-sat
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          charge-pending  (~(put by charge-pending.sat) wir p.decoded)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?:  =('/apps/rover/add-odometer' url.request.req)
      ?~  body.request.req
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs '%bad-shape: odometer')
        ==
      =/  decoded  (decode-odometer:entry `@t`q.u.body.request.req)
      ?:  ?=(%| -.decoded)
        :_  sat
        %:  http-give
            eyre-id
            400
            ['content-type' 'text/plain']~
            `(text-octs (entry-refusal p.decoded))
        ==
      =/  wir=wire  /rover-odometer-lookup/(scot %da now.bowl)/[eyre-id]
      =/  jon  !>([%script %rover %vector (vehicle-lookup:act vehicle-label.p.decoded)])
      =/  new-sat
        %_  sat
          http-pending  (~(put by http-pending.sat) wir eyre-id)
          odometer-pending  (~(put by odometer-pending.sat) wir p.decoded)
        ==
      :_  new-sat
      :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
          [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ?.  =('/apps/rover/add-fill' url.request.req)
      [(http-give eyre-id 405 ~ ~) sat]
    ?~  body.request.req
      :_  sat
      %:  http-give
          eyre-id
          400
          ['content-type' 'text/plain']~
          `(text-octs '%bad-shape: fill')
      ==
    =/  fill-body=@t  `@t`q.u.body.request.req
    =/  decoded  (decode-fill:entry fill-body)
    ?:  ?=(%| -.decoded)
      :_  sat
      %:  http-give
          eyre-id
          400
          ['content-type' 'text/plain']~
          `(text-octs (entry-refusal p.decoded))
      ==
    =/  wir=wire  /rover-fill-lookup/(scot %da now.bowl)/[eyre-id]
    =/  jon
      !>([%script %rover %vector (fill-lookup:act vehicle-label.p.decoded definition-label.p.decoded)])
    =/  new-sat
      %_  sat
        http-pending  (~(put by http-pending.sat) wir eyre-id)
        fill-pending  (~(put by fill-pending.sat) wir p.decoded)
        fill-body-pending  (~(put by fill-body-pending.sat) wir fill-body)
      ==
    :_  new-sat
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ?.  =(%'GET' method.request.req)
    [(http-give eyre-id 405 ~ ~) sat]
  ?:  =('/apps/rover/assets/tile.png' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'image/png']~ `tile-octs) sat]
  ?:  =('/apps/rover/assets/fonts/JetBrainsMono-Regular.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-regular-octs) sat]
  ?:  =('/apps/rover/assets/fonts/JetBrainsMono-Bold.woff2' url.request.req)
    [(http-give eyre-id 200 ['content-type' 'font/woff2']~ `font-bold-octs) sat]
  ?:  =('/apps/rover/view' url.request.req)
    =/  wir=wire
      ?:  bootstrap-ready.sat
        /rover-http/recover/(scot %da now.bowl)/[eyre-id]
      /rover-bootstrap-probe/(scot %da now.bowl)/[eyre-id]
    =/  jon
      ?:  bootstrap-ready.sat
        !>([%script %rover %vector (ui-view:act ~)])
      !>([%script %sys %vector database-list:act])
    =/  new-sat
      sat(pending (~(put by pending.sat) wir '0'), http-pending (~(put by http-pending.sat) wir eyre-id))
    :_  new-sat
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ::  M8, second leg, ruling 23. The two JSON routes the entry surface needs.
  ::  The HTML the browser renders is one client of them. A native client, a
  ::  phone, or a bridge relaying a device in the vehicle reaches the same
  ::  photos over the same route, without a renderer in between.
  ?:  =('/apps/rover/backends.json' (url-base url.request.req))
    [(json-give eyre-id 200 (backends-json our.bowl now.bowl)) sat]
  ?:  =('/apps/rover/attachments.json' (url-base url.request.req))
    ?.  bootstrap-ready.sat
      :_  sat
      %^  json-give  eyre-id  503
      (json-message 'Rover is still loading. Ask for the photos again.')
    =/  wanted  (~(get by (url-params url.request.req)) 'vehicle')
    ?:  ?|(?=(~ wanted) =('' u.wanted))
      :_  sat
      %^  json-give  eyre-id  400
      (json-message 'Name the vehicle whose photos you want.')
    =/  wir=wire  /rover-attachment-index/(scot %da now.bowl)/[eyre-id]
    =/  jon  !>([%script %rover %vector (attachment-index:act u.wanted)])
    =/  next
      %_  sat
        http-pending  (~(put by http-pending.sat) wir eyre-id)
        pending       (~(put by pending.sat) wir u.wanted)
      ==
    :_  next
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ::  M8. Serving one photo back. The file name is the address, because it is
  ::  the only handle on an attachment a person ever sees. The reference says
  ::  which backend holds the bytes, and the ship proxies them: no presigned
  ::  URL reaches the browser, so nothing the owner saves can expire or leak a
  ::  credential into a file.
  ?:  (url-prefix url.request.req '/apps/rover/attachment/')
    ?.  bootstrap-ready.sat
      [(http-give eyre-id 503 ['content-type' 'text/plain']~ `(text-octs 'Rover is still loading. Try the attachment again.')) sat]
    =/  wanted  (url-tail url.request.req '/apps/rover/attachment/')
    ?~  wanted
      [(http-give eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: attachment.file')) sat]
    =/  wir=wire  /rover-attachment-serve/(scot %da now.bowl)/[eyre-id]
    =/  jon  !>([%script %rover %vector (attachment-by-name:act u.wanted)])
    =/  next
      %_  sat
        http-pending  (~(put by http-pending.sat) wir eyre-id)
        pending  (~(put by pending.sat) wir u.wanted)
      ==
    :_  next
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ::  M8. The whole history AND the bytes, in one uncompressed tar. The JSON
  ::  member is the same payload the JSON endpoint serves, so a reader that
  ::  wants only the facts can take that one file out and stop.
  ?:  =('/apps/rover/export.tar' url.request.req)
    ?.  bootstrap-ready.sat
      [(http-give eyre-id 503 ['content-type' 'text/plain']~ `(text-octs 'Rover is still loading. Try the export again.')) sat]
    ?^  export-run.sat
      [(http-give eyre-id 409 ['content-type' 'text/plain']~ `(text-octs 'An export is already running')) sat]
    =/  wir=wire  /rover-export-tar/(scot %da now.bowl)/[eyre-id]
    =/  jon  !>([%script %rover %vector export-view:act])
    =/  new-sat
      sat(pending (~(put by pending.sat) wir 'export'), http-pending (~(put by http-pending.sat) wir eyre-id))
    :_  new-sat
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ?:  =('/apps/rover/export' url.request.req)
    ?.  bootstrap-ready.sat
      [(http-give eyre-id 503 ['content-type' 'text/plain']~ `(text-octs 'Rover is still loading. Try the export again.')) sat]
    =/  wir=wire  /rover-export/(scot %da now.bowl)/[eyre-id]
    =/  jon  !>([%script %rover %vector export-view:act])
    =/  new-sat
      sat(pending (~(put by pending.sat) wir 'export'), http-pending (~(put by http-pending.sat) wir eyre-id))
    :_  new-sat
    :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  [(http-give eyre-id 200 ['content-type' 'text/html']~ `shell-page) sat]
--
=|  state-24
=*  state  -
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  =/  wir=wire  /rover-install-probe/(scot %da now.bowl)
  =/  jon  !>([%script %sys %vector database-list:act])
  =/  cards=(list card)
    :~  bind-eyre
        [%pass wir %agent [our.bowl %obelisk] %watch /server]
        [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  :_  this(bootstrap-ready %.n)
  (weld cards (ensure-files-desk:files our.bowl now.bowl))
::
++  on-save  !>([%24 state])
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  s  !<(versioned-state old)
  =/  loaded=_this
    ?-  -.s
      %0  this(state [pending.+.s last.+.s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %.n ~ ~])
      %1  this(state [pending.+.s last.+.s preview.+.s total.+.s ~ ~ ~ ~ ~ ~ ~ ~ ~ %.n ~ ~])
      %2  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s ~ ~ ~ ~ ~ ~ ~ ~ %.n ~ ~])
      %3  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s ~ ~ ~ ~ ~ ~ ~ %.n ~ ~])
      %4  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ ~ ~ ~ ~ %.n ~ ~])
      %5  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ ~ ~ ~ ~ %.n ~ ~])
      %6  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s ~ ~ ~ %.n ~ ~])
      %7  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s ~ ~ ~ %.n ~ ~])
      %8  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s ~ ~ %.n ~ ~])
      %9  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s ~ ~ %.n ~ ~])
      %10  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n ~ ~])
      %11  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n ~ ~])
      %12  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n ~ ~])
      %13  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s ~ ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n ~ ~])
      %14  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n ~ ~])
      %15  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s ~ odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n ~ ~])
      %16  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ %.n ~ ~])
      %17  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ bootstrap-ready.+.s ~ ~])
      %18  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ bootstrap-ready.+.s ~ ~])
      %19  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ bootstrap-ready.+.s ~ ~])
      %20  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s import-run.+.s bootstrap-ready.+.s ~ ~])
      ::  An in-flight attachment cannot cross an upgrade: the bytes waiting
      ::  here belong to an HTTP request whose connection is already gone. The
      ::  map is dropped and the browser is told to send the photo again.
      %21  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s import-run.+.s bootstrap-ready.+.s ~ ~])
      %22  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s import-run.+.s bootstrap-ready.+.s attachment-pending.+.s ~])
      %23  this(state [pending.+.s last.+.s preview.+.s total.+.s charging-total.+.s integrity.+.s http-pending.+.s fill-pending.+.s charge-pending.+.s odometer-pending.+.s preference-pending.+.s fill-body-pending.+.s ~ bootstrap-ready.+.s attachment-pending.+.s export-run.+.s])
      ::  An import in flight is dropped, the way an attachment in flight is.
      ::  The connection it would answer does not survive the upgrade, and a
      ::  run left behind would refuse every later import as one already
      ::  running.
      %24  this(state +.s(import-run ~))
    ==
  =/  cards=(list card)  ~[bind-eyre]
  :_  loaded
  (weld cards (ensure-files-desk:files our.bowl now.bowl))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    =^  cards  state  (handle-http state bowl eyre-id req)
    [cards this]
  ::
      %rover-action
    ?>  =(our.bowl src.bowl)
    =/  a  !<(action:rover vase)
    ?-  -.a
      %init-db
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector schema-m0:act])
        :_  this(pending (~(put by pending) wir 'init-db'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %ensure-ui-schema
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector display-preference-schema:act])
        :_  this(pending (~(put by pending) wir 'ensure-ui-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      ::  Read the relation list first, then pour only what is absent. Obelisk
      ::  has no CREATE TABLE IF NOT EXISTS and a script is atomic, so a single
      ::  already-poured relation would abort the whole catch-up.
      %ensure-def-schema
        =/  wir=path  /rover-def-check/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector def-schema-check:act])
        :_  this(pending (~(put by pending) wir 'ensure-def-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %seed-starters
        =/  wir=path  /rover-starter-check/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector starter-check:act])
        :_  this(pending (~(put by pending) wir 'seed-starters-check'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      %verify-schema
        =/  wir=path  /rover/(scot %da now.bowl)
        =/  jon  !>([%script %rover %vector verify-schema:act])
        :_  this(pending (~(put by pending) wir 'verify-schema'))
        :~  [%pass wir %agent [our.bowl %obelisk] %watch /server]
            [%pass wir %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
    ==
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:def wire sign)
      [%rover-attachment-metadata *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  waiting  (~(get by pending) wire)
      =/  cleared=_this
        this(http-pending (~(del by http-pending) wire), pending (~(del by pending) wire))
      ?~  eyre-id  `cleared
      ?~  waiting
        [(restart-http u.eyre-id) cleared]
      ?:  ?=(%.n -.res)
        [(json-give u.eyre-id 422 (json-message 'The database refused the attachment lookup.')) cleared]
      =/  decoded  (decode-attachment-metadata:entry (url-params u.waiting))
      ?:  ?=(%| -.decoded)
        [(json-give u.eyre-id 400 (json-message (entry-refusal p.decoded))) cleared]
      =/  meta  p.decoded
      =/  owners  (rows-at:view p.res 0)
      ?.  =(1 (lent owners))
        [(json-give u.eyre-id 404 (json-message (attachment-not-found owner.entry.meta))) cleared]
      =/  config  (storage-configuration our.bowl now.bowl)
      ?~  config
        [(json-give u.eyre-id 409 (json-message storage-unconfigured)) cleared]
      =/  locator  (s3-locator:files bucket.u.config content-hash.meta)
      ?:  =('/apps/rover/attachment-url' (url-base u.waiting))
        =/  payload=json
          %-  pairs:enjs:format
          :~  ['putUrl' s+(s3-presign:files u.config locator now.bowl)]
              ['getUrl' s+(s3-url:files endpoint.u.config locator)]
          ==
        :_  cleared
        %:  http-give
            u.eyre-id
            200
            ~[['content-type' 'application/json; charset=utf-8'] ['cache-control' 'no-store']]
            `(text-octs (en:json:html payload))
        ==
      ::  Record only. The browser calls this after its PUT returns 200.
      =/  owner-id=@ux
        `@ux`(cell-atom:view (attachment-owner-column owner.entry.meta) (snag 0 owners))
      =/  vehicle-id=@ux  `@ux`(cell-atom:view %vehicle-id (snag 0 owners))
      =/  stored  (rows-at:view p.res 1)
      =/  same-photo  (attachment-match entry.meta content-hash.meta %.y stored)
      =/  taken=(set @t)
        (silt (turn stored |=(row=vector:ast (cell-text:view %file-name row))))
      =/  name=@t
        ?~  same-photo  (unique-name:files file-name.entry.meta taken)
        (cell-text:view %file-name u.same-photo)
      =/  already
        ?~  same-photo  %.n
        %+  lien  (rows-at:view p.res 2)
        |=  row=vector:ast
        =((cell-atom:view %attachment-id row) (cell-atom:view %attachment-id u.same-photo))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  attachment-id=@ux  (fixture-id:act base 9.201)
      =/  ref=attachment-ref:rover
        [attachment-id %s3 locator content-hash.meta byte-count.meta media-type.entry.meta name]
      =/  script=tape
        ?:  already  (remember-attachment-backend:act vehicle-id %s3 now.bowl)
        ?~  same-photo  (insert-attachment:act ref owner.entry.meta owner-id vehicle-id now.bowl)
        (attachment-link:act owner.entry.meta owner-id `@ux`(cell-atom:view %attachment-id u.same-photo) vehicle-id %s3 now.bowl)
      =/  write-wire=path
        =/  base=path  /rover-attachment-write/(scot %da now.bowl)/[u.eyre-id]
        ?:(already (weld base /already) base)
      =/  next=_this
        %=  cleared
          http-pending  (~(put by http-pending.cleared) write-wire u.eyre-id)
          pending       (~(put by pending.cleared) write-wire name)
        ==
      :_  next
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action !>([%script %rover %vector script])]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      ::  M8 phase one. Obelisk has resolved which record owns the photo and
      ::  which file names are already taken. The bytes have been waiting in
      ::  `attachment-pending`; now they go to a backend and the reference goes
      ::  to the database, in the same turn.
      [%rover-attachment-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  waiting  (~(get by attachment-pending) wire)
      =/  cleared=_this
        %=  this
          http-pending        (~(del by http-pending) wire)
          attachment-pending  (~(del by attachment-pending) wire)
        ==
      ?~  eyre-id
        `cleared
      ?~  waiting
        :_  cleared
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: attachment'))
      =/  write  u.waiting
      =/  owners  (rows-at:view p.res 0)
      ?.  =(1 (lent owners))
        :_  cleared
        %:  http-give
            u.eyre-id
            404
            ['content-type' 'text/plain']~
            `(text-octs (attachment-not-found owner.entry.write))
        ==
      =/  owner-id=@ux
        `@ux`(cell-atom:view (attachment-owner-column owner.entry.write) (snag 0 owners))
      =/  vehicle-id=@ux  `@ux`(cell-atom:view %vehicle-id (snag 0 owners))
      =/  stored  (rows-at:view p.res 1)
      =/  taken=(set @t)
        %-  silt
        %+  turn  stored
        |=(row=vector:ast (cell-text:view %file-name row))
      =/  name=@t  (unique-name:files file-name.entry.write taken)
      ::  The store is content-addressed. Bytes Rover already holds in this
      ::  backend are never stored a second time, which is what makes running
      ::  a load twice a no-op - ruling 18 applied to photos - and what makes
      ::  the one byte-identical duplicate in the owner's corpus cost one copy.
      ::
      ::  Storing once is not the same as naming once. A person who files one
      ::  photograph under two names has two photos, and the second name is a
      ::  fact Rover was told. So identical bytes under a NAME the ship
      ::  already has reuse the whole reference, and identical bytes under a
      ::  new name get their own reference pointing at the same stored file.
      =/  same-as
        |=(by-name=? (attachment-match entry.write content-hash.write by-name stored))
      =/  same-photo  (same-as %.y)
      =/  same-bytes  (same-as %.n)
      ?^  same-photo
        =/  existing=@ux  `@ux`(cell-atom:view %attachment-id u.same-photo)
        =/  existing-name  (cell-text:view %file-name u.same-photo)
        =/  already
          %+  lien  (rows-at:view p.res 2)
          |=(row=vector:ast =(existing `@ux`(cell-atom:view %attachment-id row)))
        ?:  already
          :_  cleared
          %:  http-give
              u.eyre-id
              200
              ['content-type' 'text/plain']~
              `(text-octs (cat 3 'Already attached ' existing-name))
          ==
        =/  link-wire=path  /rover-attachment-write/(scot %da now.bowl)/[u.eyre-id]
        =/  jon
          !>  :*  %script  %rover  %vector
                  (attachment-link:act owner.entry.write owner-id existing vehicle-id backend.entry.write now.bowl)
              ==
        =/  next=_this
          %=  cleared
            http-pending  (~(put by (~(del by http-pending) wire)) link-wire u.eyre-id)
            pending       (~(put by pending) link-wire existing-name)
          ==
        :_  next
        :~  [%pass link-wire %agent [our.bowl %obelisk] %watch /server]
            [%pass link-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      ::  The same bytes under a name this ship has not seen. The reference is
      ::  new and it keeps the name the owner gave, but its locator is the one
      ::  that already holds the bytes, so the file is not written twice.
      ?^  same-bytes
        =/  ref=attachment-ref:rover
          :*  attachment-id.write
              backend.entry.write
              (cell-text:view %locator u.same-bytes)
              content-hash.write
              p.bytes.write
              media-type.entry.write
              name
          ==
        =/  share-wire=path  /rover-attachment-write/(scot %da now.bowl)/[u.eyre-id]
        =/  jon
          !>  :*  %script  %rover  %vector
                  (insert-attachment:act ref owner.entry.write owner-id vehicle-id now.bowl)
              ==
        =/  next=_this
          %=  cleared
            http-pending  (~(put by (~(del by http-pending) wire)) share-wire u.eyre-id)
            pending       (~(put by pending) share-wire name)
          ==
        :_  next
        :~  [%pass share-wire %agent [our.bowl %obelisk] %watch /server]
            [%pass share-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
        ==
      =/  resolved=attachment-write:rover  write(owner-id owner-id, stored-name name)
      ::  Clay is synchronous: the commit and the reference insert go out in
      ::  the same turn. S3 is a round trip over the network, so the bytes go
      ::  first and the reference waits for the bucket to acknowledge them. A
      ::  reference to an object that was never stored would be worse than a
      ::  refusal.
      ?:  =(%s3 backend.entry.write)
        =/  config  (storage-configuration our.bowl now.bowl)
        ?~  config
          :_  cleared
          (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs storage-unconfigured))
        =/  put-wire=path  /rover-attachment-s3-put/(scot %da now.bowl)/[u.eyre-id]
        =/  outbound
          %:  s3-request:files
              u.config
              'PUT'
              (s3-locator:files bucket.u.config content-hash.write)
              media-type.entry.write
              `bytes.write
              now.bowl
          ==
        =/  next=_this
          %=  cleared
            http-pending        (~(put by (~(del by http-pending) wire)) put-wire u.eyre-id)
            attachment-pending  (~(put by (~(del by attachment-pending) wire)) put-wire resolved)
            pending             (~(put by pending) put-wire (scot %ux vehicle-id))
          ==
        :_  next
        [%pass put-wire %arvo %i %request outbound *outbound-config:iris]~
      =/  ref=attachment-ref:rover
        :*  attachment-id.write
            backend.entry.write
            (clay-locator:files attachment-id.write)
            content-hash.write
            p.bytes.write
            media-type.entry.write
            name
        ==
      =/  write-wire=path  /rover-attachment-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        (insert-attachment:act ref owner.entry.write owner-id vehicle-id now.bowl)
      =/  jon  !>([%script %rover %vector script])
      =/  next=_this
        %=  cleared
          http-pending  (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
          pending       (~(put by pending) write-wire name)
        ==
      :_  next
      :~  (clay-write-card:files attachment-id.write media-type.entry.write bytes.write)
          [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      :-  ~
      %=  this
        http-pending        (~(del by http-pending) wire)
        attachment-pending  (~(del by attachment-pending) wire)
      ==
    ::
        %watch-ack
      `this
    ==
  ::
      ::  M8 phase two. The reference row and its link landed. The answer names
      ::  the file the way the owner will ask for it back.
      [%rover-attachment-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  name  (~(get by pending) wire)
      =/  cleared=_this
        this(http-pending (~(del by http-pending) wire), pending (~(del by pending) wire))
      ?~  eyre-id
        `cleared
      ?:  ?|(?=(%.n -.res) ?=(~ name))
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: attachment'))
      =/  already=?  ?=([%rover-attachment-write @ @ %already ~] wire)
      :_  cleared
      %:  http-give
          u.eyre-id
          ?:(already 200 201)
          ['content-type' 'text/plain']~
          `(text-octs (cat 3 ?:(already 'Already attached ' 'Attached ') u.name))
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      ::  M8, second leg, ruling 23. The photos one vehicle's records carry,
      ::  answered as JSON. The History cards are one client of this.
      [%rover-attachment-index *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  label  (~(get by pending) wire)
      =/  cleared=_this
        this(http-pending (~(del by http-pending) wire), pending (~(del by pending) wire))
      ?~  eyre-id
        `cleared
      ?:  ?=(%.n -.res)
        :_  cleared
        %^  json-give  u.eyre-id  503
        (json-message 'Rover could not read the photos for that vehicle.')
      =/  config  (storage-configuration our.bowl now.bowl)
      =/  s3-photos
        %+  lien  ;:(weld (rows:exp p.res 0) (rows:exp p.res 1) (rows:exp p.res 2))
        |=(row=vector:ast =(%s3 (cell-term:view %backend row)))
      ?:  ?&(?=(~ config) s3-photos)
        [(json-give u.eyre-id 409 (json-message storage-unconfigured)) cleared]
      :_  cleared
      %^  json-give  u.eyre-id  200
      (attachment-index-json ?~(label '' u.label) ?~(config '' endpoint.u.config) p.res)
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      ::  M8. Serving one photo. The reference says which backend and where;
      ::  the ship reads the bytes and hands them to the browser itself.
      [%rover-attachment-serve *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  cleared=_this
        this(http-pending (~(del by http-pending) wire), pending (~(del by pending) wire))
      ?~  eyre-id
        `cleared
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: attachment'))
      =/  found  (rows-at:view p.res 0)
      ?.  =(1 (lent found))
        :_  cleared
        %:  http-give
            u.eyre-id
            404
            ['content-type' 'text/plain']~
            `(text-octs 'No attachment by that name.')
        ==
      =/  row  (snag 0 found)
      ::  The locator is the address of the bytes. It is read from the row
      ::  rather than rebuilt from the id, because two references can name one
      ::  stored file - the same photograph filed under two names.
      =/  locator=@t  (cell-text:view %locator row)
      =/  backend=@tas  (cell-term:view %backend row)
      =/  media-type=@t  (cell-text:view %media-type row)
      ?.  =(%clay backend)
        =/  config  (storage-configuration our.bowl now.bowl)
        ?~  config
          :_  cleared
          %:  http-give
              u.eyre-id
              409
              ['content-type' 'text/plain']~
              `(text-octs 'That photo is in S3 storage, and this ship has no bucket configured to read it from.')
          ==
        =/  get-wire=path  /rover-attachment-s3-get/(scot %da now.bowl)/[u.eyre-id]
        =/  outbound
          (s3-request:files u.config 'GET' locator media-type ~ now.bowl)
        =/  next=_this
          %=  this
            http-pending  (~(put by (~(del by http-pending) wire)) get-wire u.eyre-id)
            pending       (~(put by (~(del by pending) wire)) get-wire media-type)
          ==
        :_  next
        [%pass get-wire %arvo %i %request outbound *outbound-config:iris]~
      =/  bytes  (clay-read:files our.bowl now.bowl locator)
      ?~  bytes
        :_  cleared
        %:  http-give
            u.eyre-id
            410
            ['content-type' 'text/plain']~
            `(text-octs 'Rover has a record of that photo, but the storage backend no longer holds it.')
        ==
      :_  cleared
      %:  http-give
          u.eyre-id
          200
          ['content-type' media-type]~
          `u.bytes
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      ::  M8. The facts came back. The JSON is finished here, and the walk over
      ::  the references starts.
      [%rover-export-tar *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ::  The wire is retired before the walk begins, so `continue-export`
      ::  starts from the state the rest of the export will carry.
      =.  pending  (~(del by pending) wire)
      =.  http-pending  (~(del by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 503 ['content-type' 'text/plain']~ `(text-octs 'Rover could not read the export facts.'))
      =/  run=export-run:rover
        [u.eyre-id (document:exp p.res %.y) (export-refs p.res) ~]
      =/  continued=[(list card) state-24]
        (continue-export state our.bowl now.bowl run)
      [-.continued this(state +.continued)]
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-export *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Rover could not read the export facts.')
        ==
      =/  payload=@t  (document:exp p.res %.n)
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          200
          :~  ['content-type' 'application/json; charset=utf-8']
              ['content-disposition' 'attachment; filename="rover-export-complete.json"']
          ==
          `(text-octs payload)
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-def-check *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this(pending (~(del by pending) wire), last `res)
      =/  present=(list @tas)
        %+  turn  (rows-at:view p.res 0)
        |=  row=vector:ast
        ^-  @tas
        (cell-term:view %name row)
      =/  old-present
        (lien present |=(had=@tas =(had %fuel-fill-odometers)))
      =/  new-present
        (lien present |=(had=@tas =(had %energy-acquisition-odometers)))
      ?:  old-present
        =/  next-wire=path
          ?:  new-present
            /rover-energy-odometer-precheck/(scot %da now.bowl)
          /rover-energy-odometer-create/(scot %da now.bowl)
        =/  script=tape
          ?:  new-present
            energy-odometer-migration-check:act
          energy-odometer-create:act
        :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
        (obelisk-script-cards our.bowl next-wire script)
      =/  script  (missing-def-schema:act present)
      ?~  script
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path  /rover/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector script])
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-create *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-create-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path
        /rover-energy-odometer-precheck-delay/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-precheck *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-precheck-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  source  (rows-at:view p.res 0)
      =/  destination  (rows-at:view p.res 1)
      ~&  [%rover-energy-odometer-source-count (lent source)]
      ?:  (migration-rows-match source destination)
        ~&  [%rover-energy-odometer-preverified (lent source)]
        =/  next-wire=path
          /rover-energy-odometer-drop-delay/(scot %da now.bowl)
        :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
        ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
      ?^  destination
        ~&  [%rover-energy-odometer-migration-refused %destination-not-empty (lent source) (lent destination)]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path
        /rover-energy-odometer-copy/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      (obelisk-script-cards our.bowl next-wire (energy-odometer-copy-script source))
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-copy *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-copy-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path
        /rover-energy-odometer-verify/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      (obelisk-script-cards our.bowl next-wire energy-odometer-migration-check:act)
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-verify *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-verify-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  source  (rows-at:view p.res 0)
      =/  destination  (rows-at:view p.res 1)
      ?.  (migration-rows-match source destination)
        ~&  [%rover-energy-odometer-migration-refused %content-mismatch (lent source) (lent destination)]
        `this(pending (~(del by pending) wire), last `res)
      ~&  [%rover-energy-odometer-verified (lent source)]
      =/  next-wire=path
        /rover-energy-odometer-drop-delay/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-energy-odometer-drop *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        ~&  [%rover-energy-odometer-drop-refused p.res]
        `this(pending (~(del by pending) wire), last `res)
      =/  next-wire=path  /rover-def-check/(scot %da now.bowl)
      :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'), last `res)
      (obelisk-script-cards our.bowl next-wire def-schema-check:act)
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-probe *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      ?:  (database-present p.res)
        `this(bootstrap-ready %.y)
      =/  next-wire=path  /rover-install-pour/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector schema-m0:act])
      :_  this
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-pour *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      =/  next-wire=path  /rover-install-delay/(scot %da now.bowl)
      :_  this
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-starter-check *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  script  (starter-seed-script p.res base now.bowl)
      ?~  script
        `this(bootstrap-ready %.y)
      =/  next-wire=path  /rover-install-starter-write/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector script])
      :_  this
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-install-starter-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this
      `this(bootstrap-ready %.y)
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-consumable-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?~  eyre-id
        `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: consumable'))
      =/  decoded  (decode-consumable:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: consumable'))
      =/  vehicles  (rows-at:view p.res 0)
      =/  definitions  (rows-at:view p.res 1)
      ?.  ?&  =(1 (lent vehicles))
              =(1 (lent definitions))
          ==
        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: consumable'))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-consumable-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        %:  insert-consumable:act
            (fixture-id:act base 9.101)
            (fixture-id:act base 9.102)
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            `@ux`(cell-atom:view %consumable-id (snag 0 definitions))
            (cell-term:view %quantity-unit (snag 0 definitions))
            p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) write-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-event-lookup ?(%service %expense %note %acquisition %disposal) *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: event'))
      =/  decoded  (decode-event:entry i.t.wire u.body)
      ?:  ?=(%| -.decoded)
        :_  cleared
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: event'))
      ?.  (gte (lent p.res) 6)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: event'))
      =/  vehicles  (rows-at:view p.res 0)
      =/  station-rows  (rows-at:view p.res 1)
      =/  tag-rows  (rows-at:view p.res 2)
      =/  payment-rows  (rows-at:view p.res 3)
      =/  subtype-rows  (rows-at:view p.res 4)
      =/  disposal-kind-rows  (rows-at:view p.res 5)
      ?.  =(1 (lent vehicles))
        :_  cleared
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.vehicle'))
      =/  station-id=(unit @ux)
        ?~  station-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.station-label.p.decoded station-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.p.decoded)
              ?=(~ station-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.station'))
      =/  tag-proof
        (ids-for-labels:view tag-labels.p.decoded tag-rows %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.tags'))
      ::  A subtype the catalog does not hold is a refusal, never a silent
      ::  create. Only the starter pack and a later T8 endpoint make
      ::  definitions; an event never invents one.
      =/  subtype-proof
        (ids-for-labels:view subtype-labels.p.decoded subtype-rows %label %service-subtype-id)
      ?:  ?=(%| -.subtype-proof)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.subtypes'))
      ::  M7 T4. A disposal names one catalog row. An unknown label is a
      ::  refusal, never a silent create: only the starter pack and a later T8
      ::  endpoint make definitions, and a sale never invents one.
      =/  disposal-kind-id=(unit @ux)
        ?~  disposal-kind-label.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.disposal-kind-label.p.decoded disposal-kind-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %disposal-kind-id u.found)
      ?:  ?&  ?=(^ disposal-kind-label.p.decoded)
              ?=(~ disposal-kind-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.disposal-kind'))
      =/  payment-method-id=(unit @ux)
        ?~  payment-method-label.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.payment-method-label.p.decoded payment-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.p.decoded)
              ?=(~ payment-method-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: event.payment-method'))
      ?:  ?&  ?=(^ new-tag-label.p.decoded)
              ?=(^ (row-by-text:view %label u.new-tag-label.p.decoded tag-rows))
          ==
        :_  cleared
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%already-exists: event.new-tag'))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=event-ids:act
        :*  (fixture-id:act base 9.301)
            (fixture-id:act base 9.302)
            (fixture-id:act base 9.303)
            (fixture-id:act base 9.304)
            (fixture-id:act base 9.305)
        ==
      =/  write-wire=path  /rover-event-write/[i.t.wire]/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        %:  insert-event:act
            ids
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            station-id
            p.tag-proof
            p.subtype-proof
            disposal-kind-id
            payment-method-id
            p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) write-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-event-write ?(%service %expense %note %acquisition %disposal) *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      =/  decoded  (decode-event:entry i.t.wire u.body)
      ?:  ?|  ?=(%.n -.res)
              ?=(%| -.decoded)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: event'))
      =/  saved=@t
        =/  head  (cat 3 'Saved ' (cat 3 (scot %tas kind.p.decoded) ' event'))
        ?~  total-mills.p.decoded
          head
        (cat 3 head (cat 3 ' - ' total-display.p.decoded))
      :_  cleared
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs saved))
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
  ::  M7 T12. Correcting an event, in three phases.
  ::
  ::  One: the vehicle label and the recorded moment become an event id. Two:
  ::  the event's own state - which typed child it has, which odometer
  ::  observation it links to - and every catalog the corrected form may name.
  ::  Three: one atomic mutation-only script, because the pinned engine refuses
  ::  a mutation that follows a result-returning query in one script.
      [%rover-edit-event-lookup ?(%service %expense %note %acquisition %disposal) *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-event'))
      ?~  p.res
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-event.evidence'))
      =/  rows  (rows-at:view p.res 0)
      ?~  rows
        :_  cleared
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-event'))
      ::  Two events on one vehicle at one moment cannot be told apart by the
      ::  only handle a person has, so Rover corrects neither.
      ?.  =(1 (lent rows))
        :_  cleared
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%ambiguous: edit-event'))
      =/  event-id=@ux  `@ux`(cell-atom:view %event-id i.rows)
      =/  vehicle-id=@ux  `@ux`(cell-atom:view %vehicle-id i.rows)
      =/  state-wire=path
        :*  %rover-edit-event-state
            i.t.wire
            (scot %ux event-id)
            (scot %ux vehicle-id)
            (scot %da now.bowl)
            u.eyre-id
            ~
        ==
      =/  jon  !>([%script %rover %vector (edit-event-state:act event-id)])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) state-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) state-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass state-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass state-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-event-state ?(%service %expense %note %acquisition %disposal) @ @ *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-event'))
      =/  decoded  (decode-event:entry i.t.wire u.body)
      ?:  ?=(%| -.decoded)
        :_  cleared
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-event'))
      ?.  (gte (lent p.res) 11)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-event.evidence'))
      =/  event-id=@ux  (slav %ux i.t.t.wire)
      =/  vehicle-id=@ux  (slav %ux i.t.t.t.wire)
      ::  The kind is which typed child exists. Rover reads it rather than
      ::  trusting the request, because this is the one fact a correction may
      ::  not change.
      =/  stored=(unit event-kind:rover)
        ?^  (rows-at:view p.res 0)  `%service
        ?^  (rows-at:view p.res 1)  `%expense
        ?^  (rows-at:view p.res 2)  `%note
        ?^  (rows-at:view p.res 3)  `%acquisition
        ?^  (rows-at:view p.res 4)  `%disposal
        ~
      ?~  stored
        :_  cleared
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-event.kind'))
      ::  A service visit that should have been an expense is a different
      ::  family with a different typed child. Correcting the kind would move
      ::  the row between relations and break every link into it, so Rover says
      ::  so instead of doing it.
      ?.  =(u.stored kind.p.decoded)
        =/  reason=@t
          %^  cat  3
            '%wrong-kind: edit-event.kind - an event keeps the kind it was '
          'recorded under. Record the event again under the kind you want.'
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs reason))
      =/  current-odometer-id=(unit @ux)
        =/  odometer-rows  (rows-at:view p.res 5)
        ?~  odometer-rows
          ~
        ``@ux`(cell-atom:view %odometer-id i.odometer-rows)
      =/  station-rows  (rows-at:view p.res 6)
      =/  tag-rows  (rows-at:view p.res 7)
      =/  payment-rows  (rows-at:view p.res 8)
      =/  subtype-rows  (rows-at:view p.res 9)
      =/  disposal-kind-rows  (rows-at:view p.res 10)
      =/  station-id=(unit @ux)
        ?~  station-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.station-label.p.decoded station-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.p.decoded)
              ?=(~ station-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-event.station'))
      =/  tag-proof
        (ids-for-labels:view tag-labels.p.decoded tag-rows %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-event.tags'))
      =/  subtype-proof
        (ids-for-labels:view subtype-labels.p.decoded subtype-rows %label %service-subtype-id)
      ?:  ?=(%| -.subtype-proof)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-event.subtypes'))
      =/  disposal-kind-id=(unit @ux)
        ?~  disposal-kind-label.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.disposal-kind-label.p.decoded disposal-kind-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %disposal-kind-id u.found)
      ?:  ?&  ?=(^ disposal-kind-label.p.decoded)
              ?=(~ disposal-kind-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-event.disposal-kind'))
      =/  payment-method-id=(unit @ux)
        ?~  payment-method-label.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.payment-method-label.p.decoded payment-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.p.decoded)
              ?=(~ payment-method-id)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-event.payment-method'))
      ?:  ?&  ?=(^ new-tag-label.p.decoded)
              ?=(^ (row-by-text:view %label u.new-tag-label.p.decoded tag-rows))
          ==
        :_  cleared
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%already-exists: edit-event.new-tag'))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      ::  Only the ids for rows a correction may CREATE are fresh. The event id
      ::  is the one already stored, and the odometer id is used only when the
      ::  event had no reading before.
      =/  ids=event-ids:act
        :*  event-id
            (fixture-id:act base 9.401)
            (fixture-id:act base 9.402)
            (fixture-id:act base 9.403)
            (fixture-id:act base 9.404)
        ==
      =/  write-wire=path
        /rover-edit-event-write/[i.t.wire]/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        %:  update-event:act
            ids
            vehicle-id
            station-id
            p.tag-proof
            p.subtype-proof
            disposal-kind-id
            payment-method-id
            current-odometer-id
            p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) write-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-event-write ?(%service %expense %note %acquisition %disposal) *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      =/  decoded  (decode-event:entry i.t.wire u.body)
      ?:  ?|  ?=(%.n -.res)
              ?=(%| -.decoded)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-event'))
      ::  200, not 201. A correction mints nothing: the record a person is
      ::  looking at is the record they already had.
      =/  saved=@t
        =/  head  (cat 3 'Corrected ' (cat 3 (scot %tas kind.p.decoded) ' event'))
        ?~  total-mills.p.decoded
          head
        (cat 3 head (cat 3 ' - ' total-display.p.decoded))
      :_  cleared
      (http-give u.eyre-id 200 ['content-type' 'text/plain']~ `(text-octs saved))
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-reminder-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: reminder'))
      =/  decoded  (decode-reminder:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  cleared
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: reminder'))
      ?.  (gte (lent p.res) 2)
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: reminder'))
      =/  vehicles  (rows-at:view p.res 0)
      =/  subtype-rows  (rows-at:view p.res 1)
      ?.  =(1 (lent vehicles))
        :_  cleared
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: reminder.vehicle'))
      =/  found  (row-by-text:view %label subtype-label.p.decoded subtype-rows)
      ?~  found
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: reminder.subtype'))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-reminder-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script=tape
        %:  insert-reminder:act
            (fixture-id:act base 9.601)
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            `@ux`(cell-atom:view %service-subtype-id u.found)
            p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  next-http
        (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
      =/  next-body
        (~(put by (~(del by fill-body-pending) wire)) write-wire u.body)
      :_  this(http-pending next-http, fill-body-pending next-body)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-reminder-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      =/  cleared
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?~  eyre-id
        `cleared
      ?~  body
        :_  cleared
        (restart-http u.eyre-id)
      =/  decoded  (decode-reminder:entry u.body)
      ?:  ?|  ?=(%.n -.res)
              ?=(%| -.decoded)
          ==
        :_  cleared
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: reminder'))
      :_  cleared
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs (cat 3 'Saved reminder - ' subtype-label.p.decoded))
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-consumable-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-consumable:entry u.body)
      =/  next
        this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
      ?:  ?|  ?=(%.n -.res)
              ?=(%| -.decoded)
          ==
        :_  next
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: consumable'))
      =/  proof
        %:  derive-fill-total:act
            quantity-milli.p.decoded
            unit-price-mills.p.decoded
            minor-unit-decimals.p.decoded
            cash-increment-mills.p.decoded
            settlement-mode.p.decoded
        ==
      =/  total
        (format-total:render total-mills.proof currency.p.decoded minor-unit-decimals.p.decoded)
      :_  next
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs (cat 3 'Saved consumable purchase - ' total))
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-bootstrap-probe *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while checking for the Rover database. Obelisk refused the database list query.')
        ==
      =/  exists  (database-present p.res)
      =/  next-wire=path
        ?:  exists
          /rover-bootstrap-starter-check/existing/(scot %da now.bowl)/[u.eyre-id]
        /rover-bootstrap-pour/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        ?:  exists
          !>([%script %rover %vector starter-check:act])
        !>([%script %rover %vector schema-m0:act])
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http, bootstrap-ready %.n)
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while checking for the Rover database. Obelisk did not accept the database list request.')
      ==
    ==
  ::
      [%rover-bootstrap-pour *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while creating the Rover database. Obelisk refused the schema pour.')
        ==
      =/  next-wire=path
        /rover-bootstrap-delay/(scot %da now.bowl)/[u.eyre-id]
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http)
      ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while creating the Rover database. Obelisk did not accept the schema pour.')
      ==
    ==
  ::
      [%rover-bootstrap-starter-check @tas *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  source=@tas  i.t.wire
      ?:  ?=(%.n -.res)
        ?:  =(source %existing)
          =/  next-wire=path
            /rover-http/final/(scot %da now.bowl)/[u.eyre-id]
          =/  jon  !>([%script %rover %vector (ui-view:act ~)])
          =/  next-pending
            (~(put by (~(del by pending) wire)) next-wire u.request-text)
          =/  next-http
            (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
          :_  this(pending next-pending, http-pending next-http)
          :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
              [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
          ==
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while checking starter definitions. Obelisk refused the starter query.')
      ==
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  script  (starter-seed-script p.res base now.bowl)
      ?:  ?&  =(source %existing)
              ?=(^ script)
          ==
        =/  next-wire=path
          /rover-bootstrap-delay/(scot %da now.bowl)/[u.eyre-id]
        =/  next-pending
          (~(put by (~(del by pending) wire)) next-wire u.request-text)
        =/  next-http
          (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
        :_  this(pending next-pending, http-pending next-http)
        ~[[%pass next-wire %arvo %b %wait (add now.bowl ~s1)]]
      =/  next-wire=path
        ?:  ?=(~ script)
          ?:  =(source %existing)
            /rover-http/final/(scot %da now.bowl)/[u.eyre-id]
          /rover-http/bootstrapped/(scot %da now.bowl)/[u.eyre-id]
        /rover-bootstrap-starter-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        ?:  ?=(~ script)
          !>([%script %rover %vector (ui-view:act ~)])
        !>([%script %rover %vector script])
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http, bootstrap-ready ?=(~ script))
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while checking starter definitions. Obelisk did not accept the starter query.')
      ==
    ==
  ::
      [%rover-bootstrap-starter-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  request-text
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Database setup failed while adding starter definitions. Obelisk refused the starter seed.')
        ==
      =/  next-wire=path  /rover-http/bootstrapped/(scot %da now.bowl)/[u.eyre-id]
      =/  jon  !>([%script %rover %vector (ui-view:act ~)])
      =/  next-pending
        (~(put by (~(del by pending) wire)) next-wire u.request-text)
      =/  next-http
        (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
      :_  this(pending next-pending, http-pending next-http, bootstrap-ready %.y)
      :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      ?~  p.sign
        `this
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while adding starter definitions. Obelisk did not accept the starter seed.')
      ==
    ==
  ::
      [%rover-starter-check *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        `this(last `res)
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  script  (starter-seed-script p.res base now.bowl)
      ?:  ?=(~ script)
        `this(last `res, pending (~(del by pending) wire))
      =/  write-wire=path  /rover/starter-write/(scot %da now.bowl)
      =/  jon  !>([%script %rover %vector script])
      =/  next-pending
        (~(put by (~(del by pending) wire)) write-wire 'seed-starters-write')
      :_  this(pending next-pending)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-vehicle-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-vehicle-edit:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: vehicle'))
      =/  vehicles  (rows-at:view p.res 0)
      ?.  =(1 (lent vehicles))
        :_  this
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle'))
      =/  subtype-id=(unit @ux)
        ?~  default-subtype.p.decoded
          ~
        =/  found  (row-by-text:view %label u.default-subtype.p.decoded (rows-at:view p.res 1))
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ default-subtype.p.decoded)
              ?=(~ subtype-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.default-subtype'))
      =/  current-energy-ids=(list @ux)
        %+  turn  (rows-at:view p.res 2)
        |=  row=vector:ast
        `@ux`(cell-atom:view %energy-definition-id row)
      =/  energy-result=(each (list @ux) @t)
        ?~  energy-labels.p.decoded
          [%& current-energy-ids]
        (ids-for-labels:view u.energy-labels.p.decoded (rows-at:view p.res 3) %label %energy-definition-id)
      ?:  ?=(%| -.energy-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.energy-source'))
      =/  resolved-energy-ids=(unit (list @ux))
        ?~  energy-labels.p.decoded
          ~
        `(unique-ids:act p.energy-result)
      =/  default-energy-id=(unit @ux)
        ?~  default-energy.p.decoded
          ~
        =/  found
          (row-by-text:view %label u.default-energy.p.decoded (rows-at:view p.res 3))
        ?~  found
          ~
        ``@ux`(cell-atom:view %energy-definition-id u.found)
      ?:  ?&  ?=(^ default-energy.p.decoded)
              ?|  ?=(~ default-energy-id)
                  ?&  ?=(^ resolved-energy-ids)
                      !(has-id:act u.default-energy-id u.resolved-energy-ids)
                  ==
              ==
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.default-energy-source'))
      =/  current-mode-ids=(list @ux)
        %+  turn  (rows-at:view p.res 4)
        |=  row=vector:ast
        `@ux`(cell-atom:view %mode-id row)
      =/  mode-result=(each (list @ux) @t)
        ?~  driving-mode-labels.p.decoded
          [%& current-mode-ids]
        (ids-for-labels:view u.driving-mode-labels.p.decoded (rows-at:view p.res 5) %label %mode-id)
      ?:  ?=(%| -.mode-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-allowed: vehicle.driving-mode'))
      =/  resolved-mode-ids=(unit (list @ux))
        ?~  driving-mode-labels.p.decoded
          ~
        `(unique-ids:act p.mode-result)
      =/  current-def-rows  (rows-at:view p.res 7)
      =/  current-def  ?=(^ current-def-rows)
      =/  def-consumable-id=(unit @ux)
        ?^  current-def-rows
          ``@ux`(cell-atom:view %consumable-id i.current-def-rows)
        =/  definitions  (rows-at:view p.res 6)
        ?~  definitions
          ~
        ``@ux`(cell-atom:view %consumable-id i.definitions)
      ?:  ?&  ?=(^ def-enabled.p.decoded)
              u.def-enabled.p.decoded
              ?=(~ def-consumable-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.consumable.DEF'))
      =/  write-wire=path  /rover-edit-vehicle-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        !>([%script %rover %vector (update-vehicle-settings:act `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles)) p.decoded subtype-id current-energy-ids resolved-energy-ids default-energy-id current-mode-ids resolved-mode-ids current-def def-consumable-id now.bowl)])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-vehicle-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Saved vehicle settings'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-custom-create *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: custom-field'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Created custom field'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-type-create *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: configuration-type'))
      =/  type=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  message
        ?:(=(%energy type) 'Created energy source type' 'Created driving mode type')
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs message))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-custom-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: custom-field'))
      =/  definitions  (rows-at:view p.res 0)
      ?.  =(1 (lent definitions))
        :_  this
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: custom-field'))
      ?:  ?&  =(%change operation-term)
              ?|  ?=(^ (rows-at:view p.res 1))
                  ?=(^ (rows-at:view p.res 2))
                  ?=(^ (rows-at:view p.res 3))
              ==
          ==
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%immutable: custom-field.content-type - archive and recreate'))
      =/  field-id=@ux
        `@ux`(cell-atom:view %field-id (snag 0 definitions))
      =/  script=tape
        ?:  =(%archive operation-term)
          (archive-custom-field:act field-id)
        =/  decoded  (decode-custom-field-change:entry u.body)
        ?:  ?=(%| -.decoded)
          ~
        (change-custom-field-type:act field-id content-type.p.decoded)
      ?~  script
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: custom-field'))
      =/  write-wire=path
        /rover-custom-write/[operation-term]/(scot %da now.bowl)/[u.eyre-id]
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-custom-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: custom-field'))
      =/  message  ?:(=(%archive operation-term) 'Archived custom field' 'Changed custom field type')
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs message))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
  ::  M7 T8. Phase one of the definition lifecycle. The lookup answered; decide
  ::  whether the write may happen, and build it.
      [%rover-definition-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: definition'))
      =/  decoded
        (decode-definition-lifecycle:entry u.body =(%rename operation-term))
      ?:  ?=(%| -.decoded)
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs (entry-refusal p.decoded)))
      =/  fam  (definition-family-of:act family.p.decoded)
      ?~  fam
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%unknown-family: definition.family'))
      =/  definitions  (rows-at:view p.res 0)
      ?.  =(1 (lent definitions))
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: definition'))
      ::  A rename may not put two rows of one family under one label. The
      ::  label is how every Rover surface names a definition, so a collision
      ::  would leave both rows unaddressable — including the one just renamed.
      ::  Nothing here compares the meaning of the two labels: the app does not
      ::  police whether a rename is a correction or a repurpose.
      ?:  ?&  =(%rename operation-term)
              ?=(^ (rows-at:view p.res 1))
          ==
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%duplicate-label: definition'))
      =/  definition-id=@ux
        `@ux`(cell-atom:view `@tas`id-column.u.fam (snag 0 definitions))
      =/  script=tape
        ?:  =(%rename operation-term)
          (rename-definition:act u.fam definition-id new-label.p.decoded)
        (set-definition-archived:act u.fam definition-id =(%archive operation-term))
      =/  write-wire=path
        /rover-definition-write/[operation-term]/(scot %da now.bowl)/[u.eyre-id]
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-definition-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  operation-term=@tas
        ?~  t.wire
          %unknown
        `@tas`i.t.wire
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: definition'))
      =/  message=@t
        ?:  =(%rename operation-term)   'Renamed definition'
        ?:  =(%archive operation-term)  'Archived definition'
        'Restored definition'
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs message))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-fill-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-fill:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-fill'))
      ?~  p.res
        :_  this
        (http-give u.eyre-id 404 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill'))
      ?.  (gte (lent p.res) 9)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-fill.evidence'))
      =/  rows  (rows-at:view p.res 0)
      ?.  =(1 (lent rows))
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%ambiguous: edit-fill'))
      =/  definition-rows  (rows-at:view p.res 1)
      ?.  =(1 (lent definition-rows))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.definition'))
      =/  definition-row  (snag 0 definition-rows)
      ?.  =(%reservoir (cell-term:view %physical-kind definition-row))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%wrong-kind: edit-fill.definition'))
      =/  station-id=(unit @ux)
        ?~  station-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.station-label.p.decoded (rows-at:view p.res 2))
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.p.decoded)
              ?=(~ station-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.station'))
      =/  additive-proof
        (ids-for-labels:view additive-labels.p.decoded (rows-at:view p.res 3) %label %additive-id)
      ?:  ?=(%| -.additive-proof)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.additives'))
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.subtype-label.p.decoded (rows-at:view p.res 4))
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ subtype-label.p.decoded)
              ?=(~ subtype-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.subtype'))
      =/  mode-id=(unit @ux)
        ?~  driving-mode-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.driving-mode-label.p.decoded (rows-at:view p.res 5))
        ?~  found
          ~
        ``@ux`(cell-atom:view %mode-id u.found)
      ?:  ?&  ?=(^ driving-mode-label.p.decoded)
              ?=(~ mode-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.driving-mode'))
      =/  tag-proof
        (ids-for-labels:view tag-labels.p.decoded (rows-at:view p.res 6) %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.tags'))
      =/  payment-id=(unit @ux)
        ?~  payment-method-label.p.decoded
          ~
        =/  found  (row-by-text:view %label u.payment-method-label.p.decoded (rows-at:view p.res 7))
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.p.decoded)
              ?=(~ payment-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: edit-fill.payment-method'))
      =/  current-odometer-id=(unit @ux)
        ?~  (rows-at:view p.res 8)
          ~
        ``@ux`(cell-atom:view %odometer-id (snag 0 (rows-at:view p.res 8)))
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-edit-fill-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        !>([%script %rover %vector (update-fill:act `@ux`(cell-atom:view %acquisition-id (snag 0 rows)) `@ux`(cell-atom:view %vehicle-id (snag 0 rows)) `@ux`(cell-atom:view %energy-definition-id definition-row) (cell-term:view %quantity-unit definition-row) station-id p.additive-proof subtype-id mode-id p.tag-proof payment-id current-odometer-id (fixture-id:act base 901) p.decoded now.bowl)])
      =/  new-state
        %_  state
          pending  (~(put by (~(del by pending) wire)) write-wire u.body)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-edit-fill-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-fill:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: edit-fill'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: edit-fill'))
      =/  proof
        %:  derive-fill-total:act
            quantity-milli.p.decoded
            unit-price-mills.p.decoded
            minor-unit-decimals.p.decoded
            cash-increment-mills.p.decoded
            settlement-mode.p.decoded
        ==
      =/  total
        %:  format-total:render
            total-mills.proof
            currency.p.decoded
            minor-unit-decimals.p.decoded
        ==
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs (cat 3 'Saved fill changes - ' total)))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-default-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: default-vehicle'))
      =/  vehicles  (rows-at:view p.res 0)
      ?.  =(1 (lent vehicles))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: default-vehicle'))
      =/  write-wire=path  /rover-default-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  write-app-default:act
            `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
            ?=(^ (rows-at:view p.res 1))
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending
            (~(put by (~(del by pending) wire)) write-wire 'set-default-write')
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-default-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: default-vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Saved default vehicle'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-remove-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: remove-vehicle'))
      ?~  p.res
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: remove-vehicle'))
      =/  vehicles  (result-rows:view i.p.res)
      ?.  =(1 (lent vehicles))
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: remove-vehicle'))
      =/  vehicle-id  `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
      =/  defaults  (rows-at:view p.res 1)
      ?:  ?&  ?=(^ defaults)
              =(vehicle-id (cell-atom:view %vehicle-id i.defaults))
          ==
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%default-vehicle: choose a new default before archiving'))
      =/  write-wire=path  /rover-remove-write/(scot %da now.bowl)/[u.eyre-id]
      =/  jon
        !>([%script %rover %vector (archive-vehicle:act vehicle-id)])
      =/  new-state
        %_  state
          pending
            (~(put by (~(del by pending) wire)) write-wire 'remove-vehicle-write')
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-remove-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs '%database-refused: archive-vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs 'Archived vehicle'))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-add-vehicle-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  body  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  body
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      =/  decoded  (decode-new-vehicle:entry u.body)
      ?:  ?=(%| -.decoded)
        :_  this
        (http-give u.eyre-id 400 ['content-type' 'text/plain']~ `(text-octs '%bad-shape: vehicle'))
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: add-vehicle'))
      =/  definitions  (rows-at:view p.res 0)
      =/  modes  (rows-at:view p.res 1)
      =/  primary  (row-by-text:view %label energy-label.p.decoded definitions)
      ?~  primary
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.energy-source'))
      =/  additional-result
        (ids-for-labels:view additional-energy-labels.p.decoded definitions %label %energy-definition-id)
      ?:  ?=(%| -.additional-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.energy-source'))
      =/  mode-result
        (ids-for-labels:view driving-mode-labels.p.decoded modes %label %mode-id)
      ?:  ?=(%| -.mode-result)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.driving-mode'))
      =/  primary-id=@ux  `@ux`(cell-atom:view %energy-definition-id u.primary)
      =/  def-consumable-id=(unit @ux)
        ?:  def-enabled.p.decoded
          =/  def-rows  (rows-at:view p.res 2)
          ?~  def-rows
            ~
          ``@ux`(cell-atom:view %consumable-id i.def-rows)
        ~
      ?:  ?&  def-enabled.p.decoded
              ?=(~ def-consumable-id)
          ==
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%not-found: vehicle.consumable.DEF'))
      =/  definition-ids
        (unique-ids:act [primary-id p.additional-result])
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-add-vehicle-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  insert-vehicle:act
            (fixture-id:act base 401)
            vehicle-label.p.decoded
            primary-id
            definition-ids
            (unique-ids:act p.mode-result)
            def-consumable-id
            def-tank-size.p.decoded
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      =/  new-state
        %_  state
          pending
            (~(put by (~(del by pending) wire)) write-wire vehicle-label.p.decoded)
          http-pending
            (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        ==
      :_  this(state new-state)
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-add-vehicle-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  label  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?~  label
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        :_  this
        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: add-vehicle'))
      :_  this
      (http-give u.eyre-id 201 ['content-type' 'text/plain']~ `(text-octs (cat 3 'Added vehicle - ' u.label)))
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-preference-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by preference-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-preference-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: preference.vehicle')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: preference.vehicle')
        ==
      =/  vehicles  (rows-at:view p.res 0)
      ?.  =(1 (lent vehicles))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: preference.vehicle')
        ==
      =/  vehicle-id=@ux  `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
      =/  preferences  (rows-at:view p.res 1)
      =/  existing  (rows-by:view %vehicle-id vehicle-id preferences)
      =/  write-wire=path  /rover-preference-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  write-preference:act
            vehicle-id
            ?=(^ existing)
            u.input
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), preference-pending (~(put by preference-pending) write-wire u.input))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), preference-pending (~(del by preference-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-preference-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by preference-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-preference-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: preference')
        ==
      =/  mode=@t
        ?~  distance-unit.u.input
          'source-native'
        (scot %tas u.distance-unit.u.input)
      =/  message  (cat 3 'Saved display preference - ' mode)
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), preference-pending (~(del by preference-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-odometer-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by odometer-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-odometer-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: odometer.vehicle')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: odometer.vehicle')
        ==
      =/  rows  (result-rows:view i.p.res)
      ?.  =(1 (lent rows))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: odometer.vehicle')
        ==
      =/  row  (snag 0 rows)
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  write-wire=path  /rover-odometer-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  insert-odometer:act
            (fixture-id:act base 201)
            `@ux`(cell-atom:view %vehicle-id row)
            u.input
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), odometer-pending (~(put by odometer-pending) write-wire u.input))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), odometer-pending (~(del by odometer-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-odometer-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by odometer-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-odometer-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: odometer')
        ==
      =/  reading
        (format-distance:render digits.reading.u.input places.reading.u.input odo-unit.reading.u.input %.n)
      =/  message  (cat 3 'Saved odometer - ' reading)
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), odometer-pending (~(del by odometer-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-charge-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by charge-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-charge-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: charge.definition')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: charge.definition')
        ==
      =/  rows  (result-rows:view i.p.res)
      ?.  =(1 (lent rows))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: charge.definition')
        ==
      =/  row  (snag 0 rows)
      ?.  =(%electricity (cell-term:view %physical-kind row))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%wrong-kind: charge.definition')
        ==
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.u.input
          ~
        =/  subtype
          (row-by-text:view %label u.subtype-label.u.input (rows-at:view p.res 3))
        ?~  subtype
          ~
        ``@ux`(cell-atom:view %subtype-id u.subtype)
      ?:  ?&  ?=(^ subtype-label.u.input)
              ?=(~ subtype-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: charge.subtype')
        ==
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=charge-ids:act
        :*  (fixture-id:act base 301)
            (fixture-id:act base 302)
            (fixture-id:act base 303)
            (fixture-id:act base 304)
            (fixture-id:act base 305)
            (charging-component-ids:act base (lent components.u.input) 310)
        ==
      =/  write-wire=path  /rover-charge-write/(scot %da now.bowl)/[u.eyre-id]
      =/  script
        %:  insert-charge:act
            ids
            `@ux`(cell-atom:view %vehicle-id row)
            `@ux`(cell-atom:view %energy-definition-id row)
            subtype-id
            u.input
            now.bowl
        ==
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), charge-pending (~(put by charge-pending) write-wire u.input))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), charge-pending (~(del by charge-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-charge-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by charge-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-charge-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: charge')
        ==
      =/  delivered-text=@t
        ?~  delivered.u.input
          'Energy delivered not recorded'
        %-  crip
        ;:  weld
          "Energy delivered "
          (trip (format-scaled:render digits.u.delivered.u.input places.u.delivered.u.input %.n))
          " kWh"
        ==
      ::  Only an itemized or receipt-only charge reports a cost. %free and
      ::  %unknown carry no total, so their verdict stays the delivered energy.
      =/  cost-text=@t
        ?-  cost-state.u.input
          %free     ''
          %unknown  ''
          %itemized
            =/  amounts=(list charging-component-amount:rover)
              %+  turn  components.u.input
              |=  row=charging-component-entry:rover
              ^-  charging-component-amount:rover
              [component.row amount-mills.row]
            =/  proof  (derive-charging-total:act amounts)
            =/  total  (format-mills:render total-mills.proof currency.u.input)
            (cat 3 ' - itemized total ' total)
          %receipt-total-only
            ?~  source-total-mills.u.input
              ''
            =/  mills  u.source-total-mills.u.input
            =/  total  (format-mills:render mills currency.u.input)
            (cat 3 ' - receipt total ' total)
        ==
      =/  message  (cat 3 (cat 3 'Saved charge - ' delivered-text) cost-text)
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), charge-pending (~(del by charge-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      ::  M8 import, photo phase one. Obelisk has said which record on this
      ::  ship owns the next photo, which file names are taken, and which
      ::  digests it already holds. The bytes have been riding in the run.
      ::
      ::  This mirrors the attach endpoint's phase one and answers no HTTP
      ::  request: the import holds one connection open for the whole run, and
      ::  it is answered once, when the last photo is done.
      [%rover-import-photo-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  photos.run
        `this(import-run ~)
      =/  photo  i.photos.run
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-24]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  step
        |=  [counted=import-report:rover script=(unit tape)]
        ^-  (quip card _this)
        ?~  script
          (advance run(serial +(serial.run), photos t.photos.run, report counted))
        :_  this(import-run `run(serial +(serial.run), report counted))
        (import-photo-write-cards our.bowl serial.run u.script)
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        %+  step
          %_  report.run
            photos-failed  +(photos-failed.report.run)
            messages
              :_  messages.report.run
              (cat 3 (cat 3 'Photo ' file-name.entry.photo) (cat 3 ': ' detail))
          ==
        ~
      ?:  ?=(%.n -.res)
        (fail 'the database refused the lookup')
      =/  owners  (rows-at:view p.res 0)
      ?.  =(1 (lent owners))
        (fail 'no record on this ship carries the moment it belongs to')
      =/  owner-id=@ux
        `@ux`(cell-atom:view (attachment-owner-column owner.entry.photo) (snag 0 owners))
      =/  vehicle-id=@ux  `@ux`(cell-atom:view %vehicle-id (snag 0 owners))
      =/  stored  (rows-at:view p.res 1)
      =/  content-hash=@t  (hash-octs:files bytes.photo)
      ::  The same rule the attach endpoint follows: identical bytes under a
      ::  name this ship already has reuse the whole reference, and identical
      ::  bytes under a new name get their own reference pointing at the file
      ::  that already holds them. So an archive read twice adds nothing, and
      ::  a photograph the owner filed under two names keeps both.
      =/  same-as
        |=(by-name=? (attachment-match entry.photo content-hash by-name stored))
      =/  same-photo  (same-as %.y)
      =/  same-bytes  (same-as %.n)
      =/  taken=(set @t)
        %-  silt
        %+  turn  stored
        |=(row=vector:ast (cell-text:view %file-name row))
      ?^  same-photo
        =/  existing=@ux  `@ux`(cell-atom:view %attachment-id u.same-photo)
        =/  already
          %+  lien  (rows-at:view p.res 2)
          |=(row=vector:ast =(existing `@ux`(cell-atom:view %attachment-id row)))
        ?:  already
          %+  step
            report.run(photos-already-imported +(photos-already-imported.report.run))
          ~
        %+  step
          report.run
        `(attachment-link:act owner.entry.photo owner-id existing vehicle-id backend.entry.photo now.bowl)
      =/  name=@t  (unique-name:files file-name.entry.photo taken)
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  attachment-id=@ux  (fixture-id:act base 9.202)
      ?^  same-bytes
        =/  ref=attachment-ref:rover
          :*  attachment-id
              backend.entry.photo
              (cell-text:view %locator u.same-bytes)
              content-hash
              p.bytes.photo
              media-type.entry.photo
              name
          ==
        %+  step
          report.run
        `(insert-attachment:act ref owner.entry.photo owner-id vehicle-id now.bowl)
      ::  M8, second leg. The owner answered this question once, for the whole
      ::  batch, and the answer rides on every photo in it. Rover no longer
      ::  puts an imported photograph in Clay by default: on an S3-configured
      ::  ship that put every one of them in the store the owner chose
      ::  against, and taking them back out again is slow.
      ::
      ::  Clay is synchronous, so the file and the reference land in one turn.
      ::  S3 is a round trip, so the bytes go first and the reference waits
      ::  for the bucket. A reference to an object that was never stored would
      ::  be worse than a photograph the report calls failed.
      ?:  =(%s3 backend.entry.photo)
        =/  config  (storage-configuration our.bowl now.bowl)
        ?~  config
          (fail s3-unavailable)
        =/  ref=attachment-ref:rover
          :*  attachment-id
              %s3
              (s3-locator:files bucket.u.config content-hash)
              content-hash
              p.bytes.photo
              media-type.entry.photo
              name
          ==
        =/  put-wire=path  /rover-import-photo-s3-put/(scot %ud serial.run)
        =/  outbound
          %:  s3-request:files
              u.config
              'PUT'
              locator.ref
              media-type.entry.photo
              `bytes.photo
              now.bowl
          ==
        =/  script=tape
          (insert-attachment:act ref owner.entry.photo owner-id vehicle-id now.bowl)
        :_  %=  this
              import-run  `run(serial +(serial.run), report report.run)
              pending     (~(put by pending) put-wire (crip script))
            ==
        [%pass put-wire %arvo %i %request outbound *outbound-config:iris]~
      =/  ref=attachment-ref:rover
        :*  attachment-id
            %clay
            (clay-locator:files attachment-id)
            content-hash
            p.bytes.photo
            media-type.entry.photo
            name
        ==
      =/  script=tape
        (insert-attachment:act ref owner.entry.photo owner-id vehicle-id now.bowl)
      :_  this(import-run `run(serial +(serial.run), report report.run))
      :-  (clay-write-card:files attachment-id media-type.entry.photo bytes.photo)
      (import-photo-write-cards our.bowl serial.run script)
    ::
    ::  M8, fix leg. Obelisk closes every `/server` subscription as soon as it
    ::  has answered, so a kick on this wire is the ordinary end of one query
    ::  and carries no news. Dropping the run on it threw away the eyre-id of
    ::  the person waiting, and with it the remaining photos and the report.
    ::
    ::  A Clay import never noticed, because it finishes inside the same move
    ::  cascade that the kick unwinds behind. An S3 import parks on the bucket,
    ::  the kick lands first, and the answer had nowhere to go. Every other
    ::  import arm already ignores the kick. These two did not.
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      ::  M8 import, photo phase two. The reference and its link landed, or
      ::  the database refused them. Either way the run moves to the next
      ::  photo; one photo that will not store never stops the rest.
      [%rover-import-photo-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  photos.run
        `this(import-run ~)
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  report
        ?:  ?=(%.n -.res)
          %_  report.run
            photos-failed  +(photos-failed.report.run)
            messages
              :_  messages.report.run
              (cat 3 'Photo ' (cat 3 file-name.entry.i.photos.run ': the database refused the reference'))
          ==
        report.run(photos-imported +(photos-imported.report.run))
      =/  next=import-run:rover
        run(serial +(serial.run), photos t.photos.run, report report)
      =/  continued=[(list card) state-24]
        (continue-import state our.bowl next)
      [-.continued this(state +.continued)]
    ::
    ::  The same routine close, on the write wire. See the note above.
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-24]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?:  ?=(%.n -.res)
        (fail 'database lookup refused')
      =/  commands  p.res
      ?-  -.work
        %energy
          ?.  (gte (lent commands) 2)
            (fail 'incomplete energy definition lookup result')
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing label')
          ?^  rows
            =/  subtype-rows  (rows-at:view commands 1)
            =/  ambiguous=?
              %+  lien  subtypes.value.work
              |=  subtype=import-energy-subtype:rover
              (gth (lent (rows-by-text:view %label label.subtype subtype-rows)) 1)
            ?:  ambiguous
              (fail 'ambiguous existing subtype label')
            =/  missing=(list import-energy-subtype:rover)
              %+  skim  subtypes.value.work
              |=  subtype=import-energy-subtype:rover
              ?=(~ (rows-by-text:view %label label.subtype subtype-rows))
            =/  report
              report.run(definitions-reused +(definitions-reused.report.run))
            ?~  missing
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            =/  base=@ux  (cut 7 [0 1] eny.bowl)
            =/  definition-id=@ux
              `@ux`(cell-atom:view %energy-definition-id i.rows)
            =/  script
              (insert-energy-subtypes:imp base definition-id missing now.bowl)
            =/  next
              run(writing %.y, serial +(serial.run), report report)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run script)
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script  (insert-energy:imp base value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %service-subtype
          ?.  (gte (lent commands) 2)
            (fail 'incomplete service subtype lookup result')
          =/  definitions  (rows-at:view commands 0)
          =/  defaults  (rows-at:view commands 1)
          ?:  ?|  (gth (lent definitions) 1)
                  (gth (lent defaults) 1)
              ==
            (fail 'ambiguous existing service subtype label')
          ?^  definitions
            =/  report
              report.run(definitions-reused +(definitions-reused.report.run))
            ?~  default.value.work
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            ?^  defaults
              ?:  (subtype-default-matches:imp u.default.value.work i.defaults)
                =/  reused
                  report(subtype-defaults-reused +(subtype-defaults-reused.report))
                (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report reused))
              =/  conflicted
                %_  report
                  conflicts  +(conflicts.report)
                  messages
                    [(import-detail 'Conflict' work 'default reminder interval differs') messages.report]
                ==
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report conflicted))
            =/  script
              (insert-subtype-default:imp `@ux`(cell-atom:view %service-subtype-id i.definitions) u.default.value.work)
            =/  created
              report(subtype-defaults-created +(subtype-defaults-created.report))
            =/  next  run(writing %.y, serial +(serial.run), report created)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run script)
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script  (insert-service-subtype:imp base value.work now.bowl)
          =/  report
            %_  report.run
              definitions-created  +(definitions-created.report.run)
              subtype-defaults-created
                ?~(default.value.work subtype-defaults-created.report.run +(subtype-defaults-created.report.run))
            ==
          =/  next  run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %simple
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing label')
          ?^  rows
            =/  report
              report.run(definitions-reused +(definitions-reused.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            (insert-simple:imp base kind.work label.value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %consumable-definition
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing consumable label')
          ?^  rows
            =/  report
              report.run(definitions-reused +(definitions-reused.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script  (insert-consumable-definition:imp base value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next  run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %custom-definition
          =/  rows  (rows-at:view commands 0)
          ?:  (gth (lent rows) 1)
            (fail 'ambiguous existing custom field label')
          ?^  rows
            =/  report
              report.run(definitions-reused +(definitions-reused.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script  (insert-custom-definition:imp base value.work now.bowl)
          =/  report
            report.run(definitions-created +(definitions-created.report.run))
          =/  next  run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %place
          =/  places  (rows-at:view commands 0)
          =/  stations  (rows-at:view commands 1)
          ?:  ?|  (gth (lent places) 1)
                  (gth (lent stations) 1)
              ==
            (fail 'ambiguous existing label')
          ?^  stations
            ?~  places
              (fail 'station label exists without the matching place label')
            ?.  =((cell-atom:view %place-id i.places) (cell-atom:view %place-id i.stations))
              (fail 'station label is linked to a different place')
            =/  report
              report.run(places-reused +(places-reused.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  existing-place-id=(unit @ux)
            ?~  places
              ~
            ``@ux`(cell-atom:view %place-id i.places)
          =/  report
            ?^  existing-place-id
              report.run(places-reused +(places-reused.report.run))
            report.run(places-created +(places-created.report.run))
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            %:  insert-place:imp
                base
                value.work
                station-kind.value.work
                existing-place-id
                now.bowl
            ==
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %vehicle
          ?.  (gte (lent commands) 7)
            (fail 'incomplete vehicle lookup result')
          =/  vehicles  (rows-at:view commands 0)
          ?:  (gth (lent vehicles) 1)
            (fail 'ambiguous existing label')
          =/  definitions  (rows-at:view commands 1)
          =/  modes  (rows-at:view commands 2)
          =/  definition-ids  (row-ids:view %energy-definition-id definitions)
          =/  mode-ids  (row-ids:view %mode-id modes)
          =/  consumable-definitions  (rows-at:view commands 5)
          =/  consumable-proof
            (ids-for-labels:view (vehicle-consumable-labels:imp value.work) consumable-definitions %label %consumable-id)
          ?:  ?=(%| -.consumable-proof)
            (fail 'a vehicle consumable definition was not found')
          =/  default-subtype-id=(unit @ux)
            ?~  default-subtype.value.work  ~
            =/  subtype-rows  (rows-at:view commands 6)
            ?.  =(1 (lent subtype-rows))  ~
            ``@ux`(cell-atom:view %subtype-id (snag 0 subtype-rows))
          ?:  ?&  ?=(^ default-subtype.value.work)
                  ?=(~ default-subtype-id)
              ==
            (fail 'vehicle default energy subtype was not found')
          ::  A batch that carries none of a vehicle's fills still creates the
          ::  vehicle, so a later batch meets a vehicle that lacks the energy
          ::  definitions and driving modes its own fills use. Import widens the
          ::  vehicle: it adds those links. It never archives a link and never
          ::  moves vehicle-default-energy-definitions, so a widened vehicle
          ::  keeps the configuration its owner chose. Ruled 2026-08-12 in
          ::  ~/brain/projects/rover/import-gui.md.
          ?^  vehicles
            =/  report
              report.run(vehicles-reused +(vehicles-reused.report.run))
            =/  linked-definitions  (rows-at:view commands 3)
            =/  linked-modes  (rows-at:view commands 4)
            =/  archived-definitions  (archived-link-rows:view linked-definitions)
            =/  archived-modes  (archived-link-rows:view linked-modes)
            =/  script
              %:  widen-import-vehicle:imp
                  `@ux`(cell-atom:view %vehicle-id i.vehicles)
                  definition-ids
                  mode-ids
                  (row-ids:view %energy-definition-id linked-definitions)
                  (row-ids:view %energy-definition-id archived-definitions)
                  (row-ids:view %mode-id linked-modes)
                  (row-ids:view %mode-id archived-modes)
                  specification.value.work
                  now.bowl
              ==
            ?~  script
              (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
            =/  next
              run(writing %.y, serial +(serial.run), report report)
            :_  this(import-run `next)
            (import-write-cards our.bowl serial.run script)
          =/  default
            (row-by-text:view %label default-energy.value.work definitions)
          ?~  default
            (fail 'default energy definition was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            %:  insert-import-vehicle:imp
                base
                value.work
                `@ux`(cell-atom:view %energy-definition-id u.default)
                definition-ids
                mode-ids
                consumable-definitions
                default-subtype-id
                now.bowl
            ==
          =/  report
            report.run(vehicles-created +(vehicles-created.report.run))
          =/  next
            run(writing %.y, serial +(serial.run), report report)
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %fill
          ?.  (gte (lent commands) 1)
            (fail 'incomplete database lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            =/  report
              %_  report.run
                conflicts  +(conflicts.report.run)
                messages
                  [(import-detail 'Conflict' work 'ambiguous provenance') messages.report.run]
              ==
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          ?^  existing
            =/  differences  (existing-main-differences:imp value.work commands)
            ?~  differences
              :_  this
              (import-comparison-cards our.bowl serial.run value.work `@ux`(cell-atom:view %acquisition-id i.existing))
            =/  report
              %_  report.run
                conflicts  +(conflicts.report.run)
                messages
                  [(import-detail 'Conflict' work (join-fields:imp differences)) messages.report.run]
              ==
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  mismatches
            (fill-unit-mismatches:imp distance-unit.work volume-unit.work value.work)
          ?^  mismatches
            (fail (cat 3 'unit mismatch: ' (join-fields:imp mismatches)))
          :_  this
          (import-support-cards our.bowl serial.run value.work)
        ::
        %charge
          ?.  (gte (lent commands) 10)
            (fail 'incomplete charge lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            (fail 'ambiguous existing charge')
          ?^  existing
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run))
          =/  supports  (rows-at:view commands 1)
          ?.  =(1 (lent supports))
            (fail 'charge vehicle or energy definition was not found')
          =/  support  (snag 0 supports)
          ?.  =(%electricity (cell-term:view %physical-kind support))
            (fail 'charge energy definition is not electricity')
          =/  subtype-id=(unit @ux)
            ?~  subtype-label.value.work  ~
            =/  found  (row-by-text:view %label u.subtype-label.value.work (rows-at:view commands 4))
            ?~  found  ~
            ``@ux`(cell-atom:view %subtype-id u.found)
          ?:  ?&  ?=(^ subtype-label.value.work)
                  ?=(~ subtype-id)
              ==
            (fail 'charge subtype was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  ids=charge-ids:act
            :*  (fixture-id:act base 301)
                (fixture-id:act base 302)
                (fixture-id:act base 303)
                (fixture-id:act base 304)
                (fixture-id:act base 305)
                (charging-component-ids:act base (lent components.value.work) 310)
            ==
          =/  script
            %:  insert-charge:act
                ids
                `@ux`(cell-atom:view %vehicle-id support)
                `@ux`(cell-atom:view %energy-definition-id support)
                subtype-id
                value.work
                now.bowl
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %consumable
          ?.  (gte (lent commands) 4)
            (fail 'incomplete consumable lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            (fail 'ambiguous existing consumable acquisition')
          ?^  existing
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run))
          =/  vehicles  (rows-at:view commands 1)
          =/  definitions  (rows-at:view commands 2)
          ?.  ?&  =(1 (lent vehicles))
                  =(1 (lent definitions))
              ==
            (fail 'consumable vehicle or definition was not found')
          =/  station-id=(unit @ux)
            ?~  station-label.value.work  ~
            =/  stations  (rows-at:view commands 3)
            ?.  =(1 (lent stations))  ~
            ``@ux`(cell-atom:view %station-id (snag 0 stations))
          ?:  ?&  ?=(^ station-label.value.work)
                  ?=(~ station-id)
              ==
            (fail 'consumable station was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  acquisition-id  (fixture-id:act base 9.101)
          =/  station-script=tape
            ?~  station-id  ~
            ;:  weld
              " INSERT INTO consumable-acquisition-stations VALUES ("
              (scow %ux acquisition-id)
              ", "
              (scow %ux u.station-id)
              ");"
            ==
          =/  script
            ;:  weld
              %:  insert-consumable:act
                  acquisition-id
                  (fixture-id:act base 9.102)
                  `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
                  `@ux`(cell-atom:view %consumable-id (snag 0 definitions))
                  (cell-term:view %quantity-unit (snag 0 definitions))
                  input.value.work
                  now.bowl
              ==
              station-script
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %odometer
          ?.  (gte (lent commands) 2)
            (fail 'incomplete odometer lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            (fail 'ambiguous existing odometer reading')
          ?^  existing
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run))
          =/  vehicles  (rows-at:view commands 1)
          ?.  =(1 (lent vehicles))
            (fail 'odometer vehicle was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            %:  insert-odometer:act
                (fixture-id:act base 701)
                `@ux`(cell-atom:view %vehicle-id (snag 0 vehicles))
                value.work
                now.bowl
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %event
          ?.  (gte (lent commands) 7)
            (fail 'incomplete event lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            =/  report
              report.run(event-conflicts +(event-conflicts.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          ?^  existing
            =/  report
              report.run(events-already-imported +(events-already-imported.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  input  input.value.work
          =/  event-vehicle-rows  (rows-at:view commands 1)
          ?.  =(1 (lent event-vehicle-rows))
            (fail 'event vehicle was not found')
          =/  event-vehicle-row=vector:ast  (snag 0 event-vehicle-rows)
          =/  station-rows  (rows-at:view commands 2)
          =/  tag-rows  (rows-at:view commands 3)
          =/  payment-rows  (rows-at:view commands 4)
          =/  subtype-rows  (rows-at:view commands 5)
          =/  disposal-rows  (rows-at:view commands 6)
          =/  station-id=(unit @ux)
            ?~  station-label.input
              ~
            =/  found  (row-by-text:view %label u.station-label.input station-rows)
            ?~  found
              ~
            ``@ux`(cell-atom:view %station-id u.found)
          ?:  ?&  ?=(^ station-label.input)
                  ?=(~ station-id)
              ==
            (fail 'event station was not found')
          =/  tag-proof
            (ids-for-labels:view tag-labels.input tag-rows %label %tag-id)
          ?:  ?=(%| -.tag-proof)
            (fail 'an event tag definition was not found')
          =/  subtype-proof
            (ids-for-labels:view subtype-labels.input subtype-rows %label %service-subtype-id)
          ?:  ?=(%| -.subtype-proof)
            (fail 'an event subtype definition was not found')
          =/  disposal-kind-id=(unit @ux)
            ?~  disposal-kind-label.input
              ~
            =/  found  (row-by-text:view %label u.disposal-kind-label.input disposal-rows)
            ?~  found
              ~
            ``@ux`(cell-atom:view %disposal-kind-id u.found)
          ?:  ?&  ?=(^ disposal-kind-label.input)
                  ?=(~ disposal-kind-id)
              ==
            (fail 'event disposal kind was not found')
          =/  payment-id=(unit @ux)
            ?~  payment-method-label.input
              ~
            =/  found  (row-by-text:view %label u.payment-method-label.input payment-rows)
            ?~  found
              ~
            ``@ux`(cell-atom:view %method-id u.found)
          ?:  ?&  ?=(^ payment-method-label.input)
                  ?=(~ payment-id)
              ==
            (fail 'event payment method was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  ids=event-ids:act
            :*  (fixture-id:act base 201)
                (fixture-id:act base 202)
                (fixture-id:act base 203)
                (fixture-id:act base 204)
                (fixture-id:act base 205)
            ==
          =/  command-note=(unit @t)
            ?~  notes.input
              ~
            ?:  (urql-cord-safe:imp u.notes.input)
              ~
            notes.input
          =/  script-input=event-entry:rover
            ?~  command-note
              input
            input(notes `'Rover import note placeholder')
          =/  script
            %:  insert-event:act
                ids
                `@ux`(cell-atom:view %vehicle-id event-vehicle-row)
                station-id
                p.tag-proof
                p.subtype-proof
                disposal-kind-id
                payment-id
                script-input
                now.bowl
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          ?~  command-note
            (import-write-cards our.bowl serial.run script)
          (import-parse-cards our.bowl serial.run script)
        ::
        %reminder
          ?.  (gte (lent commands) 3)
            (fail 'incomplete reminder lookup result')
          =/  existing  (rows-at:view commands 0)
          ?:  (gth (lent existing) 1)
            (fail 'ambiguous existing reminder')
          ?^  existing
            =/  report
              report.run(reminders-already-imported +(reminders-already-imported.report.run))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
          =/  reminder-vehicle-rows  (rows-at:view commands 1)
          =/  subtypes  (rows-at:view commands 2)
          ?.  =(1 (lent reminder-vehicle-rows))
            (fail 'reminder vehicle was not found')
          =/  reminder-vehicle-row=vector:ast  (snag 0 reminder-vehicle-rows)
          =/  found  (row-by-text:view %label subtype-label.value.work subtypes)
          ?~  found
            (fail 'reminder subtype was not found')
          =/  base=@ux  (cut 7 [0 1] eny.bowl)
          =/  script
            %:  insert-reminder:act
                (fixture-id:act base 601)
                `@ux`(cell-atom:view %vehicle-id reminder-vehicle-row)
                `@ux`(cell-atom:view %service-subtype-id u.found)
                value.work
                now.bowl
            ==
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
        ::
        %archive
          =/  rows  (rows-at:view commands 0)
          ?.  =(1 (lent rows))
            (fail 'archive target was not found')
          =/  row  (snag 0 rows)
          ?:  =(0 (cell-atom:view %archived row))
            (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run))
          =/  script  (archive-import-script:imp value.work row)
          =/  next  run(writing %.y, serial +(serial.run))
          :_  this(import-run `next)
          (import-write-cards our.bowl serial.run script)
      ==
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-comparison *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-24]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?.  =(%fill -.work)
        (fail 'internal comparison lookup mismatch')
      =/  fill  (fill-work-value:imp work)
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        (fail 'database comparison lookup refused')
      ?.  (gte (lent p.res) 6)
        (fail 'incomplete database comparison lookup result')
      =/  differences  (existing-child-differences:imp fill p.res)
      ?~  differences
        ?~  t.wire
          (fail 'comparison wire omitted the acquisition id')
        :_  this
        =/  existing-id  (slaw %ux i.t.wire)
        ?>  ?=(^ existing-id)
        (import-comparison-tail-cards our.bowl serial.run fill u.existing-id)
      =/  report
        %_  report.run
          conflicts  +(conflicts.report.run)
          messages
            [(import-detail 'Conflict' work (join-fields:imp differences)) messages.report.run]
        ==
      (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-comparison-tail *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-24]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?.  =(%fill -.work)
        (fail 'internal comparison-tail lookup mismatch')
      =/  fill  (fill-work-value:imp work)
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        (fail 'database comparison-tail lookup refused')
      ?.  (gte (lent p.res) 5)
        (fail 'incomplete database comparison-tail lookup result')
      =/  differences  (existing-tail-differences:imp fill p.res)
      ?~  differences
        =/  report
          report.run(already-imported +(already-imported.report.run))
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      =/  report
        %_  report.run
          conflicts  +(conflicts.report.run)
          messages
            [(import-detail 'Conflict' work (join-fields:imp differences)) messages.report.run]
        ==
      (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-support *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance
        |=  next=import-run:rover
        ^-  (quip card _this)
        =/  continued=[(list card) state-24]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  fail
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        (advance run(writing %.n, serial +(serial.run), remaining t.remaining.run, report report))
      ?.  =(%fill -.work)
        (fail 'internal support lookup mismatch')
      =/  fill  (fill-work-value:imp work)
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?:  ?=(%.n -.res)
        (fail 'database support lookup refused')
      =/  commands  p.res
      ?.  (gte (lent commands) 8)
        (fail 'incomplete database support lookup result')
      =/  input  (canonical-fill:imp input.fill)
      =/  supports  (rows-at:view commands 0)
      ?.  =(1 (lent supports))
        (fail 'vehicle or energy definition was not found')
      =/  support  (snag 0 supports)
      ?.  =(%reservoir (cell-term:view %physical-kind support))
        (fail 'energy definition is not a reservoir fuel')
      =/  quantity-unit  (cell-term:view %quantity-unit support)
      ?.  =((fill-volume-unit:imp price-profile.input) quantity-unit)
        (fail 'fill profile and energy quantity unit differ')
      =/  station-rows  (rows-at:view commands 1)
      =/  station-id=(unit @ux)
        ?~  station-label.input
          ~
        =/  found
          (row-by-text:view %label u.station-label.input station-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.input)
              ?=(~ station-id)
          ==
        (fail 'station was not found')
      =/  additive-proof
        (ids-for-labels:view additive-labels.input (rows-at:view commands 2) %label %additive-id)
      ?:  ?=(%| -.additive-proof)
        (fail 'an additive definition was not found')
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.input
          ~
        =/  found
          (row-by-text:view %label u.subtype-label.input (rows-at:view commands 3))
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ subtype-label.input)
              ?=(~ subtype-id)
          ==
        (fail 'energy subtype was not found')
      =/  driving-mode-id=(unit @ux)
        ?~  driving-mode-label.input
          ~
        =/  found
          (row-by-text:view %label u.driving-mode-label.input (rows-at:view commands 4))
        ?~  found
          ~
        ``@ux`(cell-atom:view %mode-id u.found)
      ?:  ?&  ?=(^ driving-mode-label.input)
              ?=(~ driving-mode-id)
          ==
        (fail 'driving mode was not linked to the vehicle')
      =/  tag-proof
        (ids-for-labels:view tag-labels.input (rows-at:view commands 5) %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        (fail 'a tag definition was not found')
      =/  payment-method-id=(unit @ux)
        ?~  payment-method-label.input
          ~
        =/  found
          (row-by-text:view %label u.payment-method-label.input (rows-at:view commands 6))
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.input)
              ?=(~ payment-method-id)
          ==
        (fail 'payment method was not found')
      =/  custom-definitions  (rows-at:view commands 7)
      =/  custom-missing=?
        %+  lien  custom-values.fill
        |=  value=import-custom-value:rover
        =/  found  (row-by-text:view %label label.value custom-definitions)
        ?~  found  %.y
        !=(content-type.value (cell-term:view %content-type u.found))
      ?:  custom-missing
        (fail 'a custom field definition was not found or changed type')
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=entry-ids:act
        :*  (fixture-id:act base 101)
            (fixture-id:act base 102)
            (fixture-id:act base 103)
            (fixture-id:act base 104)
            (fixture-id:act base 105)
        ==
      =/  command-note=(unit @t)
        ?~  notes.input
          ~
        ?:  (urql-cord-safe:imp u.notes.input)
          ~
        notes.input
      =/  script-input=fill-entry:rover
        ?~  command-note
          input
        input(notes `'Rover import note placeholder')
      =/  script
        ;:  weld
          %:  insert-import-fill:imp
              ids
              `@ux`(cell-atom:view %vehicle-id support)
              `@ux`(cell-atom:view %energy-definition-id support)
              quantity-unit
              station-id
              p.additive-proof
              subtype-id
              driving-mode-id
              p.tag-proof
              payment-method-id
              script-input
              source-app.fill
              source-record-id.fill
              now.bowl
          ==
          (insert-import-custom-values:imp acquisition.ids custom-values.fill custom-definitions)
        ==
      =/  next
        run(writing %.y, serial +(serial.run))
      :_  this(import-run `next)
      ?~  command-note
        (import-write-cards our.bowl serial.run script)
      (import-parse-cards our.bowl serial.run script)
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-import-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  run-unit  import-run
      ?~  run-unit
        `this
      =/  run  u.run-unit
      ?~  remaining.run
        `this(import-run ~)
      =/  work  i.remaining.run
      =/  advance-failure
        |=  detail=@t
        ^-  (quip card _this)
        =/  report
          %_  report.run
            failures  +(failures.report.run)
            messages  [(import-detail 'Failure' work detail) messages.report.run]
          ==
        =/  next
          run(writing %.n, remaining t.remaining.run, report report)
        =/  continued=[(list card) state-24]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  phase=@ta
        ?~  t.wire
          %script
        i.t.wire
      ?:  =(%parse phase)
        =/  parsed  ;;((each (list command:ast) tang) +.q.cage.sign)
        ?:  ?=(%.n -.parsed)
          (advance-failure 'atomic database mutation parse refused')
        =/  patched
          ?-  -.work
            %fill
              =/  fill  (fill-work-value:imp work)
              (replace-fill-note:imp p.parsed (need notes.input.fill))
            %event
              (replace-event-note:imp p.parsed (need notes.input.value.work))
            %energy           !!
            %service-subtype  !!
            %simple           !!
            %place            !!
            %vehicle          !!
            %reminder         !!
            %consumable-definition  !!
            %custom-definition      !!
            %charge                 !!
            %consumable             !!
            %odometer               !!
            %archive                !!
          ==
        ?:  ?=(%| -.patched)
          (advance-failure p.patched)
        :_  this
        (import-command-write-cards our.bowl serial.run p.patched)
      ?:  =(%cmd-list phase)
        =/  report
          ?-  -.work
            %fill
              report.run(imported +(imported.report.run))
            %event
              report.run(events-imported +(events-imported.report.run))
            %reminder
              report.run(reminders-imported +(reminders-imported.report.run))
            %energy           report.run
            %service-subtype  report.run
            %simple           report.run
            %place            report.run
            %vehicle          report.run
            %consumable-definition  report.run
            %custom-definition      report.run
            %charge                 report.run
            %consumable             report.run
            %odometer               report.run
            %archive                report.run
          ==
        =/  next
          run(writing %.n, remaining t.remaining.run, report report)
        =/  continued=[(list card) state-24]
          (continue-import state our.bowl next)
        [-.continued this(state +.continued)]
      =/  res  ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  report
        ?:  ?=(%.n -.res)
          %_  report.run
            failures  +(failures.report.run)
            messages
              [(import-detail 'Failure' work 'atomic database mutation refused') messages.report.run]
          ==
        ?-  -.work
          %fill
            report.run(imported +(imported.report.run))
          %event
            report.run(events-imported +(events-imported.report.run))
          %reminder
            report.run(reminders-imported +(reminders-imported.report.run))
          %energy           report.run
          %service-subtype  report.run
          %simple           report.run
          %place            report.run
          %vehicle          report.run
          %consumable-definition  report.run
          %custom-definition      report.run
          %charge                 report.run
          %consumable             report.run
          %odometer               report.run
          %archive                report.run
        ==
      =/  next
        run(writing %.n, remaining t.remaining.run, report report)
      =/  continued=[(list card) state-24]
        (continue-import state our.bowl next)
      [-.continued this(state +.continued)]
    ::
        %kick
      `this
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-fill-lookup *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by fill-pending) wire)
      =/  body  (~(get by fill-body-pending) wire)
      ?~  eyre-id
        `this
      ?:  ?|  ?=(~ input)
              ?=(~ body)
          ==
        :_  %_  this
              http-pending  (~(del by http-pending) wire)
              fill-pending  (~(del by fill-pending) wire)
              fill-body-pending  (~(del by fill-body-pending) wire)
            ==
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-fill-lookup-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: fill.definition')
        ==
      ?~  p.res
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.definition')
        ==
      =/  rows  (result-rows:view i.p.res)
      ?.  =(1 (lent rows))
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%ambiguous: fill.definition')
        ==
      =/  row  (snag 0 rows)
      =/  kind  (cell-term:view %physical-kind row)
      =/  quantity-unit  (cell-term:view %quantity-unit row)
      ?.  =(%reservoir kind)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%wrong-kind: fill.definition')
        ==
      =/  expected-unit=@tas
        ?:  =(%us-usd-gal price-profile.u.input)
          %gal
        %litre
      ?.  =(expected-unit quantity-unit)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%unit-mismatch: fill.profile')
        ==
      ?.  (gte (lent p.res) 9)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: fill.evidence')
        ==
      =/  station-rows  (rows-at:view p.res 1)
      =/  additive-rows  (rows-at:view p.res 2)
      =/  subtype-rows  (rows-at:view p.res 3)
      =/  driving-mode-rows  (rows-at:view p.res 5)
      =/  tag-rows  (rows-at:view p.res 6)
      =/  custom-rows  (rows-at:view p.res 7)
      =/  payment-rows  (rows-at:view p.res 8)
      =/  station-id=(unit @ux)
        ?~  station-label.u.input
          ~
        =/  found  (row-by-text:view %label u.station-label.u.input station-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %station-id u.found)
      ?:  ?&  ?=(^ station-label.u.input)
              ?=(~ station-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.station')
        ==
      =/  additive-proof
        (ids-for-labels:view additive-labels.u.input additive-rows %label %additive-id)
      ?:  ?=(%| -.additive-proof)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.additives')
        ==
      =/  subtype-id=(unit @ux)
        ?~  subtype-label.u.input
          ~
        =/  found
          (row-by-text:view %label u.subtype-label.u.input subtype-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %subtype-id u.found)
      ?:  ?&  ?=(^ subtype-label.u.input)
              ?=(~ subtype-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.subtype')
        ==
      =/  driving-mode-id=(unit @ux)
        ?~  driving-mode-label.u.input
          ~
        =/  found
          (row-by-text:view %label u.driving-mode-label.u.input driving-mode-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %mode-id u.found)
      ?:  ?&  ?=(^ driving-mode-label.u.input)
              ?=(~ driving-mode-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.driving-mode')
        ==
      =/  tag-proof
        (ids-for-labels:view tag-labels.u.input tag-rows %label %tag-id)
      ?:  ?=(%| -.tag-proof)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.tags')
        ==
      =/  payment-method-id=(unit @ux)
        ?~  payment-method-label.u.input
          ~
        =/  found
          (row-by-text:view %label u.payment-method-label.u.input payment-rows)
        ?~  found
          ~
        ``@ux`(cell-atom:view %method-id u.found)
      ?:  ?&  ?=(^ payment-method-label.u.input)
              ?=(~ payment-method-id)
          ==
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%not-found: fill.payment-method')
        ==
      ?:  ?&  ?=(^ new-tag-label.u.input)
              ?=(^ (row-by-text:view %label u.new-tag-label.u.input tag-rows))
          ==
        :_  this
        %:  http-give
            u.eyre-id
            409
            ['content-type' 'text/plain']~
            `(text-octs '%already-exists: fill.new-tag')
        ==
      =/  base=@ux  (cut 7 [0 1] eny.bowl)
      =/  ids=entry-ids:act
        :*  (fixture-id:act base 101)
            (fixture-id:act base 102)
            (fixture-id:act base 103)
            (fixture-id:act base 104)
            (fixture-id:act base 105)
        ==
      =/  object  (need (json-object:entry u.body))
      =/  custom-script
        =/  build
          |=  rows=(list vector:ast)
          ^-  (each tape @t)
          ?~  rows
            [%& ~]
          =/  archived  =(0 (cell-atom:view %archived i.rows))
          ?:  archived
            $(rows t.rows)
          =/  label  (cell-text:view %label i.rows)
          =/  key  (cat 3 'custom-' label)
          =/  value-unit  (json-string:entry key object)
          =/  value=@t  ?~(value-unit '' u.value-unit)
          =/  mandatory  =(0 (cell-atom:view %mandatory i.rows))
          ?:  ?&  mandatory
                  !(nonempty:entry value)
              ==
            [%| label]
          ?.  (nonempty:entry value)
            $(rows t.rows)
          =/  content  (cell-term:view %content-type i.rows)
          =/  row-script=tape
            ?+  content  ~
              %text
                (insert-custom-text:act `@ux`(cell-atom:view %field-id i.rows) acquisition.ids value)
              %boolean
                (insert-custom-boolean:act `@ux`(cell-atom:view %field-id i.rows) acquisition.ids =('yes' value))
              %number
                =/  number  (parse-decimal:render value 3)
                ?:  ?=(%| -.number)
                  ~
                %:  insert-custom-number:act
                    `@ux`(cell-atom:view %field-id i.rows)
                    acquisition.ids
                    digits.p.number
                    places.p.number
                ==
            ==
          ?:  ?&  =(%number content)
                  ?=(~ row-script)
              ==
            [%| label]
          =/  rest  $(rows t.rows)
          ?:  ?=(%| -.rest)
            rest
          [%& (weld row-script p.rest)]
        (build custom-rows)
      ?:  ?=(%| -.custom-script)
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs (cat 3 '%mandatory-or-invalid: custom-field.' p.custom-script))
        ==
      =/  write-wire=path
        /rover-fill-write/(scot %da now.bowl)/[u.eyre-id]
      =/  fill-script
        %:  insert-fill:act
            ids
            `@ux`(cell-atom:view %vehicle-id row)
            `@ux`(cell-atom:view %energy-definition-id row)
            quantity-unit
            station-id
            p.additive-proof
            subtype-id
            driving-mode-id
            p.tag-proof
            payment-method-id
            u.input
            now.bowl
        ==
      =/  script  (weld fill-script p.custom-script)
      =/  jon  !>([%script %rover %vector script])
      :_  this(http-pending (~(put by http-pending) write-wire u.eyre-id), fill-pending (~(put by fill-pending) write-wire u.input), fill-body-pending (~(put by fill-body-pending) write-wire u.body))
      :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
          [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-pending (~(del by fill-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-fill-write *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  input  (~(get by fill-pending) wire)
      ?~  eyre-id
        `this
      ?~  input
        :_  this(http-pending (~(del by http-pending) wire))
        (restart-http u.eyre-id)
      ?:  ?=(%.n -.res)
        ~&  [%rover-fill-write-refused p.res]
        :_  this
        %:  http-give
            u.eyre-id
            422
            ['content-type' 'text/plain']~
            `(text-octs '%database-refused: fill')
        ==
      =/  proof
        %:  derive-fill-total:act
            quantity-milli.u.input
            unit-price-mills.u.input
            minor-unit-decimals.u.input
            cash-increment-mills.u.input
            settlement-mode.u.input
        ==
      =/  total-display
        %:  format-total:render
            total-mills.proof
            currency.u.input
            minor-unit-decimals.u.input
        ==
      =/  message
        %-  crip
        ;:  weld
          "Saved fill - "
          (trip price-display.u.input)
          " - derived "
          (trip total-display)
        ==
      :_  this
      %:  http-give
          u.eyre-id
          201
          ['content-type' 'text/plain']~
          `(text-octs message)
      ==
    ::
        %kick
      `this(http-pending (~(del by http-pending) wire), fill-pending (~(del by fill-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover-http @tas *]
    =/  mode=@tas  i.t.wire
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      =/  eyre-id  (~(get by http-pending) wire)
      =/  request-text  (~(get by pending) wire)
      ?~  eyre-id
        `this
      ?:  ?=(%.n -.res)
        ~&  [%rover-ui-view-refused p.res]
        ?:  =(mode %recover)
          ?~  request-text
            :_  this(http-pending (~(del by http-pending) wire))
            (restart-http u.eyre-id)
          =/  next-wire=path
            /rover-bootstrap-probe/(scot %da now.bowl)/[u.eyre-id]
          =/  jon  !>([%script %sys %vector database-list:act])
          =/  next-pending
            (~(put by (~(del by pending) wire)) next-wire u.request-text)
          =/  next-http
            (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
          :_  this(pending next-pending, http-pending next-http)
          :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
              [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
          ==
        :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
        %:  http-give
            u.eyre-id
            503
            ['content-type' 'text/plain']~
            `(text-octs 'Rover could not load the vehicle log. Obelisk refused the view query.')
        ==
      =/  history-page=@ud
        ?~  request-text
          0
        =/  request-object  (json-object:entry u.request-text)
        =/  page-text=@t
          ?~  request-object
            u.request-text
          =/  page-value  (json-string:entry 'page' u.request-object)
          ?~(page-value '0' u.page-value)
        =/  parsed  (slaw %ud page-text)
        ?~(parsed 0 u.parsed)
      =/  selected-label=(unit @t)
        ?~  request-text
          ~
        =/  request-object  (json-object:entry u.request-text)
        ?~  request-object
          ~
        (json-string:entry 'vehicle' u.request-object)
      =/  headers=header-list:http
        ?:  =(mode %bootstrapped)
          :~  ['content-type' 'text/html']
              ['x-rover-bootstrap' 'performed']
          ==
        ['content-type' 'text/html']~
      :_  this(bootstrap-ready %.y)
      %:  http-give
          u.eyre-id
          200
          headers
          `(as-octs:mimes:html (page:view our.bowl now.bowl history-page selected-label p.res (s3-configured our.bowl now.bowl)))
      ==
    ::
        %kick
      `this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
    ::
        %watch-ack
      `this
    ==
  ::
      [%rover *]
    ?+  -.sign  (on-agent:def wire sign)
        %fact
      =/  res
        ;;((each (list cmd-result:ast) tang) +.q.cage.sign)
      ?.  ?=(%.n -.res)
        `this(last `res)
      ~&  "{<(slog p.res)>}"
      `this(last `res)
    ::
        %kick
      `this(pending (~(del by pending) wire))
    ::
        %watch-ack
      `this
    ==
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
      [%x %last ~]
    ``noun+!>(last)
  ::
      [%x %preview ~]
    ``noun+!>(preview)
  ::
      [%x %total ~]
    ``noun+!>(total)
  ::
      [%x %charging-total ~]
    ``noun+!>(charging-total)
  ::
      [%x %integrity ~]
    ``noun+!>(integrity)
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  ?=([%http-response @ ~] path)
  `this
::
++  on-leave
  |=  =path
  ^-  (quip card _this)
  ?>  ?=([%http-response @ ~] path)
  `this
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ::  M8. The bucket answered a PUT. Only now does the reference go in.
  ?:  ?=([%rover-attachment-s3-put *] wire)
    ?.  ?=([%iris %http-response *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    =/  eyre-id  (~(get by http-pending) wire)
    =/  waiting  (~(get by attachment-pending) wire)
    =/  vehicle  (~(get by pending) wire)
    =/  cleared=_this
      %=  this
        http-pending        (~(del by http-pending) wire)
        attachment-pending  (~(del by attachment-pending) wire)
        pending             (~(del by pending) wire)
      ==
    ?~  eyre-id
      `cleared
    ?~  waiting
      :_  cleared
      (restart-http u.eyre-id)
    ?~  vehicle
      [(restart-http u.eyre-id) cleared]
    =/  vehicle-id=@ux  (slav %ux u.vehicle)
    ?.  ?=(%finished -.client-response.sign-arvo)
      `this
    =/  status  status-code.response-header.client-response.sign-arvo
    ?.  ?|(=(200 status) =(204 status))
      :_  cleared
      %:  http-give
          u.eyre-id
          502
          ['content-type' 'text/plain']~
          `(text-octs (s3-refusal status))
      ==
    =/  write  u.waiting
    =/  config  (storage-configuration our.bowl now.bowl)
    ?~  config
      :_  cleared
      (http-give u.eyre-id 409 ['content-type' 'text/plain']~ `(text-octs storage-unconfigured))
    =/  ref=attachment-ref:rover
      :*  attachment-id.write
          %s3
          (s3-locator:files bucket.u.config content-hash.write)
          content-hash.write
          p.bytes.write
          media-type.entry.write
          stored-name.write
      ==
    =/  write-wire=path  /rover-attachment-write/(scot %da now.bowl)/[u.eyre-id]
    =/  script=tape
      (insert-attachment:act ref owner.entry.write owner-id.write vehicle-id now.bowl)
    =/  jon  !>([%script %rover %vector script])
    =/  next=_this
      %=  cleared
        http-pending  (~(put by (~(del by http-pending) wire)) write-wire u.eyre-id)
        pending       (~(put by pending.cleared) write-wire stored-name.write)
      ==
    :_  next
    :~  [%pass write-wire %agent [our.bowl %obelisk] %watch /server]
        [%pass write-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ::  M8, second leg. The bucket took an IMPORTED photo. The insert script was
  ::  written before the PUT went out and waited on this wire, so the reference
  ::  lands only after the bytes really did.
  ?:  ?=([%rover-import-photo-s3-put *] wire)
    ?.  ?=([%iris %http-response *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    =/  waiting  (~(get by pending) wire)
    =/  bare=state-24  state(pending (~(del by pending) wire))
    =/  run-unit  import-run
    ?~  run-unit
      `this(state bare)
    =/  run  u.run-unit
    ?~  photos.run
      `this(state bare(import-run ~))
    ::  More bytes are still on the way. Wait for the end of the answer.
    ?:  ?=(%progress -.client-response.sign-arvo)
      `this
    ::  A request the runtime gave up on reads as status zero, which
    ::  `s3-refusal` says in words. Treating it as one refused photograph is
    ::  what keeps the person from watching a browser tab that never returns.
    =/  status=@ud
      ?.  ?=(%finished -.client-response.sign-arvo)  0
      status-code.response-header.client-response.sign-arvo
    =/  stored=?  ?&(?=(^ waiting) ?|(=(200 status) =(204 status)))
    ::  A bucket that refuses fails ONE photograph. The rest of the batch
    ::  still runs, and the report names the one that did not store.
    ?.  stored
      =/  report
        %_  report.run
          photos-failed  +(photos-failed.report.run)
          messages
            :_  messages.report.run
            %^    cat
                3
              (cat 3 'Photo ' file-name.entry.i.photos.run)
            (cat 3 ': ' (s3-refusal status))
        ==
      =/  continued=[(list card) state-24]
        %:  continue-import
            bare
            our.bowl
            run(serial +(serial.run), photos t.photos.run, report report)
        ==
      [-.continued this(state +.continued)]
    :_  this(state bare(import-run `run(serial +(serial.run))))
    (import-photo-write-cards our.bowl serial.run (trip (need waiting)))
  ::  M8. The bucket answered an export fetch. One more member, then the walk
  ::  continues where it stopped.
  ?:  ?=([%rover-export-fetch *] wire)
    ?.  ?=([%iris %http-response *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    =/  run-unit  export-run
    ?~  run-unit
      `this
    ?.  ?=(%finished -.client-response.sign-arvo)
      `this
    =/  run  u.run-unit
    ?~  remaining.run
      `this(export-run ~)
    =/  ref  i.remaining.run
    =/  status  status-code.response-header.client-response.sign-arvo
    =/  body  full-file.client-response.sign-arvo
    ?.  ?&  =(200 status)
            ?=(^ body)
        ==
      :_  this(export-run ~)
      %:  http-give
          eyre-id.run
          502
          ['content-type' 'text/plain']~
          `(text-octs (cat 3 'The export stopped: the S3 storage would not return ' file-name.ref))
      ==
    =/  next=export-run:rover
      %=  run
        remaining  t.remaining.run
        members    [[file-name.ref data.u.body] members.run]
      ==
    =/  continued=[(list card) state-24]
      (continue-export state our.bowl now.bowl next)
    [-.continued this(state +.continued)]
  ::  M8. The bucket answered a GET. The ship hands the bytes on itself.
  ?:  ?=([%rover-attachment-s3-get *] wire)
    ?.  ?=([%iris %http-response *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    =/  eyre-id  (~(get by http-pending) wire)
    =/  media-type  (~(get by pending) wire)
    =/  cleared=_this
      this(http-pending (~(del by http-pending) wire), pending (~(del by pending) wire))
    ?~  eyre-id
      `cleared
    ?.  ?=(%finished -.client-response.sign-arvo)
      `this
    =/  status  status-code.response-header.client-response.sign-arvo
    =/  body  full-file.client-response.sign-arvo
    ?.  ?&  =(200 status)
            ?=(^ body)
        ==
      :_  cleared
      %:  http-give
          u.eyre-id
          502
          ['content-type' 'text/plain']~
          `(text-octs (s3-refusal status))
      ==
    :_  cleared
    %:  http-give
        u.eyre-id
        200
        ['content-type' ?~(media-type 'application/octet-stream' u.media-type)]~
        `data.u.body
    ==
  ?:  ?=([%rover-energy-odometer-precheck-delay *] wire)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      `this(pending (~(del by pending) wire))
    =/  next-wire=path
      /rover-energy-odometer-precheck/(scot %da now.bowl)
    :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
    (obelisk-script-cards our.bowl next-wire energy-odometer-migration-check:act)
  ?:  ?=([%rover-energy-odometer-drop-delay *] wire)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      `this(pending (~(del by pending) wire))
    =/  next-wire=path
      /rover-energy-odometer-drop/(scot %da now.bowl)
    :_  this(pending (~(put by (~(del by pending) wire)) next-wire 'ensure-def-schema'))
    (obelisk-script-cards our.bowl next-wire energy-odometer-drop-old:act)
  ?:  ?=([%rover-install-delay *] wire)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      `this
    =/  next-wire=path  /rover-install-starter-check/(scot %da now.bowl)
    =/  jon  !>([%script %rover %vector starter-check:act])
    :_  this
    :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
        [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ?:  ?=([%rover-bootstrap-delay *] wire)
    =/  eyre-id  (~(get by http-pending) wire)
    =/  request-text  (~(get by pending) wire)
    ?~  eyre-id
      `this
    ?~  request-text
      :_  this(http-pending (~(del by http-pending) wire))
      (restart-http u.eyre-id)
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo
      :_  this(pending (~(del by pending) wire), http-pending (~(del by http-pending) wire))
      %:  http-give
          u.eyre-id
          503
          ['content-type' 'text/plain']~
          `(text-octs 'Database setup failed while waiting to add starter definitions. The system timer refused the request.')
      ==
    =/  next-wire=path
      /rover-bootstrap-starter-check/created/(scot %da now.bowl)/[u.eyre-id]
    =/  jon  !>([%script %rover %vector starter-check:act])
    =/  next-pending
      (~(put by (~(del by pending) wire)) next-wire u.request-text)
    =/  next-http
      (~(put by (~(del by http-pending) wire)) next-wire u.eyre-id)
    :_  this(pending next-pending, http-pending next-http)
    :~  [%pass next-wire %agent [our.bowl %obelisk] %watch /server]
        [%pass next-wire %agent [our.bowl %obelisk] %poke %obelisk-action jon]
    ==
  ::  M8. Clay answered the merge that creates the attachment desk, or the
  ::  commit that wrote one photo into it. Neither answer carries a decision.
  ::  The desk exists after the merge and the reference row is what proves the
  ::  write; a photo Clay refused reads back absent, and the serve path already
  ::  reports that. Without these two arms the merge answer falls through to
  ::  the Eyre assertion below and every install prints `%arvo-response`.
  ?:  ?=([%rover-files-desk *] wire)
    `this
  ?:  ?=([%rover-files-write *] wire)
    `this
  ?>  ?=([%eyre %connect ~] wire)
  ?>  ?=([%eyre %bound *] sign-arvo)
  ~?  !accepted.sign-arvo  [%rover %eyre-bind-refused]
  `this
++  on-fail   on-fail:def
--
