{
  lib,
  pkgs,
  ...
}: let
  commonAliases = {
    tree = "eza --tree";
    ":q" = "exit";
    cd = "z";
    cdi = "zi";
    del = "gio trash";
  };
  shellAliases = commonAliases // {q = "exit";};
  completions = lib.concatMapStringsSep "\n" (name: ''
    source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/${name}/${name}-completions.nu
  '');
in {
  programs = {
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    bash = {
      enable = true;
      enableCompletion = true;
      inherit shellAliases;
      initExtra = "SHELL=${pkgs.bash}/bin/bash";
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      inherit shellAliases;
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

    carapace = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableNushellIntegration = true;
      enableZshIntegration = false;
      ignoreCase = true;
    };

    nushell = {
      enable = true;
      shellAliases = commonAliases;
      environmentVariables = {
        PROMPT_INDICATOR_VI_INSERT = "  ";
        PROMPT_INDICATOR_VI_NORMAL = "∙ ";
        PROMPT_COMMAND = "";
        PROMPT_COMMAND_RIGHT = "";
        NIXPKGS_ALLOW_UNFREE = "1";
        SHELL = "${pkgs.nushell}/bin/nu";
      };
      settings = {
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
        completions = {
          sort = "smart";
          case_sensitive = false;
          quick = true;
          partial = true;
          algorithm = "fuzzy";
          external = {
            enable = true;
            max_results = 100;
          };
          use_ls_colors = true;
        };
        display_errors.exit_code = false;
        history.file_format = "sqlite";
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
      extraConfig = ''
        def purge-history [] {
          open $nu.history-path | query db "DELETE FROM history WHERE exit_status != 0"
        }

        def q [] { purge-history; exit }

        ${completions ["git" "nix"]}

        source ${pkgs.nu_scripts}/share/nu_scripts/modules/formats/from-env.nu
        source ${../scripts/blocks.nu}

        const user_config = "~/.nushellrc.nu"
        const empty_config = "/dev/null"
        source (if ($user_config | path exists) { $user_config } else { $empty_config })
      '';
    };
  };
}
