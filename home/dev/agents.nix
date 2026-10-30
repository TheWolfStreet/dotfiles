{
  config,
  dotfilesPath,
  ...
}: let
  agents = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/dev/AGENTS.md";
in {
  xdg.configFile."opencode/AGENTS.md".source = agents;
  home.file.".claude/CLAUDE.md".source = agents;
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";
}
