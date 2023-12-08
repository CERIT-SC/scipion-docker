#!/bin/bash

set -xe

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}

/opt/shared-scripts/run/prepare-links.sh

source /opt/shared-scripts/run/set-xauth.sh


echo "firefox args: $FIREFOX_ARGS"

firefox $FIREFOX_ARGS

