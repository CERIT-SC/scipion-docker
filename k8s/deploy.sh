#!/bin/bash

set -e

if [ "$#" != 4 ]; then
	echo "Wrong arguments!"
	echo "'./deploy.sh namespace onedata_host onedata_token vnc_password'"
	exit 1
fi

yaml_files=(
	"secret.yaml"
	"cluster-ip-vnc.yaml"
	"cluster-ip-x11.yaml"
	"pvc-onedata-sources.yaml"
	"pv-onedata-sources.yaml"
	"sa.yaml"
	"role.yaml"
	"rolebinding.yaml"
	"deployment.yaml"
)

export SUBST_NAMESPACE="$1"
export SUBST_OD_HOST=$(echo "$2" | base64 --wrap 0)
export SUBST_OD_TOKEN=$(echo "$3" | base64 --wrap 0)
export SUBST_VNC_PASS="$4"

for yaml in "${yaml_files[@]}"; do
	envsubst < "$yaml" | microk8s.kubectl apply -f -
done
#	"pvc-work.yaml"
#	"pvc-onedata-projects-temp.yaml"
