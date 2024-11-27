{config, ...}: let
  name = "TheWolfStreet";
  email = "wolfthestreet@gmail.com";
in {
  programs.git = {
    enable = true;
    extraConfig = {
      color.ui = true;

      core.editor = config.home.sessionVariables.EDITOR;
      credential.helper = "store";
      github.user = name;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
    userEmail = email;
    userName = name;
  };
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };
  services.ssh-agent.enable = true;
}
