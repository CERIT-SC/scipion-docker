#!/bin/bash

docker save jhandl/scipion-mn:tool > scipion-mn.tar
microk8s.ctr image import scipion-mn.tar
