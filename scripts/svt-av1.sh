#!/usr/bin/env bash

# Source: http://mywiki.wooledge.org/BashFAQ/035
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

help() {
    help="$(cat <<EOF
Test svt-av1 flag, will gather stats such as file size, duration of first pass and second pass and put them in a csv.
Usage: 
    ./encoder_svt-av1.sh [options]
Example:
    ./encoder_svt-av1.sh -i video.mkv -f "--kf-max-dist=360 --enable-keyframe-filtering=0" -t 8 --q --quality 30 
Encoding Options:
    -i/--input   [file]     Video source to use                                                 (default video.mkv)
    -o/--output  [folder]   Output folder to place encoded videos and stats files               (default output)
    -f/--flag    [string]   Flag to test, surround in quotes to prevent issues                  (default baseline)
    -t/--threads [number]   Amount of threads to use                                            (default 4)
    --quality    [number]   Bitrate for vbr, cq-level for q/cq mode, crf                        (default 50)
    --preset     [number]   Set encoding preset, higher is faster                               (default 6)
    --pass       [number]   Set amount of passes                                                (default 1)
    --cq                    Use cq mode                                                         (default)
    --vbr                   Use vbr mode
    --decode                Test decoding speed
EOF
            )"
            echo "$help"
}

OUTPUT="output"
INPUT="video.mkv"
FLAG="baseline"
THREADS=-1
PRESET=8
CQ=-1
VBR=-1
QUALITY=40
PASS=1
DECODE=-1

# Source: http://mywiki.wooledge.org/BashFAQ/035
while :; do
    case "$1" in
        -h | -\? | --help)
            help
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
        -f | --flag)
            if [ "$2" ]; then
                FLAG="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --cq)
            if [ "$VBR" -ne -1 ]; then
                die "Can not set VBR and CQ at the same time"
            fi
            CQ=1
            ;;
        --vbr)
            if [ "$CQ" -ne -1 ]; then
                die "Can not set VBR and CQ at the same time"
            fi
            VBR=1
            ;;
        --quality)
            if [ "$2" ]; then
                QUALITY="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --preset)
            if [ "$2" ]; then
                PRESET="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --pass)
            if [ "$2" ]; then
                PASS="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --decode)
            DECODE=1
            ;;
        --) # End of all options.
            shift
            break
            ;;
        -?*)
            echo "Unknown option: $1 ignored"
            ;;
        *) # Default case: No more options, so break out of the loop.
            break ;;
    esac
    shift
done

if [ "$THREADS" -eq -1 ]; then
    THREADS=$(( 18 < $(nproc) ? 18 : $(nproc) ))
fi

# Original Flags used for CSV
FLAGSSTAT="$FLAG"
# Remove any potential characters that might cause issues in folder names
FOLDER1=$(echo "$FLAG" | sed ' s/--//g; s/=//g; s/ //g; s/:/_/g')
# Get last 120 characters of flags for folder name to prevent length issues
if [ "${#FOLDER1}" -ge 120 ]; then
    FOLDER=${FOLDER1: -120}
else
    FOLDER="$FOLDER1"
fi

# Baseline is with no flag
if [ "$FLAG" == "baseline" ]; then
    FLAG=""
fi

# Set the encoding mode of cq/vbr along with a default
if [ "$CQ" -ne -1 ]; then
    TYPE="cq${QUALITY}"
    QUALITY_SETTINGS="--rc 0 -q ${QUALITY}"
elif [ "$VBR" -ne -1 ]; then
    TYPE="vbr${QUALITY}"
    QUALITY_SETTINGS="--rc 1 --tbr ${QUALITY}"
else
    TYPE="cq${QUALITY}"
    QUALITY_SETTINGS="--rc 0 -q ${QUALITY}"
fi

mkdir -p "$OUTPUT/${FOLDER}_${TYPE}"
BASE="ffmpeg -y -hide_banner -loglevel error -i $INPUT -strict -1 -pix_fmt yuv420p10le -f yuv4mpegpipe - | SvtAv1EncApp -i stdin --preset $PRESET --irefresh-type 2 --lp $THREADS $QUALITY_SETTINGS"
if [ "$PASS" == 1 ]; then
    FIRST_TIME=$(env time --format="Sec %e" bash -c " $BASE -b $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.ivf 2>&1" 2>&1 | awk ' /Sec/ { print $2 }') &&
    SECOND_TIME=0
elif [ "$PASS" == 2 ]; then
    FIRST_TIME=$(env time --format="Sec %e" bash -c " $BASE --pass 1 --stats $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.log $FLAG 2>&1" 2>&1 | awk ' /Sec/ { print $2 }') &&
    SECOND_TIME=$(env time --format="Sec %e" bash -c " $BASE --pass 2 --stats $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.log $FLAG -b $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.ivf 2>&1" 2>&1 | awk ' /Sec/ { print $2 }')
else
    die "Pass $PASS unsupported"
fi

ERROR=$(ffmpeg -y -hide_banner -loglevel error -i "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.ivf" -c:v copy "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.mkv" 2>&1)
if [ -n "$ERROR" ]; then
    rm -rf "$OUTPUT/${FOLDER}_$TYPE"
    die "$FLAG failed"
fi

if [ "$DECODE" -ne -1 ]; then
    DECODE_TIME=$(env time --format="Sec %e" bash -c " dav1d -i $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.ivf -o /dev/null" 2>&1 | awk ' /Sec/ { print $2 }')
else
    DECODE_TIME=0
fi

rm -f "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.log" &&
rm -f "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.ivf" &&
SIZE=$(du "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.mkv" | awk '{print $1}') &&
BITRATE=$(ffprobe -i "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.mkv" 2>&1 | awk ' /bitrate:/ { print $(NF-1) }')
echo -n "$FLAGSSTAT,$SIZE,$TYPE,$BITRATE,$FIRST_TIME,$SECOND_TIME,$DECODE_TIME," > "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.stats"
