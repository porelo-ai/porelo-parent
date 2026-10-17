#!/bin/sh
# A child that names spotless-maven-plugin in its <plugins> has its shell scripts checked by shfmt, which takes its
# indent from the shared .editorconfig: a script indented against it fails 'validate', naming the file, and a
# formatted one passes. The check needs the pinned shfmt on the PATH.
#
# Run from the repository root: test/misformatted-shell-fails.sh [maven command, default ./mvnw]
set -eu
MVN="${1:-./mvnw}"
ROOT="$(pwd)"
VERSION="$(sed -n 's|^    <version>\(.*\)</version>$|\1|p' pom.xml | head -1)"
BASE="$ROOT/target/misformatted-shell-fails"
rm -rf "$BASE"
FAULTS=0

# child NAME: a child project of this pom under $BASE/NAME that names the plugin, with the shared .editorconfig.
child() {
    mkdir -p "$BASE/$1/scripts"
    cp "$ROOT/.editorconfig" "$BASE/$1/.editorconfig"
    cat > "$BASE/$1/pom.xml" <<EOF
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
    <packaging>pom</packaging>
    <build>
        <plugins>
            <plugin>
                <groupId>com.diffplug.spotless</groupId>
                <artifactId>spotless-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF
}

# Four-space indents, as shfmt writes them under the shared .editorconfig.
formatted() {
    cat > "$BASE/$1/scripts/formatted.sh" <<'EOF'
#!/bin/sh
set -eu
if [ "$#" -gt 0 ]; then
    for arg in "$@"; do
        echo "$arg"
    done
fi
EOF
}

# Two-space and tab indents, and a 'then' on its own line.
misformatted() {
    printf '#!/bin/sh\nset -eu\nif [ "$#" -gt 0 ]\nthen\n  for arg in "$@"; do\n\techo "$arg"\n  done\nfi\n' \
        > "$BASE/$1/scripts/misformatted.sh"
}

# validate NAME: runs 'validate' on the child, its output in $BASE/NAME.log; the exit code is Maven's.
validate() {
    "$MVN" -B -s settings.xml -f "$BASE/$1/pom.xml" validate > "$BASE/$1.log" 2>&1
}

child formatted
formatted formatted
if validate formatted; then
    echo "OK    a child naming spotless-maven-plugin validates a script formatted with four-space indents"
else
    echo "FAULT a child naming spotless-maven-plugin did not validate a formatted script; asked 'validate', got:"
    cat "$BASE/formatted.log"
    FAULTS=$((FAULTS + 1))
fi

child misformatted
formatted misformatted
misformatted misformatted
if validate misformatted; then
    echo "FAULT a child naming spotless-maven-plugin validated a misformatted script; asked 'validate', got exit 0:"
    cat "$BASE/misformatted.log"
    FAULTS=$((FAULTS + 1))
elif grep -q 'spotless-maven-plugin.*had format violations' "$BASE/misformatted.log" \
        && grep -q 'scripts/misformatted.sh' "$BASE/misformatted.log" \
        && ! grep -q 'scripts/formatted.sh' "$BASE/misformatted.log"; then
    echo "OK    a child naming spotless-maven-plugin fails 'validate' on a misformatted script, naming it alone"
else
    echo "FAULT 'validate' failed, but not by spotless naming misformatted.sh alone; got:"
    cat "$BASE/misformatted.log"
    FAULTS=$((FAULTS + 1))
fi

[ "$FAULTS" -eq 0 ] || { echo "FAULT $FAULTS of 2 cases"; exit 1; }
