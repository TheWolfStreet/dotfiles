{
  inputs,
  username,
  ...
}: {
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./configs/desktop.nix
    ./configs/laptop.nix
    ./hardware/common.nix
    ./hardware/nvidia.nix
    ./hardware/amd.nix
    ./system.nix
    ./audio.nix
    ./locale.nix
    ./nautilus.nix
    ./hyprland.nix
  ];

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
      inherit inputs;
    };
    users.${username} = {
      home.username = username;
      home.homeDirectory = "/home/${username}";
      imports = [
        ./home.nix
      ];
    };
  };
}
