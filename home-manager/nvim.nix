{pkgs, ...}: {
  xdg = {
    configFile.nvim.source = ../nvim;
  };

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

      # For plugin rebuilds
      rustc
      luarocks
      lua5_1

      # Render PDF, PNG, TEX, Mermaid
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
}
