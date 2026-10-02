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
