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

  # Fix for Realtek r8169 ethernet chipset
  boot.extraModprobeConfig = ''
    options r8169 disable_aspm=1 use_dac=1
  '';

  boot.kernelParams = [
    "pcie_aspm=off"
  ];

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
