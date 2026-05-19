#!/bin/bash

get_mpv_window_size() {
    hyprctl -j clients | jq --arg addr "$address" \
      '.[] | select(.address == $addr) | .size'
}

get_firefox_window_size() {
    echo '[336, 189]'
}

declare -A window_size_map=(
  [firefox]=get_firefox_window_size
  [mpv]=get_mpv_window_size
  )

pin() {
    local address="$1"
    local player="$2"

    hyprctl dispatch togglefloating address:$address

    MONITOR=$(hyprctl -j monitors | jq -c ".[]")
    MONITOR_WIDTH=$(jq ".width" <<< "$MONITOR")
    MONITOR_HEIGHT=$(jq ".height" <<< "$MONITOR")

    GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jq -r ".custom" | cut -d ' ' -f 1)
    BORDER_SIZE=$(hyprctl getoption general:border_size -j | jq -r ".int")

    window_size=$(${window_size_map[$player]})
    window_width=$(jq '.[0]' <<< "$window_size")
    window_height=$(jq '.[1]' <<< "$window_size")

    x=$(( $MONITOR_WIDTH - $window_width - $GAPS_OUT - $BORDER_SIZE ))
    y=$(( $MONITOR_HEIGHT - $window_height - $GAPS_OUT - $BORDER_SIZE ))

    hyprctl dispatch resizewindowpixel exact "$window_width $window_height", address:$address
    hyprctl dispatch movewindowpixel exact "$x $y", address:$address
    hyprctl dispatch pin address:$address
}

unpin() {
    local address="$1"

    hyprctl dispatch pin address:$address
    hyprctl dispatch movetoworkspacesilent 5, address:$address
    hyprctl dispatch togglefloating address:$address
}

active_player=$(
  hyprctl activewindow -j |
  jq -r '
      select(
          .class == "mpv" or
          (.class == "firefox" and .title == "Picture-in-Picture")
      )'
)

address=$(jq -r ".address" <<< "$active_player")
class=$(jq -r ".class" <<< "$active_player")

[[ ! "$class" =~ (mpv|firefox) ]] && exit

jq -e ".pinned" <<< "$active_player" >/dev/null && unpin $address || pin $address $class
