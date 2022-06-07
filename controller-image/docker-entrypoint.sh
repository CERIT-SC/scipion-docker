#!/bin/bash

set -x

dir_scipion="/mnt/vol-project/scipion-docker"
log_file="${dir_scipion}/instance.log"
status_file="${dir_scipion}/instance-status"

mkdir -p "${dir_scipion}"
rm "${status_file}" || true
rm "${log_file}" || true

echo "Deployment created" >> "$log_file"

# Run cloner
export SUBST_NAMESPACE=handl-ns
export SUBST_CLONER_ACTION=clone
echo "Copying raw source data from Onedata storage" >> "$log_file"
pod_cloner=$(envsubst < /opt/deploy_cloner.yaml | kubectl apply -f - | awk '{print $1}' | cut -d'/' -f2)

echo "debug - pod clone ${pod_cloner}"

# Run syncer restore
export SUBST_NAMESPACE=handl-ns
export SUBST_CLONER_ACTION=restore
echo "Restoring project data from Onedata storage" >> "$log_file"
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

		sleep 30
		pod_k8s_line=$(kubectl get pod | grep "$pod")
		pod_fullname=$(echo "$pod_k8s_line" | awk '{print $1}')
		pod_status=$(echo "$pod_k8s_line" | awk '{print $3}')
		
		echo "debug - checking status - pod ${pod_fullname}"

		if [ -z "$pod_status" ]; then
			echo "${pod}: Container was unexpectedly terminated." >> "$log_file"
		elif [ "$pod_status" = "Completed" ]; then
			echo "${pod}: Container completed successfully." >> "$log_file"

			pod_list_stopped[$pod_index]="true"

		elif [ "$pod_status" = "ImagePullBackOff" ] ||
		     [ "$pod_status" = "ErrImagePull" ]; then
			echo "" >> "$log_file"
			echo "${pod}: Container cannot be started. K8S description:" >> "$log_file"
			sleep 2
			kubectl describe pod "$pod_fullname" >> "$log_file"
			echo ""
			echo "${pod}: Instance startup failed. Check the log in the controller container: \"${log_file}\"" >> "$log_file"

			pod_list_stopped[$pod_index]="true"

		elif [ "$pod_status" = "CrashLoopBackOff" ] ||
		     [ "$pod_status" = "Error" ]; then
			echo "" >> "$log_file"
			echo "${pod}: Container failed. K8S log:" >> "$log_file"
			sleep 2

			# TODO kubectl log instead of describe - problem with creating/updating roles in k8s
			kubectl describe pod "$pod_fullname" >> "$log_file"
			echo ""
			echo "${pod}: Instance startup failed. Check the log in the controller container: \"${log_file}\"" >> "$log_file"

			pod_list_stopped[$pod_index]="true"

		elif [ "$pod_status" = "ContainerCreating" ]; then
			echo "${pod}: Container is still creating." >> "$log_file"
		elif [ "$pod_status" = "Pending" ]; then
			echo "${pod}: Pending launch." >> "$log_file"
		fi
	done
done

echo "je mozne spustit scipion"
echo "ok" >> "$status_file"
#kubectl delete job.batch/scipion-cloner-clone job.batch/scipion-cloner-restore || true

while true; do
	echo "Autosaving the project" >> "$log_file"
	#envsubst < /opt/deploy_syncer_autosave.yaml | kubectl apply -f -
	sleep 600
done

# hook: run syncer save
# TODO
echo "This Scipion instance received a stop signal. The Scipion application will be terminated and project saved to the Onedata." >> "$log_file"
# TODO kill and wait (pozor na timeout v k8s podu)
echo "Saving the project" >> "$log_file"
# TODO dave
echo "Project is saved. Destroying the instance." >> "$log_file"
# 
# TODO provest "ls" pro force updatu adresaru v k8s volumu! | kvuli logum | Ales
 
