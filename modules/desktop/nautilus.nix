{
  pkgs,
  lib,
  ...
}: let
  nautEnv = pkgs.buildEnv {
    name = "nautilus-env";

    paths = with pkgs; [
      nautilus
      nautilus-python
      nautilus-open-any-terminal
    ];
  };
in {
  xdg.mime.defaultApplications = {
    "inode/directory" = ["org.gnome.Nautilus.desktop"];
  };
  environment = {
    systemPackages = [nautEnv pkgs.libheif pkgs.libheif.out];
    pathsToLink = [
      "/share/nautilus-python/extensions"
      "share/thumbnailers"
    ];
    sessionVariables = {
      NAUTILUS_4_EXTENSION_DIR = lib.mkDefault "${nautEnv}/lib/nautilus/extensions-4";
    };
  };
}
