#!/bin/bash

set -e

cd "$(dirname "$0")"

base-image/build.sh

master-image/build.sh --nobase &
tool-image/build.sh --nobase &

wait
