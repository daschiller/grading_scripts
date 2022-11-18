#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-only
# Copyright (c) 2022 David Schiller <david.schiller@jku.at>

#set -eux
shopt -s nullglob extglob

# can be overridden by environment
SEP=${SEP-","}
TIMEOUT=${TIMEOUT-15}

TARGET="$(readlink -f "$1")"

usage() {
    echo "Usage: $(basename "$0") TARGET"
    echo "Runs unit tests in working directory for every python script in TARGET and prints results sorted per student."
}

if [ $# != 1 ]; then
    usage
    exit
fi
[ -d "$TARGET" ] || {
    echo "Error: TARGET needs to be a directory" >&2
    usage
    exit 1
}
UNITTESTS="$(echo ex*_unittest.py)"
[ -n "$UNITTESTS" ] || {
    echo "Error: no unit tests found in working directory" >&2
    usage
    exit 1
}

run_dir() {
    readarray -t students <<<"$(find "$TARGET" -type f -exec basename {} \; | cut -d'_' -f1 | sort | uniq)"
    for student in "${students[@]}"; do
        echo -n "$student""$SEP"
        for unittest in $UNITTESTS; do
            exercise="${unittest%%_*}".py
            ex_nr="$(grep -Po 'ex\K\d+' <<<"$unittest")"
            submission="$(echo "$TARGET"/"$student"*ex"$ex_nr".py)"
            if [ -n "$submission" ]; then
                cp "$submission" "$exercise"

                # when "timeout" times out, it returns 124
                points="$(
                    timeout "$TIMEOUT" python3 -u ./"$unittest" </dev/null |
                        grep -Po '^(Moodle points|Estimated points upon submission): \K\d+\.?\d*'
                    [ "${PIPESTATUS[0]}" != 124 ]
                )"
                [ "$?" -eq 1 ] && points="TIMEOUT"
                [ -z "$points" ] && points="ERROR"

                rm ./"$exercise"
            else
                points="-"
            fi

            echo -ne "$points""$SEP"
        done
        echo ""
    done
}

print_header() {
    # this prints a UTF-8 byte order mark to get MS Excel to accept UTF-8 CSV
    echo -ne "\xEF\xBB\xBF"
    echo -ne name"$SEP"
    for unittest in $UNITTESTS; do
        echo -ne "${unittest%%_*}""$SEP"
    done
    echo -e feedback
}

print_header
run_dir
