#!/usr/bin/env python3
"""
Ultimate Arch Linux Developer Installer
Hyprland-focused with complete customization for the perfect dev experience
No external dependencies required - pure Python + system commands
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

class DevArchInstaller:
    def __init__(self):
        self.config = {
            'desktop_environment': 'hyprland',
            'animations_enabled': True
        }
        self.config_file = 'dev_arch_config.json'
        
    def run_cmd(self, cmd: List[str], check: bool = True, capture: bool = False) -> subprocess.CompletedProcess:
        """Run a system command"""
        try:
            if capture:
                return subprocess.run(cmd, capture_output=True, text=True, check=check)
            else:
                return subprocess.run(cmd, check=check)
        except subprocess.CalledProcessError as e:
            if check:
                raise
            return e
    
    def animate_text(self, text: str, delay: float = 0.03):
        """Animate text output"""
        for char in text:
            print(char, end='', flush=True)
            time.sleep(delay)
        print()
    
    def clear_screen(self):
        os.system('clear')
        
    def print_banner(self):
        banner = f"""
{Colors.CYAN}╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     █████╗ ██████╗  ██████╗██╗  ██╗    ██████╗ ███████╗██╗  ║
║    ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔══██╗██╔════╝██║  ║
║    ███████║██████╔╝██║     ███████║    ██║  ██║█████╗  ██║  ║
║    ██╔══██║██╔══██╗██║     ██╔══██║    ██║  ██║██╔══╝  ╚═╝  ║
║    ██║  ██║██║  ██║╚██████╗██║  ██║    ██████╔╝███████╗██╗  ║
║    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═╝  ║
║                                                              ║
║        Ultimate Developer Installation Experience           ║
║              Powered by Hyprland + Wayland                  ║
╚══════════════════════════════════════════════════════════════╝{Colors.END}
"""
        print(banner)
        time.sleep(0.5)
        
    def print_header(self, text: str):
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'═'*60}")
        print(f"  {text}")
        print(f"{'═'*60}{Colors.END}\n")
        
    def print_step(self, step: str, status: str = ""):
        if status == "success":
            icon = f"{Colors.GREEN}✓{Colors.END}"
        elif status == "error":
            icon = f"{Colors.RED}✗{Colors.END}"
        elif status == "warning":
            icon = f"{Colors.YELLOW}⚠{Colors.END}"
        else:
            icon = f"{Colors.CYAN}•{Colors.END}"
        
        print(f"{icon} {step}")
    
    def get_disks(self) -> List[Dict]:
        """Get list of available disks"""
        disks = []
        try:
            result = self.run_cmd(['lsblk', '-ndo', 'NAME,SIZE,TYPE'], capture=True)
            for line in result.stdout.strip().split('\n'):
                parts = line.split()
                if len(parts) >= 3 and parts[2] == 'disk':
                    disks.append({
                        'name': parts[0],
                        'path': f'/dev/{parts[0]}',
                        'size': parts[1]
                    })
        except:
            pass
        return disks
    
    def check_internet(self) -> bool:
        """Check internet connectivity"""
        try:
            self.run_cmd(['ping', '-c', '1', '-W', '2', '8.8.8.8'], check=True, capture=True)
            return True
        except:
            return False
    
    def setup_network(self):
        self.print_header("Network Configuration")
        
        if self.check_internet():
            self.print_step("Internet connection detected", "success")
            use_current = input(f"\n{Colors.CYAN}Use current network? (Y/n):{Colors.END} ").strip().lower()
            if use_current != 'n':
                self.config['network_configured'] = True
                return
        else:
            self.print_step("No internet connection detected", "warning")
        
        print(f"\n{Colors.BOLD}Network Options:{Colors.END}")
        print("1. 🔌 Ethernet (DHCP)")
        print("2. 📡 WiFi")
        print("3. ⚙️  Manual IP Configuration")
        print("4. ⏭️  Skip (configure later)")
        
        choice = input(f"\n{Colors.CYAN}Select (1-4):{Colors.END} ").strip()
        
        if choice == '1':
            self.setup_ethernet()
        elif choice == '2':
            self.setup_wifi()
        elif choice == '3':
            self.setup_manual_network()
        else:
            self.print_step("Network configuration skipped", "warning")
            self.config['network_configured'] = False
    
    def setup_ethernet(self):
        self.print_step("Configuring Ethernet...")
        try:
            result = self.run_cmd(['ip', 'link', 'show'], capture=True)
            print(f"\n{Colors.CYAN}Available interfaces:{Colors.END}")
            print(result.stdout)
            
            interface = input(f"\n{Colors.CYAN}Interface [enp0s3]:{Colors.END} ").strip() or 'enp0s3'
            
            self.run_cmd(['ip', 'link', 'set', interface, 'up'])
            self.run_cmd(['dhcpcd', interface], check=False)
            
            time.sleep(2)
            self.print_step(f"Ethernet configured on {interface}", "success")
            self.config['network_type'] = 'ethernet'
            self.config['network_interface'] = interface
            self.config['network_configured'] = True
        except Exception as e:
            self.print_step(f"Error: {e}", "error")
            self.config['network_configured'] = False
    
    def setup_wifi(self):
        self.print_step("Configuring WiFi...")
        try:
            # Scan networks
            self.run_cmd(['iwctl', 'station', 'wlan0', 'scan'], check=False)
            time.sleep(2)
            
            print(f"\n{Colors.CYAN}Available networks:{Colors.END}")
            result = self.run_cmd(['iwctl', 'station', 'wlan0', 'get-networks'], capture=True, check=False)
            print(result.stdout)
            
            ssid = input(f"\n{Colors.CYAN}WiFi SSID:{Colors.END} ").strip()
            password = input(f"{Colors.CYAN}Password:{Colors.END} ").strip()
            
            # Connect
            proc = subprocess.Popen(['iwctl', '--passphrase', password, 
                                   'station', 'wlan0', 'connect', ssid],
                                  stdin=subprocess.PIPE)
            proc.communicate()
            
            time.sleep(3)
            if self.check_internet():
                self.print_step(f"Connected to {ssid}", "success")
                self.config['network_type'] = 'wifi'
                self.config['wifi_ssid'] = ssid
                self.config['wifi_password'] = password
                self.config['network_configured'] = True
            else:
                self.print_step("Connection failed", "error")
                self.config['network_configured'] = False
        except Exception as e:
            self.print_step(f"Error: {e}", "error")
            self.config['network_configured'] = False
    
    def setup_manual_network(self):
        self.print_step("Manual Network Configuration")
        
        interface = input(f"{Colors.CYAN}Interface:{Colors.END} ").strip()
        ip_address = input(f"{Colors.CYAN}IP Address (CIDR, e.g. 192.168.1.100/24):{Colors.END} ").strip()
        gateway = input(f"{Colors.CYAN}Gateway:{Colors.END} ").strip()
        dns = input(f"{Colors.CYAN}DNS servers (comma-separated) [8.8.8.8,1.1.1.1]:{Colors.END} ").strip() or '8.8.8.8,1.1.1.1'
        
        try:
            self.run_cmd(['ip', 'link', 'set', interface, 'up'])
            self.run_cmd(['ip', 'addr', 'add', ip_address, 'dev', interface])
            self.run_cmd(['ip', 'route', 'add', 'default', 'via', gateway])
            
            with open('/etc/resolv.conf', 'w') as f:
                for dns_server in dns.split(','):
                    f.write(f"nameserver {dns_server.strip()}\n")
            
            time.sleep(1)
            if self.check_internet():
                self.print_step("Network configured successfully", "success")
                self.config['network_type'] = 'manual'
                self.config['network_interface'] = interface
                self.config['network_ip'] = ip_address
                self.config['network_gateway'] = gateway
                self.config['network_dns'] = dns
                self.config['network_configured'] = True
            else:
                self.print_step("Network configured but no internet", "warning")
                self.config['network_configured'] = False
        except Exception as e:
            self.print_step(f"Error: {e}", "error")
            self.config['network_configured'] = False
    
    def configure_storage(self):
        self.print_header("Storage Configuration")
        
        self.print_step("Detecting storage devices...")
        
        try:
            result = self.run_cmd(['lsblk', '-o', 'NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT'], capture=True)
            print(f"\n{Colors.CYAN}Available disks:{Colors.END}")
            print(result.stdout)
        except:
            pass
        
        disks = self.get_disks()
        
        if not disks:
            self.print_step("No disks found!", "error")
            sys.exit(1)
        
        print(f"\n{Colors.BOLD}Storage Devices:{Colors.END}")
        for i, disk in enumerate(disks, 1):
            print(f"  {i}. {disk['path']} ({disk['size']})")
        
        disk_choice = int(input(f"\n{Colors.CYAN}Select disk (1-{len(disks)}):{Colors.END} ").strip())
        self.config['disk'] = disks[disk_choice - 1]['path']
        
        # Partition scheme
        print(f"\n{Colors.BOLD}Partition Schemes:{Colors.END}")
        print("1. 💼 Developer Standard (EFI + Swap + Root + Home)")
        print("2. 🚀 Performance (EFI + Root, no swap)")
        print("3. 📦 Container Dev (EFI + Swap + Root + Docker)")
        print("4. 🎮 Gaming/Workstation (EFI + Swap + Root + Home)")
        
        scheme = input(f"\n{Colors.CYAN}Select scheme (1-4) [1]:{Colors.END} ").strip() or '1'
        self.config['partition_scheme'] = scheme
        
        # Swap size
        if scheme in ['1', '3', '4']:
            print(f"\n{Colors.BOLD}Swap Size:{Colors.END}")
            
            # Get RAM size
            try:
                with open('/proc/meminfo') as f:
                    for line in f:
                        if 'MemTotal' in line:
                            ram_kb = int(line.split()[1])
                            ram_gb = ram_kb // (1024 * 1024)
                            print(f"  Detected RAM: {ram_gb}GB")
                            break
            except:
                ram_gb = 8
            
            print(f"  Recommended: {ram_gb}GB (RAM size)")
            print(f"  Hibernation: {int(ram_gb * 1.5)}GB (RAM x 1.5)")
            
            swap_size = input(f"\n{Colors.CYAN}Swap size in GB [{ram_gb}]:{Colors.END} ").strip() or str(ram_gb)
            self.config['swap_size'] = f"{swap_size}G"
        else:
            self.config['swap_size'] = None
        
        # Home partition
        if scheme in ['1', '4']:
            home_size = input(f"\n{Colors.CYAN}Home partition size (G or %) [50%]:{Colors.END} ").strip() or '50%'
            self.config['home_size'] = home_size
        
        # Filesystem
        print(f"\n{Colors.BOLD}Filesystem:{Colors.END}")
        print("1. 🐧 ext4 (stable, proven)")
        print("2. 🌳 btrfs (snapshots, compression)")
        print("3. ⚡ xfs (performance)")
        print("4. 🚀 f2fs (SSD optimized)")
        
        fs_choice = input(f"\n{Colors.CYAN}Select (1-4) [2]:{Colors.END} ").strip() or '2'
        fs_map = {'1': 'ext4', '2': 'btrfs', '3': 'xfs', '4': 'f2fs'}
        self.config['filesystem'] = fs_map[fs_choice]
        
        # Btrfs options
        if self.config['filesystem'] == 'btrfs':
            print(f"\n{Colors.BOLD}Btrfs Options:{Colors.END}")
            compression = input(f"{Colors.CYAN}Enable compression? (zstd/lzo/none) [zstd]:{Colors.END} ").strip() or 'zstd'
            self.config['btrfs_compression'] = compression if compression != 'none' else None
            
            snapshots = input(f"{Colors.CYAN}Enable automatic snapshots? (Y/n):{Colors.END} ").strip().lower() != 'n'
            self.config['btrfs_snapshots'] = snapshots
        
        # Encryption
        print(f"\n{Colors.BOLD}Encryption:{Colors.END}")
        encrypt = input(f"{Colors.CYAN}Enable full disk encryption (LUKS)? (Y/n):{Colors.END} ").strip().lower() != 'n'
        
        if encrypt:
            while True:
                pwd1 = input(f"{Colors.CYAN}Encryption password:{Colors.END} ").strip()
                pwd2 = input(f"{Colors.CYAN}Confirm password:{Colors.END} ").strip()
                if pwd1 == pwd2:
                    self.config['encryption_password'] = pwd1
                    break
                self.print_step("Passwords don't match!", "error")
        else:
            self.config['encryption_password'] = None
    
    def configure_system(self):
        self.print_header("System Configuration")
        
        # Hostname
        self.config['hostname'] = input(f"{Colors.CYAN}Hostname [arch-dev]:{Colors.END} ").strip() or 'arch-dev'
        
        # Timezone
        print(f"\n{Colors.BOLD}Timezone:{Colors.END}")
        regions = ['America', 'Europe', 'Asia', 'Africa', 'Australia', 'Pacific']
        for i, region in enumerate(regions, 1):
            print(f"  {i}. {region}")
        
        region_choice = input(f"\n{Colors.CYAN}Select region (1-{len(regions)}) [1]:{Colors.END} ").strip() or '1'
        
        if region_choice.isdigit() and 1 <= int(region_choice) <= len(regions):
            region = regions[int(region_choice) - 1]
            city = input(f"{Colors.CYAN}City [New_York]:{Colors.END} ").strip() or 'New_York'
            self.config['timezone'] = f"{region}/{city}"
        else:
            self.config['timezone'] = 'UTC'
        
        # Locale
        print(f"\n{Colors.BOLD}Locale:{Colors.END}")
        locales = ['en_US.UTF-8', 'en_GB.UTF-8', 'de_DE.UTF-8', 'fr_FR.UTF-8', 'es_ES.UTF-8']
        
        for i, locale in enumerate(locales, 1):
            print(f"  {i}. {locale}")
        
        locale_choice = input(f"\n{Colors.CYAN}Select (1-{len(locales)}) [1]:{Colors.END} ").strip() or '1'
        
        if locale_choice.isdigit() and 1 <= int(locale_choice) <= len(locales):
            self.config['locale'] = locales[int(locale_choice) - 1]
        else:
            self.config['locale'] = 'en_US.UTF-8'
        
        # Keyboard layout
        print(f"\n{Colors.BOLD}Keyboard Layout:{Colors.END}")
        layouts = ['us', 'uk', 'de', 'fr', 'es', 'dvorak', 'colemak']
        
        for i, layout in enumerate(layouts, 1):
            print(f"  {i}. {layout}")
        
        kb_choice = input(f"\n{Colors.CYAN}Select (1-{len(layouts)}) [1]:{Colors.END} ").strip() or '1'
        
        if kb_choice.isdigit() and 1 <= int(kb_choice) <= len(layouts):
            self.config['keymap'] = layouts[int(kb_choice) - 1]
        else:
            self.config['keymap'] = 'us'
    
    def configure_users(self):
        self.print_header("User Configuration")
        
        # Root password
        print(f"{Colors.BOLD}Root Account:{Colors.END}")
        
        disable_root = input(f"{Colors.CYAN}Disable root login? (recommended) (Y/n):{Colors.END} ").strip().lower() != 'n'
        
        if not disable_root:
            while True:
                pwd1 = input(f"{Colors.CYAN}Root password:{Colors.END} ").strip()
                pwd2 = input(f"{Colors.CYAN}Confirm:{Colors.END} ").strip()
                if pwd1 == pwd2:
                    self.config['root_password'] = pwd1
                    break
                self.print_step("Passwords don't match!", "error")
        else:
            self.config['root_password'] = '!'
            self.config['disable_root'] = True
        
        # Main user
        print(f"\n{Colors.BOLD}Main User Account:{Colors.END}")
        self.config['users'] = {}
        
        username = input(f"{Colors.CYAN}Username:{Colors.END} ").strip()
        
        while True:
            pwd1 = input(f"{Colors.CYAN}Password for {username}:{Colors.END} ").strip()
            pwd2 = input(f"{Colors.CYAN}Confirm:{Colors.END} ").strip()
            if pwd1 == pwd2:
                break
            self.print_step("Passwords don't match!", "error")
        
        # Shell
        print(f"\n{Colors.BOLD}Default Shell:{Colors.END}")
        shells = ['zsh', 'bash', 'fish']
        
        for i, shell in enumerate(shells, 1):
            print(f"  {i}. {shell}")
        
        shell_choice = input(f"\n{Colors.CYAN}Select (1-{len(shells)}) [1]:{Colors.END} ").strip() or '1'
        
        if shell_choice.isdigit() and 1 <= int(shell_choice) <= len(shells):
            user_shell = shells[int(shell_choice) - 1]
        else:
            user_shell = 'zsh'
        
        self.config['users'][username] = {
            'password': pwd1,
            'sudo': True,
            'groups': ['wheel', 'audio', 'video', 'storage', 'optical', 'network', 'docker'],
            'shell': user_shell
        }
    
    def configure_hyprland(self):
        self.print_header("Hyprland Configuration")
        
        self.print_step("Hyprland will be installed as the desktop environment", "success")
        
        print(f"\n{Colors.BOLD}Hyprland Theme:{Colors.END}")
        print("1. 🎨 Catppuccin")
        print("2. 🌊 Tokyo Night")
        print("3. 🌲 Everforest")
        print("4. 🌙 Nord")
        print("5. 🎭 Dracula")
        print("6. 🔥 Gruvbox")
        
        theme_choice = input(f"\n{Colors.CYAN}Select theme (1-6) [1]:{Colors.END} ").strip() or '1'
        theme_map = {'1': 'catppuccin', '2': 'tokyonight', '3': 'everforest', '4': 'nord', '5': 'dracula', '6': 'gruvbox'}
        self.config['hyprland_theme'] = theme_map.get(theme_choice, 'catppuccin')
        
        # Animation settings
        print(f"\n{Colors.BOLD}Animation Settings:{Colors.END}")
        print("1. ⚡ Performance (fast)")
        print("2. ⚖️  Balanced")
        print("3. 🎬 Cinematic (smooth)")
        
        anim_choice = input(f"\n{Colors.CYAN}Select (1-3) [2]:{Colors.END} ").strip() or '2'
        self.config['hyprland_animations'] = anim_choice
        
        # Display manager
        print(f"\n{Colors.BOLD}Display Manager:{Colors.END}")
        print("1. 🎪 SDDM")
        print("2. 🌊 ly (minimal)")
        print("3. 💻 TTY autologin")
        
        dm_choice = input(f"\n{Colors.CYAN}Select (1-3) [1]:{Colors.END} ").strip() or '1'
        dm_map = {'1': 'sddm', '2': 'ly', '3': 'autologin'}
        self.config['display_manager'] = dm_map.get(dm_choice, 'sddm')
    
    def configure_development(self):
        self.print_header("Development Environment")
        
        # Programming languages
        print(f"{Colors.BOLD}Programming Languages:{Colors.END}")
        print("1. Python")
        print("2. Node.js")
        print("3. Rust")
        print("4. Go")
        print("5. C/C++")
        
        print(f"\n{Colors.CYAN}Select languages (comma-separated, e.g. 1,2,3) [1,2,5]:{Colors.END}")
        lang_input = input().strip() or '1,2,5'
        
        lang_map = {
            '1': ['python', 'python-pip'],
            '2': ['nodejs', 'npm'],
            '3': ['rust'],
            '4': ['go'],
            '5': ['base-devel', 'gcc', 'clang']
        }
        
        self.config['dev_languages'] = []
        for num in lang_input.split(','):
            if num.strip() in lang_map:
                self.config['dev_languages'].extend(lang_map[num.strip()])
        
        # Editors
        print(f"\n{Colors.BOLD}Code Editors:{Colors.END}")
        print("1. Neovim")
        print("2. VS Code")
        
        editor_input = input(f"\n{Colors.CYAN}Select (comma-separated) [1,2]:{Colors.END} ").strip() or '1,2'
        
        self.config['editors'] = []
        if '1' in editor_input:
            self.config['editors'].append('neovim')
        if '2' in editor_input:
            self.config['editors'].append('code')
        
        # Terminal
        print(f"\n{Colors.BOLD}Terminal:{Colors.END}")
        terminals = ['kitty', 'alacritty', 'foot']
        
        for i, term in enumerate(terminals, 1):
            print(f"  {i}. {term}")
        
        term_choice = input(f"\n{Colors.CYAN}Select (1-{len(terminals)}) [1]:{Colors.END} ").strip() or '1'
        
        if term_choice.isdigit() and 1 <= int(term_choice) <= len(terminals):
            self.config['terminal'] = terminals[int(term_choice) - 1]
        else:
            self.config['terminal'] = 'kitty'
        
        # Docker
        docker = input(f"\n{Colors.CYAN}Install Docker? (Y/n):{Colors.END} ").strip().lower() != 'n'
        self.config['install_docker'] = docker
        
        # Dev tools
        self.config['dev_tools'] = ['git', 'github-cli', 'lazygit', 'tmux', 'fzf', 'ripgrep', 'bat', 'btop']
    
    def configure_applications(self):
        self.print_header("Applications")
        
        # Browser
        browsers = ['firefox', 'chromium', 'brave']
        print(f"{Colors.BOLD}Browser:{Colors.END}")
        
        for i, browser in enumerate(browsers, 1):
            print(f"  {i}. {browser}")
        
        browser_choice = input(f"\n{Colors.CYAN}Select (1-{len(browsers)}) [1]:{Colors.END} ").strip() or '1'
        
        if browser_choice.isdigit() and 1 <= int(browser_choice) <= len(browsers):
            self.config['browser'] = browsers[int(browser_choice) - 1]
        else:
            self.config['browser'] = 'firefox'
        
        # Communication
        discord = input(f"\n{Colors.CYAN}Install Discord? (Y/n):{Colors.END} ").strip().lower() != 'n'
        self.config['install_discord'] = discord
        
        # File manager
        self.config['file_manager'] = 'thunar'
        
        # Media
        self.config['media_apps'] = ['mpv']
    
    def configure_system_tools(self):
        self.print_header("System Tools")
        
        # Bootloader
        print(f"{Colors.BOLD}Bootloader:{Colors.END}")
        print("1. GRUB")
        print("2. systemd-boot")
        
        boot_choice = input(f"\n{Colors.CYAN}Select (1-2) [2]:{Colors.END} ").strip() or '2'
        self.config['bootloader'] = 'grub' if boot_choice == '1' else 'systemd-boot'
        
        # Microcode
        print(f"\n{Colors.BOLD}CPU:{Colors.END}")
        print("1. Intel")
        print("2. AMD")
        
        cpu_choice = input(f"\n{Colors.CYAN}Select (1-2):{Colors.END} ").strip()
        self.config['microcode'] = 'intel-ucode' if cpu_choice == '1' else 'amd-ucode'
        
        # Network manager
        self.config['network_manager'] = 'NetworkManager'
        
        # Services
        self.config['enable_firewall'] = input(f"\n{Colors.CYAN}Enable firewall? (Y/n):{Colors.END} ").strip().lower() != 'n'
        self.config['enable_bluetooth'] = input(f"{Colors.CYAN}Enable Bluetooth? (Y/n):{Colors.END} ").strip().lower() != 'n'
        
        # AUR helper
        print(f"\n{Colors.BOLD}AUR Helper:{Colors.END}")
        print("1. yay")
        print("2. paru")
        
        aur_choice = input(f"\n{Colors.CYAN}Select (1-2) [1]:{Colors.END} ").strip() or '1'
        self.config['aur_helper'] = 'yay' if aur_choice == '1' else 'paru'
    
    def interactive_config(self):
        self.clear_screen()
        self.print_banner()
        
        # Root check
        if os.geteuid() != 0:
            self.print_step("This script must be run as root!", "error")
            sys.exit(1)
        
        self.print_step("Welcome to the Ultimate Arch Developer Installer", "success")
        time.sleep(1)
        
        # Configuration workflow
        self.setup_network()
        
        if not self.config.get('network_configured'):
            self.print_step("No internet connection - some features may be limited", "warning")
            cont = input(f"\n{Colors.CYAN}Continue? (y/N):{Colors.END} ").strip().lower()
            if cont != 'y':
                sys.exit(0)
        
        self.configure_storage()
        self.configure_system()
        self.configure_users()
        self.configure_hyprland()
        self.configure_development()
        self.configure_applications()
        self.configure_system_tools()
        
        return self.config
    
    def save_config(self, filename: Optional[str] = None):
        filename = filename or self.config_file
        
        safe_config = self.config.copy()
        
        # Mask sensitive data
        if 'root_password' in safe_config:
            safe_config['root_password'] = '***'
        if 'encryption_password' in safe_config:
            safe_config['encryption_password'] = '***' if safe_config['encryption_password'] else None
        if 'users' in safe_config:
            for user in safe_config['users']:
                safe_config['users'][user]['password'] = '***'
        if 'wifi_password' in safe_config:
            safe_config['wifi_password'] = '***'
        
        with open(filename, 'w') as f:
            json.dump(self.config, f, indent=2)
        
        self.print_step(f"Configuration saved to {filename}", "success")
        return filename
    
    def load_config(self, filename: Optional[str] = None):
        filename = filename or self.config_file
        
        if not os.path.exists(filename):
            self.print_step(f"Config file {filename} not found", "error")
            return False
        
        with open(filename, 'r') as f:
            self.config = json.load(f)
        
        self.print_step(f"Configuration loaded from {filename}", "success")
        return True
    
    def display_config(self):
        self.clear_screen()
        self.print_header("Configuration Summary")
        
        safe_config = self.config.copy()
        
        # Mask passwords
        if 'root_password' in safe_config:
            safe_config['root_password'] = '***'
        if 'encryption_password' in safe_config:
            safe_config['encryption_password'] = '***' if safe_config['encryption_password'] else None
        if 'users' in safe_config:
            for user in safe_config['users']:
                safe_config['users'][user]['password'] = '***'
        if 'wifi_password' in safe_config:
            safe_config['wifi_password'] = '***'
        
        print(json.dumps(safe_config, indent=2))
        print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    
    def perform_installation(self):
        """Perform the actual installation"""
        self.print_header("Installation")
        
        print(f"{Colors.RED}{Colors.BOLD}⚠️  WARNING ⚠️{Colors.END}")
        print(f"{Colors.RED}This will COMPLETELY ERASE: {self.config['disk']}{Colors.END}")
        print(f"{Colors.YELLOW}All data will be permanently lost!{Colors.END}\n")
        
        confirm = input(f"{Colors.CYAN}Type 'YES I UNDERSTAND' to continue:{Colors.END} ").strip()
        if confirm != 'YES I UNDERSTAND':
            self.print_step("Installation cancelled", "warning")
            return False
        
        try:
            # Step 1: Partition disk
            self.print_step("[1/12] Partitioning disk...", "")
            self.partition_disk()
            time.sleep(1)
            
            # Step 2: Format partitions
            self.print_step("[2/12] Formatting partitions...", "")
            self.format_partitions()
            time.sleep(1)
            
            # Step 3: Mount partitions
            self.print_step("[3/12] Mounting partitions...", "")
            self.mount_partitions()
            time.sleep(1)
            
            # Step 4: Install base system
            self.print_step("[4/12] Installing base system (this may take a while)...", "")
            self.install_base()
            
            # Step 5: Generate fstab
            self.print_step("[5/12] Generating fstab...", "")
            self.generate_fstab()
            
            # Step 6: Configure system
            self.print_step("[6/12] Configuring system...", "")
            self.configure_base_system()
            
            # Step 7: Install bootloader
            self.print_step("[7/12] Installing bootloader...", "")
            self.install_bootloader()
            
            # Step 8: Create users
            self.print_step("[8/12] Creating users...", "")
            self.create_users()
            
            # Step 9: Install Hyprland
            self.print_step("[9/12] Installing Hyprland...", "")
            self.install_hyprland()
            
            # Step 10: Install dev tools
            self.print_step("[10/12] Installing development tools...", "")
            self.install_dev_tools()
            
            # Step 11: Install applications
            self.print_step("[11/12] Installing applications...", "")
            self.install_applications()
            
            # Step 12: Configure services
            self.print_step("[12/12] Configuring services...", "")
            self.configure_services()
            
            self.print_header("Installation Complete!")
            
            print(f"{Colors.GREEN}✓ Your Arch Linux system is ready!{Colors.END}\n")
            print(f"{Colors.CYAN}Next steps:{Colors.END}")
            print("  1. Remove installation media")
            print("  2. Type: umount -R /mnt")
            print("  3. Type: reboot")
            print("  4. Log in and enjoy your Hyprland setup!")
            print(f"\n{Colors.YELLOW}Keybindings:{Colors.END}")
            print("  SUPER + Q = Close window")
            print("  SUPER + Return = Terminal")
            print("  SUPER + D = App launcher")
            print("  SUPER + M = Exit Hyprland")
            
            return True
            
        except Exception as e:
            self.print_step(f"Installation failed: {e}", "error")
            import traceback
            traceback.print_exc()
            return False
    
    def partition_disk(self):
        """Partition the disk"""
        disk = self.config['disk']
        
        # Wipe disk
        self.run_cmd(['wipefs', '-af', disk])
        
        # Create GPT partition table
        self.run_cmd(['parted', '-s', disk, 'mklabel', 'gpt'])
        
        # Create EFI partition (512MB)
        self.run_cmd(['parted', '-s', disk, 'mkpart', 'primary', 'fat32', '1MiB', '513MiB'])
        self.run_cmd(['parted', '-s', disk, 'set', '1', 'esp', 'on'])
        
        partition_num = 2
        current_start = '513MiB'
        
        # Create swap if needed
        if self.config.get('swap_size'):
            swap_end = f"{513 + int(self.config['swap_size'].rstrip('G')) * 1024}MiB"
            self.run_cmd(['parted', '-s', disk, 'mkpart', 'primary', 'linux-swap', current_start, swap_end])
            current_start = swap_end
            partition_num += 1
        
        # Create root partition
        if self.config.get('home_size'):
            # Calculate root end
            root_end = '50%'  # Simplified
            self.run_cmd(['parted', '-s', disk, 'mkpart', 'primary', self.config['filesystem'], current_start, root_end])
            current_start = root_end
            partition_num += 1
            
            # Create home partition
            self.run_cmd(['parted', '-s', disk, 'mkpart', 'primary', self.config['filesystem'], current_start, '100%'])
        else:
            # Root takes all remaining space
            self.run_cmd(['parted', '-s', disk, 'mkpart', 'primary', self.config['filesystem'], current_start, '100%'])
        
        time.sleep(2)
        self.config['efi_partition'] = f"{disk}1"
        self.config['root_partition'] = f"{disk}{2 if not self.config.get('swap_size') else 3}"
        
        if self.config.get('swap_size'):
            self.config['swap_partition'] = f"{disk}2"
    
    def format_partitions(self):
        """Format the partitions"""
        # Format EFI
        self.run_cmd(['mkfs.fat', '-F32', self.config['efi_partition']])
        
        # Format swap
        if self.config.get('swap_partition'):
            self.run_cmd(['mkswap', self.config['swap_partition']])
            self.run_cmd(['swapon', self.config['swap_partition']])
        
        # Format root (with encryption if needed)
        root_part = self.config['root_partition']
        
        if self.config.get('encryption_password'):
            # Setup LUKS
            proc = subprocess.Popen(
                ['cryptsetup', 'luksFormat', root_part],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            proc.communicate(input=f"{self.config['encryption_password']}\n".encode())
            
            # Open LUKS
            proc = subprocess.Popen(
                ['cryptsetup', 'open', root_part, 'cryptroot'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            proc.communicate(input=f"{self.config['encryption_password']}\n".encode())
            
            root_part = '/dev/mapper/cryptroot'
            self.config['encrypted_root'] = True
        
        # Format filesystem
        fs = self.config['filesystem']
        
        if fs == 'ext4':
            self.run_cmd(['mkfs.ext4', '-F', root_part])
        elif fs == 'btrfs':
            cmd = ['mkfs.btrfs', '-f', root_part]
            self.run_cmd(cmd)
        elif fs == 'xfs':
            self.run_cmd(['mkfs.xfs', '-f', root_part])
        elif fs == 'f2fs':
            self.run_cmd(['mkfs.f2fs', '-f', root_part])
        
        self.config['formatted_root'] = root_part
    
    def mount_partitions(self):
        """Mount the partitions"""
        root = self.config['formatted_root']
        
        # Mount root
        self.run_cmd(['mount', root, '/mnt'])
        
        # Create and mount EFI
        self.run_cmd(['mkdir', '-p', '/mnt/boot'])
        self.run_cmd(['mount', self.config['efi_partition'], '/mnt/boot'])
        
        # Mount home if separate
        if self.config.get('home_partition'):
            self.run_cmd(['mkdir', '-p', '/mnt/home'])
            self.run_cmd(['mount', self.config['home_partition'], '/mnt/home'])
    
    def install_base(self):
        """Install base system"""
        packages = [
            'base', 'base-devel', 'linux', 'linux-firmware',
            self.config.get('microcode', 'intel-ucode'),
            'networkmanager', 'sudo', 'nano', 'vim'
        ]
        
        self.run_cmd(['pacstrap', '/mnt'] + packages)
    
    def generate_fstab(self):
        """Generate fstab"""
        result = self.run_cmd(['genfstab', '-U', '/mnt'], capture=True)
        with open('/mnt/etc/fstab', 'w') as f:
            f.write(result.stdout)
    
    def chroot(self, command: str):
        """Execute command in chroot"""
        self.run_cmd(['arch-chroot', '/mnt', 'bash', '-c', command])
    
    def configure_base_system(self):
        """Configure base system settings"""
        # Timezone
        self.chroot(f"ln -sf /usr/share/zoneinfo/{self.config['timezone']} /etc/localtime")
        self.chroot("hwclock --systohc")
        
        # Locale
        locale = self.config['locale']
        self.chroot(f"echo '{locale} UTF-8' >> /etc/locale.gen")
        self.chroot("locale-gen")
        self.chroot(f"echo 'LANG={locale}' > /etc/locale.conf")
        
        # Keymap
        self.chroot(f"echo 'KEYMAP={self.config['keymap']}' > /etc/vconsole.conf")
        
        # Hostname
        hostname = self.config['hostname']
        self.chroot(f"echo '{hostname}' > /etc/hostname")
        
        # Hosts file
        hosts = f"""127.0.0.1    localhost
