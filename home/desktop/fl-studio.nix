{
  pkgs,
  lib,
  ...
}: let
  jq = "${pkgs.jq}/bin/jq";
  set_prop = prop: value: ''hl.dispatch(hl.dsp.window.set_prop({ prop = \"${prop}\", value = \"${value}\", window = \"address:$address\" }))'';

  hide_fl_vcl_window = pkgs.writeShellScript "hide-fl-vcl-window" ''
    hyprctl clients -j | ${jq} -r '
      .[]
      | select(
          .class == "fl64.exe"
          and .title == ""
          and .initialTitle == ""
          and .xwayland
          and .floating
          and .size == [800, 800]
        )
      | .address
    ' | while IFS= read -r address; do
      [ -n "$address" ] || continue
      hyprctl eval "${set_prop "opacity" "0"} ${set_prop "no_focus" "1"} hl.dispatch(hl.dsp.window.resize({ x = 1, y = 1, window = \"address:$address\" }))" >/dev/null
    done
  '';

  hide_fl_vst_popup_borders = pkgs.writeShellScript "hide-fl-vst-popup-borders" ''
    hyprctl clients -j | ${jq} -r '
      . as $windows
      | .[]
      | select(
          .class == "fl64.exe"
          and .title == ""
          and .initialTitle == ""
          and .xwayland
          and ((.size[0] == 12 and .size[1] > 12) or (.size[1] == 12 and .size[0] > 12))
          and any($windows[]; .class == "fl64.exe" and .title == "menu")
        )
      | .address
    ' | {
      batch=""
      while IFS= read -r address; do
        [ -n "$address" ] || continue
        batch="$batch ${set_prop "opacity" "0"}"
        batch="$batch ${set_prop "opacity_override" "1"}"
        batch="$batch ${set_prop "opacity_inactive" "0"}"
        batch="$batch ${set_prop "opacity_inactive_override" "1"}"
        batch="$batch ${set_prop "no_focus" "1"}"
      done
      [ -z "$batch" ] || hyprctl eval "$batch" >/dev/null
    }
  '';

  fl_window_watcher = pkgs.writeShellScript "fl-window-watcher" ''
    socket="''${XDG_RUNTIME_DIR}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

    ${hide_fl_vcl_window}
    ${hide_fl_vst_popup_borders}

    while true; do
      while [ ! -S "$socket" ]; do
        ${pkgs.coreutils}/bin/sleep 1
      done

      ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$socket" | while IFS= read -r event; do
        case "$event" in
          openwindow*fl64.exe*)
            ${hide_fl_vst_popup_borders}
            ${hide_fl_vcl_window}
            ;;
        esac
      done

      ${pkgs.coreutils}/bin/sleep 1
    done
  '';
in {
  wayland.windowManager.hyprland.settings.on = [
    {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline "function() hl.exec_cmd(${lib.generators.toLua {} "${fl_window_watcher}"}) end")
      ];
    }
  ];
}
