
#FROM registry.gitlab.ics.muni.cz:443/eosc-synergy/scipion-docker/base-image:dev
FROM ldelcano/scipion-base:slurm

ARG S_USER=scipionuser
ARG S_USER_HOME=/home/${S_USER}

USER root

RUN apt update && apt install -y --no-install-recommends python

COPY plugin-list.txt ${S_USER_HOME}/

USER scipionuser

RUN for pl in $(cat ${S_USER_HOME}/plugin-list.txt); do ${S_USER_HOME}/scipion3/scipion3 installp -p $pl -j $(nproc); done

RUN echo GCTF_CUDA_LIB=/usr/local/cuda-10.2/lib64 >> ${S_USER_HOME}/scipion3/config/scipion.conf

ENTRYPOINT ["bash"]
