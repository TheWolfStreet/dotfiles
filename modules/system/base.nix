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
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      min-free = 5 * 1024 * 1024 * 1024;
      max-free = 20 * 1024 * 1024 * 1024;
    };
  };

  programs = {
    kdeconnect = {
      enable = true;
      # BUG: KDE Connect types Wayland text per UTF-16 unit, so emoji surrogate pairs are dropped.
      # BUG: KDE Connect only rediscovers devices when Qt reachability or transport changes, so a second network joining stays unseen.
      # BUG: KDE Connect subscribes to the portal Session.Closed signal as (u, a{sv}) while the spec sends (a{sv}), so it never notices a closed remote input session.
      package = pkgs.kdePackages.kdeconnect-kde.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ../../patches/kdeconnect-emoji.patch
            ../../patches/kdeconnect-network-change.patch
            ../../patches/kdeconnect-session-closed.patch
          ];
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
