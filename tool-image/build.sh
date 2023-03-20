#!/bin/bash

tag=${tag:-dev}

set -e

img_cerit_io="hub.cerit.io/scipion/scipion-tool"

docker-build-push () {
    docker build --build-arg RELEASE_CHANNEL="$tag" -t "${img_cerit_io}:${1}-${tag}" "${@:2}" .

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
	docker-build-push "pwem"       --build-arg SD_PLUGIN="scipion-em-xmipp"                                  #&
	docker-build-push "relion"     --build-arg SD_PLUGIN="scipion-em-relion" --build-arg SD_BIN="relion-4.0" #&
	docker-build-push "spider"     --build-arg SD_PLUGIN="scipion-em-spider"                                 #&
	docker-build-push "xmipp3"     --build-arg SD_PLUGIN="scipion-em-xmipp"                                  #&
}

cd "$(dirname "$0")"

if [ "$1" = "--base" ]; then
    ../base-image/build.sh
fi

build-tool

wait
