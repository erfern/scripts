#!/bin/bash

calculate_screen_edges() {
    local MONITOR=$(hyprctl -j monitors | jq -c '.[]')
    local MONITOR_WIDTH=$(jq '.width' <<< "$MONITOR")
    local MONITOR_HEIGHT=$(jq '.height' <<< "$MONITOR")
    local MONITOR_RESERVED=$(jq '.reserved[1]' <<< "$MONITOR")

    local GAPS_OUT=$(
        hyprctl getoption general:gaps_out -j |
            jq -r '.custom' | cut -d ' ' -f 1
    )
    local BORDER_SIZE=$(
        hyprctl getoption general:border_size -j |
            jq '.int'
    )

    local window_width=$(jq '.size[0]' <<< "$window")
    local window_height=$(jq '.size[1]' <<< "$window")

    local Y_MIN=$(($GAPS_OUT + $BORDER_SIZE + $MONITOR_RESERVED))
    local Y_MAX=$(($MONITOR_HEIGHT - $window_height - $GAPS_OUT - $BORDER_SIZE))
    local X_MIN=$(($GAPS_OUT + $BORDER_SIZE))
    local X_MAX=$(($MONITOR_WIDTH - $window_width - $GAPS_OUT - $BORDER_SIZE))

    echo $Y_MIN $Y_MAX $X_MIN $X_MAX
}

move_to_position() {
    local position="$1" # up down left right
    local window="$2"

    local at_x=$(jq '.at[0]' <<< "$window")
    local at_y=$(jq '.at[1]' <<< "$window")

    local Y_MIN Y_MAX X_MIN X_MAX
    read Y_MIN Y_MAX X_MIN X_MAX < <(calculate_screen_edges)

    declare -A actions=(
        [up]="$at_x $Y_MIN"
        [down]="$at_x $Y_MAX"
        [left]="$X_MIN $at_y"
        [right]="$X_MAX $at_y"
    )
    local new_pos="${actions[$position]}"

    local address=$(jq -r '.address' <<< "$window")

    hyprctl dispatch movewindowpixel exact ${new_pos[@]}, address:$address
}

active_window=$(hyprctl -j activewindow)
move_to_position "$1" "$active_window"
