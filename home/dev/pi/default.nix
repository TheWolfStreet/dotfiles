{pkgs, ...}: let
  json = builtins.toJSON;

  # Pi checks updates with `npm view`; bun's equivalent `info` needs a package.json in cwd
  bun = pkgs.writeShellScriptBin "bun" ''
    b=${pkgs.bun}/bin/bun
    case "$1" in
      view) shift; cd ~/.pi/agent/npm && exec $b info "$@" ;;
      # Bun blocks postinstalls by default; pi-lens needs @ast-grep/cli's binary
      install) $b "$@" || exit
        while [ $# -gt 0 ]; do [ "$1" = --cwd ] && cd "$2"; shift; done
        exec $b pm trust --all ;;
    esac
    exec $b "$@"
  '';
in {
  home.packages = with pkgs; [
    pi-coding-agent
    (rtk.overrideAttrs {doCheck = false;}) # tests fail under -D warnings (dead code)
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ./AGENTS.md;

    ".pi/agent/settings.json".text = json {
      theme = "dark";
      defaultProvider = "anthropic";
      defaultModel = "claude-opus-5";
      defaultThinkingLevel = "medium";
      hideThinkingBlock = false;
      warnings.anthropicExtraUsage = false;
      npmCommand = ["${bun}/bin/bun"];
      packages = [
        "npm:pi-subagents"
        "npm:pi-web-access"
        "npm:pi-lens"
        "npm:pi-rtk-optimizer"
        "npm:@zgltyq/pi-provider-claude"
        "npm:@juicesharp/rpiv-todo"
        "npm:@juicesharp/rpiv-ask-user-question"
      ];
    };

    ".pi/agent/models.json".text = json {
      providers.openai-codex.models = [
        {
          id = "gpt-6-astra";
          name = "GPT-6 Astra";
          api = "openai-codex-responses";
          baseUrl = "https://chatgpt.com/backend-api";
          reasoning = true;
          input = ["text" "image"];
          contextWindow = 1050000;
          maxTokens = 128000;
          cost = {
            input = 10;
            output = 50;
            cacheRead = 1;
            cacheWrite = 12.5;
          };
        }
      ];
    };
  };
}
