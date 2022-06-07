#!/bin/bash

cd "$(dirname "$0")"

docker build -t jhandl/scipion-controller:latest .
docker push jhandl/scipion-controller:latest
