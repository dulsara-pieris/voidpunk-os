#!/bin/zsh
# =============================================
# Root .zshrc for VoidPunk OS Installer
# Theme: Cyberpunk
# Fully CLI, guided experience
# =============================================

autoload -U colors && colors
# Cyberpunk neon colors
NEON_PINK=$fg[magenta]
NEON_BLUE=$fg[blue]
NEON_CYAN=$fg[cyan]
NEON_GREEN=$fg[green]
NEON_YELLOW=$fg[yellow]
NEON_RED=$fg[red]
RESET=$reset

echo "${NEON_CYAN}============================================${RESET}"
echo "${NEON_PINK}  Welcome to the VoidPunk Cyberpunk Installer${RESET}"
echo "${NEON_CYAN}============================================${RESET}"

# --------- Basic System Setup ---------
read -p "${NEON_YELLOW}Enter target disk [/dev/sda]: ${RESET}" DISK
DISK=${DISK:-/dev/sda}

read -p "${NEON_YELLOW}Enter filesystem type (ext4/btrfs/xfs/f2fs/reiserfs) [ext4]: ${RESET}" FILE_SYSTEM_TYPE
FILE_SYSTEM_TYPE=${FILE_SYSTEM_TYPE:-ext4}

read -p "${NEON_YELLOW}Enter username [voidpunk]: ${RESET}" USERNAME
USERNAME=${USERNAME:-voidpunk}

read -s -p "${NEON_YELLOW}Enter password [voidpunk]: ${RESET}" PASSWORD
echo
PASSWORD=${PASSWORD:-voidpunk}

read -p "${NEON_YELLOW}Enter hostname [voidpunk]: ${RESET}" HOSTNAME
HOSTNAME=${HOSTNAME:-voidpunk}

read -p "${NEON_YELLOW}Enter locale [en_US.UTF-8]: ${RESET}" LOCALE
LOCALE=${LOCALE:-en_US.UTF-8}

read -p "${NEON_YELLOW}Enter timezone [Asia/Colombo]: ${RESET}" TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Colombo}

# --------- User Experience Choices ---------
echo "${NEON_CYAN}--- Choose your Code Editor ---${RESET}"
echo "${NEON_PINK}Options: vim, nano, neovim, emacs${RESET}"
read -p "${NEON_YELLOW}Default code editor [vim]: ${RESET}" CODE_EDITOR
CODE_EDITOR=${CODE_EDITOR:-vim}

echo "${NEON_CYAN}--- Choose your Text Editor ---${RESET}"
echo "${NEON_PINK}Options: nano, micro, leafpad${RESET}"
read -p "${NEON_YELLOW}Default text editor [nano]: ${RESET}" TEXT_EDITOR
TEXT_EDITOR=${TEXT_EDITOR:-nano}

echo "${NEON_CYAN}--- Choose your Media Player ---${RESET}"
echo "${NEON_PINK}Options: mpv, vlc, audacious${RESET}"
read -p "${NEON_YELLOW}Default media player [mpv]: ${RESET}" MEDIA_PLAYER
MEDIA_PLAYER=${MEDIA_PLAYER:-mpv}

echo "${NEON_CYAN}--- Optional Packages ---${RESET}"
read -p "${NEON_YELLOW}Enter other packages (space-separated) [base linux linux-firmware sudo git]: ${RESET}" PACKAGES
PACKAGES=${PACKAGES:-"base linux linux-firmware sudo git"}

# --------- Show Summary ---------
echo "${NEON_GREEN}✅ Setup complete! Here are your selections:${RESET}"
echo "${NEON_CYAN}Disk: ${DISK}${RESET}"
echo "${NEON_CYAN}Filesystem: ${FILE_SYSTEM_TYPE}${RESET}"
echo "${NEON_CYAN}User: ${USERNAME}${RESET}"
echo "${NEON_CYAN}Hostname: ${HOSTNAME}${RESET}"
echo "${NEON_CYAN}Locale: ${LOCALE}${RESET}"
echo "${NEON_CYAN}Timezone: ${TIMEZONE}${RESET}"
echo "${NEON_CYAN}Code Editor: ${CODE_EDITOR}${RESET}"
echo "${NEON_CYAN}Text Editor: ${TEXT_EDITOR}${RESET}"
echo "${NEON_CYAN}Media Player: ${MEDIA_PLAYER}${RESET}"
echo "${NEON_CYAN}Packages: ${PACKAGES}${RESET}"

# --------- Export variables for installer script ---------
export DISK FILE_SYSTEM_TYPE USERNAME PASSWORD HOSTNAME LOCALE TIMEZONE
export CODE_EDITOR TEXT_EDITOR MEDIA_PLAYER PACKAGES
