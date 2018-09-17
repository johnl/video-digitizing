# John's VHS/Cassette tape digitizing scripts

I'm digitizing a bunch of old family home movies on VHS and other video tape formats. 

I did LOADS of testing to find a good set of configs to produce useful videos.

These scripts encapsulate the results of my experimentation. They might be
helpful to someone.

They try to avoid overwriting or deleting any files, even if you re-run a
capture. I think it's better to waste disk space than chuck something away
accidentally (especially as you MIGHT find an old tape deteriorates when you
play it!). Check the `backup/` and `tmp/` directories to clean up.

If this was useful and you liked it, or it wasn't and you hate it, email me to
tell me how you feel.

## Dependencies

Bash, ffmpeg, iconv, sed, tr. I recommend using John Van Sickle's static ffmpeg
builds to get the latest versions (which have the latest vp9 codec libs and have
much improved webm metadata support). https://johnvansickle.com/ffmpeg/

## Process

I used a separate machine that I didn't use for much else, so I could leave it
capturing and encoding for long periods of time without disturbing it. Logged
in on the console rather than any gui. Sat the physical video players next to it.

If you have a lot of tapes, setup an inbox and and outbox so you don't get
confused and waste time digitizing multiple tapes.

I captured several tapes and then ran the longer filtering and compression stage
(finalizing) in a big batch.

## Capture

use `capture-vhs.sh` to digitize a video in basically lossless format. it'll ask
you some questions about the capture which it'll use to generate the filename
and it'll store the rest in the video metadata.

I recommend using `--raw` to do as little pre-processing as possible (but will
result in a large file, roughly 40G per hour).

If you know your video source is in mono, use the `--mono` option.

### CPU power

If you're not using raw, you'll need a fair bit of cpu power to deinterlace and
encode on the fly. If you see a LOT of errors like this:

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

If you're using the `--raw` option this most likely won't be an issue, though
disk space might be! See below.

### Duration

it will stop digitizing at the duration you specify. Most vhs tapes are a minute
or two longer than what they say (so 45mins is 47). And any long play videos
will be 1.5x-2x longer. Best to just capture everything at 2x longer imo and
crop it later, rather than waste time and risk tapes needing to redigitize.

## Finalizing

use `finalize-video.sh` to take the lossless version and produce a final high
quality archival version using the VP9 codec.

The first argument is the filename of file to process.

You can also specify various options:

``--time-start`` and ``--time-end`` specify the timestamps to start and end
encoding, in case you have some blank video at the start and end of your
capture.

### Deinterlacing

The script will use `bwdif` deinterlace filter by default, configured for
standard PAL-I interlacing. I found bwdif to 25fps to be the best option for the
usually fairly noisy VHS captures I'm dealing with. Other interlaces and modes
that generate 50fps end up with pretty strobing noise patterns that encode very
poorly.

### Denoising

If your video is visually noisy, which is almost certain given old VHS video
tapes, use the ``--denoise=weak`` or ``--denoise=strong`` options to apply a
denoising filter. It's definitely worth denoising because otherwise the codec
has to do a lot of work to encode the noise, so the file size will be large and
the quality will suffer. It's pointless encoding all that noise.

After comparing lots of denoisers, I found the nlmeans filter to be far
superior, but it is ridiculously slow. It's definitely worth it but it slowed
down my encoding by a factor of 10 and doesn't use multiple cores very
effectively. Expect denoising an hour of video to take 20-30 hours.

I mostly use weak denoising, but on use strong when things are particularly bad
quality.

### Quality

I did loads of work to compare various quality settings for VP9 and settled on a
crf of `28`. I could find no perceptible improvement in quality by going lower
than `28`. It produces files that are roughly 1-2G per hour of video.

If you want to increase or decrease quality you can specify your own quality
with `--crf`. Lower the number to increase quality, raise the number to decrease
quality.

### Borders

all my VHS videos has a noisy edge with no actual video but was distracting and
increased the final video size. So the script adds a few pixels of black borders
to tidy that up. Depending on a few factors, it does risk covering up some a few
pixels of real video though so you can disable that with `--no-border`

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
