{
  lib,
  pkgs,
  osConfig,
  ...
}: {
  config = lib.mkIf osConfig.desktopPC.enable {
    home.packages = with pkgs; [
      steam
    ];
    wayland.windowManager.hyprland.settings.env = [
      ''LIBVA_DRIVER_NAME, nvidia''
      ''VDPAU_DRIVER, nvidia''
      ''GBM_BACKEND, nvidia-drm''
      ''__GLX_VENDOR_LIBRARY_NAME, nvidia''
      ''NVD_BACKEND, direct''
      ''NIXOS_OZONE_WL, 1''
      ''WLR_RENDERER_ALLOW_SOFTWARE, 1''
    ];
  };
}
