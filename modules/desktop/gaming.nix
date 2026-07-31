{
  config,
  lib,
  ...
}: let
  cfg = config.gaming;
in {
  options.gaming.enable = lib.mkEnableOption "Gaming applications and services";

  config = lib.mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        localNetworkGameTransfers.openFirewall = true;
      };
      gamemode.enable = true;
      gamescope.enable = true;
    };
  };
}
