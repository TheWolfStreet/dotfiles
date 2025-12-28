{
  config,
  dotfilesPath,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    withRuby = true;
    withNodeJs = true;
    withPython3 = true;

    extraPackages = with pkgs; [
      git
      gcc
      gnumake
      unzip
      wget
      curl
      tree-sitter
      ripgrep
      fd
      fzf
      cargo

      rustc
      luarocks
      lua5_1

      ghostscript
      tectonic
      imagemagick
      mermaid-cli

      nixd
      lua-language-server
      bash-language-server
      stylua
      alejandra
    ];
  };

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/home/nvim/config";
  };
}

