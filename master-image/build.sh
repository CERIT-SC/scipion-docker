#!/bin/bash

set -e

cd "$(dirname "$0")"

if [ "$1" != "--nobase" ]; then
        ../base-image/build.sh
fi

docker build -t jhandl/scipion-mn:tool .
docker push jhandl/scipion-mn:tool
