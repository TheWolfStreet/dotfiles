{
  lib,
  osConfig,
  ...
}: {
  config = lib.mkIf osConfig.asusLaptop.enable {
    wayland.windowManager.hyprland.settings = {
      input.kb_layout = lib.mkForce "us, ru, il";
      monitor = [
        "eDP-1,1920x1200@144,0x0,1"
      ];
    };
  };
}
