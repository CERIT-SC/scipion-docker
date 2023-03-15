#!/bin/bash

set -xe

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}

# run base-image's docker-entrypoint-base.sh
/docker-entrypoint-base.sh

export PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/VirtualGL/bin:/opt/TurboVNC/bin"

export DISPLAY=scipion-vnc-svc-x11-${INSTANCE_NAME}:1

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


tool_log_dir="/mnt/vol-project/scipion-docker/tool-logs"
tool_log_file="${tool_log_dir}/${HOSTNAME}.txt"

mkdir -p "${tool_log_dir}"

echo "cmd ${TOOL_COMMAND}" >> "${tool_log_file}"
echo "start_time \"$(date)\"" >> "${tool_log_file}"
${S_USER_HOME}/scipion3/scipion3 run $TOOL_COMMAND
echo "stop_time \"$(date)\"" >> "${tool_log_file}"
