#!/bin/sh
# A child of this pom, built under the forge profile, deploys its snapshot unsigned to MAVEN_SNAPSHOTS_URL - only when
# it opts in with skipPublishing, as under the release profile - and a build without that address fails instead of
# deploying somewhere else. The children are snapshots of their own, whatever the parent's version: the profile has
# no release repository, so at a release commit a child inheriting the parent's version is refused, as it should be.
#
# Run from the repository root: test/child-deploys-to-forge.sh [maven command, default ./mvnw]
set -eu
MVN="${1:-./mvnw}"
ROOT="$(pwd)"
VERSION="$(sed -n 's|^    <version>\(.*\)</version>$|\1|p' pom.xml | head -1)"
WORK="$ROOT/target/child-deploys-to-forge"
rm -rf "$WORK"
mkdir -p "$WORK"

# child <name> <skipPublishing>: a pom-packaged child at target/child-deploys-to-forge/<name>.
child() {
    mkdir -p "$WORK/$1"
    cat > "$WORK/$1/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.fuin.porelo</groupId>
        <artifactId>porelo-parent</artifactId>
        <version>$VERSION</version>
        <relativePath>../../../pom.xml</relativePath>
    </parent>
    <artifactId>$1</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>
    <properties>
        <skipPublishing>$2</skipPublishing>
    </properties>
</project>
EOF
}

# deploy <name> <registry directory or empty for no address>: the forge's deploy step, as build.yml runs it.
deploy() {
    if [ -n "$2" ]; then
        MAVEN_SNAPSHOTS_URL="file://$2" PORELO_PUBLISHER_TOKEN=placeholder \
            "$MVN" -B -q -s settings.xml -f "$WORK/$1/pom.xml" deploy -Pforge-release -Dgpg.signer=bc
    else
        env -u MAVEN_SNAPSHOTS_URL PORELO_PUBLISHER_TOKEN=placeholder \
            "$MVN" -B -q -s settings.xml -f "$WORK/$1/pom.xml" deploy -Pforge-release -Dgpg.signer=bc
    fi
}

fault() {
    echo "FAULT $1"
    exit 1
}

child opted-in false
REGISTRY="$WORK/registry-opted-in"
deploy opted-in "$REGISTRY" || fault "a child that opts in failed to deploy under -Pforge-release"
DEPLOYED="$REGISTRY/org/fuin/porelo/opted-in/1.0.0-SNAPSHOT"
ls "$DEPLOYED"/opted-in-*.pom > /dev/null 2>&1 \
    || fault "a child that opts in deployed no pom to MAVEN_SNAPSHOTS_URL; found: $(find "$REGISTRY" -type f 2> /dev/null)"
SIGNED="$(find "$REGISTRY" -name '*.asc')"
[ -z "$SIGNED" ] || fault "the forge profile signed what it deployed: $SIGNED"
echo "OK    a child that opts in deploys its snapshot, unsigned, to MAVEN_SNAPSHOTS_URL"

child not-opted-in true
REGISTRY="$WORK/registry-not-opted-in"
deploy not-opted-in "$REGISTRY" || fault "a child that does not opt in failed the build under -Pforge-release"
[ ! -e "$REGISTRY" ] || fault "a child that does not opt in deployed: $(find "$REGISTRY" -type f)"
echo "OK    a child that does not opt in deploys nothing"

if deploy opted-in "" > "$WORK/no-address.log" 2>&1; then
    fault "a deploy under -Pforge-release without MAVEN_SNAPSHOTS_URL succeeded"
fi
grep -q 'MAVEN_SNAPSHOTS_URL, which is not set' "$WORK/no-address.log" \
    || fault "a deploy without MAVEN_SNAPSHOTS_URL failed without naming it: $(tail -5 "$WORK/no-address.log")"
echo "OK    a deploy under -Pforge-release without MAVEN_SNAPSHOTS_URL fails and names it"
