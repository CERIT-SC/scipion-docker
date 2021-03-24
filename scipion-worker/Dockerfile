
FROM registry.gitlab.ics.muni.cz:443/eosc-synergy/scipion-docker/base-image:dev

ARG S_USER=scipionuser
ARG S_USER_HOME=/home/${S_USER}

USER root

RUN apt update && apt install -y --no-install-recommends python

COPY plugin-list.txt ${S_USER_HOME}/

RUN for pl in $(cat ${S_USER_HOME}/plugin-list.txt); do ${S_USER_HOME}/scipion3/scipion3 installp -p $pl -j $(nproc); done

ENTRYPOINT ["bash"]
