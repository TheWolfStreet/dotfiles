{pkgs, ...}: {
  # Nix
  documentation.nixos.enable = false; # A .desktop entry
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      keep-outputs = true;
      keep-derivations = true;
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  # Camera
  programs.droidcam.enable = true;

  # Virtualisation
  programs.virt-manager.enable = true;
  virtualisation = {
    podman.enable = true;
    docker.enable = true;
    libvirtd.enable = true;
  };

  # Dconf
  programs.dconf.enable = true;

  # Packages
  environment.systemPackages = with pkgs; [
    home-manager
    neovim
    git
    wget
  ];

  # Services
  services = {
    xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
    };
    irqbalance.enable = true;
    printing.enable = true;
    flatpak.enable = true;
    openssh.enable = true;
    fstrim.enable = true;
  };

  # Logind
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
  #Disable lightdm
  services.xserver.displayManager.lightdm.enable = false;

  # KDE Connect
  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedTCPPorts = [27040]; # Steam LAN share
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  # Screen lock and greeter
  security.pam.services = {
    hyprlock = {};
    astal-auth = {};
  };

  # Network
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false; # Disable IPv6 so that only IPv4 evaluates in hosts, otherwise Nvim DAP fails to connect
  systemd.services.NetworkManager-wait-online.enable = false;

  hardware = {
    bluetooth = {
      powerOnBoot = true;
      enable = true;
      settings.General = {
        Experimental = true; # For gnome-bluetooth percentage
        Enable = "Source,Sink,Media,Socket";
      };
    };
    steam-hardware.enable = true;
  };

  # Bootloader
  boot = {
    tmp.cleanOnBoot = true;
    supportedFilesystems = ["ntfs"];
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_zen;

    # Splash screen
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = ["rings"];
        })
      ];
    };

    consoleLogLevel = 2;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "boot.shell_on_fail"
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
