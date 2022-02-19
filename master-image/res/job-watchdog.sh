#!/bin/bash

set -e

JOB_ID_RAW=$1

if [ -z "$JOB_ID_RAW" ]; then
	echo "The job ID is not set. Add the job ID as the only argument."
	exit 1
fi

JOB_ID=$(echo "$JOB_ID_RAW" | cut -d'/' -f2)

mkdir -p /home/scipionuser/Desktop/jobs

FILE="/home/scipionuser/Desktop/jobs/$JOB_ID"
touch "$FILE"

function clean_job {
        kubectl delete "$JOB_ID_RAW"
	#notify-send "Watchdog $JOB_ID was terminated"
}

function trap_terminate {
	notify-send "Job $JOB_ID was terminated by a linux trap"
	clean_job
	exit 1
}

function watchdog_terminate {
	notify-send "Job $JOB_ID was terminated by his watchdog"
	clean_job
	exit 1
}

trap "trap_terminate" SIGTERM SIGINT SIGQUIT

while true
do
	JOB_STATUS=$(kubectl get pod | grep "$JOB_ID" | head -n 1 | awk '{print $3}')

	if [ -z "$JOB_STATUS" ]; then
		notify_send "A Kubernetes job was unexpectedly deleted or not started."
		exit 1

	elif [ "$JOB_STATUS" = "Completed" ]; then
		clean_job

		if [ -s diff.txt ]; then
			notify_send "A job completed successfully, but a problem with Kubernetes occured when the job was running. The log was saved to the following file: $FILE"
		else
	                rm "$FILE"
		fi
		exit 0

	elif [ "$JOB_STATUS" = "ImagePullBackOff" ] ||
	     [ "$JOB_STATUS" = "ErrImagePull" ] ||
	     [ "$JOB_STATUS" = "CrashLoopBackOff" ] ||
	     [ "$JOB_STATUS" = "Error" ]; then
		kubectl describe "$JOB_ID_RAW" >> "$FILE"
		echo -e "\n\n\n\n" >> "$FILE"
		notify_send "The job: $JOB_ID failed. Log from the kubernetes was saved to the following file: $FILE"

		watchdog_terminate

	elif [ "$JOB_STATUS" = "ContainerCreating" ] ||
             [ "$JOB_STATUS" = "Running" ]; then
		sleep 1
	fi
	sleep 5
done
