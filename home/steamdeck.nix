{ config, pkgs, inputs, ... }:

{
  # Import the shared base configuration
  imports = [ ./common.nix ];

  # --- STEAM DECK SPECIFIC PACKAGES ---
  home.packages = [
    pkgs.podman-compose
    pkgs.steamcmd
  ];

  # --- STEAM DECK SPECIFIC DOTFILES ---
  xdg.configFile = {
    "topgrade.toml".source = ../config/steamdeck/topgrade.toml;
  };
}
