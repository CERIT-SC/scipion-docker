#!/bin/bash

cd "$(dirname "$0")"

docker build -t jhandl/scipion-cloner:latest .
docker push jhandl/scipion-cloner:latest
