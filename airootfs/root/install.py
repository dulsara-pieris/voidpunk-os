#!/usr/bin/env python3
import os
import subprocess
import sys

def run(cmd):
    print(f"\n>> {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def ask(msg):
    return input(f"{msg}: ").strip()

def yesno(msg):
    return ask(msg).lower() == "yes"

def disks():
    run("lsblk")

def check_uefi():
    if not os.path.exists("/sys/firmware/efi"):
        print("❌ UEFI system required")
        sys.exit(1)

### ===============================
### CONFIG
### ===============================
OS_NAME = "VoidPunk"
TIMEZONE = "Asia/Colombo"
LOCALE = "en_US.UTF-8"

### ===============================
### START
### ===============================
check_uefi()
run("timedatectl set-ntp true")

print(f"\n==== {OS_NAME} Installer ====")
print("1) Full disk wipe (auto partition)")
print("2) Manual partition sizes")
print("3) Use existing partitions")

mode = ask("Select mode (1/2/3)")
disks()
disk = ask("Target disk (example /dev/sda)")

if mode != "3":
    print(f"\n⚠️ THIS WILL ERASE {disk}")
    if not yesno("Type YES to continue"):
        sys.exit(1)

efi = root = home = swap = None

### ===============================
### MODE 1 – AUTO
### ===============================
if mode == "1":
    run(f"sgdisk --zap-all {disk}")
    run(f"sgdisk -n 1:0:+512M -t 1:ef00 {disk}")   # EFI
    run(f"sgdisk -n 2:0:+4G -t 2:8200 {disk}")     # Swap
    run(f"sgdisk -n 3:0:0 -t 3:8300 {disk}")       # Root

    efi  = f"{disk}1"
    swap = f"{disk}2"
    root = f"{disk}3"

### ===============================
### MODE 2 – MANUAL
### ===============================
elif mode == "2":
    efi_size  = ask("EFI size (512M)")
    swap_size = ask("Swap size (4G)")
    root_size = ask("Root size (rest=0)")

    run(f"sgdisk --zap-all {disk}")
    run(f"sgdisk -n 1:0:+{efi_size} -t 1:ef00 {disk}")
    run(f"sgdisk -n 2:0:+{swap_size} -t 2:8200 {disk}")
    run(f"sgdisk -n 3:0:{root_size or 0} -t 3:8300 {disk}")

    efi  = f"{disk}1"
    swap = f"{disk}2"
    root = f"{disk}3"

### ===============================
### MODE 3 – EXISTING
### ===============================
elif mode == "3":
    disks()
    efi  = ask("EFI partition")
    root = ask("Root partition")
    swap = ask("Swap partition (or leave blank)")

else:
    sys.exit(1)

### ===============================
### FORMAT
### ===============================
run(f"mkfs.fat -F32 {efi}")
run(f"mkfs.ext4 -F {root}")

if swap:
    run(f"mkswap {swap}")
    run(f"swapon {swap}")

### ===============================
### MOUNT
### ===============================
run(f"mount {root} /mnt")
run("mkdir -p /mnt/boot/efi")
run(f"mount {efi} /mnt/boot/efi")

### ===============================
### INSTALL BASE
### ===============================
run("""
pacstrap /mnt \
base linux linux-firmware \
networkmanager sudo nano grub efibootmgr
""")

run("genfstab -U /mnt >> /mnt/etc/fstab")

### ===============================
### USER SETUP
### ===============================
hostname = ask("Hostname")
username = ask("Username")
password = ask("Password")

### ===============================
### CHROOT CONFIG
### ===============================
chroot_cmd = f"""
ln -sf /usr/share/zoneinfo/{TIMEZONE} /etc/localtime
hwclock --systohc

sed -i 's/#{LOCALE} UTF-8/{LOCALE} UTF-8/' /etc/locale.gen
locale-gen

echo "LANG={LOCALE}" > /etc/locale.conf
echo "{hostname}" > /etc/hostname

cat <<EOF > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 {hostname}.localdomain {hostname}
EOF

echo "root:{password}" | chpasswd
useradd -m -G wheel -s /bin/bash {username}
echo "{username}:{password}" | chpasswd

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id={OS_NAME}
grub-mkconfig -o /boot/grub/grub.cfg
"""

run(f"arch-chroot /mnt /bin/bash -c '{chroot_cmd}'")

### ===============================
### FINISH
### ===============================
run("umount -R /mnt")
print(f"\n✅ {OS_NAME} installed successfully!")
print("👉 Reboot now")
