{...}: {
  services.easyeffects = {
    enable = true;
  };

  xdg.configFile."easyeffects" = {
    source = ./config;
    recursive = true;
  };

  xdg.dataFile."easyeffects" = {
    source = ./data;
    recursive = true;
  };
}