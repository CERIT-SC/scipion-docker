#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

#docker build -t jhandl/scipion-controller:$tag .
docker build -t hub.cerit.io/josef_handl/scipion-controller:$tag .

#docker push jhandl/scipion-controller:$tag
docker push hub.cerit.io/josef_handl/scipion-controller:$tag

