{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hardware.amd = {
    cpu.enable = lib.mkEnableOption "AMD CPU configuration";
    gpu.enable = lib.mkEnableOption "AMD GPU configuration";
  };

  config = lib.mkMerge [
    (lib.mkIf config.hardware.amd.cpu.enable {
      hardware = {
        cpu.amd.updateMicrocode = true;
      };

      boot = {
        extraModulePackages = [config.boot.kernelPackages.zenpower];
        initrd.kernelModules = ["zenpower"];
        blacklistedKernelModules = ["k10temp"];
        kernelParams = [
          "amd_pstate=active"
          "elevator=noop"
          "btusb.enable_autosuspend=0"
        ];
      };
    })

    (lib.mkIf config.hardware.amd.gpu.enable {
      hardware = {
        graphics.extraPackages = with pkgs; [
          rocmPackages.clr.icd
        ];
      };

      nixpkgs.config.rocmSupport = true;

      boot = {
        initrd.kernelModules = ["amdgpu"];
      };

      services.xserver.videoDrivers = ["amdgpu"];
    })
  ];
}
