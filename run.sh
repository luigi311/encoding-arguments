#!/usr/bin/env bash
set -e
set -o pipefail

# Source: http://mywiki.wooledge.org/BashFAQ/035
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

FLAGS="arguments"
OUTPUT="output"
INPUT="video.mkv"
CSV="stats.csv"
VMAF_WORKERS=3
THREADS=4
CPU=6
CQ=0
VBR=0
QUALITY=50
MANUAL=0

# Source: http://mywiki.wooledge.org/BashFAQ/035
while :; do
    case "$1" in
        -h | -\? | --help)
            printf "Test multiple aomenc flags simultaneously, will gather stats such as file size, duration of first pass\n"
            printf "and second pass, vmaf score and put them in a csv.\n"
            printf "\nUsage:\n"
            printf "\t ./run.sh [options]\n"
            printf "Example:\n"
            printf "\t ./run.sh --flags arguments --encworkers 12"
            printf "\nGeneral Options:\n"
            printf "\t -i/--input [\"file\"]\t\t Video source to use (default video.mkv)\n"
            printf "\t -o/--output [\"folder\"]\t\t Output folder to place all encoded videos and stats files (default output)\n"
            printf "\t -c/--csv [\"file\"]\t\t CSV file to output final stats for all encodes to (default stats.csv)\n"
            printf "\t -e/--encworkers [number]\t Number of encodes to run simultaneously (defaults cpu threads/aomenc threads)\n"
            printf "\t -v/--vmafworkers [number]\t Number of vmaf calculations to run simultaneously (defaults 3)\n"
            printf "\t --resume\t\t\t Resume option for parallel, will use encoding.log and vmaf.log \n"
            printf "\t\t\t\t\t Does not take into account different encoding settings (default false)\n"
            printf "\nEncoding Settings:\n"
            printf "\t -f/--flags [\"file\"]\t\t File with different flags to test. Each line represents\n"
            printf "\t\t\t\t\t a seperate test (default arguments)\n"
            printf "\t -t/--threads [number]\t\t Amount of aomenc threads each encode should use (default 4)\n"
            printf "\t --cq [number]\t\t\t Use q mode and set cq-level to number provided (default 50)\n"
            printf "\t --vbr [number]\t\t\t Use vbr mode and set target-bitrate to number provided\n"
            printf "\t --cpu [number]\t\t\t Set cpu-used encoding preset used by aomenc (default 6)\n"
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
        -v | --vmafworkers)
            if [ "$2" ]; then
                VMAF_WORKERS="$2"
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
                VMAF_WORKERS="$2"
                shift
            else
                die "ERROR: $1 requires a non-empty option argument."
            fi
            ;;
        --cq)
            if [ "$VBR" != 0 ]; then
                die "Can not set both VBR and CQ"
            elif [ "$2" ]; then
                QUALITY="$2"
                CQ=1
                shift
            else
                die "ERROR: $1 requires a non-empty argument."
            fi
            ;;
        --vbr)
            if [ "$CQ" != 0 ]; then
                die "Can not set both VBR and CQ"
            elif [ "$2" ]; then
                QUALITY="$2"
                VBR=1
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

if [ ! -f "$INPUT" ]; then
    die "$INPUT file does not exist"
elif [ ! -f "$FLAGS" ]; then
    die "$FLAGS file does not exist"
fi

if [ "$MANUAL" -ne 1 ]; then
  ENC_WORKERS=$(( $(nproc) / "$THREADS" ))
fi

if [ "$CQ" -ne 0 ]; then
    ENCODING="--cq $QUALITY"
elif [ "$VBR" -ne 0 ]; then
    ENCODING="--vbr $QUALITY"
else
    ENCODING="--cq $QUALITY"
fi

echo "Encoding" &&
parallel -j "$ENC_WORKERS" --joblog encoding.log $RESUME --bar scripts/encoder.sh --input "$INPUT" --output "$OUTPUT" --threads "$THREADS" --cpu "$CPU" "$ENCODING" --flags {} < "$FLAGS" &&
echo "Calculating VMAF" &&
find "$OUTPUT" -name "*.webm" | parallel -j "$VMAF_WORKERS" --joblog vmaf.log $RESUME --bar  scripts/calculate_vmaf.sh "$INPUT" {} &&
echo "Flags, Size, First Encode Time, Second Encode Time, VMAF" > "$CSV" &&
find "$OUTPUT" -name 'baseline.stats' -exec cat {} + >> "$CSV" &&
find "$OUTPUT" -name '*.stats' -not -name 'baseline.stats' -exec cat {} + >> "$CSV"
