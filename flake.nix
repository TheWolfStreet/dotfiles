{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";

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
  }:
  let
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
            username = "tws";
            stateVersion = "24.05";
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
