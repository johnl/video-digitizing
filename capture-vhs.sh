#!/bin/bash

mkdir -p backup
mkdir -p log

noise_weak=hqdn3d=2:1:2:3

noise_medium=hqdn3d=3:2:2:3

noise_strong=hqdn3d=7:7:10:10

noise_stronger=hqdn3d=10:10:14:14

# my pal encodings have a noisy border around them containing no real image data. black it out!
border_boxes=drawbox=0:0:18:0:Black:max,drawbox=iw-18:0:18:0:Black:max,drawbox=0:0:0:4:Black:max,drawbox=0:ih-4:iw:0:Black:max

! PARSED=$(getopt --options m,s,r --longoptions=mono,stereo,raw -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  exit 2
fi
eval set -- "$PARSED"
audio=stereo
while true; do
  case "$1" in
    -m|--mono)
      audio=mono
      shift
      ;;
    -s|--stereo)
      audio=stereo
      shift
      ;;
    -o|--output)
      outFile="$2"
      shift 2
      ;;
    -r|--raw)
      raw=true
      shift
      ;;
    --)
      shift
      break
      ;;
    esac
done

if [ -f .last_metadata ] ; then
	  . .last_metadata
fi
echo "New vhs recording."
read -p "title: " -i "${VIDEO_TITLE}" -e VIDEO_TITLE
echo
read -p "author: " -i "${VIDEO_ARTIST}" -e VIDEO_ARTIST
echo
read -p "album: " -i "${VIDEO_ALBUM}" -e VIDEO_ALBUM
echo
read -p "max length in HH:MM: " -i "${VIDEO_LENGTH:-02:00}" -e VIDEO_LENGTH
echo
read -p "format of original (hi8, vhsc, vhs): " -i ${VIDEO_FORMAT:-unspecified} -e VIDEO_FORMAT
echo
read -p "date of original if known (e.g: 2018-01-30): " -i "${VIDEO_DATE:-unknown-date}" -e VIDEO_DATE
echo
VIDEO_NOTES="${VIDEO_NOTES:-(source: $VIDEO_FORMAT)}"
read -p "any other notes: " -i "${VIDEO_NOTES}" -e VIDEO_NOTES
echo

VIDEO_SLUG=$(echo $VIDEO_TITLE | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)

filename="${VIDEO_DATE}-${VIDEO_SLUG}.mkv"
metaname="${filename%.*}.txt"

cat <<EOF > $metaname
VIDEO_ENCODED=$(date -Iseconds)
VIDEO_FILENAME=${filename@Q}
VIDEO_TITLE=${VIDEO_TITLE@Q}
VIDEO_ARTIST=${VIDEO_ARTIST@Q}
VIDEO_ALBUM=${VIDEO_ALBUM@Q}
VIDEO_LENGTH=${VIDEO_LENGTH@Q}
VIDEO_FORMAT=${VIDEO_FORMAT@Q}
VIDEO_DATE=${VIDEO_DATE@Q}
VIDEO_NOTES=${VIDEO_NOTES@Q}
EOF

cp $metaname .last_metadata

read -p "Hit enter to start recording."

test -f $filename && mv -v --backup -t backup $filename

fargs=" -loglevel warning -stats -report  -thread_queue_size 1024 -f alsa -i hw:1,0"
fargs+=" -thread_queue_size 1024 -f video4linux2 -standard PAL-I -i /dev/video0"
fargs+=" -c:a libopus -b:a 160k"
if [ $audio == "mono" ] ; then
  fargs+=" -ac 1"
fi
if [ "$raw" == true ] ; then
	fargs+=" -vcodec libx264 -preset faster -aspect 4:3 -tune film -crf 0 -profile:v high444 -level:v 4.1 -g 33 -flags +ildct+ilme -pix_fmt yuv422p "
else
	fargs+=" -vcodec libx264 -preset faster -aspect 4:3 -pix_fmt yuv420p -vf yadif=1:1 -tune film -crf 10"
fi
fargs+=" -t ${VIDEO_LENGTH}:00"

# https://kdenlive.org/en/project/adding-meta-data-to-mp4-video/
fargs+=" -metadata title=${VIDEO_TITLE@Q} -metadata artist=${VIDEO_ARTIST@Q} -metadata album=${VIDEO_ALBUM@Q} -metadata date=${VIDEO_DATE@Q} -metadata comment=${VIDEO_NOTES@Q}"

eval FFREPORT="file=log/$filename.log:level=40" nice -n -8 ffmpeg ${fargs} ${filename}

ls -lah $filename

