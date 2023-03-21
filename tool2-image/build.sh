#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

if [ "$1" = "--base" ]; then
    ../base-image/build.sh
fi

docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:base-dev -f Dockerfile.tool-base .

#docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:xmipp3-$tag -f xmipp3/Dockerfile.xmipp3 .
#docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:eman2-$tag -f eman2/Dockerfile.eman2 .
docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:relion-$tag -f relion/Dockerfile.relion .
#docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:cistem-$tag -f cistem/Dockerfile.cistem .

#docker push hub.cerit.io/scipion/scipion-tool2:xmipp3-$tag
#docker push hub.cerit.io/scipion/scipion-tool2:eman2-$tag
docker push hub.cerit.io/scipion/scipion-tool2:relion-$tag
#docker push hub.cerit.io/scipion/scipion-tool2:cistem-$tag
