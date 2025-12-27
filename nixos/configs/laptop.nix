{
  config,
  lib,
  pkgs,
  ...
}: let
  constants = import ../constants.nix;
in {
  options.asusLaptop = {
    enable = lib.mkEnableOption "ASUS laptop configuration";
  };

  config = lib.mkIf config.asusLaptop.enable {
    hardware.bluetooth.powerOnBoot = lib.mkForce false;

    boot.kernelParams = [
      "video=${constants.hardware.laptop.monitor}:${constants.hardware.laptop.resolution}@60"
      "ahci.mobile_lpm_policy=3"
    ];

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
      asusd = {
        enable = true;
        enableUserService = true;
      };

      system76-scheduler.settings.cfsProfiles.enable = true;
      udev.extraRules = lib.mkMerge [
        # Autosuspend all USB devices except HID
        # ''ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bDeviceClass}!="03", ATTR{power/control}="auto"''

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
