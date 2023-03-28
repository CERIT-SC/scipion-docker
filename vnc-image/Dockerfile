ARG RELEASE_CHANNEL

FROM ubuntu:22.04

ARG RELEASE_CHANNEL
ENV RELEASE_CHANNEL=${RELEASE_CHANNEL}

ARG TURBOVNC_VERSION=3.0.3
ARG VIRTUALGL_VERSION=3.0
ARG LIBJPEG_VERSION=2.1.5
ARG WEBSOCKIFY_VERSION=0.11.0
ARG NOVNC_VERSION=1.4.0

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

ENV DEBIAN_FRONTEND noninteractive

# Install necessary packages
#============================

# Some X11-related basics
RUN apt update && apt install -y --no-install-recommends \
        dbus-x11 \
        xauth \
        xorg \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# xdotool - window manipulation

# Turbovnc requirements
RUN apt update && apt install -y --no-install-recommends \
        libxt6 \
        x11-xkb-utils \
        xkb-data && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# noVNC requirements
RUN apt update && apt install -y --no-install-recommends \
        make \
        libc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# libjpeg-turbo requirements
RUN apt update && apt install -y --no-install-recommends \
        cmake \
        gcc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# websockify requirements
RUN apt update && apt install -y --no-install-recommends \
        python3-numpy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# virtualgl requirements
#RUN dpkg --add-architecture i386
#RUN apt update && apt install -y --no-install-recommends \
#        libxtst6:i386 \
#        libxv1:i386 \
#        libglu1-mesa:i386 \
#        libegl1-mesa:i386 \
#        libegl1-mesa && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/*

# Install useful packages
RUN apt update && apt install -y --no-install-recommends \
        git \
        vim \
        sudo \
        mesa-utils \
        htop \
        iperf \
        screen \
        nmap \
        strace && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# TODO iperf, screen - debuging

# Install TurboVNC, VirtualGL, noVNC
#====================================

# TurboVNC + VirtualGl
RUN cd /tmp && \
    curl -fsSL -O https://deac-fra.dl.sourceforge.net/project/turbovnc/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/libjpeg-turbo/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb && \
#        -O https://deac-fra.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
#        -O https://deac-fra.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    dpkg -i *.deb && \
    rm -f /tmp/*.deb && \
    sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver

# /opt/VirtualGL/bin
ENV PATH ${PATH}:/opt/TurboVNC/bin

# noVNC
RUN curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    curl -fsSL https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    mv /opt/websockify-${WEBSOCKIFY_VERSION} /opt/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    cd /opt/websockify && make

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER} && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

# prepare working directory
RUN chown -R ${S_USER}:${S_USER} /mnt

# Create TurboVNC config
#========================
COPY turbovncserver.conf /etc/turbovncserver.conf
COPY turbovncserver-security.conf /etc/turbovncserver-security.conf
RUN chmod go-rw /etc/turbovncserver.conf /etc/turbovncserver-security.conf

# Prepare the desktop environment
#=================================

# Create X11 dir
RUN mkdir /tmp/.X11-unix || true
RUN chmod -R ugo+rwx /tmp/.X11-unix

# Copy xsession file
COPY xsession /tmp/
RUN chmod +x /tmp/xsession

# docker-entrypoint.sh
#======================
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

USER ${S_USER}
###############

#ENTRYPOINT ["sleep", "infinity"]
ENTRYPOINT ["/docker-entrypoint.sh"]
