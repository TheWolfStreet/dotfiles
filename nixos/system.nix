{
  pkgs,
  config,
  ...
}: {
  # nix
  documentation.nixos.enable = false; # .desktop
  nixpkgs.config.allowUnfree = true;
  nix = {
    gc = {
      automatic = true;
      dates = "hourly";
      options = "--delete-older-than 30min";
    };
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  # camera
  programs.droidcam.enable = true;

  # virtualisation
  programs.virt-manager.enable = true;
  virtualisation = {
    podman.enable = true;
    docker.enable = true;
    libvirtd.enable = true;
  };

  # dconf
  programs.dconf.enable = true;

  # packages
  environment.systemPackages = with pkgs; [
    home-manager
    neovim
    git
    wget
    nvidia-vaapi-driver
    libvdpau-va-gl
    egl-wayland
    libGL
  ];

  # services
  services = {
    xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
      videoDrivers = ["nvidia"];
    };
    irqbalance.enable = true;
    printing.enable = true;
    flatpak.enable = true;
    openssh.enable = true;
    fstrim.enable = true;
  };

  # logind
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleLidSwitch=suspend
    HandleLidSwitchExternalPower=ignore
  '';

  # KDE connect
  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  # network
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings.General.Experimental = true; # for gnome-bluetooth percentage
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    cpu.amd.updateMicrocode = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaPersistenced = true;
      open = false;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = false;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
    steam-hardware.enable = true;
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    NIXOS_OZONE_WL = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  # bootloader
  boot = {
    tmp.cleanOnBoot = true;
    supportedFilesystems = ["ntfs"];
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = ["nvidia"];
    kernelPackages = pkgs.linuxPackages_xanmod_latest;

    # splash screen
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # by default it would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = ["rings"];
        })
      ];
    };

    # enable "silent boot"
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "video=1920x1080"
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=2"
      "rd.udev.log_level=2"
      "udev.log_priority=2"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
      "libahci.ignore_sss=1"
      "threadirqs"
    ];
  };

  system.stateVersion = "24.05";
}
