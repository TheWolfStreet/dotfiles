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

    systemd.services.enable-power-actions = {
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

    services = {
      system76-scheduler.settings.cfsProfiles.enable = true;

      udev.extraRules = lib.mkMerge [
        # Autosuspend all USB devices except HID
        # ''ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bDeviceClass}!="03", ATTR{power/control}="auto"''

        # Autosuspend PCI devices
        ''ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{power/control}="auto"''

        # Disable Ethernet Wake-on-LAN
        ''ACTION=="add", SUBSYSTEM=="net", NAME=="enp*", RUN+="${pkgs.ethtool}/sbin/ethtool -s $name wol d"''
      ];
    };
  };
}
