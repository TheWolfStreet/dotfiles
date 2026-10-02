{pkgs, ...}: let
  hyprlock-revive = pkgs.writeShellScriptBin "hyprlock-revive" ''
    set -euo pipefail
    if [ "$#" -gt 1 ]; then
      printf 'Usage: hyprlock-revive [instance]\n' >&2
      exit 2
    fi
    instance="''${1:-''${HYPRLAND_INSTANCE_SIGNATURE:-}}"
    if [ -z "$instance" ]; then
      printf 'Choose an instance from hyprctl instances, then run hyprlock-revive <instance>.\n' >&2
      exit 1
    fi
    ${pkgs.hyprland}/bin/hyprctl -i "$instance" keyword misc:allow_session_lock_restore 1
    exec ${pkgs.hyprland}/bin/hyprctl -i "$instance" dispatch exec ${pkgs.hyprlock}/bin/hyprlock
  '';
in {
  home.packages = [hyprlock-revive];
}
