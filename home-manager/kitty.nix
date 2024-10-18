{pkgs, ...}: {
  programs.kitty = {
    enable = true;
    themeFile = "Dracula";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };
    settings = {
      background_opacity = 0.50;
      window_padding_width = 12;
      confirm_os_window_close = 0;
      shell = "tmux";
    };
    shellIntegration = {
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
  # TODO: Move into a separate module
  home = {
    packages = let
      term = ''${pkgs.kitty}/bin/kitty $@'';
      alias = ["xterm" "kgx" "gnome-terminal"];
      aliases = map (n: pkgs.writeShellScriptBin n term) alias;
    in
      [pkgs.kitty] ++ aliases;
  };
  dconf.settings = {
    "com/github/stunkymonkey/nautilus-open-any-terminal".terminal = "kitty";
  };
}
