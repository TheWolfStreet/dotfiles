{
  pkgs,
  lib,
  ...
}: {
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
    kernelPackages = pkgs.linuxPackages_zen.extend (_: previous: {
      v4l2loopback = lib.lowPrio previous.v4l2loopback;
    });
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
