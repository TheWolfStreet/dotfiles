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
      fragments
      discord
      vesktop
      bottles
      telegram-desktop
      easyeffects
      steam
      figma-linux
      nodejs
    ];
    cli = [
      bat
      eza
      zoxide
      fd
      ripgrep
      fzf
      lazydocker
      lazygit
    ];
  };
}
