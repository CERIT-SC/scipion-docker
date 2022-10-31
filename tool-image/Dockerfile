FROM hub.cerit.io/josef_handl/scipion-base:latest

USER root
######################

# Required by Relion tool
RUN apt update && apt install -y --no-install-recommends \
      pkg-config \
      libxft-dev \
      libfreetype6-dev

# Clean apt
RUN rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint-root.sh /
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint-root.sh && \
    chmod +x /docker-entrypoint.sh

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

#ENTRYPOINT ["sleep", "infinity"]
ENTRYPOINT ["/docker-entrypoint.sh"]