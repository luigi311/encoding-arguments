#!/usr/bin/env bash

VMAF=$(ffmpeg -i "$1" -i "$2" -lavfi libvmaf -f null - 2>&1 | grep "VMAF score =" | awk '{ print $4 }') &&
FILE=${1%.webm} &&
echo -n "$VMAF" >> "$FILE".stats
