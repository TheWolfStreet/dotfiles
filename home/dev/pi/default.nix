{pkgs, ...}: let
  json = builtins.toJSON;

  # rtk's tests fail under -D warnings (dead code)
  rtk = pkgs.rtk.overrideAttrs {doCheck = false;};
in {
  home.packages = with pkgs; [
    (callPackage ./package.nix {inherit rtk;})
    rtk
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
