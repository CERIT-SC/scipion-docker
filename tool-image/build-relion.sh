#!/bin/bash

export plugin="scipion-em-relion"
docker build -t jhandl/scipion-tool:$plugin --build-arg SD_PLUGIN="$plugin" --build-arg SD_BIN="relion-4.0" .
docker push jhandl/scipion-tool:$plugin

