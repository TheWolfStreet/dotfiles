{
  inputs,
  username,
  stateVersion,
  dotfilesPath,
  gitName,
  gitEmail,
  pkgs,
  ...
}: {
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

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs stateVersion dotfilesPath gitName gitEmail;
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
      max-jobs = "auto";
      cores = 0;
    };
  };

  programs = {
    kdeconnect.enable = true;
    droidcam.enable = true;
    virt-manager.enable = true;
    dconf.enable = true;
  };

  virtualisation = {
    podman.enable = true;
    docker.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    vmVariant = {
      virtualisation = {
        memorySize = 8192;
        cores = 8;

        qemu.options = [
          "-vga virtio"
          "-display gtk,gl=on"
          "-device virtio-gpu-pci"
        ];
      };
    };
  };

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
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    '';
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
  services.xserver.displayManager.lightdm.enable = false;

  security.pam.services = {
    hyprlock = {};
    astal-auth = {};
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings.General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
        AutoEnable = false;
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
    kernelParams = [
      "libahci.ignore_sss=1"
      "threadirqs"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  system.stateVersion = stateVersion;
}
