#!/bin/bash

set -e

img_docker_com="jhandl/scipion-tool"
img_cerit_io="hub.cerit.io/josef_handl/scipion-tool"

docker-build-push () {
	docker build -t ${img_docker_com}:$1 "${@:2}" .
	docker build -t ${img_cerit_io}:$1 "${@:2}" .

	docker push ${img_docker_com}:$1
	docker push ${img_cerit_io}:$1
}

build-tool () {
	docker-build-push "scipion-em-appion"     --build-arg SD_PLUGIN="scipion-em-appion"
	docker-build-push "scipion-em-cistem"     --build-arg SD_PLUGIN="scipion-em-cistem"
	docker-build-push "scipion-em-eman2"      --build-arg SD_PLUGIN="scipion-em-eman2"
	docker-build-push "scipion-em-gautomatch" --build-arg SD_PLUGIN="scipion-em-gautomatch"
	docker-build-push "scipion-em-gctf"       --build-arg SD_PLUGIN="scipion-em-gctf" --build-arg SD_BIN="gctf-1.18"
	docker-build-push "scipion-em-motioncorr" --build-arg SD_PLUGIN="scipion-em-motioncorr"
	docker-build-push "scipion-em-phenix"     --build-arg SD_PLUGIN="scipion-em-phenix"
	docker-build-push "scipion-em-pwem"
	docker-build-push "scipion-em-relion"     --build-arg SD_PLUGIN="scipion-em-relion" --build-arg SD_BIN="relion-4.0"
	docker-build-push "scipion-em-spider"     --build-arg SD_PLUGIN="scipion-em-spider"
	docker-build-push "scipion-em-xmipp3"
}

set -e

cd "$(dirname "$0")"

if [ "$1" != "--nobase" ]; then
	../base-image/build.sh
fi

build-tool &

wait
