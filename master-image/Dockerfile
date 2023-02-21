ARG RELEASE_CHANNEL

FROM hub.cerit.io/scipion/scipion-base:${RELEASE_CHANNEL}

ARG RELEASE_CHANNEL
ENV RELEASE_CHANNEL=${RELEASE_CHANNEL}

ARG TURBOVNC_VERSION=3.0
ARG VIRTUALGL_VERSION=3.0
ARG LIBJPEG_VERSION=2.1.2
ARG WEBSOCKIFY_VERSION=0.10.0
ARG NOVNC_VERSION=1.3.0

USER root
###############

# Install necessary packages
#============================

# xfce4, term, editor
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
        dbus-x11 \
        xfce4 \
        xauth \
        xterm \
        konsole \
        pluma \
        thunar-archive-plugin \
        xdotool
# xdotool - window manipulation

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
        htop \
        iperf \
        screen
# TODO iperf, screen - debuging

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

# Install kubectl
RUN apt update && apt install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl && \
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list&& \
    apt update && apt install -y --no-install-recommends \
        kubectl

# Install Helm
RUN apt install -y --no-install-recommends \
        apt-transport-https && \
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt update && apt install -y --no-install-recommends \
        helm

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

# Install TurboVNC, VirtualGL, noVNC
#====================================

# TurboVNC + VirtualGl
RUN cd /tmp && \
    curl -fsSL -O https://deac-fra.dl.sourceforge.net/project/turbovnc/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/libjpeg-turbo/${LIBJPEG_VERSION}/libjpeg-turbo-official_${LIBJPEG_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
        -O https://deac-fra.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb && \
    dpkg -i *.deb && \
    rm -f /tmp/*.deb && \
    sed -i 's/$host:/unix:/g' /opt/TurboVNC/bin/vncserver

ENV PATH ${PATH}:/opt/VirtualGL/bin:/opt/TurboVNC/bin

# noVNC
RUN curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    curl -fsSL https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    mv /opt/websockify-${WEBSOCKIFY_VERSION} /opt/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    cd /opt/websockify && make

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,display

###############
USER ${S_USER}
###############

# Scipion plugins
#=================

# Install plugins
COPY plugin-list.txt ${S_USER_HOME}/
RUN for pl in $(cat ${S_USER_HOME}/plugin-list.txt); do ${S_USER_HOME}/scipion3/scipion3 installp -p $pl -j $(nproc) --noBin; done

# This is needed since we do not have binaries installed in master docker
RUN mkdir ${S_USER_HOME}/scipion3/software/em/gctf-1.18
RUN mkdir ${S_USER_HOME}/scipion3/software/em/gautomatch-0.56
RUN mkdir ${S_USER_HOME}/scipion3/software/em/motioncor2-1.4.0
RUN mkdir ${S_USER_HOME}/scipion3/software/em/eman-2.99
RUN mkdir ${S_USER_HOME}/scipion3/software/em/relion-4.0
RUN mkdir ${S_USER_HOME}/scipion3/software/em/cistem-1.0.0-beta

###############
USER root
###############

# Scipion hosts.conf
#====================
COPY scipion/hosts.conf ${S_USER_HOME}/scipion3/config/hosts.conf
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/scipion3/config/hosts.conf

# Create TurboVNC config
#========================
COPY res/turbovncserver.conf /etc/turbovncserver.conf
COPY res/turbovncserver-security.conf /etc/turbovncserver-security.conf
RUN chmod go-rw /etc/turbovncserver.conf /etc/turbovncserver-security.conf

# Prepare the desktop environment
#=================================

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

COPY plugin-list.txt ${S_USER_HOME}/

# Prepare wrappers and other useful files
#=========================================

# Copy the auxiliary files
COPY wrappers/controller /opt/controller
COPY wrappers/firefox /opt/firefox
COPY kubernetes /opt/kubernetes
COPY scipion /opt/scipion

# Set the wrappers as executable
RUN chmod +x /opt/controller/controller-clone
RUN chmod +x /opt/firefox/firefox
RUN chmod +x /opt/scipion/job-watchdog.sh

# Add the wrappers to the PATH
ENV PATH "${PATH}:/opt/firefox:/opt/controller"

# Set the firefox wrapper as a default browser (and pluma)
ENV BROWSER=/opt/firefox/firefox
ENV EDITOR=/usr/bin/pluma

RUN chown -R ${S_USER}:${S_USER} /opt

# Prepare desktop icons
#=======================

RUN mkdir ${S_USER_HOME}/Desktop || true

# Create Scipion icon
ADD scipion/scipion_logo.png ${S_USER_HOME}/scipion3/
COPY desktop/scipion.desktop ${S_USER_HOME}/Desktop/scipion.desktop
RUN chmod +x ${S_USER_HOME}/Desktop/scipion.desktop

# Create Controller clone icon
COPY desktop/controller-clone.desktop ${S_USER_HOME}/Desktop/controller-clone.desktop
RUN chmod +x ${S_USER_HOME}/Desktop/controller-clone.desktop

RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/Desktop


#COPY scipion-test-list.txt ${S_USER_HOME}/Desktop/
#COPY scipion-test.sh ${S_USER_HOME}/Desktop/
#RUN chmod +x ${S_USER_HOME}/Desktop/scipion-test.sh
#RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/Desktop/scipion-test-list.txt
#RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/Desktop/scipion-test.sh

COPY res/rsync-benchmark /opt/rsync-benchmark
RUN chown -R ${S_USER}:${S_USER} /opt/rsync-benchmark
RUN chmod +x /opt/rsync-benchmark/*.sh

# docker-entrypoint.sh
#======================
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

USER ${S_USER}
###############

RUN export string="\ \ \ \ \ \ \ \ submitDict['JOB_TOOL'] = protocol.getClassPlugin().getName()" && sed -i "160 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/pyworkflow/protocol/launch.py
RUN export string="\ \ \ \ \ \ \ \ submitDict['JOB_REQUIRES_GPU'] = protocol.requiresGpu()" && sed -i "161 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/pyworkflow/protocol/launch.py

#ENTRYPOINT ["sleep", "infinity"]
ENTRYPOINT ["/docker-entrypoint.sh"]

