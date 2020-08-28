# encoding-arguments

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9d73582417664408a6f0488555c6f063)](https://www.codacy.com/manual/luigi311/aomenc-arguments?utm_source=gitlab.com&utm_medium=referral&utm_content=Luigi311/aomenc-arguments&utm_campaign=Badge_Grade)  
Test multiple encoding flags simultaneously, will gather stats such as file size, duration of first pass and second pass,
visual metric scores and put them in a csv. Optionally can calulate bd_rate with that csv for all flags

## Usage

```bash
./run.sh [options]
```

## Example

```bash
./run.sh --flags arguments.aomenc --encworkers 12
```

For bd_rate calculations you need to utilize the bd flag
```bash
./run.sh --flags arguments.aomenc --encworkers 12 --bd steps
```

## Options

```bash
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
    --q                             Use q mode   (applies to aomenc only)                           (default for aomenc)
    --cq                            Use cq mode  (applies to aomenc only)
    --vbr                           Use vbr mode (applies to aomenc/x265 only)
    --crf                           Use crf mode (applies to x265 only)                             (default for x265)
    --quality           [number]    Bitrate for vbr, cq-level for q/cq mode, crf level for crf      (default 50)
    --preset            [number]    Set cpu-used/preset used by encoder                             (default 6)
```

## Format for arguments

Each test will run consist of one line of the arguments file provided. Insert flags as you would in aomenc in the agument file such as 

```bash
--aq-mode=3
```

If you want to test multiple flags on a single encode put them all in a single line like so
aomenc:
```bash
--bias-pct=0 --tune-content=screen --aq-mode=3
```

x265:
```bash
aq-mode=1:aq-strength=0
```

## Requirements

The following packages are required

-   aomenc
-   parallel
-   time
-   awk
-   grep
-   ffmpeg
-   python
