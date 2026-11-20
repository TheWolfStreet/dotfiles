{pkgs, ...}: {
  boot = {
    tmp.cleanOnBoot = true;
    supportedFilesystems = ["ntfs"];
    consoleLogLevel = 2;
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = ["rings"];
        })
      ];
    };
    kernelParams = [
      "libahci.ignore_sss=1"
      "threadirqs"
      "quiet"
      "rd.udev.log_level=2"
      "udev.log_priority=2"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
    ];
  };
}
