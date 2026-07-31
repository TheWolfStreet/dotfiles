{
  lib,
  pkgs,
  configurationName,
  hostname,
  dotfilesPath,
  virtualisationEnabled,
  ...
}: let
  rebuild = action:
    pkgs.writeShellScriptBin "nx-${action}" ''
      set -euo pipefail
      exec sudo nixos-rebuild ${action} --flake "${dotfilesPath}#${configurationName}" --impure "$@"
    '';

  nx-switch = rebuild "switch";
  nx-boot = rebuild "boot";
  nx-test = rebuild "test";

  nx-update = pkgs.writeShellScriptBin "nx-update" ''
    set -euo pipefail
    cd "${dotfilesPath}"
    nix flake update "$@"
    exec sudo nixos-rebuild switch --flake "${dotfilesPath}#${configurationName}" --impure
  '';
  nx-vm = pkgs.writeShellScriptBin "nx-vm" ''
    set -euo pipefail
    cd "${dotfilesPath}"
    nixos-rebuild build-vm --flake ".#${configurationName}" --impure "$@"
    exec "${dotfilesPath}/result/bin/run-${hostname}-vm"
  '';
  nx-gc = pkgs.writeShellScriptBin "nx-gc" ''
    set -euo pipefail
    home-manager expire-generations "-1 days"
    sudo nix-collect-garbage -d
    sudo nix-store --optimize
  '';
in {
  home.packages = [nx-switch nx-update nx-boot nx-test nx-gc] ++ lib.optional virtualisationEnabled nx-vm;
}
