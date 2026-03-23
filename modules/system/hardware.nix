{
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
    i2c.enable = true;
    steam-hardware.enable = true;
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
  '';
}
