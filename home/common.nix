{ config, pkgs, inputs, username, homeDirectory, ... }:

{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05"; 

  # Allow unfree packages across all systems
  nixpkgs.config.allowUnfree = true;

  # Export Nerd Fonts to system fontstore
  fonts.fontconfig.enable = true;

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

  # --- SHARED USER PACKAGES ---
  home.packages = [
    pkgs.git
    pkgs.bat
    pkgs.btop
    pkgs.eza
    pkgs.fd
    pkgs.ripgrep
    pkgs.starship
    pkgs.topgrade
    pkgs.tmux
    pkgs.nerd-fonts.jetbrains-mono

    # Custom Google Antigravity CLI shared across all machines
    inputs.antigravity-nix.packages.x86_64-linux.google-antigravity-cli
  ];

  # --- SHARED DOTFILES SYMLINKS ---
  xdg.configFile = {
    "nvim".source = ../config/common/nvim;
  };

  # --- SHARED SHELL INTEGRATION ---
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza --icons --group-directories-first --git";
      fetch = "fastfetch";
      tmux = "tmux -S ${homeDirectory}/.tmux.sock";
    };
  };

  # --- NEOVIM INTEGRATION WITH COMPILERS ---
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      gcc
      gnumake
      nodejs
      unzip
      cargo
      rustc
      nil
      pyright
      ruff
    ];
  };

  # --- STARSHIP PROMPT ---
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
}
