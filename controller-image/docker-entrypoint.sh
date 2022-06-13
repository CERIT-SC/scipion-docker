#!/bin/bash

check_status () {
	local pod="$1"

	pod_k8s_line=$(kubectl get pod | grep "$pod")
	pod_fullname=$(echo "$pod_k8s_line" | awk '{print $1}')
	pod_status=$(echo "$pod_k8s_line" | awk '{print $3}')

	if [ -z "$pod_status" ]; then
		echo "${pod}: Container was unexpectedly terminated." >> "$file_log"
	elif [ "$pod_status" = "Completed" ]; then
		echo "${pod}: Container completed successfully." >> "$file_log"

		return 0

	elif [ "$pod_status" = "ImagePullBackOff" ] ||
	     [ "$pod_status" = "ErrImagePull" ]; then
		echo "" >> "$file_log"
		echo "${pod}: Container cannot be started. K8S description:" >> "$file_log"
		sleep 2
		kubectl describe pod "$pod_fullname" >> "$file_log"
		echo ""
		echo "${pod}: Instance startup failed. Check the log in the \"controller\" container: \"${file_log}\"" >> "$file_log"

		return 0

	elif [ "$pod_status" = "CrashLoopBackOff" ] ||
	     [ "$pod_status" = "Error" ]; then
		echo "" >> "$file_log"
		echo "${pod}: Container failed. K8S log:" >> "$file_log"
		sleep 2

		kubectl logs "$pod_fullname" >> "$file_log"
		echo ""
		echo "${pod}: Instance startup failed. Check the log in the \"controller\" container: \"${file_log}\"" >> "$file_log"

		return 0

	elif [ "$pod_status" = "ContainerCreating" ]; then
		echo "${pod}: Container is still creating." >> "$file_log"
	elif [ "$pod_status" = "Pending" ]; then
		echo "${pod}: Pending launch." >> "$file_log"
	elif [ "$pod_status" = "Running" ]; then
		echo "${pod}: Container is still running." >> "$file_log"
	fi

	return 1
}

#auto_save () {
#}

trap_save () {
	echo "This Scipion instance has received a stop signal. The Scipion application will be terminated and the project saved to the Onedata." >> "$file_log"

	kubectl delete --force job scipion-docker-backup || true
	export SUBST_CLONER_ACTION="backup"
	export SUBST_CLONER_REMOVE_LOCK="true"
	pod_saver=$(envsubst < /opt/deploy_cloner.yaml | kubectl apply -f - | awk '{print $1}' | cut -d'/' -f2)

	while ! check_status "scipion-docker-backup"; do
		sleep 10
	done
	
	echo "Project is saved. This instance is being deleted." >> "$file_log"

	kubectl delete \
		job.batch/scipion-cloner-backup \
		job.batch/scipion-cloner-restore \
		job.batch/scipion-cloner-clone \
		deployment.apps/scipion-master || true
}

set -x

dir_scipion="/mnt/vol-project/scipion-docker"
file_log="${dir_scipion}/instance.log"
file_status="${dir_scipion}/instance-status"

export SUBST_NAMESPACE=handl-ns

mkdir -p "${dir_scipion}"
rm "${file_status}" || true
rm "${file_log}" || true

echo "Deployment created" >> "$file_log"

# Run cloner
export SUBST_CLONER_ACTION="clone"
echo "Copying raw source data from Onedata storage" >> "$file_log"
pod_cloner=$(envsubst < /opt/deploy_cloner.yaml | kubectl apply -f - | awk '{print $1}' | cut -d'/' -f2)

echo "debug - pod clone ${pod_cloner}"

# Run syncer restore
export SUBST_CLONER_ACTION="restore"
echo "Restoring project data from Onedata storage" >> "$file_log"
pod_syncer=$(envsubst < /opt/deploy_cloner.yaml | kubectl apply -f - | awk '{print $1}' | cut -d'/' -f2)

echo "debug - pod restore ${pod_syncer}"

pod_list=("$pod_cloner" "$pod_syncer")
pod_list_stopped=("false" "false")

count_completed=0
while [ "${pod_list_stopped[0]}" = "false" ] || [ "${pod_list_stopped[1]}" = "false" ]; do
	for pod_index in 0 1; do
		if [ "${pod_list_stopped[$pod_index]}" = "true" ]; then
			continue 1
		fi

		pod="${pod_list[$pod_index]}"

		if check_status "$pod"; then
			pod_list_stopped[$pod_index]="true"
		fi

		sleep 30
	done
done

echo "je mozne spustit scipion"
echo "ok" >> "$file_status"

#kubectl delete job.batch/scipion-cloner-clone job.batch/scipion-cloner-restore || true

trap trap_save EXIT 

while true; do
	sleep 600

	previous_cloner=$(kubectl get pod | grep scipion-cloner-backup | awk '{print $3}')
	if [ "Running" = "${previous_cloner}" ]; then
		echo "The previous autosave is still running. The new one will not start now." >> "$file_log"
		return 1
	fi
	
	echo "Autosaving the project" >> "$file_log"

	kubectl delete --force job scipion-docker-backup || true
	
	export SUBST_CLONER_ACTION=backup
	pod_saver=$(envsubst < /opt/deploy_cloner.yaml | kubectl apply -f - | awk '{print $1}' | cut -d'/' -f2)
done


# TODO kill and wait (pozor na timeout v k8s podu)
echo "Saving the project" >> "$file_log"
# 
# TODO provest "ls" pro force updatu adresaru v k8s volumu! | kvuli logum | Ales
 
