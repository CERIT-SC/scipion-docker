FROM hub.cerit.io/josef_handl/scipion-base:dev AS tool-all

USER root
######################

# Required by Relion tool
RUN apt update && apt install -y --no-install-recommends \
    pkg-config \
    libxft-dev \
    libfreetype6-dev

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

RUN mkdir /scipion-tool && \
    chown ${S_USER}:${S_USER} /scipion-tool

USER ${S_USER}
######################

#ARG SD_PLUGIN
#ARG SD_BIN
#ARG SD_DIR

ENV SC_LOC "${S_USER_HOME}/scipion3/scipion3"

RUN ${SC_LOC} installp -p "scipion-em-appion"     -j $(nproc);
RUN ${SC_LOC} installp -p "scipion-em-cistem"     -j $(nproc);
RUN ${SC_LOC} installp -p "scipion-em-eman2"      -j $(nproc);
RUN ${SC_LOC} installp -p "scipion-em-gautomatch" -j $(nproc);
RUN ${SC_LOC} installp -p "scipion-em-motioncorr" -j $(nproc);
RUN ${SC_LOC} installp -p "scipion-em-phenix"     -j $(nproc);
RUN ${SC_LOC} installp -p "scipion-em-spider"     -j $(nproc);

RUN ${SC_LOC} installp -p "scipion-em-gctf"       -j $(nproc);
RUN ${SC_LOC} installb "gctf-1.18" -j $(nproc);
RUN ${SC_LOC} installp -p "scipion-em-relion"     -j $(nproc);
RUN ${SC_LOC} installb "relion-4.0" -j $(nproc);





#RUN if [ ! -z "$SD_PLUGIN" ]; then \
#        if [ -z "$SD_BIN" ]; then \
#            ${S_USER_HOME}/scipion3/scipion3 installp -p "$SD_PLUGIN" -j $(nproc); \
#        else \
#            ${S_USER_HOME}/scipion3/scipion3 installp -p "$SD_PLUGIN" --noBin -j $(nproc); \
#            ${S_USER_HOME}/scipion3/scipion3 installb "$SD_BIN" -j $(nproc); \
#        fi; \
#    fi

#RUN if [ ! -z "${SD_DIR}" ]; then \
#        cp -r "/home/scipionuser/scipion3/software/em/${SD_DIR}" "/scipion-tool/"; \
#    else \
#        false; \
#    fi
#RUN rm -rf "${S_USER_HOME}/scipion3"
#RUN rm -rf "${S_USER_HOME}/miniconda3"

#ENTRYPOINT ["sleep", "infinity"]
ENTRYPOINT ["/docker-entrypoint.sh"]















# cannot compile xmipp using "runtime" image
FROM nvidia/cudagl:10.2-devel-ubuntu18.04 AS tool-base
#FROM nvidia/cudagl:11.4.2-devel-ubuntu18.04

ENV S_USER=scipionuser
ENV S_USER_HOME=/home/${S_USER}

# temporary workaround
# https://developer.download.nvidia.com/compute/cuda/repos/
RUN apt-key del 7fa2af80
RUN rm /etc/apt/sources.list.d/cuda.list
RUN rm /etc/apt/sources.list.d/nvidia-ml.list

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
	ca-certificates \
	python3

# gettext - envsubst
# cuda-samples, strace, nmap - for testing and debuging purpose

# temporary workaround
# https://developer.download.nvidia.com/compute/cuda/repos/
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    rm cuda-keyring_1.0-1_all.deb

RUN rm /usr/local/cuda && ln -s /usr/local/cuda-10.2 /usr/local/cuda

# Another MPI requirements
#RUN apt install -y --no-install-recommends libopenmpi-dev libopenmpi2 openmpi-bin openmpi-common

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
ENV NVIDIA_VISIBLE_DEVICES=all
ENV CUDA_VISIBLE_DEVICES=all

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

RUN mkdir -p ${S_USER_HOME}/scipion3/data && \
    ln -s ${S_USER_HOME}/ScipionUserData/projects ${S_USER_HOME}/scipion3/data

USER ${S_USER}
#######################

ENTRYPOINT ["/docker-entrypoint.sh"]


FROM tool-base
ARG SD_DIR
COPY --from=tool-base "/home/scipionuser/scipion3/software/em/${SD_DIR}" "/scipion-tool/"
