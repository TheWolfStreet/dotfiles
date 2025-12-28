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

  config.programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };

  config.programs.bash = {
    shellAliases = aliases // config.shellAliases;
    enable = true;
    enableCompletion = true;
    initExtra = ''
      SHELL=${pkgs.bash}/bin/bash
    '';
  };

  config.programs.zsh = {
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

  config.programs.nushell = {
    shellAliases = aliases // config.shellAliases;
    enable = true;
    environmentVariables = {
      PROMPT_INDICATOR_VI_INSERT = "  ";
      PROMPT_INDICATOR_VI_NORMAL = "∙ ";
      PROMPT_COMMAND = "";
      PROMPT_COMMAND_RIGHT = "";
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_INSECURE = "1";
      SHELL = "${pkgs.nushell}/bin/nu";
    };
    extraConfig = let
      conf = builtins.toJSON {
        show_banner = false;
        edit_mode = "vi";

        ls.clickable_links = true;
        rm.always_trash = true;

        table = {
          mode = "compact";
          index_mode = "always";
          header_on_separator = false;
        };

        cursor_shape = {
          vi_insert = "line";
          vi_normal = "block";
        };

        display_errors = {
          exit_code = false;
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
      completions = let
        completion = name: ''
          source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu
        '';
      in
        names:
          builtins.foldl'
          (prev: str: "${prev}\n${str}") ""
          (map completion names);
    in
      # nu
      ''
        $env.config = ${conf};
        ${completions ["git" "nix"]}

        source ${pkgs.nu_scripts}/share/nu_scripts/modules/formats/from-env.nu
        source ${../scripts/blocks.nu}

        const path = "~/.nushellrc.nu"
        const null = "/dev/null"
        source (if ($path | path exists) {
            $path
        } else {
            $null
        })
      '';
    extraEnv = ''
      $env.PATH = ($env.PATH | append "${config.home.homeDirectory}/.local/bin")
    '';
  };
}
