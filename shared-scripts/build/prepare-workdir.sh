#!/bin/bash

set -e

# prepare working directory for Scipion
mkdir ${S_USER_HOME}/ScipionUserData
chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/ScipionUserData
chown -R ${S_USER}:${S_USER} /mnt
