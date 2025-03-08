{pkgs, ...}: let
  mkIf = cond: value:
    if cond
    then value
    else [];
in {
  imports = [
    ./scripts/blocks.nix
    ./scripts/nx-switch.nix
    ./scripts/vault.nix
  ];

  home.packages = pkgs.lib.flatten (with pkgs; [
    fastfetch
    bat
    eza
    fd
    zoxide
    ripgrep
    ncdu
    btop
    powertop
    fzf
    xxd
    distrobox
    lazydocker
    lazygit

    (mkIf pkgs.stdenv.isLinux [
      (mpv.override {scripts = [mpvScripts.mpris];})
      xdg-desktop-portal-gtk
      bottles
      libreoffice
      kdePackages.kdenlive
      obs-studio
      fragments
      steam-run
      file-roller
      evince
      telegram-desktop
      krita
      audacity
      blender-hip
      ghidra
      easyeffects
      figma-linux
      nodejs
      appimage-run
    ])
  ]);
}
