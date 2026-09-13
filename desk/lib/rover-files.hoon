::  lib/rover-files - attachment bytes, the container, and the digests.
::
::  M8, ruling 17. The blobs never enter Obelisk. This library is the only place
::  in Rover that touches attachment BYTES: it writes them to a storage backend,
::  reads them back, proves they did not change, and packs them into the export
::  container. Nothing here builds a urQL statement.
::
::  The bytes that arrive are the bytes that are stored. No re-encode, no
::  normalize, no EXIF strip - that rule governs publication, not the owner's
::  own storage.
::
/-  rover
|%
::  The Clay desk that holds the owner's attachments.
::
::  NOT the %rover desk. %rover is published and installed on other ships, and
::  a published desk carrying the owner's receipts would ship them to every
::  installer. This desk is created on the ship and never published.
++  files-desk  `desk`%rover-files
::
::  Where one attachment lives inside Clay. The machine id is the path element
::  because Clay needs a stable, collision-free knot and a file name is neither;
::  this path is a locator held in the database, not a name shown to a person.
++  clay-path
  |=  attachment-id=@ux
  ^-  path
  /attachments/[(scot %ux attachment-id)]/mime
::
++  clay-locator
  |=  attachment-id=@ux
  ^-  @t
  (spat (clay-path attachment-id))
