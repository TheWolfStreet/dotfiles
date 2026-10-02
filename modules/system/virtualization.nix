{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.virtualisation;
in {
  options.virtualisation.enable = lib.mkEnableOption "local containers and virtual machines";

  config = lib.mkIf cfg.enable {
    virtualisation = {
      podman.enable = true;
      docker.enable = true;
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu.vhostUserPackages = [pkgs.virtiofsd];
      };
    };

    users.users.${username}.extraGroups = ["docker" "libvirtd"];
    programs.virt-manager.enable = true;

    home-manager.sharedModules = [
      {
        dconf.settings."org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
        };
      }
    ];
  };
}
