{
  outputs = inputs @ {
    self,
    home-manager,
    nixpkgs,
    ...
  }: let
    platform = builtins.currentSystem;
  in {
    packages.${platform}.default =
      nixpkgs.legacyPackages.${platform}.callPackage ./ags {inherit inputs;};
    nixosConfigurations = {
      "nixos" = nixpkgs.lib.nixosSystem {
        system = "${platform}";
        specialArgs = {
          inherit inputs;
          asztal = self.packages.${platform}.default;
        };
        modules = [
          ./nixos/nixos.nix
          home-manager.nixosModules.home-manager
          {networking.hostName = "nixos";}
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
    ags.url = "github:Aylur/ags";
    astal.url = "github:Aylur/astal";

    lf-icons = {
      url = "github:gokcehan/lf";
      flake = false;
    };
  };
}
