
#FROM registry.gitlab.ics.muni.cz:443/eosc-synergy/scipion-docker/base-image:dev
#FROM ldelcano/scipion-base:slurm
#FROM jhandl/scipion-base:v4
FROM jhandl/scipion-base:tool

ARG TURBOVNC_VERSION=3.0
ARG VIRTUALGL_VERSION=3.0
ARG LIBJPEG_VERSION=2.1.2
ARG WEBSOCKIFY_VERSION=0.10.0
ARG NOVNC_VERSION=1.3.0

ARG SLURM_VERSION=20.02.6

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
	thunar-archive-plugin \
	xdotool \
	rsync
# xdotool - window manipulation
# rsync is required only by cloner

# libjpeg-turbo requirements
RUN apt update && apt install -y --no-install-recommends \
	cmake \
	gcc

# websockify requirements
RUN apt update && apt install -y --no-install-recommends \
	python3-numpy

# virtualgl requirements
RUN apt update && apt install -y --no-install-recommends \
        libxtst6:i386 \
        libxv1:i386 \
        libglu1-mesa:i386 \
        libegl1-mesa:i386 \
        libegl1-mesa

# Install useful packages
RUN apt update && apt install -y --no-install-recommends \
	git \
	vim \
	sudo \
	mesa-utils \
	htop

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

# Install TurboVNC, VirtualGL, noVNC
RUN cd /tmp && \
    curl -fsSL -O https://deac-fra.dl.sourceforge.net/project/turbovnc/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/libjpeg-turbo/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    dpkg -i *.deb && \
    rm -f /tmp/*.deb && \
    sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver

ENV PATH ${PATH}:/opt/VirtualGL/bin:/opt/TurboVNC/bin

RUN curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    curl -fsSL https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    mv /opt/websockify-${WEBSOCKIFY_VERSION} /opt/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    cd /opt/websockify && make

# Create Scipion icon
RUN mkdir ${S_USER_HOME}/Desktop || true
ADD res/scipion_logo.png ${S_USER_HOME}/scipion3/
ADD res/Scipion.desktop ${S_USER_HOME}/Desktop/
RUN chmod +x ${S_USER_HOME}/Desktop/Scipion.desktop

RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/Desktop

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,display


USER ${S_USER}
#######################

# Install plugins for Scipion
COPY plugin-list.txt ${S_USER_HOME}/
RUN for pl in $(cat ${S_USER_HOME}/plugin-list.txt); do ${S_USER_HOME}/scipion3/scipion3 installp -p $pl -j $(nproc) --noBin; done

# This is needed since we do not have binaries installed in master docker
RUN mkdir ${S_USER_HOME}/scipion3/software/em/gctf-1.18
RUN mkdir ${S_USER_HOME}/scipion3/software/em/motioncor2-1.4.0

USER root
#######################

# Create TurboVNC config
ADD res/turbovncserver.conf /etc/turbovncserver.conf
ADD res/turbovncserver-security.conf /etc/turbovncserver-security.conf

# Prepare environment
# Create X11 dir
RUN mkdir /tmp/.X11-unix || true
RUN chmod -R ugo+rwx /tmp/.X11-unix

# Copy basic xfce4 configuration
COPY xfce4 ${S_USER_HOME}/.config/xfce4/
RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/.config/xfce4

# Disable logout from xfce4
#RUN sed -ie 's/^Exec=.*/Exec=notify-send "Logout is disabled"/' /usr/share/applications/xfce4-session-logout.desktop

# Set screensaver to blank
COPY res/.xscreensaver ${S_USER_HOME}/
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/.xscreensaver

# Copy xsession file
COPY res/xsession /tmp/
RUN chmod +x /tmp/xsession

ENV MYVNCPASSWORD abc
ENV EDITOR=/usr/bin/pluma

COPY plugin-list.txt ${S_USER_HOME}/

# run docker-entrypoint.sh
COPY docker-entrypoint-root.sh /
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint-root.sh && \
    chmod +x /docker-entrypoint.sh

# Install minimal prerequisites (Ubuntu 18.04 as reference)
#RUN apt update && apt install -y --no-install-recommends cmake g++ wget unzip python-numpy
# Download and unpack sources
#RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/4.x.zip && \
#    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.x.zip && \
#    unzip opencv.zip && \
#    unzip opencv_contrib.zip
# Create build directory and switch into it
#RUN mkdir -p build && cd build
# Configure
#RUN cmake -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib-4.x/modules ../opencv-4.x
# Build
#RUN cmake --build .

COPY res/hosts.conf ${S_USER_HOME}/scipion3/config/hosts.conf
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/scipion3/config/hosts.conf

RUN mkdir /opt/k8s
COPY res/depl-tool.yaml /opt/k8s/
COPY res/job-watchdog.sh /opt/k8s/
RUN chmod +x /opt/k8s/job-watchdog.sh
RUN chown -R ${S_USER}:${S_USER} /opt

COPY scipion-test-list.txt ${S_USER_HOME}/Desktop/
COPY scipion-test.sh ${S_USER_HOME}/Desktop/

RUN chmod +x ${S_USER_HOME}/Desktop/scipion-test.sh
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/Desktop/scipion-test-list.txt
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/Desktop/scipion-test.sh

USER ${S_USER}
#######################

RUN export string="\ \ \ \ \ \ \ \ submitDict['JOB_TOOL'] = protocol.getClassPlugin().getName()" && sed -i "132 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/pyworkflow/protocol/launch.py
RUN export string="\ \ \ \ \ \ \ \ submitDict['REQUIRES_GPU'] = protocol.requiresGpu()" && sed -i "133 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/pyworkflow/protocol/launch.py

ENTRYPOINT ["/docker-entrypoint.sh"]

