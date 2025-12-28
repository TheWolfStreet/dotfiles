{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hardware.nvidia.desktop = {
    enable = lib.mkEnableOption "NVIDIA desktop configuration";
  };

  config = lib.mkIf config.hardware.nvidia.desktop.enable {
    hardware = {
      graphics.extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        egl-wayland
      ];
      nvidia = {
        modesetting.enable = true;
        nvidiaPersistenced = true;
        open = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        nvidiaSettings = false;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };
      nvidia-container-toolkit.enable = true;
    };

    boot.kernelModules = ["nvidia"];

    virtualisation.docker = {
      daemon.settings = {
        features.cdi = true;
      };
    };

    services.xserver.videoDrivers = ["nvidia"];
  };
}

