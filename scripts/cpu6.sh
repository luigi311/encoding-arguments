#!/usr/bin/env bash

mkdir -p "$3/$1"
BASE1P="ffmpeg -y -hide_banner -loglevel error -i short.mkv -strict -1 -pix_fmt yuv420p10le -f yuv4mpegpipe - | aomenc --passes=2 --pass=1 --threads=4 -b 10 --cpu-used=6 --end-usage=vbr --target-bitrate=250"
BASE2P="ffmpeg -y -hide_banner -loglevel error -i short.mkv -strict -1 -pix_fmt yuv420p10le -f yuv4mpegpipe - | aomenc --passes=2 --pass=2 --threads=4 -b 10 --cpu-used=6 --end-usage=vbr --target-bitrate=250"

if [[ $1 = "baseline" ]]; then
    FIRST=$(env time --format="%e" bash -c " $BASE1P --fpf=$3/$1/$1.log -o /dev/null - > /dev/null 2>&1" 2>&1 | awk '{ print $1 }') &&
    SECOND=$(env time --format="%e" bash -c " $BASE2P --fpf=$3/$1/$1.log -o $3/$1/$1.mkv - 2>&1" 2>&1 | awk '{ print $1 }') &&
    rm -f "$3/$1/$1".log &&
    SIZE=$(du "$3/$1/$1".mkv | awk '{print $1}') &&
    echo -n "baseline,$SIZE,$FIRST,$SECOND" > "$3/$1/$1".stats
else
    echo "Main"
    FIRST=$(env time --format="%e" bash -c " $BASE1P --$1=$2 --fpf=$3/$1/$1$2.log -o /dev/null - 2>&1" 2>&1 | awk '{ print $1 }') &&
    SECOND=$(env time --format="%e" bash -c " $BASE2P --$1=$2 --fpf=$3/$1/$1$2.log -o $3/$1/$1$2.mkv - 2>&1" 2>&1 | awk '{ print $1 }') &&
    rm -f "$3/$1/$1$2".log &&
    SIZE=$(du "$3/$1/$1$2".mkv | awk '{print $1}') &&
    echo -n "$1=$2,$SIZE,$FIRST,$SECOND" > "$3/$1/$1$2".stats
fi
