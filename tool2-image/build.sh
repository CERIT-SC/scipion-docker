#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

if [ "$1" = "--base" ]; then
    ../base-image/build.sh
fi

docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:xmipp3-$tag -f Dockerfile.xmipp .

docker push hub.cerit.io/scipion/scipion-tool2:xmipp3-$tag

