{
  config,
  inputs,
  configurationName,
  username,
  hostname,
  stateVersion,
  dotfilesPath,
  gitName,
  gitEmail,
  pkgs,
  ...
}: let
  mkTheme = scheme: import ../../home/desktop/defs.nix {inherit pkgs inputs scheme;};
in {
  users.users.${username} = {
    isNormalUser = true;
    # NOTE: Bootstrap credential; replace it with `passwd` after the first login.
    initialPassword = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "i2c"
    ];
  };

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs configurationName hostname stateVersion dotfilesPath gitName gitEmail mkTheme;
      virtualisationEnabled = config.virtualisation.enable;
      theme = mkTheme "dark";
    };
    users.${username} = {
      imports = [
        ../../home/terminal
        ../../home/nvim
        ../../home/desktop
        ../../home/dev
        ../../home/music.nix
        ../../home/packages.nix
      ];

      programs.home-manager.enable = true;
      home = {
        inherit username stateVersion;
        homeDirectory = "/home/${username}";
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

  programs = {
    kdeconnect.enable = true;
    droidcam.enable = true;
    dconf.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  system.stateVersion = stateVersion;
}
