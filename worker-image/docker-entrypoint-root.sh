#!/bin/bash
set -e

# run base-images's docker-entrypoint-base.sh
/docker-entrypoint-base.sh

su -c ./docker-entrypoint.sh $S_USER

