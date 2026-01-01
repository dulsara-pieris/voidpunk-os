#!/bin/zsh
# 🖤 Arch Installer with Hyprland (Wayland) 🖤
# ⚠️ WARNING: This WILL erase the selected disk!

autoload -U colors && colors
GREEN=$fg[green]; RED=$fg[red]; YELLOW=$fg[yellow]; BLUE=$fg[blue]; RESET=$reset_color

echo "${GREEN}🖤 Welcome to the Arch + Hyprland Installer 🖤${RESET}"

# === Ask for username and hostname ===
while [[ -z "$username" ]]; do
    read "username?Enter your new username: "
done
while [[ -z "$hostname" ]]; do
    read "hostname?Enter your system hostname: "
done

# === Check network ===
echo "${BLUE}Checking network...${RESET}"
ping -c 1 archlinux.org &>/dev/null && echo "${GREEN}Network OK!${RESET}" || { echo "${RED}No network!${RESET}"; exit 1; }

# === Select disk safely ===
echo "${BLUE}Available disks:${RESET}"
lsblk
while true; do
    read "disk?Enter the disk to install Arch (e.g., /dev/sda): "
    [[ -b "$disk" ]] && break || echo "${RED}Invalid disk. Try again.${RESET}"
done

# Confirm destructive action
echo "${RED}All data on $disk will be erased!${RESET}"
read "confirm?Type YES to continue: "
[[ $confirm != YES ]] && { echo "${YELLOW}Canceled.${RESET}"; exit 1; }

# === Partition ===
echo "${BLUE}Partitioning $disk...${RESET}"
parted "$disk" -- mklabel gpt
parted "$disk" -- mkpart primary fat32 1MiB 513MiB
parted "$disk" -- set 1 boot on
parted "$disk" -- mkpart primary linux-swap 513MiB 2.5GiB
parted "$disk" -- mkpart primary ext4 2.5GiB 100%

# === Format & Mount ===
echo "${BLUE}Formatting...${RESET}"
mkfs.fat -F32 "${disk}1"
mkswap "${disk}2"
swapon "${disk}2"
mkfs.ext4 "${disk}3"

mount "${disk}3" /mnt
mkdir -p /mnt/boot
mount "${disk}1" /mnt/boot

# === Base system + Hyprland DE packages ===
HYPR_PACKAGES=(
    zsh vim sudo git
    networkmanager dhcpcd wpa_supplicant
    base-devel neofetch htop firefox
    hyprland waybar wofi mako swaybg foot grim slurp
    wl-clipboard wayland-protocols
)

echo "${BLUE}Installing base system + Hyprland...${RESET}"
pacstrap /mnt base linux linux-firmware $HYPR_PACKAGES

# === fstab ===
echo "${BLUE}Generating fstab...${RESET}"
genfstab -U /mnt > /mnt/etc/fstab

# === Configure system inside chroot ===
echo "${GREEN}⚡ Entering chroot to finish setup...${RESET}"
arch-chroot /mnt /bin/zsh <<EOF
autoload -U colors && colors
GREEN=\$fg[green]; RED=\$fg[red]; YELLOW=\$fg[yellow]; BLUE=\$fg[blue]; RESET=\$reset_color

echo "\${GREEN}🖤 Configuring system 🖤\${RESET}"

# Hostname
echo "$hostname" > /etc/hostname

# Root password
echo "Set root password for root user:"
passwd

# Create user
useradd -m -G wheel -s /bin/zsh "$username"
echo "Set password for $username:"
passwd "$username"

# Enable sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Enable NetworkManager
systemctl enable NetworkManager

# Install GRUB bootloader
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable graphical login with Hyprland (optional)
echo "${GREEN}You can now start Hyprland with: startx or just log in to TTY and run hyprland.${RESET}"
EOF

echo "${GREEN}✅ Installation complete! Reboot now to start your Hyprland desktop.${RESET}"
