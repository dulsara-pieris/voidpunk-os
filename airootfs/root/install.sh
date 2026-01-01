#!/bin/zsh

# =============================================
#        VoidPunk Cyberpunk Installer
#        Hyprland default DE
# =============================================
clear
autoload -U colors && colors
# Neon palette
GREEN=$fg_bold[green]; RED=$fg_bold[red]; YELLOW=$fg_bold[yellow]
BLUE=$fg_bold[blue]; MAGENTA=$fg_bold[magenta]; CYAN=$fg_bold[cyan]
NEON=$fg_bold[magenta]; BOLD=$fg_bold[white]; RESET=$reset_color

# === Cyberpunk ASCII banner ===
banner=(
"╔══════════════════════════════════════════════════════════════╗"
"║ ____   ____    .__    ._____________              __         ║"
"║ \\   \\ /   /___ |__| __| _/\\______   \\__ __  ____ |  | __     ║"
"║  \\   Y   /  _ \\|  |/ __ |  |     ___/  |  \\/    \\|  |/ /     ║"
"║   \\     (  <_> )  / /_/ |  |    |   |  |  /   |  \\    <      ║"
"║    \\___/ \\____/|__\\____ |  |____|   |____/|___|  /__|_ \\     ║"
"║                        \\/                      \\/     \\/     ║"
"╚══════════════════════════════════════════════════════════════╝"
)
COLORS=($fg_bold[cyan] $fg_bold[magenta] $fg_bold[blue] $fg_bold[yellow] $fg_bold[green] $fg_bold[red])

# Flicker effect
for _ in {1..2}; do
    for i in {1..${#banner[@]}}; do
        color=${COLORS[$RANDOM % ${#COLORS[@]}]}
        echo "${color}${banner[$i]}${RESET}"
    done
    sleep 0.8
    tput cuu ${#banner[@]}
done

# Final static banner
for i in {1..${#banner[@]}}; do
    color=${COLORS[$((i % ${#COLORS[@]}))]}
    echo "${color}${banner[$i]}${RESET}"
done

# === Animated initializing message ===
msg="${BOLD}⚡ Initializing VoidPunk Cyberpunk Installer... ⚡${RESET}"
for ((i=0; i<${#msg}; i++)); do
    echo -n "${msg:$i:1}"
    sleep 0.03
done
echo ""

# === Ask for username and hostname ===
while [[ -z "$username" ]]; do
    read "username?${NEON}Enter your new username: ${RESET}"
done
while [[ -z "$hostname" ]]; do
    read "hostname?${NEON}Enter your system hostname: ${RESET}"
done

# === Check network ===
echo -n "${BLUE}Checking network"
for i in {1..3}; do echo -n "."; sleep 0.5; done
echo ""
ping -c 1 voidlinux.org &>/dev/null && echo "${GREEN}Network OK!${RESET}" || { echo "${RED}No network!${RESET}"; exit 1; }

# === Select disk safely ===
echo "${MAGENTA}Available disks:${RESET}"
lsblk
while true; do
    read "disk?${NEON}Enter the disk to install VoidPunk (e.g., /dev/sda): ${RESET}"
    [[ -b "$disk" ]] && break || echo "${RED}Invalid disk. Try again.${RESET}"
done

echo "${RED}⚠️ All data on $disk will be erased! ⚠️${RESET}"
read "confirm?Type ${BOLD}YES${RESET} to continue: "
[[ $confirm != YES ]] && { echo "${YELLOW}Canceled.${RESET}"; exit 1; }

# === Partitioning progress bar ===
echo "${CYAN}Partitioning $disk...${RESET}"
echo -n "${BLUE}["
for i in {1..20}; do echo -n "#"; sleep 0.05; done
echo "] Done"

parted "$disk" -- mklabel gpt
parted "$disk" -- mkpart primary fat32 1MiB 513MiB
parted "$disk" -- set 1 boot on
parted "$disk" -- mkpart primary linux-swap 513MiB 2.5GiB
parted "$disk" -- mkpart primary ext4 2.5GiB 100%

# === Format & Mount ===
echo "${GREEN}Formatting...${RESET} 💾"
mkfs.fat -F32 "${disk}1"
mkswap "${disk}2"
swapon "${disk}2"
mkfs.ext4 "${disk}3"

mount "${disk}3" /mnt
mkdir -p /mnt/boot
mount "${disk}1" /mnt/boot

# === Interactive package selection ===
PACKAGES=(base-system xbps xbps-src sudo git zsh networkmanager)

echo "${CYAN}📦 Customize your packages!${RESET}"

# Editors
read "editors?${NEON}Editors (vim nano emacs) ?: ${RESET}"
[[ -n $editors ]] && PACKAGES+=($editors)

# Browsers
read "browsers?${NEON}Browsers (firefox chromium qutebrowser) ?: ${RESET}"
[[ -n $browsers ]] && PACKAGES+=($browsers)

# Utilities
read "utils?${NEON}Utilities (htop neofetch tmux ranger) ?: ${RESET}"
[[ -n $utils ]] && PACKAGES+=($utils)

# Hyprland DE is default, no selection needed
PACKAGES+=(hyprland waybar wofi mako swaybg foot grim slurp wl-clipboard)

# Show final package list
echo "${CYAN}📦 Installing packages:${RESET}"
echo "${PACKAGES[@]}"

echo -n "${CYAN}Installing "
for i in {1..10}; do echo -n "⚡"; sleep 0.1; done
echo ""

# Install selected packages with xbps
for pkg in "${PACKAGES[@]}"; do
    xbps-install -Sy --yes $pkg
done

# === Generate fstab ===
genfstab -U /mnt > /mnt/etc/fstab

# === Chroot configuration ===
echo "${GREEN}⚡ Entering chroot to finish setup...${RESET}"
chroot /mnt /bin/zsh <<EOF
echo "$hostname" > /etc/hostname
echo "Set root password:"
passwd
useradd -m -G wheel -s /bin/zsh "$username"
echo "Set password for $username:"
passwd "$username"
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
systemctl enable NetworkManager
echo "${GREEN}✅ VoidPunk setup complete! Hyprland is default DE.${RESET}"

echo "${GREEN}⚡ Setting up user dotfiles...${RESET}"
DOTSRC="/home"
DOTDEST="/home/$username"
rsync -a "$DOTSRC/" "$DOTDEST/"
chown -R "$username:$username" "$DOTDEST"
echo "${GREEN}✅ Dotfiles copied to $DOTDEST${RESET}"


EOF
echo "${GREEN}🎉 Installation finished! Reboot to enter your VoidPunk Cyberpunk Desktop.${RESET}"
