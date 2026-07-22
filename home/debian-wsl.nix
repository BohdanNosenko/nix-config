{ config, pkgs, ... }:

{
  # Import the shared base configuration
  imports = [ ./common.nix ];

  # --- WSL SPECIFIC PACKAGES ---
  home.packages = [
    pkgs.steamcmd
  ];

  # --- WSL SPECIFIC DOTFILES ---
  xdg.configFile = {
    "topgrade.toml".source = ../config/debian-wsl/topgrade.toml;
  };
}
