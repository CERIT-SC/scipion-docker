#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

docker build --build-arg RELEASE_CHANNEL="$tag" -t hub.cerit.io/scipion/scipion-vnc:$tag .

docker push hub.cerit.io/scipion/scipion-vnc:$tag
