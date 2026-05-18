#!/bin/bash

get_window_size() {
    hyprctl -j clients | jq --arg addr "$address" \
      '.[] | select(.address == $addr) | .size'
}

pin_mpv() {
    address=$(jq -rc ".address" <<< "$mpv_player")

    hyprctl dispatch setprop address:$address no_anim 1
    hyprctl dispatch togglefloating address:$address

    MONITOR=$(hyprctl -j monitors | jq -c ".[]")
    MONITOR_WIDTH=$(jq ".width" <<< "$MONITOR")
    MONITOR_HEIGHT=$(jq ".height" <<< "$MONITOR")

    GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jq -r ".custom" | cut -d ' ' -f 1)
    BORDER_SIZE=$(hyprctl getoption general:border_size -j | jq -r ".int")

    # proportions's been updated after making the window float
    window_size=$(get_window_size)
    window_width=$(jq ".[0]" <<< "$window_size")
    window_height=$(jq ".[1]" <<< "$window_size")

    x=$(( $MONITOR_WIDTH - $window_width - $GAPS_OUT - $BORDER_SIZE ))
    y=$(( $MONITOR_HEIGHT - $window_height - $GAPS_OUT - $BORDER_SIZE ))

    hyprctl dispatch resizewindowpixel exact "$window_width $window_height", address:$address
    hyprctl dispatch movewindowpixel exact "$x $y", address:$address
    hyprctl dispatch pin address:$address
    hyprctl dispatch setprop address:$address no_anim 0
}

unpin_mpv() {
    address=$(jq -rc ".address" <<< "$mpv_player")
    hyprctl dispatch setprop address:$address no_anim 1

    hyprctl dispatch pin address:$address
    hyprctl dispatch movetoworkspacesilent 5, address:$address
    hyprctl dispatch togglefloating address:$address

    hyprctl dispatch setprop address:$address no_anim 0
}

unpin_firefox_player() {
    address=$(jq -rc ".address" <<< "$firefox_player")
    hyprctl dispatch sendshortcut , Escape, address:$address
}

pin_firefox_player() {
    ff_address=$(jq -r ".address" <<< "$firefox_window")

    # Open pip player at the workspace set by hyprland's windowrules
    hyprctl dispatch sendshortcut CTRL SHIFT, bracketright, address:$ff_address


    sleep 0.3  # 0.2 works 0.1 doesnt
    address=$(hyprctl -j clients | jq -r '.[] | select(.class == "firefox" and .title == "Picture-in-Picture") | .address')

    hyprctl dispatch togglefloating address:$address

    # CANNOT BE DYNAMIC.
    # After resizing it once, firefox wont bother to resize to match the video anymore.
    window_width=336
    window_height=189

    hyprctl dispatch resizewindowpixel exact "$window_width $window_height", address:$address

    MONITOR=$(hyprctl -j monitors | jq -c ".[]")
    MONITOR_WIDTH=$(jq ".width" <<< "$MONITOR")
    MONITOR_HEIGHT=$(jq ".height" <<< "$MONITOR")

    GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jq -r ".custom" | cut -d ' ' -f 1)
    BORDER_SIZE=$(hyprctl getoption general:border_size -j | jq -r ".int")

    x=$(( $MONITOR_WIDTH - $window_width - $GAPS_OUT - $BORDER_SIZE ))
    y=$(( $MONITOR_HEIGHT - $window_height - $GAPS_OUT - $BORDER_SIZE ))

    hyprctl dispatch movewindowpixel exact "$x $y", address:$address
    hyprctl dispatch pin address:$address

    # When a window out of the current workspace is pinned,
    # it's not added to the current workspace properly
    sleep 0.3
    hyprctl dispatch movetoworkspacesilent +0, title:"Picture-in-Picture"
}


clients=$(hyprctl -j clients)

mpv_player=$(jq -r '.[] | select(.class == "mpv")' <<< "$clients")
[[ -n $mpv_player ]] && {
    jq -e ".pinned" <<< "$mpv_player" >/dev/null && unpin_mpv || pin_mpv
} && exit

firefox_player=$(jq -r '.[] | select(.class == "firefox" and .title == "Picture-in-Picture")' <<< "$clients")
[[ -n $firefox_player ]] && unpin_firefox_player && exit

firefox_window=$(jq -r '.[] | select(.class == "firefox" and .title != "Picture-in-Picture")' <<< "$clients")
[[ -n $firefox_window ]] && pin_firefox_player && exit
