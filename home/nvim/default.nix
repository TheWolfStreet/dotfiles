{
  pkgs,
  configurationName,
  dotfilesPath,
  ...
}: {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NVIM_NIXD_HOST = configurationName;
    NVIM_NIXD_DOTFILES = dotfilesPath;
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    sideloadInitLua = true;

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
      clang-tools
      cmake
      ninja
      neocmakelsp
      cmake-format
      cmake-lint
      bash-language-server
      stylua
      alejandra
      statix
      libxml2
    ];
  };

  xdg.configFile."nvim" = {
    source = ./config;
  };
}
