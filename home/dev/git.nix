{
  config,
  gitName,
  gitEmail,
  ...
}: {
  programs.git = {
    enable = true;
    settings = {
      color.ui = true;

      core.editor = config.home.sessionVariables.EDITOR;
      credential.helper = "cache";
      github.user = gitName;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;

      user = {
        email = gitEmail;
        name = gitName;
      };
    };
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };
  services.ssh-agent.enable = true;
}
