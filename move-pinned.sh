#!/bin/bash

window=$(hyprctl -j clients | jq -c ".[] | select(.pinned == true)")
[[ -z "$window" ]] && exit

GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jq -r ".custom" | cut -d ' ' -f 1)
BORDER_SIZE=$(hyprctl getoption general:border_size -j | jq -r ".int")

MONITOR=$(hyprctl -j monitors | jq -c ".[]")
MONITOR_WIDTH=$(jq ".width" <<< "$MONITOR")
MONITOR_HEIGHT=$(jq ".height" <<< "$MONITOR")
MONITOR_RESERVED=$(jq ".reserved[1]" <<< "$MONITOR")

window_width=$(jq -c ".size[0]" <<< "$window")
window_height=$(jq -c ".size[1]" <<< "$window")
pos_x=$(jq -c ".at[0]" <<< "$window")
pos_y=$(jq -c ".at[1]" <<< "$window")

Y_MIN=$(( $GAPS_OUT + $BORDER_SIZE + $MONITOR_RESERVED ))
Y_MAX=$(( $MONITOR_HEIGHT - $window_height - $GAPS_OUT - $BORDER_SIZE))
X_MIN=$(( $GAPS_OUT + $BORDER_SIZE ))
X_MAX=$(( $MONITOR_WIDTH - $window_width - $GAPS_OUT - $BORDER_SIZE ))

declare -A actions=(
    [up]="$pos_x $Y_MIN"
    [down]="$pos_x $Y_MAX"
    [left]="$X_MIN $pos_y"
    [right]="$X_MAX $pos_y"
)
new_pos="${actions[$1]}" 

address=$(jq -c ".address" <<< "$window" | sed 's/"//g') 
hyprctl dispatch movewindowpixel exact ${new_pos[@]}, address:$address
