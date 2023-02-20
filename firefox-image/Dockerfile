FROM ubuntu:20.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

RUN apt update && apt upgrade -y

RUN apt update && DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends \
        apt-utils \
        tzdata

RUN apt update && apt install -y --no-install-recommends \
        firefox

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER} && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

# prepare working directory
RUN mkdir ${S_USER_HOME}/ScipionUserData && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/ScipionUserData && \
    chown -R ${S_USER}:${S_USER} /mnt

#COPY ../base-image/docker-entrypoint-base.sh /
#RUN chmod +x /docker-entrypoint-base.sh

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

USER ${S_USER}
######################

RUN mkdir ${S_USER_HOME}/scipion3
RUN ln -s ${S_USER_HOME}/ScipionUserData/projects ${S_USER_HOME}/scipion3/data

ENTRYPOINT ["/docker-entrypoint.sh"]
