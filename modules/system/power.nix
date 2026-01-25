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
    environment.systemPackages = [pkgs.powertop];

    boot = {
      kernelModules = ["msr"];
      kernelParams = [
        "snd_hda_intel.power_save=1"
        "nmi_watchdog=0"
      ];
    };

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };

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

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x02*", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x0d11*", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{class}!="0x02*", ATTR{class}!="0x0d11*", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
      ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bInterfaceClass}=="e0", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bDeviceClass}=="e0", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bDeviceClass}!="03", ATTR{bInterfaceClass}!="01", ATTR{bInterfaceClass}!="03", ATTR{bInterfaceClass}!="e0", ATTR{power/control}="auto"
      ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{power/autosuspend_delay_ms}="60000"
    '';
  };
}
