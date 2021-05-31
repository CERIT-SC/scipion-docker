#!/bin/bash

docker save jhandl/scipion-tool:tool > scipion-tool.tar
microk8s.ctr image import scipion-tool.tar
