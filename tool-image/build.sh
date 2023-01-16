#!/bin/bash

set -e

tag=${tag:-dev}

img_docker_com="jhandl/scipion-tool"
img_cerit_io="hub.cerit.io/josef_handl/scipion-tool"

docker-build-push () {
	docker build -t "${img_docker_com}:${1}-${tag}" "${@:2}" .
	docker build -t "${img_cerit_io}:${1}-${tag}" "${@:2}" .

	docker push "${img_docker_com}:${1}-${tag}"
	docker push "${img_cerit_io}:${1}-${tag}"
}

build-tool () {
	docker-build-push "appion"     --build-arg SD_PLUGIN="scipion-em-appion"                                 #&
	docker-build-push "cistem"     --build-arg SD_PLUGIN="scipion-em-cistem"                                 #&
	docker-build-push "eman2"      --build-arg SD_PLUGIN="scipion-em-eman2"                                  #&
	docker-build-push "gautomatch" --build-arg SD_PLUGIN="scipion-em-gautomatch"                             #&
	docker-build-push "gctf"       --build-arg SD_PLUGIN="scipion-em-gctf" --build-arg SD_BIN="gctf-1.18"    #&
	docker-build-push "motioncorr" --build-arg SD_PLUGIN="scipion-em-motioncorr"                             #&
	docker-build-push "phenix"     --build-arg SD_PLUGIN="scipion-em-phenix"                                 #&
	docker-build-push "pwem"                                                                                 #&
	docker-build-push "relion"     --build-arg SD_PLUGIN="scipion-em-relion" --build-arg SD_BIN="relion-4.0" #&
	docker-build-push "spider"     --build-arg SD_PLUGIN="scipion-em-spider"                                 #&
	docker-build-push "xmipp3"                                                                               #&
}

cd "$(dirname "$0")"

build-tool

wait
