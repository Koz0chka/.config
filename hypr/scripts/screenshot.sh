#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshots/$(date +%Y-%m)"
mkdir -p "$SCREENSHOT_DIR"
FILENAME="$SCREENSHOT_DIR/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
    "area")
        geometry=$(slurp)
        if [ -n "$geometry" ]; then
            grim -g "$geometry" "$FILENAME"
            wl-copy < "$FILENAME"
        fi
        ;;

    "full")
        grim "$FILENAME"
        wl-copy < "$FILENAME"
        ;;

    "active")
        geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        if [ -n "$geometry" ]; then
            grim -g "$geometry" "$FILENAME"
            wl-copy < "$FILENAME"
        fi
        ;;
esac
