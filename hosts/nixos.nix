{
  username,
  hostname,
  ...
}: {
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
    ../modules/hardware/nvidia.nix
    ../modules/hardware/amd.nix
  ];

  networking.hostName = hostname;

  hardware = {
    enableAllFirmware = true;
    nvidia = {
      enable = true;
      persistence.enable = true;
    };
    amd.cpu.enable = true;
  };

  power.enable = false;

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings.monitor = [
      "HDMI-A-2,1920x1080@100,0x0,1"
    ];
    wayland.windowManager.hyprland.settings.input.kb_layout = "us, ru";
  };
}
