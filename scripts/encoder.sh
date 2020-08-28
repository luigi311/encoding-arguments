#!/usr/bin/env bash

# Source: http://mywiki.wooledge.org/BashFAQ/035
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

help() {
    help="$(cat <<EOF
Test encoding flag, will gather stats such as file size, duration of first pass and second pass and put them in a csv.
Usage: 
    ./encoder.sh [options]
Example:
    ./encoder.sh -i video.mkv -f "--kf-max-dist=360 --enable-keyframe-filtering=0" -t 8 --q --quality 30 
Encoding Options:
    -i/--input   [file]     Video source to use                                                 (default video.mkv)
    -o/--output  [folder]   Output folder to place encoded videos and stats files               (default output)
    -f/--flag    [string]   Flag to test, surround in quotes to prevent issues                  (default baseline)
    -t/--threads [number]   Amount of threads to use                                            (default 4)
    --q                     Use q mode   (applies to aomenc only)                               (default for aomenc)
    --cq                    Use cq mode  (applies to aomenc only)
    --vbr                   Use vbr mode (applies to aomenc/x265 only)
    --crf                   Use crf mode (applies to x265 only)                                 (default for x265)
    --quality    [number]   Bitrate for vbr, cq-level for q/cq mode, crf                        (default 50)
    --preset     [number]   Set encoding preset, aomenc higher is faster, x265 lower is faster  (default 6)
EOF
            )"
            echo "$help"
}

OUTPUT="output"
INPUT="video.mkv"
THREADS=4
FLAG="baseline"
PRESET=6
Q=-1
CQ=-1
VBR=-1
CRF=-1
QUALITY=50
ENCODER="aomenc"
SUPPORTED_ENCODERS="aomenc:x265"

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
        --q)
            if [ "$VBR" -ne -1 ] || [ "$CQ" -ne -1 ] || [ "$CRF" -ne -1 ]; then
                die "Can not set VBR, CQ, q and CRF at the same time"
            fi
            Q=1
            ;;
        --cq)
            if [ "$VBR" -ne -1 ] || [ "$Q" -ne -1 ] || [ "$CRF" -ne -1 ]; then
                die "Can not set VBR, CQ, q and CRF at the same time"
            fi
            die "CQ is not properly setup"
            CQ=1
            ;;
        --vbr)
            if [ "$Q" -ne -1 ] || [ "$CQ" -ne -1 ] || [ "$CRF" -ne -1 ]; then
                die "Can not set VBR, CQ, q and CRF at the same time"
            fi
            VBR=1
            ;;
        --crf)
            if [ "$VBR" -ne -1 ] || [ "$Q" -ne -1 ] || [ "$CQ" -ne -1 ]; then
                die "Can not set VBR, CQ, q and CRF at the same time"
            fi
            CRF=1
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
        --enc)
            if [ "$2" ]; then
                ENCODER="$2"
                # https://stackoverflow.com/questions/8063228/how-do-i-check-if-a-variable-exists-in-a-list-in-bash#comment91727359_46564084
                if [[ ":$SUPPORTED_ENCODERS:" != *:$ENCODER:* ]]; then
                    die "$2 not supported"
                fi
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

# Baseline is with no flag, x265 requires a : due to x265 parms used during base encoder
if [ "$FLAG" == "baseline" ]; then
    FLAG=""
elif [ "$ENCODER" == "x265" ]; then
    FLAG=":${FLAG}"
fi

# Set the encoding mode of q/cq/vbr/crf along with a default
if [ "$Q" -ne -1 ]; then
    TYPE="q${QUALITY}"
    if [ "$ENCODER" == "aomenc" ]; then
        QUALITY_SETTINGS="--end-usage=q --cq-level=${QUALITY}"
    elif [ "$ENCODER" == "x265" ]; then
        die "Q is not a valid x265 encoding setting"
    fi
elif [ "$CQ" -ne -1 ]; then
    TYPE="cq${QUALITY}"
    if [ "$ENCODER" == "aomenc" ]; then
        QUALITY_SETTINGS="--end-usage=cq --cq-level=${QUALITY}"
    elif [ "$ENCODER" == "x265" ]; then
        die "CQ is not a valid x265 encoding setting"
    fi
