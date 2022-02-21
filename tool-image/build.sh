#!/bin/bash

set -e

cd "$(dirname "$0")"

if [ "$1" != "--nobase" ]; then
	../base-image/build.sh
fi

for file in $(ls build-*.sh); do
	./$file &
done

wait
