{
  username,
  stateVersion,
  pkgs,
  ...
}: {
  users.users.${username} = {
    isNormalUser = true;
    initialPassword = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "i2c"
    ];
  };

  documentation.nixos.enable = false;
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      keep-outputs = true;
      keep-derivations = true;
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
  };

  programs = {
    kdeconnect = {
      enable = true;
      # BUG: KDE Connect types Wayland text per UTF-16 unit, so emoji surrogate pairs are dropped.
      # BUG: KDE Connect only rediscovers devices when Qt reachability or transport changes, so a second network joining stays unseen.
      package = pkgs.kdePackages.kdeconnect-kde.overrideAttrs (old: {
        patches = (old.patches or []) ++ [../../patches/kdeconnect-emoji.patch ../../patches/kdeconnect-network-change.patch];
      });
    };
    droidcam.enable = true;
    dconf.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  system.stateVersion = stateVersion;
}
