{pkgs, lib, ...}: {
  services = {
    xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
      displayManager.lightdm.enable = false;
    };
    printing.enable = true;
    flatpak.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkDefault "no";
        PasswordAuthentication = lib.mkDefault false;
        PubkeyAuthentication = lib.mkDefault true;
      };
    };
    fstrim.enable = true;
    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandlePowerKey = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
  };
}
