#!/bin/bash

vida=$1
vidb=$2
outvid=$3

ffmpeg -i $vida -i $vidb -filter_complex "[0:v]setpts=PTS-STARTPTS, pad=iw*2:ih[bg]; [1:v]setpts=PTS-STARTPTS[fg]; [bg][fg]overlay=w" -acodec copy -vcodec libx264 -crf 17 -pix_fmt yuv420p -preset fast $outvid
