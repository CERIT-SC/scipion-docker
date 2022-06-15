#!/bin/bash

set -xe

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}

# run base-image's docker-entrypoint-base.sh
/docker-entrypoint-base.sh

export PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/VirtualGL/bin:/opt/TurboVNC/bin"

export DISPLAY=scipion-master-svc-x11:1

#echo "$TOOL_COMMAND" > ${S_USER_HOME}/ScipionUserData/`date +%s`.txt
#
#if [ "1" = `cat ${S_USER_HOME}/ScipionUserData/status.txt` ]; then
#	echo "0" > ${S_USER_HOME}/ScipionUserData/status.txt
#	#${S_USER_HOME}/scipion3/scipion3 run $TOOL_COMMAND
#	strace -f -o /home/scipionuser/ScipionUserData/`date +%s`.txt -s 2000 ${S_USER_HOME}/scipion3/scipion3 run $TOOL_COMMAND
#	echo "1" > ${S_USER_HOME}/ScipionUserData/status.txt
#else
#	touch ${S_USER_HOME}/ScipionUserData/fail.txt
#fi
#
#sleep 999999

${S_USER_HOME}/scipion3/scipion3 run $TOOL_COMMAND
