#!/bin/bash

ffmpeg -loglevel info -i $1 -i $2 -lavfi "ssim;[0:v][1:v]psnr" -f null -
