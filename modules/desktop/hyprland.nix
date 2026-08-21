{
  config,
  pkgs,
  lib,
  ...
}: {
  nix.settings = {
    # Keep default NixOS substituters/keys (eg cache.nixos.org), and add AGS.
    substituters = lib.mkAfter [
      "https://ags.cachix.org"
    ];
    trusted-public-keys = lib.mkAfter [
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
    ];
  };

  programs.hyprland = {
    enable = true;
  };

  security = {
    polkit.enable = true;
    pam.services.hyprlock = {};
  };

  environment.systemPackages =
    (with pkgs; [
      wl-clipboard
      loupe
      baobab
      evince
      file-roller
      gnome-text-editor
      gnome-calendar
      gnome-system-monitor
      gnome-control-center
      gnome-weather
      gnome-calculator
      gnome-clocks
      gnome-software
    ])
    ++ lib.optional config.virtualisation.enable pkgs.gnome-boxes;

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "GNOME polkit authentication agent";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session-pre.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  systemd.user.services.gnome-keyring-daemon = {
    description = "GNOME Keyring daemon";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session-pre.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "/run/wrappers/bin/gnome-keyring-daemon --start --foreground --components=secrets";
      Restart = "on-failure";
    };
  };

  systemd.user.services.gnome-settings-daemon-rfkill = {
    description = "GNOME rfkill service";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session-pre.target"];
    serviceConfig = {
      Type = "dbus";
      BusName = "org.gnome.SettingsDaemon.Rfkill";
      ExecStart = "${pkgs.gnome-settings-daemon}/libexec/gsd-rfkill";
      Restart = "on-failure";
    };
  };

  services = {
    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    accounts-daemon.enable = true;
    gnome = {
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      localsearch.enable = true;
      tinysparql.enable = true;
    };
  };
}
