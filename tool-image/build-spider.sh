#!/bin/bash

export plugin="scipion-em-spider"
docker build -t jhandl/scipion-tool:$plugin --build-arg SD_PLUGIN="$plugin" .
docker push jhandl/scipion-tool:$plugin

