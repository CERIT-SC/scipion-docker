#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

if [ "$1" = "--base" ]; then
    ../base-image/build.sh
fi

docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:base-dev -f Dockerfile.base .
docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:all-dev -f Dockerfile.all .

docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:xmipp3-$tag -f Dockerfile.xmipp3 .
#docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:eman2-$tag -f Dockerfile.eman2 .
#docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:relion-$tag -f Dockerfile.relion .
#docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:cistem-$tag -f Dockerfile.cistem .
#docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-tool2:spider-$tag -f Dockerfile.spider .

docker push hub.cerit.io/scipion/scipion-tool2:xmipp3-$tag
#docker push hub.cerit.io/scipion/scipion-tool2:eman2-$tag
#docker push hub.cerit.io/scipion/scipion-tool2:relion-$tag
#docker push hub.cerit.io/scipion/scipion-tool2:cistem-$tag
#docker push hub.cerit.io/scipion/scipion-tool2:spider-$tag
