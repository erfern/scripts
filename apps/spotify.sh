#!/usr/bin/bash
# LD_PRELOAD=/usr/local/lib/spotify-adblock.so /bin/spotify
env LD_PRELOAD=/usr/lib/spotify-adblock.so /bin/spotify --uri=%U

