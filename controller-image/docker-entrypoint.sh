#!/bin/bash

set -e

log="/mnt/shared/instance.log"

touch "$log"
unbuffer /cloner.py > "$log" 2>&1 &

tail -f "$log" & pid_tail=$!

pid_cloner=""
while [ -z "$pid_cloner" ]; do
    sleep 1
    pid_cloner=$(pgrep "cloner.py")
done

#echo "cloner PID: ${pid_cloner}"

_trap () {
    kill "$pid_cloner"
    sleep 2
    kill "$pid_tail"
}

#trap "echo trap" SIGTERM
trap "_trap" SIGINT SIGTERM

wait "$pid_tail"

