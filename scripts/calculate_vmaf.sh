#!/usr/bin/env bash

VMAF=$(ffmpeg -i "$1" -i "$2" -lavfi libvmaf -f null - 2>&1 | grep "VMAF score =" | awk '{ print $4 }') &&
FILE=${2%.webm} &&
echo ",$VMAF" >> "$FILE".stats
