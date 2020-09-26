#!/usr/bin/env bash
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

FILE=${1%.mkv} &&
LOG=$(ffmpeg -hide_banner -loglevel error -r 60 -i "$1" -r 60 -i "$2" -filter_complex "[0:v]scale=-1:1080:flags=bicubic[distorted];[1:v]scale=-1:1080:flags=bicubic[reference];[distorted][reference]libvmaf=psnr=1:ssim=1:ms_ssim=1:log_path=${FILE}.json:log_fmt=json" -f null - 2>&1)

if [ -n "$LOG" ]; then
    rm -f "$FILE".*
    die "$LOG"
fi

VMAF=$(jq '.["VMAF score"]' "${FILE}".json) &&
PSNR=$(jq '.["PSNR score"]' "${FILE}".json) &&
SSIM=$(jq '.["SSIM score"]' "${FILE}".json) &&
MSSSIM=$(jq '.["MS-SSIM score"]' "${FILE}".json)
echo -n "$VMAF,$PSNR,$SSIM,$MSSSIM" >> "$FILE.stats"
