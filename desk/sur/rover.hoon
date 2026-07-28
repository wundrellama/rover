::  Rover shared structures — v1 backbone.
::  Mirrors the ratified contract in brain/projects/rover/schema-v1.md.
::  Raw machine IDs never cross human/agent/remote boundaries; these types are
::  internal. Projections (separate) render labels and human values only.
|%
::  --- opaque identity ---
+$  id  @ux                    ::  nonzero random 128-bit Rover-generated identity
::
::  --- closed enums (Rover enforces; Obelisk stores only the aura) ---
+$  unit        ?(%mi %km)
+$  precision   ?(%second %minute %day)
+$  physical-kind  ?(%reservoir %electricity)
+$  tank-state  ?(%full %partial)
+$  station-kind ?(%fuel %charging %mixed %private)
::
::  --- observed-time evidence (system derives UTC bounds from owner input) ---
+$  observed
  $:  start=@da                ::  inclusive lower bound
      end=@da                  ::  exclusive upper bound
      =precision
      zone=@t                  ::  source-zone label (human context)
  ==
::
::  --- actions accepted by %rover (local same-ship callers only in v1) ---
+$  action
  $%
    ::  schema + database lifecycle
    [%init-db ~]                          ::  create %rover db + apply schema v1
    ::  energy definitions
    [%add-definition label=@t kind=physical-kind quantity-unit=@tas ~]
    ::  vehicle configuration (atomic: vehicle + links + default)
    [%create-vehicle label=@t links=(list id) default=id ~]
    ::  odometer
    [%add-odometer vehicle=id digits=@ud places=@ud u=unit obs=observed ~]
    [%current-odometer vehicle=id ~]
    ::  energy acquisitions
    [%add-fill vehicle=id def=id qty-milli=@ud qty-unit=@tas ts=tank-state
               obs=observed odo=(unit [digits=@ud places=@ud u=unit]) ~]
    [%add-charge vehicle=id def=id obs=observed ~]
    ::  reads (return human projections; never raw ids at the boundary)
    [%vehicle-history vehicle=id ~]
  ==
::
::  --- update/result envelopes for projections ---
+$  result
  $%  [%ok msg=@t]
      [%err why=@t]
      [%vehicle-projection label=@t current-odo=(unit @t) history=(list @t)]
  ==
--
