{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.power;
  amdCpu = config.hardware.amd.cpu.enable;
  amdGpu = config.hardware.amd.gpu.enable;
in {
  options.power.enable = lib.mkEnableOption "laptop power management";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.powertop];

    boot = {
      kernelModules = ["msr"];
      kernelParams = [
        "snd_hda_intel.power_save=1"
        "nmi_watchdog=0"
      ];
    };

    powerManagement.enable = true;

    services = {
      power-profiles-daemon.enable = true;
      logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x02*", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x0d11*", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="pci", TEST=="power/control", ATTR{class}!="0x02*", ATTR{class}!="0x0d11*", ATTR{power/control}="auto"
        ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
        ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"
        ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bInterfaceClass}=="e0", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{bDeviceClass}=="e0", ATTR{power/control}="on"
        ACTION=="add|change", SUBSYSTEM=="pci", DRIVER=="nvme", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="60000"
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl --no-block start suspend-on-lid-battery.service"
        ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card[0-9]*-*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start suspend-on-lid-battery.service"
      '';
    };

    systemd.services = {
      suspend-on-lid-battery = {
        description = "Suspend a closed, undocked laptop on battery";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "suspend-if-clamshell" ''
            ${pkgs.coreutils}/bin/sleep 1
            no_external_count=0
            for _ in $(${pkgs.coreutils}/bin/seq 1 10); do
              ${pkgs.gnugrep}/bin/grep -qi closed /proc/acpi/button/lid/*/state || exit 0

              for p in /sys/class/power_supply/*; do
                [ "$(${pkgs.coreutils}/bin/cat "$p/type" 2>/dev/null)" = "Mains" ] || continue
                [ "$(${pkgs.coreutils}/bin/cat "$p/online" 2>/dev/null)" = "1" ] && exit 0
              done

              external_connected=false
              for s in /sys/class/drm/*/status; do
                case "$s" in *eDP*|*LVDS*|*Writeback*) continue ;; esac
                [ "$(${pkgs.coreutils}/bin/cat "$s" 2>/dev/null)" = connected ] && external_connected=true
              done
              if [ "$external_connected" = false ]; then
                no_external_count=$((no_external_count + 1))
                if [ "$no_external_count" -ge 2 ]; then
                  ${pkgs.systemd}/bin/systemctl suspend
                  exit 0
                fi
              else
                no_external_count=0
              fi
              ${pkgs.coreutils}/bin/sleep 1
            done
          '';
        };
      };

      enable-power-actions = lib.mkIf (amdCpu && amdGpu) {
        description = "Enable AMD power profile actions";
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
          ExecStop = pkgs.writeShellScript "disable-power-actions" ''
            ${pkgs.power-profiles-daemon}/bin/powerprofilesctl configure-action --disable amdgpu_panel_power
            ${pkgs.power-profiles-daemon}/bin/powerprofilesctl configure-action --disable amdgpu_dpm

            for gpu in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
              if [ -w "$gpu" ]; then
                printf auto > "$gpu"
              fi
            done
            for panel in /sys/class/drm/card*-*/amdgpu/panel_power_savings; do
              if [ -w "$panel" ]; then
                printf 0 > "$panel"
              fi
            done
          '';
        };
      };
    };
  };
}
