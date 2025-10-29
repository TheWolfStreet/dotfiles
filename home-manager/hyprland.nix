{
  pkgs,
  config,
  ...
}: let
  constants = import ../nixos/constants.nix;
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  hyprlock = "pidof hyprlock || hyprlock";
  touchpad_toggle = import ./scripts/touchpad.nix pkgs;
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
    systemd.enable = true;
    xwayland.enable = true;

    settings = {
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      env = [
        ''QT_QPA_PLATFORMTHEME, gtk3''
      ];
      exec-once = [
        "ags run"
        "hyprctl setcursor ${constants.graphics.cursors.theme} ${toString constants.graphics.cursors.size}"
      ];

      monitor = [
        ",highrr,auto,1"
      ];

      general = {
        layout = "dwindle";
        allow_tearing = false;
        resize_on_border = true;
      };

      render = {
        direct_scanout = false;
      };

      cursor = {
        no_hardware_cursors = true;
      };

      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        middle_click_paste = false;
        force_default_wallpaper = 0;
      };

      input = {
        kb_layout = constants.keyboards.desktop;
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
        pseudotile = "yes";
        preserve_split = "yes";
      };

      gesture = [
        "3, horizontal, workspace"
        "2, swipe, mod: SUPER+SHIFT, resize"
      ];

      windowrule = let
        f = regex: "float, class:^(${regex})$";
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
        (f "io.Astal.ags2-shell")
        "workspace special, title:Spotify"
        "workspace special, title:Discord"

        # Discord and xwayland video bridge
        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "allowsinput, class:^(discord|vesktop)$"

        # KDE Connect
        "opacity 1, class:^(org.kde.kdeconnect.daemon)"
        "minsize 1920 1200, class:^(org.kde.kdeconnect.daemon)"
        "noblur, class:^(org.kde.kdeconnect.daemon)"
        "noborder, class:^(org.kde.kdeconnect.daemon)"
        "noshadow, class:^(org.kde.kdeconnect.daemon)"
        "noanim, class:^(org.kde.kdeconnect.daemon)"
        "nofocus, class:^(org.kde.kdeconnect.daemon)"
        "suppressevent fullscreen, class:^(org.kde.kdeconnect.daemon)"
        "float, class:^(org.kde.kdeconnect.daemon)"
        "pin, class:^(org.kde.kdeconnect.daemon)"
        "move, 50% 50%, class:^(org.kde.kdeconnect.daemon)"
        "decorate, off, class:^(org.kde.kdeconnect.daemon)"
      ];

      bind = let
        binding = mod: cmd: key: arg: "${mod}, ${key}, ${cmd}, ${arg}";
        ws = binding "SUPER" "workspace";
        mvtows = binding "SUPER SHIFT" "movetoworkspace";
        e = "exec, ags -i ags2-shell";
        arr = [1 2 3 4 5 6 7];
      in
        [
          "CTRL ALT, Delete, ${e} quit; ags run"
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

          "SUPER, Q, killactive"
          "SUPER, F, fullscreen"
          "SUPER, SPACE, togglefloating"
          "SUPER, P, togglesplit"

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
      bindir = ",mouse:276, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ 1";

      bindle = [
        "CTRL, F8,               exec, ${brightnessctl} set +5%"
        "CTRL, F7,               exec, ${brightnessctl} set 5%-"
        ",XF86MonBrightnessUp,   exec, ${brightnessctl} set +5%"
        ",XF86MonBrightnessDown, exec, ${brightnessctl} set  5%-"
        ",XF86KbdBrightnessUp,   exec, ${brightnessctl} -d asus::kbd_backlight set +1"
        ",XF86KbdBrightnessDown, exec, ${brightnessctl} -d asus::kbd_backlight set  1-"
        ",XF86AudioRaiseVolume,  exec, ${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
        ",XF86AudioLowerVolume,  exec, ${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
        ",XF86AudioMute,         exec, ${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
      ];

      bindl = [
        ",XF86AudioPlay,       exec, ${playerctl} play-pause"
        ",XF86AudioStop,       exec, ${playerctl} pause"
        ",XF86AudioPause,      exec, ${playerctl} pause"
        ",XF86AudioPrev,       exec, ${playerctl} previous"
        ",XF86AudioNext,       exec, ${playerctl} next"
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
    };
  };
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        before_sleep_cmd = "${hyprlock}";
        ignore_dbus_inhibit = false;
        lock_cmd = "${hyprlock}";
      };
      listener = [
        {
          timeout = constants.power.idleTimeoutSec;
          on-timeout = "${hyprlock}";
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
      general = {
        no_fade_in = false;
        grace = 0;
        disable_loading_bar = false;
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
