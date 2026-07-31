{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.amd;
in {
  options.hardware.amd = {
    cpu.enable = lib.mkEnableOption "AMD CPU support";
    gpu = {
      enable = lib.mkEnableOption "AMD GPU support";
      rocm.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.gpu.enable;
        defaultText = lib.literalExpression "config.hardware.amd.gpu.enable";
        description = "Whether to enable ROCm support.";
      };
      disablePanelSelfRefresh = lib.mkEnableOption "the amdgpu PSR/Panel Replay workaround for a dead panel or GPU hang on resume after a lid-closed suspend (sets dcdebugmask=0x410)";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.gpu.disablePanelSelfRefresh -> cfg.gpu.enable;
          message = "hardware.amd.gpu.disablePanelSelfRefresh requires hardware.amd.gpu.enable";
        }
        {
          assertion = cfg.gpu.rocm.enable -> cfg.gpu.enable;
          message = "hardware.amd.gpu.rocm.enable requires hardware.amd.gpu.enable";
        }
      ];
    }

    (lib.mkIf cfg.cpu.enable {
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

    (lib.mkIf cfg.gpu.enable {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      boot.initrd.kernelModules = ["amdgpu"];
      services.xserver.videoDrivers = ["amdgpu"];
    })

    (lib.mkIf cfg.gpu.rocm.enable {
      hardware.graphics.extraPackages = [pkgs.rocmPackages.clr.icd];
      nixpkgs.config.rocmSupport = true;
    })

    (lib.mkIf cfg.gpu.disablePanelSelfRefresh {
      # Disable amdgpu Panel Self Refresh (0x10) and Panel Replay (0x400): their
      # state can fail to restore on resume after a lid-closed s2idle, leaving the
      # internal panel dead or hanging the GPU. Opt in per host; this is panel-specific.
      boot.kernelParams = ["amdgpu.dcdebugmask=0x410"];
    })
  ];
}
