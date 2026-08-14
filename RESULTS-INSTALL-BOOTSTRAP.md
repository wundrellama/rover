# Install bootstrap and status results

Date: 2026-08-14

Branch: `feat/install-bootstrap-status`

Base commit: `3184412`

Full-suite pier: `/home/michael/piers/rover-statscope-bel`

Final fresh install piers:

- `/home/michael/piers/rover-install-release-deferred-bel`
- `/home/michael/piers/rover-install-release-interim-bel`

## Status marker choice

Rover uses the response header `X-Rover-Bootstrap: performed`. The header keeps
the served fragment unchanged and identifies the response that ran the
bootstrap. The shell reads this header from that response. It does not infer
the state from the DOM, the response size, or timing.

## RED evidence

### Fixture 129: normal response status

The new fixture drove the authenticated shell in Chromium against the base
code. The response had no bootstrap marker. The fixture failed because the
first active status made the bootstrap claim:

```text
ui-test: logged-out browser receives login redirect with no Rover body
ui-test: FAIL - fixture 129 normal status is dishonest: ui-browser-fixtures: FAIL - first paint did not say Loading…: {"statuses":["Setting up the database…","Connected · current on navigation"],"markers":[null]}; header=ROVER · VEHICLE LOG · ~BEL · NO DEFAULT VEHICLE
```

### Fixture 130: bootstrap response status

The fixture removed the isolated Rover database and drove the real lazy
bootstrap. The database and starters appeared, which supplied a nonzero control
for the instrument. The fixture failed because the response had no marker and
the shell did not show the setup status:

```text
ui-test: fixture 129 PASS - a normal first paint says Loading and no response marker makes a bootstrap claim
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: FAIL - fixture 130 bootstrap status is dishonest: ui-browser-fixtures: FAIL - bootstrap response was not echoed: {"statuses":["Loading…","Connected · current on navigation"],"markers":[null],"gasoline":true,"diesel":true,"emptyState":true}; header=ROVER · VEHICLE LOG · ~BEL · NO DEFAULT VEHICLE
```

### Fixture 131: install bootstrap

The fixture hard-reset Rover state and booted the agent with Obelisk running.
It made no request to `/apps/rover/view`. The base code did not create or seed
the database:

```text
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: FAIL - fixture 131 install did not create and seed Rover before any page load
```

### Fixture 132: queued delivery

The fixture installed Rover while Obelisk was absent. The trace guard refused
the base code because it observed no install probe:

```text
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: FAIL - fixture 132 stopped-Obelisk install captured 0 install probes; refusing to trust absence counts
```

The first RED run used a soft Obelisk nuke. That operation removed the
disposable `rover-statscope-bel` pier's Obelisk state, including its renamed
Rover test database. The state was not recoverable. No later run used that
operation on a baseline pier.

### Fixture 133: populated install

The fixture prepared a populated database through the proven lazy path. It
then hard-reset and booted Rover. The guarded trace rejected the base code
because no install probe ran:

```text
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: FAIL - fixture 133 populated install captured 0 install probes; refusing to trust absence counts
```

### Fixture 134: interim lazy bootstrap

The first fresh-state run found that the new Boolean latch bunted to true.
The waiting page used `%rover-http %recover` instead of the lazy probe. After
the fresh-state fix, the next run reached the lazy starter write while Obelisk
was still inside its install event. Obelisk refused that early write, and the
fixture failed before it could report a false green:

```text
install-bootstrap-test: FAIL - the lazy page did not return HTTP 200
```

The repair reuses the lazy path's existing post-schema wait. The initial
install path then performs the only starter write. The waiting page rechecks
the starters and returns the marked response.

### Fixture 134: late-probe sabotage

The sabotage changed only the disposable pier copy of the request-less install
handler. It forced a populated Rover database to look absent. The fixture had
a positive queued-probe control and detected the forbidden pour:

```text
install-bootstrap-test: sabotage control - queued-install-probe=present install-pours=1
install-bootstrap-test: FAIL - the late install path sent 1 schema pours, want 0
```

The sabotage copy was replaced from the repository after this run, and the
restored desk compiled.

## GREEN evidence

### Fixture 132: deferred queued delivery

Command:

```text
bash bin/install-bootstrap-test.sh /home/michael/piers/rover-install-release-deferred-bel
```

Output:

```text
install-bootstrap-test: deferred transcript - absent-watch=queued absent-poke=queued database=rover starters=Gasoline|Diesel no-page-bootstrap-probes=0
install-bootstrap-test: starter row counts - energy-definition-id=8 subtype-id=32 octane-subtype-id=11 cetane-subtype-id=0 blend-subtype-id=9 consumable-id=4 additive-id=2 mode-id=5
install-bootstrap-test: normal page transcript - {"statuses":["Loading…","Connected · current on navigation"],"markers":[null],"gasoline":true,"diesel":true,"emptyState":true}
install-bootstrap-test: fixture 132 PASS - starting Obelisk delivers the queued install and makes Rover ready before any page load
```

