{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mactahoe-icon-theme = {
      url = "github:TheWolfStreet/MacTahoe-icon-theme.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags2-shell = {
      url = "path:./ags2-shell";
      inputs.ags.follows = "ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    self.submodules = true;
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    defaultUsername = "tws";
    gitName = "TheWolfStreet";
    gitEmail = "wolfthestreet@gmail.com";
    stateVersion = "24.05";

    hosts = {
      ironmaiden.username = "ghost";
      nixos = {};
      nixtop = {};
    };

    mkSystem = configurationName: {
      username ? defaultUsername,
      hostname ? configurationName,
    }: let
      dotfilesPath = "/home/${username}/.dotfiles";
    in
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs configurationName username hostname gitName gitEmail stateVersion dotfilesPath;
        };

        modules = [
          ./hosts/${configurationName}.nix
          home-manager.nixosModules.home-manager
        ];
      };
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem hosts;
  };
}
