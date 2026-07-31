{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.intel;
  vaapiDriver =
    if cfg.gpu.vaapiDriver == "legacy"
    then {
      native = pkgs.intel-vaapi-driver;
      compat = pkgs.pkgsi686Linux.intel-vaapi-driver;
    }
    else {
      native = pkgs.intel-media-driver;
      compat = pkgs.pkgsi686Linux.intel-media-driver;
    };
in {
  options.hardware.intel = {
    cpu.enable = lib.mkEnableOption "Intel CPU support";
    gpu = {
      enable = lib.mkEnableOption "Intel GPU support";
      vaapiDriver = lib.mkOption {
        type = lib.types.enum ["modern" "legacy"];
        default = "modern";
        description = "VA-API driver generation: modern for Broadwell and newer, legacy for older Intel GPUs.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.cpu.enable {
      hardware.cpu.intel.updateMicrocode = true;
    })

    (lib.mkIf cfg.gpu.enable {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [vaapiDriver.native];
        extraPackages32 = [vaapiDriver.compat];
      };

      boot.initrd.kernelModules = ["i915"];
      services.xserver.videoDrivers = ["modesetting"];
    })
  ];
}
