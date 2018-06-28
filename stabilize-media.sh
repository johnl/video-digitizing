#!/bin/bash

mkdir -p tmp
mkdir -p backup
mkdir -p stabilized
mkdir -p stabilizationdata
mkdir -p log

filename=$(basename "$1")
extension="${filename##*.}"
withoutext="${filename%.*}"
tmpname=$(mktemp -u tmp/$filename.XXXXX.$extension)
vidstabtmpname="${tmpname}.vidstabdetect"
vidstabname="stabilizationdata/${filename}.vidstabdetect"

args=$(printf " %q" "${@}")
if [ ! -f $vidstabname ] ; then
	nice -n 19 ffmpeg -loglevel warning -stats -i $filename -vf vidstabdetect=result="$vidstabtmpname" -f null - && mv --backup $vidstabtmpname $vidstabname
fi

FFREPORT="file=log/$filename.stabilize.log:level=40" nice -n 19 ffmpeg -loglevel warning -stats -i $filename -vf vidstabtransform=smoothing=10:input="$vidstabname",unsharp=5:5:0.8:3:3:0.4 -acodec copy -vcodec libx264 -preset slower -tune film -pix_fmt yuv420p -crf 18 $tmpname && mv --backup $tmpname stabilized/$filename
