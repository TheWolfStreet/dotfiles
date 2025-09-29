{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./home-manager/nvim.nix
    ./home-manager/starship.nix
    ./home-manager/sh.nix
    ./home-manager/git.nix
    ./home-manager/lf.nix
    ./home-manager/tmux.nix
  ];
  home.stateVersion = "24.05";
}
