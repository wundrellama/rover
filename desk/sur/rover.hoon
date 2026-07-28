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
      [%seed-spike ~]
      [%verify-schema ~]
      [%vehicle-history ~]
      [%current-odometer ~]
  ==
+$  result
  $%  [%ok msg=@t]
      [%err why=@t]
  ==
--
