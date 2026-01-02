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

# ===========================================
# --- Network Configuration ---
# ===========================================

echo -e "\n${CYAN}╔════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║     Network Configuration          ║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════╝${RESET}\n"

# Detect available interfaces
ETHERNET_IFACE=$(ip link show | grep -E '^[0-9]+: (en|eth)' | awk -F': ' '{print $2}' | head -n1)
WIFI_IFACE=$(ip link show | grep -E '^[0-9]+: wl' | awk -F': ' '{print $2}' | head -n1)

echo -e "${BLUE}Detected interfaces:${RESET}"
[[ -n $ETHERNET_IFACE ]] && echo -e "  ${GREEN}✓${RESET} Ethernet: $ETHERNET_IFACE"
[[ -n $WIFI_IFACE ]] && echo -e "  ${GREEN}✓${RESET} WiFi: $WIFI_IFACE"

# Check if we already have a connection
if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo -e "\n${GREEN}✓ Internet connection detected!${RESET}"
    NETWORK_READY=1
else
    echo -e "\n${YELLOW}⚠ No internet connection detected${RESET}"
    NETWORK_READY=0
fi

# Setup network if needed
if [[ $NETWORK_READY -eq 0 ]]; then
    echo -e "\n${NEON}Select network type:${RESET}"
    echo -e "  ${BOLD}1)${RESET} Ethernet (DHCP)"
    echo -e "  ${BOLD}2)${RESET} WiFi"
    echo -e "  ${BOLD}3)${RESET} Skip (manual configuration)"
    echo -ne "${NEON}Choice [1-3]: ${RESET}"
    read net_choice

    case $net_choice in
        1)
            if [[ -n $ETHERNET_IFACE ]]; then
                echo -e "${CYAN}Configuring Ethernet on $ETHERNET_IFACE...${RESET}"
                ip link set "$ETHERNET_IFACE" up
                dhcpcd "$ETHERNET_IFACE" &
                sleep 3
                
                # Test connection
                if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
                    echo -e "${GREEN}✓ Ethernet connected!${RESET}"
                    NETWORK_READY=1
                else
                    echo -e "${RED}✗ Failed to get DHCP lease${RESET}"
                    echo -e "${YELLOW}Try: dhcpcd $ETHERNET_IFACE manually${RESET}"
                fi
            else
                echo -e "${RED}✗ No Ethernet interface detected${RESET}"
            fi
            ;;
        2)
            if [[ -n $WIFI_IFACE ]]; then
                echo -e "${CYAN}Setting up WiFi...${RESET}"
                ip link set "$WIFI_IFACE" up
                
                # Check for wpa_supplicant or iwd
                if command -v wpa_supplicant &>/dev/null; then
                    echo -e "${BLUE}Using wpa_supplicant${RESET}"
                    echo -ne "${NEON}WiFi SSID: ${RESET}"
                    read wifi_ssid
                    echo -ne "${NEON}WiFi Password: ${RESET}"
                    read -s wifi_pass
                    echo ""
                    
                    # Create wpa_supplicant config
                    wpa_passphrase "$wifi_ssid" "$wifi_pass" > /tmp/wpa.conf
                    
                    # Connect
                    killall wpa_supplicant dhcpcd 2>/dev/null
                    wpa_supplicant -B -i "$WIFI_IFACE" -c /tmp/wpa.conf
                    sleep 3
                    dhcpcd "$WIFI_IFACE" &
                    sleep 5
                    
                    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
                        echo -e "${GREEN}✓ WiFi connected!${RESET}"
                        NETWORK_READY=1
                    else
                        echo -e "${RED}✗ Failed to connect to WiFi${RESET}"
                    fi
                    
                    rm -f /tmp/wpa.conf
                    
                elif command -v iwctl &>/dev/null; then
                    echo -e "${BLUE}Using iwd (iwctl)${RESET}"
                    echo -e "${YELLOW}Run these commands manually:${RESET}"
                    echo -e "  iwctl station $WIFI_IFACE scan"
                    echo -e "  iwctl station $WIFI_IFACE get-networks"
                    echo -e "  iwctl station $WIFI_IFACE connect SSID"
                else
                    echo -e "${RED}✗ No WiFi tools found (need wpa_supplicant or iwd)${RESET}"
                fi
            else
                echo -e "${RED}✗ No WiFi interface detected${RESET}"
            fi
            ;;
        3)
            echo -e "${YELLOW}⚠ Skipping network configuration${RESET}"
            echo -e "${YELLOW}Configure manually before continuing${RESET}"
            ;;
        *)
            echo -e "${RED}Invalid choice${RESET}"
            ;;
    esac
fi

# Final network check
echo -ne "\n${BLUE}Testing connection to voidlinux.org"
for i in {1..3}; do echo -n "."; sleep 0.5; done
echo ""

