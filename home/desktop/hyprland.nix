{
  pkgs,
  lib,
  config,
  theme,
  ...
}: let
  cursorTheme = theme.cursor;
  toLua = lib.generators.toLua {};
  lua = lib.generators.mkLuaInline;
  exec = command: lua "hl.dsp.exec_cmd(${toLua command})";
  bind = keys: dispatcher: options: {
    _args = [keys dispatcher] ++ lib.optional (options != {}) options;
  };
  window_target = "local a = w.address if not a:match('^0x') then a = '0x' .. a end local target = 'address:' .. a";
  place_presenter = lua ''
    function(w)
      if not w or w.class ~= "org.kde.kdeconnect.daemon" or w.title ~= "KDE Connect Daemon" then return end
      local m = hl.get_monitor_at_cursor()
      if not m then return end
      ${window_target}
      hl.dispatch(hl.dsp.window.move({ x = m.x, y = m.y, window = target }))
      hl.dispatch(hl.dsp.window.resize({ x = math.floor(m.width / m.scale), y = math.floor(m.height / m.scale), window = target }))
    end
  '';
  present_fullscreen = lua ''
    function(w)
      if not w or w.class ~= "libreoffice-impress" or not (w.title or ""):match("^Presenting:") or w.fullscreen == 2 then return end
      ${window_target}
      hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 2, client = 2, window = target }))
    end
  '';
  float_rule = name: class: {
    inherit name;
    match.class = "^(${class})$";
    float = true;
  };

  playerctl = "${pkgs.playerctl}/bin/playerctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  keyboard_backlight = pkgs.writeShellScript "keyboard-backlight" ''
    set -euo pipefail
    case "$*" in
      +1|1-) ;;
      *) printf 'Usage: keyboard-backlight {+1|1-}\n' >&2; exit 2 ;;
    esac
    led_dir=/sys/class/leds
    [ -d "$led_dir" ] || exit 0
    if [ ! -r "$led_dir" ] || [ ! -x "$led_dir" ]; then
      printf 'keyboard-backlight: cannot read LED devices\n' >&2
      exit 1
    fi
    device=
    for led in "$led_dir"/*:kbd_backlight; do
      [ -e "$led" ] || continue
      if [ -n "$device" ]; then
        printf 'keyboard-backlight: multiple devices (%s, %s); select a device explicitly with brightnessctl\n' "$device" "''${led##*/}" >&2
        exit 1
      fi
      device="''${led##*/}"
    done
    [ -n "$device" ] || exit 0
    exec ${brightnessctl} --class=leds --device="$device" set "$1"
  '';
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  hyprlock = "pidof hyprlock || hyprlock";
  touchpad_toggle = import ../scripts/touchpad.nix pkgs;
  jq = "${pkgs.jq}/bin/jq";
  lid_closed = pkgs.writeShellScript "lid-closed" ''
    for lid in /proc/acpi/button/lid/*/state; do
      [ -r "$lid" ] || continue
      ${pkgs.gnugrep}/bin/grep -qi closed "$lid" && exit 0
    done
    exit 1
  '';
  ac_online = pkgs.writeShellScript "ac-online" ''
    has_battery=false
    for p in /sys/class/power_supply/*; do
      case "$(${pkgs.coreutils}/bin/cat "$p/type" 2>/dev/null)" in
        Mains)
          [ "$(${pkgs.coreutils}/bin/cat "$p/online" 2>/dev/null)" = "1" ] && exit 0
          ;;
        Battery)
          has_battery=true
          ;;
      esac
    done
    [ "$has_battery" = false ]
  '';
  lid_close = pkgs.writeShellScript "lid-close" ''
    if [ -z "''${XDG_RUNTIME_DIR:-}" ] || [ ! -d "$XDG_RUNTIME_DIR" ] || [ ! -O "$XDG_RUNTIME_DIR" ] || [ ! -w "$XDG_RUNTIME_DIR" ] || [ "$(${pkgs.coreutils}/bin/stat -c %a "$XDG_RUNTIME_DIR" 2>/dev/null)" != 700 ]; then
      printf 'lid-close: private XDG_RUNTIME_DIR is required\n' >&2
      exit 1
    fi
    state="$XDG_RUNTIME_DIR/hypr-internal-panel-$UID"
    monitors=$(hyprctl monitors all -j) || exit 1
    ${jq} -e 'type == "array" and length > 0 and all(.[]; (.name | type == "string") and (.disabled | type == "boolean"))' <<< "$monitors" >/dev/null || exit 1
    panel=$(${jq} -c '[.[] | select((.name | test("^(eDP|LVDS)"; "i")) and .disabled == false)] | first // empty' <<< "$monitors")
    [ -n "$panel" ] || exit 0
    ${jq} -e '(.width | type == "number") and (.height | type == "number") and (.refreshRate | type == "number") and (.x | type == "number") and (.y | type == "number") and (.scale | type == "number") and (.transform | type == "number")' <<< "$panel" >/dev/null || exit 1

    if [ ! -s "$state" ]; then
      ${jq} -r '.name, "hl.monitor({ output = \(.name | tojson), mode = \("\(.width)x\(.height)@\(.refreshRate)" | tojson), position = \("\(.x)x\(.y)" | tojson), scale = \(.scale), transform = \(.transform), disabled = false })"' \
        <<< "$panel" > "$state" || exit 1
    fi
    hyprctl eval "hl.monitor({ output = $(${jq} -c '.name' <<< "$panel"), disabled = true })" || exit 1

    if ! ${jq} -e 'any(.[]; (.name | test("^(eDP|LVDS)"; "i") | not) and .disabled == false)' <<< "$monitors" >/dev/null; then
      ${ac_online} || ${pkgs.systemd}/bin/systemctl suspend
    fi
  '';
  reapply_lid = pkgs.writeShellScript "reapply-lid" ''
    if ${lid_closed}; then exec ${lid_close}; fi
  '';
  restore_panel = pkgs.writeShellScript "restore-panel" ''
    if [ -z "''${XDG_RUNTIME_DIR:-}" ] || [ ! -d "$XDG_RUNTIME_DIR" ] || [ ! -O "$XDG_RUNTIME_DIR" ] || [ ! -w "$XDG_RUNTIME_DIR" ] || [ "$(${pkgs.coreutils}/bin/stat -c %a "$XDG_RUNTIME_DIR" 2>/dev/null)" != 700 ]; then
      printf 'restore-panel: private XDG_RUNTIME_DIR is required\n' >&2
      exit 1
    fi
    state="$XDG_RUNTIME_DIR/hypr-internal-panel-$UID"
    if ${lid_closed}; then exit 0; fi
    if [ ! -s "$state" ]; then
      ${wake_display}
      exit $?
    fi
    { IFS= read -r name && IFS= read -r monitor_rule; } < "$state"
    [ -n "$name" ] && [ -n "$monitor_rule" ] || exit 1

    ${pkgs.coreutils}/bin/sleep 1
    hyprctl reload >/dev/null || exit 1
    for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
      if ${lid_closed}; then exit 0; fi
      if hyprctl eval "$monitor_rule" >/dev/null && hyprctl dispatch "hl.dsp.dpms({ action = \"on\", monitor = \"$name\" })" >/dev/null &&
        hyprctl monitors -j | ${jq} -e --arg name "$name" 'type == "array" and any(.[]; .name == $name and .dpmsStatus == true)' >/dev/null; then
        ${pkgs.coreutils}/bin/sleep 1
        if ${lid_closed}; then exit 0; fi
        hyprctl dispatch "hl.dsp.dpms({ action = \"on\", monitor = \"$name\" })" >/dev/null || exit 1
        ${pkgs.coreutils}/bin/rm -f "$state"
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    exit 1
  '';
  wake_display = pkgs.writeShellScript "wake-display" ''
    if ${lid_closed}; then
      monitors=$(hyprctl monitors -j) || exit 1
      ${jq} -e 'type == "array" and all(.[]; .name | type == "string")' <<< "$monitors" >/dev/null || exit 1
      failed=0
      while IFS= read -r name; do
        if ! hyprctl dispatch "hl.dsp.dpms({ action = \"on\", monitor = \"$name\" })" >/dev/null; then
          printf 'wake-display: could not wake %s\n' "$name" >&2
          failed=1
        fi
      done < <(${jq} -r '.[] | select(.name | test("^(eDP|LVDS)"; "i") | not) | .name' <<< "$monitors")
      exit "$failed"
    fi
    monitors=$(hyprctl monitors all -j) || exit 1
    ${jq} -e 'type == "array" and all(.[]; .name | type == "string")' <<< "$monitors" >/dev/null || exit 1
    if ! ${jq} -e 'any(.[]; .name | test("^(eDP|LVDS)"; "i"))' <<< "$monitors" >/dev/null; then
      hyprctl dispatch 'hl.dsp.dpms({ action = "on" })' >/dev/null
      exit $?
    fi

    for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
      if ${lid_closed}; then exit 0; fi
      hyprctl dispatch 'hl.dsp.dpms({ action = "on" })' >/dev/null 2>&1
      monitors=$(hyprctl monitors all -j) || exit 1
      ${jq} -e 'type == "array" and all(.[]; (.name | type == "string") and (.dpmsStatus | type == "boolean"))' <<< "$monitors" >/dev/null || exit 1
      if ${jq} -e 'any(.[]; (.name | test("^(eDP|LVDS)"; "i")) and .dpmsStatus == true)' <<< "$monitors" >/dev/null; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.25
    done
    if ${lid_closed}; then exit 0; fi
    hyprctl dispatch 'hl.dsp.dpms({ action = "off" })' >/dev/null 2>&1
    ${pkgs.coreutils}/bin/sleep 0.5
    hyprctl dispatch 'hl.dsp.dpms({ action = "on" })' >/dev/null 2>&1
  '';
  suspend_on_battery = pkgs.writeShellScript "suspend-on-battery" ''
    ${ac_online} && exit 0
    ${pkgs.systemd}/bin/systemctl suspend
  '';
in {
  xdg = {
    configFile."hypr/xdph.conf".text = ''
      screencopy {
        allow_token_by_default = true
      }
    '';

    desktopEntries."org.gnome.Settings" = {
      name = "GNOME Settings";
      comment = "GNOME control center (GNOME settings only)";
      icon = "org.gnome.Settings";
      exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
      categories = ["X-Preferences"];
      terminal = false;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    portalPackage = null;
    configType = "lua";
    systemd.enable = true;
    xwayland.enable = true;

    settings = {
      config = {
        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };

        general = {
          layout = "dwindle";
          allow_tearing = false;
          resize_on_border = true;
        };

        render = {
          direct_scanout = false;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          mouse_move_enables_dpms = true;
          middle_click_paste = false;
          force_default_wallpaper = 0;
        };

        input = {
          follow_mouse = 1;
          kb_options = "grp:alt_shift_toggle";
          touchpad = {
            natural_scroll = true;
            middle_button_emulation = true;
            disable_while_typing = false;
            drag_lock = true;
          };
          sensitivity = 0;
          float_switch_override_focus = 2;
        };

        binds = {
          allow_workspace_cycles = true;
        };

        dwindle = {
          preserve_split = true;
        };

        decoration = {
          shadow = {
            enabled = true;
            range = 8;
            render_power = 2;
            color = "rgba(00000044)";
          };

          dim_inactive = false;

          blur = {
            enabled = true;
            size = 5;
            passes = 5;
            new_optimizations = true;
            noise = 0.01;
            contrast = 1.0;
            brightness = 0.9;
            popups = true;
          };
        };

        animations.enabled = true;
      };

      on = [
        {
          _args = [
            "hyprland.start"
            (lua "function() hl.exec_cmd(${toLua "hyprctl setcursor ${cursorTheme.name} ${toString cursorTheme.size}"}) end")
          ];
        }
        {
          _args = [
            "config.reloaded"
            (lua "function() hl.exec_cmd(${toLua "${reapply_lid}"}) end")
          ];
        }
        {_args = ["window.open" place_presenter];}
        {_args = ["window.open" present_fullscreen];}
        {_args = ["window.title" present_fullscreen];}
      ];

      monitor = [
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1;
        }
      ];

      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        }
        {
          fingers = 2;
          direction = "swipe";
          mods = "SUPER SHIFT";
          action = "resize";
        }
      ];

      bind = let
        shell = request: exec "ags -i ags2-shell ${request}";
        repeating = {repeating = true;};
        locked = {locked = true;};
        locked_repeating = {
          locked = true;
          repeating = true;
        };
        mouse = {mouse = true;};
        push_to_talk = {
          ignore_mods = true;
          dont_inhibit = true;
        };
        workspaces = [1 2 3 4 5 6 7];
        focus = selector: lua "hl.dsp.focus(${toLua selector})";
        move = selector: lua "hl.dsp.window.move(${toLua selector})";
      in
        [
          (bind "CTRL + ALT + Delete" (exec "${pkgs.systemd}/bin/systemctl --user restart ags.service") {})
          (bind "SUPER + R" (shell "toggle launcher") {})
          (bind "SUPER + Tab" (shell "toggle overview") {})
          (bind "SUPER + L" (exec hyprlock) {})

          (bind "XF86PowerOff" (shell "request 'shutdown'") {})
          (bind "SUPER + Print" (shell "request 'record-area'") {})
          (bind "SUPER + SHIFT + Print" (shell "request 'record'") {})
          (bind "Print" (shell "request 'screenshot-area'") {})
          (bind "SHIFT + Print" (shell "request 'screenshot'") {})
          (bind "XF86TouchpadToggle" (exec "${touchpad_toggle}") {})

          (bind "SUPER + B" (exec config.home.sessionVariables.BROWSER) {})
          (bind "SUPER + E" (exec "nautilus") {})
          (bind "SUPER + X" (exec "xterm") {})

          (bind "ALT + Tab" (lua "hl.dsp.window.cycle_next()") {})
          (bind "ALT + Tab" (lua "hl.dsp.window.bring_to_top()") {})
          (bind "ALT + CTRL + Tab" (lua "hl.dsp.window.cycle_next({ next = false })") {})
          (bind "ALT + CTRL + Tab" (lua "hl.dsp.window.bring_to_top()") {})

          (bind "SUPER + CTRL + right" (focus {direction = "right";}) {})
          (bind "SUPER + CTRL + left" (focus {direction = "left";}) {})
          (bind "SUPER + CTRL + up" (focus {direction = "up";}) {})
          (bind "SUPER + CTRL + down" (focus {direction = "down";}) {})

          (bind "SUPER + Q" (lua "hl.dsp.window.close()") {})
          (bind "SUPER + F" (lua "hl.dsp.window.fullscreen()") {})
          (bind "SUPER + SPACE" (lua "hl.dsp.window.float()") {})
          (bind "SUPER + P" (lua "hl.dsp.layout(\"togglesplit\")") {})

          (bind "SUPER + grave" (lua "hl.dsp.workspace.toggle_special()") {})
          (bind "SUPER + SHIFT + grave" (move {workspace = "special";}) {})

          (bind "SUPER + SHIFT + right" (lua "hl.dsp.window.resize({ x = 10, y = 0, relative = true })") repeating)
          (bind "SUPER + SHIFT + left" (lua "hl.dsp.window.resize({ x = -10, y = 0, relative = true })") repeating)
          (bind "SUPER + SHIFT + up" (lua "hl.dsp.window.resize({ x = 0, y = -10, relative = true })") repeating)
          (bind "SUPER + SHIFT + down" (lua "hl.dsp.window.resize({ x = 0, y = 10, relative = true })") repeating)

          (bind "SUPER + right" (move {direction = "right";}) repeating)
          (bind "SUPER + left" (move {direction = "left";}) repeating)
          (bind "SUPER + up" (move {direction = "up";}) repeating)
          (bind "SUPER + down" (move {direction = "down";}) repeating)

          (bind "mouse:276" (exec "${pactl} set-source-mute @DEFAULT_SOURCE@ 0") push_to_talk)
          (bind "mouse:276" (exec "${pactl} set-source-mute @DEFAULT_SOURCE@ 1") (push_to_talk
            // {
              locked = true;
              release = true;
            }))

          (bind "CTRL + F8" (exec "${brightnessctl} set +5%") locked_repeating)
          (bind "CTRL + F7" (exec "${brightnessctl} set 5%-") locked_repeating)
          (bind "XF86MonBrightnessUp" (exec "${brightnessctl} set +5%") locked_repeating)
          (bind "XF86MonBrightnessDown" (exec "${brightnessctl} set  5%-") locked_repeating)
          (bind "XF86AudioRaiseVolume" (exec "${pactl} set-sink-volume @DEFAULT_SINK@ +5%") locked_repeating)
          (bind "XF86AudioLowerVolume" (exec "${pactl} set-sink-volume @DEFAULT_SINK@ -5%") locked_repeating)
          (bind "XF86KbdBrightnessUp" (exec "${keyboard_backlight} +1") locked_repeating)
          (bind "XF86KbdBrightnessDown" (exec "${keyboard_backlight} 1-") locked_repeating)

          (bind "switch:on:Lid Switch" (exec "${lid_close}") locked)
          (bind "switch:off:Lid Switch" (exec "${restore_panel}") locked)

          (bind "XF86Calculator" (exec "gnome-calculator") locked)
          (bind "XF86AudioPlay" (exec "${playerctl} play-pause") locked)
          (bind "XF86AudioStop" (exec "${playerctl} pause") locked)
          (bind "XF86AudioPause" (exec "${playerctl} pause") locked)
          (bind "XF86AudioPrev" (exec "${playerctl} previous") locked)
          (bind "XF86AudioNext" (exec "${playerctl} next") locked)
          (bind "XF86AudioMute" (exec "${pactl} set-sink-mute @DEFAULT_SINK@ toggle") locked)
          (bind "SHIFT + XF86AudioMute" (exec "${pactl} set-source-mute @DEFAULT_SOURCE@ toggle") locked)
          (bind "XF86AudioMicMute" (exec "${pactl} set-source-mute @DEFAULT_SOURCE@ toggle") locked)

          (bind "SUPER + mouse:273" (lua "hl.dsp.window.resize()") mouse)
          (bind "SUPER + mouse:272" (lua "hl.dsp.window.drag()") mouse)
        ]
        ++ map (i: bind "SUPER + ${toString i}" (focus {workspace = i;}) {}) workspaces
        ++ map (i: bind "SUPER + SHIFT + ${toString i}" (move {workspace = i;}) {}) workspaces;

      curve = {
        _args = [
          "elasticSnap"
          {
            type = "bezier";
            points = [[0.12 1.0] [0.45 0.98]];
          }
        ];
      };

      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 3.5;
          bezier = "elasticSnap";
          style = "popin 70%";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 3.8;
          bezier = "elasticSnap";
          style = "slidefade 70%";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 5.0;
          bezier = "elasticSnap";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 4.5;
          bezier = "elasticSnap";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 3.5;
          bezier = "elasticSnap";
        }
      ];

      layer_rule = {
        match.namespace = "gtk4-layer-shell";
        blur = true;
        blur_popups = true;
        ignore_alpha = 0.29;
        no_anim = true;
      };

      window_rule = [
        {
          name = "float_calculator";
          match.class = "^(org.gnome.Calculator)$";
          float = true;
          size = "400 616";
        }
        (float_rule "float_nautilus" "org.gnome.Nautilus")
        (float_rule "float_pavucontrol" "pavucontrol")
        (float_rule "float_nmconnection" "nm-connection-editor")
        (float_rule "float_blueberry" "blueberry.py")
        (float_rule "float_settings" "org.gnome.Settings")
        (float_rule "float_palette" "org.gnome.design.Palette")
        (float_rule "float_colorpicker" "Color Picker")
        (float_rule "float_portal" "xdg-desktop-portal")
        (float_rule "float_portal_gnome" "xdg-desktop-portal-gnome")
        (float_rule "float_fragments" "de.haeckerfelix.Fragments")
        (float_rule "float_ags" "io.Astal.ags2-shell")
        {
          name = "spotify_special";
          match.title = "Spotify";
          workspace = "special";
        }
        {
          name = "discord_special";
          match.title = "Discord";
          workspace = "special";
        }
        {
          name = "xwayland_popups";
          match = {
            xwayland = true;
            float = true;
            title = "^$";
          };
          decorate = false;
          no_blur = true;
          no_shadow = true;
          no_anim = true;
        }
        {
          name = "xembedsniproxy";
          match.class = "^(xembedsniproxy)$";
          workspace = "special:tray silent";
          opacity = "0.0 0.0";
          size = "1 1";
          no_anim = true;
          no_blur = true;
          no_initial_focus = true;
          no_focus = true;
        }
        {
          name = "xwaylandvideobridge";
          match.class = "^(xwaylandvideobridge)$";
          opacity = "0.0 0.0";
          no_anim = true;
          no_initial_focus = true;
          size = "1 1";
          no_blur = true;
        }
        {
          name = "discord_input";
          match.class = "^(discord|vesktop)$";
          allows_input = true;
        }
        {
          name = "kdeconnect_presenter";
          match.class = "^(org.kde.kdeconnect.daemon)$";
          match.title = "^(KDE Connect Daemon)$";
          float = true;
          pin = true;
          move = "0 0";
          size = "monitor_w monitor_h";
          opacity = "1.0 1.0";
          decorate = false;
          no_shadow = true;
          no_blur = true;
          no_anim = true;
          no_focus = true;
          no_initial_focus = true;
          suppress_event = "fullscreen fullscreenoutput maximize activate";
        }
      ];
    };
  };
  services = {
    hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "${restore_panel}; ${wake_display}";
          before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
          ignore_dbus_inhibit = false;
          lock_cmd = "${hyprlock}";
        };
        listener = [
          {
            timeout = 900;
            on-timeout = "${hyprlock}";
          }
          {
            timeout = 1200;
            on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
            on-resume = "${wake_display}";
          }
          {
            timeout = 1800;
            on-timeout = "${suspend_on_battery}";
          }
        ];
      };
    };
  };
  programs.hyprlock = {
    enable = true;
    settings = {
      background = {
        path = "screenshot";
        blur_passes = 5;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };
      label = [
        {
          text = "cmd[update:1000] echo -e \"$(date +\"%A, %B %d\")\"";
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 25;
          font_family = "SF Pro Display Nerd Font Bold";
          position = "0, 350";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:1000] echo \"<span>$(date +\"%H:%M\")</span>\"";
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 120;
          font_family = "SF Pro Display Nerd Font Bold";
          position = "0, 250";
          halign = "center";
          valign = "center";
        }
        {
          text = "$USER";
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 20;
          font_family = "SF Pro Display Nerd Font Bold";
          position = "0, -82";
          halign = "center";
          valign = "center";
        }
        {
          text = builtins.concatStringsSep " " [
            "cmd[update:250] ${pkgs.hyprland}/bin/hyprctl devices -j | ${jq} -r --arg layout '$LAYOUT[en,ru,he]' '"
            ''(.keyboards | map(select(.main == true)) | first) as $keyboard |''
            ''"<span font_desc=\"SFProDisplay Nerd Font 12\">\u21ea</span>" as $caps_icon |''
            ''"<span font_desc=\"SFProDisplay Nerd Font 12\">\uf11c</span>" as $keyboard_icon |''
            ''$keyboard_icon + "  " + $layout + (if $keyboard.capsLock == true then "  " + $caps_icon else "" end)''
            "'"
          ];
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 16;
          font_family = "SF Pro Display Nerd Font Regular";
          position = "0, -210";
          halign = "center";
          valign = "center";
        }
      ];

      image = {
        path = "/var/lib/AccountsService/icons/$USER";
        border_size = 2;
        border_color = "rgba(255, 255, 255, .65)";
        size = 180;
        rounding = -1;
        rotate = 0;
        reload_time = -1;
        reload_cmd = "";
        position = "0, 40";
        halign = "center";
        valign = "center";
      };

      input-field = {
        size = "125, 50";
        dots_center = true;
        outline_thickness = 0;
        outer_color = "rgba(0, 0, 0, 0)";
        inner_color = "rgba(255, 255, 255, 0.1)";
        check_color = "rgba(255, 255, 255, 0.1)";
        fail_color = "rgba(255, 255, 255, 0.1)";
        capslock_color = "rgba(255, 255, 255, 0.1)";
        numlock_color = "rgba(255, 255, 255, 0.1)";
        bothlock_color = "rgba(255, 255, 255, 0.1)";
        font_color = "rgb(200, 200, 200)";
        fade_on_empty = false;
        font_family = "SF Pro Display Nerd Font Regular";
        placeholder_text = "Password";
        fail_text = "Incorrect";
        hide_input = false;
        position = "0, -140";
        halign = "center";
        valign = "center";
      };
    };
  };
}
