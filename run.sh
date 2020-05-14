#!/usr/bin/env bash

FOLDER="output"

echo "Encoding" &&
cat arguments | parallel -j 14 --joblog encoding.log --bar --colsep ' ' "$1" scripts/cpu6.sh "{1}" "{2}" "$FOLDER" &&
echo "Calculating VMAF" &&
find "$FOLDER" -name "*.mkv" | parallel -j 3 --joblog vmaf.log --bar "$1" scripts/calculate_vmaf.sh {} &&
cat "$FOLDER"/*/*.stats > stats.csv
