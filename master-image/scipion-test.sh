#!/bin/bash

mkdir logs || exit 1

cat scipion-test-list.txt | while read line; do
	log_file=$(echo "$line" | awk {'print $3'})
	out=$(eval "$line 2>&1")
	ret=$?
	if [ "$ret" == "0" ]; then
		echo "$out" | tee "logs/OK-$log_file.txt"
	else
		echo "$out" | tee "logs/FF-$log_file.txt"
	fi
done

