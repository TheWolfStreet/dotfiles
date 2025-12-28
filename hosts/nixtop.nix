{
  username,
  hostname,
  pkgs,
  ...
}: {
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
    ../modules/hardware/amd.nix
  ];

  networking.hostName = hostname;

  hardware = {
    enableAllFirmware = true;
    amd.cpu.enable = true;
    amd.gpu.enable = true;
  };

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
    home.packages = with pkgs; [
      ollama-rocm
    ];
    wayland.windowManager.hyprland.settings.input.kb_layout = "us, ru, il";
  };
}
