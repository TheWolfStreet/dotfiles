{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hardware.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU configuration";
    offload.enable = lib.mkEnableOption "NVIDIA offloading (hybrid graphics)";
    persistence.enable = lib.mkEnableOption "NVIDIA persistence daemon";
    container.enable = lib.mkEnableOption "NVIDIA container toolkit for Docker";
  };

  config = lib.mkMerge [
    (lib.mkIf config.hardware.nvidia.enable {
      hardware = {
        graphics.extraPackages = with pkgs; [
          nvidia-vaapi-driver
          libva-vdpau-driver
          egl-wayland
        ];
        nvidia = {
          modesetting.enable = true;
          open = true;
          powerManagement.enable = false;
          powerManagement.finegrained = false;
          nvidiaSettings = false;
          package = config.boot.kernelPackages.nvidiaPackages.latest;
        };
      };

      boot.kernelModules = ["nvidia"];
      services.xserver.videoDrivers = ["nvidia"];
    })

    (lib.mkIf config.hardware.nvidia.persistence.enable {
      hardware.nvidia.nvidiaPersistenced = true;
    })

    (lib.mkIf config.hardware.nvidia.enable {
      home-manager.sharedModules = [{
        wayland.windowManager.hyprland.settings.env = lib.mkMerge [
          [
            "NIXOS_OZONE_WL, 1"
            "WLR_RENDERER_ALLOW_SOFTWARE, 1"
          ]
          (lib.mkIf (!config.hardware.nvidia.offload.enable) [
            "LIBVA_DRIVER_NAME, nvidia"
            "VDPAU_DRIVER, nvidia"
            "GBM_BACKEND, nvidia-drm"
            "__GLX_VENDOR_LIBRARY_NAME, nvidia"
            "NVD_BACKEND, direct"
          ])
        ];
      }];
    })

    (lib.mkIf config.hardware.nvidia.container.enable {
      hardware.nvidia-container-toolkit.enable = true;

      virtualisation.docker = {
        daemon.settings = {
          features.cdi = true;
        };
      };
    })
  ];
}

