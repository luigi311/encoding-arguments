#!/usr/bin/env bash

# Source: http://mywiki.wooledge.org/BashFAQ/035
die() {
    printf '%s\n' "$1" >&2
    #exit 1
}

N_THREADS=-1

if [ "$N_THREADS" -eq -1 ]; then
    N_THREADS=$(( 8 < $(nproc) ? 8 : $(nproc) ))
fi

FILE=${1%.mkv} &&
LOG=$(ffmpeg -hide_banner -loglevel error -r 60 -i "$1" -r 60 -i "$2" -filter_complex "libvmaf=log_path=${FILE}.json:log_fmt=json:n_threads=${N_THREADS}" -f null - 2>&1)

if [ -n "$LOG" ]; then
    die "$LOG"
fi

VMAF=$(jq '.["pooled_metrics"]["vmaf"]["mean"]' "${FILE}".json)

echo -n "$VMAF" >> "$FILE.stats"
