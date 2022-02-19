#!/bin/bash

set -xe

echo "docker-entrypoint.sh"

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}


ls -la ${S_USER_HOME}/scipion3/
ls -la ${S_USER_HOME}/ScipionUserData/
ls -la ${S_USER_HOME}
ln -s ${S_USER_HOME}/ScipionUserData/ ${S_USER_HOME}/scipion3/data

# run base-image's docker-entrypoint-base.sh
#/docker-entrypoint-base.sh

echo $USE_DISPLAY
export WEBPORT=590${USE_DISPLAY}
export DISPLAY=:${USE_DISPLAY}

echo $WEBPORT
echo $DISPLAY

# Disable screensaver
#xset s off -dpms

mkdir $S_USER_HOME/.vnc
echo $MYVNCPASSWORD
echo $MYVNCPASSWORD | vncpasswd -f > $S_USER_HOME/.vnc/passwd
chmod 0600 $S_USER_HOME/.vnc/passwd
/opt/websockify/run ${WEBPORT} --web=/opt/noVNC --wrap-mode=ignore -- vncserver ${DISPLAY} -listen TCP -xstartup /tmp/xsession
#/opt/websockify/run ${WEBPORT} --cert=/self.pem --ssl-only --web=/opt/noVNC --wrap-mode=ignore -- vncserver ${DISPLAY} -xstartup /tmp/xsession

