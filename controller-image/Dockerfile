FROM ubuntu:22.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

RUN apt update && apt install -y --no-install-recommends \
	bash \
	rsync

# Install kubectl
RUN apt update && apt install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt update && apt install -y \
        kubectl

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

COPY res/deploy_cloner.yaml /opt/

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER} && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

RUN mkdir -p /opt/cloner && \
    chown ${S_USER}:${S_USER} /opt/cloner

COPY docker-entrypoint.sh /
COPY cloner.sh /
RUN chmod +x /docker-entrypoint.sh
RUN chmod +x /cloner.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
