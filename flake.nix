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
  }: let
    system = "x86_64-linux";
    constants = import ./nixos/constants.nix;

    mkSystem = {
      hostname,
      extraModules ? [],
      extraArgs ? {},
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs =
          {
            inherit inputs;
            username = constants.system.username;
          }
          // extraArgs;

        modules =
          [
            ./nixos/nixos.nix
            home-manager.nixosModules.home-manager
            {
              networking.hostName = hostname;
            }
          ]
          ++ extraModules;
      };
  in {
    nixosConfigurations = {
      nixos = mkSystem {
        hostname = "nixos";
        extraModules = [
          {
            desktopPC.enable = true;
            hardware.nvidia.desktop.enable = true;
          }
        ];
      };

      nixtop = mkSystem {
        hostname = "nixtop";
        extraModules = [
          {
            asusLaptop.enable = true;
            hardware.amd.laptop.enable = true;
            swapDevices = [
              {
                device = "/var/lib/swapfile";
                size = constants.system.swapSizeGB * 1024;
              }
            ];
          }
        ];
      };
    };
  };
}
