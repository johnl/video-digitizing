#!/bin/bash

exec cvlc --global-key-quit=q --key-quit=q --fbdev /dev/fb0 v4l2:///dev/video0
