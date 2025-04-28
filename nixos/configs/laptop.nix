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
      ];
    };

    # systemd.services.batteryThreshold = {
    #   script = ''
    #     echo 85 | tee /sys/class/power_supply/BAT0/charge_control_end_threshold
    #   '';
    #   wantedBy = ["multi-user.target"];
    #   description = "Set the charge threshold to protect battery life";
    #   serviceConfig = {
    #     Restart = "on-failure";
    #   };
    # };

    powerManagement.powertop.enable = true;
    services = {
      asusd = {
        enable = true;
        enableUserService = true;
      };
      system76-scheduler.settings.cfsProfiles.enable = true;
      xserver.videoDrivers = ["amdgpu"];
      power-profiles-daemon.enable = lib.mkForce false;
      udev.extraRules = lib.mkMerge [
        # Autosuspend all USB devices
        # ''ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"''

        # Autosuspend PCI devices
        ''ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"''

        # Disable Ethernet Wake-on-LAN
        ''ACTION=="add", SUBSYSTEM=="net", NAME=="enp*", RUN+="${pkgs.ethtool}/sbin/ethtool -s $name wol d"''
      ];
      thermald.enable = true;
      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 20;

          USB_EXCLUDE_BTUSB = 1;
          # STOP_CHARGE_THRESH_BAT0 = 80;
        };
      };
      openssh.settings = {
        PasswordAuthentication = lib.mkForce false;
        KbdInteractiveAuthentication = lib.mkForce false;
      };
    };
  };
}
