#!/bin/bash

mkdir -p backup
mkdir -p log

if [ -f .last_metadata ] ; then
	. .last_metadata
fi

IFS=$'\n'
echo "New tape recording."
read -p "title: " -i "${AUDIO_TITLE}" -e AUDIO_TITLE
echo
read -p "artist: " -i "${AUDIO_ARTIST}" -e AUDIO_ARTIST
echo
read -p "album: " -i "${AUDIO_ALBUM}" -e AUDIO_ALBUM
echo
read -p "max length in HH:MM: " -i "${AUDIO_LENGTH:-01:30}" -e AUDIO_LENGTH
echo
read -p "format of original: " -i ${AUDIO_FORMAT:-cassette} -e AUDIO_FORMAT
echo
read -p "date of original if known (e.g: 2018-01-30): " -i "${AUDIO_DATE:-unknown-date}" -e AUDIO_DATE
echo
AUDIO_NOTES="${AUDIO_NOTES:-(source: $AUDIO_FORMAT)}"
read -p "any other notes: " -i "${AUDIO_NOTES}" -e AUDIO_NOTES
echo

AUDIO_SLUG=$(echo $AUDIO_TITLE | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)

filename="${AUDIO_DATE}-${AUDIO_SLUG}.mp3"
metaname="${filename%.*}.txt"

cat <<EOF > $metaname
AUDIO_ENCODED=$(date -Iseconds)
AUDIO_FILENAME=${filename@Q}
AUDIO_TITLE=${AUDIO_TITLE@Q}
AUDIO_ARTIST=${AUDIO_ARTIST@Q}
AUDIO_ALBUM=${AUDIO_ALBUM@Q}
AUDIO_LENGTH=${AUDIO_LENGTH@Q}
AUDIO_FORMAT=${AUDIO_FORMAT@Q}
AUDIO_DATE=${AUDIO_DATE@Q}
AUDIO_NOTES=${AUDIO_NOTES@Q}
EOF

cp $metaname .last_metadata

read -p "Hit enter to start recording."

test -f $filename && mv -v --backup -t backup $filename

fargs=" -loglevel warning -stats -report  -thread_queue_size 1024 -f alsa -ac 2 -i hw:1,0"
fargs+=" -ac 2 -q:a 4"
fargs+=" -t ${AUDIO_LENGTH}:30"

fargs+=" -metadata title=${AUDIO_TITLE@Q} -metadata date=${AUDIO_DATE@Q} -metadata comment=${AUDIO_NOTES@Q} -metadata artist=${AUDIO_ARTIST@Q} -metadata album=${AUDIO_ALBUM@Q}"

eval FFREPORT="file=log/$filename.log:level=40" nice -n -8 ffmpeg ${fargs} ${filename}

ls -lah $filename


