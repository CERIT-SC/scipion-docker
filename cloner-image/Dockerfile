#FROM alpine:3.15
FROM ubuntu:22.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

#RUN apk add --no-cache rsync
RUN apt update && apt install -y --no-install-recommends \
    rsync

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER} && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

RUN mkdir -p /opt/cloner/tmp && \
    chown ${S_USER}:${S_USER} /opt/cloner/tmp

COPY docker-entrypoint.sh /
COPY cloner.sh /opt/cloner/
RUN chmod +x /docker-entrypoint.sh && \
    chmod +x /opt/cloner/cloner.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
