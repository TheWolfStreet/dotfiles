{
  username,
  pkgs,
  ...
}: {
  # ASUS TUF Gaming A16 laptop.
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
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
