pkgs: let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
in
  pkgs.writeShellScript "touchpad" ''
    set -euo pipefail
    if [ -z "''${XDG_RUNTIME_DIR:-}" ] || [ ! -d "$XDG_RUNTIME_DIR" ] || [ ! -O "$XDG_RUNTIME_DIR" ] || [ ! -w "$XDG_RUNTIME_DIR" ] || [ "$(${pkgs.coreutils}/bin/stat -c %a "$XDG_RUNTIME_DIR" 2>/dev/null)" != 700 ] || [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      printf 'touchpad: private runtime directory and compositor instance required\n' >&2
      exit 1
    fi
    devices="$(${hyprctl} devices -j)"
    device="$(${pkgs.jq}/bin/jq -c 'if (.mice | type) == "array" then [.mice[] | select(.name | test("touchpad"; "i"))][0] // empty else error("mice unavailable") end' <<< "$devices")"
    [ -n "$device" ] || exit 0
    name="$(${pkgs.jq}/bin/jq -er '.name | select(type == "string")' <<< "$device")"
    address="$(${pkgs.jq}/bin/jq -er '.address | select(type == "string")' <<< "$device")"
    key="$(printf '%s\n' "$HYPRLAND_INSTANCE_SIGNATURE" "$name" "$address" | ${pkgs.coreutils}/bin/sha256sum)"
    state_file="$XDG_RUNTIME_DIR/touchpad-disabled-''${key%% *}"

    if [ -e "$state_file" ]; then
      ${hyprctl} keyword "device[$name]:enabled" true
      ${pkgs.coreutils}/bin/rm -f "$state_file"
    else
      ${hyprctl} keyword "device[$name]:enabled" false
      : > "$state_file"
    fi
  ''
