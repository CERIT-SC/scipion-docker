#!/bin/bash

set -xe

echo "docker-entrypoint.sh"

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}
CERT_PATH="/mnt/cert-loadbalancer-vncclient"

# run base-image's docker-entrypoint-base.sh
/docker-entrypoint-base.sh

echo $USE_DISPLAY
export WEBPORT=590${USE_DISPLAY}
export DISPLAY=:${USE_DISPLAY}

echo $WEBPORT
echo $DISPLAY

# Disable screensaver
#xset s off -dpms

mkdir $S_USER_HOME/.vnc
echo $VNC_PASS
echo $VNC_PASS | vncpasswd -f > $S_USER_HOME/.vnc/passwd
chmod 0600 $S_USER_HOME/.vnc/passwd

if [ "$USE_VNCCLIENT" == "true" ]; then
	vncserver ${DISPLAY} -x509cert "${CERT_PATH}/tls.crt" -x509key "${CERT_PATH}/tls.key" -listen TCP -xstartup /tmp/xsession
	sleep infinity
else
	/opt/websockify/run ${WEBPORT} --verbose --web=/opt/noVNC --wrap-mode=ignore -- vncserver ${DISPLAY} -listen TCP -xstartup /tmp/xsession
fi

#/opt/websockify/run ${WEBPORT} --cert=/self.pem --ssl-only --web=/opt/noVNC --wrap-mode=ignore -- vncserver ${DISPLAY} -xstartup /tmp/xsession

