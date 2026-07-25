{pkgs, ...}: {
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };
}
