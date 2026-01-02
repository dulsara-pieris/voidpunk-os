#!/bin/bash

# =============================================
#        VoidPunk Cyberpunk Installer
#        Hyprland default DE
# =============================================
clear

# --- Neon palette (ANSI codes for portability) ---
GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
NEON='\033[1;35m'; BOLD='\033[1;37m'; RESET='\033[0m'

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
COLORS=('\033[1;36m' '\033[1;35m' '\033[1;34m' '\033[1;33m' '\033[1;32m' '\033[1;31m')

# --- Flicker effect ---
for _ in {1..2}; do
    for i in "${!banner[@]}"; do
        idx=$((RANDOM % ${#COLORS[@]}))
        color=${COLORS[$idx]}
        echo -e "${color}${banner[$i]}${RESET}"
    done
    sleep 0.8
    tput cuu ${#banner[@]}
done

# --- Final static banner ---
for i in "${!banner[@]}"; do
    idx=$((i % ${#COLORS[@]}))
    color=${COLORS[$idx]}
    echo -e "${color}${banner[$i]}${RESET}"
done

# --- Animated initializing message ---
msg="⚡ Initializing VoidPunk Cyberpunk Installer... ⚡"
echo -ne "${BOLD}"
for ((i=0; i<${#msg}; i++)); do
    echo -n "${msg:$i:1}"
    sleep 0.03
done
echo -e "${RESET}\n"

# --- Ask for username and hostname ---
echo -ne "${NEON}Enter your new username: ${RESET}"
read username
echo -ne "${NEON}Enter your system hostname: ${RESET}"
read hostname

# --- Check network ---
echo -ne "${BLUE}Checking network"
for i in {1..3}; do echo -n "."; sleep 0.5; done
echo ""
if ping -c 1 voidlinux.org &>/dev/null; then
    echo -e "${GREEN}Network OK!${RESET}"
else
    echo -e "${RED}No network!${RESET}"
    exit 1
fi

# --- Select disk safely ---
echo -e "${MAGENTA}Available disks:${RESET}"
lsblk -d -o NAME,SIZE,TYPE | grep disk
while true; do
    echo -ne "${NEON}Enter the disk to install VoidPunk (e.g., /dev/sda): ${RESET}"
    read disk
    [[ -b "$disk" ]] && break || echo -e "${RED}Invalid disk. Try again.${RESET}"
done

echo -e "${RED}⚠️ All data on $disk will be erased! ⚠️${RESET}"
echo -ne "Type ${BOLD}YES${RESET} to continue: "
read confirm
if [[ $confirm != "YES" ]]; then
    echo -e "${YELLOW}Canceled.${RESET}"
    exit 1
fi

# --- Wipe old partition table ---
echo -e "${YELLOW}Wiping old partition table on $disk...${RESET}"
dd if=/dev/zero of="$disk" bs=1M count=10 status=progress 2>/dev/null
sync
partprobe "$disk" 2>/dev/null
sleep 2

# --- Partitioning ---
echo -e "${CYAN}Partitioning $disk...${RESET}"
parted --script "$disk" mklabel gpt
parted --script "$disk" mkpart primary fat32 1MiB 513MiB
parted --script "$disk" set 1 boot on
parted --script "$disk" mkpart primary linux-swap 513MiB 2.5GiB
parted --script "$disk" mkpart primary ext4 2.5GiB 100%
sync
partprobe "$disk" 2>/dev/null
sleep 2
echo -e "${GREEN}Partitioning complete!${RESET}"

# --- Progress bar ---
echo -ne "${BLUE}["
for i in {1..20}; do echo -n "#"; sleep 0.05; done
echo -e "] Done${RESET}"

# --- Detect partition naming scheme ---
if [[ $disk == *"nvme"* ]] || [[ $disk == *"mmcblk"* ]]; then
    part1="${disk}p1"
    part2="${disk}p2"
    part3="${disk}p3"
else
    part1="${disk}1"
    part2="${disk}2"
    part3="${disk}3"
fi

# --- Format & Mount ---
echo -e "${GREEN}Formatting partitions...${RESET} 💾"
mkfs.fat -F32 "$part1"
mkswap "$part2"
swapon "$part2"
mkfs.ext4 -F "$part3"

echo -e "${GREEN}Mounting partitions...${RESET}"
mount "$part3" /mnt
mkdir -p /mnt/boot
mount "$part1" /mnt/boot

# --- Package selection ---
PACKAGES=(base-system linux grub-x86_64-efi efibootmgr xbps sudo git zsh NetworkManager)

echo -e "${CYAN}📦 Customize your packages!${RESET}"

echo -ne "${NEON}Editors (vim nano emacs) ?: ${RESET}"
read editors
[[ -n $editors ]] && PACKAGES+=($editors)

echo -ne "${NEON}Browsers (firefox chromium) ?: ${RESET}"
read browsers
[[ -n $browsers ]] && PACKAGES+=($browsers)

echo -ne "${NEON}Utilities (htop neofetch tmux ranger) ?: ${RESET}"
read utils
[[ -n $utils ]] && PACKAGES+=($utils)

# Hyprland DE default packages
PACKAGES+=(hyprland waybar wofi mako swaybg foot grim slurp wl-clipboard polkit)

echo -e "${CYAN}📦 Installing packages:${RESET}"
echo "${PACKAGES[@]}"

echo -ne "${CYAN}Installing "
for i in {1..10}; do echo -n "⚡"; sleep 0.1; done
echo -e "${RESET}"

# --- Copy RSA keys for package installation ---
mkdir -p /mnt/var/db/xbps/keys
cp -a /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

# Install base system
XBPS_ARCH=x86_64 xbps-install -Sy -r /mnt -R https://repo-default.voidlinux.org/current "${PACKAGES[@]}"

# --- Generate fstab ---
echo -e "${GREEN}Generating fstab...${RESET}"
cat > /mnt/etc/fstab << FSTAB_END
# /etc/fstab: static file system information
UUID=$(blkid -s UUID -o value "$part3")  /       ext4    defaults        0 1
UUID=$(blkid -s UUID -o value "$part1")  /boot   vfat    defaults        0 2
UUID=$(blkid -s UUID -o value "$part2")  none    swap    sw              0 0
FSTAB_END

# --- Chroot configuration ---
echo -e "${GREEN}⚡ Entering chroot to finish setup...${RESET}"

cat > /mnt/root/chroot_setup.sh << 'CHROOT_SCRIPT'
#!/bin/bash

# Set hostname
echo "$CHROOT_HOSTNAME" > /etc/hostname

# Set root password
echo "Setting root password..."
echo "root:voidpunk" | chpasswd
echo "✅ Root password set to: voidpunk (CHANGE THIS AFTER FIRST BOOT!)"

# Create user
useradd -m -G wheel -s /bin/bash "$CHROOT_USERNAME"
echo "$CHROOT_USERNAME:voidpunk" | chpasswd
echo "✅ User $CHROOT_USERNAME password set to: voidpunk"

# Enable sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable services
ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/

# Install and configure GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=VoidPunk --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Configure locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

# Copy dotfiles if available
DOTSRC="/root/dotfiles"
DOTDEST="/home/$CHROOT_USERNAME"
if [ -d "$DOTSRC" ]; then
    cp -r "$DOTSRC/.config" "$DOTDEST/" 2>/dev/null
    cp "$DOTSRC/.bashrc" "$DOTDEST/" 2>/dev/null
    cp "$DOTSRC/.zshrc" "$DOTDEST/" 2>/dev/null
    chown -R "$CHROOT_USERNAME:$CHROOT_USERNAME" "$DOTDEST"
    echo "✅ Dotfiles copied"
else
    echo "⚠️ No dotfiles found at $DOTSRC"
fi

echo "✅ VoidPunk setup complete! Hyprland is default DE."
CHROOT_SCRIPT

chmod +x /mnt/root/chroot_setup.sh

# Export variables for chroot
export CHROOT_USERNAME="$username"
export CHROOT_HOSTNAME="$hostname"

# Execute chroot script
chroot /mnt /usr/bin/env \
    CHROOT_USERNAME="$username" \
    CHROOT_HOSTNAME="$hostname" \
    /bin/bash /root/chroot_setup.sh

# Cleanup
rm /mnt/root/chroot_setup.sh

echo -e "${GREEN}🎉 Installation finished!${RESET}"
echo -e "${YELLOW}Default password for root and $username: voidpunk${RESET}"
echo -e "${RED}⚠️ CHANGE PASSWORDS AFTER FIRST BOOT! ⚠️${RESET}"
echo -e "${CYAN}Reboot and remove installation media.${RESET}"