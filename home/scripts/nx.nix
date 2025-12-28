{
  pkgs,
  dotfilesPath,
  ...
}: let
  nx-switch = pkgs.writeShellScriptBin "nx-switch" ''
    sudo nixos-rebuild switch --flake "${dotfilesPath}" --impure $@
  '';
  nx-update = pkgs.writeShellScriptBin "nx-update" ''
    cd "${dotfilesPath}"
    nix flake update $@
    sudo nixos-rebuild switch --flake "${dotfilesPath}" --impure
  '';
  nx-boot = pkgs.writeShellScriptBin "nx-boot" ''
    sudo nixos-rebuild boot --flake "${dotfilesPath}" --impure $@
  '';
  nx-test = pkgs.writeShellScriptBin "nx-test" ''
    sudo nixos-rebuild test --flake "${dotfilesPath}" --impure $@
  '';
  nx-vm = pkgs.writeShellScriptBin "nx-vm" ''
    cd "${dotfilesPath}"
    nixos-rebuild build-vm --flake . --impure $@
    "${dotfilesPath}/result/bin/run-$(hostname)-vm"
  '';
  nx-gc = pkgs.writeShellScriptBin "nx-gc" ''
    sudo nix-collect-garbage -d
    home-manager expire-generations "-1 days"
    sudo nix-store --optimize
    sudo nix-collect-garbage --delete-older-than 1d
  '';
in {
  home.packages = [nx-switch nx-update nx-boot nx-test nx-vm nx-gc];
}
