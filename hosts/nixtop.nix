{username, ...}: {
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../modules/hardware/common.nix
    ../modules/hardware/amd.nix
    ../modules/desktop/hyprland.nix
    ../modules/desktop/audio.nix
    ../modules/desktop/nautilus.nix
    ../modules/system/locale.nix
    ../modules/system/power.nix
    ../modules/system/base.nix
  ];

  networking.hostName = "nixtop";
  hardware.amd.cpu.enable = true;
  hardware.amd.gpu.enable = true;

  power.enable = true;

  services.asusd = {
    enable = true;
    enableUserService = true;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings.monitor = [
      "eDP-1,1920x1200@144,0x0,1"
    ];
    wayland.windowManager.hyprland.settings.input.kb_layout = "us, ru, il";
  };
}
