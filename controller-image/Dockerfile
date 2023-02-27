
FROM ubuntu:22.04 as rsync-builder

RUN apt update && apt install -y --no-install-recommends \
        gcc \
        g++ \
        gawk \
        autoconf \
        automake \
        python3 \
        python3-pip \
        python3-cmarkgfm \
        xxhash \
        zstd \
        lz4 \
        acl \
        libacl1-dev \
        attr \
        libattr1-dev \
        libxxhash-dev \
        libzstd-dev \
        liblz4-dev \
        libssl-dev \
        wget \
        curl \
        unzip \
        make

RUN cd tmp && \
    python3 -mpip install --user commonmark && \
    wget https://github.com/WayneD/rsync/archive/refs/tags/v3.2.7.zip && \
    unzip v3.2.7.zip && \
    cd rsync-3.2.7 && \
    ./md2man --test rsync-ssl.1.md && \
    ./configure && \
    make && \
    make install

RUN ls -la /tmp/rsync-*

FROM ubuntu:22.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

RUN apt update && apt install -y --no-install-recommends \
        bash \
        python3 \
        python3-pip \
        expect-dev

# Install kubectl
#RUN apt update && apt install -y --no-install-recommends \
#        apt-transport-https \
#        ca-certificates \
#        curl
#RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
#RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
#RUN apt update && apt install -y \
#        kubectl

COPY --from=rsync-builder /tmp/rsync-*/rsync /bin/


# Clean apt
RUN rm -rf /var/lib/apt/lists/*

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
