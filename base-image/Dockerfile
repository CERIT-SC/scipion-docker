#FROM nvidia/cudagl:10.1-runtime-ubuntu18.04

# cannot compile xmipp using "runtime" image
FROM nvidia/cudagl:10.2-devel-ubuntu18.04
#FROM nvidia/cudagl:11.4.2-devel-ubuntu18.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

ENV DEBIAN_FRONTEND noninteractive

# temporary workaround
# https://developer.download.nvidia.com/compute/cuda/repos/
RUN apt-key del 7fa2af80
RUN rm /etc/apt/sources.list.d/cuda.list || true
RUN rm /etc/apt/sources.list.d/nvidia-ml.list || true

# Install necessary packages
RUN apt update && apt install -y --no-install-recommends \
        apt-utils \
        tzdata \
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
        strace \
        iputils-ping \
        nmap && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# gettext - envsubst
# cuda-samples, strace, nmap - for testing and debuging purpose

# temporary workaround
# https://developer.download.nvidia.com/compute/cuda/repos/
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt update && apt install -y --no-install-recommends \
        cuda-samples-10-2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm /usr/local/cuda && \
    ln -s /usr/local/cuda-10.2 /usr/local/cuda && \
    cd /usr/local/cuda/samples/0_Simple/vectorAdd && \
    make

# Required by Scipion
RUN apt update && apt install -y --no-install-recommends \
        libxv1 \
        openjdk-8-jdk \
        libfftw3-dev \
        libtiff-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Required by Scipion for conda installation
RUN apt update && apt install -y --no-install-recommends \
        sudo \
        wget \
        gcc \
        g++ \
        libopenmpi-dev \
        mesa-utils \
        openssh-client \
        cmake \
        libnss3 \
        libfontconfig1 \
        libxrender1 \
        libxtst6 \
        xterm \
        libasound2 \
        libglu1 \
        libxcursor1 \
        libdbus-1-3 \
        libxkbcommon-x11-0 \
        libhdf5-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Another MPI requirements
RUN apt update && apt install -y --no-install-recommends \
        libopenmpi-dev \
        libopenmpi2 \
        openmpi-bin \
        openmpi-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER} && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

ENV CUDA_HOME "/usr/local/cuda"
#ENV PATH "${CUDA_HOME}/bin:$PATH"
ENV CUDA_BIN "/usr/local/cuda/bin"

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_VISIBLE_DEVICES=0
ENV CUDA_VISIBLE_DEVICES=0

# prepare working directory
RUN mkdir ${S_USER_HOME}/ScipionUserData && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/ScipionUserData && \
    chown -R ${S_USER}:${S_USER} /mnt

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

RUN ln -s ${S_USER_HOME}/ScipionUserData/projects ${S_USER_HOME}/scipion3/data
#RUN /home/scipionuser/scipion3/scipion3 installp -p scipion-em-xmipp -j $(nproc)

ENV PATH "${PATH}:/home/scipionuser/scipion3"

# Disable conda auto activation
RUN ${S_USER_HOME}/miniconda3/bin/conda config --set auto_activate_base false

USER ${S_USER}
#######################

ENTRYPOINT ["bash"]

