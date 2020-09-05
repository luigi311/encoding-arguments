#!/usr/bin/env bash

# Source: http://mywiki.wooledge.org/BashFAQ/035
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

help() {
    help="$(cat <<EOF
Test multiple encoding flags simultaneously, will gather stats such as file size, duration of first pass and second pass,
    visual metric scores and put them in a csv. Optionally can calulate bd_rate with that csv for all flags
Usage:
    ./run.sh [options]
Example:
    ./run.sh --flags arguments.aomenc --encworkers 12
General Options:
    -h/--help                       Print this help screen
    -i/--input          [file]      Video source to use                                             (default video.mkv)
    -o/--output         [folder]    Output folder to place all encoded videos and stats files       (default output)
    --bd                [file]      File that contains different qualities to test for bd_rate
    -c/--csv            [file]      CSV file to output final stats for all encodes to               (default stats.csv)
    -e/--encworkers     [number]    Number of encodes to run simultaneously                         (defaults aom threads/encoding threads, x265 threads/2)
    -m/--metricworkers  [number]    Number of vmaf calculations to run simultaneously               (defaults 1)
    --resume                        Resume option for parallel, will use encoding.log and vmaf.log  (default false)
Encoding Settings:
    --enc               [string]    Encoder to test, supports aomenc and x265                       (default aomenc)
    -f/--flags          [file]      File with different flags to test. Each line is a seperate test (default arguments.aomenc)
    -t/--threads        [number]    Amount of aomenc threads each encode should use                 (default 4)
    --quality           [number]    Bitrate for vbr, cq-level for q/cq mode, crf level for crf      (default 50)
    --preset            [number]    Set cpu-used/preset used by encoder                             (default 6)
    --pass              [number]    Set amount of passes for encoder
    --q                             Use q mode   (applies to aomenc only)                           (default for aomenc)
    --cq                            Use cq mode  (applies to aomenc only)
    --vbr                           Use vbr mode (applies to aomenc/x265 only)
    --crf                           Use crf mode (applies to x265 only)                             (default for x265)
    --decode                        Test decoding speed
EOF
)"
    echo "$help"
}

FLAGS=-1
OUTPUT="output"
INPUT="video.mkv"
CSV="stats.csv"
METRIC_WORKERS=1
THREADS=-1
Q=-1
CQ=-1
VBR=-1
CRF=-1
QUALITY=-1
MANUAL=0
BD=-1
ENCODER="aomenc"
SUPPORTED_ENCODERS="aomenc:x265:svt-av1"

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
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        -o | --output)
            if [ "$2" ]; then
                OUTPUT="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
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
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        -c | --csv)
            if [ "$2" ]; then
                CSV="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        -e | --encworkers)
            if [ "$2" ]; then
                ENC_WORKERS="$2"
                MANUAL=1
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        -m | --metricworkers)
            if [ "$2" ]; then
                METRIC_WORKERS="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        --resume)
            RESUME="--resume"
            ;;
        -f | --flags)
            if [ "$2" ]; then
                FLAGS="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        -t | --threads)
            if [ "$2" ]; then
                THREADS="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
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
            if [ "$BD" -ne -1 ]; then
                die "Can not set both BD and quality"
            elif [ "$2" ]; then
                QUALITY="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        --bd)
            if [ "$QUALITY" -ne -1 ]; then
                die "Can not set both BD and quality"
            elif [ "$2" ]; then
                BD=1
                BD_FILE="$2"
                if [ ! -f "$BD_FILE" ]; then
                    die "$BD_FILE file does not exist"
                fi
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        --preset)
            if [ "$2" ]; then
                PRESET="--preset $2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --pass)
            if [ "$2" ]; then
                PASS="--pass $2"
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --decode)
            DECODE="--decode"
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

if [ "$THREADS" -eq -1 ]; then
    if [ "$ENCODER" == "aomenc" ]; then
        THREADS=$(( 4 < $(nproc) ? 4 : $(nproc) ))
    elif [ "$ENCODER" == "svt-av1" ]; then
        THREADS=$(( 18 < $(nproc) ? 18 : $(nproc) ))
    elif [ "$ENCODER" == "x265" ]; then
        THREADS=$(( 32 < $(nproc) ? 32 : $(nproc) ))
    fi
