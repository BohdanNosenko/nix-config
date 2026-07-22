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


# 1. Configure /etc/nix/nix.custom.conf to allow the current user to control the nix daemon
echo "[+] Configuring /etc/nix/nix.custom.conf with trusted-users..."
sudo mkdir -p /etc/nix
CURRENT_USER=$(whoami)

cat <<EOF | sudo tee /etc/nix/nix.custom.conf >/dev/null
trusted-users = root $CURRENT_USER
EOF



# 4. Install basic APT prerequisites
echo "[+] Installing APT prerequisites (curl, git, xz-utils, wget)..."
sudo apt-get update -qq </dev/null && sudo apt-get install -y -qq curl git xz-utils wget </dev/null

# 5. Ensure systemd and hostname are set in /etc/wsl.conf
if ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
    echo "[+] Enabling systemd in /etc/wsl.conf..."
    echo -e "[boot]\nsystemd=true" | sudo tee -a /etc/wsl.conf >/dev/null
fi

if ! grep -q "hostname=" /etc/wsl.conf 2>/dev/null; then
    echo "[+] Setting hostname to crimson-wsl in /etc/wsl.conf..."
    echo -e "[network]\nhostname=crimson-wsl" | sudo tee -a /etc/wsl.conf >/dev/null
fi

# 6. Check if Nix is installed; if not, download nix-installer binary directly from GitHub Releases
if ! command -v nix >/dev/null 2>&1; then
    echo "[+] Installing Nix via Determinate Systems Installer binary..."
    wget -q --tries=5 --timeout=30 https://github.com/DeterminateSystems/nix-installer/releases/latest/download/nix-installer-x86_64-linux -O /tmp/nix-installer </dev/null || \
    curl -sSL --tlsv1.2 --http1.1 --retry 5 https://github.com/DeterminateSystems/nix-installer/releases/latest/download/nix-installer-x86_64-linux -o /tmp/nix-installer </dev/null
    
    chmod +x /tmp/nix-installer
    sudo /tmp/nix-installer install linux --no-confirm </dev/null
    rm -f /tmp/nix-installer
    
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

# 7. Ensure nix-daemon is active
echo "[+] Restarting nix-daemon service..."
sudo systemctl restart nix-daemon || true

# 8. Clone or update repository in ~/.config/home-manager
REPO_DIR="$HOME/.config/home-manager"
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "[+] Cloning nix-config repository..."
    git clone https://github.com/BohdanNosenko/nix-config.git "$REPO_DIR" </dev/null
fi

# 9. Clear any corrupted partial caches
sudo rm -rf /root/.cache/nix "$HOME/.cache/nix" /nix/var/nix/binary-cache-v* 2>/dev/null || true

# 10. Run Home Manager bootstrap with fallback & automatic dotfile backup
echo "[+] Building and activating Home Manager WSL profile (#wsl)..."
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
nix run --fallback --option max-substitution-jobs 2 github:nix-community/home-manager -- switch -b backup --flake "$REPO_DIR#wsl" </dev/null

# 11. Register Fish in /etc/shells and set as default login shell
if command -v fish >/dev/null 2>&1 || [ -x "$HOME/.nix-profile/bin/fish" ]; then
    FISH_BIN=$(command -v fish 2>/dev/null || echo "$HOME/.nix-profile/bin/fish")
    echo "[+] Registering Fish in /etc/shells and setting default login shell..."
    if ! grep -q "$FISH_BIN" /etc/shells 2>/dev/null; then
        echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
        realpath "$FISH_BIN" 2>/dev/null | sudo tee -a /etc/shells >/dev/null || true
    fi
    sudo chsh -s "$FISH_BIN" "$CURRENT_USER" || true
fi

# 12. Auto-install Tmux Plugin Manager (TPM) if missing
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "[+] Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" </dev/null || true
fi

# 13. Clean Neovim lazy plugin cache to ensure fresh plugin checkout
echo "[+] Preparing Neovim plugin directory..."
rm -rf "$HOME/.local/share/nvim/lazy" 2>/dev/null || true

# 14. Ensure correct user permissions on config, local, and cache directories
echo "[+] Restoring home directory permissions for $CURRENT_USER..."
sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$HOME/.config" "$HOME/.local" "$HOME/.cache" 2>/dev/null || true

echo "[+] WSL Bootstrap complete! Restart WSL (wsl.exe --shutdown in PowerShell) to activate your crimson-wsl hostname and Fish shell."
