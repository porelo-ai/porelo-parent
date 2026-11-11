# PA01 — The Parent's Build Takes Its Downloads From The Cache

```json
{
  "$schema": "issue-1.json",
  "id": "PA01",
  "title": "The Parent's Build Takes Its Downloads From The Cache",
  "state": "Review",
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

## As built

- `build.yml`, Build: Maven's local repository is cached with `actions/cache`, key
  `maven-repository-<os>-<hashFiles('**/pom.xml')>`, restore-keys `maven-repository-<os>-`; the Publish job has its own
  key, `maven-repository-publish-…`, since the Build's entry would hit there and never save the publishing plugins.
- `build.yml`, "The pinned shfmt": restored by `pinned-shfmt-<digest>` (the digest the release names, as porelo's
  `pinned-jdk` keys it), fetched only on a miss, checked against the digest after a hit too, and saved only after the
  check passed.
- `workflows.yml`, Workflow check: Maven's local repository for the release tooling, key
  `maven-repository-ci-tools-<os>-<tooling version>-<hashFiles('**/pom.xml')>`; the tooling's version moved into the
  job's `BUILDTOOLS_VERSION` so the key and the command read one value.
- Retention without `gh cache delete`: each key names what the entry holds, so a moved pom or pin gives a new key, the
  old entry is no longer read (a restore-key picks the newest entry only) and GitHub drops it seven days after its
  last read. No job needs `actions: write`. The plan's pruning step was dropped for this, as porelo's `build.yml` does.
- Not yet seen on a runner: the acceptance (a second run downloads nothing; one entry per cache) is read from the first
  two runs after this lands.

## After the code reading

agy (gemini) read the change: no harm found (shfmt is checked against its digest before it reaches the path or the
cache, the Publish job's key and restore prefix share nothing with a pull request's, every action is pinned and no job
gains a permission). Two keys did not name all they hold, fixed: the Build's Maven key also hashes `test/*.sh`, whose
child poms resolve the managed plugins, and the Publish key names the deploy profile, which picks its plugins.
