#!/bin/sh
# The task image's GraalVM (porelo.yml) must be the archive and digest porelo-machines pins at porelo.buildtools.version:
# porelo.yml is moved by hand, and a stale copy builds every task on a JDK the pin has left, a vulnerable one among them.
#
# Run from the repository root: test/task-image-follows-machines-pin.sh [maven command, default ./mvnw] [task image file,
# default porelo.yml]. Maven's own flags, such as the snapshot repository filter, come from MAVEN_ARGS, which Maven reads.
set -eu
MVN="${1:-./mvnw}"
IMAGE="${2:-porelo.yml}"
OUT="$(pwd)/target/task-image-follows-machines-pin"
rm -rf "$OUT"
mkdir -p "$OUT"
"$MVN" -B -q -s settings.xml -Pci-tools,buildtools-snapshots dependency:build-classpath \
    -Dmdep.outputFile="$OUT/cp.txt" >"$OUT/maven.log" 2>&1 || {
    cat "$OUT/maven.log"
    echo "FAULT porelo-machines at porelo.buildtools.version could not be resolved"
    exit 1
}
JAR="$(tr ':' '\n' <"$OUT/cp.txt" | grep '/porelo-machines-[^/]*\.jar$' | head -1)"
[ -n "$JAR" ] || {
    echo "FAULT the ci-tools class path names no porelo-machines jar"
    exit 1
}
unzip -p "$JAR" org/fuin/porelo/machines/machines.properties >"$OUT/machines.properties" || {
    echo "FAULT $JAR has no org/fuin/porelo/machines/machines.properties"
    exit 1
}
URL="$(sed -n 's|^graalvm\.url=||p' "$OUT/machines.properties")"
SHA="$(sed -n 's|^graalvm\.sha256=||p' "$OUT/machines.properties")"
TAG="$(printf '%s\n' "$URL" | sed -n 's|^.*/releases/download/\([^/][^/]*\)/[^/][^/]*$|\1|p')"
FILE="${URL##*/}"
[ -n "$URL" ] && [ -n "$SHA" ] && [ -n "$TAG" ] && [ -n "$FILE" ] || {
    echo "FAULT $JAR names no graalvm.url and graalvm.sha256 in machines.properties"
    exit 1
}
GOT_TAG="$(sed -n 's|^ *RUN tag=\([^ ]*\) file=.*$|\1|p' "$IMAGE")"
GOT_FILE="$(sed -n 's|^ *RUN tag=[^ ]* file=\([^ ]*\) .*$|\1|p' "$IMAGE")"
GOT_SHA="$(sed -n 's|^ *&& echo "\([0-9a-f]*\)  /tmp/graalvm\.tar\.gz" .*$|\1|p' "$IMAGE")"
# The address curl fetches, with the image's own $tag and $file put in, so a changed host or path is seen too.
# shellcheck disable=SC2016 # $tag and $file are the image's words, replaced here, not this shell's.
GOT_URL="$(sed -n 's|^ *"\(https://[^"]*\)" \\$|\1|p' "$IMAGE" | head -1 | sed -e "s|\$tag|$GOT_TAG|" -e "s|\$file|$GOT_FILE|")"
grep -q '^ *| sha256sum -c - \\$' "$IMAGE" || {
    echo "FAULT $IMAGE does not check the GraalVM archive with sha256sum -c"
    exit 1
}
if [ "$GOT_URL" = "$URL" ] && [ "$GOT_SHA" = "$SHA" ]; then
    echo "OK    $IMAGE installs $URL by sha256 $SHA, as porelo-machines pins"
    exit 0
fi
echo "FAULT $IMAGE installs '$GOT_URL' by sha256 '$GOT_SHA'; porelo-machines ($JAR) pins $URL by sha256 $SHA"
exit 1
