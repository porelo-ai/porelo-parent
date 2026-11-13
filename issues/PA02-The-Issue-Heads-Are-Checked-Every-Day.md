# PA02 — The Issue Heads Are Checked Every Day

```json
{
  "$schema": "issue-1.json",
  "id": "PA02",
  "title": "The Issue Heads Are Checked Every Day",
  "state": "Review",
  "size": "XS",
  "priority": "Low",
  "rank": 2,
  "blockedBy": [],
  "covers": "A daily run checks every issue head under issues/ with porelo-release's `issues check issues`, so a head that breaks the issue format is found within a day."
}
```

**Why this size.** one scheduled step taken as it stands from the released `porelo-release`; no code.

Filed 2026-11-12 as this repository's part of the shared daily check of issue heads that `porelo-buildtools` added
to its own Shared rules check.

**What must be true.** Once a day, and by hand, a workflow of this repository checks every issue head under
`issues/` with `porelo-release`'s `issues check issues`, and fails on a head that does not hold the issue format.

## Plan

- This repository has no scheduled check today (`build.yml`, `delete-runs.yml`, `workflows.yml`). Add the step as a
  scheduled job in `workflows.yml`, which already runs without a rented machine, calling the released
  `porelo-release`.
- Run the same command on the host on the exact commit before the hand-over.

## Acceptance

- A dispatched run shows the step and passes on today's issues; a head with an unknown state, tried locally, makes the
  same command fail.

## What is built

- `workflows.yml` runs on a schedule (03:23 UTC daily) and by hand besides its pull request trigger, and its last step
  is `porelo-release issues check issues`, after the steps it had.
- No release of `porelo-release` holds `issues check` (0.5.1 is older than the issue heads), so the step runs on
  porelo-buildtools' snapshot `0.5.3-SNAPSHOT`, as Porelo's artifacts may be pinned. `settings.xml` gains the profile
  `buildtools-snapshots` with Central's snapshot repository, which only that workflow turns on; `.mvn/rrf/` lets that
  repository answer the group `org.fuin.porelo` alone, the same filter as in the agent repositories, switched on in the
  workflow's command, since this repository keeps `.mvn/maven.config` machine-local. The Build reads Central alone.
- Tried with porelo-buildtools' main: the command passes on this repository's issues and fails on a copy whose head
  has an unknown state. The workflow's resolution, run on the build box, took `porelo-release` 0.5.3-SNAPSHOT from
  Central's snapshots, and that snapshot's `issues check issues` passed on this repository's issues.
