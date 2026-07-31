{
  imports = [
    ./amd.nix
    ./intel.nix
    ./nvidia.nix
  ];

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings.General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
        AutoEnable = false;
      };
    };
    enableAllFirmware = true;
    i2c.enable = true;
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
  '';
}
