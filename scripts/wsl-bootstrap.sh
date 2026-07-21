#!/usr/bin/env bash
# Automated WSL Bootstrap Script for Nix & Home Manager
# 
# WINDOWS HOST SETUP INSTRUCTIONS (.wslconfig):
# To prevent network drops and socket timeouts on WSL2, configure Mirrored Networking
# on your Windows host:
# 1. Open Windows Run (Win + R), type %USERPROFILE%, and press Enter.
# 2. Create or edit a file named '.wslconfig'.
# 3. Add the following lines:
#
#    [wsl2]
#    networkingMode=mirrored
#    dnsTunneling=true
#    firewall=true
#    autoProxy=true
#
# 4. Open PowerShell on Windows and run: wsl.exe --shutdown
# 5. Reopen your WSL terminal.

set -euo pipefail

echo "[+] Starting Automated WSL Nix & Home Manager Bootstrap..."

# 1. Disable HTTP/2 in Nix daemon to prevent SSL socket drops on WSL
echo "[+] Configuring /etc/nix/nix.custom.conf for WSL stability..."
sudo mkdir -p /etc/nix
if ! grep -q "http2 = false" /etc/nix/nix.custom.conf 2>/dev/null; then
    echo "http2 = false" | sudo tee -a /etc/nix/nix.custom.conf >/dev/null
fi

# Add current user to trusted-users if missing
CURRENT_USER=$(whoami)
if ! grep -q "trusted-users" /etc/nix/nix.custom.conf 2>/dev/null; then
    echo "trusted-users = root $CURRENT_USER" | sudo tee -a /etc/nix/nix.custom.conf >/dev/null
fi

# 2. Fix WSL2 MTU network packet drops if eth0 exists
if ip link show eth0 >/dev/null 2>&1; then
    echo "[+] Setting eth0 MTU to 1350..."
    sudo ip link set dev eth0 mtu 1350 || true
fi

# 3. Install basic APT prerequisites
echo "[+] Installing APT prerequisites (curl, git, xz-utils)..."
sudo apt-get update -qq && sudo apt-get install -y -qq curl git xz-utils

# 4. Ensure systemd and hostname are set in /etc/wsl.conf
if ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
    echo "[+] Enabling systemd in /etc/wsl.conf..."
    echo -e "[boot]\nsystemd=true" | sudo tee -a /etc/wsl.conf >/dev/null
fi

if ! grep -q "hostname=" /etc/wsl.conf 2>/dev/null; then
    echo "[+] Setting hostname to crimson-wsl in /etc/wsl.conf..."
    echo -e "[network]\nhostname=crimson-wsl" | sudo tee -a /etc/wsl.conf >/dev/null
fi

# 5. Check if Nix is installed; if not, run Determinate Nix installer
if ! command -v nix >/dev/null 2>&1; then
    echo "[+] Installing Nix via Determinate Systems Installer..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

# 6. Ensure nix-daemon is active
echo "[+] Restarting nix-daemon service..."
sudo systemctl restart nix-daemon || true

# 7. Clone or update repository in ~/.config/home-manager
REPO_DIR="$HOME/.config/home-manager"
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[+] Cloning nix-config repository..."
    git clone https://github.com/BohdanNosenko/nix-config.git "$REPO_DIR"
fi

# 8. Clear any corrupted partial caches
sudo rm -rf /root/.cache/nix "$HOME/.cache/nix" /nix/var/nix/binary-cache-v* 2>/dev/null || true

# 9. Run Home Manager bootstrap with fallback & network throttling
echo "[+] Building and activating Home Manager WSL profile (#wsl)..."
nix run --fallback --option max-substitution-jobs 2 github:nix-community/home-manager -- switch --flake "$REPO_DIR#wsl"

echo "[+] WSL Bootstrap complete! Run 'exec fish' to enter your shell."
