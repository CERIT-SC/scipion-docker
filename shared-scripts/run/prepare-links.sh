#!/bin/bash

set -e

dir_dataset="/mnt/vol-dataset"
dir_project="/mnt/vol-project"
ln -s "${dir_dataset}/" "${S_USER_HOME}/ScipionUserData/dataset"
ln -s "${dir_project}/" "${S_USER_HOME}/ScipionUserData/projects"
# ^ this should be the only occurence of the word "projects" (plural) instead of "project". Scipion requires this directory
