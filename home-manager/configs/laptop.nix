{
  lib,
  osConfig,
  ...
}: let
  constants = import ../../nixos/constants.nix;
in {
  config = lib.mkIf osConfig.asusLaptop.enable {
    wayland.windowManager.hyprland.settings = {
      input.kb_layout = lib.mkForce constants.keyboards.laptop;
      monitor = [
        "${constants.hardware.laptop.monitor},${constants.hardware.laptop.resolution}@${toString constants.hardware.laptop.refreshRate},0x0,1"
      ];
    };
  };
}
