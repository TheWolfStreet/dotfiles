{pkgs, ...}: {
  imports = [
    ./modules/packages.nix
    ./scripts/blocks.nix
    ./scripts/nx-switch.nix
    ./scripts/vault.nix
  ];

  packages = with pkgs; {
    linux = [
      (mpv.override {scripts = [mpvScripts.mpris];})
      spotify
      bottles
      libreoffice
      kdenlive
      obs-studio
      fragments
      file-roller
      evince
      telegram-desktop
      vesktop
      krita
      blender
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
