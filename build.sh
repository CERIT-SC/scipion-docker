#!/bin/bash

set -e

cd "$(dirname "$0")"

controller-image/build.sh
firefox-image/build.sh

base-image/build.sh
master-image/build.sh --nobase

tool-image/build.sh --nobase

wait

