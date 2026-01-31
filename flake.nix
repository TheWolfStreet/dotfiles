{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";

    mactahoe-icon-theme.url = "github:TheWolfStreet/MacTahoe-icon-theme.nix";

    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lf-icons = {
      url = "github:gokcehan/lf";
      flake = false;
    };
    self.submodules = true;
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    username = "tws";
    gitName = "TheWolfStreet";
    gitEmail = "wolfthestreet@gmail.com";
    stateVersion = "24.05";
    dotfilesPath = "/home/${username}/.dotfiles";

    mkSystem = {
      hostname,
      extraModules ? [],
      extraArgs ? {},
    }:
      nixpkgs.lib.nixosSystem {
        system = builtins.currentSystem;

        specialArgs =
          {
            inherit inputs;
            inherit username;
            inherit hostname;
            inherit gitName;
            inherit gitEmail;
            inherit stateVersion;
            inherit dotfilesPath;
          }
          // extraArgs;

        modules =
          [
            ./hosts/${hostname}.nix
            home-manager.nixosModules.home-manager
          ]
          ++ extraModules;
      };
  in {
    nixosConfigurations = {
      nixos = mkSystem {
        hostname = "nixos";
      };

      nixtop = mkSystem {
        hostname = "nixtop";
      };
    };
  };
}
