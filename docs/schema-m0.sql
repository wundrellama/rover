-- Rover M0 schema — full pour, 68 relations.
-- Adopted 2026-07-29 (Gate 6 + schema Q1-11 + app-structure Q1-7 + import/consumables).
-- Amended 2026-07-30: +energy-subtype-cetane (import Q1), +acquisition-imports (Q5),
--                     +place-address-formatted / place-addresses loses formatted (Q9),
--                     +vehicle-refill-reserve.
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

-- Subtypes of an energy definition (Q3): "Gasoline" has no octane rating,
-- "Gasoline 93 AKI" does. Attributes hang off the SUBTYPE, not the definition.
CREATE TABLE rover..energy-definition-subtypes
  (subtype-id @ux, energy-definition-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (subtype-id)
  FOREIGN KEY (energy-definition-id)
    REFERENCES energy-definitions (energy-definition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..energy-subtype-octane
  (subtype-id @ux, rating @ud, method @tas)
  PRIMARY KEY (subtype-id)
  FOREIGN KEY (subtype-id)
    REFERENCES energy-definition-subtypes (subtype-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Cetane sibling, ratified 2026-07-30 (import Q1). 414 of the 420 records in the
-- real aCar corpus are cetane-45 ULSD; before this relation existed a diesel
-- rating had nowhere to go, and writing 45 into an octane row would assert a
-- fuel that does not exist.
--
-- Octane and cetane are mutually exclusive BY PHYSICS: octane measures
-- RESISTANCE to compression ignition (spark decides timing), cetane measures
-- EAGERNESS to ignite under compression (compression is the only trigger). The
-- dividing line is IGNITION MODE, not fuel name:
--   spark       -> octane : gasoline, ethanol blends (E85 ~100-105 AKI), LPG, CNG
--   compression -> cetane : diesel, biodiesel (B100 ~50-65), synthetic/HVO
-- "Octane belongs to gasoline" would be wrong and would make E85's rating
-- unrecordable - exactly the gap aCar has (its bioalcohol/gas categories carry
-- an EMPTY rating-type).
--
-- No method column: AKI and RON are two methods for the SAME property, so
-- octane needs one. Civilian diesel has no competing cetane scale, so a method
-- column here would be a knob with one setting.
--
-- ROVER INVARIANT: at most one rating child per subtype. Which child exists IS
-- the rating scale - no discriminator, no bunt (same as battery-observations).
CREATE TABLE rover..energy-subtype-cetane
  (subtype-id @ux, rating @ud)
  PRIMARY KEY (subtype-id)
  FOREIGN KEY (subtype-id)
    REFERENCES energy-definition-subtypes (subtype-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..energy-subtype-blend
  (subtype-id @ux, blend-kind @tas, percent-digits @ud, percent-decimals @ud)
  PRIMARY KEY (subtype-id, blend-kind)
  FOREIGN KEY (subtype-id)
    REFERENCES energy-definition-subtypes (subtype-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..energy-subtype-grade-code
  (subtype-id @ux, code @t)
  PRIMARY KEY (subtype-id)
  FOREIGN KEY (subtype-id)
    REFERENCES energy-definition-subtypes (subtype-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Configurable per-vehicle default subtype. No narrowing: every subtype of an
-- allowed definition stays selectable at fill time (Q3).
CREATE TABLE rover..vehicle-default-energy-subtype
  (vehicle-id @ux, subtype-id @ux, recorded-at @da)
  PRIMARY KEY (vehicle-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (subtype-id) REFERENCES energy-definition-subtypes (subtype-id)
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

-- AMENDED 2026-07-30 (import Q9): formatted moved to its own child.
-- The parent is now FACT-NEUTRAL: it asserts "this place has address evidence,
-- from source X", not "a source supplied address text".
--
-- Q10 originally made formatted mandatory on the reasoning that an address
-- record exists only because a source supplied text. The real aCar corpus
-- falsifies that: 105 of 420 fills carry address PARTS with no formatted text,
-- 97 of them a COMPLETE address (line1+locality+region+postal+country). With
-- parts FK'd to a mandatory-formatted parent, those were structurally
-- unrecordable - 11 of 50 named places would have lost %locality entirely,
-- disabling the ratified grantable approximate-locality projection for 22% of
-- them while the source knew the city perfectly well.
--
-- Same defect class as Q3/Q4/Q9: one relation holding two INDEPENDENT facts
-- ("a source gave text" vs "we have address evidence"). Same fix: neutral
-- parent + independently optional children.
--
-- ROVER INVARIANT: at least one child - a formatted row, one or more parts, or
-- both. NOT XOR: 275 records legitimately have both, and text plus structure is
-- the richest case. A parent with no children asserts nothing (reconciliation
-- failure).
--
-- Synthesising formatted text from parts is FORBIDDEN: Rover would invent a
-- string no source supplied, indistinguishable from real source text once
-- stored, and address grammar is not universal (Japanese runs
-- largest-to-smallest, the UK has no %region in the US sense).
CREATE TABLE rover..place-addresses
  (place-id @ux, source @tas, recorded-at @da)
  PRIMARY KEY (place-id)
  FOREIGN KEY (place-id) REFERENCES places (place-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- The source-supplied address text, when there is one. Absent = the source
-- gave structured parts only.
CREATE TABLE rover..place-address-formatted
  (place-id @ux, formatted @t)
  PRIMARY KEY (place-id)
  FOREIGN KEY (place-id) REFERENCES place-addresses (place-id)
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

-- ============================================================
-- APP-STRUCTURE ADDITIONS (ratified 2026-07-28)
-- See ~/brain/projects/rover/app-structure.md
-- ============================================================

-- Singleton (Q4): constant PK makes two defaults structurally impossible.
-- Changed by UPDATE on the one row; absence = no default set.
CREATE TABLE rover..app-default-vehicle
  (scope @tas, vehicle-id @ux, recorded-at @da)
  PRIMARY KEY (scope)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Optional (Q5): absent when unknown; the distance-to-next-fill estimate then
-- reports unavailable with a reason rather than deriving from a guess.
CREATE TABLE rover..vehicle-tank-size
  (vehicle-id @ux, digits @ud, decimals @ud, size-unit @tas)
  PRIMARY KEY (vehicle-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Optional per-vehicle refill reserve. Absence means the full tank is usable.
CREATE TABLE rover..vehicle-refill-reserve
  (vehicle-id @ux, reserve-percent @ud)
  PRIMARY KEY (vehicle-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Per-fill subtype selection (Q3). Absent when not recorded.
CREATE TABLE rover..fuel-fill-subtype
  (acquisition-id @ux, subtype-id @ux)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (subtype-id) REFERENCES energy-definition-subtypes (subtype-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Driving modes (Q2): owner-defined, copied from shipped starters, scoped per
-- vehicle so a sedan never offers Tow/Haul.
CREATE TABLE rover..driving-mode-definitions
  (mode-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (mode-id);

CREATE TABLE rover..vehicle-driving-modes
  (vehicle-id @ux, mode-id @ux, archived @f)
  PRIMARY KEY (vehicle-id, mode-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (mode-id) REFERENCES driving-mode-definitions (mode-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..fuel-fill-driving-mode
  (acquisition-id @ux, mode-id @ux)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (mode-id) REFERENCES driving-mode-definitions (mode-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Independently optional per-fill facts (Q6). The city/highway slider must
-- start UNSET in the UI: an untouched slider writes no row, so 50/50 is never
-- recorded as an assertion the owner did not make.
CREATE TABLE rover..fuel-fill-average-speed
  (acquisition-id @ux, digits @ud, decimals @ud, speed-unit @tas)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..fuel-fill-drive-balance
  (acquisition-id @ux, highway-percent @ud)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Tags: mirrors the additives pattern (definitions + link).
CREATE TABLE rover..tag-definitions
  (tag-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (tag-id);

CREATE TABLE rover..fuel-fill-tags
  (acquisition-id @ux, tag-id @ux)
  PRIMARY KEY (acquisition-id, tag-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (tag-id) REFERENCES tag-definitions (tag-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Custom fields (Q1). content-type is IMMUTABLE once values exist; to change
-- it, archive the definition and create a new one. mandatory is a
-- ROVER-ENFORCED invariant (Obelisk has no CHECK constraints).
CREATE TABLE rover..custom-field-definitions
  (field-id @ux, label @t, content-type @tas, entry-type @tas, mandatory @f,
   target @tas, archived @f, recorded-at @da)
  PRIMARY KEY (field-id);

-- Only present for %dropdown entry-type; absence is not a sentinel.
CREATE TABLE rover..custom-field-options
  (field-id @ux, ordinal @ud, label @t)
  PRIMARY KEY (field-id, ordinal)
  FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Typed value tables: every column used, no bunt-filled spares.
-- Numeric values carry digits/decimals/unit so exact arithmetic still holds.
CREATE TABLE rover..custom-field-values-number
  (field-id @ux, parent-id @ux, digits @ud, decimals @ud, value-unit @tas)
  PRIMARY KEY (field-id, parent-id)
  FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..custom-field-values-text
  (field-id @ux, parent-id @ux, value @t)
  PRIMARY KEY (field-id, parent-id)
  FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..custom-field-values-boolean
  (field-id @ux, parent-id @ux, value @f)
  PRIMARY KEY (field-id, parent-id)
  FOREIGN KEY (field-id) REFERENCES custom-field-definitions (field-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ============================================================
-- IMPORT + CONSUMABLES ADDITIONS (ratified 2026-07-29)
-- See ~/brain/projects/rover/import-format.md and app-structure.md
-- ============================================================

-- Payment method is DESCRIPTIVE and kept out of the arithmetic.
-- settlement-mode (%standard/%cash) drives cash rounding; this does not.
CREATE TABLE rover..payment-method-definitions
  (method-id @ux, label @t, archived @f, recorded-at @da)
  PRIMARY KEY (method-id);

CREATE TABLE rover..fuel-fill-payment-method
  (acquisition-id @ux, method-id @ux)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (method-id) REFERENCES payment-method-definitions (method-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Re-import detection (import Q5, ratified 2026-07-30). Records WHICH foreign
-- record an acquisition came from, so a second import of the same export
-- recognises what it has already seen and only new records land.
--
-- Same shape and same rule as station-identifiers: a provider-namespaced
-- external ID that must NEVER cross a human or agent boundary. Namespacing
-- means aCar 78432901 and Fuelly 78432901 cannot collide.
--
-- Absence of the row = owner-entered. No sentinel.
--
-- The natural key (vehicle + observed-start) was REJECTED: aCar dates are
-- minute-precision, so two legitimate fills inside one minute (splitting across
-- pumps, topping a jerry can) would be silently refused as duplicates.
-- "Have I imported this record?" is a provenance question with an exact answer;
-- "are these the same real-world event?" is a semantic one Rover cannot answer.
--
-- CHANGED records report a conflict and import NOTHING - never UPSERT, never
-- clobber an owner's Rover-side edit. 391 of 420 records in the real corpus
-- have a last-modification-date after their entry date, so edits do happen.
-- No content hash column: a stored hash is a derived value that drifts from its
-- inputs when any normalisation rule changes (same reason total paid is not
-- stored on fuel-fills). Field comparison at re-import time is always current.
CREATE TABLE rover..acquisition-imports
  (acquisition-id @ux, source-app @tas, source-record-id @t)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES energy-acquisitions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Present only when non-empty, so no empty-string sentinel.
CREATE TABLE rover..fill-notes
  (acquisition-id @ux, note @t)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES fuel-fills (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Electricity subtypes (DC Fast / AC L2 / AC L1) need a link too; the fuel
-- link keys to fuel-fills and cannot serve a charge.
CREATE TABLE rover..charging-session-subtype
  (acquisition-id @ux, subtype-id @ux)
  PRIMARY KEY (acquisition-id)
  FOREIGN KEY (acquisition-id) REFERENCES charging-sessions (acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (subtype-id) REFERENCES energy-definition-subtypes (subtype-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- CONSUMABLES: DEF, washer fluid, oil, coolant. Bought by volume and priced
-- per unit like fuel, but NOT energy - energy-acquisitions carries a mandatory
-- energy-definition-id, so a consumable there would have to name an energy
-- definition it does not have. Separate parent keeps consumables permanently
-- out of every fuel-economy derivation.
CREATE TABLE rover..consumable-definitions
  (consumable-id @ux, label @t, quantity-unit @tas, archived @f, recorded-at @da)
  PRIMARY KEY (consumable-id);

-- Enablement is presence of this link, never a boolean on vehicles. An
-- archived link is retained configuration history and does not enable use.
CREATE TABLE rover..vehicle-consumables
  (vehicle-id @ux, consumable-id @ux, archived @f)
  PRIMARY KEY (vehicle-id, consumable-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (consumable-id) REFERENCES consumable-definitions (consumable-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Capacity belongs to any vehicle/consumable pair, not specifically to DEF.
-- Absence means no tank size was recorded.
CREATE TABLE rover..vehicle-consumable-tank-size
  (vehicle-id @ux, consumable-id @ux, digits @ud, decimals @ud, unit @tas)
  PRIMARY KEY (vehicle-id, consumable-id)
  FOREIGN KEY (vehicle-id, consumable-id)
    REFERENCES vehicle-consumables (vehicle-id, consumable-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..consumable-acquisitions
  (consumable-acquisition-id @ux, vehicle-id @ux, consumable-id @ux,
   observed-start @da, observed-end @da, observed-precision @tas,
   source-zone @t, recorded-at @da)
  PRIMARY KEY (consumable-acquisition-id)
  FOREIGN KEY (vehicle-id) REFERENCES vehicles (vehicle-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (consumable-id) REFERENCES consumable-definitions (consumable-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

-- Pricing columns deliberately mirror fuel-fills rather than sharing a table:
-- sharing would put consumables back in the fuel path. Rounding rules are
-- snapshotted per purchase so a later profile change cannot re-render history.
CREATE TABLE rover..consumable-purchases
  (consumable-acquisition-id @ux, quantity-milli @ud, quantity-unit @tas,
   unit-price-mills @ud, currency @tas, settlement-mode @tas, price-profile @tas,
   minor-unit-decimals @ud, cash-increment-mills @ud)
  PRIMARY KEY (consumable-acquisition-id)
  FOREIGN KEY (consumable-acquisition-id)
    REFERENCES consumable-acquisitions (consumable-acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..consumable-acquisition-stations
  (consumable-acquisition-id @ux, station-id @ux)
  PRIMARY KEY (consumable-acquisition-id)
  FOREIGN KEY (consumable-acquisition-id)
    REFERENCES consumable-acquisitions (consumable-acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (station-id) REFERENCES stations (station-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE TABLE rover..consumable-acquisition-odometers
  (consumable-acquisition-id @ux, odometer-id @ux)
  PRIMARY KEY (consumable-acquisition-id)
  FOREIGN KEY (consumable-acquisition-id)
    REFERENCES consumable-acquisitions (consumable-acquisition-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  (odometer-id) REFERENCES odometer-observations (odometer-id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;
