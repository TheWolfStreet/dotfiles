{
  pkgs,
  config,
  theme,
  ...
}: let
  cursorTheme = theme.cursor;

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
    if ! ${jq} -e 'any(.[]; (.name | test("^(eDP|LVDS)"; "i") | not) and .disabled == false)' <<< "$monitors" >/dev/null; then
      ${ac_online} || ${pkgs.systemd}/bin/systemctl suspend
      exit 0
    fi

    panel=$(${jq} -c '[.[] | select((.name | test("^(eDP|LVDS)"; "i")) and .disabled == false)] | first // empty' <<< "$monitors")
    [ -n "$panel" ] || exit 0
    ${jq} -e '(.width | type == "number") and (.height | type == "number") and (.refreshRate | type == "number") and (.x | type == "number") and (.y | type == "number") and (.scale | type == "number") and (.transform | type == "number")' <<< "$panel" >/dev/null || exit 1

    name=$(${jq} -r '.name' <<< "$panel")
    if [ ! -s "$state" ]; then
      ${jq} -r '[.name, "\(.width)x\(.height)@\(.refreshRate)", "\(.x)x\(.y)", (.scale | tostring), "transform", (.transform | tostring)] | join(",")' \
        <<< "$panel" > "$state" || exit 1
    fi
    hyprctl keyword monitor "$name,disable" || exit 1
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
    IFS= read -r monitor_rule < "$state"
    [ -n "$monitor_rule" ] || exit 1
    name="''${monitor_rule%%,*}"

    ${pkgs.coreutils}/bin/sleep 1
    hyprctl reload >/dev/null || exit 1
    for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
      if ${lid_closed}; then exit 0; fi
      if hyprctl keyword monitor "$monitor_rule" >/dev/null && hyprctl dispatch dpms on "$name" >/dev/null &&
        hyprctl monitors -j | ${jq} -e --arg name "$name" 'type == "array" and any(.[]; .name == $name and .dpmsStatus == true)' >/dev/null; then
        ${pkgs.coreutils}/bin/sleep 1
        if ${lid_closed}; then exit 0; fi
        hyprctl dispatch dpms on "$name" >/dev/null || exit 1
        ${pkgs.coreutils}/bin/rm -f "$state"
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    exit 1
  '';
  wake_display = pkgs.writeShellScript "wake-display" ''
    # amdgpu can fail to relight the internal panel after s2idle when the lid was closed during
    # suspend. Nudge DPMS on, retrying until the panel reports on; if it never
    # does, force a full modeset toggle as a last resort.
    if ${lid_closed}; then
      monitors=$(hyprctl monitors -j) || exit 1
      ${jq} -e 'type == "array" and all(.[]; .name | type == "string")' <<< "$monitors" >/dev/null || exit 1
      failed=0
      while IFS= read -r name; do
        if ! hyprctl dispatch dpms on "$name" >/dev/null; then
          printf 'wake-display: could not wake %s\n' "$name" >&2
          failed=1
        fi
      done < <(${jq} -r '.[] | select(.name | test("^(eDP|LVDS)"; "i") | not) | .name' <<< "$monitors")
      exit "$failed"
    fi
    monitors=$(hyprctl monitors all -j) || exit 1
    ${jq} -e 'type == "array" and all(.[]; .name | type == "string")' <<< "$monitors" >/dev/null || exit 1
    if ! ${jq} -e 'any(.[]; .name | test("^(eDP|LVDS)"; "i"))' <<< "$monitors" >/dev/null; then
      hyprctl dispatch dpms on >/dev/null
      exit $?
    fi

    for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
      if ${lid_closed}; then exit 0; fi
      hyprctl dispatch dpms on >/dev/null 2>&1
      monitors=$(hyprctl monitors all -j) || exit 1
      ${jq} -e 'type == "array" and all(.[]; (.name | type == "string") and (.dpmsStatus | type == "boolean"))' <<< "$monitors" >/dev/null || exit 1
      if ${jq} -e 'any(.[]; (.name | test("^(eDP|LVDS)"; "i")) and .dpmsStatus == true)' <<< "$monitors" >/dev/null; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.25
    done
    if ${lid_closed}; then exit 0; fi
    hyprctl dispatch dpms off >/dev/null 2>&1
    ${pkgs.coreutils}/bin/sleep 0.5
    hyprctl dispatch dpms on >/dev/null 2>&1
  '';
  suspend_on_battery = pkgs.writeShellScript "suspend-on-battery" ''
    ${ac_online} && exit 0
    ${pkgs.systemd}/bin/systemctl suspend
  '';
