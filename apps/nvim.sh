#!/usr/bin/bash

if [ ! "$1" ]; then
  alacritty --class nvim -e /bin/nvim &
elif [ -d "$1" ]; then
  dir="$1"
  alacritty --class nvim -e /bin/nvim -c ":cd $dir" -c ":Telescope find_files" &
elif [ -f "$1" ]; then
  dir=$(dirname "$1")
  alacritty --class nvim -e /bin/nvim -c ":cd $dir" -- "$1" &
else
  /bin/nvim "$@"
fi


