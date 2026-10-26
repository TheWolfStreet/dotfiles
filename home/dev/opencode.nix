{
  config,
  dotfilesPath,
  ...
}: {
  xdg.configFile."opencode/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/dev/opencode/AGENTS.md";
}
