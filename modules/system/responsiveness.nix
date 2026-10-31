{pkgs, ...}: let
  max_jobs = pkgs.writeShellScript "nix-max-jobs" ''
    set -eu
    threads=$(${pkgs.coreutils}/bin/nproc)
    mem_kib=$(${pkgs.gawk}/bin/awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
    jobs=$(( (2 * mem_kib + threads * 524288) / (threads * 1048576) ))
    [ "$jobs" -ge 1 ] || jobs=1
    [ "$jobs" -le 4 ] || jobs=4
    printf 'max-jobs = %s\n' "$jobs" > /run/nix-daemon/max-jobs.conf
  '';
in {
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

  nix = {
    settings = {
      max-jobs = 1;
      cores = 0;
    };
    extraOptions = "!include /run/nix-daemon/max-jobs.conf";
  };

  systemd.services.nix-daemon.serviceConfig = {
    CPUWeight = "idle";
    MemoryHigh = "60%";
    RuntimeDirectory = "nix-daemon";
    ExecStartPre = "-${max_jobs}";
  };

  services.irqbalance.enable = true;

  zramSwap.enable = true;
}
