#!/bin/bash

export plugin="scipion-em-xmipp3"
docker build -t jhandl/scipion-tool:$plugin .
docker push jhandl/scipion-tool:$plugin

