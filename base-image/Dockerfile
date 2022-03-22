# noVNC + TurboVNC + VirtualGL
# http://novnc.com
# https://turbovnc.org
# https://virtualgl.org

#FROM nvidia/cudagl:10.1-runtime-ubuntu18.04

# cannot compile xmipp using "runtime" image
FROM nvidia/cudagl:10.2-devel-ubuntu18.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

RUN apt update && apt upgrade -y

RUN apt update && DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends \
        apt-utils \
	tzdata

# Install necessary packages
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
	bash \
	make \
	curl \
	wget \
	openssh-client \
	ca-certificates \
	python3 \
	bison \
	flex \
	git \
        gettext \
        cuda-samples-10-2 \
        strace \
        nmap
# gettext - envsubst
# cuda-samples, strace, nmap - for testing and debuging purpose

RUN cd /usr/local/cuda/samples/0_Simple/vectorAdd && make

# Required by Scipion
RUN apt update && apt install -y --no-install-recommends \
	libxv1 \
	openjdk-8-jdk \
	libfftw3-dev \
	libtiff-dev

# Install kubectl
RUN apt update && apt install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt update && apt install -y --no-install-recommends \
        kubectl

# Required by Scipion for conda installation
RUN apt install -y --no-install-recommends sudo wget gcc g++ libopenmpi-dev mesa-utils openssh-client cmake libnss3 libfontconfig1 libxrender1 libxtst6 xterm libasound2 libglu1 libxcursor1 libdbus-1-3 libxkbcommon-x11-0 libhdf5-dev
# Another MPI requirements
RUN apt install -y --no-install-recommends libopenmpi-dev libopenmpi2 openmpi-bin openmpi-common

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER} && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

ENV CUDA_HOME "/usr/local/cuda"
#ENV PATH "${CUDA_HOME}/bin:$PATH"
ENV CUDA_BIN "/usr/local/cuda/bin"

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

# prepare working directory
RUN ln -s /mnt/onedata ${S_USER_HOME}/ScipionUserData && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/ScipionUserData

COPY docker-entrypoint-base.sh /
RUN chmod +x /docker-entrypoint-base.sh

USER ${S_USER}
#######################

RUN ["/bin/bash", "-c", "echo $CUDA_HOME"]
RUN ["/bin/bash", "-c", "echo $PATH"]

# Install Scipion
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ${S_USER_HOME}/miniconda.sh
RUN bash ${S_USER_HOME}/miniconda.sh -b
RUN ${S_USER_HOME}/miniconda3/bin/conda init
RUN ["/bin/bash", "-ci" , "python3 -m pip install scipion-installer"]
RUN ["/bin/bash", "-ci" , "cd ${S_USER_HOME} && python3 -m scipioninstaller ${S_USER_HOME}/scipion3 -noAsk -noXmipp -j $(nproc)"]

USER root
#######################

COPY res/scipion.conf ${S_USER_HOME}/scipion3/config/scipion.conf
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/scipion3/config/scipion.conf

USER ${S_USER}
#######################

RUN /home/scipionuser/scipion3/scipion3 installp -p scipion-em-xmipp -j $(nproc)

ENV PATH "${PATH}:/home/scipionuser/scipion3"

# Disable conda auto activation
RUN ${S_USER_HOME}/miniconda3/bin/conda config --set auto_activate_base false

USER ${S_USER}
#######################

ENTRYPOINT ["bash"]

