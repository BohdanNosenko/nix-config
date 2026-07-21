{ config, pkgs, ... }:

{
  # Import the shared base configuration
  imports = [ ./common.nix ];

  # --- WSL SPECIFIC PACKAGES ---
  home.packages = [
    pkgs.python3
    pkgs.nodejs_22
  ];

  # --- WSL SPECIFIC DOTFILES ---
  xdg.configFile = {
    "topgrade.toml".source = ../config/debian-wsl/topgrade.toml;
  };

  programs.neovim.enable = true;
}
