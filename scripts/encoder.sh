#!/usr/bin/env bash

# Source: http://mywiki.wooledge.org/BashFAQ/035
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

OUTPUT="output"
INPUT="video.mkv"
THREADS=4
FLAGS="baseline"
CPU=6
CQ=""
VBR=""

# Source: http://mywiki.wooledge.org/BashFAQ/035
while :; do
    case "$1" in
        -h | -\? | --help)
            printf "Test aomenc flags will gather stats such as file size, duration of first pass\n"
            printf "and second pass and put them in a csv.\n"
            printf "\nUsage:\n"
            printf "\t ./encoder.sh [options]\n"
            printf "Example:\n"
            printf "\t ./encoder.sh --flags arguments --encworkers 12"
            printf "\nEncoding Options:\n"
            printf "\t -i/--input [\"file\"]\t\t Video source to use (default video.mkv)\n"
            printf "\t -o/--output [\"folder\"]\t\t Output folder to place encoded videos and stats files (default output)\n"
            printf "\t -f/--flags [\"string\"]\t\t Flags to test, surround in quotes to prevent issues (default baseline)\n"
            printf "\t -t/--threads [number]\t\t Amount of threads to use (default 4)\n"
            printf "\t --cq [number]\t\t\t Use q mode and set cq-level to number provided (default 50)\n"
            printf "\t --vbr [number]\t\t\t Use vbr mode and set target-bitrate to number provided\n"
            printf "\t --cpu [number]\t\t\t Set cpu-used encoding preset (default 6)\n"
            exit 0
            ;;
        -i | --input)
            if [ "$2" ]; then
                INPUT="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        -o | --output)
            if [ "$2" ]; then
                OUTPUT="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        -t | --threads)
            if [ "$2" ]; then
                THREADS="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        -f | --flags)
            if [ "$2" ]; then
                FLAGS="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --cq)
            if [ "$VBR" != "" ]; then
                die "Can not set both VBR and CQ"
            elif [ "$2" ]; then
                CQ="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --vbr)
            if [ "$CQ" != "" ]; then
                die "Can not set both VBR and CQ"
            elif [ "$2" ]; then
                VBR="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --cpu)
            if [ "$2" ]; then
                CPU="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --) # End of all options.
            shift
            break
            ;;
        -?*)
            die "Error: Unknown option : $1"
            ;;
        *) # Default case: No more options, so break out of the loop.
            break ;;
    esac
    shift
done

FOLDER=$(echo "$FLAGS" | sed ' s/--//g; s/=//g; s/ //g')
FLAGSSTAT="$FLAGS"

if [ "$CQ" != "" ]; then
    QUALITY="--end-usage=q --cq-level=$CQ"
elif [ "$VBR" != "" ]; then
    QUALITY="--end-usage=vbr --target-bitrate=$VBR"
else
    QUALITY="--end-usage=q --cq-level=50"
fi

if [ "$FLAGS" == "baseline" ]; then
    FLAGS=""
fi

mkdir -p "$OUTPUT/$FOLDER"
BASE="ffmpeg -y -hide_banner -loglevel error -i $INPUT -strict -1 -pix_fmt yuv420p10le -f yuv4mpegpipe - | aomenc --passes=2 --threads=$THREADS -b 10 --cpu-used=$CPU $QUALITY"
FIRST=$(env time --format="Sec %e" bash -c " $BASE --pass=1 $FLAGS --fpf=$OUTPUT/$FOLDER/$FOLDER.log -o /dev/null - > /dev/null 2>&1" 2>&1 | awk ' /Sec/ { print $2 }') &&
SECOND=$(env time --format="Sec %e" bash -c " $BASE --pass=2 $FLAGS --fpf=$OUTPUT/$FOLDER/$FOLDER.log -o $OUTPUT/$FOLDER/$FOLDER.webm - 2>&1" 2>&1 | awk ' /Sec/ { print $2 }') &&
rm -f "$OUTPUT/$FOLDER/$FOLDER".log &&
SIZE=$(du "$OUTPUT/$FOLDER/$FOLDER".webm | awk '{print $1}') &&
echo -n "$FLAGSSTAT,$SIZE,$FIRST,$SECOND" > "$OUTPUT/$FOLDER/$FOLDER".stats