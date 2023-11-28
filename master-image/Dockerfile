ARG RELEASE_CHANNEL

FROM hub.cerit.io/scipion/scipion-base:${RELEASE_CHANNEL}

ARG RELEASE_CHANNEL
ENV RELEASE_CHANNEL=${RELEASE_CHANNEL}

USER root
###############

# Install necessary packages
#============================

# xfce4, term, editor
RUN apt update && apt install -y \
        dbus-x11 \
        xfce4 \
        xauth \
        xterm \
        konsole \
        pluma \
        thunar-archive-plugin \
        xdotool && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# xdotool - window manipulation

# Install useful packages
RUN apt update && apt install -y --no-install-recommends \
        git \
        vim \
        sudo \
        mesa-utils \
        htop \
        iperf \
        screen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
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
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt update && apt install -y --no-install-recommends \
        kubectl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Helm
RUN apt update && apt install -y --no-install-recommends \
        apt-transport-https && \
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt update && apt install -y --no-install-recommends \
        helm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility,display

# TODO required by xmipp from scipion v3.3.0 (skip from v3.0.12). Maybe this should be in the base-image because of the tools.
RUN apt update && apt install -y --no-install-recommends \
        nvidia-utils-545
RUN apt update && apt install -y --no-install-recommends \
        cuda-nvcc-11-4 \
        libcufft-dev-11-4 \
        nvidia-cuda-toolkit \
        rsync

###############
USER ${S_USER}
###############

# Scipion plugins
#=================

# Install plugins
COPY plugin-list.txt ${S_USER_HOME}/
RUN for pl in $(cat ${S_USER_HOME}/plugin-list.txt); do ${S_USER_HOME}/scipion3/scipion3 installp -p $pl -j $(nproc) --noBin; done

RUN ${S_USER_HOME}/scipion3/scipion3 installp -p scipion-em-xmipp -j $(nproc)

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

# Add hosts.conf
COPY scipion/hosts.conf ${S_USER_HOME}/scipion3/config/hosts.conf
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/scipion3/config/hosts.conf

# Prepare the desktop environment
#=================================

# Copy basic xfce4 configuration
COPY xfce4 ${S_USER_HOME}/.config/xfce4/
RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/.config/xfce4

# Disable logout from xfce4
#RUN sed -ie 's/^Exec=.*/Exec=notify-send "Logout is disabled"/' /usr/share/applications/xfce4-session-logout.desktop

# Set screensaver to blank screen
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
COPY scipion /opt/scipion

# Add kubernetes helm charts for spawning tools, firefox...
RUN git clone https://github.com/CERIT-SC/scipion-helm-charts /tmp/helm-charts \
        && cp -r /tmp/helm-charts/scipion-docker-master-image/v2.0/ /opt/kubernetes/ \
        && rm -rf /tmp/helm-charts/

# Add dictionary of a binaries of the installed tools to find the right tool name
COPY tool-dictionary.csv /opt/scipion/tool-dictionary.csv

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

# docker-entrypoint.sh
#======================
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

USER ${S_USER}
###############

# TODO tmp workarounds
#RUN export string="\ \ \ \ \ \ \ \ submitDict['JOB_TOOL'] = protocol.getClassPlugin().getName()" && sed -i "164 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/pyworkflow/protocol/launch.py
#RUN export string="\ \ \ \ \ \ \ \ submitDict['JOB_REQUIRES_GPU'] = protocol.requiresGpu()" && sed -i "165 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/pyworkflow/protocol/launch.py

#ENTRYPOINT ["sleep", "infinity"]
ENTRYPOINT ["/docker-entrypoint.sh"]
