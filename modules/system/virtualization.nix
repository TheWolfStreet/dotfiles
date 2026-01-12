{...}: {
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
}
