{
  config,
  lib,
  pkgs,
  ...
}: {
  options.desktopPC = {
    enable = lib.options.mkEnableOption {
      type = lib.types.bool;
      default = false;
      description = "Enable desktop configuration";
    };
  };

  config = lib.mkIf config.desktopPC.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          egl-wayland
          vaapiVdpau
        ];
      };
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
      enableAllFirmware = true;
      cpu.amd.updateMicrocode = true;
    };
    boot = {
      kernelParams = [
        "video=1920x1080"
        "amd_pstate=active"
      ];
      kernelModules = ["nvidia"];
    };
    virtualisation.docker = {
      daemon.settings = {
        features.cdi = true;
      };
    };
    services.xserver.videoDrivers = ["nvidia"];
  };
}
