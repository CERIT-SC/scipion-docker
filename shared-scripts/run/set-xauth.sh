#!/bin/bash

set -e

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
