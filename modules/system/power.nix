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

    # CPU scaling uses amd-pstate-epp (active mode); the effective bias is the
    # EPP, which power-profiles-daemon sets per profile. Pinning a cpuFreqGovernor
    # here is pointless ("schedutil" isn't even valid under amd-pstate-epp).
    powerManagement.enable = true;

    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };

    systemd.services.suspend-on-lid-battery = {
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

    # Tie GPU VRAM clock and CPU boost to the *selected* power profile (not to
    # AC/battery — profile choice stays absolute). power-saver pins VRAM to its
    # lowest state (big idle-power win; GFX still free to ramp) and turns CPU
    # boost off while keeping EPP responsive so it isn't sluggish. balanced and
    # performance hand everything back to the driver/PPD (full boost, auto clocks).
    systemd.services.gpu-cpu-by-profile = {
      description = "GPU VRAM clock + CPU boost follow the selected power profile";
      after = ["power-profiles-daemon.service"];
      wants = ["power-profiles-daemon.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Restart = "always";
        RestartSec = 3;
        ExecStart = pkgs.writeShellScript "gpu-cpu-by-profile" ''
          gpu=""
          for c in /sys/class/drm/card[0-9]; do
            [ -e "$c/device/pp_dpm_mclk" ] && gpu="$c/device" && break
          done

          apply() {
            if [ "$1" = "power-saver" ]; then
              if [ -n "$gpu" ]; then
                echo manual > "$gpu/power_dpm_force_performance_level" 2>/dev/null || true
                echo "0 1 2" > "$gpu/pp_dpm_sclk" 2>/dev/null || true
                echo 0 > "$gpu/pp_dpm_mclk" 2>/dev/null || true
              fi
              echo 0 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
              for e in /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference; do
                echo balance_performance > "$e" 2>/dev/null || true
              done
            else
              [ -n "$gpu" ] && echo auto > "$gpu/power_dpm_force_performance_level" 2>/dev/null || true
              echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
            fi
          }

          last=""
          while :; do
            profile="$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get 2>/dev/null || echo balanced)"
            [ "$profile" != "$last" ] && { apply "$profile"; last="$profile"; }
            ${pkgs.coreutils}/bin/sleep 3
          done
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
      ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl --no-block start suspend-on-lid-battery.service"
      ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card[0-9]*-*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start suspend-on-lid-battery.service"
    '';
  };
}
