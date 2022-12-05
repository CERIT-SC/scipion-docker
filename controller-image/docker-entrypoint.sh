#!/bin/bash

set -e

log="/mnt/shared/instance.log"

touch "$log"
unbuffer uvicorn controller-rest:app --reload > "$log" 2>&1 &

tail -f "$log" & pid_tail=$!

pid_controller=""
while [ -z "$pid_controller" ]; do
    sleep 1
    pid_controller=$(pgrep "uvicorn")
done

#echo "controller PID: ${pid_controller}"

_trap () {
    kill "$pid_controller"
    sleep 2
    kill "$pid_tail"
}

trap "_trap" SIGINT SIGTERM

wait "$pid_tail"
