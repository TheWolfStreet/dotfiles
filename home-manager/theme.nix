{
  pkgs,
  config,
  inputs,
  ...
}: let
  theme = {
    name = "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };
  font = {
    name = "SF Pro Display Nerd Font";
    size = 11;
    package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
  };
  cursor_theme = {
    name = "Qogir";
    size = 24;
    package = pkgs.qogir-icon-theme;
  };
  icon_theme = {
    name = "WhiteSur";
    package = pkgs.whitesur-icon-theme;
  };
in {
  home = {
    packages = with pkgs; [
      font-awesome
      theme.package
      font.package
      nerd-fonts.jetbrains-mono
      cursor_theme.package
      icon_theme.package
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      adwaita-icon-theme
      papirus-icon-theme
    ];
    sessionVariables = {
      XCURSOR_THEME = cursor_theme.name;
      XCURSOR_SIZE = "${toString cursor_theme.size}";
    };
    pointerCursor =
      cursor_theme
      // {
        gtk.enable = true;
      };
    file = {
      ".config/gtk-4.0/gtk.css".text = ''
        window.messagedialog .response-area > button,
        window.dialog.message .dialog-action-area > button,
        .background.csd{
          border-radius: 0;
        }
      '';
    };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    inherit font;
    iconTheme = icon_theme;
    cursorTheme = cursor_theme;
    theme.name = theme.name;
    enable = true;
    gtk3.extraCss = ''
      headerbar, .titlebar,
      .csd:not(.popup):not(tooltip):not(messagedialog) decoration{
        border-radius: 0;
      }
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "kde";
  };

  home.file.".local/share/flatpak/overrides/global".text = let
    dirs = [
      "/nix/store:ro"
      "xdg-config/gtk-3.0:ro"
      "xdg-config/gtk-4.0:ro"
      "${config.xdg.dataHome}/icons:ro"
    ];
  in ''
    [Context]
    filesystems=${builtins.concatStringsSep ";" dirs}
  '';
}
