#!/bin/bash

set -xe

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}

# run base-image's docker-entrypoint-base.sh
dir_dataset="/mnt/vol-dataset"
dir_project="/mnt/vol-project"
ln -s "${dir_dataset}/" "${S_USER_HOME}/ScipionUserData/dataset"
ln -s "${dir_project}/" "${S_USER_HOME}/ScipionUserData/projects" # this should be the only occurence of the word "projects" (plural) instead of "project". Scipion requires this directory

export DISPLAY="${INSTANCE_PREFIX}-${INSTANCE_NAME}-x11:1"

# Wait for the xorg (vnc container) (existency of xauthority means that xserver in the vnc container is running)
while [ ! -f /mnt/shared/.Xauthority ]; do
    sleep 2
done
# set target to the shared xauthority and extract cookie
export XAUTHORITY=/mnt/shared/.Xauthority
x11_cookie="$(echo $(xauth list) | awk '{print $3}')"
# set target to the correct path of the local xauthority and create new entry with the cookie
export XAUTHORITY=${S_USER_HOME}/.Xauthority
xauth add "${DISPLAY}" "MIT-MAGIC-COOKIE-1" "${x11_cookie}"


echo "firefox args: $FIREFOX_ARGS"

firefox $FIREFOX_ARGS

