from behave import *
from urllib.request import urlretrieve
from pathlib import Path
import os
import shutil
import tarfile

outFolder="BehaveTesting"
videoDownload="https://raw.githubusercontent.com/OpenVisualCloud/SVT-AV1-Resources/master/video.tar.gz"


def startup(context):
    Path(context.outFolder).mkdir(parents=True, exist_ok=True)
    urlretrieve(videoDownload, f"{context.outFolder}/video.tar.gz")
    tar = tarfile.open('video.tar.gz')
    tar.extractall(context.outFolder)
    tar.close()
    
def cleanup(folder):
    dirpath = folder
    if os.path.exists(dirpath) and os.path.isdir(dirpath):
        shutil.rmtree(dirpath)

def before_all(context):
    context.outFolder = outFolder
    startup(context)

def after_scenario(context, scenario):
    cleanup(f"{context.outFolder}/{context.encoder}")

def after_all(context):
    context.add_cleanup(cleanup, context.outFolder)