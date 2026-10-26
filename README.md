# porelo-parent
Porelo Parent POM

[Contributing](CONTRIBUTING.md), and [reporting a vulnerability](SECURITY.md).

## Publishing a snapshot

The Publish step deploys under the profile named by the forge's variable `PORELO_DEPLOY_PROFILE`, and refuses any
other value:

- **`central-sonatype-release`** (GitHub): signed, to Sonatype's snapshots.
- **`forge-release`** (a local Forgejo): unsigned, to the Maven registry at `MAVEN_SNAPSHOTS_URL`, as the user
  `porelo-publisher` with the token in `PORELO_PUBLISHER_TOKEN`. A release version is refused.

A module built on this parent deploys under either profile when it sets `skipPublishing` to `false`.

On a local forge whose organization is private, the registry refuses an anonymous reader (`401`), and an
organization member's token reads it.
