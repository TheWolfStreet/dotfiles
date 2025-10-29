{
  config,
  lib,
  pkgs,
  ...
}: let
  constants = import ../constants.nix;
in {
  options.hardware.amd.laptop = {
    enable = lib.mkEnableOption "AMD laptop configuration";
  };

  config = lib.mkIf config.hardware.amd.laptop.enable {
    hardware = {
      graphics.extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };

    nixpkgs.config.rocmSupport = true;

    boot = {
      extraModulePackages = [config.boot.kernelPackages.zenpower];
      initrd.kernelModules = ["amdgpu" "zenpower"];
      blacklistedKernelModules = ["k10temp"];
      kernelParams = [
        "elevator=noop"
        "btusb.enable_autosuspend=0"
      ];
    };

    systemd.services.amdgpu-dynamic-dpm = {
      description = "AMDGPU power mode follows CPU profile";
      wantedBy = ["multi-user.target"];

      script = ''
        CARD=1
        while true; do
            PROFILE=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get)
            case "$PROFILE" in
                performance) LEVEL=high ;;
                balanced)    LEVEL=auto ;;
                power-saver) LEVEL=low ;;
                *) continue ;;
            esac

            CURRENT=$(cat /sys/class/drm/card$CARD/device/power_dpm_force_performance_level)
            if [ "$CURRENT" != "$LEVEL" ]; then
                echo $LEVEL > /sys/class/drm/card$CARD/device/power_dpm_force_performance_level
            fi

            sleep ${toString constants.power.amdGpuPollIntervalSec}
        done
      '';

      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 0;
      };
    };

    services.xserver.videoDrivers = ["amdgpu"];
  };
}