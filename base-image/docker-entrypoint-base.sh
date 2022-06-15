#!/bin/bash

dir_source="/mnt/vol-source"
dir_project="/mnt/vol-project"

ln -s "${dir_source}/" "${S_USER_HOME}/ScipionUserData/source"
ln -s "${dir_project}/" "${S_USER_HOME}/ScipionUserData/projects" # this should be the only occurence of the word "projects" (plural) instead of "project". Scipion requires this directory
