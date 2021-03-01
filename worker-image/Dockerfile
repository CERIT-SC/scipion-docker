
#FROM registry.gitlab.ics.muni.cz:443/eosc-synergy/scipion-docker/base-image:dev
FROM ldelcano/scipion-base:slurm

ARG S_USER=scipionuser
ARG S_USER_HOME=/home/${S_USER}

USER root

RUN apt update && apt install -y --no-install-recommends python

COPY plugin-list.txt ${S_USER_HOME}/

USER scipionuser

RUN for pl in $(cat ${S_USER_HOME}/plugin-list.txt); do ${S_USER_HOME}/scipion3/scipion3 installp -p $pl -j $(nproc); done

RUN echo MOTIONCOR2_BIN=${S_USER_HOME}/software/em/motioncor2-1.4.0/bin/MotionCor2_1.4.0_Cuda102 >> ${S_USER_HOME}/scipion3/config/scipion.conf

ENTRYPOINT ["bash"]
