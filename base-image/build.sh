#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

#docker build -t jhandl/scipion-base:$tag .
docker build -t hub.cerit.io/scipion/scipion-base:$tag .

#docker push jhandl/scipion-base:$tag
docker push hub.cerit.io/scipion/scipion-base:$tag

