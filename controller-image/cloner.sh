#!/bin/sh

set -e

dir_od_p="/mnt/od-project"
dir_vol_p="/mnt/vol-project"
dir_cloner="/opt/cloner"
dir_tmp="${dir_cloner}/tmp"

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

echo "${dir_od_p_path}/"
echo "${dir_od_s_path}/"

# vol-project > od-project
#--------------------------
save_project () {
	mkdir -p "${dir_tmp}"

	# rsync vol-project > tmp
	rsync $rsync_options --links "${dir_vol_p_path}/" "${dir_tmp}/"

	# create symlinks dump
	rm "${dir_tmp}/${dir_scipion}/${file_symlink_dump}" || true
	cd "${dir_tmp}/"
	for link in $(find -L "./" -xtype l); do
		link_target="$(readlink ${link})"
		echo "${link_target} ${link}" >> "${dir_tmp}/${file_symlink_dump}"
	done

	# remove symlinks
	cd "${dir_tmp}/"
	for link in $(find -L "./" -xtype l); do
		rm "${dir_tmp}/${link}"
	done

	# rsync tmp > od-project
	rsync $rsync_options "${dir_tmp}/" "${dir_od_p_path}/"

	# remove project lock in OD
	if [ "$1" = "unlock" ]; then
		rm "${dir_od_p_path}/${dir_scipion}/${file_project_lock}"
		echo "The project lock has been removed" >> "$file_instance_log_path"
	fi
}
autosave_project () {
	echo "Autosaving the project" >> "$file_instance_log_path"
	save_project
	echo "Autosave has been completed" >> "$file_instance_log_path"
}
trapsave_project () {
	echo "Saving the project due to instance termination" >> "$file_instance_log_path"
	save_project unlock
	echo "Save has been completed" >> "$file_instance_log_path"
}

# od-project > vol-project
#--------------------------
restore_project () {
	echo "Restoring the project" >> "$file_instance_log_path"

	# check project lock
	if [ -f "${dir_od_p_path}/${dir_scipion}/${file_project_lock}" ]; then
		echo "The project is open in another instance" >> "$file_instance_log_path"
		exit 1
	fi

	# remove last instance files
	mkdir -p "${dir_tmp}"
	mkdir -p "${dir_od_p_path}/${dir_scipion}/"
	rm "${dir_od_p_path}/${dir_scipion}/${file_instance_status}" || true
	rm "${dir_od_p_path}/${dir_scipion}/${file_instance_log}" || true

	# lock the project in OD
	touch "${dir_od_p_path}/${dir_scipion}/${file_project_lock}"
	echo "The project has been locked so that it cannot be opened from another instance of Scipion" >> "$file_instance_log_path"	

	# rsync od-project > tmp
	rsync $rsync_options --exclude "${dir_scipion}/" "${dir_od_p_path}/" "${dir_tmp}/" > "${dir_cloner}/progress-restore.log"
	#rsync $rsync_options --exclude "${dir_tmp}/${dir_scipion}/${file_instance_log}" "${dir_od_p_path}/" "${dir_tmp}/"

	# restore symlinks in tmp dir
	cd "${dir_tmp}/"
	while read line; do
		link_target=$(echo $line | awk '{ print $1 }')
		link=$(echo $line | awk '{ print $2 }')
		ln -s "$link_target" "$link"
	done < "${dir_tmp}/${dir_scipion}/${file_symlink_dump}"

	# rsync tmp > vol-project
	rsync $rsync_options --links --exclude "${dir_scipion}/" "${dir_tmp}/" "${dir_vol_p_path}/" > "${dir_cloner}/progress-restore.log"
	#rsync $rsync_options --links --exclude "${dir_vol_p_path}/${dir_scipion}/${file_instance_log}" "${dir_tmp}/" "${dir_vol_p_path}/"

	echo "Restore has been completed" >> "$file_instance_log_path"
}

# od-dataset > vol-dataset
#--------------------------
clone_dataset () {
	echo "Cloning a dataset data" >> "$file_instance_log_path"
	rsync $rsync_options "${dir_od_s_path}/" "${dir_vol_s_path}/" > "${dir_cloner}/progress-clone.log"
	echo "Cloning has been completed" >> "$file_instance_log_path"
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

