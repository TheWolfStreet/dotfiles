{pkgs, ...}: let
  symlink = pkgs.writeShellScript "symlink" ''
    if [[ "$1" == "-r" ]]; then
      rm -rf "$HOME/.config/nvim"
      rm -rf "$HOME/.config/easyeffects"
    fi

    if [[ "$1" == "-a" ]]; then
      rm -rf "$HOME/.config/nvim"
      rm -rf "$HOME/.config/easyeffects"

      ln -s "$HOME/.dotfiles/nvim" "$HOME/.config/nvim"
      ln -s "$HOME/.dotfiles/easyeffects" "$HOME/.config/easyeffects";
    fi
  '';
  nx-switch = pkgs.writeShellScriptBin "nx-switch" ''
    ${symlink} -r
    sudo nixos-rebuild switch --flake . --impure $@
    ${symlink} -a
  '';
  nx-boot = pkgs.writeShellScriptBin "nx-boot" ''
    ${symlink} -r
    sudo nixos-rebuild boot --flake . --impure $@
    ${symlink} -a
  '';
  nx-test = pkgs.writeShellScriptBin "nx-test" ''
    ${symlink} -r
    sudo nixos-rebuild test --flake . --impure $@
    ${symlink} -a
  '';
in {
  home.packages = [nx-switch nx-boot nx-test];
}
