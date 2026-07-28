|%
+$  id  @ux
+$  distance-unit  ?(%mi %km)
+$  precision  ?(%second %minute %day)
+$  physical-kind  ?(%reservoir %electricity)
+$  tank-state  ?(%full %partial)
+$  station-kind  ?(%fuel %charging %mixed %private)
+$  observed
  $:  start=@da
      end=@da
      =precision
      zone=@t
  ==
+$  odo-reading  [digits=@ud places=@ud odo-unit=distance-unit]
+$  action
  $%  [%init-db ~]
      [%add-definition label=@t kind=physical-kind quantity-unit=@tas ~]
      [%create-vehicle label=@t links=(list id) default=id ~]
      [%add-odometer vehicle=id digits=@ud places=@ud odo-unit=distance-unit observation=observed ~]
      [%current-odometer vehicle=id ~]
      [%add-fill vehicle=id def=id qty-milli=@ud qty-unit=@tas ts=tank-state observation=observed odo=(unit odo-reading) ~]
      [%add-charge vehicle=id def=id observation=observed ~]
      [%vehicle-history vehicle=id ~]
  ==
+$  result
  $%  [%ok msg=@t]
      [%err why=@t]
  ==
--
