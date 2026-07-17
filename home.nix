{ config, pkgs, inputs, username, homeDirectory, ... }:

{
  # Dynamically resolved arguments passed from flake.nix
  home.username = username;
  home.homeDirectory = homeDirectory;

  # --- READ-ONLY STATE VERSION WARNING ---
  # This value determines the Home Manager release that your configuration is
  # compatible with. It prevents Home Manager from breaking your setup if a 
  # future release changes default configuration behaviors. 
  # Set to "26.05" as this matches your active installation defaults.
  home.stateVersion = "26.05"; 

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # --- DECLARATIVE GIT CONFIGURATION ---
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "BohdanNosenko";
        email = "nosenko.bog@gmail.com";
      };
    };
  };

  # --- GLOBAL USER PACKAGES ---
  home.packages = [
    # Core system tools
    pkgs.git
    pkgs.bat
    pkgs.btop
    pkgs.eza
    pkgs.fd
    pkgs.ripgrep
    pkgs.starship
    pkgs.topgrade
    pkgs.podman-compose

    # Custom Google Antigravity CLI (fetched dynamically from inputs)
    inputs.antigravity-nix.packages.x86_64-linux.google-antigravity-cli
  ];

  # --- NEOCIM WRAPPER ---
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      # Core build utilities for lazy.nvim extensions and tree-sitter
      gcc
      gnumake
      nodejs
      unzip
      cargo
      rustc

      # LSP, Linters, and Formatters
      nil
      pyright
      ruff
    ];
  };

  # --- DOTFILES SYMLINKS (XDG CONFIG) ---
  # Home Manager will symlink files directly from your Git repository into ~/.config/
  xdg.configFile = {
    # Symlink your Neovim configurations directory
    "nvim".source = ./config/nvim;

    # Symlink your Topgrade configuration file
    "topgrade.toml".source = ./config/topgrade.toml;
  };

  # --- SHELL & PROMPT INTEGRATION ---
  # Installs Fish shell and declares custom functions/aliases
  programs.fish = {
    enable = true;

    # Declarative wrapper functions for your custom commands.
    # Home Manager automatically appends the '--wraps' parameter behind the scenes
    # to preserve command-line autocomplete behaviors (e.g. for eza and fastfetch).
    shellAliases = {
      # Custom ls wrapper (wraps eza with standard flags)
      ls = "eza --icons --group-directories-first --git";

      # Custom fetch wrapper (wraps fastfetch)
      fetch = "fastfetch";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
}
