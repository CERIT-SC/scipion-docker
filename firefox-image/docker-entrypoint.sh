#!/bin/bash

set -xe

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}

# run base-image's docker-entrypoint-base.sh
dir_dataset="/mnt/vol-dataset"
dir_project="/mnt/vol-project"
ln -s "${dir_dataset}/" "${S_USER_HOME}/ScipionUserData/dataset"
ln -s "${dir_project}/" "${S_USER_HOME}/ScipionUserData/projects" # this should be the only occurence of the word "projects" (plural) instead of "project". Scipion requires this directory

export DISPLAY="scipion-master-svc-x11-${INSTANCE_NAME}:1"

echo "firefox args: $FIREFOX_ARGS"

firefox $FIREFOX_ARGS

