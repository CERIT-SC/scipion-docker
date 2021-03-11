# noVNC + TurboVNC + VirtualGL
# http://novnc.com
# https://turbovnc.org
# https://virtualgl.org

#FROM nvidia/cudagl:10.1-runtime-ubuntu18.04

# cannot compile xmipp using "runtime" image
FROM nvidia/cudagl:10.2-devel-ubuntu18.04

ARG S_USER=scipionuser
ARG S_USER_HOME=/home/${S_USER}

RUN apt update && apt upgrade -y

RUN apt update && DEBIAN_FRONTEND="noninteractive" apt install -y \
	tzdata

# Install necessary packages
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
	bash \
	make \
	curl \
	wget \
	openssh-client \
	ca-certificates \
	python3 \
	bison \
	flex \
	git
# bison, flex, ca-certificates, git ??

# Required by Scipion
RUN apt update && apt install -y \
	libxv1 \
	openjdk-8-jdk \
	libfftw3-dev \
	libtiff-dev

# Required by Scipion for conda installation
RUN apt-get -y install sudo wget gcc g++ libopenmpi-dev mesa-utils openssh-client cmake libnss3 libfontconfig1 libxrender1 libxtst6 xterm libasound2 libglu1 libxcursor1 libdbus-1-3 libxkbcommon-x11-0 libhdf5-dev

# Install oneclient (OneData client)
RUN curl -sS  http://get.onedata.org/oneclient.sh | bash

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

# Create scipionuser
RUN groupadd --gid 1042 ${S_USER} && \
    useradd --uid 1042 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER}

RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

ENV CUDA_HOME "/usr/local/cuda"
#ENV PATH "${CUDA_HOME}/bin:$PATH"
ENV CUDA_BIN "/usr/local/cuda/bin"

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

# data directory for mount NFS using docker volume
RUN mkdir /mnt/onedata && \
    chown -R ${S_USER}:${S_USER} /mnt/onedata
RUN ln -s /mnt/onedata/scipion-docker-test ${S_USER_HOME}/ScipionUserData && \
    chown -R ${S_USER}:${S_USER} ${S_USER_HOME}/ScipionUserData

# mount OneData
#ENV ONEDATA_TOKEN MDAyMWxvY2F00aW9uIG9uZXpvbmUub25lZGF00YS5vcmcKMDA2YmlkZW500aWZpZXIgMi9ubWQvdXNyLTI4YWRmMmViZDY2NTczMDhkMTI4NTJjZWMwYzFmMDkwY2g2NTczL2FjdC9mYzRiYWYwODQzZjUxMWEzMjQ2YTU4YWFhNzU1NGM3YmNoZWFjZAowMDE4Y2lkIHNlcnZpY2UgPSBvcHctKgowMDJmc2lnbmF00dXJlILwbQY74hrfqu4DajWjNpXN8sV7fHz01ebs8OhO00HrLd01Cg
#RUN modprobe fuse
#RUN oneclient -H muni.onezone.onedata.org -t ${ONEDATA_TOKEN} /mnt/onedata

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

# Install xmipp without native compilation flags
RUN ["/bin/bash", "-c" , "${S_USER_HOME}/scipion3/scipion3 installp -p scipion-em-xmipp -j $(nproc) --noBin"]
RUN mkdir ${S_USER_HOME}/scipion3/software/em
RUN wget http://scipion.cnb.csic.es/downloads/scipion/software/em/xmippSrc-v3.20.07.tgz -O ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07.tgz
RUN tar xfz ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07.tgz -C ${S_USER_HOME}/scipion3/software/em/
RUN ["/bin/bash", "-c" , "cd ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07 && ${S_USER_HOME}/scipion3/scipion3 run ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp noAsk config"]
RUN sed -i 's/-mtune=native -march=native //g' ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp.conf
RUN sed -i 's/CUDA=True/CUDA=False/g' ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp.conf
RUN ["/bin/bash", "-c" , "cd ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07 && ${S_USER_HOME}/scipion3/scipion3 run ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp compile"]
RUN mkdir ${S_USER_HOME}/scipion3/software/lib
RUN ["/bin/bash", "-c" , "cd ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07 && ${S_USER_HOME}/scipion3/scipion3 run ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp install"]
RUN ln -s ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/build ${S_USER_HOME}/scipion3/software/em/xmipp

# Disable conda auto activation
RUN ${S_USER_HOME}/miniconda3/bin/conda config --set auto_activate_base false

USER ${S_USER}
#######################

ENTRYPOINT ["bash"]

