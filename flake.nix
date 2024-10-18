{
  outputs = inputs @ {
    self,
    home-manager,
    nixpkgs,
    ...
  }: {
    packages.x86_64-linux.default =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./ags {inherit inputs;};

    nixosConfigurations = {
      "nixos" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          asztal = self.packages.x86_64-linux.default;
        };
        modules = [
          ./nixos/nixos.nix
          home-manager.nixosModules.home-manager
          {
            networking.hosts = {
              "127.0.0.1" = ["localhost" "nixos"];
            };
          }
        ];
      };
    };
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-hyprspace = {
      url = "github:KZDKM/Hyprspace";
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
