{
  inputs,
  username,
  hostname,
  stateVersion,
  dotfilesPath,
  gitName,
  gitEmail,
  pkgs,
  ...
}: {
  imports = [
    ./virtualization.nix
    ./services.nix
    ./boot.nix
    ./hardware.nix
    ./security.nix
    ./responsiveness.nix
  ];
  users.users.${username} = {
    isNormalUser = true;
    # Initial password is set to username for first login convenience
    # NOTE: Change this immediately after first login with 'passwd'
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

  environment.systemPackages = with pkgs; [
    home-manager
    neovim
    git
    wget
  ];

  system.stateVersion = stateVersion;
}
