{
  boot = {
    kernelModules = ["tcp_bbr"];
    kernelParams = [
      "transparent_hugepage=madvise"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.page-cluster" = 0;

      "kernel.sched_autogroup_enabled" = 1;

      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_congestion_control" = "bbr";

      "fs.inotify.max_user_watches" = 524288;
    };
  };

  services.irqbalance.enable = true;

  zramSwap.enable = true;
}
