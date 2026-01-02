#!/usr/bin/env python3
import os
import sys
import subprocess

def run(cmd):
    print(f"→ {cmd}")
    subprocess.run(cmd, shell=True, check=True)

# ---- ROOT CHECK ----
if os.geteuid() != 0:
    print("❌ Run as root")
    sys.exit(1)

# ---- INTERNET CHECK ----
try:
    run("ping -c 1 archlinux.org")
except:
    print("❌ No internet")
    sys.exit(1)

print("✅ Internet OK")

# ---- ASK DISK ----
run("lsblk")
disk = input("Enter disk (example /dev/sda): ")

confirm = input(f"⚠️ ERASE {disk}? type YES: ")
if confirm != "YES":
    sys.exit(0)

# ---- PARTITION ----
run(f"sgdisk -Z {disk}")
run(f"sgdisk -n 1:0:+512M -t 1:ef00 {disk}")
run(f"sgdisk -n 2:0:0 -t 2:8300 {disk}")

run(f"mkfs.fat -F32 {disk}1")
run(f"mkfs.ext4 {disk}2")

run(f"mount {disk}2 /mnt")
run("mkdir -p /mnt/boot")
run(f"mount {disk}1 /mnt/boot")

# ---- INSTALL BASE ----
run("""
pacstrap /mnt base linux linux-firmware \
networkmanager sudo git vim
""")

run("genfstab -U /mnt >> /mnt/etc/fstab")

# ---- CHROOT ----
run("""
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Asia/Colombo /etc/localtime
hwclock --systohc
systemctl enable NetworkManager
EOF
""")

print("✅ Base system installed")
