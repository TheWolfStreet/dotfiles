{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.ags.homeManagerModules.default];
  programs.ags = {
    enable = true;
    configDir = ../ags2-shell;
    extraPackages = with pkgs; [
      dart-sass
      brightnessctl
      swww
      which
      libnotify
      libheif
      wf-recorder
      wl-clipboard
      slurp
      wayshot
      swappy
      hyprpicker
      pavucontrol
      networkmanager
      gtk3
      fd
      # Font, icons and cursor are handled in theme.nix
      # Matugen in flake.nix
      matugen
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.apps
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.battery
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.wireplumber
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.network
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.tray
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.battery
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.notifd
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.mpris
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.bluetooth
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.auth
      inputs.ags.packages.${pkgs.stdenv.hostPlatform.system}.powerprofiles
    ];
  };
}
