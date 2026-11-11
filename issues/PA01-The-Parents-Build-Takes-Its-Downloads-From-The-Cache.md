# PA01 — The Parent's Build Takes Its Downloads From The Cache

```json
{
  "$schema": "issue-1.json",
  "id": "PA01",
  "title": "The Parent's Build Takes Its Downloads From The Cache",
  "state": "Implementing",
  "size": "S",
  "priority": "Medium",
  "rank": 1,
  "blockedBy": [],
  "covers": "porelo-parent's workflows take Maven's dependencies and the pinned shfmt from the Actions cache, keyed by what pins them, and keep only the newest entry of each."
}
```

**Why this size.** cache steps in two workflows and one pruning step; no code.

Filed 2026-11-11 as this repository's part of `porelo-project` ST317, "Builds take outside downloads from a cache".

**What must be true.** Every download from outside GitHub that a build of porelo-parent makes comes from the Actions
cache after its first run, and the cache holds only the newest state of each.

How it is today, read in the workflows:

- `build.yml` (build and deploy) and `workflows.yml` cache the wrapper's Maven only; `verify`, `deploy` and
  `dependency:build-classpath` fetch every plugin and dependency from Maven Central on each run.
- `build.yml`'s step "The pinned shfmt" fetches shfmt from GitHub's release download with curl on each run.

## Plan

- Cache Maven's local repository keyed by `hashFiles('**/pom.xml')`, and shfmt by its pinned digest, as porelo's
  `pinned-jdk` does.
- After saving a new entry, delete the older entries of the same cache (`gh cache delete` by prefix).

## Acceptance

- A second run on one commit downloads nothing from Maven Central or the shfmt release; the cache list holds one entry
  per cache.
