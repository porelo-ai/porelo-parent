# Parent Requirements

What the parent pom and its build must do for every Porelo Maven repository. One file per requirement,
`PA<nn>-Short-Title.md`, each with its acceptance criteria; the number is identity, not order.

Grouped by state, in the order [workflow.yml](workflow.yml) gives; within a group the order is what to do next. A
group with nothing in it is left out. A finished requirement's file is deleted once what outlives it is in the
repository's documents.

## Finished

| # | Title | What was built |
|---|---|---|
| <a id="pa02"></a>PA02 | The Issue Heads Are Checked Every Day | Once a day and by hand, the Workflow check runs porelo-release's `issues check issues` over every issue head under `issues/` and fails on one that does not hold the issue format. |
| <a id="pa01"></a>PA01 | The Parent's Build Takes Its Downloads From The Cache | The Build, its Publish job and the Workflow check take Maven's dependencies and the pinned shfmt from the Actions cache, keyed by what each entry holds, and shfmt is checked against its digest after a hit too. |
