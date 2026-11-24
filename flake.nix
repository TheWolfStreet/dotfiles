{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
    };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mactahoe-icon-theme = {
      url = "github:TheWolfStreet/MacTahoe-icon-theme.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags2-shell = {
      url = "path:./ags2-shell";
      inputs.ags.follows = "ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-remote-portal = {
      url = "path:./hyprland-remote-portal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    self.submodules = true;
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    defaultUsername = "tws";
    gitName = "TheWolfStreet";
    gitEmail = "wolfthestreet@gmail.com";
    stateVersion = "26.11";

    hosts = {
      ironmaiden.username = "ghost";
      nixos = {};
      nixtop = {};
    };

    mkSystem = configurationName: {
      username ? defaultUsername,
      hostname ? configurationName,
    }: let
      dotfilesPath = "/home/${username}/.dotfiles";
    in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs configurationName username hostname gitName gitEmail stateVersion dotfilesPath;
        };

        modules = [
          ./hosts/${configurationName}.nix
          home-manager.nixosModules.home-manager
        ];
      };
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem hosts;

    formatter.${system} = pkgs.alejandra;

    checks.${system} = {
      ags-package = inputs.ags2-shell.packages.${system}.default;
      font-typography = let
        theme_config = import ./home/desktop/theme.nix {
          inherit pkgs;
          config = {};
          theme = {};
        };
        fonts = inputs.apple-fonts.packages.${system}.sf-pro;
        aliases = pkgs.writeText "sf-pro-fontconfig.conf" theme_config.fonts.fontconfig.configFile.sf-pro.text;
        lock_config = import ./home/desktop/hyprland.nix {
          inherit pkgs;
          inherit (pkgs) lib;
          config.home.sessionVariables.BROWSER = "false";
          theme.cursor = {
            name = "test";
            size = 24;
          };
        };
        labels = map (label: {inherit (label) text font_family font_size;}) (pkgs.lib.take 3 lock_config.programs.hyprlock.settings.label);
      in
        pkgs.runCommand "font-typography-tests" {
          nativeBuildInputs = [pkgs.fontconfig pkgs.gjs pkgs.gobject-introspection];
          buildInputs = [pkgs.pango];
        } ''
          export FONTCONFIG_FILE="$TMPDIR/fonts.conf"
          cat > "$FONTCONFIG_FILE" <<EOF
          <fontconfig>
            <dir>${fonts}/share/fonts</dir>
            <dir>${pkgs.nerd-fonts.symbols-only}/share/fonts</dir>
            <cachedir>$TMPDIR/font-cache</cachedir>
            <include>${aliases}</include>
          </fontconfig>
          EOF
          for family in "SF Pro Display" "SFProDisplay Nerd Font" "SF Pro Display Nerd Font"; do
            for style in Regular Bold; do
              actual=$(fc-match -f '%{file}' "$family:style=$style")
              printf '%s -> %s\n' "$family:style=$style" "$actual"
              test "$actual" = "${fonts}/share/fonts/opentype/SF-Pro-Display-$style.otf"
            done
            actual=$(fc-match -f '%{file}' "$family:slant=italic")
            printf '%s -> %s\n' "$family:slant=italic" "$actual"
            test "$actual" = "${fonts}/share/fonts/opentype/SF-Pro-Display-RegularItalic.otf"
            actual=$(fc-match -f '%{family}' "$family:charset=f11c")
            printf '%s -> %s\n' "$family:charset=f11c" "$actual"
            test "$actual" = "Symbols Nerd Font"
          done
          cat > typography.js <<'JS'
          const { Gio, Pango, PangoCairo } = imports.gi;
          const context = PangoCairo.FontMap.get_default().create_context();
          const labels = ${builtins.toJSON labels};
          function fonts(label, text) {
            const description = Pango.FontDescription.from_string(label.font_family);
            description.set_size(label.font_size * Pango.SCALE);
            description.set_weight(Pango.Weight.NORMAL);
            description.set_style(Pango.Style.NORMAL);
            const layout = Pango.Layout.new(context);
            layout.set_font_description(description);
            layout.set_markup(text, -1);
            const iterator = layout.get_iter();
            const result = [];
            do {
              const run = iterator.get_run_readonly();
              if (run) result.push(run.item.analysis.font.describe());
            } while (iterator.next_run());
            return result;
          }
          for (const label of labels) {
            let text = label.text.replaceAll("$USER", "test-user");
            if (text.startsWith("cmd[")) {
              const command = text.replace(/^cmd\[update:\d+\] /, "");
              const process = Gio.Subprocess.new(["bash", "-c", command], Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
              const [ok, stdout, stderr] = process.communicate_utf8(null, null);
              if (!ok || !process.get_successful()) throw new Error(stderr || "Label command failed");
              text = stdout.trim();
            }
            const bold = fonts(label, text);
            if (bold.length === 0 || bold.some(font => font.get_family() !== "SF Pro Display" || font.get_weight() !== Pango.Weight.BOLD))
              throw new Error("Label did not select original SF Pro Display Bold: " + text);
            const plain = fonts(label, text.replace(/<\/?b>/g, ""));
            if (plain.length === 0 || plain.some(font => font.get_weight() !== Pango.Weight.NORMAL))
              throw new Error("Removing the bold markup did not restore normal weight: " + text);
            print(text + " -> " + bold.map(font => font.to_string()).join(", "));
          }
          JS
          gjs typography.js
          touch "$out"
        '';
      hyprlock-revive = let
        hyprctl = pkgs.writeShellScriptBin "hyprctl" ''
          printf '%s\n' "$@" >> "$CALL_LOG"
          [ "''${FAIL_RESTORE:-0}" != 1 ]
        '';
        revive_config = import ./home/scripts/revive.nix {
          inherit (pkgs) lib;
          pkgs = pkgs // {hyprland = hyprctl;};
        };
        revive = builtins.head revive_config.home.packages;
      in
        pkgs.runCommand "hyprlock-revive-tests" {} ''
          export CALL_LOG="$TMPDIR/calls"
          export HYPRLAND_INSTANCE_SIGNATURE=stale-instance
          for instance in 0 2 explicit-signature; do
            : > "$CALL_LOG"
            if [ "$instance" = 0 ]; then
              ${revive}/bin/hyprlock-revive
            else
              ${revive}/bin/hyprlock-revive "$instance"
            fi
            printf '%s\n' -i "$instance" eval \
              'hl.config({ misc = { allow_session_lock_restore = true } })' \
              -i "$instance" dispatch \
              ${pkgs.lib.escapeShellArg "hl.dsp.exec_cmd(${pkgs.lib.generators.toLua {} "${pkgs.hyprlock}/bin/hyprlock"})"} > "$TMPDIR/expected"
            diff -u "$TMPDIR/expected" "$CALL_LOG"
          done
          : > "$CALL_LOG"
          if ${revive}/bin/hyprlock-revive 0 1; then exit 1; fi
          test ! -s "$CALL_LOG"
          if FAIL_RESTORE=1 ${revive}/bin/hyprlock-revive; then exit 1; fi
          test "$(wc -l < "$CALL_LOG")" -eq 4
          touch "$out"
        '';
      lid-policy = let
        lid_config = import ./home/desktop/hyprland.nix {
          inherit (pkgs) lib;
          config.home.sessionVariables.BROWSER = "false";
          theme.cursor = {
            name = "test";
            size = 24;
          };
          pkgs =
            pkgs
            // {
              writeShellScript = name: text:
                pkgs.writeShellScript name (
                  if name == "lid-closed"
                  then ''[ "$LID_STATE" = closed ]''
                  else text
                );
            };
        };
        lid_script = key: let
          binding = builtins.head (builtins.filter (binding: builtins.head binding._args == key) lid_config.wayland.windowManager.hyprland.settings.bind);
        in
          pkgs.lib.removeSuffix "\")" (pkgs.lib.removePrefix "hl.dsp.exec_cmd(\"" (builtins.elemAt binding._args 1).expr);
      in
        pkgs.runCommand "lid-policy-tests" {
          nativeBuildInputs = [pkgs.nodejs];
          LID_CLOSE = lid_script "switch:on:Lid Switch";
          RESTORE_PANEL = lid_script "switch:off:Lid Switch";
          WAKE_DISPLAY = (builtins.elemAt lid_config.services.hypridle.settings.listener 1).on-resume;
        } ''
          node --test ${./tests/lid_policy.mjs}
          touch "$out"
        '';
      formatting =
        pkgs.runCommand "dotfiles-formatting" {
          nativeBuildInputs = [pkgs.alejandra];
          src = nixpkgs.lib.fileset.toSource {
            root = ./.;
            fileset = nixpkgs.lib.fileset.unions [
              ./flake.nix
              (nixpkgs.lib.fileset.fileFilter (file: file.hasExt "nix") ./hosts)
              (nixpkgs.lib.fileset.fileFilter (file: file.hasExt "nix") ./modules)
              (nixpkgs.lib.fileset.fileFilter (file: file.hasExt "nix") ./home)
            ];
          };
        } ''
          alejandra --check "$src/flake.nix" "$src/hosts" "$src/modules" "$src/home"
          touch "$out"
        '';
    };
  };
}
