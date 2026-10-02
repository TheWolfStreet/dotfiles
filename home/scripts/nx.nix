{
  config,
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
      printf 'Rebuilding %s: %s\n' '${configurationName}' '${action}'
      exec sudo nixos-rebuild ${action} --flake "${dotfilesPath}#${configurationName}" --impure "$@"
    '';

  nx-switch = rebuild "switch";
  nx-boot = rebuild "boot";
  nx-test = rebuild "test";

  nx-update = pkgs.writeShellScriptBin "nx-update" ''
    set -euo pipefail
    cd "${dotfilesPath}"
    printf 'Updating flake inputs for %s\n' '${configurationName}'
    if ! nix flake update "$@"; then
      printf 'Input update failed; no rebuild was started. Inspect the lockfile before retrying.\n' >&2
      exit 1
    fi
    printf 'Building and activating %s\n' '${configurationName}'
    if ! sudo nixos-rebuild switch --flake "${dotfilesPath}#${configurationName}" --impure; then
      printf 'Build or activation failed; the updated lockfile was left intact. Inspect the output and system state before retrying.\n' >&2
      exit 1
    fi
  '';
  nx-vm = pkgs.writeShellScriptBin "nx-vm" ''
    set -euo pipefail
    cd "${dotfilesPath}"
    nixos-rebuild build-vm --flake ".#${configurationName}" --impure "$@"
    exec "${dotfilesPath}/result/bin/run-${hostname}-vm"
  '';
  nx-gc = pkgs.writeShellScriptBin "nx-gc" ''
    set -euo pipefail
    hm_profile_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
    if [ ! -d "$hm_profile_dir" ]; then
      hm_profile_dir="''${NIX_STATE_DIR:-/nix/var/nix}/profiles/per-user/$USER"
    fi
    case "$*" in
      --yes) ;;
      "")
        printf 'This deletes Home Manager generations older than one day and all old root-profile Nix generations.\n'
        if [ -e "$hm_profile_dir/home-manager" ] || [ -L "$hm_profile_dir/home-manager" ]; then
          ${config.programs.home-manager.package}/bin/home-manager generations
        else
          printf 'No standalone Home Manager profile; generations are managed by NixOS.\n'
        fi
        sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
        if ! read -r -p 'Delete old generations and collect garbage? [y/N] ' answer || [ "$answer" != y ]; then
          printf 'Cancelled; no generations were deleted.\n'
          exit 0
        fi
        ;;
      *) printf 'Usage: nx-gc [--yes]\n' >&2; exit 2 ;;
    esac
    if [ -e "$hm_profile_dir/home-manager" ] || [ -L "$hm_profile_dir/home-manager" ]; then
      ${config.programs.home-manager.package}/bin/home-manager expire-generations "-1 days"
    fi
    sudo nix-collect-garbage -d
    sudo nix-store --optimize
  '';
in {
  home.packages = [nx-switch nx-update nx-boot nx-test nx-gc] ++ lib.optional virtualisationEnabled nx-vm;
}
