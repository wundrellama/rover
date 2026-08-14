# Handoff — publish Rover to the moon

Read `AGENTS.md` first. Load the `obelisk-substrate`, `gall-agents`, and
`urbit-desk-publishing` skills before work starts.

## Current source

The install bootstrap work is on branch `feat/install-bootstrap-status`. The
branch is not merged. Use the reported branch head from the completed install
bootstrap run. Do not publish an older `master` commit.

Evidence is in `RESULTS-INSTALL-BOOTSTRAP.md`. The full UI battery, the
68-relation schema battery, deferred Gall delivery, and late-probe idempotence
passed on real fake piers with Obelisk commit
`9de633299b373a1047490b48281a40b457fb2043`.

Gate 7 remains closed. Rover's shipping action union has five arms. The host
fixtures remain under `bin/` and `probes/`.

## Publishing target

The publish moon is `~naprys-nocsyp-dozzod-labbel`. Its pier is:

```text
/var/home/michael/workspace/urbit/moons/naprys-nocsyp-dozzod-labbel/
```

The runtime is beside it at:

```text
/var/home/michael/workspace/urbit/moons/urbit
```

Do not confuse this moon with `~ritheb-laplur-dozzod-labbel`. That is the
Hermes bot moon.

The publish moon holds the owner's real 420-fill corpus. Back it up before any
publication work. Do not use it as a test pier. Do not delete or reset agent
state on it.

## Obelisk pin

Obelisk must remain a separate desk. Rover is verified only against exact
commit `9de633299b373a1047490b48281a40b457fb2043` from
`~dister-nomryg-nilref`.

Install Obelisk, verify the source and commit, and start the app with its
explicit desk:

```text
|start %obelisk %obelisk
```

Stop if the distribution source has moved past the verified commit. Do not
vendor Obelisk or change Rover to accept a different substrate.

## Publication checks

Before each Rover desk commit, remove empty directories:

```text
find <pier>/rover -type d -empty -delete
```

Then verify all of these conditions on the moon:

1. `+vats %obelisk` and `+vats %rover` show live agents with no pending update.
2. The docket charge uses `site /apps/rover`, a same-origin tile, and no glob.
3. `GET /apps/rover/view` returns the rendered page.
4. The tile asset has the correct content type.
5. The database and starter pack exist without a first page load.
6. The import screen loads and accepts a Rover import document.
7. A moon restart preserves the desk and its data.

If any check fails, stop and record the actual result. Do not change the
verified Rover source on the moon.
