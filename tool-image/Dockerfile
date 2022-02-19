FROM nvidia/cudagl:10.2-devel-ubuntu18.04

ARG S_USER=scipionuser
ARG S_USER_HOME=/home/${S_USER}

RUN apt update && apt upgrade -y

RUN apt update && DEBIAN_FRONTEND="noninteractive" apt install -y --no-install-recommends \
        tzdata

#RUN du -sh / || true

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
        gettext
# gettext - envsubst

# Required by Scipion
RUN apt update && apt install -y --no-install-recommends \
        libxv1 \
        openjdk-8-jdk \
        libfftw3-dev \
        libtiff-dev

# Required by Scipion for conda installation
RUN apt-get -y install --no-install-recommends sudo wget gcc g++ libopenmpi-dev mesa-utils openssh-client cmake libnss3 libfontconfig1 libxrender1 libxtst6 xterm libasound2 libglu1 libxcursor1 libdbus-1-3 libxkbcommon-x11-0 libhdf5-dev
# Another MPI requirements
RUN apt install -y libopenmpi-dev libopenmpi2 openmpi-bin openmpi-common

# TODO OneData

# Create scipionuser
RUN groupadd --gid 1000 ${S_USER} && \
    useradd --uid 1000 --create-home --home-dir ${S_USER_HOME} -s /bin/bash -g ${S_USER} ${S_USER} && \
    usermod -aG sudo ${S_USER}

RUN chown -R ${S_USER}:${S_USER} ${S_USER_HOME}

ENV CUDA_HOME "/usr/local/cuda"
#ENV PATH "${CUDA_HOME}/bin:$PATH"
ENV CUDA_BIN "/usr/local/cuda/bin"

ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

# prepare working directory
RUN mkdir ${S_USER_HOME}/ScipionUserData && \
    cd ${S_USER_HOME}/ScipionUserData && \
    mkdir projects logs

USER ${S_USER}
#######################

RUN ["/bin/bash", "-c", "echo $CUDA_HOME"]
RUN ["/bin/bash", "-c", "echo $PATH"]

RUN du -sh / || true

# Install Scipion
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ${S_USER_HOME}/miniconda.sh
RUN bash ${S_USER_HOME}/miniconda.sh -b
RUN ${S_USER_HOME}/miniconda3/bin/conda init
RUN ["/bin/bash", "-ci" , "python3 -m pip install scipion-installer"]
RUN ["/bin/bash", "-ci" , "cd ${S_USER_HOME} && python3 -m scipioninstaller ${S_USER_HOME}/scipion3 -noAsk -noXmipp -j $(nproc)"]

# Install xmipp without native compilation flags
#RUN ["/bin/bash", "-c" , "${S_USER_HOME}/scipion3/scipion3 installp -p scipion-em-xmipp -j $(nproc) --noBin"]
#RUN mkdir ${S_USER_HOME}/scipion3/software/em || true
#RUN wget http://scipion.cnb.csic.es/downloads/scipion/software/em/xmippSrc-v3.20.07.tgz -O ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07.tgz
#RUN tar xfz ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07.tgz -C ${S_USER_HOME}/scipion3/software/em/
#RUN ["/bin/bash", "-c" , "cd ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07 && ${S_USER_HOME}/scipion3/scipion3 run ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp noAsk config"]
#RUN sed -i 's/-mtune=native -march=native //g' ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp.conf
#RUN sed -i 's/CUDA=True/CUDA=False/g' ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp.conf
#RUN ["/bin/bash", "-c" , "cd ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07 && ${S_USER_HOME}/scipion3/scipion3 run ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp compile"]
#RUN mkdir ${S_USER_HOME}/scipion3/software/lib || true
#RUN ["/bin/bash", "-c" , "cd ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07 && ${S_USER_HOME}/scipion3/scipion3 run ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/xmipp install"]
#RUN ln -s ${S_USER_HOME}/scipion3/software/em/xmippSrc-v3.20.07/build ${S_USER_HOME}/scipion3/software/em/xmipp

USER root

COPY res/scipion.conf ${S_USER_HOME}/scipion3/config/scipion.conf
RUN chown ${S_USER}:${S_USER} ${S_USER_HOME}/scipion3/config/scipion.conf

USER $S_USER

RUN /home/scipionuser/scipion3/scipion3 installp -p scipion-em-xmipp -j $(nproc)


RUN du -sh / || true

# Disable conda auto activation
RUN ${S_USER_HOME}/miniconda3/bin/conda config --set auto_activate_base false


ARG SD_PLUGIN
ARG SD_BIN

RUN if [ ! -z "$SD_PLUGIN" ]; then \
        if [ -z "$SD_BIN" ]; then \
            ${S_USER_HOME}/scipion3/scipion3 installp -p "$SD_PLUGIN" -j $(nproc); \
        else \
            ${S_USER_HOME}/scipion3/scipion3 installp -p "$SD_PLUGIN" --noBin -j $(nproc); \
            ${S_USER_HOME}/scipion3/scipion3 installb "$SD_BIN" -j $(nproc); \
        fi; \
    fi


USER root
######################

# run docker-entrypoint.sh
COPY docker-entrypoint-root.sh /
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint-root.sh && \
    chmod +x /docker-entrypoint.sh


RUN apt update && apt install -y --no-install-recommends iputils-ping strace xauth

#USER root
USER $S_USER

RUN export string="\ \ \ \ \ \ \ \ print(\"debugovacivypiszacatek-\" + str(self.getInputMicrographs()) + \"-debugovacivypiskonec\")" && sed -i "570 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/xmipp3/protocols/protocol_extract_particles_pairs.py
#ENTRYPOINT ["/docker-entrypoint-root.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]
