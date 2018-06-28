#!/bin/bash

mkdir -p tmp
mkdir -p backup

filename=$(basename "$1")
extension="${filename##*.}"
withoutext="${filename%.*}"
tmpname=$(mktemp -u tmp/$filename.XXXXX.$extension)
timeduration=$2
timestart=${3:-0}

ffmpeg -loglevel warning -stats -ss ${timestart} -t ${timeduration} -i $filename -acodec copy -vcodec copy $tmpname && (mv --backup -t backup  $filename && mv $tmpname $filename)
