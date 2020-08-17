# aomenc-arguments

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9d73582417664408a6f0488555c6f063)](https://www.codacy.com/manual/luigi311/aomenc-arguments?utm_source=gitlab.com&utm_medium=referral&utm_content=Luigi311/aomenc-arguments&utm_campaign=Badge_Grade)  
Utilize gnu parallel to test multiple aomenc flags simultaneously, will gather stats such as file size, duration of first pass
and second pass, visual metric scores and put them in a csv.

## Usage

```bash
./run.sh [options]
```

## Example

```bash
./run.sh --flags arguments --encworkers 12
```

For bd_rate calculations you need to utilize the bd flag
```bash
./run.sh --flags arguments --encworkers 12 --bd steps
```

## Options

```bash
General Options:

         -i/--input ["file"]             Video source to use (default video.mkv)
         -o/--output ["folder"]          Output folder to place all encoded videos and stats files (default output)   
         --bd ["file"]                   Steps file that contains different quality settings to test bd_rate with   
         -c/--csv ["file"]               CSV file to output final stats for all encodes to (default stats.csv)        
         -e/--encworkers [number]        Number of encodes to run simultaneously (defaults cpu threads/aomenc threads)
         -v/--vmafworkers [number]       Number of vmaf calculations to run simultaneously (defaults 3)
         --resume                        Resume option for parallel, will use encoding.log and vmaf.log 
                                         Does not take into account different encoding settings (default false)       

Encoding Settings:
         -f/--flags ["file"]             File with different flags to test. Each line represents
                                         a seperate test (default arguments)
         -t/--threads [number]           Amount of aomenc threads each encode should use (default 4)
         --q [number]                   Use q mode and set cq-level to number provided (default 50)
         --cq [number]                   Use cq mode and set cq-level to number provided, currently disabled
         --vbr [number]                  Use vbr mode and set target-bitrate to number provided
         --cpu [number]                  Set cpu-used encoding preset used by aomenc (default 6)
```

## Format for arguments

Each test will run consist of one line of the arguments file provided. Insert flags as you would in aomenc in the agument file such as 

```bash
--aq-mode=3
```

If you want to test multiple flags on a single encode put them all in a single line like so

```bash
--bias-pct=0 --tune-content=screen --aq-mode=3
```

## Requirements

The following packages are required

-   aomenc
-   parallel
-   time
-   awk
-   grep
-   python
