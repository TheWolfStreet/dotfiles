{
  description = "Advanced example of Nix-on-Droid system config with home-manager.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    lf-icons = {
      url = "github:gokcehan/lf";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nix-on-droid,
    ...
  }: {
    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      modules = [
        ./nix-on-droid.nix
      ];

      extraSpecialArgs = {
        inherit inputs;
      };

      pkgs = import nixpkgs {
        system = "aarch64-linux";

        overlays = [
          nix-on-droid.overlays.default
        ];
      };

      home-manager-path = home-manager.outPath;
    };
  };
}
