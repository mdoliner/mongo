#!/bin/bash
tags=""
if [ ! -z "$1" ]
  then
  	tags="$@"
fi

# make sure we're in the directory where the script lives
SCRIPT_DIR="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
cd $SCRIPT_DIR
OUTPUT_DIR="$SCRIPT_DIR/testing_output"
mkdir -p "$OUTPUT_DIR"

. ./set_goenv.sh
set_goenv || exit

# remove stale packages
rm -rf vendor/pkg

ec=0

# Run all tests depending on what flags are set in the environment
for i in $(find . -iname *.go | grep -v '^\./vendor/' | sed -e 's/\(.*\)\/.*\.go/\1/' | sort -u); do 
        echo "Testing ${i}/..."
        COMMON_SUBPKG=$(basename $i)
        COVERAGE_ARGS="";
        if [ "$RUN_COVERAGE" = "true" ]; then
          export COVERAGE_ARGS="-coverprofile=coverage_$COMMON_SUBPKG.out"
        fi
        if [ "$ON_EVERGREEN" = "true" ]; then
            (cd $i && go test "$(print_tags $tags)" "$COVERAGE_ARGS" > "$OUTPUT_DIR/$COMMON_SUBPKG.suite")
            exitcode=$?
            cat "$OUTPUT_DIR/$COMMON_SUBPKG.suite"
            # Evergreen looks for test files here
            cp "$OUTPUT_DIR/$COMMON_SUBPKG.suite" "$SCRIPT_DIR"
        else
            (cd $i && go test "$(print_tags $tags)" "$COVERAGE_ARGS" )
            exitcode=$?
        fi
        if [ $exitcode -ne 0 ]; then
            echo "Error testing $i"
            ec=1
        fi
done

if [ -t /dev/stdin ]; then
    stty sane
fi

exit $ec
