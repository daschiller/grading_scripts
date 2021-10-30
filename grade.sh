#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-only
# Copyright (c) 2021 David Schiller <david.schiller@jku.at>

#set -eux

SEP=","
TIMEOUT=15
UNITTEST="$(readlink -f "$1")"
DIR="$(readlink -f "$2")"

usage() {
    echo "Usage: $(basename "$0") UNITTEST DIR"
    echo "Runs UNITTEST for every python script within DIR and prints results as CSV."
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
[ -d "$DIR" ] || {
    echo "Error: DIR needs to be a directory" >&2
    usage
    exit 1
}

cd "$(dirname "$UNITTEST")" || {
    echo "Error: cd to unit test directory failed" >&2
    exit 1
}

run_unittest() {
    shopt -s nullglob
    for submission in "$DIR"/*assignsubmission*/*.py; do
        # copy, if linking fails (happens on non-Unix file systems)
        ln -sf "$submission" . || cp "$submission" .

        # when "timeout" times out, it returns 124
        points="$(
            timeout "$TIMEOUT" python3 -u ./"$(basename "$UNITTEST")" | grep -Po '^Moodle points: \K\d+'
            [ "${PIPESTATUS[0]}" != 124 ]
        )"
        [ "$?" -eq 1 ] && points="TIMEOUT"
        [ -z "$points" ] && points="ERROR"
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

print_header
run_unittest
