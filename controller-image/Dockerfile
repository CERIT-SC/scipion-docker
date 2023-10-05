FROM ubuntu:22.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

ENV DEBIAN_FRONTEND noninteractive

# Install required basics
RUN apt update && apt install -y --no-install-recommends \
        bash \
        rsync \
        python3 \
        python3-pip \
        expect-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN apt update && apt install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl && \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt update && apt install -y \
        kubectl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER} && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

COPY controller /opt/controller
RUN chown -R ${S_USER}:${S_USER} /opt/controller

WORKDIR /opt/controller

RUN pip3 install -r requirements.txt

USER ${S_USER}

#ENTRYPOINT ["sleep", "infinity"]
ENTRYPOINT ["/docker-entrypoint.sh"]
