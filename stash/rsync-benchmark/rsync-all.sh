#!/bin/bash

set -x

d_od_arr=(
	"/mnt/od-s3-cesnet/test_s3_cesnet"
	"/mnt/od-s3-elixir/test_s3_elixir"
	"/mnt/od-s3-openstack/test_s3_openstack"
	"/mnt/od-rados-cesnet/test_RADOS_cesnet"
)
#	"/mnt/od-posix-ceitec/test_POSIX_ceitec1"

d_tmp="/tmp/rsync-benchmark"


pull () {
	d_if="$d_od"
	d_of="$d_tmp"
}

push () {
	d_if="$d_tmp"
	d_of="${d_od}/benchmark_out"
}

sync () {
	rm -r "$d_of" || true
	mkdir "$d_of"

	rsync -av --delete --stats --progress ${d_if}/220321_ribosome/ ${d_of}/220321_ribosome
	rsync -av --delete --stats --progress ${d_if}/220321_ribosome_2GB_tars/ ${d_of}/220321_ribosome_2GB_tars
	rsync -av --delete --stats --progress ${d_if}/220321_ribosome.tar ${d_of}/220321_ribosome.tar
}


d_bench="/tmp/benchmark"
rm -r "$d_bench" || true
mkdir "$d_bench"

for d_od in "${d_od_arr[@]}"; do
	pull
	sync | tee -a "${d_bench}/log.txt"

	push
	sync | tee -a "${d_bench}/log.txt"
done

echo "cesnet"
echo "elixir"
echo "openstack"
cat "${d_bench}/log.txt" | grep "bytes/sec"

