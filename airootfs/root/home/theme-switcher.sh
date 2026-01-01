#!/usr/bin/env zsh

# -----------------------------
# Paths
# -----------------------------
THEME_DIR="/etc/voidpunk/themes"
HYPR_THEME="$HOME/.config/hypr/theme.conf"
WAYBAR_THEME="$HOME/.config/waybar/style.css"
WOFI_THEME="$HOME/.config/wofi/style.css"

# -----------------------------
# Pick theme with Wofi
# -----------------------------
THEME=($(ls "$THEME_DIR" | wofi --dmenu --prompt "Choose Theme"))
[[ -z "$THEME" ]] && exit 0

# -----------------------------
# Link configs
# -----------------------------
mkdir -p "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/wofi"
ln -sf "$THEME_DIR/$THEME/hypr.conf" "$HYPR_THEME"
ln -sf "$THEME_DIR/$THEME/waybar.css" "$WAYBAR_THEME"
ln -sf "$THEME_DIR/$THEME/wofi.css" "$WOFI_THEME"

# -----------------------------
# GTK theme
# -----------------------------
GTK_THEME=$(cat "$THEME_DIR/$THEME/gtk.theme")
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

# -----------------------------
# Wallpaper
# -----------------------------
swww img "$THEME_DIR/$THEME/wallpaper.jpg" --transition-type grow

# -----------------------------
# Reload Hyprland + Waybar
# -----------------------------
hyprctl reload
pkill waybar && waybar &

# -----------------------------
# Reload pywal colors
# -----------------------------
wal -R