::
::  Create the attachment desk if the ship has none. Merging from %base is what
::  gives the desk its marks, and a Clay commit cannot store a cage whose mark
::  the desk cannot build.
++  ensure-files-desk
  |=  [our=@p now=@da]
  ^-  (list card:agent:gall)
  =/  desks  .^((set desk) %cd /(scot %p our)//(scot %da now))
  ?:  (~(has in desks) files-desk)
    ~
  :_  ~
  [%pass /rover-files-desk %arvo %c %merg files-desk our %base da+now %init]
::
::  One attachment into Clay, as the camera wrote it.
++  clay-write-card
  |=  [attachment-id=@ux media-type=@t bytes=octs]
  ^-  card:agent:gall
  =/  =mime  [(de-mite media-type) bytes]
  =/  =miso:clay  [%ins %mime !>(mime)]
  [%pass /rover-files-write %arvo %c %info files-desk %& [(clay-path attachment-id) miso]~]
::
::  Read one attachment back out of Clay. Absent means the reference names a
::  file the backend does not hold, which is a fault worth reporting rather
::  than a zero-length body.
::
::  The LOCATOR is the address, not the id. Two references can name the same
::  stored bytes - the owner filed one photograph under two names - and only
::  one of them owns the id the path was built from.
++  clay-read
  |=  [our=@p now=@da locator=@t]
  ^-  (unit octs)
  =/  =path  (weld /(scot %p our)/[files-desk]/(scot %da now) (stab locator))
  ?.  .^(? %cu path)
    ~
  `q:.^(mime %cx path)
::
::  A media type as Clay wants it: 'image/jpeg' becomes /image/jpeg.
++  de-mite
  |=  media-type=@t
  ^-  mite
  =/  text  (trip media-type)
  =/  cut-at  (find "/" text)
  ?~  cut-at
    ~[(crip text)]
  :~  (crip (scag u.cut-at text))
      (crip (slag +(u.cut-at) text))
  ==
::
++  en-mite
  |=  =mite
  ^-  @t
  ?~  mite  'application/octet-stream'
  ?~  t.mite  i.mite
  (crip :(weld (trip i.mite) "/" (trip i.t.mite)))
::
::  ---------------------------------------------------------------------
::  Digests
::  ---------------------------------------------------------------------
::
::  SHA-256 of an octs, rendered the way every other tool on the owner's
::  machine renders it: sixty-four lowercase hex characters, no separators.
::  `shay` returns the digest in Urbit's byte order, so it is reversed once.
++  hash-octs
  |=  bytes=octs
  ^-  @t
  (hex-digest (rev 3 32 (shay p.bytes q.bytes)))
::
::  Most significant byte first, the way `sha256sum` prints one.
++  hex-digest
  |=  value=@ux
  ^-  @t
  %-  crip
  =/  index=@ud  32
  |-  ^-  tape
  ?:  =(0 index)
    ~
  =/  next  (dec index)
  =/  byte  (cut 3 [next 1] value)
  :+  (hex-digit (rsh [2 1] byte))
    (hex-digit (dis 15 byte))
  $(index next)
::
++  hex-digit
  |=  value=@ud
  ^-  @tD
  ?:  (lth value 10)
    (add '0' value)
  (add 'a' (sub value 10))
::
::  ---------------------------------------------------------------------
::  The container: an uncompressed ustar tar, written by hand
::  ---------------------------------------------------------------------
::
::  Measured on the real corpus, compression bought 0.0% - JPEG bytes are
::  already entropy coded - so the container is chosen for how simply Rover can
::  write and read it. Pinned zuse 408 has no tar, zip, gzip, deflate or zlib
::  arm, so any container is written here by hand, and tar is the smallest one:
::  one 512-byte header per file, every numeric field ASCII octal, an integrity
::  field that is a sum of the header bytes, and no index to seek backward to.
++  block-size  512
::
::  Hoon has no octal renderer. `scot` handles %ud, %ux and %uv only. This is
::  the div-and-mod loop, left-padded with zeros to the field width tar wants.
++  octal
  |=  [value=@ud width=@ud]
  ^-  tape
  =/  digits=tape  ~
  =/  left=@ud  value
  |-  ^-  tape
  ?:  =(0 left)
    =/  padded  ?~(digits "0" digits)
    (pad-left padded width)
  $(left (div left 8), digits [(add '0' (mod left 8)) digits])
::
++  pad-left
  |=  [text=tape width=@ud]
  ^-  tape
  =/  have  (lent text)
  ?:  (gte have width)
    (slag (sub have width) text)
  (weld (reap (sub width have) '0') text)
::
::  A tar field: the text, then zero bytes out to the field width.
++  field
  |=  [text=tape width=@ud]
  ^-  [p=@ud q=@]
  =/  clipped  ?:((gth (lent text) width) (scag width text) text)
  :-  width
  (crip (weld clipped (reap (sub width (lent clipped)) '\00')))
::
::  One 512-byte ustar header. The integrity field is the sum of the header
::  bytes with the field itself read as eight spaces, so the header is built
::  once with spaces, summed, then rebuilt with the real figure.
++  tar-header
  |=  [name=@t size=@ud stamp=@ud]
  ^-  [p=@ud q=@]
  =/  blank  (header-bytes name size stamp "        ")
  =/  sum  (byte-sum q.blank block-size)
  =/  checked  (weld (octal sum 6) "\00 ")
  (header-bytes name size stamp checked)
::
++  header-bytes
  |=  [name=@t size=@ud stamp=@ud checksum=tape]
  ^-  [p=@ud q=@]
  =/  parts=(list [p=@ud q=@])
    :~  (field (trip name) 100)
        (field "0000644" 8)
        (field "0000000" 8)
        (field "0000000" 8)
        (field (octal size 11) 12)
        (field (octal stamp 11) 12)
        [8 (crip checksum)]
        (field "0" 1)
        (field ~ 100)
        [6 'ustar']
        [2 '00']
        (field ~ 32)
        (field ~ 32)
        (field ~ 8)
        (field ~ 8)
        (field ~ 155)
        (field ~ 12)
    ==
  [block-size (can 3 parts)]
::
++  byte-sum
  |=  [value=@ width=@ud]
  ^-  @ud
  =/  index=@ud  0
  =/  total=@ud  0
  |-  ^-  @ud
  ?:  =(index width)
    total
  $(index +(index), total (add total (cut 3 [index 1] value)))
::
::  Every file rounds up to a whole number of 512-byte blocks.
++  tar-padding
  |=  size=@ud
  ^-  [p=@ud q=@]
  =/  over  (mod size block-size)
  ?:  =(0 over)
    [0 0]
  [(sub block-size over) 0]
::
::  One member of the archive.
++  tar-member
  |=  [name=@t bytes=octs stamp=@ud]
  ^-  (list [p=@ud q=@])
  :~  (tar-header name p.bytes stamp)
      [p.bytes q.bytes]
      (tar-padding p.bytes)
  ==
::
::  The whole archive. `can` assembles every chunk in one pass, which is what
::  keeps a 49 MB export from being built by 121 successive atom copies.
++  tar-archive
  |=  members=(list [name=@t bytes=octs])
  ^-  octs
  =/  stamp=@ud  0
  =/  chunks=(list [p=@ud q=@])
    %-  zing
    %+  turn  members
    |=  [name=@t bytes=octs]
    (tar-member name bytes stamp)
  ::  Two zero blocks close the archive, as every tar reader expects.
  =/  all  (weld chunks `(list [p=@ud q=@])`~[[block-size 0] [block-size 0]])
  =/  total
    |-  ^-  @ud
    ?~  all  0
    (add p.i.all $(all t.all))
  [total (can 3 all)]
::
::  ---------------------------------------------------------------------
::  Reading a tar back
::  ---------------------------------------------------------------------
::
::  A reader walks 512-byte blocks forward. There is no central directory and
::  no byte offset to trust, which is the property that made tar the cheapest
::  container to write by hand and it is the same property here.
++  tar-members
  |=  archive=octs
  ^-  (list [name=@t bytes=octs])
  =/  offset=@ud  0
  |-  ^-  (list [name=@t bytes=octs])
  ?:  (gth (add offset block-size) p.archive)
    ~
  =/  name  (read-field archive offset 0 100)
  ?:  =('' name)
    ~
  =/  size  (read-octal archive (add offset 124) 12)
  =/  start  (add offset block-size)
  ?:  (gth (add start size) p.archive)
    ~
  =/  body=octs  [size (cut 3 [start size] q.archive)]
  =/  over  (mod size block-size)
  =/  next  (add start ?:(=(0 over) size (add size (sub block-size over))))
  [[name body] $(offset next)]
::
::  Is this body an archive, or the import document by itself? The `ustar`
::  magic sits at offset 257 of the first header, and no JSON document can
::  carry it there: byte 0 of a Rover import is always `{`.
++  tar-body
  |=  body=octs
  ^-  ?
  ?&  (gte p.body block-size)
      =('ustar' (cut 3 [257 5] q.body))
  ==
::
::  One member out of an unpacked archive, by the name the writer gave it.
++  member-named
  |=  [wanted=@t members=(list [name=@t bytes=octs])]
  ^-  (unit octs)
  ?~  members  ~
  ?:  =(wanted name.i.members)
    `bytes.i.members
  $(members t.members)
::
::  A NUL-terminated tar field. Everything from the first zero byte on is pad.
++  read-field
  |=  [archive=octs offset=@ud from=@ud width=@ud]
  ^-  @t
  =/  index=@ud  0
  =/  out=tape  ~
  |-  ^-  @t
  ?:  =(index width)
    (crip (flop out))
  =/  byte  (cut 3 [(add (add offset from) index) 1] q.archive)
  ?:  =(0 byte)
    (crip (flop out))
  $(index +(index), out [`@tD`byte out])
::
::  Tar numbers are ASCII octal, terminated by a NUL or a space.
++  read-octal
  |=  [archive=octs from=@ud width=@ud]
  ^-  @ud
  =/  index=@ud  0
  =/  total=@ud  0
  |-  ^-  @ud
  ?:  =(index width)
    total
  =/  byte  (cut 3 [(add from index) 1] q.archive)
  ?:  ?|(=(0 byte) =(' ' byte))
    total
  ?:  ?|((lth byte '0') (gth byte '7'))
    total
  $(index +(index), total (add (mul total 8) (sub byte '0')))
::
::  ---------------------------------------------------------------------
::  The human boundary
::  ---------------------------------------------------------------------
::
::  A file name is the only handle on an attachment that crosses the Eyre
::  boundary, so Rover keeps it unique. A second file called `receipt.jpg`
::  becomes `receipt (2).jpg`, which is what a person expects of a file store.
++  unique-name
  |=  [wanted=@t taken=(set @t)]
  ^-  @t
  ?.  (~(has in taken) wanted)
    wanted
  =/  parts  (split-extension (trip wanted))
  =/  index=@ud  2
  |-  ^-  @t
  =/  candidate=@t
    %-  crip
    :(weld stem.parts " (" (decimal index) ")" ext.parts)
  ?.  (~(has in taken) candidate)
    candidate
  $(index +(index))
::
++  decimal
  |=  value=@ud
  ^-  tape
  ?:  (lth value 10)
    ~[(add '0' value)]
  (weld $(value (div value 10)) ~[(add '0' (mod value 10))])
::
++  split-extension
  |=  text=tape
  ^-  [stem=tape ext=tape]
  =/  index  (lent text)
  |-  ^-  [stem=tape ext=tape]
  ?:  =(0 index)
    [text ~]
  =/  next  (dec index)
  ?:  =('.' (snag next text))
    [(scag next text) (slag next text)]
  $(index next)
::
::  The path an attachment takes inside the export tar.
++  tar-name
  |=  file-name=@t
  ^-  @t
  (crip (weld "attachments/" (trip file-name)))
::
++  strip-tar-name
  |=  name=@t
  ^-  (unit @t)
  =/  text  (trip name)
  ?.  =("attachments/" (scag 12 text))
    ~
  =/  rest  (slag 12 text)
  ?~  rest  ~
  `(crip rest)
::  ---------------------------------------------------------------------
::  The S3 backend: AWS Signature Version 4, written here
::  ---------------------------------------------------------------------
::
::  The ship signs each request. A presigned PUT expires after 300 seconds.
::  Only the upload uses that URL. References and exports never store it.
::
::  Byte order is the trap in this section. `shay` reads and writes an atom
::  least-significant-byte first, the way a cord does. `sha-256l` and
::  `hmac-sha256l` read and write MOST significant first. Every value that
::  enters the signing chain is converted once, at `msb-byts`, and stays in
::  that order until it is rendered as hex.
++  msb-byts
  |=  value=@
  ^-  byts
  =/  width  (met 3 value)
  [width (rev 3 width value)]
::
++  digest-byts  |=(value=@ `byts`[32 value])
::
::  `hex-digest` reads byte 31 first, which is the first byte of a value that
::  is already most-significant-byte first. So no reversal here.
++  hex-msb  |=(value=@ `@t`(hex-digest value))
::
::  One newline, as a tape. Written out rather than escaped, so nothing here
::  depends on how a string escape is read.
++  nl  ^-(tape ~[`@tD`10])
::
++  sign-step
  |=  [key=byts message=@t]
  ^-  @
  (hmac-sha256l:hmac:crypto key (msb-byts message))
::
::  kSigning = HMAC(HMAC(HMAC(HMAC("AWS4"+secret, date), region), "s3"), "aws4_request")
++  signing-key
  |=  [secret=@t stamp=@t region=@t]
  ^-  @
  =/  seed=@t  (crip (weld "AWS4" (trip secret)))
  =/  k-date  (sign-step (msb-byts seed) stamp)
  =/  k-region  (sign-step (digest-byts k-date) region)
  =/  k-service  (sign-step (digest-byts k-region) 's3')
  (sign-step (digest-byts k-service) 'aws4_request')
::
++  sha-hex
  |=  text=@t
  ^-  @t
  (hex-msb (sha-256l:sha (msb-byts text)))
::
::  Two ASCII stamps, both derived from the same moment: 20260822T235959Z for
::  the request and 20260822 for the credential scope.
++  amz-stamps
  |=  now=@da
  ^-  [full=@t day=@t]
  =/  d  (yore now)
  =/  day=tape
    ;:  weld
      (pad-decimal y.d 4)  (pad-decimal m.d 2)  (pad-decimal d.t.d 2)
    ==
  :-  %-  crip
      ;:  weld
        day  "T"
        (pad-decimal h.t.d 2)  (pad-decimal m.t.d 2)  (pad-decimal s.t.d 2)
        "Z"
      ==
  (crip day)
::
++  pad-decimal
  |=  [value=@ud width=@ud]
  ^-  tape
  =/  text  (decimal value)
  =/  have  (lent text)
  ?:  (gte have width)
    text
  (weld (reap (sub width have) '0') text)
::
::  The host an endpoint names, without scheme or trailing slash. RustFS and
::  MinIO both answer path-style requests, which is what a bucket name with a
::  dot in it needs anyway.
++  endpoint-host
  |=  endpoint=@t
  ^-  @t
  =/  text  (trip endpoint)
  =/  after-scheme
    ?:  =("http://" (scag 7 text))   (slag 7 text)
    ?:  =("https://" (scag 8 text))  (slag 8 text)
    text
  =/  cut-at  (find "/" after-scheme)
  ?~  cut-at  (crip after-scheme)
  (crip (scag u.cut-at after-scheme))
::
++  endpoint-base
  |=  endpoint=@t
  ^-  tape
  =/  text  (trip endpoint)
  ?:  =("http://" (scag 7 text))   text
  ?:  =("https://" (scag 8 text))  text
  (weld "http://" text)
::
::  The content hash names the bytes without exposing an attachment id.
++  s3-key
  |=  content-hash=@t
  ^-  @t
  (cat 3 'attachments/' content-hash)
::
++  s3-locator
  |=  [bucket=@t content-hash=@t]
  ^-  @t
  (crip :(weld "/" (trip bucket) "/" (trip (s3-key content-hash))))
::
++  s3-url
  |=  [endpoint=@t locator=@t]
  ^-  @t
  =/  base  (endpoint-base endpoint)
  =/  base
    ?:  =('/' (snag (dec (lent base)) base))
      (scag (dec (lent base)) base)
    base
  (crip (weld base (trip locator)))
::
::  Header signing and query signing use the same SigV4 chain.
++  s3-signature
  |=  [config=s3-config:rover now=@da canonical=@t]
  ^-  @t
  =/  stamps  (amz-stamps now)
  =/  region=@t  ?:(=('' region.config) 'us-east-1' region.config)
  =/  scope=tape
    :(weld (trip day.stamps) "/" (trip region) "/s3/aws4_request")
  =/  to-sign=@t
    %-  crip
    ;:  weld
      "AWS4-HMAC-SHA256"  nl
      (trip full.stamps)  nl
      scope               nl
      (trip (sha-hex canonical))
    ==
  =/  key-bytes  (signing-key secret-access-key.config day.stamps region)
  (hex-msb (sign-step (digest-byts key-bytes) to-sign))
::
::  The browser consumes this PUT URL immediately. It signs host alone.
++  s3-presign
  |=  [config=s3-config:rover locator=@t now=@da]
  ^-  @t
  =/  stamps  (amz-stamps now)
  =/  region=@t  ?:(=('' region.config) 'us-east-1' region.config)
  =/  credential=@t
    %-  crip
    ;:  weld
      (trip access-key-id.config)  "/"  (trip day.stamps)
      "/"  (trip region)  "/s3/aws4_request"
    ==
  ::  These query parameters are in canonical byte order.
  =/  query=tape
    ;:  weld
      "X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential="
      (en-urlt:html (trip credential))
      "&X-Amz-Date="  (trip full.stamps)
      "&X-Amz-Expires=300&X-Amz-SignedHeaders=host"
    ==
  =/  canonical=@t
    %-  crip
    ;:  weld
      "PUT"  nl
      (trip locator)  nl
      query  nl
      "host:"  (trip (endpoint-host endpoint.config))  nl
      nl  "host"  nl  "UNSIGNED-PAYLOAD"
    ==
  %-  crip
  ;:  weld
    (trip (s3-url endpoint.config locator))  "?"  query
    "&X-Amz-Signature="  (trip (s3-signature config now canonical))
  ==
::
::  A signed request, ready for Iris. `method` is 'PUT' or 'GET'; a GET carries
::  no body and hashes the empty string, exactly as the specification says.
++  s3-request
  |=  $:  config=s3-config:rover
          method=@t
          locator=@t
          media-type=@t
          bytes=(unit octs)
          now=@da
      ==
  ^-  request:http
  =/  stamps  (amz-stamps now)
  =/  host  (endpoint-host endpoint.config)
  ::  The locator is already `/bucket/key`, and it is what the database holds.
  =/  resource=tape  (trip locator)
  =/  payload=@t
    ?~  bytes  (sha-hex '')
    (hash-octs u.bytes)
  =/  signed-headers=@t  'host;x-amz-content-sha256;x-amz-date'
  =/  canonical=@t
    %-  crip
    ;:  weld
      (trip method)                            nl
      resource                                 nl
      nl
      "host:"  (trip host)                     nl
      "x-amz-content-sha256:"  (trip payload)  nl
      "x-amz-date:"  (trip full.stamps)        nl
      nl
      (trip signed-headers)                    nl
      (trip payload)
    ==
  =/  region=@t  ?:(=('' region.config) 'us-east-1' region.config)
  =/  scope=tape
    :(weld (trip day.stamps) "/" (trip region) "/s3/aws4_request")
  =/  signature  (s3-signature config now canonical)
  =/  authorization=@t
    %-  crip
    ;:  weld
      "AWS4-HMAC-SHA256 Credential="
      (trip access-key-id.config)  "/"  scope
      ", SignedHeaders="  (trip signed-headers)
      ", Signature="  (trip signature)
    ==
  ::  `host` is SIGNED but not EMITTED. Vere writes its own `Host:` line, and a
  ::  second one makes the request ambiguous - S3-compatible servers answer 403
  ::  for it, which reads exactly like a bad credential and is not one.
  =/  headers=header-list:http
    :~  ['x-amz-content-sha256' payload]
        ['x-amz-date' full.stamps]
        ['authorization' authorization]
    ==
  =/  headers
    ?~  bytes  headers
    (weld headers `header-list:http`~[['content-type' media-type]])
  :*  ?:(=('PUT' method) %'PUT' %'GET')
      (crip (weld (endpoint-base endpoint.config) resource))
      headers
      bytes
  ==
--
