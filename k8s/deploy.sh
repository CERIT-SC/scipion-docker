#!/bin/bash

set -e

yaml_files=(
	"secret.yaml"
	"cluster-ip-vnc.yaml"
	"cluster-ip-x11.yaml"
	"pvc-vol.yaml" # PVC dynamic volume provisioning (both - microk8s & kuba)
	"sa.yaml"
	"role.yaml"
	"rolebinding.yaml"
	"ingress.yaml"
	"deployment.yaml"
)

print_help () {
	echo "Wrong arguments!"
	echo "'./deploy.sh (microk8s|kuba) <namespace> <onedata_host> <onedata_source_token> <onedata_source_space> <onedata_project_token> <onedata_project_space> <vnc_password>'"
	exit 1
}

use_kuba () {
	for yaml in "${yaml_files[@]}"; do
		envsubst < "$yaml" | kubectl apply -f -
	done
	echo -e "kuba\n${SUBST_NAMESPACE}" > deployment_script_info
}

use_microk8s () {
	yaml_files+=(
		"pv.yaml"
		"pvc-od.yaml"
	)
	for yaml in "${yaml_files[@]}"; do
		envsubst < "$yaml" | microk8s.kubectl apply -f -
	done
	echo -e "microk8s\n${SUBST_NAMESPACE}" > deployment_script_info
}

if [ "$#" != 8 ]; then
	print_help
fi

if [ -f deployment_script_info ]; then
	echo "An instance of scipion is already running. (deployment_script_info file exists)."
	exit 2
fi

export SUBST_NAMESPACE="$2"
export SUBST_OD_HOST=$(echo "$3" | base64 --wrap 0)
export SUBST_OD_SOURCE_TOKEN=$(echo "$4" | base64 --wrap 0)
export SUBST_OD_SOURCE_SPACE_ID=$(echo "$5" | base64 --wrap 0)
export SUBST_OD_PROJECT_TOKEN=$(echo "$6" | base64 --wrap 0)
export SUBST_OD_PROJECT_SPACE_ID=$(echo "$7" | base64 --wrap 0)
export SUBST_VNC_PASS="$8"

echo "namespace: ${SUBST_NAMESPACE}"
echo "OD host: ${SUBST_OD_HOST}"
echo "OD source token: ${SUBST_OD_SOURCE_TOKEN}"
echo "OD source space_id: ${SUBST_OD_SOURCE_SPACE_ID}"
echo "OD project token: ${SUBST_OD_PROJECT_TOKEN}"
echo "OD project space_id: ${SUBST_OD_PROJECT_SPACE_ID}"
echo "VNC password: ${SUBST_VNC_PASS}"

if [ "$1" == "microk8s" ]; then
	use_microk8s
elif [ "$1" == "kuba" ]; then
	use_kuba
else
	print_help
fi

