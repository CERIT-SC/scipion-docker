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
        echo "The instance cannot be started" >> "$file_log"
        sleep infinity
}

test_dir () {
        if ! test -d "$1"; then
                echo "The mountpoint \"${1}\" missing" >> "$file_log"
                exit_f
        fi
}

test_dir "$dir_od"
test_dir "$dir_vol"

if [ $(ls "${dir_od}/" | wc -l) != "1" ]; then
        echo "There are more or less Onedata spaces than one in the \"${dir_od}\" path." >> "$file_log"
        exit_f
fi

dir_od_path="${dir_od}/$(ls "${dir_od}/")"

if [ $(ls "$dir_od_path" | wc -l) = "0" ]; then
        echo "There is no data in the Onedata mount \"${dir_od_path}\"!" >> "$file_log"
fi

trapsave () {
	echo "This Scipion instance has received a stop signal. The Scipion application will be terminated and the project saved to the Onedata" >> "$file_log"

	if [ kill -SIGTERM $pid_autosave ]; then
		"The autosave was terminated" >> "$file_log"
	fi

	./cloner.sh trapsave 2>> "$file_log" &

	echo "Project is saved. Instance is being deleted" >> "$file_log"

	exit 0
}

mkdir -p "${dir_scipion}"
rm "${file_status}" || true
rm "${file_log}" || true

echo "Deployment created" >> "$file_log"

# Start cloner-clone and cloner-restore
#==========================================

./cloner.sh clone 2>> "$file_log" &
pid_clone=$!

./cloner.sh restore 2>> "$file_log" &
pid_restore=$!

update_progress () {
	# remove the previous line from the log
	sed -i "/${1}:.*$/d" "$file_log"

	# print new line with rsync progress
	progress=$(sed 's/.*\r//' "$2" | awk '{print $2}')
	echo "${1}: ${progress}" >> "$file_log"
}

while true; do
	sleep 5

	if ps -p $pid_clone > /dev/null; then
		update_progress "Cloning" "${dir_cloner}/progress-clone.log"
	elif ! wait $pid_clone; then
		echo "Cloning failed" >> "$file_log"
		pid_clone=0
		exit_f
	fi

	if ps -p $pid_restore > /dev/null; then
		update_progress "Restoring" "${dir_cloner}/progress-restore.log"
	elif ! wait $pid_restore; then
		echo "Restore failed" >> "$file_log"
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
	./cloner.sh autosave 2>> "$file_log" &
	pid_autosave=$!
	if ! wait $pid_autosave; then
		echo "Autosave failed" >> "$file_log"
	fi
done

# TODO kill and wait (pozor na timeout v k8s podu)
#echo "Saving the project" >> "$file_log"
# 
# TODO provest "ls" pro force updatu adresaru v k8s volumu! | kvuli logum | Ales
 
