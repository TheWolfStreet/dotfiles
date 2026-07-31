{username, ...}: {
  # AMD Matisse/NVIDIA desktop.
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
  ];

  hardware = {
    amd.cpu.enable = true;
    nvidia = {
      enable = true;
      persistence.enable = true;
    };
  };

  gaming.enable = true;
  virtualisation.enable = true;

  services.openssh.settings.PasswordAuthentication = true;

  networking.networkmanager.ensureProfiles.profiles.ethernet-default = {
    connection = {
      id = "Ethernet";
      type = "ethernet";
      interface-name = "eno1";
      autoconnect = true;
    };
    ipv4.method = "auto";
    ipv6.method = "disabled";
  };

  services.pipewire.wireplumber.extraConfig."99-matisse-auto-switch" = {
    "monitor.alsa.rules" = [
      {
        matches = [{"device.product.name" = "Starship/Matisse HD Audio Controller";}];
        actions.update-props = {
          "api.acp.auto-port" = true;
          "api.acp.auto-profile" = true;
        };
      }
    ];
  };

  home-manager.users.${username}.wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-1,1920x1080@100,0x0,1"
    ];
    input.kb_layout = "us, ru";
  };
}
