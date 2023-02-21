#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

if [ "$1" = "--base" ]; then
    ../base-image/build.sh
fi

#docker build -t jhandl/scipion-master:$tag .
docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-master:$tag .

#docker push jhandl/scipion-master:$tag
docker push hub.cerit.io/scipion/scipion-master:$tag

