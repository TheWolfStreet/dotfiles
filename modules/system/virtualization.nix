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

    systemd.services.virt-secret-init-encryption.serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.runtimeShell} -c 'umask 0077 && ${pkgs.coreutils}/bin/dd if=/dev/random status=none bs=32 count=1 | ${config.systemd.package}/bin/systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key'"
    ];
  };
}
