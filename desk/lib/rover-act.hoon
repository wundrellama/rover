::  lib/rover-act - Obelisk driver helpers for %rover.
::
/-  ast=obelisk-ast
|%
++  rover-db  %rover
::
++  schema-v1
  ^-  tape
  ;:  weld
    "CREATE DATABASE rover; "
    "CREATE TABLE vehicles (vehicle-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (vehicle-id); "
    "CREATE TABLE odometer-observations (odometer-id @ux, vehicle-id @ux, value-digits @ud, decimal-places @ud, unit @tas, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (odometer-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE energy-definitions (energy-definition-id @ux, label @t, physical-kind @tas, quantity-unit @tas, archived @f, recorded-at @da) PRIMARY KEY (energy-definition-id); "
    "CREATE TABLE vehicle-energy-definitions (vehicle-id @ux, energy-definition-id @ux, archived @f) PRIMARY KEY (vehicle-id, energy-definition-id) FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id) ON DELETE RESTRICT ON UPDATE RESTRICT FOREIGN KEY (energy-definition-id) REFERENCES energy-definitions (energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE vehicle-default-energy-definitions (vehicle-id @ux, energy-definition-id @ux) PRIMARY KEY (vehicle-id) FOREIGN KEY (vehicle-id, energy-definition-id) REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE energy-acquisitions (acquisition-id @ux, vehicle-id @ux, energy-definition-id @ux, observed-start @da, observed-end @da, observed-precision @tas, source-zone @t, recorded-at @da) PRIMARY KEY (acquisition-id) FOREIGN KEY (vehicle-id, energy-definition-id) REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE fuel-fills (acquisition-id @ux, quantity-milli @ud, quantity-unit @tas, tank-state @tas) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE charging-sessions (acquisition-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE places (place-id @ux, label @t, archived @f, recorded-at @da) PRIMARY KEY (place-id); "
    "CREATE TABLE stations (station-id @ux, place-id @ux, label @t, station-kind @tas, archived @f, recorded-at @da) PRIMARY KEY (station-id) FOREIGN KEY (place-id) REFERENCES places (place-id) ON DELETE RESTRICT ON UPDATE RESTRICT; "
    "CREATE TABLE energy-acquisition-stations (acquisition-id @ux, station-id @ux) PRIMARY KEY (acquisition-id) FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id) ON DELETE RESTRICT ON UPDATE RESTRICT FOREIGN KEY (station-id) REFERENCES stations (station-id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
  ==
--
