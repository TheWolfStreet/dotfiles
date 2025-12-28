{pkgs, ...}: {
  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = with pkgs; [
      (adi1090x-plymouth-themes.override {
        selected_themes = ["rings"];
      })
    ];
  };

  boot = {
    consoleLogLevel = 2;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "boot.shell_on_fail"
      "rd.udev.log_level=2"
      "udev.log_priority=2"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
    ];
  };
}
