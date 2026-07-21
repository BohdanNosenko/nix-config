{
  description = "Modular Multi-Host Declarative Home Configuration";

  # Nix configuration parameters applied during flake commands
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

  inputs = {
    # Pin to the unstable Nixpkgs rolling release
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager source
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Google Antigravity custom flake
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Standard code formatter (run "nix fmt" to clean up code syntax)
      formatter.${system} = pkgs.alejandra;

      # Define configurations for different targets
      homeConfigurations = {
        # Profile 1: Steam Deck
        "deck" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/steamdeck.nix ];
          extraSpecialArgs = { 
            inherit inputs;
            username = "deck";
            homeDirectory = "/home/deck";
          };
        };

        # Profile 2: Debian WSL
        "wsl" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/debian-wsl.nix ];
          extraSpecialArgs = { 
            inherit inputs;
            username = "sart";
            homeDirectory = "/home/sart";
          };
        };
      };
    };
}