if ping -c 2 -W 3 voidlinux.org &>/dev/null || ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✓ Network OK! Ready to install.${RESET}\n"
else
    echo -e "${RED}✗ No internet connection!${RESET}"
    echo -e "${YELLOW}Installation requires internet. Please configure network and try again.${RESET}"
    echo -e "\n${CYAN}Quick troubleshooting:${RESET}"
    echo -e "  ${BOLD}Ethernet:${RESET} dhcpcd $ETHERNET_IFACE"
    echo -e "  ${BOLD}WiFi:${RESET} wpa_supplicant -B -i $WIFI_IFACE -c <(wpa_passphrase 'SSID' 'PASS')"
    echo -e "  ${BOLD}Test:${RESET} ping -c 3 8.8.8.8"
    exit 1
fi

# ===========================================
# --- Disk & Partition Selection ---
# ===========================================

echo -e "\n${CYAN}╔════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║     Disk & Partition Setup         ║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════╝${RESET}\n"

echo -e "${MAGENTA}Available disks and partitions:${RESET}"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT

echo -e "\n${NEON}Installation mode:${RESET}"
echo -e "  ${BOLD}1)${RESET} Whole disk - Wipe everything and auto-partition ${RED}(DESTROYS ALL DATA)${RESET}"
echo -e "  ${BOLD}2)${RESET} Auto-partition - Script creates partitions on chosen disk"
echo -e "  ${BOLD}3)${RESET} Manual - I'll choose each partition myself"
echo -ne "\n${NEON}Choice [1-3]: ${RESET}"
read part_choice

