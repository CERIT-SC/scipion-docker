#!/bin/bash

set -e

cd "$(dirname "$0")"

if [ "$1" != "--nobase" ]; then
        ../base-image/build.sh
fi

docker build -t jhandl/scipion-master:latest .
docker build -t hub.cerit.io/josef_handl/scipion-master:latest .

docker push jhandl/scipion-master:latest
docker push hub.cerit.io/josef_handl/scipion-master:latest

