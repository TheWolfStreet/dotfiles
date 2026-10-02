{
  username,
  pkgs,
  config,
  lib,
  ...
}: let
  hermesPath = /home/${username}/.hermes/nixos/hermes.nix;
in {
  # ASUS TUF Gaming A16 laptop.
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
    (import ../modules/system/hermes.nix {
      implementation =
        if builtins.pathExists hermesPath
        then hermesPath
        else null;
    })
  ];

  hardware.amd = {
    cpu.enable = true;
    gpu = {
      enable = true;
      disablePanelSelfRefresh = true;
    };
  };

  gaming.enable = true;
  hermes.enable = true;
  power.enable = true;
  virtualisation.enable = true;
  services.asusd.enable = true;

  # ASUS TUF A16 FA617NSR PixArt touchpad (ASUP1205:00 093A:2008) freezes with
  # "i2c_hid_get_input: incomplete report (18/65535)" until a suspend/resume
  # cycle resets the bus. Poll instead of relying on the racy GPIO IRQ.
  boot.kernelParams = ["i2c_hid.polling_mode=1"];

  # Keep the touchpad's I2C link powered; runtime autosuspend can also wedge it.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="i2c-ASUP1205:00", ATTR{power/control}="on"
  '';

  # The BOE panel's overdrive overshoots at 144 Hz: bright/dark fringes trail moving edges
  systemd.services.panel-overdrive-off = lib.mkIf config.services.asusd.enable {
    after = ["asusd.service"];
    requires = ["asusd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = "${pkgs.asusctl}/bin/asusctl armoury set panel_overdrive 0";
  };

  virtualisation.vmVariant.hermes.enable = lib.mkForce false;

  networking.networkmanager.ensureProfiles.profiles.ethernet-default = {
    connection = {
      id = "Ethernet";
      type = "ethernet";
      interface-name = "eno1";
      autoconnect = true;
      autoconnect-priority = 100;
    };
    ipv4.method = "auto";
    ipv6.method = "disabled";
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  home-manager.users.${username} = {
    home.packages = [pkgs.ollama-rocm];
    wayland.windowManager.hyprland.settings = {
      monitor = [
        "eDP-1,1920x1200@144,0x0,1"
      ];
      input.kb_layout = "us, ru, il";
    };
  };
}
