from behave import *
import subprocess
import csv

inputFile="akiyo_cif.y4m"
arguments="arguments"
quality = "40"
baselineFlag = "baseline"
qualityMap = {"x265":["crf"],"aomenc":["q"],"svt-av1":["q"]}
csvfile="behave"

@given('I want to encode a video')
def step_impl(context):
    context.bd_rate = 0 # Default encoding without bd_rate calculations
    context.argument = f"{context.outFolder}/{arguments}"
    out = open(context.argument,"w")
    out.write(baselineFlag)

@when('I encode the video with {encoder}')
def step_impl(context, encoder):
    context.encoder = encoder
    if context.bd_rate == 1:
        extra = ["--bd", f"steps/steps_{encoder}"]
    else:
        extra = ["--quality", quality]
    cmd = ["./run.sh", "--input", f"{context.outFolder}/{inputFile}", 
        "--output", f"{context.outFolder}/{encoder}", "--enc", encoder, 
        "--flags", context.argument, "--csv", f"{context.outFolder}/{csvfile}_{encoder}.csv"]
    cmd.extend(extra)
    print(f"Command: {cmd}")

    output = subprocess.run(cmd, stdout=None, stderr=subprocess.PIPE)
    try:
        error = output.stderr.decode("ascii").split("ERROR:",1)[1]
    except IndexError:
        error = None

    print(f"Error: {error}")
    assert error is None

@then('the output file will be encoded with {expected_output}')
def step_impl(context, expected_output):
    cmd = ("ffprobe", f"{context.outFolder}/{context.encoder}/{baselineFlag}_{qualityMap[context.encoder][0]}{quality}/{baselineFlag}_{qualityMap[context.encoder][0]}{quality}.mkv", "-hide_banner")
    output = subprocess.run(cmd, stdout=None, stderr=subprocess.PIPE)
    processed_output = output.stderr.decode('ascii').split()
    video_codec = processed_output[processed_output.index('Video:')+1]
    
    print(f"Expected: {expected_output}\nGot: {video_codec}")
    assert expected_output == video_codec

@given('I want to calculate bd rate of {flag}')
def step_impl(context, flag):
    context.bd_rate = 1
    context.argument = f"{context.outFolder}/{arguments}"
    out = open(context.argument,"w")
    out.write(f"{baselineFlag}\n")
    out.write(flag)

@then('there should be a csv file with vmaf bd rate {less_greater_equal} than 0')
def step_impl(context, less_greater_equal):
    with open(f"{context.outFolder}/{csvfile}_{context.encoder}_bd_rates.csv", newline='') as f:
        bd_file = csv.reader(f)
        headers = next(bd_file, None)
        column = {}
        for h in headers:
            column[h] = []

        for row in bd_file:
            for h, v in zip(headers, row):
                column[h].append(v)
    
    vmaf = float(column["VMAF"][0])
    print(f"VMAF: {vmaf}")

    if less_greater_equal == "better":
        assert vmaf < 0
    elif less_greater_equal == "worse":
        assert vmaf > 0
    elif less_greater_equal == "same":
        assert vmaf == 0
    else:
        print("ERROR: worse_better_same must be worse, better or same")
        context.failed = True
