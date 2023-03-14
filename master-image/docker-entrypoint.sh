#!/bin/bash

set -x

echo "docker-entrypoint.sh"

S_USER=scipionuser
S_USER_HOME=/home/${S_USER}
CERT_PATH="/mnt/cert-loadbalancer-vncclient"

_trap () {
	notify-send --urgency=critical "This instance will be destroyed within 30 seconds. Scipion projects will be saved in Onedata."

	sleep 30

	kill -s SIGTERM $(pgrep -f "sleep infinity")
	kill -s SIGTERM $(pgrep -f "/bin/sh /tmp/xsession")
}

# run base-image's docker-entrypoint-base.sh
/docker-entrypoint-base.sh

/tmp/xsession

trap "_trap" SIGINT SIGTERM

sleep infinity &

wait
