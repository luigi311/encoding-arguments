#!/usr/bin/env bash

VMAF=$(vmaf.sh short.mkv "$1" 2>&1 | grep "VMAF score =" | awk '{ print $4 }') &&
FILE=${1%.mkv} &&
echo ",$VMAF" >> "$FILE".stats
