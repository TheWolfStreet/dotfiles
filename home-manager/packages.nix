{pkgs, ...}: let
  aagl = import (builtins.fetchTarball "https://github.com/ezKEa/aagl-gtk-on-nix/archive/main.tar.gz");
in {
  imports = [
    ./modules/packages.nix
    ./scripts/blocks.nix
    ./scripts/nx-switch.nix
    ./scripts/vault.nix
  ];

  nix.settings = aagl.nixConfig;
  packages = with pkgs; {
    linux = [
      (mpv.override {scripts = [mpvScripts.mpris];})
      aagl.anime-games-launcher
      spotify
      fragments
      file-roller
      discord
      vesktop
      bottles
      telegram-desktop
      krita
      blender
      obsidian
      ghidra
      easyeffects
      steam
      figma-linux
      nodejs
    ];
    cli = [
      fastfetch
      bat
      eza
      fd
      zoxide
      ripgrep
      ncdu
      btop
      fzf
      lazydocker
      lazygit
    ];
  };
}
