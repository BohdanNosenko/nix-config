{ config, pkgs, ... }:

{
  # Import the shared base configuration
  imports = [ ./common.nix ];

  # --- WSL SPECIFIC PACKAGES ---
  home.packages = [
    # Add machine-specific CLI tools here as needed
  ];

  # --- WSL SPECIFIC DOTFILES ---
  xdg.configFile = {
    "topgrade.toml".source = ../config/debian-wsl/topgrade.toml;
  };

  programs.neovim.enable = true;
}
