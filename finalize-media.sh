#!/bin/bash

function join_by { local IFS="$1"; shift; echo "$*"; }

mkdir -p tmp
mkdir -p backup
mkdir -p archive
mkdir -p final
mkdir -p log

denoise_strong="nlmeans=2:3"
denoise_weak="nlmeans=1:1"
denoise=
deint="bwdif=0:1"
audio="-c:a copy"
brighten=
crf=28
framerate=

# my pal encodings have a noisy border around them containing no real image data. black it out!
border_boxes="drawbox=0:0:18:0:Black:fill,drawbox=iw-18:0:18:0:Black:fill,drawbox=0:0:0:4:Black:fill,drawbox=0:ih-4:iw:0:Black:fill"

! PARSED=$(getopt --options c:,b,d:,i,m,e:,s:,a,o,n:,r: --longoptions=crf:,brighten,denoise:,no-deint,force-mono,time-end:,time-start:,audio-encode,no-border,frame-rate: -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  exit 2
fi
eval set -- "$PARSED"
while true; do
  case "$1" in
    -c|--crf)
      crf=$2
      shift 2
      ;;
    -b|--brighten)
      brighten="normalize=blackpt=black:whitept=white:smoothing=50"
      shift
      ;;
    -d|--denoise)
      case "$2" in
        none)
	  denoise=
	  ;;
	strong)
          denoise=$denoise_strong
          ;;
	weak)
	  denoise=$denoise_weak
	  ;;
      esac
      shift 2
      ;;
    -i|--no-deint)
      deint=''
      shift 1
      ;;
    -m|--force-mono)
      audio="-ac 1 -c:a libopus -b:a 160k"
      shift
      ;;
    -e|--time-end)
      timeend="-to $2"
      shift 2
      ;;
    -s|--time-start)
      timestart="-ss $2"
      shift 2
      ;;
    -a|--audio-encode)
      audio="-c:a libopus -b:a 160k"
      shift
      ;;
    -o|--no-border)
      border_boxes=""
      shift
      ;;
    -r|--frame-rate)
      framerate="-r $2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    esac
done

vfl=()
if [ ! -z $brighten ] ; then
	vfl+=($brighten)
fi
if [ ! -z $border_boxes ] ; then
	vfl+=($border_boxes)
fi
if [ ! -z $denoise ] ; then
	vfl+=($denoise)
fi
if [ ! -z $deint ] ; then
	vfl+=($deint)
fi

vf=$(join_by , ${vfl[*]})

filename=$(basename "$1")
extension="${filename##*.}"
withoutext="${filename%.*}"
tmpname=$(mktemp -u tmp/$filename.XXXXX.$extension)
archivename="archive/${withoutext}.webm"
finalname="final/$filename"

if [ ! -f $archivename ] ; then
	echo "Encoding archive version $archivename"
	FFREPORT="file=log/$filename.archive.org:level=40" nice -n 19 ffmpeg -loglevel warning -stats $timestart $timeend -i $filename $audio -c:v libvpx-vp9 -threads 3 -tile-columns 4 -frame-parallel 1 -auto-alt-ref 1 -lag-in-frames 25 -crf $crf -b:v 0 -speed 1 -g 33 $framerate -vf $vf ${tmpname}.webm && (mv --backup ${tmpname}.webm $archivename)
fi
exit 0
if [ ! -f $finalname ] ; then
	echo "Encoding final version $finalname"
	FFREPORT="file=log/$filename.final.log:level=40" nice -n 19 ffmpeg -loglevel warning -stats -ss $timestart $timeend -i $filename -c:a aac -b:a 128k -c:v libx264 -preset veryslow -tune film -pix_fmt yuv420p -crf 23 -movflags +faststart  -vf $vf,$noise_medium $tmpname && mv --backup $tmpname $finalname
fi
