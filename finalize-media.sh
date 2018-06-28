#!/bin/bash

mkdir -p tmp
mkdir -p backup
mkdir -p archive
mkdir -p final
mkdir -p log

noise_weak=hqdn3d=2:1:2:3

noise_medium=hqdn3d=3:2:2:3

noise_strong=hqdn3d=7:7:10:10

noise_stronger=hqdn3d=10:10:14:14

# my pal encodings have a noisy border around them containing no real image data. black it out!
border_boxes=drawbox=0:0:18:0:Black:max,drawbox=iw-18:0:18:0:Black:max,drawbox=0:0:0:4:Black:max,drawbox=0:ih-4:iw:0:Black:max

filename=$(basename "$1")
extension="${filename##*.}"
withoutext="${filename%.*}"
tmpname=$(mktemp -u tmp/$filename.XXXXX.$extension)
archivename="archive/$filename"
finalname="final/$filename"

if [ $2 != "" ] ; then
	timeduration="-to $2"
fi

timestart=${3:-0}

if [ ! -f $archivename ] ; then
	echo "Encoding archive version $archivename"
	FFREPORT="file=log/$filename.archive.org:level=40" nice -n 19 ffmpeg -loglevel warning -stats -ss $timestart -i $filename -c:a copy -c:v libx265 -preset medium -vf $border_boxes,$noise_weak -crf 23 $timeduration $tmpname && (mv --backup $tmpname $archivename)
fi

echo "Encoding final version $finalname"
FFREPORT="file=log/$filename.final.log:level=40" nice -n 19 ffmpeg -loglevel warning -stats -ss $timestart -i $filename -movflags +faststart -c:a copy -c:v libx264 -preset slower -vf $border_boxes,$noise_stronger -tune film -pix_fmt yuv420p -crf 26 $timeduration $tmpname && mv --backup $tmpname $finalname