elif [ "$VBR" -ne -1 ]; then
    TYPE="vbr${QUALITY}"
    if [ "$ENCODER" == "aomenc" ]; then
        QUALITY_SETTINGS="--end-usage=vbr --target-bitrate=${QUALITY}"
    elif [ "$ENCODER" == "x265" ]; then
        QUALITY_SETTINGS="-b:v ${QUALITY}"
    fi
elif [ "$CRF" -ne -1 ]; then
    if [ "$ENCODER" == "x265" ]; then
        TYPE="crf${QUALITY}"
        QUALITY_SETTINGS="-crf ${QUALITY}"
    else
        die "crf is only supported by x265"
    fi
else
    if [ "$ENCODER" == "aomenc" ]; then
        TYPE="q${QUALITY}"
        QUALITY_SETTINGS="--end-usage=q --cq-level=${QUALITY}"
    elif [ "$ENCODER" == "x265" ]; then
        TYPE="crf${QUALITY}"
        QUALITY_SETTINGS="-crf ${QUALITY}"
    fi
fi

mkdir -p "$OUTPUT/${FOLDER}_${TYPE}"
FFMPEGBASE="ffmpeg -y -hide_banner -loglevel error -i $INPUT -strict -1 -pix_fmt yuv420p10le"
if [ "$ENCODER" == "aomenc" ]; then
    FIRST=$(env time --format="Sec %e" bash -c " $FFMPEGBASE -f yuv4mpegpipe - | aomenc --passes=2 --threads=$THREADS -b 10 --cpu-used=$PRESET $QUALITY_SETTINGS $FLAG --fpf=$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.log --pass=1 -o /dev/null - > /dev/null 2>&1" 2>&1 | awk ' /Sec/ { print $2 }') &&
    SECOND=$(env time --format="Sec %e" bash -c " $FFMPEGBASE -f yuv4mpegpipe - | aomenc --passes=2 --threads=$THREADS -b 10 --cpu-used=$PRESET $QUALITY_SETTINGS $FLAG --fpf=$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.log --pass=2 -o $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.webm - 2>&1" 2>&1 | awk ' /Sec/ { print $2 }')
    ffmpeg -i $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.webm -c:v copy $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.mkv
elif [ "$ENCODER" == "x265" ]; then
    if [ "$CRF" -ne -1 ]; then
        FIRST=$(env time --format="Sec %e" bash -c " $FFMPEGBASE -c:v libx265 $QUALITY_SETTINGS -preset $PRESET -x265-params \"frame-threads=1${FLAG}\" $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.mkv " 2>&1 | awk ' /Sec/ { print $2 }')
        SECOND=0
    elif [ "$VBR" -ne -1 ]; then
        FIRST=$(env time --format="Sec %e" bash -c " $FFMPEGBASE -c:v libx265 $QUALITY_SETTINGS -preset $PRESET -x265-params \"frame-threads=1:pass=1:stats=\"$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.log\"${FLAG}\" -an -f null /dev/null " 2>&1 | awk ' /Sec/ { print $2 }')
        SECOND=$(env time --format="Sec %e" bash -c " $FFMPEGBASE -c:v libx265 $QUALITY_SETTINGS -preset $PRESET -x265-params \"frame-threads=1:pass=2:stats=\"$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.log\"${FLAG}\" $OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE.mkv " 2>&1 | awk ' /Sec/ { print $2 }')
    fi
else
    die "Unsupported encoder $ENCODER"
fi

rm -f "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE".log* &&
rm -f "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE".webm &&
SIZE=$(du "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE".mkv | awk '{print $1}') &&
BITRATE=$(ffprobe -i "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE".mkv 2>&1 | awk ' /bitrate:/ { print $(NF-1) }')
echo -n "$FLAGSSTAT,$SIZE,$TYPE,$BITRATE,$FIRST,$SECOND," > "$OUTPUT/${FOLDER}_$TYPE/${FOLDER}_$TYPE".stats
