#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

#docker build -t jhandl/scipion-firefox:$tag .
docker build -t hub.cerit.io/scipion/scipion-firefox:$tag .

#docker push jhandl/scipion-firefox:$tag
docker push hub.cerit.io/scipion/scipion-firefox:$tag

