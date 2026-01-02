#!/usr/bin/env bash
set -euo pipefail

echo "============================"
echo " Arch Linux Automated Installer "
echo "============================"

read -rp "Enter EFI partition (e.g., /dev/sda1 or /dev/nvme0n1p1): " EFI
read -rp "Enter Root (/) partition (e.g., /dev/sda3): " ROOT
read -rp "Enter Username: " USER
read -rp "Enter Full Name: " NAME
read -rsp "Enter Password: " PASSWORD
echo

# -------------------------------
# Filesystem creation
# -------------------------------
echo -e "\nCreating filesystems...\n"

if ! blkid "$EFI" | grep -q "vfat"; then
    echo "Formatting EFI partition as FAT32..."
    mkfs.vfat -F32 "$EFI"
else
    echo "EFI partition already formatted."
fi

echo "Formatting root partition as ext4..."
mkfs.ext4 "$ROOT"

# -------------------------------
# Mounting
# -------------------------------
mount "$ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI" /mnt/boot/efi

# -------------------------------
# Install base system
# -------------------------------
echo "--------------------------------------"
echo "-- Installing base system --"
echo "--------------------------------------"

pacstrap /mnt base base-devel linux linux-firmware linux-headers \
    networkmanager wireless_tools nano intel-ucode bluez bluez-utils git --noconfirm --needed

# -------------------------------
# Generate fstab
# -------------------------------
genfstab -U /mnt >> /mnt/etc/fstab

# -------------------------------
# Arch-chroot configuration
# -------------------------------
arch-chroot /mnt /bin/bash <<EOF
set -e

# -------------------------------
# User setup
# -------------------------------
useradd -m -G wheel,storage,power,audio,video "$USER"
usermod -c "$NAME" "$USER"
echo "$USER:$PASSWORD" | chpasswd

# Allow wheel group to sudo without password
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# -------------------------------
# Localization & timezone
# -------------------------------
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc

# -------------------------------
# Hostname & hosts
# -------------------------------
echo "asus-f15" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1	localhost
::1		localhost
127.0.1.1	asus-f15.localdomain	asus-f15
127.0.0.1   front1.rms.local
192.168.0.124 front1.rms
127.0.0.1   front1.ims.local
192.168.0.153 front1.ims
127.0.0.1   front1.dpms.local
192.168.0.164 front1.dpms
HOSTS

# -------------------------------
# Audio & Graphics drivers
# -------------------------------
pacman -S --noconfirm --needed mesa-utils nvidia nvidia-utils nvidia-settings opencl-nvidia nvidia-prime \
    pipewire pipewire-alsa pipewire-pulse

# Enable services
systemctl enable NetworkManager bluetooth
systemctl --user enable pipewire pipewire-pulse

# -------------------------------
# Bootloader
# -------------------------------
pacman -S --noconfirm --needed grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Linux Boot Manager" \
    --modules="normal test efi_gop efi_uga search echo linux all_video gfxmenu gfxterm_background gfxterm_menu gfxterm loadenv configfile tpm" \
    --disable-shim-lock
grub-mkconfig -o /boot/grub/grub.cfg

# -------------------------------
# Optional: dotfiles clone
# -------------------------------
cd /home/$USER
sudo -u $USER git clone https://github.com/sandipsky/dotfiles

EOF

echo "--------------------------------------"
echo "Installation complete! You can reboot now."
echo "--------------------------------------"
