#!/bin/bash

set -e

d_scipion="/mnt/vol-project/scipion-docker"
f_log="${d_scipion}/instance.log"
f_status="${d_scipion}/instance-status"

mkdir -p "${d_scipion}"
rm "$f_status" || true
rm "$f_log" || true
touch "$f_log"

/controller-daemon.sh 2>&1 | tee -a "$f_log"

