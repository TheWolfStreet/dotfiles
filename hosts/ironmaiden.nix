{
  pkgs,
  username,
  ...
}: {
  # Lenovo ThinkPad T420 (4238-QAR).
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
  ];

  hardware = {
    intel = {
      cpu.enable = true;
      gpu = {
        enable = true;
        vaapiDriver = "legacy";
      };
    };
    hackrf.enable = true;
    rtl-sdr.enable = true;
    ubertooth = {
      enable = true;
      group = "plugdev";
    };
  };

  power.enable = true;
  services = {
    thermald.enable = true;
    pcscd.enable = true;
    udev.packages = [pkgs.proxmark3];
  };

  virtualisation.enable = false;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
    usbmon.enable = true;
  };

  users.users.${username}.extraGroups = [
    "plugdev"
    "wireshark"
  ];

  home-manager.users.${username}.imports = [../home/pentest.nix];
}