fi

# Set job amounts for encoding
if [ "$MANUAL" -ne 1 ]; then
    ENC_WORKERS=$(( ($(nproc) / "$THREADS") ))
fi

# Set encoding settings
if [ "$Q" -ne -1 ]; then
    if [ "$ENCODER" == "aomenc" ]; then
        ENCODING="--q"
    else
        die "q is not supported by $ENCODER"
    fi
elif [ "$CQ" -ne -1 ]; then
    if [ "$ENCODER" == "aomenc" ] || [ "$ENCODER" == "svt-av1" ]; then
        ENCODING="--cq"
    else
        die "cq is not supported by $ENCODER"
    fi
elif [ "$VBR" -ne -1 ]; then
    if [ "$ENCODER" == "aomenc" ] || [ "$ENCODER" == "svt-av1" ] || [ "$ENCODER" == "x265" ]; then
        ENCODING="--vbr"
    else
        die "vbr is not supported by $ENCODER"
    fi
elif [ "$CRF" -ne -1 ]; then
    if [ "$ENCODER" == "x265" ]; then
        ENCODING="--crf"
    else
        die "crf is not supported by $ENCODER"
    fi
else
    if [ "$ENCODER" == "aomenc" ]; then
        ENCODING="--q"
    elif [ "$ENCODER" == "x265" ]; then
        ENCODING="--crf"
    elif [ "$ENCODER" == "svt-av1" ]; then
        ENCODING="--cq"
    fi
fi

# Default quality setting if not manually set
if [ "$QUALITY" == -1 ]; then
    QUALITY=45
fi

if [ "$FLAGS" == -1 ]; then
    if [ "$ENCODER" == "aomenc" ]; then
        FLAGS="arguments.aomenc"
    elif [ "$ENCODER" == "svt-av1" ]; then
        FLAGS="arguments.svt-av1"
    elif [ "$ENCODER" == "x265" ]; then
        FLAGS="arguments.x265"
    fi
fi

# Check if files exist
if [ ! -f "$INPUT" ]; then
    die "$INPUT file does not exist"
elif [ ! -f "$FLAGS" ]; then
    die "$FLAGS file does not exist"
fi

# Run encoding scripts
if [ "$BD" -eq -1 ]; then
    parallel -j "$ENC_WORKERS" --joblog encoding.log $RESUME --bar -a "$FLAGS" "scripts/${ENCODER}.sh" --input "$INPUT" --output "$OUTPUT" --threads "$THREADS" "$ENCODING" --quality "$QUALITY" --flag "{1}" "$PRESET" "$PASS" "$DECODE"
else
    parallel -j "$ENC_WORKERS" --joblog encoding.log $RESUME --bar -a "$BD_FILE" -a "$FLAGS" "scripts/${ENCODER}.sh" --input "$INPUT" --output "$OUTPUT" --threads "$THREADS" "$ENCODING" --quality "{1}" --flag "{2}" "$PRESET" "$PASS" "$DECODE"
fi

echo "Calculating Metrics" &&
find "$OUTPUT" -name "*.mkv" | parallel -j "$METRIC_WORKERS" --joblog metrics.log $RESUME --bar scripts/calculate_metrics.sh {} "$INPUT"

echo "Creating CSV" &&
echo "Flags, Size, Quality, Bitrate, First Encode Time, Second Encode Time, Decode Time, VMAF, PSNR, SSIM, MSSSIM" > "$CSV" &&
find "$OUTPUT" -name 'baseline*.stats' -exec awk '{print $0}' {} + >> "$CSV" &&
find "$OUTPUT" -name '*.stats' -not -name 'baseline*.stats' -exec awk '{print $0}' {} + >> "$CSV"

if [ "$BD" -ne -1 ]; then
    scripts/bd_features.py --input "$CSV" --output "${CSV%.csv}_bd_rates.csv"
fi
