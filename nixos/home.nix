{config, ...}: {
  news.display = "show";

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    warn-dirty = false;
  };

  nixpkgs.overlays = [
    (self: super: {
      stdenv = super.impureUseNativeOptimizations super.stdenv;
    })
  ];

  home = {
    sessionVariables = {
      QT_XCB_GL_INTEGRATION = "none"; # kde-connect
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
