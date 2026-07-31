pkgs: let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
in
  pkgs.writeShellScript "touchpad" ''
    set -euo pipefail
    device="$(${hyprctl} devices -j | ${pkgs.jq}/bin/jq -r '[.mice[].name | select(test("touchpad"; "i"))][0] // empty')"
    [ -n "$device" ] || exit 0

    state_file="''${XDG_RUNTIME_DIR:-/run/user/$UID}/touchpad-disabled"
    if [ -e "$state_file" ]; then
      ${hyprctl} keyword "device[$device]:enabled" true
      ${pkgs.coreutils}/bin/rm -f "$state_file"
    else
      ${hyprctl} keyword "device[$device]:enabled" false
      : > "$state_file"
    fi
  ''
