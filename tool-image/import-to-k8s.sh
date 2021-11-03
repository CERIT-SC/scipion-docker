#!/bin/bash

while read plugin; do
    docker save jhandl/scipion-tool:$plugin > scipion-tool-$plugin.tar
    microk8s.ctr image import scipion-tool-$plugin.tar
done <plugin-list.txt
