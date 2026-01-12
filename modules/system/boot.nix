{pkgs, ...}: {
  boot = {
    tmp.cleanOnBoot = true;
    supportedFilesystems = ["ntfs"];
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      "libahci.ignore_sss=1"
      "threadirqs"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
  };
}
