#!/bin/bash

cd "$(dirname "$0")"

docker build -t jhandl/scipion-firefox:latest .
docker build -t hub.cerit.io/josef_handl/scipion-firefox:latest .

docker push jhandl/scipion-firefox:latest
docker push hub.cerit.io/josef_handl/scipion-firefox:latest

