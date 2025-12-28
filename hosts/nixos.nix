{username, ...}: {
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../modules/hardware/common.nix
    ../modules/hardware/nvidia.nix
    ../modules/hardware/amd.nix
    ../modules/desktop/hyprland.nix
    ../modules/desktop/audio.nix
    ../modules/desktop/nautilus.nix
    ../modules/system/locale.nix
    ../modules/system/power.nix
    ../modules/system/base.nix
  ];

  networking.hostName = "nixos";
  hardware.nvidia.enable = true;
  hardware.amd.cpu.enable = true;

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings.monitor = [
      "HDMI-A-2,1920x1080@100,0x0,1"
    ];
    wayland.windowManager.hyprland.settings.input.kb_layout = "us, ru";
  };
}

