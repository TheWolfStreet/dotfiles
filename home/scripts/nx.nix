{pkgs, ...}: let
  dotfiles = "$HOME/.dotfiles";
  nx-switch = pkgs.writeShellScriptBin "nx-switch" ''
    sudo nixos-rebuild switch --flake "${dotfiles}" --impure $@
  '';
  nx-boot = pkgs.writeShellScriptBin "nx-boot" ''
    sudo nixos-rebuild boot --flake "${dotfiles}" --impure $@
  '';
  nx-test = pkgs.writeShellScriptBin "nx-test" ''
    sudo nixos-rebuild test --flake "${dotfiles}" --impure $@
  '';
  nx-vm = pkgs.writeShellScriptBin "nx-vm" ''
    cd "${dotfiles}"
    nixos-rebuild build-vm --flake . --impure $@
    ./result/bin/run-nixos-vm
  '';
  nx-gc = pkgs.writeShellScriptBin "nx-gc" ''
    sudo nix-collect-garbage -d
    home-manager expire-generations "-1 days"
    sudo nix-store --optimize
    sudo nix-collect-garbage --delete-older-than 1d
  '';
in {
  home.packages = [nx-switch nx-boot nx-test nx-vm nx-gc];
}
