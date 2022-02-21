#!/bin/bash

set -e

../base-image/build.sh

for file in $(ls build-*.sh); do
	./${file}
done
