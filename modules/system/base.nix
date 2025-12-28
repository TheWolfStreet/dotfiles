{
  inputs,
  username,
  stateVersion,
  pkgs,
  ...
}: {
  # User setup
  users.users.${username} = {
    isNormalUser = true;
    initialPassword = username;
    extraGroups = [
      "nixosvmtest"
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "libvirtd"
      "docker"
    ];
  };

  # Home Manager integration
  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs stateVersion;
    };
    users.${username} = {
      home.username = username;
      home.homeDirectory = "/home/${username}";
      imports = [
        ../../home/terminal
        ../../home/nvim
        ../../home/desktop
        ../../home/dev
        ../../home/packages.nix
      ];

      programs.home-manager.enable = true;
      home = {
        stateVersion = stateVersion;
        sessionPath = [
          "$HOME/.local/bin"
        ];
      };
    };
  };

  documentation.nixos.enable = false;
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      keep-outputs = true;
      keep-derivations = true;
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  programs.droidcam.enable = true;

  programs.virt-manager.enable = true;
  virtualisation = {
    podman.enable = true;
    docker.enable = true;
    libvirtd.enable = true;
  };

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    home-manager
    neovim
    git
    wget
  ];

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

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
  services.xserver.displayManager.lightdm.enable = false;

  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedTCPPorts = [27040];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  security.pam.services = {
    hyprlock = {};
    astal-auth = {};
  };

  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  hardware = {
    bluetooth = {
      powerOnBoot = true;
      enable = true;
      settings.General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
      };
    };
    steam-hardware.enable = true;
  };

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

  system.stateVersion = stateVersion;
}
