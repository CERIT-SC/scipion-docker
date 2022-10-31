#!/bin/bash

set -ex

log="/mnt/shared/instance.log"

touch "$log"
unbuffer /cloner.py > "$log" 2>&1 & pid_cloner=$!

tail -f "$log" & pid_tail=$!

_trap () {
    kill "$pid_cloner"
    sleep 2
    kill "$pid_tail"
}

#trap "echo trap" SIGTERM
trap "_trap" SIGINT SIGTERM

wait "$pid_cloner"
wait "$pid_tail"
