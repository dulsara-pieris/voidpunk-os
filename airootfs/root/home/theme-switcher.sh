#!/bin/env zsh

# -------------------------------
# Full Modular Theme Switcher
# -------------------------------

THEME_DIR="$HOME/.config/hypr/themes"

# Get a list of themes
themes=($(ls "$THEME_DIR"))

# Show Wofi menu
selected=$(printf "%s\n" "${themes[@]}" | wofi --dmenu --prompt "Select Theme")
[ -z "$selected" ] && exit

# Map theme files to config locations
declare -A modules
modules=(
  ["styling.conf"]="$HOME/.config/hypr/modules/styling.conf"
  ["waybar.conf"]="$HOME/.config/waybar/config"
  ["waybar.css"]="$HOME/.config/waybar/style.css"
  ["wofi.rasi"]="$HOME/.config/wofi/style.rasi"
  ["kitty.conf"]="$HOME/.config/kitty/kitty.conf"
  ["starship.toml"]="$HOME/.config/starship.toml"
  ["swaylock.rasi"]="$HOME/.config/swaylock/style.rasi"
)

# Copy theme files if they exist
for file in "${(@k)modules}"; do
  if [[ -f "$THEME_DIR/$selected/$file" ]]; then
    cp "$THEME_DIR/$selected/$file" "${modules[$file]}"
  fi
done

# Set wallpaper if exists
if [[ -f "$THEME_DIR/$selected/wallpaper.jpg" ]]; then
    feh --bg-scale "$THEME_DIR/$selected/wallpaper.jpg"
fi

# Reload Hyprland and Waybar
hyprctl reload
killall waybar &>/dev/null
waybar &

# Reload Kitty colors dynamically
if command -v kitty >/dev/null && [[ -f "$THEME_DIR/$selected/kitty.conf" ]]; then
    kitty @ set-colors --all --config "$THEME_DIR/$selected/kitty.conf" 2>/dev/null
fi

# Notify theme change
notify-send "Theme switched" "$selected theme applied!"
