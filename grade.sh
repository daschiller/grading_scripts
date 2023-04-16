#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-only
# Copyright (c) 2022 David Schiller <david.schiller@jku.at>

#set -eux
shopt -s nullglob extglob

# can be overridden by environment
SEP=${SEP-","}
TIMEOUT=${TIMEOUT-15}

UNITTEST="$(readlink -f "$1")"
TARGET="$(readlink -f "$2")"

usage() {
    echo "Usage: $(basename "$0") UNITTEST TARGET"
    echo "Runs UNITTEST for every python script in TARGET and prints results as CSV."
    echo "If TARGET is a regular file, the output of the unit test is printed instead."
}

if [ $# != 2 ]; then
    usage
    exit
fi

[[ "$UNITTEST" == *.py ]] || {
    echo "Error: UNITTEST needs to be a Python script" >&2
    usage
    exit 1
}
[ -e "$TARGET" ] || {
    echo "Error: TARGET needs to be a valid file or directory" >&2
    usage
    exit 1
}

cd "$(dirname "$UNITTEST")" || {
    echo "Error: cd to unit test directory failed" >&2
    exit 1
}

run_dir() {
    ex_nr="$(grep -Po 'ex\K\d+' "$UNITTEST")"
    for submission in "$TARGET"/*_ex${ex_nr}.*; do
        base="$(basename "$submission")"
        exercise="${base##*_}"
        cp -f "$submission" "$exercise"

        # when "timeout" times out, it returns 124
        points="$(
            timeout "$TIMEOUT" python3 -u ./"$(basename "$UNITTEST")" </dev/null |
                grep -Pao '^(Moodle points|Estimated points upon submission): \K\d+\.?\d*'
            [ "${PIPESTATUS[0]}" != 124 ]
        )"
        [ "$?" -eq 1 ] && points="TIMEOUT"
        [ -z "$points" ] && points="ERROR"

        name="${base%%_*}"

        echo -e "$name""$SEP""$points""$SEP"

        rm ./"$exercise"
    done
}

print_header() {
    # this prints a UTF-8 byte order mark to get MS Excel to accept UTF-8 CSV
    echo -ne "\xEF\xBB\xBF"
    echo -e name"$SEP"student_id"$SEP"points"$SEP"feedback
}

run_file() {
    base="$(basename "$TARGET")"
    exercise="${base##*_file_}"
    # copy reference solutions, if available
    if [ -d "reference/" ]; then
        cp -f reference/*.py .
    fi
    cp -f "$TARGET" "$exercise"

    python3 ./"$(basename "$UNITTEST")"

    rm ./"$exercise"
}

if [ -d "$TARGET" ]; then
    print_header
    run_dir
elif [ -f "$TARGET" ]; then
    run_file
fi
