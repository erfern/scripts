#!/usr/bin/bash

store() {
  tee "$HOME/pictures/screenshots/$(date +%s).png"
}

copy_to_clipboard() {
  xclip -selection clipboard -t image/png
}

case $1 in
  area) maim -s -d 0.2 | store | copy_to_clipboard;; 
  screen) maim -d 0.2 | store | copy_to_clipboard;;
esac

