{
  config,
  lib,
  pkgs,
  ...
}: {
  options.asusLaptop = {
    enable = lib.mkEnableOption "Asus Laptop";
  };

  config = lib.mkIf config.asusLaptop.enable {
    hardware = {
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
    boot.initrd.kernelModules = ["amdgpu"];
    services = {
      asusd = {
        enable = true;
        enableUserService = true;
      };
      xserver.videoDrivers = ["amdgpu"];
      openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      auto-cpufreq = {
        enable = true;
        settings = {
          battery = {
            governor = "powersave";
            turbo = "never";
          };
          charger = {
            governor = "performance";
            turbo = "auto";
          };
        };
      };
    };
  };
}
