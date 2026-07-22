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

  # --- DOTFILES LINKING ---
  home.file.".tmux.conf".source = ../config/common/tmux/tmux.conf;
  home.file.".npmrc".text = ''
    registry=http://registry.npmjs.org/
    strict-ssl=false
  '';

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
    pkgs.difftastic
    pkgs.nerd-fonts.jetbrains-mono

    # Custom Google Antigravity CLI shared across all machines
    inputs.antigravity-nix.packages.x86_64-linux.google-antigravity-cli
  ];

  # --- AUTOMATIC DEV ENVIRONMENT CACHING ---
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # --- SHARED DOTFILES SYMLINKS ---
  xdg.configFile = {
    "nvim".source = ../config/common/nvim;
    "tmux/tmux.conf".source = ../config/common/tmux/tmux.conf;
    "markdownlint/config.json".source = ../config/common/markdownlint/config.json;
  };

  # --- SHARED SHELL INTEGRATION ---
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "eza --icons --group-directories-first --git";
      fetch = "fastfetch";
      tmux = "tmux -S ${homeDirectory}/.tmux.sock -f ${homeDirectory}/.tmux.conf";
    };
  };

  # --- SESSION VARIABLES ---
  home.sessionVariables = {
    NODE_OPTIONS = "--tls-min-v1.2";
  };

  # --- NEOVIM INTEGRATION WITH COMPILERS ---
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      gcc
      gnumake
      nodejs
      python3
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
