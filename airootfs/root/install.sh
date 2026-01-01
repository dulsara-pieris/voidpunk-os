#!/bin/zsh

# =============================================
#        VoidPunk Cyberpunk Installer
#        Hyprland default DE
# =============================================
clear
autoload -U colors && colors

# --- Neon palette ---
GREEN=$fg_bold[green]; RED=$fg_bold[red]; YELLOW=$fg_bold[yellow]
BLUE=$fg_bold[blue]; MAGENTA=$fg_bold[magenta]; CYAN=$fg_bold[cyan]
NEON=$fg_bold[magenta]; BOLD=$fg_bold[white]; RESET=$reset_color

# --- Cyberpunk ASCII banner ---
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

# --- Flicker effect ---
for _ in {1..2}; do
    for i in $(seq 1 ${#banner[@]}); do
        idx=$(( RANDOM % ${#COLORS[@]} + 1 ))
        color=${COLORS[$idx]}
        echo "${color}${banner[$i]}${RESET}"
    done
    sleep 0.8
    tput cuu $((${#banner[@]}))
done

# --- Final static banner ---
for i in $(seq 1 ${#banner[@]}); do
    idx=$(( i % ${#COLORS[@]} + 1 ))
    color=${COLORS[$idx]}
    echo "${color}${banner[$i]}${RESET}"
done

# --- Animated initializing message ---
msg="${BOLD}⚡ Initializing VoidPunk Cyberpunk Installer... ⚡${RESET}"
for ((i=0; i<${#msg}; i++)); do
    echo -n "${msg:$i:1}"
    sleep 0.03
done
echo ""

# --- Ask for username and hostname ---
echo -n "${NEON}Enter your new username: ${RESET}"
read username
echo -n "${NEON}Enter your system hostname: ${RESET}"
read hostname

# Export for chroot usage
export USERNAME="$username"
export HOSTNAME="$hostname"

# --- Check network ---
echo -n "${BLUE}Checking network"
for i in {1..3}; do echo -n "."; sleep 0.5; done
echo ""
ping -c 1 voidlinux.org &>/dev/null && echo "${GREEN}Network OK!${RESET}" || { echo "${RED}No network!${RESET}"; exit 1; }

# --- Select disk safely ---
echo "${MAGENTA}Available disks:${RESET}"
lsblk
while true; do
    echo -n "${NEON}Enter the disk to install VoidPunk (e.g., /dev/sda): ${RESET}"
    read disk
    [[ -b "$disk" ]] && break || echo "${RED}Invalid disk. Try again.${RESET}"
done

echo "${RED}⚠️ All data on $disk will be erased! ⚠️${RESET}"
echo -n "Type ${BOLD}YES${RESET} to continue: "
read confirm
[[ $confirm != YES ]] && { echo "${YELLOW}Canceled.${RESET}"; exit 1; }

# --- Wipe old partition table (important for disks with Manjaro/other OS) ---
echo "${YELLOW}Wiping old partition table on $disk...${RESET}"
dd if=/dev/zero of="$disk" bs=1M count=10 status=progress
partprobe "$disk"

# --- Partitioning ---
echo "${CYAN}Partitioning $disk...${RESET}"
parted --script "$disk" mklabel gpt
parted --script "$disk" mkpart primary fat32 1MiB 513MiB
parted --script "$disk" set 1 boot on
parted --script "$disk" mkpart primary linux-swap 513MiB 2.5GiB
parted --script "$disk" mkpart primary ext4 2.5GiB 100%
echo "${GREEN}Partitioning complete!${RESET}"

# --- Progress bar ---
echo -n "${BLUE}["
for i in {1..20}; do echo -n "#"; sleep 0.05; done
echo "] Done"

# --- Format & Mount ---
echo "${GREEN}Formatting partitions...${RESET} 💾"
mkfs.fat -F32 "${disk}1"
mkswap "${disk}2"
swapon "${disk}2"
mkfs.ext4 "${disk}3"

echo "${GREEN}Mounting partitions...${RESET}"
mount "${disk}3" /mnt
mkdir -p /mnt/boot
mount "${disk}1" /mnt/boot

# --- Package selection ---
PACKAGES=(base-system xbps xbps-src sudo git zsh networkmanager)

echo "${CYAN}📦 Customize your packages!${RESET}"

echo -n "${NEON}Editors (vim nano emacs) ?: ${RESET}"
read editors
[[ -n $editors ]] && PACKAGES+=($editors)

echo -n "${NEON}Browsers (firefox chromium qutebrowser) ?: ${RESET}"
read browsers
[[ -n $browsers ]] && PACKAGES+=($browsers)

echo -n "${NEON}Utilities (htop neofetch tmux ranger) ?: ${RESET}"
read utils
[[ -n $utils ]] && PACKAGES+=($utils)

# Hyprland DE default packages
PACKAGES+=(hyprland waybar wofi mako swaybg foot grim slurp wl-clipboard)

echo "${CYAN}📦 Installing packages:${RESET}"
echo "${PACKAGES[@]}"

echo -n "${CYAN}Installing "
for i in {1..10}; do echo -n "⚡"; sleep 0.1; done
echo ""

# Install packages
for pkg in "${PACKAGES[@]}"; do
    xbps-install -Sy --yes "$pkg"
done

# --- Generate fstab ---
genfstab -U /mnt > /mnt/etc/fstab

# --- Chroot configuration ---
echo "${GREEN}⚡ Entering chroot to finish setup...${RESET}"

chroot /mnt /bin/zsh <<'EOF'
echo "$HOSTNAME" > /etc/hostname

echo "Set root password:"
passwd

useradd -m -G wheel -s /bin/zsh "$USERNAME"
echo "Set password for $USERNAME:"
passwd "$USERNAME"

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager

# --- Copy dotfiles ---
DOTSRC="/root/home"  # Adjust to ISO dotfiles location
DOTDEST="/home/$USERNAME"
if [ -d "$DOTSRC" ]; then
    rsync -a "$DOTSRC/" "$DOTDEST/"
    chown -R "$USERNAME:$USERNAME" "$DOTDEST"
    echo "✅ Dotfiles copied to $DOTDEST"
else
    echo "⚠️ Dotfiles source $DOTSRC not found, skipping."
fi

echo "✅ VoidPunk setup complete! Hyprland is default DE."
EOF

echo "${GREEN}🎉 Installation finished! Reboot to enter $username's VoidPunk Cyberpunk Desktop.${RESET}"
