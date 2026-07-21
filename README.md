# Declarative Multi-Host Nix Configuration

A modular, reproducible Home Manager and Nix Flake repository configured for SteamOS (Steam Deck), Debian WSL, and Linux workstations.

---

## Repository Architecture

```
~/.config/home-manager/
├── flake.nix             # Multi-host Flake entry point (deck, wsl profiles)
├── flake.lock            # Dependency lockfile
├── README.md             # Repository documentation
├── home/
│   ├── common.nix        # Shared base (git, bat, btop, eza, fd, ripgrep, starship, topgrade, agy)
│   ├── steamdeck.nix     # Steam Deck profile (podman-compose, steamcmd, Neovim compiler wrappers)
│   └── debian-wsl.nix    # Debian WSL profile (python3, nodejs)
├── config/
│   ├── common/           # Dotfiles shared across all machines (nvim)
│   ├── steamdeck/        # Host dotfiles (topgrade.toml for Steam Deck)
│   └── debian-wsl/       # Host dotfiles (topgrade.toml for WSL)
└── scripts/
    └── wsl-bootstrap.sh  # Automated 1-command WSL installer script
```

---

## Quick Start & Deployment

### 1. Steam Deck Deployment
```bash
# Clone repository
git clone https://github.com/BohdanNosenko/nix-config.git ~/.config/home-manager

# Bootstrap environment
nix run github:nix-community/home-manager -- switch --flake ~/.config/home-manager#deck
```

### 2. Debian WSL Deployment (Automated 1-Command Setup)
On a fresh Debian WSL installation, run this single command to install Nix, set network parameters, clone the repo, and activate your environment:

```bash
curl -sSL https://raw.githubusercontent.com/BohdanNosenko/nix-config/master/scripts/wsl-bootstrap.sh | bash
```

---

## Windows Host Setup (.wslconfig)

To prevent TCP packet drops and SSL socket timeouts during large file transfers inside WSL2, configure Mirrored Networking on your Windows host:

1. Open Windows Run (`Win + R`), type `%USERPROFILE%`, and press Enter.
2. Create or edit a file named `.wslconfig`.
3. Add the following lines:

```ini
[wsl2]
networkingMode=mirrored
dnsTunneling=true
firewall=true
autoProxy=true
```

4. Open Windows PowerShell and restart WSL:
```powershell
wsl.exe --shutdown
```

---

## Maintenance & Everyday Usage

* **Update Package Versions:**
  ```bash
  cd ~/.config/home-manager
  nix flake update
  home-manager switch
  ```

* **Clean Old Generations & Optimize Store:**
  ```bash
  home-manager expire-generations "-7 days"
  nix store gc
  nix store optimise
  ```

* **Format Nix Code:**
  ```bash
  cd ~/.config/home-manager
  nix fmt
  ```
