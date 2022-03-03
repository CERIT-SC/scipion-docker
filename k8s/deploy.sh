#!/bin/bash

set -e

if [ "$#" != 3 ]; then
	echo "Missing arguments"
	echo "'./deploy.sh namespace onedata_host onedata_token'"
	exit 1
fi

yaml_files=(
	"secret.yaml"
	"cluster-ip-vnc.yaml"
	"cluster-ip-x11.yaml"
	"pvc-onedata.yaml"
	"pv-onedata.yaml"
	"sa.yaml"
	"role.yaml"
	"rolebinding.yaml"
	"ingress.yaml"
	"deployment.yaml"
)

export SUBST_NAMESPACE="$1"
export SUBST_OD_HOST="$2"
export SUBST_OD_TOKEN="$3"

for yaml in "${yaml_files[@]}"; do
	envsubst < "$yaml" | kubectl apply -f -
done
