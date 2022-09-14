#!/bin/bash

set -e

cd "$(dirname "$0")"

docker build -t jhandl/scipion-base:latest .
docker build -t hub.cerit.io/josef_handl/scipion-base:latest .

docker push jhandl/scipion-base:latest
docker push hub.cerit.io/josef_handl/scipion-base:latest

