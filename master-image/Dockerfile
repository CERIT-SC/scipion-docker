
#FROM registry.gitlab.ics.muni.cz:443/eosc-synergy/scipion-docker/base-image:dev
FROM ldelcano/scipion-worker

ARG TURBOVNC_VERSION=2.2.4
ARG LIBJPEG_VERSION=1.5.2
ARG WEBSOCKIFY_VERSION=0.8.0
ARG NOVNC_VERSION=1.1.0

ARG SLURM_VERSION=20.02.7
ARG CRYOSPARC_VERSION=3.1.0

ARG S_USER=scipionuser
ARG S_USER_HOME=/home/${S_USER}
ARG CRYOSPARC_LICENSE=a0e74f16-3181-11ea-84b9-d7e876129116

USER root
#######################

# Install necessary packages - xfce4, term, editor
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
	dbus-x11 \
	xfce4 \
	xauth \
	xterm \
	konsole \
	pluma \
	firefox

# libjpeg-turbo requirements
RUN apt update && apt install -y --no-install-recommends \
	cmake \
	gcc

# websockify requirements
RUN apt update && apt install -y --no-install-recommends \
	python-numpy

# Install useful packages
RUN apt update && apt install -y --no-install-recommends \
	git \
	vim \
	sudo \
	mesa-utils \
	htop \
	iputils-ping

# Slurm requirements
RUN apt update && apt install -y --no-install-recommends \
        libmunge2 \
        libpq5 \
        munge \
        libmunge-dev \
        gcc \
        make \
        bzip2

RUN useradd --uid 1052 -M slurm

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

# Install TurboVNC, VirtualGL, noVNC
RUN cd /tmp && \
    curl -fsSL -O https://deac-fra.dl.sourceforge.net/project/turbovnc/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/libjpeg-turbo/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb && \
    dpkg -i *.deb && \
    rm -f /tmp/*.deb && \
    sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver

ENV PATH ${PATH}:/opt/TurboVNC/bin

RUN curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    curl -fsSL https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    mv /opt/websockify-${WEBSOCKIFY_VERSION} /opt/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    cd /opt/websockify && make

# Install Slurm client
RUN cd /tmp && \
    curl -fsSL -o slurm.tar.bz2 http://ftpgrycap.i3m.upv.es/src/slurm-${SLURM_VERSION}.tar.bz2 && \
    tar -xjf slurm.tar.bz2 && \
    cd slurm-${SLURM_VERSION} && \
    ./configure && \
    make && \
    make install

# Create Scipion icon
RUN mkdir ${S_USER_HOME}/Desktop || true
ADD res/scipion_logo.png ${S_USER_HOME}/scipion3/
ADD res/Scipion.desktop ${S_USER_HOME}/Desktop/
RUN chmod +x ${S_USER_HOME}/scipion3/scipion_logo.png && \
    chmod +x ${S_USER_HOME}/Desktop/Scipion.desktop

RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/Desktop

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,display


USER ${S_USER}
#######################

COPY hosts.conf ${S_USER_HOME}/scipion3/config/

# Install cryosparc
USER ${S_USER}
RUN mkdir ${S_USER_HOME}/cryosparc3
RUN curl -L https://get.cryosparc.com/download/master-latest/$CRYOSPARC_LICENSE -o ${S_USER_HOME}/cryosparc3/cryosparc_master.tar.gz
RUN curl -L https://get.cryosparc.com/download/worker-latest/$CRYOSPARC_LICENSE -o ${S_USER_HOME}/cryosparc3/cryosparc_worker.tar.gz
RUN tar -xf ${S_USER_HOME}/cryosparc3/cryosparc_master.tar.gz -C ${S_USER_HOME}/cryosparc3
RUN tar -xf ${S_USER_HOME}/cryosparc3/cryosparc_worker.tar.gz -C ${S_USER_HOME}/cryosparc3
RUN rm ${S_USER_HOME}/cryosparc3/cryosparc_*.tar.gz
COPY install_cryosparc_master.sh ${S_USER_HOME}/
USER root
RUN chown ${S_USER}.${S_USER} ${S_USER_HOME}/install_cryosparc_master.sh
RUN chmod +x ${S_USER_HOME}/install_cryosparc_master.sh
USER ${S_USER}
RUN cd ${S_USER_HOME} && ${S_USER_HOME}/install_cryosparc_master.sh

USER root
#######################

# Create TurboVNC config
RUN echo 'no-remote-connections\n\
no-httpd\n\
no-x11-tcp-connections\n\
no-pam-sessions\n\
permitted-security-types = TLSVnc, TLSOtp, TLSPlain, TLSNone, X509Vnc, X509Otp, X509Plain, X509None, VNC, OTP, UnixLogin, Plain\
' > /etc/turbovncserver-security.conf

ADD res/turbovncserver.conf /etc/turbovncserver.conf

# Prepare environment
RUN mkdir /tmp/.X11-unix || true
RUN chmod -R ugo+rwx /tmp/.X11-unix

COPY xfce4 ${S_USER_HOME}/.config/xfce4/
RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/.config/xfce4

RUN echo '#!/bin/sh\n\
xfce4-session \
' >/tmp/xsession; chmod +x /tmp/xsession

ENV MYVNCPASSWORD Scipion4U
ENV EDITOR=/usr/bin/pluma

COPY self.pem /

# run docker-entrypoint.sh
COPY docker-entrypoint-root.sh /
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint-root.sh && \
    chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint-root.sh"]

