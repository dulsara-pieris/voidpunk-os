#!/bin/env zsh

# Directory where themes are stored
THEME_DIR="$HOME/.config/themes"

# Get a list of available themes
themes=($(ls "$THEME_DIR"))

# Show Wofi menu to select theme
selected=$(printf "%s\n" "${themes[@]}" | wofi --dmenu --prompt "Select Theme")

# Exit if no selection
[ -z "$selected" ] && exit

# Paths
HYPR_CONFIG="$HOME/.config/hypr/modules/styling.conf"
WAYBAR_CONFIG="$HOME/.config/waybar/config"
WOFI_CONFIG="$HOME/.config/wofi/style.rasi"

# Copy theme files
if [[ -f "$THEME_DIR/$selected/styling.conf" ]]; then
    cp "$THEME_DIR/$selected/styling.conf" "$HYPR_CONFIG"
fi

if [[ -f "$THEME_DIR/$selected/waybar.conf" ]]; then
    cp "$THEME_DIR/$selected/waybar.conf" "$WAYBAR_CONFIG"
fi

if [[ -f "$THEME_DIR/$selected/wofi.rasi" ]]; then
    cp "$THEME_DIR/$selected/wofi.rasi" "$WOFI_CONFIG"
fi

# Reload Hyprland and Waybar
hyprctl reload
killall waybar &>/dev/null
waybar &

# Optional: notify theme change
notify-send "Theme switched" "$selected theme applied!"
