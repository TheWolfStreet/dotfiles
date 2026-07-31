{lib, ...}: let
  forceDisabled = lib.mkForce false;
in {
  virtualisation.vmVariant = {
    hardware = {
      amd = {
        cpu.enable = forceDisabled;
        gpu = {
          enable = forceDisabled;
          disablePanelSelfRefresh = forceDisabled;
        };
      };
      intel = {
        cpu.enable = forceDisabled;
        gpu.enable = forceDisabled;
      };
      nvidia = {
        enable = forceDisabled;
        persistence.enable = forceDisabled;
      };
    };

    gaming.enable = forceDisabled;
    power.enable = forceDisabled;
    services = {
      asusd.enable = forceDisabled;
      power-profiles-daemon.enable = forceDisabled;
    };
    swapDevices = lib.mkForce [];

    virtualisation = {
      enable = forceDisabled;
      memorySize = 8192;
      cores = 8;
      qemu.options = [
        "-display gtk,gl=on"
        "-device virtio-vga-gl"
      ];
    };
  };
}
