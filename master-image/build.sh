#!/bin/bash

docker build -t jhandl/scipion-base:tool ../base-image/
docker build  -t jhandl/scipion-mn:tool .
