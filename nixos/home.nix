{
  config,
  inputs,
  ...
}: {
  imports = [
    ../home-manager/ags.nix
    ../home-manager/browser.nix
    ../home-manager/dconf.nix
    ../home-manager/easyeffects.nix
    ../home-manager/ghostty.nix
    ../home-manager/git.nix
    ../home-manager/hyprland.nix
    ../home-manager/lf.nix
    ../home-manager/nvim.nix
    ../home-manager/packages.nix
    ../home-manager/sh.nix
    ../home-manager/spotify.nix
    ../home-manager/starship.nix
    ../home-manager/theme.nix
    ../home-manager/tmux.nix
    ../home-manager/configs/laptop.nix
    ../home-manager/configs/desktop.nix
  ];

  news.display = "show";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };

  home = {
    sessionVariables = {
      QT_XCB_GL_INTEGRATION = "none"; # For KDE Connect
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_INSECURE = "1";
      BAT_THEME = "base16";
      GOPATH = "${config.home.homeDirectory}/.local/share/go";
      GOMODCACHE = "${config.home.homeDirectory}/.cache/go/pkg/mod";
    };

    sessionPath = [
      "$HOME/.local/bin"
    ];
  };
  gtk.gtk3.bookmarks = let
    home = config.home.homeDirectory;
  in [
    "file://${home}/Desktop"
    "file://${home}/Downloads"
    "file://${home}/Documents"
    "file://${home}/Videos"
    "file://${home}/Music"
    "file://${home}/Software"
    "file://${home}/Pictures"
    "file://${home}/Projects"
    "file://${home}/.config Config"
  ];

  services = {
    kdeconnect = {
      enable = true;
      indicator = true;
    };
  };

  programs.home-manager.enable = true;
  home.stateVersion = "24.05";
}