in {
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = ["hyprland" "gtk"];
  };

  xdg.desktopEntries."org.gnome.Settings" = {
    name = "GNOME Settings";
    comment = "GNOME control center (GNOME settings only)";
    icon = "org.gnome.Settings";
    exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
    categories = ["X-Preferences"];
    terminal = false;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    systemd.enable = true;
    xwayland.enable = true;

    settings = {
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      exec-once = [
        "hyprctl setcursor ${cursorTheme.name} ${toString cursorTheme.size}"
      ];

      monitor = [
        ",preferred,auto,1"
      ];

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
          natural_scroll = "yes";
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
        preserve_split = "yes";
      };

      gesture = [
        "3, horizontal, workspace"
        "2, swipe, mod: SUPER+SHIFT, resize"
      ];

      bind = let
        binding = mod: cmd: key: arg: "${mod}, ${key}, ${cmd}, ${arg}";
        ws = binding "SUPER" "workspace";
        mvtows = binding "SUPER SHIFT" "movetoworkspace";
        e = "exec, ags -i ags2-shell";
        arr = [1 2 3 4 5 6 7];
      in
        [
          "CTRL ALT, Delete, exec, ${pkgs.systemd}/bin/systemctl --user restart ags.service"
          "SUPER, R,         ${e} toggle launcher"
          "SUPER, Tab,       ${e} toggle overview"
          "SUPER, L,         exec, ${hyprlock}"

          ",XF86PowerOff,    ${e} request 'shutdown'"
          "SUPER, Print,   ${e} request 'record-area'"
          "SUPER SHIFT, Print,   ${e} request 'record'"
          ", Print,   ${e} request 'screenshot-area'"
          "SHIFT, Print,   ${e} request 'screenshot'"
          ",XF86TouchpadToggle, exec, ${touchpad_toggle}"

          "SUPER, B, exec,   ${config.home.sessionVariables.BROWSER}"
          "SUPER, E, exec,   nautilus"
          "SUPER, X, exec,   xterm" # A symlink to other terminal

          # Alt + TAB switch
          "ALT, Tab, cyclenext"
          "ALT, Tab, bringactivetotop"
          "ALT CTRL, Tab, cyclenext, prev"
          "ALT CTRL, Tab, bringactivetotop"

          "SUPER CTRL, right, movefocus, r"
          "SUPER CTRL, left, movefocus, l"
          "SUPER CTRL, up, movefocus, u"
          "SUPER CTRL, down, movefocus, d"

          "SUPER, Q, killactive"
          "SUPER, F, fullscreen"
          "SUPER, SPACE, togglefloating"
          "SUPER, P, layoutmsg, togglesplit"

          "SUPER, grave, togglespecialworkspace"
          "SUPER SHIFT, grave, movetoworkspace, special"
        ]
        ++ (map (i: ws (toString i) (toString i)) arr)
        ++ (map (i: mvtows (toString i) (toString i)) arr);

      binde = [
        # Resize window with arrow keys
        "SUPER SHIFT, right, resizeactive, 10 0"
        "SUPER SHIFT, left, resizeactive,-10 0"
        "SUPER SHIFT, up, resizeactive, 0 -10"
        "SUPER SHIFT, down, resizeactive, 0 10"

        # Move window with arrow keys
        "SUPER, right, movewindow, r"
        "SUPER, left, movewindow, l"
        "SUPER, up, movewindow, u"
        "SUPER, down, movewindow, d"
      ];

      # Push to talk
      bindip = ",mouse:276, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ 0";
      bindilpr = ",mouse:276, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ 1";

      bindle = [
        "CTRL, F8,               exec, ${brightnessctl} set +5%"
        "CTRL, F7,               exec, ${brightnessctl} set 5%-"
        ",XF86MonBrightnessUp,   exec, ${brightnessctl} set +5%"
        ",XF86MonBrightnessDown, exec, ${brightnessctl} set  5%-"
        ",XF86AudioRaiseVolume,  exec, ${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
        ",XF86AudioLowerVolume,  exec, ${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
        ",XF86KbdBrightnessUp,   exec, ${keyboard_backlight} +1"
        ",XF86KbdBrightnessDown, exec, ${keyboard_backlight} 1-"
      ];

      bindl = [
        ",switch:on:Lid Switch,  exec, ${lid_close}"
        ",switch:off:Lid Switch, exec, ${restore_panel}"

        ",XF86Calculator,      exec, gnome-calculator"
        ",XF86AudioPlay,       exec, ${playerctl} play-pause"
        ",XF86AudioStop,       exec, ${playerctl} pause"
        ",XF86AudioPause,      exec, ${playerctl} pause"
        ",XF86AudioPrev,       exec, ${playerctl} previous"
        ",XF86AudioNext,       exec, ${playerctl} next"
        ",XF86AudioMute,       exec, ${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
        "SHIFT ,XF86AudioMute, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
        ",XF86AudioMicMute,    exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
      ];

      bindm = [
        "SUPER, mouse:273, resizewindow"
        "SUPER, mouse:272, movewindow"
      ];

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
          new_optimizations = "on";
          noise = 0.01;
          contrast = 1.0;
          brightness = 0.9;
          popups = true;
        };
      };

      animations = {
        enabled = "yes";
        bezier = "elasticSnap, 0.12, 1.0, 0.45, 0.98";
        animation = [
          "windows, 1, 3.5, elasticSnap, popin 70%"
          "windowsOut, 1, 3.8, elasticSnap, slidefade 70%"
          "border, 1, 5.0, elasticSnap"
          "fade, 1, 4.5, elasticSnap"
          "workspaces, 1, 3.5, elasticSnap"
        ];
      };

      layerrule = [
        "blur on, match:namespace gtk4-layer-shell"
        "blur_popups on, match:namespace gtk4-layer-shell"
        "ignore_alpha 0.29, match:namespace gtk4-layer-shell"
        "no_anim on, match:namespace gtk4-layer-shell"
      ];
    };

    extraConfig = ''
      windowrule {
        name = float_calculator
        match:class = ^(org.gnome.Calculator)$
        float = on
        size = 400 616
      }

      windowrule {
        name = float_nautilus
        match:class = ^(org.gnome.Nautilus)$
        float = on
      }

      windowrule {
        name = float_pavucontrol
        match:class = ^(pavucontrol)$
        float = on
      }

      windowrule {
        name = float_nmconnection
        match:class = ^(nm-connection-editor)$
        float = on
      }

      windowrule {
        name = float_blueberry
        match:class = ^(blueberry.py)$
        float = on
      }

      windowrule {
        name = float_settings
        match:class = ^(org.gnome.Settings)$
        float = on
      }

      windowrule {
        name = float_palette
        match:class = ^(org.gnome.design.Palette)$
        float = on
      }

      windowrule {
        name = float_colorpicker
        match:class = ^(Color Picker)$
        float = on
      }

      windowrule {
        name = float_portal
        match:class = ^(xdg-desktop-portal)$
        float = on
      }

      windowrule {
        name = float_portal_gnome
        match:class = ^(xdg-desktop-portal-gnome)$
        float = on
      }

      windowrule {
        name = float_fragments
        match:class = ^(de.haeckerfelix.Fragments)$
        float = on
      }

      windowrule {
        name = float_ags
        match:class = ^(io.Astal.ags2-shell)$
        float = on
      }

      windowrule {
        name = spotify_special
        match:title = Spotify
        workspace = special
      }

      windowrule {
        name = discord_special
        match:title = Discord
        workspace = special
      }

      windowrule {
        name = xwaylandvideobridge
        match:class = ^(xwaylandvideobridge)$
        opacity = 0.0 0.0
        no_anim = on
        no_initial_focus = on
        size = 1 1
        no_blur = on
      }

      windowrule {
        name = discord_input
        match:class = ^(discord|vesktop)$
        allows_input = on
      }

      windowrule {
        name = kdeconnect
        match:class = ^(org.kde.kdeconnect.daemon)$
        opacity = 1.0 1.0
        no_blur = on
        decorate = off
        no_shadow = on
        no_anim = on
        no_focus = on
        suppress_event = fullscreen
        float = on
        pin = on
        center = on
      }
    '';
  };
  services.hypridle = {
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
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "${wake_display}";
        }
        {
          timeout = 1800;
          on-timeout = "${suspend_on_battery}";
        }
      ];
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
          text = "Layout: $LAYOUT";
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 16;
          font_family = "SF Pro Display Nerd Font Regular";
          position = "0, -210";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:250] ${pkgs.hyprland}/bin/hyprctl devices -j | ${jq} -r 'if any(.keyboards[]; .main == true and .capsLock == true) then \"\\u21ea\" else \"\" end'";
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 20;
          font_family = "SFProDisplay Nerd Font Regular";
          position = "88, -140";
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