::1          localhost
127.0.1.1    {hostname}.localdomain {hostname}"""
        self.chroot(f"echo '{hosts}' > /etc/hosts")
    
    def install_bootloader(self):
        """Install and configure bootloader"""
        bootloader = self.config.get('bootloader', 'systemd-boot')
        
        if bootloader == 'grub':
            self.chroot("pacman -S --noconfirm grub efibootmgr")
            self.chroot("grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB")
            
            if self.config.get('encrypted_root'):
                # Configure GRUB for encryption
                root_uuid = self.run_cmd(['blkid', '-s', 'UUID', '-o', 'value', self.config['root_partition']], capture=True).stdout.strip()
                self.chroot(f"sed -i 's/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID={root_uuid}:cryptroot root=\\/dev\\/mapper\\/cryptroot\"/' /etc/default/grub")
            
            self.chroot("grub-mkconfig -o /boot/grub/grub.cfg")
        
        else:  # systemd-boot
            self.chroot("bootctl install")
            
            # Create loader entry
            entry = """title   Arch Linux
linux   /vmlinuz-linux
initrd  /{microcode}
initrd  /initramfs-linux.img
options root={root} rw
""".format(
                microcode=self.config.get('microcode', 'intel-ucode') + '.img',
                root='PARTUUID=' + self.run_cmd(['blkid', '-s', 'PARTUUID', '-o', 'value', self.config['formatted_root']], capture=True).stdout.strip()
            )
            
            self.chroot(f"echo '{entry}' > /boot/loader/entries/arch.conf")
            
            # Configure loader
            self.chroot("echo 'default arch.conf' > /boot/loader/loader.conf")
            self.chroot("echo 'timeout 3' >> /boot/loader/loader.conf")
    
    def create_users(self):
        """Create user accounts"""
        # Set root password
        if self.config.get('root_password') and self.config['root_password'] != '!':
            self.chroot(f"echo 'root:{self.config['root_password']}' | chpasswd")
        elif self.config.get('disable_root'):
            self.chroot("passwd -l root")
        
        # Create users
        for username, user_data in self.config.get('users', {}).items():
            # Create user
            shell = user_data.get('shell', 'bash')
            self.chroot(f"useradd -m -s /bin/{shell} {username}")
            
            # Set password
            self.chroot(f"echo '{username}:{user_data['password']}' | chpasswd")
            
            # Add to groups
            groups = user_data.get('groups', [])
            if groups:
                self.chroot(f"usermod -aG {','.join(groups)} {username}")
            
            # Enable sudo
            if user_data.get('sudo'):
                self.chroot("sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers")
    
    def install_hyprland(self):
        """Install Hyprland and related packages"""
        packages = [
            'hyprland', 'waybar', 'wofi', 'kitty', 'swaybg',
            'swaylock', 'mako', 'grim', 'slurp', 'wl-clipboard',
            'xdg-desktop-portal-hyprland', 'polkit-kde-agent',
            'qt5-wayland', 'qt6-wayland'
        ]
        
        # Add terminal
        terminal = self.config.get('terminal', 'kitty')
        if terminal not in packages:
            packages.append(terminal)
        
        # Add display manager
        dm = self.config.get('display_manager', 'sddm')
        if dm == 'sddm':
            packages.append('sddm')
        elif dm == 'ly':
            # ly needs to be installed from AUR later
            pass
        
        self.chroot(f"pacman -S --noconfirm {' '.join(packages)}")
        
        # Enable display manager
        if dm == 'sddm':
            self.chroot("systemctl enable sddm")
    
    def install_dev_tools(self):
        """Install development tools"""
        packages = []
        
        # Languages
        packages.extend(self.config.get('dev_languages', []))
        
        # Editors
        editors = self.config.get('editors', [])
        if 'neovim' in editors:
            packages.append('neovim')
        if 'code' in editors:
            # VS Code from AUR later
            pass
        
        # Dev tools
        packages.extend(self.config.get('dev_tools', []))
        
        # Docker
        if self.config.get('install_docker'):
            packages.extend(['docker', 'docker-compose'])
            self.chroot("systemctl enable docker")
        
        if packages:
            self.chroot(f"pacman -S --noconfirm {' '.join(packages)}")
    
    def install_applications(self):
        """Install applications"""
        packages = []
        
        # Browser
        browser = self.config.get('browser', 'firefox')
        packages.append(browser)
        
        # File manager
        fm = self.config.get('file_manager', 'thunar')
        packages.append(fm)
        
        # Media
        packages.extend(self.config.get('media_apps', []))
        
        if packages:
            self.chroot(f"pacman -S --noconfirm {' '.join(packages)}")
    
    def configure_services(self):
        """Enable and configure services"""
        # NetworkManager
        self.chroot("systemctl enable NetworkManager")
        
        # Firewall
        if self.config.get('enable_firewall'):
            self.chroot("pacman -S --noconfirm ufw")
            self.chroot("systemctl enable ufw")
        
        # Bluetooth
        if self.config.get('enable_bluetooth'):
            self.chroot("pacman -S --noconfirm bluez bluez-utils")
            self.chroot("systemctl enable bluetooth")
        
        # Configure network based on installation setup
        if self.config.get('network_type') == 'wifi' and self.config.get('wifi_ssid'):
            # Save WiFi credentials
            ssid = self.config['wifi_ssid']
            password = self.config.get('wifi_password', '')
            
            wifi_config = f"""[connection]
