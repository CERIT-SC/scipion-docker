#!/bin/bash

tag=${tag:-dev}

set -e

cd "$(dirname "$0")"

export tag "$tag"

controller-image/build.sh
firefox-image/build.sh

rm "master-image/tool-dictionary.csv" || true
for f_bin_list in $(ls "tool2-image/bin/"); do
    for line in $(cat "tool2-image/bin/${f_bin_list}"); do
        echo "${line};${f_bin_list}" >> "master-image/tool-dictionary.csv"
    done
done

base-image/build.sh
master-image/build.sh
vnc-image/build.sh

tool-image/build.sh

wait
