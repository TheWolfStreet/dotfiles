{pkgs, ...}: let
  hyprlock-revive = pkgs.writeShellScriptBin "hyprlock-revive" ''
    set -e
    hyprctl keyword misc:allow_session_lock_restore 1
    exec hyprctl dispatch exec hyprlock
  '';
in {
  home.packages = [hyprlock-revive];
}
