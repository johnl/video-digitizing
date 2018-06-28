# John's VHS/Cassette tape digitizing scripts

I'm digitizing a bunch of old family home movies on VHS and other video tape formats. 

I did LOADS of testing to find a good set of configs to produce useful videos.

These scripts encapsulate the results of my experimentation. They might be
helpful to someone.

they try to avoid overwriting or deleting any files, even if you re-run a
capture. I think it's better to waste disk space than chuck something away
accidentally (especially as you MIGHT find an old tape deteriorates when you
play it!). Check the `backup/` and `tmp/` directories to clean up.

If this was useful and you liked it, or it wasn't and you hate it, email me to
tell me how you feel.

## Dependencies

Bash, ffmpeg, iconv, sed, tr.

## Process

I used a separate machine that I didn't use for much else, so I could leave it
captureing and encoding for long periods of time without disturbing it. Logged
in on the console rather than any gui. Sat the physical video players next to it.

If you have a lot of tapes, setup an inbox and and outbox so you don't get
confused and waste time digitizing multiple tapes.

I captured several tapes during the day, and then ran the longer final encoding
work overnight.

## Capture

use `capture-vhs.sh` to digitize a video in basically lossless format. it'll ask
you some questions about the capture which it'll use to generate the filename
and it'll store the rest in the video metadata.

it will deinterlate pal to 50fps. the resulting file will be around 20G per
hour, depending how noisy the video is.

### cpu power

you'll need a fair bit of cpu power to deinterlace and encode on the fly, but I
had trouble deinterlacing well post-capture. so I hope you have enough cpu power!

If you see a LOT of errors like this:

```
PTS -1443966142109, next:2230133221 invalid dropping st:0
DTS -1443966142109, next:2230173221 st:0 invalid dropping
```

it probably means the deinterlacing fell behind and there isn't enough cpu speed
to catch up (i.e: the errors just never stop). It's normal to see some of these,
especially for noisy videos which can take lots of cpu for the encoding alone.

Try changing `-preset faster` to `-preset ultrafast` to speed things up if you
have problems. It should not affect quality - it'll just create a bigger first
capture.

Don't run any other cpu intensive tasks.

Make sure the user you're running the scripts as has permission to set high
priorities on processes (see `/etc/security/limits.conf` :)

### duration

it will stop digitizing at the duration you specify. Most vhs tapes are a minute
or two longer than what they say (so 45mins is 47). And any long play videos
will be 1.5x-2x longer. Best to just capture everything at 2x longer imo and
crop it later, rather than waste time and risk tapes needing to redigitize.

## Finalizing

use `finalize-video.sh` to take the lossless version and create two copies, one
higher quality "archive" version in x265 for and one medium quality "final"
version in x264.

Basically, I couldn't find a good compromise between quality, file size and
*compatibility on players* so I went with two files.

use the archive one if you can as it's higher quality (and might even be smaller
in size!). But is uses the x265 codec which isn't as well supported (and for the
record, is a fair bit slower to do encoding!).

use the final one (x264) for sticking on a bluray or dvd that should play in
most bluray/dvd players, or on a USB stick that will play on most smart TVs now.

once this has run and you're happy you can delete the first large "lossless"
version if you need the space. The archive version should be good enough.

### arguments

first argument is the filename of the lossless version.

second argument is optional and is the the duration of the video (in case the
capture you have is longer than the actual video content).

third argument is the start position in case the actual video content doesn't
start straight away. FIXME: check this does the right thing when combined with
duration!)

## Other tools

`capture-tape-audio.sh` is like `capture-vhs.sh` but just for audio. I used it
to digitize a bunch of old cassette tapes.

`compare-video-quality.sh` takes two videos as arguments and runs an anaylsis
against them to help you compare quality. you can hit q at any time and get the
analysis up to that point. tbh though it's best to compare manually imo. if you
want to use it, look up the docs for the filters to find out what the number
mean.

`edit-media.sh` takes a file name as first arg and then sticks all the remaining
args in the ffmpeg command for it. Handy for fiddling with videos, particularly
for changing metadata.

`side-by-side-media.sh` takes two existing videos as the first two arguments and
creates a new video of them displayed next to each other. This was handy for
testing out video filtering, especially stabilisiation. Quicker to run two
players next to each other though tbh.

`stabilize-media.sh` takes an existing video as an argument and writes a new
version with motion stabilization. It takes quite a long time. I found that to
get acceptable results you have to tweak all the filter settings carefully
per-video, and even then the quality will be a bit worse overall due to the
transformations. not really worth it imo.

`watch-tv.sh` uses the command line version of vlc to let you watch the input
live on the frame buffer. useful for peeking at videos before playing them.
though I'd still recommend digitizing it and fixing the metadata afterwards
rather than peeking at videos and risking damaging them.
