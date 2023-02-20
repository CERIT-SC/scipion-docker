ARG RELEASE_CHANNEL

FROM hub.cerit.io/scipion/scipion-base:${RELEASE_CHANNEL}

ARG RELEASE_CHANNEL
ENV RELEASE_CHANNEL=${RELEASE_CHANNEL}

USER root
######################

# Required by Relion tool
RUN apt update && apt install -y --no-install-recommends \
      pkg-config \
      libxft-dev \
      libfreetype6-dev

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

USER ${S_USER}
######################

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

RUN export string="\ \ \ \ \ \ \ \ print(\"debugovacivypiszacatek-\" + str(self.getInputMicrographs()) + \"-debugovacivypiskonec\")" && sed -i "570 i $string" /home/scipionuser/miniconda3/envs/scipion3/lib/python3.8/site-packages/xmipp3/protocols/protocol_extract_particles_pairs.py

USER root
######################

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

USER ${S_USER}
######################

ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_VISIBLE_DEVICES=0
ENV CUDA_VISIBLE_DEVICES=0

#ENTRYPOINT ["sleep", "infinity"]
ENTRYPOINT ["/docker-entrypoint.sh"]
