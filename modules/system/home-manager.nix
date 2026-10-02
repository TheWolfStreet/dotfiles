{
  config,
  inputs,
  configurationName,
  username,
  hostname,
  stateVersion,
  dotfilesPath,
  gitName,
  gitEmail,
  pkgs,
  ...
}: let
  mkTheme = scheme: import ../../home/desktop/defs.nix {inherit pkgs inputs scheme;};
in {
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs configurationName hostname stateVersion dotfilesPath gitName gitEmail mkTheme;
      virtualisationEnabled = config.virtualisation.enable;
      theme = mkTheme "dark";
    };
    users.${username} = {
      imports = [
        ../../home/terminal
        ../../home/nvim
        ../../home/desktop
        ../../home/dev
        ../../home/music.nix
        ../../home/packages.nix
        ../../home/scripts/nx.nix
        ../../home/scripts/revive.nix
        ../../home/easyeffects
      ];

      programs.home-manager.enable = true;
      home = {
        inherit username stateVersion;
        homeDirectory = "/home/${username}";
        sessionPath = ["$HOME/.local/bin"];
      };
    };
  };
}
