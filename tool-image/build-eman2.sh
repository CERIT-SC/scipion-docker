#!/bin/bash

export plugin="scipion-em-eman2"
docker build -t jhandl/scipion-tool:$plugin --build-arg SD_PLUGIN="$plugin" .
docker push jhandl/scipion-tool:$plugin

