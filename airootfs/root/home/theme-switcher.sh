#!/bin/bash

THEME_DIR="$HOME/.config/themes"

# Get list of themes
themes=($(ls "$THEME_DIR"))

# Show menu with Wofi
selected=$(printf "%s\n" "${themes[@]}" | wofi --dmenu --prompt "Select Theme")

# Exit if no selection
[ -z "$selected" ] && exit

# Copy theme files to main config
cp "$THEME_DIR/$selected/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
cp "$THEME_DIR/$selected/waybar.conf" "$HOME/.config/waybar/config"
cp "$THEME_DIR/$selected/wofi.rasi" "$HOME/.config/wofi/style.rasi"

# Reload Hyprland and Waybar
hyprctl reload
killall waybar &>/dev/null
waybar &
