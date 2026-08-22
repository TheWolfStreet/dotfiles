{
  config,
  dotfilesPath,
  ...
}: {
  services.easyeffects.enable = true;

  # Keep EasyEffects' mutable state in the repository. Linking the whole
  # directory lets EasyEffects update these files without Home Manager
  # replacing each file with a new Nix store symlink on every rebuild.
  xdg.configFile."easyeffects" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/easyeffects/config";
  };

  xdg.dataFile."easyeffects" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/easyeffects/presets";
  };
}
