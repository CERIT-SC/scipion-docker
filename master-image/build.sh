#!/bin/bash

set -e

../base-image/build.sh
docker build -t jhandl/scipion-mn:tool .
docker push jhandl/scipion-mn:tool
