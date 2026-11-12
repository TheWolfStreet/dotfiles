{
  pkgs,
  lib,
  ...
}: let
  hyprlock-revive = pkgs.writeShellScriptBin "hyprlock-revive" ''
    set -euo pipefail
    if [ "$#" -gt 1 ]; then
      printf 'Usage: hyprlock-revive [instance]\n' >&2
      exit 2
    fi
    instance="''${1:-0}"
    ${pkgs.hyprland}/bin/hyprctl -i "$instance" eval 'hl.config({ misc = { allow_session_lock_restore = true } })'
    exec ${pkgs.hyprland}/bin/hyprctl -i "$instance" dispatch ${lib.escapeShellArg "hl.dsp.exec_cmd(${lib.generators.toLua {} "${pkgs.hyprlock}/bin/hyprlock"})"}
  '';
in {
  home.packages = [hyprlock-revive];
}
