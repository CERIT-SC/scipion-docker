#!/bin/sh

set -ex

dir_od_p="/mnt/od-project"
dir_vol_p="/mnt/vol-project"
dir_tmp="/opt/cloner/tmp"

dir_od_s="/mnt/od-source"
dir_vol_s="/mnt/vol-source"

dir_scipion="scipion-docker"
file_symlink_dump="symlink-dump"
file_project_lock="project.lock"

# TODO tmp solution - check in docker-entrypoint
dir_od_p_path="${dir_od_p}/$(ls ${dir_od_p})"
dir_vol_p_path="${dir_vol_p}"

# TODO tmp solution - check in docker-entrypoint
dir_od_s_path="${dir_od_s}/$(ls ${dir_od_s})"
dir_vol_s_path="${dir_vol_s}"

rsync_options="--delete --recursive --times --omit-dir-times"

echo "${dir_od_p_path}/"
echo "${dir_od_s_path}/"

# vol-project > od-project
#--------------------------
backup_project () {
	# vol-project > tmp
	rsync $rsync_options --links "${dir_vol_p_path}/" "${dir_tmp}/"

	# create dump
	rm "${dir_tmp}/${dir_scipion}/${file_symlink_dump}" || true
	cd "${dir_tmp}/"
	for link in $(find -L "./" -xtype l); do
		link_target="$(readlink -f ${link})"
		echo "${link_target} ${link}" >> "${dir_tmp}/${file_symlink_dump}"
	done

	# remove symlinks
	cd "${dir_tmp}/"
	for link in $(find -L "./" -xtype l); do
		rm "${dir_tmp}/${link}"
	done

	# tmp > od-project
	rsync $rsync_options "${dir_tmp}/" "${dir_od_p_path}/"

	# remove project lock in OD
	rm "${dir_od_p_path}/${dir_scipion}/${file_project_lock}"
}

# od-project > vol-project
#--------------------------
restore_project () {
	if [ -f "${dir_od_p_path}/${dir_scipion}/${file_project_lock}" ]; then
		echo "TODO project is opened in another instance"
		exit 1
	fi

	mkdir -p "${dir_od_p_path}/${dir_scipion}/"

	# lock project in OD
	touch "${dir_od_p_path}/${dir_scipion}/${file_project_lock}"

	# od-project > tmp
	rsync $rsync_options "${dir_od_p_path}/" "${dir_tmp}/"

	# restore symlinks in tmp dir
	cd "${dir_tmp}/"
	while read line; do
		link_target=$(echo $line | awk '{ print $1 }')
		link=$(echo $line | awk '{ print $2 }')
		ln -s "$link_target" "$link"
	done < "${dir_tmp}/${dir_scipion}/${file_symlink_dump}"

	# tmp > vol-project
	rsync $rsync_options --links "${dir_tmp}/" "${dir_vol_p_path}/"
}

# od-source > vol-source
#--------------------------
clone_source () {
	rsync -av --delete --no-perms --omit-dir-times "${dir_od_s_path}/" "${dir_vol_s_path}/"
}

if [ "$CLONER_ACTION" = "backup" ]; then
	backup_project
elif [ "$CLONER_ACTION" = "restore" ]; then
	restore_project
elif [ "$CLONER_ACTION" = "clone" ]; then
	clone_source
else
	echo "No action has been specified"
	exit 1
fi

