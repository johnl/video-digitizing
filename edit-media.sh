#!/bin/bash

mkdir -p tmp
mkdir -p backup

filename=$(basename "$1")
shift
extension="${filename##*.}"
withoutext="${filename%.*}"
tmpname=$(mktemp -u tmp/$filename.XXXXX.$extension)

args=$(printf " %q" "${@}")
eval ffmpeg -loglevel warning -stats -i $filename -acodec copy -vcodec copy ${args} $tmpname && (mv --backup -t backup  $filename && mv $tmpname $filename)
