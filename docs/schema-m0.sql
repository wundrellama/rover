-- Rover M0 schema — full pour, 36 relations.
-- Adopted 2026-07-28 (Gate 6 + open questions 1-11).
-- Source of truth: ~/brain/projects/rover/schema-m0.md
--
-- SYNTAX NOTES (verified against pinned Obelisk master @ eecab1b, zuse 408):
--   * Multi-FK continuation: FOREIGN KEY (a) REFERENCES t (a) ON ..., (b) REFERENCES u (b) ON ...
--     Do NOT repeat the FOREIGN KEY keyword after the comma — the parser rejects it.
--   * Every FK carries explicit ON DELETE RESTRICT ON UPDATE RESTRICT.
--   * Tables are qualified rover..<name> (database rover, default dbo namespace).
--   * Parent tables must be created before children (FK targets must exist).
--
-- INVARIANTS OBELISK CANNOT ENFORCE (Rover validates + reconciles):
--   * enum membership for every @tas column
--   * exactly-one-subtype per acquisition (fuel-fills XOR charging-sessions)
--   * archived @f written literal N on insert (the @f bunt is %.y = archived)
--   * nonempty labels, quantity > 0, precision 0-3, observed-start < observed-end
--   * derived values (total paid, current odometer) are NEVER stored

CREATE DATABASE rover;

-- ============================================================
-- GROUP A — backbone (11)
-- ============================================================

