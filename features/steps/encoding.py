from behave import *
import subprocess

inputFile="akiyo_cif.y4m"
tempArguments="argument.temp"
quality = "40"
defaultFlag = "baseline"
qualityMap = {"x265":["crf"],"aomenc":["q"],"svt-av1":["q"]}

@Given('I want to encode a video')
def step_impl(context):
    context.argument = f"{context.outFolder}/tempArguments"
    out = open(context.argument,"w")
    out.write(defaultFlag)

@When('I encode the video with {encoder}')
def step_impl(context, encoder):
    context.encoder = encoder
    cmd = ("./run.sh", "--input", f"{context.outFolder}/{inputFile}", "--output", f"{context.outFolder}/{encoder}", "--enc", encoder, "--flags", context.argument, "--quality", quality)
    output = subprocess.run(cmd, stdout=None, stderr=subprocess.PIPE)
    try:
        error = output.stderr.decode("ascii").split("ERROR:",1)[1]
    except IndexError:
        error = None
    print(error)

    assert error is None

@Then('the output file will be encoded with {expected_output}')
def step_impl(context, expected_output):
    cmd = ("ffprobe", f"{context.outFolder}/{context.encoder}/{defaultFlag}_{qualityMap[context.encoder][0]}{quality}/{defaultFlag}_{qualityMap[context.encoder][0]}{quality}.mkv", "-hide_banner")
    output = subprocess.run(cmd, stdout=None, stderr=subprocess.PIPE)
    processed_output = output.stderr.decode('ascii').split()
    video_codec = processed_output[processed_output.index('Video:')+1]
    print(f"Expected: {expected_output}\nGot: {video_codec}")
    assert expected_output == video_codec
