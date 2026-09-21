{
  config,
  pkgs,
  dotfilesPath,
  ...
}: let
  # Live links into the repo so pi can edit its own rules and skills; changes show in git
  live = f: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/dev/pi/${f}";
  json = builtins.toJSON;

  # rtk's tests fail under -D warnings (dead code)
  rtk = pkgs.rtk.overrideAttrs {doCheck = false;};

  # Pi injects ~/.pi/agent/AGENTS.md into the top-level harness only; subagents
  # run in their own sessions and don't get it. Give every native builtin the
  # same guidelines: `defaultReads` delivers the pi-global AGENTS.md (the cwd
  # context-file walk never finds it), and `inheritProjectContext` loads a
  # project's own AGENTS.md when one exists — so subagents follow pi's rules
  # plus the project's, exactly like the harness.
  guided = {
    inheritProjectContext = true;
    defaultReads = ["~/.pi/agent/AGENTS.md"];
  };
  guidedAgents = ["worker" "scout" "reviewer" "researcher" "oracle" "evidence-auditor" "delegate"];
  agentOverrides = builtins.listToAttrs (map (n: {
    name = n;
    value = guided;
  }) guidedAgents);

  # See pi-coding-agent.nix: newer than pinned nixpkgs for Go Responses models.
  piAgent = pkgs.callPackage ./pi-coding-agent.nix {};
in {
  home.packages = with pkgs; [
    (callPackage ./package.nix {inherit rtk; pi-coding-agent = piAgent;})
    rtk
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = live "AGENTS.md";
    ".pi/agent/skills".source = live "skills";

    ".pi/agent/settings.json".text = json {
      theme = "dark";
      defaultProvider = "anthropic";
      defaultModel = "claude-opus-5";
      defaultThinkingLevel = "medium";
      enabledModels = ["claude-*" "gpt-6-astra" "opencode-go/*"];
      hideThinkingBlock = false;
      warnings.anthropicExtraUsage = false;

      # Subagents run in a detached process that does not auto-load ambient
      # extensions. Give every agent without its own `extensions` field the
      # tools that make sense for delegated work: the Claude-subscription
      # provider (so OAuth requests aren't billed as third-party), LSP/linting,
      # RTK optimization, and web search. Excludes todo and ask-user-question
      # (main-session UX) and pi-subagents (no nested spawning).
      subagents = {
        defaultExtensions = [
          "@zgltyq/pi-provider-claude"
          "pi-lens"
          "pi-rtk-optimizer"
          "pi-web-access"
        ];
        inherit agentOverrides;
      };
    };

    # No custom models.json: Pi's own catalog (models-store.json, refreshed
    # via `pi update --models`) already covers openai-codex and opencode-go
    # with correct per-model APIs. A custom file pins a provider-level API for
    # every model in it, which misroutes Go Responses/Anthropic models.
  };
}
