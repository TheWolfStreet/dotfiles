{
  config,
  lib,
  pkgs,
  ...
}: {
  options.power = {
    enable = lib.mkEnableOption "Power management features";
  };

  config = lib.mkIf config.power.enable {
    powerManagement.powertop.enable = true;

    boot.kernelModules = ["msr"];

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };

    systemd.services = {
      enable-power-actions = {
        description = "Enable power profile actions";
        after = ["power-profiles-daemon.service"];
        wants = ["power-profiles-daemon.service"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "enable-power-actions" ''
            ${pkgs.power-profiles-daemon}/bin/powerprofilesctl configure-action --enable amdgpu_panel_power
            ${pkgs.power-profiles-daemon}/bin/powerprofilesctl configure-action --enable amdgpu_dpm
          '';
        };
      };
    };

    services = {
      udev.extraRules = lib.mkMerge [
        ''ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{class}!="0x02*", ATTR{power/control}="auto"''
        ''ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"''

        ''ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"''

        ''ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save on"''
        ''ACTION=="add", SUBSYSTEM=="net", NAME=="enp*", RUN+="${pkgs.ethtool}/sbin/ethtool -s $name wol d"''

        ''ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bDeviceClass}!="03", ATTR{bInterfaceClass}!="01", ATTR{bInterfaceClass}!="03", ATTR{power/control}="auto"''

        ''ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{power/autosuspend_delay_ms}="60000"''
      ];
    };
  };
}
