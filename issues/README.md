# Parent Requirements

What the parent pom and its build must do for every Porelo Maven repository. One file per requirement,
`PA<nn>-Short-Title.md`, each with its acceptance criteria; the number is identity, not order.

Grouped by state, in the order [workflow.yml](workflow.yml) gives; within a group the order is what to do next. A
group with nothing in it is left out. A finished requirement's file is deleted once what outlives it is in the
repository's documents.

## Review

| # | Size | Blocked by | What it covers |
|---|---|---|---|
| <a id="pa01"></a>[PA01](PA01-The-Parents-Build-Takes-Its-Downloads-From-The-Cache.md) | S | - | porelo-parent's workflows take Maven's dependencies and the pinned shfmt from the Actions cache, keyed by what pins them, and keep only the newest entry of each. |
