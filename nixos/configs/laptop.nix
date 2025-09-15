{
  config,
  lib,
  pkgs,
  ...
}: {
  options.asusLaptop = {
    enable = lib.options.mkEnableOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ASUS laptop configuration";
    };
  };
  config = lib.mkIf config.asusLaptop.enable {
    hardware = {
      bluetooth.powerOnBoot = lib.mkForce false;
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd
        ];
      };
      enableAllFirmware = true;
      cpu.amd.updateMicrocode = true;
    };

    nixpkgs.config.rocmSupport = true;

    boot = {
      extraModulePackages = [config.boot.kernelPackages.zenpower];
      initrd.kernelModules = ["amdgpu" "zenpower"];
      blacklistedKernelModules = ["k10temp"];
      kernelParams = [
        "video=eDP-1:1920x1200@60"
        "ahci.mobile_lpm_policy=3"
        "amd_pstate=active"
        "elevator=noop"
        "btusb.enable_autosuspend=0"
      ];
    };

    powerManagement.powertop.enable = true;

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

            sleep 5
        done
      '';

      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = 0;
      };
    };

    services = {
      asusd = {
        enable = true;
        enableUserService = true;
      };
      system76-scheduler.settings.cfsProfiles.enable = true;
      xserver.videoDrivers = ["amdgpu"];
      udev.extraRules = lib.mkMerge [
        # Autosuspend all USB devices except HID
        ''ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bDeviceClass}!="03", ATTR{power/control}="auto"''

        # Autosuspend PCI devices
        ''ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"''

        # Disable Ethernet Wake-on-LAN
        ''ACTION=="add", SUBSYSTEM=="net", NAME=="enp*", RUN+="${pkgs.ethtool}/sbin/ethtool -s $name wol d"''
      ];
      openssh.settings = {
        PasswordAuthentication = lib.mkForce false;
        KbdInteractiveAuthentication = lib.mkForce false;
      };
    };
  };
}
