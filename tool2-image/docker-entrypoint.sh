#!/bin/bash

set -xe

mkdir -p /mnt/shared/jobs
echo "running" > /mnt/shared/jobs/${JOB_NAME}

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}

# run base-image's docker-entrypoint-base.sh
/docker-entrypoint-base.sh

#export PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/VirtualGL/bin:/opt/TurboVNC/bin"
export DISPLAY=scipion-master-svc-x11-${INSTANCE_NAME}:1

# Required steps by the EMAN2
#unset LD_LIBRARY_PATH

#export PATH="/scipion-tool/relion/bin:${S_USER_HOME}/eman2-sphire-sparx/bin:${PATH}"

cd "$JOB_WORKDIR" #TODO <-----------

#${S_USER_HOME}/scipion3/scipion3 run $TOOL_COMMAND
echo "$TOOL_COMMAND"

#sleep infinity
$TOOL_COMMAND

echo "done" > /mnt/shared/jobs/${JOB_NAME}
