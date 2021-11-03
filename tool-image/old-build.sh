#!/bin/bash

while read plugin; do
#    export SCIPION_DOCKER_PLUGIN=$plugin
#    envsubst < Dockerfile | docker build . -t jhandl/scipion-tool:$plugin -f -

#(trap 'kill 0' SIGINT; docker build -t jhandl/scipion-tool:$plugin --build-arg SCIPION_DOCKER_PLUGIN=$plugin . & )
     docker build -t jhandl/scipion-tool:$plugin --build-arg SCIPION_DOCKER_PLUGIN=$plugin .
done <plugin-list.txt
