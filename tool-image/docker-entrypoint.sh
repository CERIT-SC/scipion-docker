#!/bin/bash

set -xe

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}

ln -s ${S_USER_HOME}/ScipionUserData/ ${S_USER_HOME}/scipion3/data

export PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/VirtualGL/bin:/opt/TurboVNC/bin"

${S_USER_HOME}/scipion3/scipion3 run $TOOL_COMMAND
