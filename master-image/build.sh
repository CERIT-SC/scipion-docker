#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

if [ "$1" != "--nobase" ]; then
        ../base-image/build.sh
fi

docker build -t jhandl/scipion-master:$tag .
docker build -t hub.cerit.io/josef_handl/scipion-master:$tag .

docker push jhandl/scipion-master:$tag
docker push hub.cerit.io/josef_handl/scipion-master:$tag

