{
  config,
  lib,
  ...
}: let
  constants = import ../constants.nix;
in {
  options.desktopPC = {
    enable = lib.mkEnableOption "desktop configuration";
  };

  config = lib.mkIf config.desktopPC.enable {
    boot.kernelParams = [
      "video=${constants.hardware.desktop.resolution}"
    ];
  };
}
