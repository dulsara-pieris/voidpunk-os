#!/bin/env zsh

THEME_DIR="$HOME/.config/themes"

themes=($(ls "$THEME_DIR"))

selected=$(printf "%s\n" "${themes[@]}" | wofi --dmenu --prompt "Select Theme")

[ -z "$selected" ] && exit

cp "$THEME_DIR/$selected/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
cp "$THEME_DIR/$selected/waybar.conf" "$HOME/.config/waybar/config"
cp "$THEME_DIR/$selected/wofi.rasi" "$HOME/.config/wofi/style.rasi"

hyprctl reload
killall waybar &>/dev/null
waybar &
