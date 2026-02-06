{
  pkgs,
  inputs,
  ...
}: let
  theme = import ../../home/desktop/defs.nix {inherit pkgs inputs;};
in {
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  fonts.packages = [theme.font.package];

  environment.systemPackages = [
    theme.icon.package
    theme.cursor.package
  ];

  programs.dconf.profiles.gdm.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          font-name = "${theme.font.name} ${toString theme.font.size}";
          monospace-font-name = "${theme.monospaceFont.name} ${toString theme.monospaceFont.size}";
          icon-theme = theme.icon.name;
          cursor-theme = theme.cursor.name;
        };
      };
    }
  ];
}
