{
  outputs = inputs @ {
    self,
    home-manager,
    nixpkgs,
    ...
  }: let
    platform = "x86_64-linux";
    common_args = {
      inherit inputs;
      asztal = self.packages.${platform}.default;
      username = "tws";
    };
    common_mods = [
      ./nixos/nixos.nix
      home-manager.nixosModules.home-manager
    ];
  in {
    packages.${platform}.default =
      nixpkgs.legacyPackages.${platform}.callPackage ./ags {inherit inputs;};

    nixosConfigurations = {
      "nixos" = nixpkgs.lib.nixosSystem {
        system = platform;
        specialArgs =
          common_args
          // {
            desktopPC.enable = true;
          };
        modules =
          common_mods
          ++ [
            {networking.hostName = "nixos";}
          ];
      };

      "nixtop" = nixpkgs.lib.nixosSystem {
        system = platform;
        specialArgs =
          common_args
          // {
            asusLaptop.enable = true;
          };
        modules =
          common_mods
          ++ [
            {
              networking.hostName = "nixtop";
              swapDevices = [
                {
                  device = "/var/lib/swapfile";
                  size = 16 * 1024;
                }
              ];
            }
          ];
      };
    };
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    matugen.url = "github:InioX/matugen?ref=v2.2.0";
    ags.url = "github:Aylur/ags/v1";
    astal.url = "github:Aylur/astal";

    lf-icons = {
      url = "github:gokcehan/lf";
      flake = false;
    };
  };
}
