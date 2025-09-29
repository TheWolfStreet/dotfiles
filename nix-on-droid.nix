{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.packages = with pkgs; [
    home-manager
    git
    wget
    gh
    openssh
  ];

  environment.etcBackupExtension = ".bak";

  system.stateVersion = "24.05";
  terminal = {
    font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
    colors = {
      background = "#1c1c1c"; # deep gray
      foreground = "#c0c0c0"; # soft light gray
      cursor = "#e0e0e0"; # slightly brighter for visibility

      color0 = "#1c1c1c"; # black / deep gray
      color1 = "#ff6c6b"; # red accent
      color2 = "#98be65"; # green
      color3 = "#da8548"; # orange
      color4 = "#51afef"; # blue
      color5 = "#c678dd"; # purple
      color6 = "#46d9ff"; # cyan
      color7 = "#c0c0c0"; # light gray

      color8 = "#555555"; # dark gray
      color9 = "#ff6c6b"; # bright red
      color10 = "#98be65"; # bright green
      color11 = "#da8548"; # bright orange
      color12 = "#51afef"; # bright blue
      color13 = "#c678dd"; # bright purple
      color14 = "#46d9ff"; # bright cyan
      color15 = "#ffffff"; # white
    };
  };
  user = {
    userName = "tws";
    shell = "${pkgs.nushell}/bin/nu";
  };

  time.timeZone = "Asia/Jerusalem";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  home-manager = {
    config = ./home.nix;
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
  };
}