The counter required an Obelisk poke as its positive control. Before the first
page load, it observed one install probe, one schema pour, one starter check,
one starter write, zero lazy probes, and zero view queries.

### Fixture 134: interim lazy path and late queued probe

Command:

```text
bash bin/install-bootstrap-test.sh /home/michael/piers/rover-install-release-interim-bel interim-lazy
```

Output:

```text
install-bootstrap-test: interim transcript - waiting-lazy-marker=performed initial-starter-writes=1 late-queued-install-probe=1 late-pours=0 late-starter-writes=0
install-bootstrap-test: row counts before late completion - energy-definition-id=8 subtype-id=32 octane-subtype-id=11 cetane-subtype-id=0 blend-subtype-id=9 consumable-id=4 additive-id=2 mode-id=5
install-bootstrap-test: row counts after late completion  - energy-definition-id=8 subtype-id=32 octane-subtype-id=11 cetane-subtype-id=0 blend-subtype-id=9 consumable-id=4 additive-id=2 mode-id=5
install-bootstrap-test: fixture 134 PASS - the waiting page observes one completed seed, and a later queued install probe changes no starter rows
```

This fixture suspends the Obelisk desk after the marked lazy response. It then
hard-resets only Rover's agent state and reinstalls Rover. Gall queues the new
request-less install probe. When Obelisk revives, the probe finds the populated
database and sends no pour, starter check, or starter write. The hard reset is
destructive to Rover's state on this dedicated disposable pier. It does not
delete the Rover database.

## Full UI gate

Command:

```text
bash bin/ui-test.sh /home/michael/piers/rover-statscope-bel
```

Bootstrap, status, and install output:

```text
ui-test: status normal transcript - {"statuses":["Loading…","Connected · current on navigation"],"markers":[null],"gasoline":true,"diesel":true,"emptyState":true}
ui-test: fixture 129 PASS - a normal first paint says Loading and no response marker makes a bootstrap claim
ui-test: fixture 124 PASS - a genuine database refusal names the failed view query and exposes no bare HTTP status
ui-test: install bootstrap transcript - page-loads=0 install-probes=1 pours=1 starter-checks=1 starter-writes=1 database=present starters=Gasoline|Diesel
ui-test: fixture 131 PASS - on-init creates and seeds Rover before the first page load
ui-test: install idempotence transcript - install-probes=1 pours=0 before=fills=0 starter-energy-definitions=8 after=fills=0 starter-energy-definitions=8
ui-test: fixture 133 PASS - install against populated Rover re-pours nothing and changes no row counts
ui-test: fixture 128 PASS - the cold path proves the probe counter is live before any zero-probe assertion
ui-test: status bootstrap transcript - {"statuses":["Loading…","Setting up the database…","Connected · current on navigation"],"markers":["performed"],"gasoline":true,"diesel":true,"emptyState":true}
ui-test: fixture 130 PASS - a response that performs bootstrap carries the marker and the shell echoes the setup status
ui-test: fixture 122 PASS - a cold GET creates the database, seeds starters, and serves the usable empty state
ui-test: fixture 125 PASS - the second view skips the database probe
ui-test: fixture 126 PASS - the saved latch skips the probe after restart and keeps the data
ui-test: fixture 127 PASS - one failed latched view re-probes, restores the database, and serves
```

Required statscope output and final verdict:

```text
ui-test: fixture 117 PASS - the real import endpoint added a 30-fill vehicle and a 3-fill vehicle
ui-test: fixture 118 PASS - the selected 3-fill diesel vehicle keeps its honest interval refusal
ui-test: fixture 119 PASS - History and Statistics page inside the selected 30-fill vehicle
ui-test: fixture 120 PASS - page 2 stays inside the selected vehicle and serves its last 5 fills
ui-test: fixture 121 PASS - GET serves both defaults and the old bare-page POST stays compatible
ui-test: fixture 123 PASS - a populated view does not re-pour, re-seed, or change fill and starter counts
ui-test: COVERAGE - ran 82 of 110 defined fixtures
```

Fixtures 117 through 128 all passed. The gated fixture list does not include
any fixture in that range.

## Schema gate

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

## Pier notes

All absent-Obelisk scenarios used fresh dedicated `~bel` piers. The first
rehearsal pier, `rover-install-queued-bel`, exited while Obelisk compiled. It
held no user data. Its files remain on disk. No test touched `fakezod`,
`fakenec`, or the publishing moon.
