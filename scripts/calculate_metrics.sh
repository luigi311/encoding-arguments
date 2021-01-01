#!/usr/bin/env bash

FILE=${1%.mkv} &&
LOG=$(ffmpeg -hide_banner -loglevel error -r 60 -i "$1" -r 60 -i "$2" -filter_complex "libvmaf=psnr=1:ssim=1:ms_ssim=1:log_path=${FILE}.json:log_fmt=json" -f null - 2>&1)

if [ -n "$LOG" ]; then
    printf '%s\n' "$LOG"
fi

VMAF=$(jq '.["VMAF score"]' "${FILE}".json) &&
PSNR=$(jq '.["PSNR score"]' "${FILE}".json) &&
SSIM=$(jq '.["SSIM score"]' "${FILE}".json) &&
MSSSIM=$(jq '.["MS-SSIM score"]' "${FILE}".json)
echo -n "$VMAF,$PSNR,$SSIM,$MSSSIM" >> "$FILE.stats"
