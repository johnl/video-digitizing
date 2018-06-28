#!/bin/bash

exec cvlc --fbdev /dev/tty1 v4l2:///dev/video0

