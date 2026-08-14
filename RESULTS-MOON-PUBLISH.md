# Moon publish results

Date: 2026-08-14

Published commit: `f4efbfe`

Moon: `~naprys-nocsyp-dozzod-labbel`

Pier: `/var/home/michael/workspace/urbit/moons/naprys-nocsyp-dozzod-labbel`

## Reason for this publish

The moon served the earlier `master` build. That build trusted the `@f` bunt of
`bootstrap-ready`, which is `%.y`. A fresh install therefore claimed the
database was ready before any database existed. The first page load queried
`ui-view` against a database `%rover` that Obelisk had not created. Obelisk
refused the query and Rover printed the raw refusal to the dojo.

`~nomryg-nilsef` reported that trace after installing Rover. His ship recovered
on the same request. The recovery path created the database, poured the M0
schema, seeded the starters, and served the page.

Commit `7752df6` removes the cause. `on-init` now sets `bootstrap-ready` to
`%.n` and sends an install probe to Obelisk.

## Backup

The pier holds the owner's real fill corpus. The publish work started with a
clean shutdown and a full copy:

```text
/var/home/michael/workspace/urbit/moons/backups/naprys-20260814-131653/
```

Size 1.9G. The copy holds `.urb/log`, both snapshot directories, and all four
desks.

## Merge

The merge was fast-forward, so the log carries no merge commit.

```text
Updating 3184412..f4efbfe
Fast-forward
```

`origin/master` now points at `f4efbfe`.

## Desk source

The mount was stale, so the old unix directory was removed and remounted before
the sync. The desk was mirrored, pruned, and compared:

```text
find <pier>/rover -type d -empty -delete    -> 0 empty directories remain
diff -rq desk <pier>/rover                  -> IDENTICAL
git status --short                          -> clean
```

The published desk equals the reviewed commit. The working tree was not edited
to make the ship accept the desk.

The copied `sur/obelisk-ast.hoon` still hashes to
`e7fd9775da24a34ef2d12386247fa59426a0e1c00993de35b99ad672ba1006a2`.

## State migration

Both builds are state version `%17`, so the load ran no migration:

```text
gall: reloading %rover
gall: bumped %rover
```

No nest-fail. The fill count held at 423 across the commit, the install, and a
later restart.

## Treaty

`|commit` alone leaves the treaty advertising the previous snapshot. The
publish poke was re-run and the two hashes were compared:

```text
+vats %rover           %cz hash ends in: o8eoe
:treaty +dbug %state   hash=0vh.mlf3t.…o8eoe
```

The advertised artifact is the running artifact.

## Verification battery

| # | Check | Result |
|---|-------|--------|
| 1 | `+vats %rover` running, no pending updates | PASS |
| 2 | Docket charge, `site /apps/rover`, no glob | PASS |
| 3 | `GET /apps/rover/view` | `HTTP 200 text/html 350077 bytes` |
| 4 | Tile asset | `HTTP 200 image/png 373667 bytes`, PNG 512x512 |
| 5 | Database and starter pack present | PASS |
| 6 | Import screen loads | `HTTP 200 text/html 72268 bytes` |
| 7 | Restart preserves the desk and its data | PASS |

A logged-out request returns `HTTP 303` to the login page. It does not return
500.

The served page hashed the same before the publish, after the publish, and
after the restart:

```text
91d0213f16f2b7ff71557cd360a7a3e92765811bbdd031eb3275f82e21cd4123
```

One hash proves the desk, the agent state, and the database all survived.

The `X-Rover-Bootstrap` header was absent on every request. The database
already existed, so the new build performed no bootstrap. An absent marker is
the correct answer here.

## Obelisk

```text
+vats %obelisk
  source ship:  ~dister-nomryg-nilref
  app status:   running
  pending updates: ~
```

Obelisk stays a separate desk from its own publisher. Rover did not vendor it.

## Scope of the checks

Every check above ran on the publishing ship. The battery proves the desk runs
there. It does not exercise a remote first install. The install bootstrap path
was proven earlier on dedicated `~bel` piers, and that evidence is in
`RESULTS-INSTALL-BOOTSTRAP.md`.

No probe in this run wrote a row. The publish ship holds the owner's real data,
so the battery used read-only checks only.

## Known residual

`on-load` case `%17` passes the old state through without change. A ship that
installed the previous build and never opened the page carries
`bootstrap-ready` as `%.y`. That ship performs no install probe on upgrade. Its
first page load takes the recovery path and prints the refusal trace once,
then recovers.

The owner reviewed this case and chose to leave it. The reporting ship is not
in this class. It already opened the page, so its flag is honest.

The refusal trace at `desk/app/rover.hoon:3463` stays. After this publish it
fires only on a real failure, and it is the reason this defect was found.
