{config, ...}: let
  name = "TheWolfStreet";
  email = "wolfthestreet@gmail.com";
in {
  programs.git = {
    enable = true;
    settings = {
      color.ui = true;

      core.editor = config.home.sessionVariables.EDITOR;
      credential.helper = "store";
      github.user = name;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;

      user = {
        email = email;
        name = name;
      };
    };
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
    };
  };
  services.ssh-agent.enable = true;
}
