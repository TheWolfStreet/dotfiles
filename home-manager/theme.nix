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
    package = inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro-nerd;
  };
  cursorTheme = {
    name = "Qogir";
    size = 24;
    package = pkgs.qogir-icon-theme;
  };
  iconTheme = {
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
      cursorTheme.package
      iconTheme.package
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
    ];
    sessionVariables = {
      XCURSOR_THEME = cursorTheme.name;
      XCURSOR_SIZE = "${toString cursorTheme.size}";
    };
    pointerCursor =
      cursorTheme
      // {
        gtk.enable = true;
      };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    inherit font iconTheme cursorTheme;
    theme.name = theme.name;
    enable = true;
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
