# PA02 — The Issue Heads Are Checked Every Day

```json
{
  "$schema": "issue-1.json",
  "id": "PA02",
  "title": "The Issue Heads Are Checked Every Day",
  "state": "Backlog",
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
