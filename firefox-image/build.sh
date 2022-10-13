#!/bin/bash

tag=${tag:-dev}

cd "$(dirname "$0")"

docker build -t jhandl/scipion-firefox:$tag .
docker build -t hub.cerit.io/josef_handl/scipion-firefox:$tag .

docker push jhandl/scipion-firefox:$tag
docker push hub.cerit.io/josef_handl/scipion-firefox:$tag

