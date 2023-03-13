#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

docker build -t hub.cerit.io/scipion/scipion-controller:$tag .

docker push hub.cerit.io/scipion/scipion-controller:$tag
