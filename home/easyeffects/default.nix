{
  config,
  dotfilesPath,
  ...
}: {
  xdg.configFile."easyeffects" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/easyeffects/config";
  };

  xdg.dataFile."easyeffects" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/easyeffects/presets";
  };
}
