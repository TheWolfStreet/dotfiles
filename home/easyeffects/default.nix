{
  services.easyeffects.enable = true;

  xdg.configFile."easyeffects" = {
    force = true;
    recursive = true;
    source = ./config;
  };

  xdg.dataFile."easyeffects" = {
    force = true;
    recursive = true;
    source = ./presets;
  };
}