id={ssid}
type=wifi

[wifi]
ssid={ssid}

[wifi-security]
key-mgmt=wpa-psk
psk={password}

[ipv4]
method=auto

[ipv6]
method=auto
"""
            self.chroot(f"echo '{wifi_config}' > /etc/NetworkManager/system-connections/{ssid}.nmconnection")
            self.chroot(f"chmod 600 /etc/NetworkManager/system-connections/{ssid}.nmconnection")

def main():
    installer = DevArchInstaller()
    
    installer.clear_screen()
    installer.print_banner()
    
    print(f"{Colors.BOLD}Installation Options:{Colors.END}\n")
    print("1. 🚀 New Installation (full interactive)")
    print("2. 📂 Load Configuration")
    print("3. ✏️  Edit Configuration")
    print("4. 🚪 Exit")
    
    choice = input(f"\n{Colors.CYAN}Select (1-4):{Colors.END} ").strip()
    
    if choice == '1':
        installer.interactive_config()
        installer.display_config()
        
        save = input(f"\n{Colors.CYAN}Save configuration? (Y/n):{Colors.END} ").strip().lower()
        if save != 'n':
            filename = input(f"{Colors.CYAN}Filename [dev_arch_config.json]:{Colors.END} ").strip()
            installer.save_config(filename if filename else None)
        
        install = input(f"\n{Colors.CYAN}Proceed with installation? (y/N):{Colors.END} ").strip().lower()
        if install == 'y':
            installer.perform_installation()
    
    elif choice == '2':
        filename = input(f"{Colors.CYAN}Config file [dev_arch_config.json]:{Colors.END} ").strip()
        if installer.load_config(filename if filename else None):
            installer.display_config()
            
            install = input(f"\n{Colors.CYAN}Proceed with installation? (y/N):{Colors.END} ").strip().lower()
            if install == 'y':
                installer.perform_installation()
    
    elif choice == '3':
        filename = input(f"{Colors.CYAN}Config file [dev_arch_config.json]:{Colors.END} ").strip()
        if installer.load_config(filename if filename else None):
            print(f"\n{Colors.GREEN}✓ Configuration loaded{Colors.END}")
            print(f"{Colors.CYAN}Edit the JSON file manually and run installer again{Colors.END}")
    
    else:
        print(f"\n{Colors.YELLOW}Thanks for using Arch Dev Installer! 👋{Colors.END}")
        return

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.RED}Installation cancelled by user{Colors.END}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}✗ Fatal error: {e}{Colors.END}")
        import traceback
        traceback.print_exc()
        sys.exit(1)