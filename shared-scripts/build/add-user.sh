#!/bin/bash

set -e

groupadd --gid 1000 ${S_USER}
useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER}
usermod -aG sudo ${S_USER}
chown -R ${S_USER}:${S_USER} ${S_USER_HOME}
