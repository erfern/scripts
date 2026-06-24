#!/usr/bin/bash

storage="$HOME/pictures/screenshots/$(date +%s).png"
slurp |  grim -c -g - - | tee "$storage" | wl-copy -t image/png
