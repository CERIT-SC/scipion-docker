#!/bin/bash

set -e

# Change dir to project workdir
cd "$(dirname "$0")"

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <tag> <image>"
    echo "Example: $0 dev controller"
    exit 1
fi

image=$2
tag=$1

# Update dictionary with available tools for the master to know what tool image should be started
rm "master-image/tool-dictionary.csv" || true
for f_bin_list in $(ls "tool2-image/bin/"); do
    for line in $(cat "tool2-image/bin/${f_bin_list}"); do
        echo "${line};${f_bin_list}" >> "master-image/tool-dictionary.csv"
    done
done

docker build --build-arg RELEASE_CHANNEL="${tag}" -t hub.cerit.io/scipion/scipion-${image}:${tag} -f "Dockerfile.${image}" .
docker push hub.cerit.io/scipion/scipion-${image}:${tag}
