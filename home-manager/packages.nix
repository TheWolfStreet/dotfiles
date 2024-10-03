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
      steam
      figma-linux
      nodejs
    ];
    cli = [
      bat
      eza
      fd
      ripgrep
      fzf
      lazydocker
      lazygit
    ];
  };
}