CREATE TABLE rover..vehicles
  (vehicle-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (vehicle-id);

-- Owner display preference, per vehicle (Q11). Absence of the row = render
-- source-native; presentation only, never rewrites history.
CREATE TABLE rover..vehicle-display-preferences
  (vehicle-id @ux, distance-unit @tas, currency @tas, recorded-at @da)
  PRIMARY KEY (vehicle-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..odometer-observations
  (odometer-id @ux, vehicle-id @ux, value-digits @ud, decimal-places @ud,
   unit @tas, observed-start @da, observed-end @da, observed-precision @tas,
   source-zone @t, recorded-at @da)
  PRIMARY KEY (odometer-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..energy-definitions
  (energy-definition-id @ux, label @t, physical-kind @tas, quantity-unit @tas,
   archived @f, recorded-at @da)
  PRIMARY KEY (energy-definition-id);

CREATE TABLE rover..vehicle-energy-definitions
  (vehicle-id @ux, energy-definition-id @ux, archived @f)
  PRIMARY KEY (vehicle-id, energy-definition-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (energy-definition-id) REFERENCES energy-definitions (energy-definition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..vehicle-default-energy-definitions
  (vehicle-id @ux, energy-definition-id @ux)
  PRIMARY KEY (vehicle-id)
  FOREIGN KEY (vehicle-id, energy-definition-id)
    REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..energy-acquisitions
  (acquisition-id @ux, vehicle-id @ux, energy-definition-id @ux,
   observed-start @da, observed-end @da, observed-precision @tas,
   source-zone @t, recorded-at @da)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (vehicle-id, energy-definition-id)
    REFERENCES vehicle-energy-definitions (vehicle-id, energy-definition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- AMENDED: gains mandatory pricing columns (Gate 6).
-- minor-unit-decimals and cash-increment-mills are SNAPSHOTTED at entry (Q7):
-- a later profile correction must never re-round a historical fill.
-- Total paid is DERIVED, never stored.
CREATE TABLE rover..fuel-fills
  (acquisition-id @ux, quantity-milli @ud, quantity-unit @tas, tank-state @tas,
   unit-price-mills @ud, currency @tas, settlement-mode @tas, price-profile @tas,
   minor-unit-decimals @ud, cash-increment-mills @ud)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..charging-sessions
  (acquisition-id @ux)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..places
  (place-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (place-id);

CREATE TABLE rover..stations
  (station-id @ux, place-id @ux, label @t, station-kind @tas, archived @f,
   recorded-at @da)
  PRIMARY KEY (station-id)
  FOREIGN KEY (place-id) REFERENCES places (place-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- UNCHANGED from backbone: visit evidence lives in its own child (Q3).
CREATE TABLE rover..energy-acquisition-stations
  (acquisition-id @ux, station-id @ux)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (station-id) REFERENCES stations (station-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================
-- GROUP B — definition attributes (3). Typed, not key-value (Q6).
-- ============================================================

CREATE TABLE rover..energy-definition-octane
  (energy-definition-id @ux, rating @ud, method @tas)
  PRIMARY KEY (energy-definition-id)
  FOREIGN KEY (energy-definition-id)
    REFERENCES energy-definitions (energy-definition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..energy-definition-blend
  (energy-definition-id @ux, blend-kind @tas, percent-digits @ud,
   percent-decimals @ud)
  PRIMARY KEY (energy-definition-id, blend-kind)
  FOREIGN KEY (energy-definition-id)
    REFERENCES energy-definitions (energy-definition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..energy-definition-grade-code
  (energy-definition-id @ux, code @t)
  PRIMARY KEY (energy-definition-id)
  FOREIGN KEY (energy-definition-id)
    REFERENCES energy-definitions (energy-definition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================
-- GROUP C — fills, mileage, economy, additives (4)
-- ============================================================

-- Optional mileage link. Absence = mileage not supplied.
CREATE TABLE rover..fuel-fill-odometers
  (acquisition-id @ux, odometer-id @ux)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (odometer-id) REFERENCES odometer-observations (odometer-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..additive-definitions
  (additive-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (additive-id);

-- Selection only: no dose, no cost. Zero rows = no additive (no None row).
CREATE TABLE rover..fuel-fill-additives
  (acquisition-id @ux, additive-id @ux)
  PRIMARY KEY (acquisition-id, additive-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (additive-id) REFERENCES additive-definitions (additive-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Explicit break row rather than a sentinel. Absence = chain intact.
-- No free-text note column (Q8): an optional @t could only store the empty-string
-- bunt, making "no note" and "blank note" indistinguishable.
CREATE TABLE rover..economy-breaks
  (acquisition-id @ux, reason @tas, recorded-at @da)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================
-- GROUP D — charging measurements (4)
-- ============================================================

-- kW and range NEVER substitute for kWh; each stays its own row.
CREATE TABLE rover..charging-energy-measurements
  (measurement-id @ux, acquisition-id @ux, quantity @ud, decimals @ud,
   measure-unit @tas, point @tas, evidence @tas, recorded-at @da)
  PRIMARY KEY (measurement-id)
  FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Form-neutral parent; exactly one typed child carries the form-specific values (Q9).
-- The form column is DROPPED: which child row exists IS the form.
-- Rover's atomic write + reconciliation enforce exactly-one-child (Obelisk cannot
-- express cross-table XOR), same as fuel-fills/charging-sessions.
CREATE TABLE rover..battery-observations
  (battery-observation-id @ux, vehicle-id @ux, measure @tas,
   observed-start @da, observed-end @da, observed-precision @tas,
   source-zone @t, recorded-at @da)
  PRIMARY KEY (battery-observation-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..battery-observation-percent
  (battery-observation-id @ux, value-digits @ud, value-decimals @ud)
  PRIMARY KEY (battery-observation-id)
  FOREIGN KEY (battery-observation-id)
    REFERENCES battery-observations (battery-observation-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Filled/total preserved WITHOUT inventing a percentage.
CREATE TABLE rover..battery-observation-segments
  (battery-observation-id @ux, filled @ud, total @ud)
  PRIMARY KEY (battery-observation-id)
  FOREIGN KEY (battery-observation-id)
    REFERENCES battery-observations (battery-observation-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..charging-session-batteries
  (acquisition-id @ux, endpoint @tas, battery-observation-id @ux)
  PRIMARY KEY (acquisition-id, endpoint)
  FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (battery-observation-id)
    REFERENCES battery-observations (battery-observation-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..charging-efficiency-breaks
  (acquisition-id @ux, reason @tas, recorded-at @da)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================
-- GROUP E — charging cost (3)
-- ============================================================

CREATE TABLE rover..charging-costs
  (acquisition-id @ux, cost-state @tas, currency @tas, recorded-at @da)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..charging-cost-components
  (component-id @ux, acquisition-id @ux, component @tas, quantity @ud,
   quantity-decimals @ud, quantity-unit @tas, rate-mills @ud, amount-mills @ud)
  PRIMARY KEY (component-id)
  FOREIGN KEY (acquisition-id) REFERENCES charging-costs (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Source-reported total, preserved as reported. Absence (not 0) = no total.
CREATE TABLE rover..charging-cost-source-totals
  (acquisition-id @ux, total-mills @ud)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES charging-costs (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================
-- GROUP F — vehicle-reported consumption (1)
-- ============================================================

-- Scope is part of the reading's meaning: instant never enters lifetime.
CREATE TABLE rover..consumption-observations
  (consumption-id @ux, vehicle-id @ux, value-digits @ud, value-decimals @ud,
   consumption-unit @tas, scope @tas, source @tas,
   observed-start @da, observed-end @da, observed-precision @tas,
   source-zone @t, recorded-at @da)
  PRIMARY KEY (consumption-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================
-- GROUP G — location evidence (7 total; 3 backbone above + 4 new here,
-- plus brand/operator, identifiers, equipment)
-- ============================================================

CREATE TABLE rover..place-addresses
  (place-id @ux, formatted @t, source @tas, recorded-at @da)
  PRIMARY KEY (place-id)
  FOREIGN KEY (place-id) REFERENCES places (place-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Permissive open set, no part required (Q2); %country is a part term (Q10).
-- Formatted text stays authoritative.
CREATE TABLE rover..place-address-parts
  (place-id @ux, part @tas, value @t)
  PRIMARY KEY (place-id, part)
  FOREIGN KEY (place-id) REFERENCES place-addresses (place-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- 7 decimal places is the M0 standard (Q1); coord-scale stored per row.
CREATE TABLE rover..place-coordinates
  (place-id @ux, latitude-scaled @sd, longitude-scaled @sd, coord-scale @ud,
   source @tas, recorded-at @da)
  PRIMARY KEY (place-id)
  FOREIGN KEY (place-id) REFERENCES places (place-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Child row (Q4): a 0-metre column would read as PERFECT precision.
-- Absence = no source reported an accuracy figure.
CREATE TABLE rover..place-coordinate-accuracy
  (place-id @ux, radius-digits @ud, radius-decimals @ud, radius-unit @tas)
  PRIMARY KEY (place-id)
  FOREIGN KEY (place-id) REFERENCES place-coordinates (place-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Child values, not owner definitions (Q5). Human labels — distinct from
-- station-identifiers, which holds provider-namespaced external IDs.
CREATE TABLE rover..station-brand-operator
  (station-id @ux, role @tas, label @t)
  PRIMARY KEY (station-id, role)
  FOREIGN KEY (station-id) REFERENCES stations (station-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..station-identifiers
  (station-id @ux, provider @tas, external-id @t)
  PRIMARY KEY (station-id, provider)
  FOREIGN KEY (station-id) REFERENCES stations (station-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Visit-specific, child row (Q3): empty-string columns would be sentinels.
CREATE TABLE rover..acquisition-station-equipment
  (acquisition-id @ux, equipment-label @t, receipt-text @t)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id)
    REFERENCES energy-acquisition-stations (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;
