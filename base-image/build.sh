#!/bin/bash

set -e

cd "$(dirname "$0")"

docker build -t jhandl/scipion-base:tool .
docker push jhandl/scipion-base:tool
