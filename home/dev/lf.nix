{pkgs, ...}: let
  lf = pkgs.lf.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace nav.go \
          --replace-fail '"bytes"' '"bytes"
          "encoding/base64"' \
          --replace-fail 'currSelections := strings.Join(selections, gOpts.filesep)' 'currSelections := strings.Join(selections, gOpts.filesep)
          encoded := make([]string, 0, len(selections))
          if len(selections) == 0 && currFile != "" {
            encoded = append(encoded, base64.StdEncoding.EncodeToString([]byte(currFile+".")))
          }
          for _, selection := range selections {
            encoded = append(encoded, base64.StdEncoding.EncodeToString([]byte(selection+".")))
          }
          os.Setenv("fx_encoded", strings.Join(encoded, ":"))'
        gofmt -w nav.go
      '';
  });

  selected_paths = ''
    [ -n "$fx_encoded" ] || { printf 'lf: no files selected\n' >&2; exit 1; }
    IFS=:
    set -f
    set --
    for encoded in $fx_encoded; do
      path="$(printf '%s' "$encoded" | ${pkgs.coreutils}/bin/base64 --decode)" || exit 1
      case "$path" in
        *.) path=''${path%.} ;;
        *) printf 'lf: invalid selection encoding\n' >&2; exit 1 ;;
      esac
      [ -e "$path" ] || [ -L "$path" ] || { printf 'lf: missing selected file: %s\n' "$path" >&2; exit 1; }
      set -- "$@" "$path"
    done
    [ "$#" -gt 0 ] || exit 1
  '';
in {
  xdg.desktopEntries.lf = {
    name = "lf";
    noDisplay = true;
  };

  home.packages = with pkgs; [
    glib
    fzf
    bat
    zip
    unar
    file
  ];

  programs.lf = {
    enable = true;
    package = lf;

    commands = let
      trash = ''
        ''${{
          ${selected_paths}
          gio trash -- "$@"
        }}
      '';
    in {
      inherit trash;
      delete = trash;

      open = ''
        ''${{
          ${selected_paths}
          all_text=true
          for path do
            mime="$(file --mime-type -Lb -- "$path")" || exit 1
            case "$mime" in
              text/*|inode/x-empty) ;;
              *) all_text=false ;;
            esac
          done
          if [ "$all_text" = true ]; then
            "$EDITOR" "$@"
          else
            lf -remote "send $id echomsg Non-text selection: opening all with opener" || exit 1
            for path do "$OPENER" "$path" || exit 1; done
          fi
        }}
      '';

      fzf = ''
        ''${{
          tmp="$(${pkgs.coreutils}/bin/mktemp -d)" || { printf 'lf: mktemp failed\n' >&2; exit 1; }
          trap '${pkgs.coreutils}/bin/rm -rf -- "$tmp"' EXIT
          find . -mindepth 1 -maxdepth 1 -print0 > "$tmp/entries" || { printf 'lf: find failed\n' >&2; exit 1; }
          if fzf --read0 --print0 --no-multi --reverse --header='Jump to location' < "$tmp/entries" > "$tmp/choice"; then
            :
          else
            status=$?
            case "$status" in
              1|130) exit 0 ;;
              *) printf 'lf: fzf failed (%s)\n' "$status" >&2; exit "$status" ;;
            esac
          fi

          bytes="$(${pkgs.coreutils}/bin/od -An -v -tu1 "$tmp/choice")" || exit 1
          quoted='"'
          IFS="$(printf ' \n.')"
          IFS=''${IFS%.}
          ended=false
          for byte in $bytes; do
            if [ "$byte" -eq 0 ]; then
              [ "$ended" = false ] || { printf 'lf: invalid picker result\n' >&2; exit 1; }
              ended=true
            else
              [ "$ended" = false ] || { printf 'lf: invalid picker result\n' >&2; exit 1; }
              quoted="$quoted$(printf '\\%03o' "$byte")"
            fi
          done
          [ "$ended" = true ] || { printf 'lf: empty picker result\n' >&2; exit 1; }
          quoted="$quoted\""
          res="$(${pkgs.coreutils}/bin/tr -d '\000' < "$tmp/choice" && printf '.')" || exit 1
          res=''${res%.}
          if [ -d "$res" ]; then
            cmd=cd
          elif [ -e "$res" ] || [ -L "$res" ]; then
            cmd=select
          else
            printf 'lf: selected path no longer exists: %s\n' "$res" >&2
            exit 1
          fi
          reply="$(lf -remote "send $id $cmd $quoted")" || { printf 'lf: remote selection failed\n' >&2; exit 1; }
          [ -z "$reply" ] || { printf 'lf: remote selection failed: %s\n' "$reply" >&2; exit 1; }
        }}
      '';

      unzip = ''
        ''${{
          set -f
          unar -- "$f"
        }}
      '';

      zip = ''
        ''${{
          set -f
          [ -n "$1" ] || exit 1
          archive="$1.zip"
          case "$archive" in -*) archive="./$archive" ;; esac
          ${selected_paths}
          zip -r -nw "$archive" -- "$@"
        }}
      '';

      pager = ''$bat --paging=always -- "$f"'';

      q = "quit";
    };

    keybindings = {
      a = "push %mkdir<space>";
      t = "push %touch<space>";
      r = "push :rename<space>";
      x = "trash";
      "." = "set hidden!";
      "<delete>" = "trash";
      "<enter>" = "open";
      i = "pager";
      f = "fzf";
    };

    settings = {
      ifs = "\\n";
      scrolloff = 4;
      preview = true;
      drawbox = true;
      icons = true;
      cursorpreviewfmt = "";
    };
  };

  xdg.configFile."lf/icons".source = "${pkgs.lf.src}/etc/icons.example";
}
