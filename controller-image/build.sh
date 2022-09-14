#!/bin/bash

cd "$(dirname "$0")"

docker build -t jhandl/scipion-controller:latest .
docker build -t hub.cerit.io/josef_handl/scipion-controller:latest .

docker push jhandl/scipion-controller:latest
docker push hub.cerit.io/josef_handl/scipion-controller:latest

