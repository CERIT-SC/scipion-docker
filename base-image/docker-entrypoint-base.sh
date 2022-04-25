#!/bin/bash

dir_source="/mnt/vol-source"
dir_project="/mnt/vol-project"

test_mountpoint () {
	if [ "1" != $(ls "$1" | wc -l) ]; then
		echo "There is more or less spaces than one in the \"${1}\""
		echo "The instance cannot be started"
		exit 1
	fi
}

test_mountpoint "$dir_source"
test_mountpoint "$dir_project"

ln -s "${dir_source}/*" "${S_USER_HOME}/ScipionUserData/source"
ln -s "${dir_project}/*" "${S_USER_HOME}/ScipionUserData/projects" # this should be the only occurence of the word "projects" (plural) instead of "project". Scipion requires this directory
