{...}: {
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
    steam-hardware.enable = true;
  };
}
