FROM ubuntu:22.04

RUN apt update && apt install -y --no-install-recommends \
        bash \
        gettext-base

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

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
