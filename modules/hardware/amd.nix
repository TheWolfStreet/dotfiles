{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hardware.amd = {
    cpu.enable = lib.mkEnableOption "AMD CPU configuration";
    gpu.enable = lib.mkEnableOption "AMD GPU configuration";
    gpu.disablePanelSelfRefresh = lib.mkEnableOption "the amdgpu PSR/Panel Replay workaround for a dead panel or GPU hang on resume after a lid-closed suspend (sets dcdebugmask=0x410)";
  };

  config = lib.mkMerge [
    (lib.mkIf config.hardware.amd.cpu.enable {
      hardware.cpu.amd.updateMicrocode = true;

      boot = {
        extraModulePackages = [config.boot.kernelPackages.zenpower];
        initrd.kernelModules = ["zenpower"];
        blacklistedKernelModules = ["k10temp"];
        kernelParams = [
          "amd_pstate=active"
        ];
      };
    })

    (lib.mkIf config.hardware.amd.gpu.enable {
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            rocmPackages.clr.icd
          ];
        };
      };

      nixpkgs.config.rocmSupport = true;
      boot.initrd.kernelModules = ["amdgpu"];
      services.xserver.videoDrivers = ["amdgpu"];
    })

    (lib.mkIf config.hardware.amd.gpu.disablePanelSelfRefresh {
      # Disable amdgpu Panel Self Refresh (0x10) and Panel Replay (0x400): their
      # state can fail to restore on resume after a lid-closed s2idle, leaving the
      # internal panel dead or hanging the GPU. Opt-in per host — panel-specific.
      boot.kernelParams = ["amdgpu.dcdebugmask=0x410"];
    })
  ];
}
