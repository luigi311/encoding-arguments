#!/usr/bin/env bash

FILE=${1%.webm} &&
ffmpeg -r 60 -i "$1" -r 60 -i "$2" -filter_complex "libvmaf=psnr=1:ssim=1:ms_ssim=1:log_path=${FILE}.json:log_fmt=json" -f null - 2> /dev/null &&
VMAF=$(jq '.["VMAF score"]' "${FILE}".json) &&
PSNR=$(jq '.["PSNR score"]' "${FILE}".json) &&
SSIM=$(jq '.["SSIM score"]' "${FILE}".json) &&
MSSSIM=$(jq '.["MS-SSIM score"]' "${FILE}".json) &&
echo -n "$VMAF,$PSNR,$SSIM,$MSSSIM" >> "$FILE".stats
