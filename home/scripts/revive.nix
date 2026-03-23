{pkgs, ...}: let
  hyprlock-revive = pkgs.writeShellScriptBin "hyprlock-revive" ''
    hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'; hyprctl --instance 0 "dispatch exec hyprlock"
  '';
in {
  home.packages = [hyprlock-revive];
}
