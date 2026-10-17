#!/bin/sh
# A child that names spotless-maven-plugin in its <plugins> has its Java checked by google-java-format in its
# AOSP style when it validates: a misformatted file fails 'validate', naming the file, and a formatted one passes.
# A child that does not name the plugin is not checked, so a repository switches the check on by itself.
#
# Run from the repository root: test/misformatted-java-fails.sh [maven command, default ./mvnw]
set -eu
MVN="${1:-./mvnw}"
ROOT="$(pwd)"
VERSION="$(sed -n 's|^    <version>\(.*\)</version>$|\1|p' pom.xml | head -1)"
BASE="$ROOT/target/misformatted-java-fails"
rm -rf "$BASE"
FAULTS=0

# child NAME PLUGINS: a child project of this pom under $BASE/NAME, with PLUGINS as its <build><plugins>.
child() {
    mkdir -p "$BASE/$1/src/main/java/example"
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
    <packaging>jar</packaging>
    <build>
        <plugins>$2</plugins>
    </build>
</project>
EOF
}

# Formatted as google-java-format --aosp prints it.
formatted() {
    cat > "$BASE/$1/src/main/java/example/Formatted.java" <<'EOF'
package example;

/** A class as the formatter leaves it. */
public final class Formatted {

    private Formatted() {}

    /**
     * Adds two numbers.
     *
     * @param a the first
     * @param b the second
     * @return their sum
     */
    public static int add(int a, int b) {
        return a + b;
    }
}
EOF
}

# Two-space indents, a brace on its own line and a statement run together: what the AOSP style refuses.
misformatted() {
    cat > "$BASE/$1/src/main/java/example/Misformatted.java" <<'EOF'
package example;

/** A class indented against the style. */
public final class Misformatted
{
  private Misformatted() {}

  /** Adds two numbers. */
  public static int add(int a,int b){ return a+b; }
}
EOF
}

SPOTLESS='
            <plugin>
                <groupId>com.diffplug.spotless</groupId>
                <artifactId>spotless-maven-plugin</artifactId>
            </plugin>'

# validate NAME: runs 'validate' on the child, its output in $BASE/NAME.log; the exit code is Maven's.
validate() {
    "$MVN" -B -s settings.xml -f "$BASE/$1/pom.xml" validate > "$BASE/$1.log" 2>&1
}

child formatted "$SPOTLESS"
formatted formatted
if validate formatted; then
    echo "OK    a child naming spotless-maven-plugin validates a file formatted in the AOSP style"
else
    echo "FAULT a child naming spotless-maven-plugin did not validate a formatted file; asked 'validate', got:"
    cat "$BASE/formatted.log"
    FAULTS=$((FAULTS + 1))
fi

child misformatted "$SPOTLESS"
formatted misformatted
misformatted misformatted
if validate misformatted; then
    echo "FAULT a child naming spotless-maven-plugin validated a misformatted file; asked 'validate', got exit 0:"
    cat "$BASE/misformatted.log"
    FAULTS=$((FAULTS + 1))
elif grep -q 'spotless-maven-plugin.*had format violations' "$BASE/misformatted.log" \
        && grep -q 'src/main/java/example/Misformatted.java' "$BASE/misformatted.log" \
        && ! grep -q 'src/main/java/example/Formatted.java' "$BASE/misformatted.log"; then
    echo "OK    a child naming spotless-maven-plugin fails 'validate' on a misformatted file, naming it alone"
else
    echo "FAULT 'validate' failed, but not by spotless naming Misformatted.java alone; got:"
    cat "$BASE/misformatted.log"
    FAULTS=$((FAULTS + 1))
fi

child unchecked ""
misformatted unchecked
if validate unchecked; then
    echo "OK    a child that does not name spotless-maven-plugin is not checked"
else
    echo "FAULT a child that does not name spotless-maven-plugin failed 'validate'; got:"
    cat "$BASE/unchecked.log"
    FAULTS=$((FAULTS + 1))
fi

[ "$FAULTS" -eq 0 ] || { echo "FAULT $FAULTS of 3 cases"; exit 1; }
