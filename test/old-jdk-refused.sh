#!/bin/sh
# A child of this pom must refuse to build on a JDK open to the Base64 decoder's overflow (CVE-2026-114938), and
# build on the fixed one: the enforcer's floor is the only thing that keeps a vulnerable JDK from building every child.
#
# Run from the repository root: test/old-jdk-refused.sh <home of a JDK below 25.0.5.1> [maven command, default ./mvnw].
# The fixed JDK is JAVA_HOME.
set -eu
OLD="${1:?usage: test/old-jdk-refused.sh <home of a JDK below 25.0.5.1> [maven command]}"
MVN="${2:-./mvnw}"
ROOT="$(pwd)"
VERSION="$(sed -n 's|^    <version>\(.*\)</version>$|\1|p' pom.xml | head -1)"
CHILD="$ROOT/target/old-jdk-refused"
rm -rf "$CHILD"
mkdir -p "$CHILD"
cat >"$CHILD/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.fuin.porelo</groupId>
        <artifactId>porelo-parent</artifactId>
        <version>$VERSION</version>
        <relativePath>../../pom.xml</relativePath>
    </parent>
    <artifactId>old-jdk-refused</artifactId>
    <packaging>pom</packaging>
</project>
EOF
java_version() {
    "$1/bin/java" -XshowSettings:properties -version 2>&1 | sed -n 's|^ *java\.version = ||p'
}
OLD_VERSION="$(java_version "$OLD")"
[ -n "$OLD_VERSION" ] || {
    echo "FAULT $OLD is no JDK: its bin/java names no java.version"
    exit 1
}
NEW_VERSION="$(java_version "${JAVA_HOME:?JAVA_HOME names the fixed JDK}")"
[ -n "$NEW_VERSION" ] || {
    echo "FAULT JAVA_HOME $JAVA_HOME is no JDK: its bin/java names no java.version"
    exit 1
}
if JAVA_HOME="$OLD" "$MVN" -B -s settings.xml -f "$CHILD/pom.xml" validate >"$CHILD/old.log" 2>&1; then
    echo "FAULT a child validated on Java $OLD_VERSION ($OLD), which is open to CVE-2026-114938"
    exit 1
fi
grep -q 'CVE-2026-114938' "$CHILD/old.log" || {
    cat "$CHILD/old.log"
    echo "FAULT validate on Java $OLD_VERSION failed, but not with the enforcer's floor message"
    exit 1
}
echo "OK    a child refuses Java $OLD_VERSION with the floor's message"
"$MVN" -B -s settings.xml -f "$CHILD/pom.xml" validate >"$CHILD/new.log" 2>&1 || {
    cat "$CHILD/new.log"
    echo "FAULT a child does not validate on Java $NEW_VERSION ($JAVA_HOME)"
    exit 1
}
echo "OK    a child validates on Java $NEW_VERSION"
