# First-use database bootstrap results

Date: 2026-08-13

Branch: `fix/vehicle-scoped-history-statistics`

Base commit: `7891ecc`

Pier: `/home/michael/piers/rover-statscope-bel`

Obelisk was running as the separate pinned desk. Rover used the system database
list query before it made a schema request. An existing `rover` database went
directly to the view query. An absent database ran `schema-m0:act`, waited one
second for the schema time to pass, ran the shared idempotent starter path, and
then ran the view query.

The delay is required by the real substrate. Without it, Obelisk refused the
first starter insert because its `recorded-at` value was before the schema time.

## RED evidence

The new cold-start fixture failed against the code from the branch base:

```text
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: FAIL - fixture 122 cold view returned 503: Unavailable - database query refused
ROVER_HTTP_STATUS=503
```

The new refusal fixture also failed against the old human surface:

```text
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: FAIL - fixture 124 refusal does not name the failed view query: Unavailable - database query refused
```

I then replaced the bootstrap pour in the mounted test desk with an invalid
atomic script. This made the real Obelisk refuse the pour. The cold-start
fixture failed and captured the phase-specific response:

```text
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: FAIL - fixture 122 cold view returned 503: Database setup failed while creating the Rover database. Obelisk refused the schema pour.
ROVER_HTTP_STATUS=503
```

I restored `schema-m0:act` before the GREEN runs.

## UI battery

Command:

```text
bash bin/ui-test.sh /home/michael/piers/rover-statscope-bel
```

The command exited with status 0. These lines are from the full run:

```text
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: bootstrap cold transcript - database-before=absent GET-status=200 starters=Gasoline|Diesel empty-state=Add-a-fill-to-begin-tracking
ui-test: fixture 122 PASS - a cold GET creates the database, seeds starters, and serves the usable empty state
ui-test: fixture 117 PASS - the real import endpoint added a 30-fill vehicle and a 3-fill vehicle
ui-test: fixture 118 PASS - the selected 3-fill diesel vehicle keeps its honest interval refusal
ui-test: fixture 119 PASS - History and Statistics page inside the selected 30-fill vehicle
ui-test: fixture 120 PASS - page 2 stays inside the selected vehicle and serves its last 5 fills
ui-test: fixture 121 PASS - GET serves both defaults and the old bare-page POST stays compatible
ui-test: bootstrap idempotence counts - before fills=56 starter-energy-definitions=8 after fills=56 starter-energy-definitions=8
ui-test: fixture 123 PASS - a populated view does not re-pour, re-seed, or change fill and starter counts
ui-test: fixture 75 PASS - after the full disposable battery the owner database serves the same active vehicles it had before the run
ui-test: COVERAGE - ran 74 of 102 defined fixtures
```

## Schema battery

Command:

```text
bash bin/schema-test.sh /home/michael/piers/rover-statscope-bel
```

Output:

```text
schema-test: PASS - SQL/Hoon parity is 68/68 relations; DDL has 75 explicit RESTRICT FKs and zero forward references
schema-test: PASS - fixture 17 - SQL/Hoon parity and isolated live Obelisk each have 68 relations; all 75 FK constraints (78 column rows) are RESTRICT; zero cascade/set-default
schema-test: PASS - COVERAGE - all 1 defined fixtures executed
```

## Fence checks

`desk/sur/rover.hoon` still has five action arms. The schema files did not
change. The copied Obelisk AST and the pinned upstream AST both have this
SHA-256:

```text
e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2
```

The final database list contained `animal-shelter`, `rover`, and `sys`. It did
not contain `rovertestowner`. Fixture 75 also confirmed that the restored owner
database served the same active vehicles as it did before the full run.
