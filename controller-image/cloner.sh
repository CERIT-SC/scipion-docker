#!/bin/sh

set -e

dir_od_p="/mnt/od-project"
dir_vol_p="/mnt/vol-project"
dir_cloner="/opt/cloner"

dir_od_s="/mnt/od-dataset"
dir_vol_s="/mnt/vol-dataset"

dir_scipion="scipion-docker"
file_symlink_dump="symlink-dump"
file_project_lock="project.lock"
file_instance_status="instance-status"
file_instance_log="instance.log"

file_instance_log_path="${dir_vol_p}/${dir_scipion}/${file_instance_log}"

dir_od_p_path="${dir_od_p}/$(ls ${dir_od_p})"
dir_vol_p_path="${dir_vol_p}"

dir_od_s_path="${dir_od_s}/$(ls ${dir_od_s})"
dir_vol_s_path="${dir_vol_s}"

rsync_options="--delete --recursive --times --omit-dir-times --info=progress2"

# vol-project > od-project
#--------------------------
save_project () {
	# create symlinks dump
	rm "${dir_vol_p_path}/${file_symlink_dump}" 2> /dev/null || true
	cd "${dir_vol_p_path}/"
	for link in $(find -L "./" -xtype l); do
		link_target="$(readlink ${link})"
		echo "${link_target} ${link}" >> "${dir_vol_p_path}/${file_symlink_dump}"
	done

	# rsync vol-project > od-project (except symlinks)
	rsync $rsync_options --exclude "${dir_scipion}/" "${dir_vol_p_path}/" "${dir_od_p_path}/" > /dev/null

	# remove project lock in OD
	if [ "$1" = "unlock" ]; then
		rm "${dir_od_p_path}/${dir_scipion}/${file_project_lock}"
		echo "The project lock has been removed"
	fi
}
autosave_project () {
	echo "Autosaving the project"
	save_project
	echo "Autosave has been completed"
}
trapsave_project () {
	echo "Saving the project due to instance termination"
	save_project unlock
	echo "Save has been completed"
}

# od-project > vol-project
#--------------------------
restore_project () {
	echo "Restoring the project"

	# check project lock
	if [ -f "${dir_od_p_path}/${dir_scipion}/${file_project_lock}" ]; then
		echo "Error: The project is opened in another instance"
		exit 1
	fi

	# remove files from the last instance
	mkdir -p "${dir_od_p_path}/${dir_scipion}/"
	rm "${dir_od_p_path}/${dir_scipion}/${file_instance_status}" 2> /dev/null || true
	rm "${dir_od_p_path}/${dir_scipion}/${file_instance_log}" 2> /dev/null || true

	# lock the project in OD
	touch "${dir_od_p_path}/${dir_scipion}/${file_project_lock}"
	echo "The project has been locked so that it cannot be opened from another instance of Scipion"

	# rsync od-project > vol-project
	rsync $rsync_options --exclude "${dir_scipion}/" "${dir_od_p_path}/" "${dir_vol_p_path}/" > "${dir_cloner}/progress-restore.log"

	# restore symlinks in vol-project
	cd "${dir_vol_p_path}/"
	while read line; do
		link_target=$(echo $line | awk '{ print $1 }')
		link=$(echo $line | awk '{ print $2 }')
		ln -s "$link_target" "$link"
	done < "${dir_od_p_path}/${file_symlink_dump}"

	echo "Restore has been completed"
}

# od-dataset > vol-dataset
#--------------------------
clone_dataset () {
	echo "Cloning a dataset data"
	rsync $rsync_options "${dir_od_s_path}/" "${dir_vol_s_path}/" > "${dir_cloner}/progress-clone.log"
	echo "Cloning has been completed"
}

if [ "$1" = "autosave" ]; then
	autosave_project
elif [ "$1" = "trapsave" ]; then
	trapsave_project
elif [ "$1" = "restore" ]; then
	restore_project
elif [ "$1" = "clone" ]; then
	clone_dataset
else
	echo "No action has been specified"
	exit 1
fi

