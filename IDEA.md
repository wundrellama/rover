# Rover

Urbit Gall app for vehicle lifecycle tracking.

## Overview

Track vehicle data (fuel, service, maintenance, costs, insurance, modifications) across multiple vehicles. Native Urbit app using Obelisk as the database layer. Similar to [Lubelog](https://github.com/hargata/lubelog) and [Fuelly](https://www.fuelly.com/) — but running on your own Urbit ship with social/sharing features.

## Architecture

- **Development**: Disposable fake ships only until explicit release readiness
- **Runtime**: Urbit Gall app (Hoon)
- **Database**: Obelisk (temporal RDBMS with urQL)
- **UI**: Landscape tile (primary), %hawk (secondary/admin)
- **File storage**: RustFS/S3 (via urbit connection) or Clay fallback after vere64
- **Sharing**: Ames poke (`%rover/share`, `%rover/request-access`) — read-only or write access
- **Distribution**: Public app via Clay desk / OTA

## Data Model

### Core tables (Phase 1)
| Table | Key fields |
|-------|-----------|
| `vehicles` | id, name, year, make, model, trim, vin, license_plate, vin_hash, current_odometer, purchase_date, purchase_price, notes |
| `fuel_records` | id, vehicle_id, date, odometer, gallons, price_per_gallon, total_cost, fuel_type, station_location, notes |
| `maintenance_records` | id, vehicle_id, scheduled_date, interval_miles, interval_months, service_type, completed, notes |
| `vehicle_shares` | vehicle_id, shared_with (%p), access_level (%read/%write), granted_at, granted_by |

### Deferred (later phases)
- Service records, insurance, taxes, modifications, supplies
- CSV import/export
- Community-aggregated analytics

## Derived Calculations (Phase 5)

Computed in Gall's `+gain` hook:
- Fuel economy (mpg/kpl) — per fillup, per fuel type, per date interval, per station
- Cost per mile — fuel, service, total
- Mileage tracking — by date interval
- Upcoming maintenance predictions (based on interval_miles / interval_months)


## Implementation Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Learning & environment — hello-world Gall app, moon setup, Obelisk install, urbit-mcp | Not started |
| 1 | Data model & Obelisk schema | Not started |
| 2 | Core Gall app skeleton | Not started |
| 3 | Vehicle CRUD | Not started |
| 4 | Fuel & service records | Not started |
| 5 | Derived calculations | Not started |
| 6 | File attachments (S3/Clay) | Not started |
| 7 | CSV import | Not started |
| 8 | Sharing & social features | Not started |
| 9 | Polish & release | Not started |

## Risks

1. **Obelisk is beta** — API may change. Pin a commit version. Monitor releases.
2. **Loom memory** — Monitor loom usage carefully. 2GB default may fill up with many vehicles.

## Related

- fuelly — current tool of choice (external)
- lubelog — open source reference implementation
- obelisk — Urbit temporal RDBMS
