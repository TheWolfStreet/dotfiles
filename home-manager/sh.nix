{
  pkgs,
  config,
  lib,
  ...
}: let
  aliases = {
    "tree" = "eza --tree";

    ":q" = "exit";
    "q" = "exit";

    "cd" = "z";
    "cdi" = "zi";

    "del" = "gio trash";
  };
in {
  options.shellAliases = with lib;
    mkOption {
      type = types.attrsOf types.str;
      default = {};
    };
  config.programs = {
    zsh = {
      shellAliases = aliases // config.shellAliases;
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initContent = ''
        SHELL=${pkgs.zsh}/bin/zsh
        zstyle ':completion:*' menu select
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        unsetopt BEEP
      '';
    };

    bash = {
      shellAliases = aliases // config.shellAliases;
      enable = true;
      initExtra = "SHELL=${pkgs.bash}";
    };

    nushell = {
      shellAliases = aliases // config.shellAliases;
      enable = true;
      environmentVariables = {
        PROMPT_INDICATOR_VI_INSERT = "  ";
        PROMPT_INDICATOR_VI_NORMAL = "• ";
        PROMPT_COMMAND = ''""'';
        PROMPT_COMMAND_RIGHT = ''""'';
        NIXPKGS_ALLOW_UNFREE = "1";
        NIXPKGS_ALLOW_INSECURE = "1";
        SHELL = ''"${pkgs.nushell}/bin/nu"'';
        EDITOR = ''"${config.home.sessionVariables.EDITOR}"'';
        VISUAL = ''"${config.home.sessionVariables.VISUAL}"'';
      };
      extraConfig = let
        conf = builtins.toJSON {
          show_banner = false;
          edit_mode = "vi";

          ls.clickable_links = true;
          rm.always_trash = true;

          completions = {
            case_sensitive = false;
            quick = true;
            partial = true;
            algorithm = "fuzzy";
          };

          table = {
            mode = "compact";
            index_mode = "always";
            header_on_separator = false;
          };

          cursor_shape = {
            vi_insert = "line";
            vi_normal = "block";
          };

          menus = [
            {
              name = "completion_menu";
              only_buffer_difference = false;
              marker = "? ";
              type = {
                layout = "columnar";
                columns = 4;
                col_padding = 2;
              };

              style = {
                text = "magenta";
                selected_text = "blue_reverse";
                description_text = "yellow";
              };
            }
          ];
        };
      in ''
        $env.config = ${conf};
        alias pueue = ${pkgs.pueue}/bin/pueue
        alias pueued = ${pkgs.pueue}/bin/pueued
        use ${pkgs.nu_scripts}/share/nu_scripts/modules/background_task/task.nu
      '';
    };
    carapace = {
      enable = true;
      enableNushellIntegration = true;
    };
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };
  };
}