case $part_choice in
    1)
        # ===== OPTION 1: WHOLE DISK WIPE + AUTO =====
        echo -e "\n${RED}╔════════════════════════════════════════════╗${RESET}"
        echo -e "${RED}║  WHOLE DISK MODE - WIPES EVERYTHING!      ║${RESET}"
        echo -e "${RED}╚════════════════════════════════════════════╝${RESET}"
        
        while true; do
            echo -ne "\n${NEON}Enter disk to WIPE (e.g., nvme0n1 or /dev/nvme0n1): ${RESET}"
            read disk_input
            [[ $disk_input == /dev/* ]] && disk="$disk_input" || disk="/dev/$disk_input"
            [[ -b "$disk" ]] && break || echo -e "${RED}Invalid disk. Try again.${RESET}"
        done

        echo -e "\n${YELLOW}This will ERASE ALL DATA on $disk!${RESET}"
        echo -ne "Type ${BOLD}YES${RESET} to continue: "
        read confirm
        if [[ $confirm != "YES" ]]; then
            echo -e "${YELLOW}Canceled.${RESET}"
            exit 1
        fi

        echo -e "\n${YELLOW}Wiping $disk...${RESET}"
        dd if=/dev/zero of="$disk" bs=1M count=10 status=progress 2>/dev/null
        sync
        partprobe "$disk" 2>/dev/null
        sleep 2

        echo -e "${CYAN}Creating partitions...${RESET}"
        echo -e "  ${GREEN}•${RESET} 512MB EFI boot"
        echo -e "  ${BLUE}•${RESET} 2GB swap"
        echo -e "  ${MAGENTA}•${RESET} Rest for root"
        
        parted --script "$disk" mklabel gpt
        parted --script "$disk" mkpart primary fat32 1MiB 513MiB
        parted --script "$disk" set 1 boot on
        parted --script "$disk" mkpart primary linux-swap 513MiB 2.5GiB
        parted --script "$disk" mkpart primary ext4 2.5GiB 100%
        sync
        partprobe "$disk" 2>/dev/null
        sleep 3

        if [[ $disk == *"nvme"* ]] || [[ $disk == *"mmcblk"* ]]; then
            part1="${disk}p1"
            part2="${disk}p2"
            part3="${disk}p3"
        else
            part1="${disk}1"
            part2="${disk}2"
            part3="${disk}3"
        fi

        echo -e "${GREEN}✓ Partitions created!${RESET}"
        lsblk "$disk"
        ;;
        
    2)
        # ===== OPTION 2: AUTO-PARTITION (NO WIPE) =====
        echo -e "\n${CYAN}╔════════════════════════════════════════════╗${RESET}"
        echo -e "${CYAN}║  AUTO-PARTITION MODE                       ║${RESET}"
        echo -e "${CYAN}║  Script will create partitions for you     ║${RESET}"
        echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
        
        while true; do
            echo -ne "\n${NEON}Enter disk to partition (e.g., nvme0n1 or /dev/nvme0n1): ${RESET}"
            read disk_input
            [[ $disk_input == /dev/* ]] && disk="$disk_input" || disk="/dev/$disk_input"
            [[ -b "$disk" ]] && break || echo -e "${RED}Invalid disk. Try again.${RESET}"
        done

        echo -e "\n${YELLOW}Current partitions on $disk:${RESET}"
        lsblk "$disk"
        
        echo -e "\n${YELLOW}⚠️  This will create NEW partitions on $disk${RESET}"
        echo -e "${YELLOW}⚠️  Existing data may be lost!${RESET}"
        echo -ne "\nType ${BOLD}YES${RESET} to continue: "
        read confirm
        if [[ $confirm != "YES" ]]; then
            echo -e "${YELLOW}Canceled.${RESET}"
            exit 1
        fi

        echo -e "\n${CYAN}Creating fresh GPT partition table...${RESET}"
        parted --script "$disk" mklabel gpt
        
        echo -e "${CYAN}Creating partitions...${RESET}"
        echo -e "  ${GREEN}•${RESET} 512MB EFI boot"
        echo -e "  ${BLUE}•${RESET} 2GB swap"
        echo -e "  ${MAGENTA}•${RESET} Rest for root"
        
        parted --script "$disk" mkpart primary fat32 1MiB 513MiB
        parted --script "$disk" set 1 boot on
        parted --script "$disk" mkpart primary linux-swap 513MiB 2.5GiB
        parted --script "$disk" mkpart primary ext4 2.5GiB 100%
        sync
        partprobe "$disk" 2>/dev/null
        sleep 3

        if [[ $disk == *"nvme"* ]] || [[ $disk == *"mmcblk"* ]]; then
            part1="${disk}p1"
            part2="${disk}p2"
            part3="${disk}p3"
        else
            part1="${disk}1"
            part2="${disk}2"
            part3="${disk}3"
        fi

        echo -e "${GREEN}✓ Partitions created!${RESET}"
        lsblk "$disk"
        ;;
        
    3)
        # ===== CUSTOM PARTITIONS =====
        echo -e "\n${CYAN}Custom partition mode${RESET}"
        echo -e "Select your existing partitions for installation\n"
        
        echo -e "${BOLD}You need:${RESET}"
        echo -e "  ${GREEN}1.${RESET} Boot/EFI partition (FAT32, ~512MB)"
        echo -e "  ${BLUE}2.${RESET} Swap partition (optional, ~2GB+)"
        echo -e "  ${MAGENTA}3.${RESET} Root partition (ext4, rest of space)"
        echo ""
        
        echo -ne "${NEON}Boot/EFI partition (e.g., nvme0n1p1): ${RESET}"
        read part1_input
        [[ $part1_input == /dev/* ]] && part1="$part1_input" || part1="/dev/$part1_input"
        
        echo -ne "${NEON}Swap partition (e.g., nvme0n1p2 or 'none' to skip): ${RESET}"
        read part2_input
        if [[ $part2_input == "none" ]]; then
            part2=""
        else
            [[ $part2_input == /dev/* ]] && part2="$part2_input" || part2="/dev/$part2_input"
        fi
        
        echo -ne "${NEON}Root partition (e.g., nvme0n1p3): ${RESET}"
        read part3_input
        [[ $part3_input == /dev/* ]] && part3="$part3_input" || part3="/dev/$part3_input"
        
        echo -e "\n${YELLOW}Selected partitions:${RESET}"
        echo -e "  Boot: ${GREEN}$part1${RESET}"
        [[ -n $part2 ]] && echo -e "  Swap: ${BLUE}$part2${RESET}" || echo -e "  Swap: ${YELLOW}none${RESET}"
        echo -e "  Root: ${MAGENTA}$part3${RESET} ${RED}(will be formatted!)${RESET}"
        
        echo -ne "\nType ${BOLD}YES${RESET} to format and install: "
        read confirm
        if [[ $confirm != "YES" ]]; then
            echo -e "${YELLOW}Canceled.${RESET}"
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}Invalid choice. Exiting.${RESET}"
        exit 1
        ;;
esac

# --- Format & Mount ---
echo -e "\n${GREEN}Formatting partitions...${RESET} 💾"
mkfs.fat -F32 "$part1"

if [[ -n $part2 ]]; then
    mkswap "$part2"
    swapon "$part2"
fi

mkfs.ext4 -F "$part3"

echo -e "${GREEN}Mounting partitions...${RESET}"
mount "$part3" /mnt
mkdir -p /mnt/boot
mount "$part1" /mnt/boot

echo -e "${GREEN}✓ Partitions ready!${RESET}"
lsblk | grep -E "$(basename $part1)|$(basename $part2)|$(basename $part3)"

# --- Package selection ---
PACKAGES=(base-system linux grub-x86_64-efi efibootmgr xbps sudo git zsh NetworkManager dhcpcd wpa_supplicant)

echo -e "\n${CYAN}📦 Customize your packages!${RESET}"

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

echo -e "\n${CYAN}📦 Installing packages:${RESET}"
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
FSTAB_END

if [[ -n $part2 ]]; then
    echo "UUID=$(blkid -s UUID -o value "$part2")  none    swap    sw              0 0" >> /mnt/etc/fstab
fi

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

# Execute chroot script
chroot /mnt /usr/bin/env \
    CHROOT_USERNAME="$username" \
    CHROOT_HOSTNAME="$hostname" \
    /bin/bash /root/chroot_setup.sh

# Cleanup
rm /mnt/root/chroot_setup.sh

echo -e "\n${GREEN}🎉 Installation finished!${RESET}"
echo -e "${YELLOW}Default password for root and $username: voidpunk${RESET}"
echo -e "${RED}⚠️ CHANGE PASSWORDS AFTER FIRST BOOT! ⚠️${RESET}"
echo -e "${CYAN}Reboot and remove installation media.${RESET}\n"