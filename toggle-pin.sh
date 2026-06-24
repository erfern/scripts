#!/bin/bash

STORAGE="/tmp/hyprland_pinned_workspaces.json"

store_original_workspace() {
    address="$1"
    workspace="$2"

    ! [[ -f "$STORAGE" ]] && echo "{}" >"$STORAGE"

    updated=$(
        jq --arg address "$address" --argjson workspace "$workspace" \
            '. + {($address): $workspace}' \
            "$STORAGE"
    )
    echo "$updated" > "$STORAGE"
}

get_original_workspace() {
    address="$1"

    jq -r --arg address "$address" '.[$address] // .' \
        "$STORAGE" 2>/dev/null

    # Delete entry, since the address might be overritten
    updated=$(
        jq --arg address "$address" \
            'del(.[$address])' \
            "$STORAGE"
    )
    echo "$updated" > "$STORAGE"
}

get_window_size() {
    class="$1"

    case "$class" in
        "mpv") hyprctl -j activewindow | jq -c '.size' ;;
        *) echo '[336, 189]' ;;
    esac
}

pin() {
    local address="$1"
    local class"$2"
    local workspace="$3"

    store_original_workspace "$address" "$workspace"

    hyprctl dispatch togglefloating address:$address

    local MONITOR=$(hyprctl -j monitors | jq -c '.[]')
    local MONITOR_WIDTH=$(jq '.width' <<<"$MONITOR")
    local MONITOR_HEIGHT=$(jq '.height' <<<"$MONITOR")

    local GAPS_OUT=$(
        hyprctl getoption general:gaps_out -j |
            jq -r '.custom' | cut -d ' ' -f 1
    )
    local BORDER_SIZE=$(
        hyprctl getoption general:border_size -j |
            jq '.int'
    )

    local window_size=$(get_window_size "$class")
    local window_width=$(jq '.[0]' <<<"$window_size")
    local window_height=$(jq '.[1]' <<<"$window_size")

    local x=$(($MONITOR_WIDTH - $window_width - $GAPS_OUT - $BORDER_SIZE))
    local y=$(($MONITOR_HEIGHT - $window_height - $GAPS_OUT - $BORDER_SIZE))

    hyprctl dispatch resizewindowpixel exact $window_width $window_height, address:$address
    hyprctl dispatch movewindowpixel exact $x $y, address:$address
    hyprctl dispatch pin address:$address
}

unpin() {
    local address="$1"

    workspace=$(get_original_workspace "$address")

    hyprctl dispatch pin address:$address
    hyprctl dispatch movetoworkspacesilent $workspace, address:$address
    hyprctl dispatch togglefloating address:$address
}

active_window=$(hyprctl activewindow -j)
address=$(jq -r '.address' <<< "$active_window")

if jq -e '.pinned' <<< "$active_window" >/dev/null; then
    unpin "$address"
else
    class=$(jq -r '.class' <<< "$active_window")
    workspace=$(jq -r '.workspace.id' <<< "$active_window")
    pin "$address" "$class" "$workspace"
fi
