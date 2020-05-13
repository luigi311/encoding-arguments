#!/usr/bin/env bash

FOLDER="output"

echo "Encoding" &&
parallel -j 14 --joblog encoding.log --bar "$1" --colsep ' ' scripts/cpu6.sh "{1}" "{2}" "$FOLDER" <arguments &&
echo "Calculating VMAF" &&
find "$FOLDER" -name "*.mkv" | parallel -j 3 --joblog vmaf.log "$1" --bar "$1" scripts/calculate_vmaf.sh {} &&
cat "$FOLDER"/*/*.stats > stats.csv
