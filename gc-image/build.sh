#!/bin/bash

docker build -t jhandl/scipion-gc:latest .
docker push jhandl/scipion-gc:latest
