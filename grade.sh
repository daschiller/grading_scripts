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

command -v bc &>/dev/null || {
    echo "Error: bc (basic calculator) is not available" >&2
    usage
    exit 1
}

run_dir() {
    for submission in "$TARGET"/*assignsubmission*/ex+([0-9]).py; do
        cp "$submission" .

        # when "timeout" times out, it returns 124
        points="$(
            timeout "$TIMEOUT" python3 -u ./"$(basename "$UNITTEST")" </dev/null |
                grep -Po '^(Moodle points|Estimated points upon submission): \K\d+\.?d*'
            [ "${PIPESTATUS[0]}" != 124 ]
        )"
        [ "$?" -eq 1 ] && points="TIMEOUT"
        [ -z "$points" ] && points="ERROR"
        # if points is a float, we multiply by 10 to satisfy Moodle
        [[ $points == *.* ]] && points="$(bc <<<"$points * 10 / 1")"

        subdir="$(basename "$(dirname "$submission")")"
        subdir="${subdir//_assignsubmission_file_/}"
        name="${subdir%_*}"

        # some people have badly mangled the student ID field
        # this regex matches the submission guidelines
        # id="$(grep -Po 'Matr\.Nr\.: [aA]?[kK]?\K\d{7,8}' "$submission")"

        # this is a more relaxed one that should match all (reasonable) submissions
        student_id="$(grep -Po '^Mat[A-Za-z. ]*:\s*<?[aA]?[kK]?\K\d{7,8}' "$submission")"
        [ -z "$student_id" ] && student_id="IDERROR"

        echo -e "$name""$SEP""$student_id""$SEP""$points""$SEP"

        rm ./"$(basename "$submission")"
    done
}

print_header() {
    # this prints a UTF-8 byte order mark to get MS Excel to accept UTF-8 CSV
    echo -ne "\xEF\xBB\xBF"
    echo -e name"$SEP"student_id"$SEP"points"$SEP"feedback
}

run_file() {
    cp "$TARGET" .

    python3 ./"$(basename "$UNITTEST")"

    rm ./"$(basename "$TARGET")"
}

if [ -d "$TARGET" ]; then
    print_header
    run_dir
elif [ -f "$TARGET" ]; then
    run_file
fi
