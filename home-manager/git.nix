{config, ...}: let
  name = "TheWolfStreet";
in {
  programs.git = {
    enable = true;
    extraConfig = {
      color.ui = true;

      core.editor = config.home.sessionVariables.EDITOR;
      credential.helper = "store";
      github.user = name;
      push.autoSetupRemote = true;
    };
    userEmail = "wolfthestreet@gmail.com";
    userName = name;
  };
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };
  services.ssh-agent.enable = true;
}
