{
  inputs,
  pkgs,
  config,
  ...
}: let
  hyprland = inputs.hyprland.packages.${pkgs.system}.hyprland;

  yt = pkgs.writeShellScript "yt" ''
    notify-send "Opening video" "$(wl-paste)"
    mpv "$(wl-paste)"
  '';

  playerctl = "${pkgs.playerctl}/bin/playerctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  screenshot = import ./scripts/screenshot.nix pkgs;
in {
  xdg.desktopEntries."org.gnome.Settings" = {
    name = "Settings";
    comment = "Gnome Control Center";
    icon = "org.gnome.Settings";
    exec = "env XDG_CURRENT_DESKTOP=gnome ${pkgs.gnome-control-center}/bin/gnome-control-center";
    categories = ["X-Preferences"];
    terminal = false;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland;
    systemd.enable = true;
    xwayland.enable = true;

    settings = {
      exec-once = [
        "ags -b hypr"
        "hyprctl setcursor Qogir 24"
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
        explicit_sync = 2;
        explicit_sync_kms = 2;
        direct_scanout = false;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        force_default_wallpaper = 0;
        vfr = false;
        enable_swallow = true;
        swallow_regex = "^(Alacritty|kitty|footclient|wezterm|blackbox)$";
      };

      input = {
        kb_layout = "us, ru";
        follow_mouse = 1;
        kb_options = "grp:alt_shift_toggle";
        touchpad = {
          natural_scroll = "yes";
          middle_button_emulation = true;
          disable_while_typing = true;
          drag_lock = true;
        };
        sensitivity = 0;
        float_switch_override_focus = 2;
      };

      binds = {
        allow_workspace_cycles = true;
      };

      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_use_r = true;
      };

      windowrule = let
        f = regex: "float, ^(${regex})$";
      in [
        (f "org.gnome.Calculator")
        (f "org.gnome.Nautilus")
        (f "pavucontrol")
        (f "nm-connection-editor")
        (f "blueberry.py")
        (f "org.gnome.Settings")
        (f "org.gnome.design.Palette")
        (f "Color Picker")
        (f "xdg-desktop-portal")
        (f "xdg-desktop-portal-gnome")
        (f "de.haeckerfelix.Fragments")
        (f "com.github.Aylur.ags")
        "workspace 5, title:Spotify"
      ];

      windowrulev2 = [
        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "allowsinput, class:^(discord|vesktop)$"
      ];

      bind = let
        binding = mod: cmd: key: arg: "${mod}, ${key}, ${cmd}, ${arg}";
        ws = binding "SUPER" "workspace";
        mvtows = binding "SUPER SHIFT" "movetoworkspace";
        e = "exec, ags -b hypr";
        arr = [1 2 3 4 5 6 7];
      in
        [
          "CTRL ALT, Delete,  ${e} quit; ags -b hypr"
          "SUPER, R,       ${e} -t launcher"
          "SUPER, Tab,     ${e} -t overview"
          ",XF86PowerOff,  ${e} -r 'powermenu.shutdown()'"
          "SUPER SHIFT, R,   ${e} -r 'recorder.start()'"
          ",Print,         exec, ${screenshot}"
          "SHIFT, Print,    exec, ${screenshot} --full"
          "SUPER, B, exec, ${config.home.sessionVariables.BROWSER}"
          "SUPER, E, exec, nautilus"
          "SUPER, X, exec, xterm" # A symlink to other terminal

          # youtube
          "SUPER SHIFT, Y , exec, ${yt}"

          "ALT, Tab, cyclenext"
          "ALT, Tab, bringactivetotop"
          "SUPER SHIFT, Q, exit"
          "SUPER, Q, killactive"
          "SUPER, F, fullscreen"
          "SUPER, SPACE, togglefloating"
          "SUPER, P, togglesplit"

          "SUPER, grave, togglespecialworkspace"
          "SUPER SHIFT, grave, movetoworkspace, special"

          (ws "left" "e-1")
          (ws "right" "e+1")
          (mvtows "left" "e-1")
          (mvtows "right" "e+1")
        ]
        ++ (map (i: ws (toString i) (toString i)) arr)
        ++ (map (i: mvtows (toString i) (toString i)) arr);

      # Push to talk
      bindp = ",mouse:276, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ 0";
      bindr = ",mouse:276, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ 1";

      bindle = [
        ",XF86MonBrightnessUp,   exec, ${brightnessctl} set +5%"
        ",XF86MonBrightnessDown, exec, ${brightnessctl} set  5%-"
        ",XF86KbdBrightnessUp,   exec, ${brightnessctl} -d asus::kbd_backlight set +1"
        ",XF86KbdBrightnessDown, exec, ${brightnessctl} -d asus::kbd_backlight set  1-"
        ",XF86AudioRaiseVolume,  exec, ${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
        ",XF86AudioLowerVolume,  exec, ${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
      ];

      bindl = [
        ",XF86AudioPlay,    exec, ${playerctl} play-pause"
        ",XF86AudioStop,    exec, ${playerctl} pause"
        ",XF86AudioPause,   exec, ${playerctl} pause"
        ",XF86AudioPrev,    exec, ${playerctl} previous"
        ",XF86AudioNext,    exec, ${playerctl} next"
        "SHIFT, XF86AudioMute, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
      ];

      bindm = [
        "SUPER, mouse:273, resizewindow"
        "SUPER, mouse:272, movewindow"
      ];

      decoration = {
        drop_shadow = "yes";
        shadow_range = 8;
        shadow_render_power = 2;
        "col.shadow" = "rgba(00000044)";

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
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 5, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      plugin = {
        overview = {
          centerAligned = true;
          hideTopLayers = true;
          hideOverlayLayers = true;
          showNewWorkspace = true;
          exitOnClick = true;
          exitOnSwitch = true;
          drawActiveWorkspace = true;
          reverseSwipe = true;
        };
        hyprbars = {
          bar_color = "rgb(2a2a2a)";
          bar_height = 28;
          col_text = "rgba(ffffffdd)";
          bar_text_size = 11;
          bar_text_font = "Ubuntu Nerd Font";

          buttons = {
            button_size = 0;
            "col.maximize" = "rgba(ffffff11)";
            "col.close" = "rgba(ff111133)";
          };
        };
      };
    };
  };
}
