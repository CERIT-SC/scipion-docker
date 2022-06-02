#!/bin/sh

set -e

dir_od="/mnt/od-source"
dir_vol="/mnt/vol-source"

exit_f () {
	echo "Cloner cannot be started"
	exit 1
}

test_dir () {
	if ! test -d "$1"; then
		echo "The mountpoint \"${1}\" missing"
		exit_f
	fi
}

test_dir "$dir_od"
test_dir "$dir_vol"

if [ $(ls "${dir_od}/" | wc -l) != "1" ]; then
	echo "There are more or less Onedata spaces than one in the \"${dir_od}\" path."
	exit_f
fi

dir_od_path="${dir_od}/$(ls "${dir_od}/")"

if [ $(ls "$dir_od_path" | wc -l) = "0" ]; then
	echo "There is no data in the Onedata mount \"${dir_od_path}\""
	exit_f
fi

/opt/cloner/cloner.sh

