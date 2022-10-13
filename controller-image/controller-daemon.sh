#!/bin/bash

set -e

dir_od="/mnt/od-dataset"
dir_vol="/mnt/vol-dataset"

dir_scipion="/mnt/vol-project/scipion-docker"
file_log="${dir_scipion}/instance.log"
file_status="${dir_scipion}/instance-status"

dir_cloner="/opt/cloner"

# Check the mounts
#====================

exit_f () {
        echo "The instance cannot be started"
        sleep infinity
}

test_dir () {
        if ! test -d "$1"; then
                echo "The mountpoint \"${1}\" missing"
                exit_f
        fi
}

trapsave () {
	echo "This Scipion instance has received a stop signal. The Scipion application will be terminated and the project saved to the Onedata"

	if [ kill -SIGTERM $pid_autosave ]; then
		"The autosave was terminated"
	fi

	./cloner.sh trapsave

	echo "Project is saved. Instance is being deleted"

	exit 0
}

test_dir "$dir_od"
test_dir "$dir_vol"

if [ $(ls "${dir_od}/" | wc -l) != "1" ]; then
        echo "Error: There are more or less Onedata spaces than one in the \"${dir_od}\" path."
        exit_f
fi

dir_od_path="${dir_od}/$(ls "${dir_od}/")"

if [ $(ls "$dir_od_path" | wc -l) = "0" ]; then
        echo "Warning: There is no data in the Onedata mount \"${dir_od_path}\"!"
fi

echo "Deployment created"

# Start cloner-clone and cloner-restore
#==========================================

./cloner.sh clone &
pid_clone=$!

./cloner.sh restore &
pid_restore=$!

update_progress () {
	# remove the previous line from the log
	sed -i "/${1}:.*$/d" "$file_log"

	# print new line with rsync progress
	progress=$(sed 's/.*\r//' "$2" | awk '{print $2}')
	echo "${1}: ${progress}"
}

while true; do
	sleep 5

	if ps -p $pid_clone > /dev/null; then
		update_progress "Cloning" "${dir_cloner}/progress-clone.log"
	elif ! wait $pid_clone; then
		echo "Cloning failed"
		pid_clone=0
		exit_f
	fi

	if ps -p $pid_restore > /dev/null; then
		update_progress "Restoring" "${dir_cloner}/progress-restore.log"
	elif ! wait $pid_restore; then
		echo "Restore failed"
		pid_restore=0
		exit_f
	fi

	if ! ps -p $pid_clone > /dev/null && ! ps -p $pid_restore > /dev/null; then
		break 1
	fi
done

# Send "signal" to start desktop environment
# and start autosaving
#===============================================

echo "ok" >> "$file_status"

trap trapsave EXIT

set +e

while true; do
	sleep 30
	./cloner.sh autosave &
	pid_autosave=$!
	if ! wait $pid_autosave; then
		echo "Autosave failed"
	fi
done

# TODO provest "ls" pro force updatu adresaru v k8s volumu! | kvuli logum | Ales
 
