{
  pkgs,
  config,
  inputs,
  ...
}: let
  theme = import ./defs.nix {inherit pkgs inputs;};
in {
  home = {
    packages = with pkgs; [
      font-awesome
      theme.gtk.package
      theme.font.package
      theme.monospaceFont.package
      theme.cursor.package
      theme.icon.package
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
    ];
    sessionVariables = {
      XCURSOR_THEME = theme.cursor.name;
      XCURSOR_SIZE = "${toString theme.cursor.size}";
    };
    pointerCursor =
      theme.cursor
      // {
        gtk.enable = true;
      };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    font = theme.font;
    iconTheme = theme.icon;
    cursorTheme = theme.cursor;
    theme.name = theme.gtk.name;
    enable = true;
    gtk3.bookmarks = let
      home = config.home.homeDirectory;
    in [
      "file://${config.xdg.userDirs.desktop}"
      "file://${config.xdg.userDirs.download}"
      "file://${config.xdg.userDirs.documents}"
      "file://${config.xdg.userDirs.videos}"
      "file://${config.xdg.userDirs.music}"
      "file://${config.xdg.userDirs.pictures}"
      "file://${home}/.config Config"
      "file://${home}/Software"
      "file://${home}/Projects"
    ];
  };

  qt = {
    platformTheme.name = "gtk3";
  };

  home.file.".local/share/flatpak/overrides/global".text = let
    dirs = [
      "/nix/store:ro"
      "/run/current-system/sw/share/X11/fonts:ro"
      "xdg-config/gtk-3.0:ro"
      "xdg-config/gtk-4.0:ro"
      "${config.xdg.dataHome}/icons:ro"
    ];
  in ''
    [Context]
    filesystems=${builtins.concatStringsSep ";" dirs}
  '';
}
