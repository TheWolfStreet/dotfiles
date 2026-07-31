{
  config,
  lib,
  ...
}: let
  cfg = config.hardware.nvidia;
in {
  options.hardware.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";
    persistence.enable = lib.mkEnableOption "NVIDIA persistence daemon";
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.persistence.enable -> cfg.enable;
          message = "hardware.nvidia.persistence.enable requires hardware.nvidia.enable";
        }
      ];
    }

    (lib.mkIf cfg.enable {
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
        };
        nvidia = {
          branch = "latest";
          open = true;
          videoAcceleration = true;
          nvidiaSettings = false;
          nvidiaPersistenced = cfg.persistence.enable;
        };
      };

      services.xserver.videoDrivers = ["nvidia"];
      home-manager.sharedModules = [
        {
          wayland.windowManager.hyprland.settings = {
            cursor.no_hardware_cursors = true;
            env =
              [
                "NIXOS_OZONE_WL, 1"
                "WLR_RENDERER_ALLOW_SOFTWARE, 1"
              ]
              ++ lib.optionals (!cfg.prime.offload.enable) [
                "LIBVA_DRIVER_NAME, nvidia"
                "VDPAU_DRIVER, nvidia"
                "GBM_BACKEND, nvidia-drm"
                "__GLX_VENDOR_LIBRARY_NAME, nvidia"
                "NVD_BACKEND, direct"
              ];
          };
        }
      ];
    })
  ];
}
