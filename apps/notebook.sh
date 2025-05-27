#!/usr/bin/bash

alacritty --class notebook -e nvim -c ":cd $HOME/notes" -c ":Telescope find_files" -c ":highlight @neorg.headings.2.title guifg=#5DFF88" -c ":highlight @neorg.headings.2.prefix guifg=#5DFF88" &
