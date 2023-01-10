#!/bin/bash

set -e

tag=${tag:-dev}

img_docker_com="jhandl/scipion-tool"
img_cerit_io="hub.cerit.io/josef_handl/scipion-tool"

docker-build-push () {
#	docker build -t "${img_docker_com}:${1}-${tag}" "${@:2}" .
	docker build -t "${img_cerit_io}:${1}-${tag}" "${@:2}" .

#	docker push "${img_docker_com}:${1}-${tag}"
	docker push "${img_cerit_io}:${1}-${tag}"
}

build-tool () {
	docker-build-push "cistem"     --build-arg SD_DIR="cistem-1.0.0-beta" #&
	docker-build-push "eman2"      --build-arg SD_DIR="eman-2.99"         #&
	docker-build-push "gautomatch" --build-arg SD_DIR="gautomatch-0.56"   #&
	docker-build-push "gctf"       --build-arg SD_DIR="gctf-1.18"         #&
	docker-build-push "motioncorr" --build-arg SD_DIR="motioncor2-1.4.0"  #&
	docker-build-push "phenix"     --build-arg SD_DIR=""                  #&
	docker-build-push "pwem"       --build-arg SD_DIR=""                  #&
	docker-build-push "relion"     --build-arg SD_DIR=""                  #&
	docker-build-push "spider"     --build-arg SD_DIR=""                  #&
	docker-build-push "xmipp3"     --build-arg SD_DIR=""                  #&
	docker-build-push "appion"     --build-arg SD_DIR=""                  #&
}

set -e

cd "$(dirname "$0")"

if [ "$1" != "--nobase" ]; then
	true #../base-image/build.sh
fi

build-tool

wait
