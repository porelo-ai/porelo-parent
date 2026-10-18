# Contributing

Changes to porelo-parent follow the project's guide: how an issue is written, how a change is proposed and
reviewed, and what a commit carries. It is one page for every Porelo repository:
[Contributing to Porelo](https://porelo-ai.github.io/porelo-project/contributing/).

## In this repository

- **Building and testing:** JDK 25. `./mvnw -B verify` builds the parent POM, and the scripts in `test/` check what it
  makes every child do: publishing, and refusing misformatted Java and shell.
- **A change here reaches every Porelo repository** that names this parent, with its next version.
