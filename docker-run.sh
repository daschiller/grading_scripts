#!/bin/bash

# make sure that DIR contains all the stuff that you need (submissions, unit tests)

if [ -d "$DIR" ]; then
    docker build -t grading .
    docker run --rm -it --user="$UID":"$GID" --name grading \
        -v "$DIR":/data grading
else
    echo "Improperly or unset DIR environment variable (needed for bind mount)"
fi
