{
  config,
  lib,
  pkgs,
  ...
}: {
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

  systemd.services.virt-secret-init-encryption.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.bash}/bin/sh -c 'umask 0077 && (${pkgs.coreutils}/bin/dd if=/dev/random status=none bs=32 count=1 | ${config.systemd.package}/bin/systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key)'"
  ];
}
